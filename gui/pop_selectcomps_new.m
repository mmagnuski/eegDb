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

% TODOs:
% [ ] check cached topos if present
% [ ] write and call selcomps_update
% [ ] selcomps_update - should it cache topos or some other fun?
% [ ] work on broadcast
% [ ] check update option if passed (?)
% [ ] cached topos should have info on plot options


% info for hackers (or future self)
% ---------------------------------
% h     - structure of handles (to figure, axes and buttons)
% info  - structure of lightweight info:
%     .eegDb_present      - boolean; whether eegDb was passed
%     .compnum (?)
%     .topopts (?)
%     .r                  
%     .ver
%
% in 'appdata':
% 'h'         - structure of handles
% 'EEG'       - EEG structure
% 'info'      - struct; see in previous section
% 'eegDb'     - eegDb structure (database of preprocessing steps)
% 'topopts'   - structure of options for compo plotting

% INPUT CHECKS
% ------------

% if not enough arguments passed, show help:
if nargin < 1
    help pop_selectcomps;
    return
end

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
    
end



% DEFAULTS
% --------

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


% topopts
topopts.verbose    = 'off';
topopts.style      = 'fill';
topopts.chaninfo   = EEG.chaninfo;
topopts.numcontour = 8;

if EEG.nbchan > NOTPLOTCHANS
    topopts.electrodes = 'off';
else
    topopts.electrodes = 'on';
end


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
addParamValue(prs, 'perfig',  PLOTPERFIG, @isnumeric);
addParamValue(prs, 'fill',    true,       @islogical);
addParamValue(prs, 'eegDb',   [],         @iseegDb);
addParamValue(prs, 'h',       [],         @isstructofhandles);
addParamValue(prs, 'update',  'no',       @isupdateval);
addParamValue(prs, 'rsync',   [],         @isnumeric);
addParamValue(prs, 'r',       1,          @isnumeric);
addParamValue(prs, 'topopts', topopts,    @isupdateval);

parse(prs, varargin{:});
params = prs.Results;
clear prs


% clean up parameters
% -------------------
PLOTPERFIG = params.perfig;
info.eegDb_present = ~isempty(params.eegDb);
info.EGGcompN = size(EEG.icaweights,1);


% other fig handles:
if ~isempty(params.h)
    info.otherfigh = true;

    testflds = {'eegDb_gui', 'comp_explore'};
    for f = testflds
        if isfield(params.h, f{1})
            info.(f{1}) = params.h.(f{1});
        end
    end
else
    info.otherfigh = false;
end

% r
if info.eegDb_present
    eegDb = params.eegDb;

    info.r = params.r;

    if isempty(params.rsync)
        info.rsync = info.r;
    end

    % icaweights
    info.eegDbcompN = size(eegDb(info.r).ICA.icaweights, 1);

    % CHANGE
    % test for problems - when EEG does not have the same num
    %                     of components as eegDb
end



% ----------------------------------
% Num Axes per dimension and Filling
% figure rows and columns
% -----------------------

% CHANGE - move rows etc from params to info (or maybe change params to info?)
% testing plotperfig dimensions if 'fill' is on
params.column = ceil(sqrt( PLOTPERFIG ))+1;
params.rows = ceil(PLOTPERFIG/params.column);
if params.fill
    PLOTPERFIG = params.column * params.rows;
end

% if more components than figure space, enable scroll buttons
if length(compnum) > PLOTPERFIG
    info.block_navig = false;
    info.allcomp = compnum;
    compnum = compnum(1:PLOTPERFIG);
else
    info.block_navig = true;
    info.allcomp = [];
    
    NumOfComp = length(compnum);
    params.column = ceil(sqrt( NumOfComp ))+1;
    params.rows = ceil(NumOfComp/params.column);
end


% ADD or CHANGE:
% check what figures with selcomp tag exist
% and add a tag that is not being used
% or maybe do not use the tag (?)

% generate a random figure tag:
currentfigtag = ['selcomp' num2str(rand)];


% icadefs
% -------
% using icadefs is generally a bad idea - especially in terms of speed
% for compatibility it is still used if no eegDb was passed
if ~info.eegDb_present
    try
        icadefs;        
    end
end


% set up the figure
% -----------------

% h - strucutre of handles
% the rest is in appdata

if ~fig_h_passed
    
    % CHANGE name
    % create figure
    h.fig = figure('name', [ 'Reject components by map - ',...
        'pop_selectcomps_new() (dataset: ', EEG.setname ')'], 'tag', ...
        currentfigtag, 'numbertitle', 'off', 'color', BACKCOLOR);
    
    % delete the classic menu bar:
    set(h.fig, 'MenuBar', 'none');
    
    % get figure position:
    pos = get(h.fig, 'Position');
    
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


% check cached topos
% ------------------
info.ifcached = false;
cachetopo     = [];

% if eegDb passed - there
if info.eegDb_present
    tst = femp(eegDb(info.r).ICA, 'topo');
    if tst
        info.ifcached = true;
        cachetopo     = eegDb(info.r).ICA.topo;
        clear tst
    end
end

if ~info.ifcached
    tst = femp(EEG.etc, 'topo');
    if tst
        info.ifcached = true;
        cachetopo     = EEG.etc.topo;
        clear tst
    end
end

% CHECK?
% check cachetopo first
% should contain all components


% get rejected comps
% ------------------

if info.eegDb_present 
    % components marked as removed
    if femp(eegDb(info.r).ICA, 'remove')
        info.compremove = true(1, )
        info.compremove = eegDb(info.r).ICA.remove;
    else
        info.compremove = [];
    end

    % components marked as 'maybe'
    if femp(eegDb(info.r).ICA, 'ifremove')
        info.compifremove = eegDb(info.r).ICA.ifremove;
    else
        info.compifremove = [];
    end
else
    % get info from EEG
    if femp(EEG.reject, 'gcompreject')
        info.compremove =  EEG.reject.gcompreject;
    else
        info.compremove = [];
    end

    info.compifremove = [];
end



% draw the bottom buttons
% -----------------------
if ~fig_h_passed
    % CHANGE callbacks
    % CHECK  pop_icathresh(EEG)
    % CHANGE clarify visually (shorter lines)

    h.cancel = uicontrol(h.fig, 'Style', 'pushbutton', 'string', 'Cancel', 'Units','Normalized', 'backgroundcolor', GUIBUTTONCOLOR, ...
        'Position',[-10 -10  15 sizewy*0.25].*s+q, 'callback', 'close(gcf); fprintf(''Operation cancelled\n'')' );
    h.setthresholds = uicontrol(h.fig, 'Style', 'pushbutton', 'string', 'Set threhsolds', 'Units','Normalized', 'backgroundcolor', GUIBUTTONCOLOR, ...
        'Position',[10 -10  15 sizewy*0.25].*s+q, 'callback', 'pop_icathresh(EEG); pop_selectcomps( EEG, gcbf);' );
    
    % check if component statistics have been computed:
    if isempty( EEG.stats.compenta	), set(h.setthresholds, 'enable', 'off'); end;
    
    h.seecompstats = uicontrol(h.fig, 'Style', 'pushbutton', 'string', 'See comp. stats', 'Units','Normalized', 'backgroundcolor', GUIBUTTONCOLOR, ...
        'Position',[30 -10  15 sizewy*0.25].*s+q, 'callback',  ' ' );
    if isempty( EEG.stats.compenta	), set(h.seecompstats, 'enable', 'off'); end;
    
    % CHANGE - maybe better use a handles structure rather
    %          than later findobj...
    h.seeproj = uicontrol(h.fig, 'Style', 'pushbutton', 'string', 'See projection', 'Units','Normalized', 'backgroundcolor', GUIBUTTONCOLOR, ...
        'Position',[50 -10  15 sizewy*0.25].*s+q, 'callback', ' ', 'enable', 'off'  );
    
    % we've deleted the help button and added a button for plot
    % refreshing (left right arrows)
    h.prev = uicontrol(h.fig, 'Style', 'pushbutton', 'string', '  <  ', 'Units','Normalized', 'backgroundcolor', GUIBUTTONCOLOR, ...
        'Position',[68 -10  9 sizewy*0.25].*s+q, 'callback', {@topos_refresh, '<'},...
        'Enable', onoff{2 - info.block_navig});
    h.next = uicontrol(h.fig, 'Style', 'pushbutton', 'string', ...
        '  >  ', 'Units','Normalized', 'backgroundcolor', ...
        GUIBUTTONCOLOR, 'Position', [78 -10  9 sizewy*0.25].*s+q,...
        'callback', {@topos_refresh, '>'}, 'Enable', ...
        onoff{2 - info.block_navig});
    
    % CHANGE - use function handles
    % here the command for OK button is created:
    command = '[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET); eegh(''[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);''); close(gcf)';
    hh = uicontrol(h.fig, 'Style', 'pushbutton', 'string', 'OK', 'Units','Normalized', 'backgroundcolor', GUIBUTTONCOLOR, ...
        'Position',[90 -10  15 sizewy*0.25].*s+q, 'callback',  command);
end


% ===============================
% plotting consecutive components
% ADD - checking whether the figure is still alive
% ADD - checking (before!) which components are cached

% CONSIDER - the plotting below should be a
%            'refresh' subfunction
% count is used to find position of given axis
count = 1;
for i = 1:length(compnum)
    
    ri = compnum(i);

    % ===
    % button check:
    if fig_h_passed

        % CHANGE - should get info, h struct etc. from figure handle etc.
        %          findobj is unneccessarily slow

        % find the button of a present figure:
        button = findobj('parent', h.fig, 'tag', ['comp' num2str(ri)]);
        
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
        % instead - selcomps_update() later
        
        % CHANGE this to checking whether
        % the figure is still alive
        if ~strcmp(get(gcf, 'tag'), currentfigtag);
            disp('Aborting plot');
            return;
        end
        
        % CHANGE - tag is not necessary if we use array of handles
        % create axis for the topoplot
        h.ax(i) = axes('Units','Normalized', 'Position',[X Y sizewx sizewy].*s+q,...
            'tag', ['topoaxis', num2str(ri)]);
        
        
        % axis should be square
        % (so that component plots look OK)
        axis square;
        
        % plot the button above
        % ---------------------
        button_pos = [X, Y+sizewy, sizewx, sizewy*0.25] .* s+q;
        h.button(i) = uicontrol(h.fig, 'Style', 'pushbutton', 'Units','Normalized',...
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




% CONSIDER
% what about these:
h.comps.all = allcomp;
h.perfig = PLOTPERFIG;
h.opt.plotelec = plotelec;


if ~info.block_navig
    h.comps.visible = 1:PLOTPERFIG;
else
    h.comps.visible = [];
end
h.comps.invisible = zeros(1, h.perfig);

% APPDATA
% -------
setappdata(h.fig, 'h', h);
setappdata(h.fig, 'EEG', EEG);
setappdata(h.fig, 'info', info);
setappdata(h.fig, 'topopts', topopts);
setappdata(h.fig, 'cachetopo', cachetopo);


if info.eegDb_present
    setappdata(h.fig, 'eegDb', eegDb);

end

% CHANGE
% work on com a little more

% ---
% COM
% com is used to pass info to EEGlab history, we
% will use it only if called from EEGlab GUI
com = '';

% CHECK vararg2str - its EEGlab's function, not MATLAB's
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