function varargout = db_gui(varargin)

% DB_GUI - GUI that allows for basic operations on db.`
%             Adding notes, marking epochs in different ways
%             as well as listing bad channels is easy with
%             db_gui GUI.
%  use as:
%      db = DB_GUI(db);
%  or:
%      db = DB_GUI(db, r)
%                where r is a positive integer
%                to start exploring db structure from r register
%
% CHANGE - see also should be updated
% See also: db_buildbase, db_create_base

% TODOs:
% [ ] universal mechanism for mark types:
%         - [X] adding user-defined types
%         - [X] name field that defines how the
%               mark type should be displayed
%         - [ ] check regular rejection types
%               in EEG.reject
%         - [ ] universal adding rejection types
%               in recoverEEG and cooleegplot

% Last Modified by GUIDE v2.5 05-Jun-2015 17:20:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @db_gui_OpeningFcn, ...
    'gui_OutputFcn',  @db_gui_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before db_gui is made visible.
function db_gui_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to db_gui (see VARARGIN)

% Choose default command line output for db_gui
handles.output = hObject;
handles.UniOrig = get(0, 'Units');

% CHECK
% [?] why are the lines below commented out?
% [?] why setting figure1 to visible if units are not pixels?
if ~strcmp(handles.UniOrig, 'pixels')
    set(handles.figure1, 'Visible', 'on');
    %     set(0, 'Units', 'pixels');
    %     set(handles.figure1, 'Units', 'pixels');
    %     set(get(handles.figure1, 'Children'),...
    %         'Units', 'pixels');
end

% CHANGE:
% [ ] old (distance --> prerej) assumptions are dangerous
%     should be changed as priority
% [ ] organize handles into neat structures and sub-structures
%     so that it's easiest to add profile use later on
% [ ] change handles to h and test
%
% currently it works this way:
% h.db - self-explanatory
% h.db_start - initial db structure passed
%                back to the user if he aborts
% h.EEG        - last recovered EEG
% h.EEGr       - registry of last recovered EEG
% h.ecol = color options for electrode display
%          CHECK - h.ecol not used?
% handles.figure2 = [];
% handles.selected = [];
% handles.CloseReq = false;
% handles.multisel_col = ;
% handles.structpath = false;
% handles.recovopts = cell(1);
% handles.cooleegopts = [];

% --- SET ---
% set color options
handles.ecol = 'cosmic bubblegum';

% check for EEGlab presence (if not present - add path)
[~, funacc] = checkEEGlab();
if ~funacc
    eeg_path('add');
end

% put database in handles (GUI data)
handles.db = varargin{1};
handles.db_start = handles.db;

% set registry number to start with
if length(varargin) > 1
    handles.r = varargin{2};
else
    handles.r = 1;
end

% set other GUI variables:
handles.EEG = [];
handles.rEEG = [];
handles.figure2 = [];
handles.selected = [];
handles.CloseReq = false;
handles.multisel_col = get(handles.multisel, 'BackgroundColor');

% CHECK - do we need structpath?
handles.structpath = false;

handles.recovopts = cell(1); % CHECK - why is this cell length one and not zero?
handles.plotopts = struct('ecol', 'off', 'winlen', 3, ...
    'badplot', 'grey', 'lsmo', 'off', 'plotter', 'eegplot');
handles.last_recovered_opts = handles.recovopts;

% set info_text to FiexedWidth
set(handles.info_text ,'FontName','FixedWidth');
% set slider position:
set(handles.slider, 'Value', get(handles.slider, 'Max'));
set(handles.slider, 'SliderStep', [1 3]);

% CHANGE - now we check recov by nonempty prerej
%          but this is not optimal
handles.recov = ~cellfun(@(x) isempty(x.pre),...
    {handles.db.reject});

% KEYPRESS
% --------
% set window keypress behavior
set(handles.figure1, 'WindowKeyPressFcn', @db_gui_buttonpress);

% Update handles structure
guidata(hObject, handles);

% ===PROFILE========================
% try to load profile if one exists:
handles = test_profile(handles, 'load');

% Refresh GUI:
db_gui_refresh(handles);

% UIWAIT makes db_gui wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = db_gui_OutputFcn(hObject, eventdata, handles)

% if no output defined - generate ans in workspace
if nargout == 0 && ~handles.CloseReq
    assignin('base', 'ans', handles.db);
elseif nargout > 0
    varargout{1} = handles.db;
end
delete(handles.figure1);


%% [~] PLOT DATA
function dataplot_butt_Callback(hObject, eventdata, handles) %#ok<*DEFNU,*INUSD>

% first - check if data plot is not open already:
if handles.figure2
    % CHANGE - block main interface during plotting
    %          and do not check for handles.figure2 here
    figure(handles.figure2); % this is not used yet
else


    % CHANGE - this is a mess
    %        - whether r is recovered should be checked in a sepatate
    %          function (the same with recover if not present)
    %        - recovopts should be reworked
    %        - comparing EEG and current r/version should be
    %          smarter

    % first - recover data if not present
    if isempty(handles.EEG) || handles.r ~= handles.rEEG || ...
            ~db_recov_compare(handles.EEG.etc.recov, handles.db(handles.r)) ...
            || ~isequal(handles.recovopts, handles.last_recovered_opts)

        % save recovery options:
        handles.last_recovered_opts = handles.recovopts;

        % TXT display
        set(handles.addit_text, 'String', 'Recovering EEG...');
        drawnow;

        % RECOVER EEG data
        handles.EEG = recoverEEG(handles.db, handles.r, 'local', ...
                                 handles.recovopts{:});
        handles.rEEG = handles.r;
        rEEG = handles.rEEG;

        % update prerej field
        f = db_checkfields(handles.EEG, 1,...
            {'onesecepoch'}, 'subfields', true);
        if f.fsubf(1)
            isprerej = find(strcmp('prerej', f.subfields{1}));
        end

        % CHECK - in case of prerej, postrej division
        %          the following step is important because
        %          it allows for some prerej-postrej-removed
        %          calculations. However, it should not restric
        %          usage of databases that do not use onesecepoch
        %          Checking recov should be done only
        %          for databases using onesecepoch
        %
        % set this file as elligible to some
        % operations (apply rejections, multisel, etc.)
        if f.fsubf(1) && ~isempty(isprerej) ...
                && f.subfnonempt{1}(isprerej)
            handles.db(handles.r).reject.pre = handles...
                .EEG.onesecepoch.prerej;
            handles.recov(handles.r) = true;
        end
        clear f isprerej

        % Update handles structure
        guidata(hObject, handles);

        % file recovered
        set(handles.addit_text, 'String', 'EEG recovered');

        % refresh gui (CHECK - do we need to?)
        db_gui_refresh(handles);
    end

    % disable plotting
    set(hObject, 'Enable', 'off');

    % ADD warining if removed is filled and
    % userrem or autorem too ?

    linkfun_eegplot(handles);

    % enable plotting
    set(hObject, 'Enable', 'on');

    % get updated handles
    handles = guidata(hObject);

    % Refresh GUI:
    db_gui_refresh(handles);
end


% --- Executes on button press in done_butt.
function done_butt_Callback(hObject, eventdata, handles)

% Update handles structure
guidata(hObject, handles);

% resume action
uiresume(handles.figure1);



% --- Executes on button press in CL_checkbox.
function CL_checkbox_Callback(hObject, eventdata, handles)

% Hint: get(hObject,'Value') returns toggle state of CL_checkbox
handles.db(handles.r).cleanline = logical(get(hObject, 'Value'));

% Update handles structure
guidata(hObject, handles);


function notes_win_Callback(hObject, eventdata, handles)

handles.db(handles.r).notes = get(hObject, 'String');

% Update handles structure
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function notes_win_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%% [~] BADCHAN SELECT
% --- Executes on button press in badel_butt.
function badel_butt_Callback(hObject, eventdata, handles)

chanlab = {handles.db(handles.r).datainfo.chanlocs.labels};
badchan = handles.db(handles.r).chan.bad;

f_cha = db_gui_choose_chan(chanlab, badchan);

if ishandle(f_cha)
    selchan = get(f_cha, 'UserData');
    handles.db(handles.r).chan.bad = selchan{1};
    handles.db(handles.r).chan.badlab = selchan{2};

    close(f_cha);


    % Update handles structure
    guidata(hObject, handles);

    % Refresh GUI:
    db_gui_refresh(handles);
end


% --- Executes on button press in col_butt.
function col_butt_Callback(hObject, eventdata, handles)

% color changes are now present in cooleeg options
% CHANGE - delete this button callback

%% [~] NAVIGATION
% --- Executes on button press in next_butt.
function next_butt_Callback(hObject, eventdata, handles)

if handles.r < length(handles.db)
    handles.r = handles.r + 1;

    % Update handles structure
    guidata(hObject, handles);

    % refresh
    db_gui_refresh(handles);
end


% --- Executes on button press in prev_butt.
function prev_butt_Callback(hObject, eventdata, handles)

if handles.r > 1
    handles.r = handles.r - 1;

    % Update handles structure
    guidata(hObject, handles);

    % refresh
    db_gui_refresh(handles);
end

%% [~] SLIDER
% --- Executes on slider movement.
function slider_Callback(hObject, eventdata, handles)

% CHANGE - db_gui_refresh should be selective - what to
%          refresh
db_gui_refresh(handles);

% --- Executes during object creation, after setting all properties.
function slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

%% [~] CLOSE REQUEST
% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)

if isequal(get(hObject, 'waitstatus'), 'waiting')
    % The GUI is still in UIWAIT,
    % output is unmodified, modified output
    % is generated base in workspace as ans
    assignin('base', 'ans', handles.db);

    % main output is unchanged
    handles.db = handles.db_start;
    handles.CloseReq = true;

    % Update handles structure
    guidata(hObject, handles);

    % Resume GUI
    uiresume(hObject);
else
    % The GUI is no longer waiting, just close it
    delete(hObject);
end

%% [~] RECOVER IN EEGLAB
% --- Executes on button press in EEGreco.
function EEGreco_Callback(hObject, eventdata, handles)

% check selection
% ADD - selection checks should be in a separate function
if isempty(handles.selected)
    sel = handles.r;
else
    sel = handles.selected;
end

% % which can be recovered:
% cansel = sel(handles.recov(sel));

cansel = sel;

% set text info:
if ~isempty(cansel)
    % we can recover the file in EEGlab
    set(handles.addit_text, 'String', {'Recovering to EEGlab GUI'});
    drawnow;
else
    % we cannot recover
    set(handles.addit_text, 'String', {'Sorry, you need to'; ...
        'mark the data first'});
    drawnow;
end

for c = 1:length(cansel)
    r = cansel(c);

    % CHANGE - it should work both ways:
    % now we remove by prerej, not distance
    % CHANGE - previous comment not clear,
    % howver, this should not probably remove
    % distance option, epoching should be checking
    % pre - if it is filled, no need to check
    % distance again. If we change distance -->
    % some reworking is needed to save post
    % but clear pre. May be problematic if
    % pre is empty after distance was applied
    % use .distUsed or internal.distUsed ??
    if femp(handles.db(r).epoch, 'locked') && ...
        ~handles.db(r).epoch.locked && ...
        femp(handles.db(r).epoch, 'distance')

        % CHANGE ??
        % clear distance option
        handles.db(r).epoch.distance = [];
        % Update handles structure
        guidata(hObject, handles);
    end

    str = get(handles.addit_text, 'String');
    str{2,1} = ['record ', num2str(c), ' of ',...
        num2str(length(cansel))];
    set(handles.addit_text, 'String', str);
    drawnow;

    % nonlocal call to recoverEEG
    % ADD - in some cases 'interp' may be wanted (?)
    handles.EEG = recoverEEG(handles.db, r, handles.recovopts{:});

    % add version info to EEG
    handles.EEG = db_ver2EEG(handles.db, handles.r, handles.EEG);
end

if ~isempty(cansel)
    if length(cansel) < length(sel)
        set(handles.addit_text, 'String', {'Done but some data could not';...
            ' be recovered - mark them first'});
        drawnow;
    else
        set(handles.addit_text, 'String', {'Done.'});
        drawnow;
    end
end

%% [~] MULTI-SELECTION
% --- Executes on button press in multisel.
function multisel_Callback(hObject, eventdata, handles)
% call the link function:
linkfun_multiselect(handles);


%% [~]  APPLY REJECTIONS
% --- Executes on button press in applyrej.
function applyrej_Callback(hObject, eventdata, handles)
% hObject    handle to applyrej (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% check selection
if isempty(handles.selected)
    sel = handles.r;
else
    sel = handles.selected;
end

% which can be applied:
% cansel = sel(handles.recov(sel));
cansel = sel;

% sif none can be selected:
if isempty(cansel)
    % we cannot apply rejs - no prerej
    set(handles.addit_text, 'String', {'Sorry, you need to'; ...
        'mark the data first'});
    drawnow;
    return
end

% what kind of selections?
rej = db_getrej(handles.db, handles.r, 'nonempt', true);
seltypes = (rej.name)';


% ===============================
% if some have applied rejections
% - allow for removal
remopt =false;
remhas = ~cellfun(@(x) isempty(x.all), {handles.db(cansel).reject});
remhas = sum(remhas) > 0;
if remhas
    remopt = true;
    seltypes = [seltypes; 'clear rejections'];
    clear remhas
end

% =========================
% if no selections present:
if isempty(seltypes)
    % we cannot apply rejs - no seltypes
    set(handles.addit_text, 'String', {'Sorry, no data could'; ...
        'be selected'});
    drawnow;
    return
end

% =================================
% open list gui to choose selection
sel = gui_chooselist(seltypes, 'text', ...
    {'Select rejections'; 'to apply:'});

% =================
% reject selections
% ADD handling for choosing clearing rejections
%     with some other rejections
%
% isequal(sel, length(seltypes)) because
% clear rejections is the last option in seltypes
% while sel is what the user selects

if remopt && isequal(sel, length(seltypes))
    % apply rejections
    handles.db = db_applyrej(handles.db, cansel,...
        'clear', true);

    % Update handles structure
    guidata(hObject, handles);

    % refresh
    db_gui_refresh(handles);
    return
end

seltypes = rej.name(sel);

if ~isempty(seltypes)

    % apply rejections
    handles.db = db_applyrej(handles.db, cansel,...
        'byname', seltypes);

    % Update handles structure
    guidata(hObject, handles);

    % refresh
    db_gui_refresh(handles);
end


%% [~] RUN ICA
% --- Executes on button press in runICA.
function runICA_Callback(hObject, eventdata, handles)
% hObject    handle to runICA (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% check selection
if isempty(handles.selected)
    sel = handles.r;
else
    sel = handles.selected;
end

% which can be applied:
% cansel = sel(handles.recov(sel));
cansel = sel;

% sif none can be selected:
if isempty(cansel)
    % we cannot apply rejs - no prerej
    set(handles.addit_text, 'String', {'Sorry, no valid'; ...
        'sets selected...'});
    drawnow;
    return
end

% check eeglab:
[~, f] = checkEEGlab();

if ~f
    eeg_path('add');
end

if femp(handles.db(handles.r).ICA, 'icaweights')
    % plot ica of the first record
    linkfun_compexplore(handles.figure1);
else
%% run ica

% text update
set(handles.addit_text, 'String', {'computing ICA'});
drawnow;

for c = 1:length(cansel)
    s = cansel(c);

    % update text display
    str = get(handles.addit_text, 'String');
    str{2,1} = ['record ', num2str(c), ' of ',...
        num2str(length(cansel))];
    set(handles.addit_text, 'String', str);
    drawnow

    if isempty(handles.db(s).ICA.icaweights)
        EEG = recoverEEG(handles.db, s, 'local');
        % good channels:
        allchan = 1:size(EEG.data,1);
        allchan(handles.db(s).chan.bad) = [];

        %ICA
        EEG = pop_runica(EEG, 'extended', 1, 'interupt',...
            'off', 'verbose', 'on', 'chanind', allchan);

        % apply weights
        handles.db = db_addw(handles.db, s, EEG);

        % Update handles structure
        guidata(hObject, handles);
    end
end
end

% update text display
set(handles.addit_text, 'String', {'Done!'});
drawnow

% Update handles structure
guidata(hObject, handles);

% refresh GUI
db_gui_refresh(handles);



% --- Executes on button press in save2file.
function save2file_Callback(hObject, eventdata, handles)

% CHANGE - quick fix for profile handling
if ischar(handles.structpath)
    handles.savepath = handles.structpath;
    handles.structpath = true;
end

if ~handles.structpath && ~femp(handles, 'savepath')
    savepath = uigetdir('', 'Where would you like to save the structure?');
    if savepath
        handles.savepath = savepath;
        handles.structpath = true;
        test_profile(handles, 'update');
    end
end

if femp(handles, 'savepath')
    db = handles.db; %#ok<NASGU>

    time = gettime('full');
    time1 = regexprep(time, ':', '.');
    time2 = regexp(time, '[0-9]{2}:[0-9]{2}:[0-9]{2}',...
        'match', 'once');
    save(fullfile(handles.savepath, ['db ', time1, '.mat']), 'db');
    set(handles.savingstruct, 'String', ['Saved (', time2 , ')'] );
end

guidata(hObject, handles);


% --------------------------------------------------------------------
function opts_Callback(hObject, eventdata, handles)
% hObject    handle to opts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% [~] OPTION MENUs
function recover_opts_Callback(hObject, eventdata, handles)
% hObject    handle to recover_opts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
args = {'interp', 'ICAnorem', 'prerej', 'nofilter'};

if ~isempty(handles.recovopts)
    args = [args, 'clear options'];
end

addopt = gui_chooselist(args, 'text', {'Select additional', 'options'});
add = args(addopt);

if ~isempty(add)
    if strcmp('clear options', add)
        handles.recovopts=cell(1);
    else
        handles.recovopts=add;
    end
end
guidata(hObject, handles);

% --------------------------------------------------------------------
function coolplo_opt_Callback(hObject, eventdata, handles)

h = guidata(hObject);

hs = gui_multiedit('Plotting options', ...
    {'plotter', 'electrode colors', 'show this many epochs',...
    'plot bad channels in', 'line smoothing'},...
    {'eegplot', 'select colors', '4', 'ba�watkowy', 'on'});

% ============
% plotter type
opts = {'eegplot'; 'fastplot'};
val = find(strcmp(h.plotopts.plotter, opts));
set(hs.edit(1), 'style', 'popupmenu', ...
    'string', opts, ...
    'value', val);

% ================
% electrode colors
set(hs.edit(2), 'userdata', h.plotopts.ecol);
set(hs.edit(2), 'callback', ...
    @(obj, evnt) plot_opt_fun(hs),...
    'style', 'pushbutton');

% ====================
% num epochs displayed
set(hs.edit(3), 'string', h.plotopts.winlen);

val = 1;
coldef = h.plotopts.badplot;

if isnumeric(coldef)
    val = 2;
elseif ischar(coldef)
    tovar = {'grey'; ''; 'plot'; 'hide'};
    val = find(strcmp(coldef, tovar));

    if isempty(val) || val == 2
        val = 1;
        coldef = 'grey';
    end
    clear tovar
end

set(hs.edit(4), 'userdata', coldef);
set(hs.edit(4), 'callback', @badplot_callback,...
    'style', 'popupmenu', 'string', {'grey'; ...
    'specific color'; 'normal'; 'do not plot'},...
    'value', val);

% =============
% linesmoothing

tovar = {'on'; 'off'};
val = find(strcmp(h.plotopts.lsmo, tovar));

set(hs.edit(5), 'userdata', h.plotopts.lsmo);
thish = hs.edit(5);
set(hs.edit(5), 'callback', ...
    @(obj, evnt) some_other_callback(thish), ...
    'style', 'popupmenu', ...
    'string', {'on'; 'off'}, 'value', val);
clear hnd coldef epdef coldefadr epdefadr


% =======================
% OK and CANCEL Callbacks
set(hs.ok, 'Callback', {@coolopt, hObject, hs});
thish = hs.hf;
set(hs.cancel, 'Callback', @(o, e) myclosefun(thish));

% function dealing with how to plot badchans:
function badplot_callback(h, e)

val = get(h, 'value');
if val == 2
    set(h, 'userdata', uisetcolor);
    return
end

tovar = {'grey'; ''; 'plot'; 'hide'};
set(h, 'userdata', tovar{val});


% callback function for Cooleegplot options
function coolopt(h, e, hobj, hwin) %#ok<INUSL>

h = guidata(hobj);
prevopts = h.plotopts;
str = get(hwin.edit(1), 'String');
h.plotopts.plotter = str(get(hwin.edit(1), 'value'));

cols = get(hwin.edit(2), 'userdata');
if ~isempty(cols)
    h.plotopts.ecol = cols;
else
    h.plotopts.ecol = 'off';
end

winl = get(hwin.edit(3), 'String');
if ~isempty(winl)
    h.plotopts.winlen = str2double(winl);
end

% bad channel plot:
badpl = get(hwin.edit(4), 'userdata');
if ~isempty(badpl)
    h.plotopts.badplot = badpl;
end

smo = get(hwin.edit(5), 'userdata');
if ~isempty(smo)
    h.plotopts.lsmo = smo;
end

guidata(hobj,h);

% save profile if changes have been made:
if ~isequal(prevopts, h.plotopts)
    test_profile(h, 'update');
end
delete(hwin.hf);


% ====PROFILE=====
function handles = test_profile(handles, opt)
% tests whether:
% (1) when 'opt' == 'load':
%     - whether an option profile is present in the workspace
% (2) when 'opt' == 'update'
%     - whether the option profile has changed

switch opt
    case 'load'
        % testing whether there already is a profile in the workspace
        is_base_profile = evalin('base', ['exist(''db_winrej_current_profile''',...
            ', ''var'');']);

        if is_base_profile
            base_profile = evalin('base', 'db_winrej_current_profile;');
        end

        if is_base_profile

            % use the profile from workspace
            flds = fields(base_profile);

            for f = 1:length(flds)
                if strcmp('plotopts', flds{f})
                    base_plotopts = fields(base_profile.(flds{f}));
                    for ff = 1:length(base_plotopts)
                        thisfield = base_plotopts{ff};
                        handles.(flds{f}).(thisfield) = ...
                            base_profile.(flds{f}).(thisfield);
                    end
                elseif strcmp('savepath', flds{f})
                    handles.structpath = base_profile.(flds{f});
                else
                    handles.(flds{f}) = base_profile.(flds{f});
                end
            end
            guidata(handles.figure1, handles);
        else
            % the default settings have already been set:

        end

    case 'update'
        % updating profile

        profile = [];
        if ~isempty(handles.plotopts)
            profile.plotopts = handles.plotopts;
        end

        if isfield(handles, 'savepath') && ~isempty(handles.savepath)
            profile.savepath = handles.savepath;
        end

        % save profile to workspace
        assignin('base', 'db_winrej_current_profile',...
            profile);
end


% --------------------------------------------------------------------
function clearica_Callback(hObject, eventdata, handles)
% clearing ica weights for given record

% get guidata:
h = guidata(hObject);

% ask if user is sure:
choice = questdlg({'Are you sure you want to clear the ICA weights?'}, ...
                   'Are you sure?', 'Yes', 'No', 'No');

% if they are not sure, do not proceed:
if strcmp(choice, 'No')
    return
end

% clear ICA weights:
h.db = db_clearica(h.db, h.r);
guidata(h.figure1, h);

% refresh GUI:
db_gui_refresh(h);


function plot_opt_fun(h)

colol = selcol_GUI;
set(h.edit(2), 'userdata', colol);

function some_other_callback(hnd)

st = get(hnd, 'string');
vl = get(hnd, 'value');
set(hnd, 'userdata', st{vl});

function myclosefun(h)

close(h);
