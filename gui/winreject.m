function varargout = winreject(varargin)

% WINREJECT - GUI that allows for basic operations on db.`
%             Adding notes, marking epochs in different ways
%             as well as listing bad channels is easy with
%             winreject GUI. It is also possible to create
%             multiple versions of a given db record and
%             perform ICA for each of these versions (to
%             compare later)
%
%  use as:
%      db = WINREJECT(db);
%  or:
%      db = WINREJECT(db, r)
%                where r is a positive integer
%                to start exploring db structure from r register
%
% CHANGE - see also should be updated
% See also: GUIDE, GUIDATA, GUIHANDLES

% TODOs:
% [ ] resolve removed marks but no recover bug
% [ ] delete current version from versions field
%     when saving or closing winreject? This would
%     save some memory... (!)
% [ ] universal mechanism for mark types:
%         - [X] adding user-defined types
%         - [X] name field that defines how the
%               mark type should be displayed
%         - [ ] check regular rejection types
%               in EEG.reject
%         - [ ] universal adding rejection types
%               in recoverEEG and cooleegplot
% [ ] multisel working on multiple versions too (?) - 
%     does work for ICA but not yet for other options 
% [ ] ...

% Last Modified by GUIDE v2.5 27-Aug-2014 16:41:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @winreject_OpeningFcn, ...
    'gui_OutputFcn',  @winreject_OutputFcn, ...
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


% --- Executes just before winreject is made visible.
function winreject_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to winreject (see VARARGIN)

% Choose default command line output for winreject
handles.output = hObject;
handles.UniOrig = get(0, 'Units');

% CHECK
% why are the lines below commented out?
% why setting figure1 to visible if units are not pixels?
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
% [ ] organize handles into neat
% structures and sub-structures
% so that it's easiest to add
% profile use later on
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
handles.cooleegopts = {'ecol', 'off', 'winlen', 3, 'badplot', 'grey', ...
    'lsmo', 'on'};
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
set(handles.figure1, 'WindowKeyPressFcn', @winrej_buttonpress);

% Update handles structure
guidata(hObject, handles);

% ===PROFILE========================
% try to load profile if one exists:
handles = test_profile(handles, 'load');

% Refresh GUI:
winreject_refresh(handles);

% UIWAIT makes winreject wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = winreject_OutputFcn(hObject, eventdata, handles)

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
    
    % just to be sure - update version
    currf = handles.db(handles.r).versions.current;
    handles.db = db_updateversion(handles.db, handles.r, currf);
    
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
        handles.EEG = recoverEEG(handles.db, handles.r, 'local', handles.recovopts{:});
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
        winreject_refresh(handles);
    end
    
    % disable plotting
    set(hObject, 'Enable', 'off');
    
    % ADD warining if removed is filled and
    % userrem or autorem too ?
    
    % clear base workspace
    evalin('base', 'clear TMPREJ TMPNEWREJ');
    
    % display badelectrodes according to options
    badchadr = find(strcmp('badchan', handles.cooleegopts));
    if ~isempty(badchadr)
        handles.cooleegopts{badchadr + 1} = handles.db(handles.r)...
            .chan.bad;
    else
        if ~isempty(handles.db(handles.r).chan.bad)
            handles.cooleegopts = [handles.cooleegopts, 'badchan', ...
                handles.db(handles.r).chan.bad];
        else
            handles.cooleegopts = [handles.cooleegopts, 'badchan'];
            handles.cooleegopts{end + 1} = [];
        end
    end
    
    
    %     if ~femp(handles, 'recovopts') || (femp(handles, 'recovopts')...
    %             && sum(strcmp('interp', handles.recovopts)) == 0)
    %     goodel(handles.db(handles.r).badchan) = [];
    %     end
    
    % get rejections from cooleegplot
    if isempty(handles.cooleegopts)
        TMPREJ = cooleegplot(handles.EEG, handles.db, ...
            handles.r, 'update', false);
    else
        TMPREJ = cooleegplot(handles.EEG, handles.db, ...
            handles.r, 'update', ...
            false, handles.cooleegopts{:});
    end
    
    % CHECK db_newrejtype - and think about
    %       whether it is of final form or only
    %       a temporary solution (kind of slow...)
    %
    % get additional rejections set in eegplot2
    handles.db = db_newrejtype(handles.db,...
        []);
    
    % Update handles structure
    guidata(hObject, handles);
    
    if ~isempty(TMPREJ)
        % get current handles
        handles = guidata(hObject);
        
        if ~exist('rEEG', 'var')
            rEEG = handles.rEEG;
        end
        
        % CHANGE FIXME
        % update rejections
        [handles.db, handles.EEG] = db_rejTMP(handles.db,...
            rEEG, handles.EEG, TMPREJ);
        
        % Update handles structure
        guidata(hObject, handles);
        
        % remove TMPREJ from base workspace
        if evalin('base', 'exist(''TMPREJ'', ''var'');')
            evalin('base', 'clear TMPREJ');
        end
    end
    
    % enable plotting
    set(hObject, 'Enable', 'on');
    
    % Refresh GUI:
    winreject_refresh(handles);
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
    winreject_refresh(handles);
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
    winreject_refresh(handles);
end


% --- Executes on button press in prev_butt.
function prev_butt_Callback(hObject, eventdata, handles)

if handles.r > 1
    handles.r = handles.r - 1;
    
    % Update handles structure
    guidata(hObject, handles);
    
    % refresh
    winreject_refresh(handles);
end

%% [~] SLIDER
% --- Executes on slider movement.
function slider_Callback(hObject, eventdata, handles)

% CHANGE - winreject_refresh should be selective - what to
%          refresh
winreject_refresh(handles);

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
    str{2,1} = ['registry ', num2str(c), ' of ',...
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
rej = db_getrej(handles.db, handles.r, 'nonempt');
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
    
    % update versions
    for c = cansel(:)'
        % current version
        origcurrent_f = handles.db(c).versions.current;
        
        % update current
        handles.db = db_updateversion(handles.db, ...
            c, origcurrent_f);
    end
    
    % Update handles structure
    guidata(hObject, handles);
    
    % refresh
    winreject_refresh(handles);
    return
end

seltypes = rej.name(sel);

if ~isempty(seltypes)
    
    % apply rejections
    handles.db = db_applyrej(handles.db, cansel,...
        'byname', seltypes);
    
    % ADD - we need a function for mass update versions
    % update versions
    for c = cansel(:)'
        % current version
        origcurrent_f = handles.db(c).versions.current;
        
        % update current
        handles.db = db_updateversion(handles.db, ...
            c, origcurrent_f);
    end
    
    % Update handles structure
    guidata(hObject, handles);
    
    % refresh
    winreject_refresh(handles);
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

%% run ica
% for all versions and all selections that do not have ICA

% text update
set(handles.addit_text, 'String', {'computing ICA'});
drawnow;

for c = 1:length(cansel)
    s = cansel(c);
    
    % get versions:
    vers = db_getversions(handles.db, s);
    origcurrent_f = handles.db(s).versions.current;
    %origcurrent_n = handles.db(s).versions.(origcurrent_f).version_name;
    
    % update current
    handles.db = db_updateversion(handles.db, ...
        s, origcurrent_f);
    
    % update text display
    str = get(handles.addit_text, 'String');
    str{2,1} = ['registry ', num2str(c), ' of ',...
        num2str(length(cansel))];
    set(handles.addit_text, 'String', str);
    drawnow
    
    for v = 1:size(vers,1)
        strv = vers{v,2};
        %     fv = vers{v,1};
        
        % update text display
        str = get(handles.addit_text, 'String');
        str{3,1} = ['version ', num2str(v), ' of ',...
            num2str(size(vers, 1))];
        set(handles.addit_text, 'String', str);
        drawnow
        
        % recover the other
        handles.db = db_bringversion(handles.db, s, strv);
        
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
            
            % update current version
            handles.db = db_updateversion(handles.db, ...
                s, vers{v,1});
            
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
winreject_refresh(handles);

% --------------------------------------------------------------------
function vers_Callback(hObject, eventdata, handles)
% hObject    handle to vers (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function appvers_Callback(hObject, eventdata, handles)
% hObject    handle to appvers (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function movevers_Callback(hObject, eventdata, handles)

vn = gui_editbox('', {'Type version name'; 'here:'});
if ~isempty(vn)
    opt = handles.db(handles.r);
    opt.version_name = vn;
    handles.db = db_addversion(handles.db, handles.r, opt);
    
    % update handles
    guidata(hObject, handles);
    % refresh interface
    winreject_refresh(handles);
end

% --------------------------------------------------------------------
function creavers_Callback(hObject, eventdata, handles)
% hObject    handle to creavers (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in versions_pop.
function versions_pop_Callback(hObject, eventdata, handles)

strv = get(hObject,'String');
strv = strv{get(hObject,'Value')};

% if current selection is not == current, update current version
currf = handles.db(handles.r).versions.current;
curr = handles.db(handles.r).versions.(currf).version_name;
if ~strcmp(strv, curr)
    % update current
    handles.db = db_updateversion(handles.db, ...
        handles.r, currf);
    
    % recover the other
    handles.db = db_bringversion(handles.db, handles.r, strv);
    
    % refresh etc.
    guidata(hObject, handles);
    winreject_refresh(handles);
end
%

% --- Executes during object creation, after setting all properties.
function versions_pop_CreateFcn(hObject, eventdata, handles)
% hObject    handle to versions_pop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


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
    {'electrode colors', 'show this many epochs',...
    'plot bad channels in', 'line smoothing'},...
    {'select colors', '4', 'ba³watkowy', 'on'});

% ====================
% num epochs displayed

% CONSIDER - wrap the code below into one function
%            as it is repeated 3 times in this
%            function
epdefadr = find(strcmp('winlen', h.cooleegopts));
if ~isempty(epdefadr) && ~(epdefadr(1) > length(...
        h.cooleegopts))
    epdef = num2str(h.cooleegopts{epdefadr(1) + 1});
    if isempty(epdef)
        epdef = '3';
    end
else
    epdef = '3';
end

set(hs.edit(2), 'string', epdef);

% ================
% electrode colors
coldefadr = find(strcmp('ecol', h.cooleegopts));
if ~isempty(coldefadr) && ~(coldefadr(1) > length(...
        h.cooleegopts))
    coldef = h.cooleegopts{coldefadr(1) + 1};
else
    coldef = 'off';
end

set(hs.edit(1), 'userdata', coldef);
set(hs.edit(1), 'callback', ...
    @(obj, evnt) plot_opt_fun(hs),...
    'style', 'pushbutton');


coldefadr = find(strcmp('badplot', h.cooleegopts));
val = 1;
if ~isempty(coldefadr) && ~(coldefadr(1) > length(...
        h.cooleegopts))
    coldef = h.cooleegopts{coldefadr(1) + 1};
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
    else
        coldef = 'grey';
    end
    
else
    coldef = 'grey';
end

set(hs.edit(3), 'userdata', coldef);
set(hs.edit(3), 'callback', @badplot_callback,...
    'style', 'popupmenu', 'string', {'grey'; ...
    'specific color'; 'normal'; 'do not plot'},...
    'value', val);

% =============
% linesmoothing

coldefadr = find(strcmp('lsmo', h.cooleegopts));
val = 1;
if ~isempty(coldefadr) && ~(coldefadr(1) > length(...
        h.cooleegopts))
    coldef = h.cooleegopts{coldefadr(1) + 1};
        
    if ischar(coldef)
        tovar = {'on'; 'off'};
        val = find(strcmp(coldef, tovar));
        
        if isempty(val)
            val = 1;
            coldef = 'on';
        end
        
        clear tovar
    else
        coldef = 'on';
    end
    
else
    coldef = 'on';
end

set(hs.edit(4), 'userdata', coldef);
thish = hs.edit(4);
set(hs.edit(4), 'callback', ...
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

hgui = guidata(hobj);
prevopts = hgui.cooleegopts;

cols = get(hwin.edit(1), 'userdata');
if ~isempty(cols)
    hgui.cooleegopts = {'ecol', cols};
else
    hgui.cooleegopts = {'ecol', 'off'};
end

winl = get(hwin.edit(2), 'String');
if ~isempty(winl)
    if isempty(hgui.cooleegopts)
        hgui.cooleegopts = {'winlen', str2double(winl)};
    else
        hgui.cooleegopts = [hgui.cooleegopts, 'winlen', str2double(winl)];
    end
end

% bad channel plot:
badpl = get(hwin.edit(3), 'userdata');
if ~isempty(badpl)
    if isempty(hgui.cooleegopts)
        hgui.cooleegopts = {'badplot', badpl};
    else
        hgui.cooleegopts = [hgui.cooleegopts, 'badplot', badpl];
    end
end

smo = get(hwin.edit(4), 'userdata');
if ~isempty(smo)
    if isempty(hgui.cooleegopts)
        hgui.cooleegopts = {'lsmo', smo};
    else
        hgui.cooleegopts = [hgui.cooleegopts, 'lsmo', smo];
    end
end

guidata(hobj,hgui);

% save profile if changes have been made:
if ~isequal(prevopts, hgui.cooleegopts)
    test_profile(hgui, 'update');
end
delete(hwin.hf);


% --------------------------------------------------------------------
function manage_versions_Callback(hObject, eventdata, handles)
% hObject    handle to manage_versions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

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
                if ~strcmp('savepath', flds{f})
                    handles.(flds{f}) = base_profile.(flds{f});
                else
                    handles.structpath = base_profile.(flds{f});
                end
            end
            guidata(handles.figure1, handles);
        else
            % the default settings have already been set:
            
        end
        
    case 'update'
        % updating profile
        
        profile = [];
        if ~isempty(handles.cooleegopts)
            profile.cooleegopts = handles.cooleegopts;
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
% clearing ica weights for given version

% get guidata:
h = guidata(hObject);

% check if multiple versions:
f = db_checkfields(h.db(h.r).versions, 1, {}, 'ignore', ...
    {'current'});
nver = length(f.fields);
drawnow;

if nver < 2
    % if only one version present - ask if user is sure:
    choice = questdlg({'Only one version present. Are you sure you'; ...
        ' want to clear the ICA weights?'}, 'Are you sure?', 'Yes', ...
        'No', 'No');
    
    % if they are not sure, do not proceed:
    if strcmp(choice, 'No')
        return
    end
end

% clear ICA weights:
h.db = db_clearica(h.db, h.r);
guidata(h.figure1, h);

% refresh GUI:
winreject_refresh(h);

function plot_opt_fun(h)

colol = selcol_GUI; 
set(h.edit(1), 'userdata', colol);

function some_other_callback(hnd)

st = get(hnd, 'string'); 
vl = get(hnd, 'value'); 
set(hnd, 'userdata', st{vl});

function myclosefun(h)

close(h);