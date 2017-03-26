% Usage:
%       >> OUTEEG = pop_selectcomps( INEEG, compnum );
%
% Inputs:
%   INEEG    - Input dataset
%              May have some additional fields to allow for
%              additional stuff (? - or db alongside ?)
%   compnum  - vector of component numbers
%
%  ---myadd---
%  Additonal optional inputs:
%  'topopts' - allows to define how topos should be plotted
%              not used yet!
%  'perfig'  - how many components to plot per figure
%  'fill'    - ?? what was this for ??
%  'db' ?
%  'rsync' ?
%  'r'    ?
%  'appdata' ? (handles structure etc. in case it was called from
%               comp_explore
%
%
% Output:
%   OUTEEG - Output dataset with updated rejected components
% Additional outputs:
%   db   - updated db structure
%
% Note:
%   if the function POP_REJCOMP is ran prior to this function, some
%   fields of the EEG datasets will be present and the current function
%   will have some more button active to tune up the automatic rejection.
%
%   author:                   Mikołaj Magnuski,                     2014
% based on: pop_selcomps.m by Arnaud Delorme, CNL / Salk Institute, 2001
%
% See also: pop_prop(), eeglab()



function [EEG, com] = pop_selectcomps_new( EEG, compnum, fig, varargin )

% TODOs:
% [ ] change name to something simpler like selcomps or compgui
% [ ] do not use compnum and fig as positional
% [ ] clear up help
% FUTURE:
% [ ] work on broadcast? - notify and addlistener for GUIs?
% [ ] cached topos should have info on plot options


% info for hackers (or future self)
% ---------------------------------
% h     - structure of handles (to figure, axes and buttons)
% info  - structure of lightweight info:
%     .db_present      - boolean; whether eegDb was passed
%     .compnum (?)
%     .topopts (?)
%     .r                  
%     .ver
%     .comps
%           .all   - all selected components
%           .visible
%           .invisible
%           .state
%
% in 'appdata':
% 'h'         - structure of handles
% 'EEG'       - EEG structure
% 'info'      - struct; see in previous section
% 'eegDb'     - eegDb structure (database of preprocessing steps)
% 'topopts'   - structure of options for compo plotting
% 
% TAGS:
% buttons     -> 'comp10' denotes button corresponding to 10th component
% axes        -> 


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
% BACKCOLOR        = [0.8 0.8 0.8];
FIGBACKCOLOR     = [0.93, 0.93, 0.93];
GUIBUTTONCOLOR   = [0.85 0.85 0.85];

NOTPLOTCHANS = 100;
PLOTPERFIG   = 25;
DRAWFREQ     = 1;
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
info.db_present = ~isempty(params.eegDb);
info.EGGcompN = size(EEG.icaweights,1);


% other fig handles:
if ~isempty(params.h)
    info.otherfigh = true;

    testflds = {'db_gui', 'comp_explore'};
    for f = testflds
        if isfield(params.h, f{1})
            info.(f{1}) = params.h.(f{1});
        end
    end
else
    info.otherfigh = false;
end

% if eegDb is present:
if info.db_present
    eegDb = params.eegDb;

    info.r = params.r;

    if isempty(params.rsync)
        info.rsync = info.r;
    else
        info.rsync = params.rsync;
    end

    % icaweights
    info.eegDbcompN = size(eegDb(info.r).ICA.icaweights, 1);

    % check mapping between EEG and eegDb comps:
    info.mapping = db_compare_ICA(EEG, eegDb(info.r));

    % CHANGE
    % test for problems - when EEG does not have the same num
    %                     of components as eegDb

    % get chanind and put wininv and chanlocs in appdata
    chansind = eegDb(info.r).ICA.icachansind;
    icawinv  = eegDb(info.r).ICA.icawinv;
    chanlocs = eegDb(info.r).datainfo.chanlocs(chansind);
else
    chansind = EEG.icachansind;
    icawinv  = EEG.icawinv;
    chanlocs = EEG.chanlocs(chansind);
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
    info.comps.all = compnum;
    compnum = compnum(1:PLOTPERFIG);
else
    info.block_navig = true;
    info.comps.all = compnum;
    
    NumOfComp = length(compnum);
    params.column = ceil(sqrt( NumOfComp ))+1;
    params.rows = ceil(NumOfComp/params.column);
end

% CHANGE - this is in info, should later be in opts or sth similar
info.FIGBACKCOLOR = FIGBACKCOLOR;


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
if ~info.db_present
    try %#ok<*TRYNC>
        icadefs;        
    end
end


% set up the figure
% -----------------

% h - strucutre of handles
% evetything is in relevant appdata fields

if ~fig_h_passed
    
    % CHANGE figure name

    % compute figure position - currently do not care about
    % number of comps per row, just make it bigger on the screen
    unt = get(0, 'Units');
    set(0, 'Units', 'pixels');
    scr_sz = get(0, 'ScreenSize');
    set(0, 'Units', unt);
    % pos = [pos(1) 20 800/7* params.column 600/5* params.rows];
    pos = [round(scr_sz(3) * 0.1), round(scr_sz(4) * 0.1), ...
        round(scr_sz(3) * 0.8), round(scr_sz(4) * 0.8)];

    % create figure
    h.fig = figure('name', [ 'Reject components by map - ',...
        'pop_selectcomps_new() (dataset: ', EEG.setname ')'], 'tag', ...
        currentfigtag, 'numbertitle', 'off', 'color', FIGBACKCOLOR, ...
        'Position', pos, 'MenuBar', 'none');
    
    % CHECK - later this should be checked and compared
    %         against options
    % CHANGE - manipulate the pos(1) and pos(2) to
    %          get better results

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
    % hh = gca;
    
    % CHECK - q and s seem to be scaling factors
    % CHANGE - does it make sense to use these
    %          scaling and moving factors?
    q = [pos(1) pos(2) 0 0];
    s = [pos(3) pos(4) pos(3) pos(4)]./100;
    axis off;
end


% check cached topos
% ------------------

% currently topos are not cached in eegDb struct
% - this turns out to take too much space
% they could be kept in EEG though or a separate
% file - topocache

info.ifcached = false;
topocache     = [];

% if eegDb passed - there
if info.db_present
    tst = femp(eegDb(info.r).ICA, 'topo');
    if tst
        info.ifcached = true;
        topocache     = eegDb(info.r).ICA.topo;
        clear tst
    end
end

if ~info.ifcached
    tst = femp(EEG.etc, 'topo');
    if tst
        info.ifcached = true;
        topocache     = EEG.etc.topo;
        clear tst
    end
end


% get rejected comps
% ------------------
% ADD / CHANGE - so that it works when some comps have been
%                rejected...
% CHANGE       - currently only eegDb-level
% CONSIDER     - may be better when state is only for those comps
%                present in comps.all 
info.comps.colorcycle = [GUIBUTTONCOLOR; eval(COLREJ); ...
                            eval(COLACC); [1, 0.65, 0]];
info.comps.stateNames = {'', 'reject', 'select', 'maybe'};
if info.db_present 

    % compstate
    info.comps.state = zeros(1, info.eegDbcompN);

    % components marked as removed
    if femp(eegDb(info.r).ICA, 'reject')
        info.comps.state(eegDb(info.r).ICA.reject) = 1;
    end

    % components marked as selected
    if femp(eegDb(info.r).ICA, 'select')
        info.comps.state(eegDb(info.r).ICA.select) = 2;
    end

    % components marked as 'maybe'
    if femp(eegDb(info.r).ICA, 'maybe')
        info.comps.state(eegDb(info.r).ICA.maybe) = 3;
    end

    % select only those present in comps.all
    info.comps.state = info.comps.state(info.comps.all);

else
    % CHANGE!
    % get info from EEG
    info.comps.colorcycle([3, 4],:) = [];
    info.comps.stateNames([3, 4]) = [];
    info.comps.state = zeros(1, info.EGGcompN);
    info.comps.state(logical(EEG.reject.gcompreject)) = 1;

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
    % CHANGE - some descriptions are reused - put 
    %          these in a cell array and reuse

    common_opts = {'Style', 'pushbutton', 'Units','Normalized', ...
        'backgroundcolor', GUIBUTTONCOLOR};

    h.cancel = uicontrol(h.fig, common_opts{:},...
        'string', 'Cancel', ...
        'Position',[-10 -10  15 sizewy*0.25].*s+q, ...
        'callback', 'close(gcf); fprintf(''Operation cancelled\n'')' );
    h.setthresholds = uicontrol(h.fig, common_opts{:}, ...
        'string', 'Set threhsolds', ...
        'Position',[10 -10  15 sizewy*0.25].*s+q, ...
        'callback', 'pop_icathresh(EEG); pop_selectcomps( EEG, gcbf);' );
    
    h.seecompstats = uicontrol(h.fig, common_opts{:}, ...
        'string', 'See comp. stats', ...
        'Position',[30 -10  15 sizewy*0.25].*s+q, ...
        'callback',  ' ' );

    % check if component statistics have been computed:
    if isempty( EEG.stats.compenta	)
        set(h.setthresholds, 'enable', 'off'); 
        set(h.seecompstats, 'enable', 'off'); 
    end
    
    % CHANGE - maybe better use a handles structure rather
    %          than later findobj...
    h.seeproj = uicontrol(h.fig, common_opts{:},...
        'string', 'See projection', ...
        'Position',[50 -10  15 sizewy*0.25].*s+q, ...
        'callback', ' ', 'enable', 'off'  );
    
    % we've deleted the help button and added a button for plot
    % refreshing (left right arrows)
    h.prev = uicontrol(h.fig, common_opts{:}, ...
        'string', '  <  ', ...
        'Position',[68 -10  9 sizewy*0.25] .* s+q, ...
        'callback', @(src, ev) linkfun_selcomps_dir_update(h.fig, '<'), ...
        'Enable', onoff{2 - info.block_navig});

    h.next = uicontrol(h.fig, common_opts{:}, ...
        'string', '  >  ', ...
        'Position', [78 -10  9 sizewy*0.25].*s+q,...
        'callback', @(src, ev) linkfun_selcomps_dir_update(h.fig, '>'), ...
        'Enable', onoff{2 - info.block_navig});
    
    % CHANGE - use function handles
    % here the command for OK button is created:
    
    h.ok = uicontrol(h.fig, common_opts{:}, ...
        'string', 'OK', ...
        'Position',[90 -10  15 sizewy*0.25].*s+q, ...
        'callback', @(src, evnt) compsel_OK(h.fig));
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
        
        % create axes
        % CONSIDER - move axes out of the loop?
        h.ax(i) = axes('Units','Normalized', 'Position',[X Y sizewx sizewy].*s+q,...
            'tag', ['topoaxis', num2str(ri)], 'Visible', 'off'); %#ok<LAXES>
        
        
        % axis should be square
        % (so that component plots look OK)
        axis square;
        
        % plot the button above
        % ---------------------
        button_pos = [X, Y+sizewy, sizewx, sizewy*0.25] .* s+q;
        h.button(i) = uicontrol(h.fig, 'Style', 'pushbutton', 'Units','Normalized',...
            'Position', button_pos, 'tag', ['comp' num2str(ri)]);
    end
    
    % go to the next component
    count = count +1;
end



% CONSIDER - move to info part of the code?
% update info
info.perfig = PLOTPERFIG;

if ~info.block_navig
    info.comps.visible = 1:PLOTPERFIG;
else
    info.comps.visible = info.comps.all;
end
info.comps.invisible = zeros(1, info.perfig);
info.drawfreq = DRAWFREQ;

% fastplotopts
fastplotopts = struct();
fastplotopts.num_epochs = []; % get from main gui? obj.opt.num_epoch_per_window
fastplotopts.window = []; % obj.window
fastplotopts.scale = []; % obj.opt.signal_scale

% APPDATA
% -------
setappdata(h.fig, 'h', h);
setappdata(h.fig, 'EEG', EEG);
setappdata(h.fig, 'info', info);
setappdata(h.fig, 'topopts', topopts);
setappdata(h.fig, 'icawinv',  icawinv);
setappdata(h.fig, 'chansind', chansind);
setappdata(h.fig, 'chanlocs', chanlocs);
setappdata(h.fig, 'topocache', topocache);
setappdata(h.fig, 'fastplotopts', fastplotopts);

% window callback(s)
set(h.fig, 'WindowKeyPressFcn', @compsel_compare_changes);


% initialize scheduler
% --------------------
% scheduler is used to resolved conflicts
% when clicking direction buttons while plotting
% has not been finished
s = Scheduler();

% initialize syncer
% -----------------
% very simple object helpful in syncing
% guis
snc = sync_compsel(h.fig);


% finish appdata
% --------------
setappdata(h.fig, 'syncer', snc);
setappdata(h.fig, 'scheduler', s);

if info.db_present
    setappdata(h.fig, 'eegDb', eegDb);
end


% ask Scheduler for gui update:
% -----------------------------
add(s, 'run', {@selcomps_update, 'figh', h.fig, 'update', 'topo'});
add(s, 'post', {@selcomps_topocache, h.fig});

% close task and ask to run:
close(s);
run(s);



% CHANGE
% COM
% ---
% com is used to pass info to EEGlab history, we
% will use it only if called from EEGlab GUI
% com = '';

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