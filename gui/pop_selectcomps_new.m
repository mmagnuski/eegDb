% modification of pop_select comps
% allows to:
% 1. scroll through components in a window with < > at the bottom
%  + interrupting plotting
% 2. minimize plotting time by saving the graphical object structure
%    (precomputing if users wishes so)
% 3. integrate with comp_explore (think it over - how to integrate best)
% 4. some other cool stuff - plotting options (other GUI)
%                          - tags (in da future)
%                          - what else?


% TODOs:
        % [ ] resolve adding computed topos to EEG in the
        %     base workspace (or how else?)
        % [ ] add an EEG-checking function that compares
        %     given EEG to those present in the base work-
        %     space or global variables available from 
        %     base workspace...
        % [ ] add precompute option

% FEATURES:
% options structure
% graphic structure?
%
%
%

% varargin options and 'update' keyword could help...
% OR, maybe better - until the figure is closed
%                    all data are kept in appdata figure
%                    field. only then (close request)
%                    the data are migrated or not
%                    (this depends on the call context)

% CONSIDER - how to pass options to the function?
%       --> hidden in EEG.etc.(somefield)?
%       --> as another argument (in varargin)?
%       --> maybe both ways with varargin overriding
%           EEG.etc.(somefield)
% CONSIDER - whether to use this one function for both
%            EEGlab and ICAw or only use it as a

% CONSIDER looking for a figure if handle not given
%          or only figure name given (?)
%          figh = findobj('type','figure','name','orange')

% CONSIDER if one resizes the figure the buttons do not
%          get scaled too much - some limits are set

% Would be nice if pop_selectcomps_new (or some other name
% that this function will have) was compatible with pop_selectcomps:

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
%
% See also: pop_prop(), eeglab()



function [EEG, com] = pop_selectcomps_new( EEG, compnum, fig, varargin )

% TODOs:
% - saves topo maps in EEG

%% ><\_''~~INPUT CHECKS~~''_/><

% ==========================================
% if not enough arguments passed, show help:
if nargin < 1
    help pop_selectcomps;
    return;
end;

% =====================================
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
    
    % the code below is no longer valid, now the
    % components are plotted in one window
    % with the option to move around
    %
    %if length(compnum) > PLOTPERFIG
    %    ButtonName=questdlg2(strvcat(['More than ' int2str(PLOTPERFIG) ' components so'],'this function will pop-up several windows'), ...
    %                         'Confirmation', 'Cancel', 'OK','OK');
    %    if ~isempty( strmatch(lower(ButtonName), 'cancel')), return; end;
    %end;
end;

% ============
% other checks

% check EEG.etc for topocach
TopCach = femp(EEG.etc, 'topocache');

% whether figure handle has been passed:
fig_h_passed = vpres('fig');

% a key might have been passed in place of
% figure handle
if fig_h_passed && ischar(fig)
    varargin = [{fig}, varargin];
    fig_h_passed = false;
end

% check keys
% ------------
% INPUT PARSER

prs = inputParser;
prs.FunctionName = 'pop_selectcomps_new';
% addParamValue is addParameter in new MATLAB...
% moreover addParamValue is not recommended...
addParamValue(prs,'perfig', 35, @isnumeric);
addParamValue(prs,'fill', true, @islogical);
parse(prs, varargin{:});
params = prs.Results;
clear prs

%%

% maybe CHANGE later - customize colors?
% reject and accept colors,
% we can leave these as they are:
COLREJ = '[1 0.6 0.6]';
COLACC = '[0.75 1 0.75]';

% CHANGE later:
% how many components per figure,
% this should be possible to pass
% in some data structure, now it
% only checks whether the variable
% is present
if ~femp(params, 'perfig')
    PLOTPERFIG = 35;
else
    PLOTPERFIG = params.perfig;
end

% testing plotperfig dimensions if 'fill' is on

params.column = ceil(sqrt( PLOTPERFIG ))+1;
params.rows = ceil(PLOTPERFIG/params.column);
if params.fill
    PLOTPERFIG = params.column * params.rows;
end

DRAWFREQ = 4;

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

% OTHER DEFAULTS
onoff = {'off', 'on'};

% ---
% COM
% com is used to pass info to EEGlab history, we
% will use it only if called from EEGlab GUI
com = '';
% CHANGE
% We'll think about filling com later
% com = [ 'pop_selectcomps(' inputname(1) ', ' vararg2str(compnum) ');' ];



% CONSIDER
% Ideally, there should be a 'verbose' option.
% now, I'm just going to comment out all print statements
% fprintf('Drawing figure...\n');

% generate a random figure tag:
currentfigtag = ['selcomp' num2str(rand)];

% ADD or CHANGE:
% check what figures with selcomp tag exist
% and add a tag that is not being used



% CHANGE - so that comp info is taken from:
%          ICAw    - if present
%     else EEG.etc - if it has relevant field there
%     else EEG     - if no other source present
% Check EEG.reject.gcompreject for component rejection
% info
if isempty(EEG.reject.gcompreject)
    EEG.reject.gcompreject = zeros( size(EEG.icawinv,2));
end

% CHECK - running icadefs may not be the best
%         especially in terms of speed
try
    icadefs;
catch  %#ok<CTCH>
    BACKCOLOR = [0.8 0.8 0.8];
    GUIBUTTONCOLOR   = [0.8 0.8 0.8];
end

% CHANGE - so that figure is not created when
%          figure handle has been passed
%
% set up the figure
% -----------------

if ~fig_h_passed
    
    % CHANGE name
    % create figure
    fig = figure('name', [ 'Reject components by map - ',...
        'pop_selectcomps() (dataset: ', EEG.setname ')'], 'tag', ...
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
    end;
    
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
end;


% figure rows and columns
% -----------------------
if EEG.nbchan > 64
    % CHANGE - verbose:
    % disp('More than 64 electrodes: electrode locations not shown');
    plotelec = 0;
else
    plotelec = 1;
end;


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
        
        h.EEG = EEG_topo_cache(h.EEG, gcf);
        
        % CONSIDER - gui data updates should happen more often...
        % update guidata
        h.comps.visible = toplot;
        guidata(figh, h);
    end

com = [ 'pop_selectcomps(' inputname(1) ', ' vararg2str(compnum) ');' ];
return
end
