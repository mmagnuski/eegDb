% Usage:
%       >> OUTEEG = pop_selectcomps( INEEG, compnum );
%
% Inputs:
%   INEEG    - Input dataset
%              May have some additional fields to allow for
%              additional stuff (? - or ICAw alongside ?)
%   compnum  - vector of component numbers
%
%  ---myadd---
%  Additonal optional inputs:
%  'ICAw' ?
%  'r'    ?
%  'appdata' ? (handles structure etc. in case it was called from
%               comp_explore
%
%
% Output:
%   OUTEEG - Output dataset with updated rejected components
% Additional outputs:
%   ICAw   - updated ICAw structure
%
% Note:
%   if the function POP_REJCOMP is ran prior to this function, some
%   fields of the EEG datasets will be present and the current function
%   will have some more button active to tune up the automatic rejection.
%
% Author: Arnaud Delorme, CNL / Salk Institute, 2001
%         Mikołaj Magnuski,                     2014
%
% See also: pop_prop(), eeglab()



function [EEG, com] = pop_selectcomps_new( EEG, compnum, fig, varargin )


% INPUT CHECKS
% ------------

% if not enough arguments passed, show help:
if nargin < 1
    help pop_selectcomps;
    return;
end;

% if comp indices have not been passed:
if nargin < 2
    
    % initialize GUI values:
    promptstr = { 'Components to plot:' };
    initstr   = { [ '1:' int2str(size(EEG.icaweights,1)) ] };
    
    % pop up a GUI dialog window asking for comp indices
    % maybe ADD something to the dialog window to indicate
    % that this is not the standard function
    result = inputdlg2(promptstr, ['Reject comp. by map -- ',...
        'pop_selectcomps'], 1, initstr);
    
    % if the user does not choose anything, return:
    if isempty(result), return; end;
    
    % turn user's string input to numbers:
    compnum = eval( [ '[' result{1} ']' ]);
    
end;



% DEFAULTS
% --------

% default topo plotting
topopts.verbose    = 'off';
topopts.style      = 'fill';
topopts.chaninfo   = EEG.chaninfo;
topopts.numcontour = 8;

% maybe CHANGE later - customize colors?
% reject and accept colors,
COLREJ           = '[1 0.6 0.6]';
COLACC           = '[0.75 1 0.75]';
BACKCOLOR        = [0.8 0.8 0.8];
GUIBUTTONCOLOR   = [0.8 0.8 0.8];

NOTPLOTCHANS = 65;
PLOTPERFIG   = 25;
DRAWFREQ     = 4;
onoff = {'off', 'on'};

% ============
% other checks

if nargin > 2
    % a key might have been passed in place of
    % figure handle
    if ischar(fig)
        varargin = [{fig}, varargin];
        fig_h_passed = false;
    else
        fig_h_passed = true;
    end
else
    fig_h_passed = false;
end

% INPUT PARSER
% ------------

prs = inputParser;
prs.FunctionName = 'pop_selectcomps_new';
% addParamValue is addParameter in new MATLAB...
% moreover addParamValue is not recommended...
addParamValue(prs, 'perfig', PLOTPERFIG, @isnumeric);
addParamValue(prs, 'fill', true, @islogical);
addParamValue(prs, 'eegDb', [], @iseegDb);
addParamValue(prs, 'h', true, @isstructofhandles);
addParamValue(prs, 'update', 'no', @isupdateval);
addParamValue(prs, 'topopts', topopts, @isupdateval);

parse(prs, varargin{:});
params = prs.Results;
clear prs

% clean up parameters
% -------------------
PLOTPERFIG = params.perfig;
eegDb_present = ~isempty(params.eegDb);

% testing plotperfig dimensions if 'fill' is on
params.column = ceil(sqrt( PLOTPERFIG ))+1;
params.rows = ceil(PLOTPERFIG/params.column);
if params.fill
    PLOTPERFIG = params.column * params.rows;
end

% ----------------------------------
% Num Axes per dimension and Filling

% if more components than figure space, enable scroll buttons
if length(compnum) > PLOTPERFIG
    block_navig = false;
    allcomp = compnum;
    compnum = compnum(1:PLOTPERFIG);
else
    block_navig = true;
    allcomp = [];
    
    NumOfComp = length(compnum);
    params.column = ceil(sqrt( NumOfComp ))+1;
    params.rows = ceil(NumOfComp/params.column);
end;


% generate a random figure tag:
currentfigtag = ['selcomp' num2str(rand)];

% ADD or CHANGE:
% check what figures with selcomp tag exist
% and add a tag that is not being used


% using icadefs is generally a bad idea - especially in terms of speed
% for compatibility it is still used if no eegDb was passed
if ~eegDb_present
    try
        icadefs;        
    end
end


% set up the figure
% -----------------

if ~fig_h_passed
    
    % CHANGE name
    % create figure
    fig = figure('name', [ 'Reject components by map - ',...
        'pop_selectcomps_new() (dataset: ', EEG.setname ')'], 'tag', ...
        currentfigtag, 'numbertitle', 'off', 'color', BACKCOLOR);
    
    % delete the classic menu bar:
    set(fig, 'MenuBar', 'none');
    
    % get figure position:
    pos = get(fig, 'Position');
    
    % CHECK - later this should be checked and compared
    %         against options
    % CHANGE - manipulate the pos(1) and pos(2) to
    %          get better results

    % change the position to match number of rows and columns
    % it is assumed that each colum should consume
    % 115 pixels (previously 800/7 that is - 114.2857)
    % and each row should take 120 pixels
    pos = [pos(1) 20 800/7* params.column 600/5* params.rows];
    set(gcf,'Position', pos);
    
    % incx and incy are used to compute button coordinates
    % (increment in x, increment in y)
    incx = 120; incy = 110;
    
    % sizewx and sizewy control the size of buttons
    % as well as axes coordinates
    sizewx = 100/params.column;
    if params.rows > 2
        sizewy = 90/params.rows;
    else
        sizewy = 80/params.rows;
    end
    
    % get current axis position to plot
    % relative to current axes
    pos = get(gca,'position');
    hh = gca;
    
    % CHECK - q and s seem to be scaling factors
    % CHANGE - does not make much sense to use these
    %          scaling and moving factors
    q = [pos(1) pos(2) 0 0];
    s = [pos(3) pos(4) pos(3) pos(4)]./100;
    axis off;
end


% figure rows and columns
% -----------------------
if EEG.nbchan > NOTPLOTCHANS
    plotelec = 0;
else
    plotelec = 1;
end;


% check cached topos
% ------------------
% check EEG.etc for topocach
TopCach = femp(EEG.etc, 'topo');

% get rejected comps
% ------------------
% CHANGE - so that comp info is taken from:
%          ICAw    - if present
%     else EEG.reject     - if no other source present
% Check EEG.reject.gcompreject for component rejection
% info
if isempty(EEG.reject.gcompreject)
    EEG.reject.gcompreject = zeros( size(EEG.icawinv,2));
end


% ===============================
% plotting consecutive components
% ADD - checking whether the figure is still alive
% ADD - checking (before!) which components are cached

% CONSIDER - the plotting below should be a
%            'refresh' subfunction
% count is used to find position of given axis
count = 1;
for ri = compnum
    
    % ===
    % button check:
    if fig_h_passed
        % find the button of a present figure:
        button = findobj('parent', fig, 'tag', ['comp' num2str(ri)]);
        
        % no such button was found, whoops!
        if isempty(button)
            error( 'pop_selectcomps(): figure does not contain the component button');
        end
    else
        button = [];
    end
    
    if isempty( button )
        
        % compute coordinates
        % -------------------
        % CHECK why -10 if units are set to normalized?
        %       OK - most probably this is because this function
        %       uses this strange scaling approach...
        X = mod(count-1, params.column)/params.column * incx - 10;
        Y = (params.rows-floor((count-1)/params.column))/params.rows * incy - sizewy*1.3;
        
        % plot the head
        % -------------
        
        % CHANGE this to checking whether
        % the figure is still alive
        if ~strcmp(get(gcf, 'tag'), currentfigtag);
            disp('Aborting plot');
            return;
        end
        
        % CHANGE - store axis handles in h.ax
        % create axis for the topoplot
        ha = axes('Units','Normalized', 'Position',[X Y sizewx sizewy].*s+q,...
            'tag', ['topoaxis', num2str(ri)]);
        
        % CHANGE - recreate from saved data if cached
        %        - add plot options to be used
        % plot the topo there
        if plotelec
            topoplot( EEG.icawinv(:,ri), EEG.chanlocs, 'verbose', ...
                'off', 'style' , 'fill', 'chaninfo', EEG.chaninfo,...
                'numcontour', 8);
        else
            topoplot( EEG.icawinv(:,ri), EEG.chanlocs, 'verbose', ...
                'off', 'style' , 'fill','electrodes','off', ...
                'chaninfo', EEG.chaninfo, 'numcontour', 8);
        end
        
        % axis should be square
        % (so that component plots look OK)
        axis square;
        
        % plot the button above
        % ---------------------
        button_pos = [X, Y+sizewy, sizewx, sizewy*0.25] .* s+q;
        button = uicontrol(gcf, 'Style', 'pushbutton', 'Units','Normalized',...
            'Position', button_pos, 'tag', ['comp' num2str(ri)]);
        
        % CHANGE command to a function handle that takes relevant
        % data from appdata and decides how to plot the component
        % CHECK how pop_prop behves too
        command = sprintf(['pop_prop( %s, 0, %d, %3.15f, ',...
            '{ ''freqrange'', [1 50] });'], inputname(1), ri, button);
        set( button, 'callback', command );
    end
    
    % CHANGE this so that other sources can be used:
    % CHANGE fastif to indexing through color cell matrix
    %
    % set button color
    set( button, 'backgroundcolor', eval(fastif(EEG.reject.gcompreject(ri),...
        COLREJ,COLACC)), 'string', int2str(ri));
    
    % CONSIDER whether changing this might
    % help with speed:
    % draw each of the component without
    % waiting for buffer to fill
    drawnow;
    
    % go to the next component
    count = count +1;
end

% draw the bottom buttons
% -----------------------
if ~fig_h_passed
    hh = uicontrol(gcf, 'Style', 'pushbutton', 'string', 'Cancel', 'Units','Normalized', 'backgroundcolor', GUIBUTTONCOLOR, ...
        'Position',[-10 -10  15 sizewy*0.25].*s+q, 'callback', 'close(gcf); fprintf(''Operation cancelled\n'')' );
    hh = uicontrol(gcf, 'Style', 'pushbutton', 'string', 'Set threhsolds', 'Units','Normalized', 'backgroundcolor', GUIBUTTONCOLOR, ...
        'Position',[10 -10  15 sizewy*0.25].*s+q, 'callback', 'pop_icathresh(EEG); pop_selectcomps( EEG, gcbf);' );
    
    % check if component statistics have been computed:
    if isempty( EEG.stats.compenta	), set(hh, 'enable', 'off'); end;
    
    hh = uicontrol(gcf, 'Style', 'pushbutton', 'string', 'See comp. stats', 'Units','Normalized', 'backgroundcolor', GUIBUTTONCOLOR, ...
        'Position',[30 -10  15 sizewy*0.25].*s+q, 'callback',  ' ' );
    if isempty( EEG.stats.compenta	), set(hh, 'enable', 'off'); end;
    
    % CHANGE - hh used multiple times for no reason...
    %          maybe better use a handles structure rather
    %          than later findobj...
    hh = uicontrol(gcf, 'Style', 'pushbutton', 'string', 'See projection', 'Units','Normalized', 'backgroundcolor', GUIBUTTONCOLOR, ...
        'Position',[50 -10  15 sizewy*0.25].*s+q, 'callback', ' ', 'enable', 'off'  );
    
    % we've deleted the help button and added a button for plot
    % refreshing (left right arrows)
    hh = uicontrol(gcf, 'Style', 'pushbutton', 'string', '  <  ', 'Units','Normalized', 'backgroundcolor', GUIBUTTONCOLOR, ...
        'Position',[68 -10  9 sizewy*0.25].*s+q, 'callback', {@topos_refresh, '<'},...
        'Enable', onoff{2 - block_navig});
    hh = uicontrol(gcf, 'Style', 'pushbutton', 'string', ...
        '  >  ', 'Units','Normalized', 'backgroundcolor', ...
        GUIBUTTONCOLOR, 'Position', [78 -10  9 sizewy*0.25].*s+q,...
        'callback', {@topos_refresh, '>'}, 'Enable', ...
        onoff{2 - block_navig});
    
    % here the command is created:
    command = '[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET); eegh(''[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);''); close(gcf)';
    hh = uicontrol(gcf, 'Style', 'pushbutton', 'string', 'OK', 'Units','Normalized', 'backgroundcolor', GUIBUTTONCOLOR, ...
        'Position',[90 -10  15 sizewy*0.25].*s+q, 'callback',  command);
    
    % CHECK code below - what is this? (it was commented out in the
    % original function)
    % sprintf(['eeg_global; if %d pop_rejepoch(%d, %d, find(EEG.reject.sigreject > 0), EEG.reject.elecreject, 0, 1);' ...
    %		' end; pop_compproj(%d,%d,1); close(gcf); eeg_retrieve(%d); eeg_updatemenu; '], rejtrials, set_in, set_out, fastif(rejtrials, set_out, set_in), set_out, set_in));
end

EEG = EEG_topo_cache(EEG, gcf);

% temporarily:
h.EEG = EEG;
h.TopCach = TopCach;
h.comps.all = allcomp;
h.block_navig = block_navig;
h.perfig = PLOTPERFIG;
h.opt.plotelec = plotelec;

if ~block_navig
    h.comps.visible = 1:PLOTPERFIG;
else
    h.comps.visible = [];
end
h.comps.invisible = zeros(1, h.perfig);
guidata(fig, h);

% temp refresh:

    function topos_refresh(hobject, ~, dir)
        % a button has been pressed,
        % evaluate which comps have to be plotted
        
        % TODOs:
        % [ ] fix plotting components when those
        %     to plot are less than the number of axes
        
        figh = get(hobject, 'Parent');
        h = guidata(figh);
        numcomps = length(h.comps.all);
        
        cachedcomps = [h.EEG.etc.topocache.CompNum];
        % remapping that some of the component plots can just be moved from
        % one place to another
        remapping = false; % CHANGE - should remapping be used?
        
        if strcmp(dir, '<')
            toplot(1) = h.comps.visible(1) - h.perfig;
            if toplot(1) < 1; toplot(1) = 1; remapping = true; end
            toplot = toplot(1) : toplot(1) + h.perfig - 1;
        elseif strcmp(dir, '>')
            toplot(1) = h.comps.visible(end) + 1;
            fin = min(toplot(1) + h.perfig - 1, numcomps);
            toplot = toplot(1) : fin;
        end
        
        if ~isempty(toplot)
        % -----------
        % clear up field
        for stp = 1:length(h.comps.visible)
            
            % comp number
            cmp = h.comps.all(toplot(stp));
            
            % get axis handle:
            thisax = findobj('Parent', figh, 'tag', ...
                ['topoaxis', num2str(h.comps.visible(stp))]);
            
            % clear axis children
            axchil = get(thisax, 'Children');
            
            % CHECK
            % why invisible are compared with zero?
            % this is weird -  what should this code do?
            if ~isempty(axchil) %&& h.comps.invisible(stp) == 0
                set(axchil, 'Visible', 'off');
                h.comps.invisible(stp) = h.comps.visible(stp);
            end
            
            % change tag etc.
            h.comps.visible(stp) = toplot(stp);
            set(thisax, 'tag', ['topoaxis', num2str(cmp)]);
            
            but = findobj('tag', ['comp', num2str(h.comps.all(...
                h.comps.invisible(stp)))]);
            comm = sprintf(['pop_prop( %s, 0, %d, %3.15f, ',...
                '{ ''freqrange'', [1 50] });'], 'h.EEG', cmp, but);
            set( but, 'callback', comm, 'string', int2str(cmp),...
                'tag', ['comp', num2str(cmp)]);
        end
        
        
        % -----------
        % plot components
        for stp = 1:length(toplot)
            cmp = h.comps.all(toplot(stp));
            
            % get axis handle:
            thisax = findobj('Parent', figh, 'tag', ...
                ['topoaxis', num2str(h.comps.visible(stp))]);
            
            % ------------------
            % replot from memory
            if sum(cachedcomps == cmp) > 0
                replot_topo(h.EEG, cmp, thisax);
                
                
                % CHANGE so that frequency of drawnow
                % can be controlled
                
                if mod(stp, DRAWFREQ) == 0
                    drawnow
                end
            else
                
                % clear axis children
                axchil = get(thisax, 'Children');
                delete(axchil);
                h.comps.invisible(stp) = 0;
                
                % activate axis:
                axes(thisax); %#ok<LAXES>
                
                % draw new topoplot
                if h.opt.plotelec
                    topoplot( h.EEG.icawinv(:,cmp), h.EEG.chanlocs, 'verbose', ...
                        'off', 'style' , 'fill', 'chaninfo', h.EEG.chaninfo,...
                        'numcontour', 8);
                else
                    topoplot( h.EEG.icawinv(:,cmp), h.EEG.chanlocs, 'verbose', ...
                        'off', 'style' , 'fill','electrodes','off', ...
                        'chaninfo', h.EEG.chaninfo, 'numcontour', 8);
                end
                
                % --- and change other stuff ---
                
            end
        end
        
        % topo caching - CHECK and probably CHANGE
        h.EEG = EEG_topo_cache(h.EEG, gcf);
        
        % CONSIDER - gui data updates should happen more often...
        % update guidata
        h.comps.visible = toplot;
        guidata(figh, h);
        end
    end

% CHANGE
% work on com a little more

% ---
% COM
% com is used to pass info to EEGlab history, we
% will use it only if called from EEGlab GUI
com = '';

com = [ 'pop_selectcomps(' inputname(1) ', ' vararg2str(compnum) ');' ];

end


function isv = isupdateval(v)
% checks whether input is char and corresponds to
% either 'workspace', 'eegDb gui'

    if ~ischar(v)
        isv = false;
        return
    end

    valid = {'workspace', 'eegDb gui'};
    isv = any(strcmp(v, valid));
end