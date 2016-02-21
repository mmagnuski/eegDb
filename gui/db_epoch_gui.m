function varargout = db_epoch_gui(varargin)

% NOHELPINFO
% DB_EPOCH_GUI
%
% See also: GUIDE, GUIDATA, GUIh

% Last Modified by GUIDE v2.5 06-Jun-2015 17:45:16

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @db_epoch_gui_OpeningFcn, ...
    'gui_OutputFcn',  @db_epoch_gui_OutputFcn, ...
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


% TODOs:
% [ ] check close etc behavior
% 
% [ ] LATER - block pushbutton from going to indices
% [ ] is indices pushbutton useful? not very much when
%     multiple files are used...
% [ ] permit passing r range...
% [ ] eventpatternsearch <-- !
% [ ] conditions !
% [ ] usage of segment option...
% [ ] progress bar 'scanning events' ?

% --- just before db_epoch_gui is made visible.
function db_epoch_gui_OpeningFcn(hObject, eventdata, h, varargin) %#ok<*INUSL>
% varargin - command line arguments to db_epoch_gui (see VARARGIN)

% Choose default command line output for db_epoch_gui
h.output = hObject;

% set which h belong to which parts
h.under_onesec = [h.winlen_text, h.winlen_box, h.eventname_text,...
    h.eventname_box, h.winsel_check];
h.under_winsel = [h.add_button, h.remove_button,...
    h.eventpattern_button, h.pop_winsel, h.conditions_button,...
    h.event_list, h.typeind_toggle, h.distance_text, h.distance_box];
h.under_epoch = [h.pre_text, h.pre_box, h.post_text, ...
    h.post_box, h.event_list, h.typeind_toggle];

% requires at least one input argument
if isempty(varargin)
    error('This function requires db database as input');
end

h.db = varargin{1};

if length(varargin) < 2
    h.r = 1;
else
    h.r = varargin{2};
end

% inform user in command window:
disp('Scanning files for event types.');

% the default is to choose one random r:
r_check = h.r(randperm(length(h.r), 1));

% CHANGE - this is often used - should be a separate
%          function...
% find correct dir:
corr_dir = [];
if iscell(h.db(r_check).filepath)
    for dr = 1:length(h.db(r_check).filepath)
        if isdir(h.db(r_check).filepath{dr})
            corr_dir = h.db(r_check).filepath{dr};
        end
    end
else
    corr_dir = h.db(r_check).filepath;
end

ld = load([corr_dir, h.db(r_check).filename], '-mat');
EEG = ld.EEG;

% when segmenting is used no events are
% needed
if femp(EEG, 'event') && femp(EEG.event(1), 'type')
    if ~isnumeric(EEG.event(1).type)
    h.event_types = unique({EEG.event.type})';
    else
        h.event_types = unique([EEG.event.type]);
        h.event_types = arrayfun(@num2str, h.event_types, ...
            'UniformOutput', false);
    end  
else
    h.event_types = {};
end

h.event_num = length(EEG.event);
h.event_stream = EEG.event;

% refresh event list:
evlst = get(h.event_list, 'String');

if ~iscell(evlst)
    evlst = {evlst};
end
if size(h.event_types, 2) > 1
    h.event_types = h.event_types';
end
evlst = [evlst; h.event_types];
set(h.event_list, 'String', evlst);
set(h.event_list, 'Value', 1);
set(h.event_list, 'Max', length(evlst));

% add other fields:
h.onesecopts = {};
h.epochopts = [];
h.dropdown_last = 1;
set(h.pop_winsel, 'String', {'Nothing'});

% Update h structure
guidata(hObject, h);

% get active settings from db:
prev_settings(h, r_check);

% UIWAIT makes db_epoch_gui wait for user response (see UIRESUME)
uiwait(h.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = db_epoch_gui_OutputFcn(hObject, eventdata, h)

% h    structure with handles and user data (see GUIDATA)

% Get default command line output from h structure
if ~isempty(h) && ishandle(h.figure1)
    h = guidata(h.figure1);
    close(h.figure1);
    varargout{1} = h.output;
end

% ================================
% [~] reading in previous settings
function prev_settings(h, r)

% ====================
% check epoch options:
if femp(h.db(r), 'epoch') && femp(h.db(r).epoch, 'events')
    if iscell(h.db(r).epoch.events)
        
        % CHECK - set list with event types!
        update_event_list(h, h.db(r).epoch.events);
    elseif isnumeric(h.db(r).epoch.events)
        % what to do in such case?
        % toggle button for types/indices ?
        set(h.typeind_toggle, 'Value', 0);
        
        % update button etc.
        typeind_toggle_Callback(h.typeind_toggle, [], h);
        % update list to numeric values of epoch_events:
        set(h.event_list, 'Value', h.db(r).epoch.events);
        set(h.event_list, 'ListBoxTop', h.db(r).epoch.events(1));
    end
    
    set(h.check_epoch, 'Value', 1);
    check_epoch_Callback([], [], h);
    
end

if femp(h.db(r), 'epoch_limits')
    set(h.pre_box, 'String', num2str(-1 * h.db(r).epoch.limits(1)));
    set(h.post_box, 'String', num2str(h.db(r).epoch.limits(2)));
    
    set(h.check_epoch, 'Value', 1);
    check_epoch_Callback([], [], h);
end

% =====================
% check onesec options:
if femp(h.db(r), 'epoch') && femp(h.db(r).epoch, 'locked') && ...
        ~h.db(r).epoch.locked
        
        % ADD - else default options?
        % check 'winlen':
        if femp(h.db(r).epoch, 'winlen')
            val = h.db(r).epoch.winlen;
            val = num2str(val);
            set(h.winlen_box, 'String', val);
        end
        
        % check 'eventname':
        if femp(h.db(r).epoch, 'eventname')
            val = h.db(r).epoch.eventname;
            set(h.eventname_box, 'String', val);
        end
        
        % check 'distance':
        if femp(h.db(r).epoch, 'distance')
            % ADD
        end
end

% ================================
% [~] updating list of events
function update_event_list(h, evnt)

% set these:
ev_len = length(evnt);
newval = zeros(ev_len, 1);
couldnot = false;

for ev = 1:ev_len
    fnd_adr = find(strcmp(evnt{ev}, get(h.event_list, 'String')));
    
    
    if fnd_adr
        newval(ev) = fnd_adr;
    else
        if ~couldnot
        disp('Cold not find event of type:');
        couldnot = true;
        end
        
        disp(evnt{ev});
    end
    
    
end
clear couldnot

newval = newval(newval > 0);

% set these values:
set(h.event_list, 'Value', newval);

% --- Executes on button press in check_onesec.
function check_onesec_Callback(hObject, eventdata, h)
%
h = guidata(h.figure1);

if get(h.check_onesec, 'Value') == 1
    
    % turn off the other box:
    set(h.check_epoch, 'Value', 0);
    
    % check selected epochs and save in
    % h.epochopts
    h.epochopts = get(h.event_list, 'Value'); 
    
    % disable certain fields:
    set(h.under_epoch, 'Enable', 'off');
    set(h.under_onesec, 'Enable', 'on');
    
    % check state of winsel check:
    winsel_check_Callback(h.winsel_check, [], h);
    
    % update guidata
    guidata(h.figure1, h);
else
    % if unblocked update winsel current option
    winsel_check_Callback(h.winsel_check, [], h);
    
    % turn on the other box:
    set(h.check_epoch, 'Value', 1);
    
    % disable certain fields:
    set(h.under_epoch, 'Enable', 'on');
    set(h.under_onesec, 'Enable', 'off');
    set(h.under_winsel, 'Enable', 'off');
    
    % enable event list:
    set(h.event_list, 'Enable', 'on');
    set(h.typeind_toggle, 'Enable', 'on');
    
    % refresh event list
    set(h.event_list, 'Value', h.epochopts);
end


% ------------
% setDist
function setDist(h, info)

% used for updating etc the list of distance
% options for onesecepoch

% h.typeind_toggle
    h = guidata(h.figure1);
    opts = h.onesecopts;
    val = get(h.pop_winsel, 'Value');
    str = get(h.pop_winsel, 'String');
    
    switch info
        case 'update' 
            if strcmp(str{val}, 'Nothing')
                return
            end
            
            % get events and distance from opts
            ev = opts{val,1};
            if ischar(ev)
                ev = {ev};
            end
            
            if length(ev) == 1 && isempty(ev{1})
                vl = 1;
            else
                evlst = get(h.event_list, 'String');
                vl = zeros(size(ev));
                for e = 1:length(ev)
                    vl(e) = find(strcmp(ev{e}, evlst));
                end
            end
            
            % highlight these events
            set(h.event_list, 'Value', vl);
            
            % get distance
            dist = opts{val, 2};
            set(h.distance_box, 'String', num2str(dist));
            
            h.dropdown_last = val;
            guidata(h.figure1, h);
            
        case 'modif'
            last = h.dropdown_last;
            
            if strcmp(str{last}, 'Nothing')
                return
            end
            
            opts{last,2} = str2num(get(h.distance_box, 'string'));
            evlst = get(h.event_list, 'String');
            ev_selected = get(h.event_list, 'Value');
            if ev_selected == 1
                opts{last,1} = [];
            else
                
                opts{last,1} = {evlst{ev_selected}}; %#ok<CCAT1>
            end
            
            h.onesecopts = opts;
            guidata(h.figure1, h);
            
        case 'remove'
            if strcmp(str{val}, 'Nothing')
                return
            end
            
            if size(opts, 1) == 1
                opts = [];
                set(h.pop_winsel, 'String', {'Nothing'});
                
            else
                opts(val,:) = [];
                evstr = get(h.pop_winsel, 'String');
                evstr(val) = [];
                set(h.pop_winsel, 'String', evstr);
            end
            
            set(h.pop_winsel, 'Value', 1);
            h.onesecopts = opts;
            h.dropdown_last = 1;
            guidata(h.figure1, h);
            setDist(h, 'update');
            
        case 'add'
            if strcmp(str{val}, 'Nothing')
                set(h.pop_winsel, 'String', {'1'});
                set(h.pop_winsel, 'Value', 1);
                opts = cell(1,2);
                h.dropdown_last = 1;
                h.onesecopts = opts;
                guidata(h.figure1, h);
                setDist(h, 'modif');
            else
                
                optlst = get(h.pop_winsel, 'String');
                len = length(optlst) + 1;
                optlst{end+1} = num2str(len);
                set(h.pop_winsel, 'String', optlst);
                set(h.pop_winsel, 'Value', len);
                opts{len,1} = [];
                
                % use modify
                h.dropdown_last = len;
                h.onesecopts = opts;
                guidata(h.figure1, h);
                setDist(h, 'modif');
            end
    end
            

% -------------------
% --- check_epoch ---
function check_epoch_Callback(hObject, eventdata, h) %#ok<*DEFNU>

%
if get(h.check_epoch, 'Value') == 1
    
    % turn off the other box:
    set(h.check_onesec, 'Value', 0);
    
else
    
    % turn on the other box:
    set(h.check_onesec, 'Value', 1);
    
end

% run the other function:
check_onesec_Callback([], [], h);


function winlen_box_Callback(hObject, eventdata, h) %#ok<*INUSD>

% Hints: get(hObject,'String') returns contents of winlen_box as text
%        str2double(get(hObject,'String')) returns contents of winlen_box as a double


% --- Executes during object creation, after setting all properties.
function winlen_box_CreateFcn(hObject, eventdata, h)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in event_list.
function event_list_Callback(hObject, eventdata, h)

% Hints: contents = cellstr(get(hObject,'String')) returns event_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from event_list


% --- Executes during object creation, after setting all properties.
function event_list_CreateFcn(hObject, eventdata, h)

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function eventname_box_Callback(hObject, eventdata, h)

% Hints: get(hObject,'String') returns contents of eventname_box as text
%        str2double(get(hObject,'String')) returns contents of eventname_box as a double


% --- Executes during object creation, after setting all properties.
function eventname_box_CreateFcn(hObject, eventdata, h)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in winsel_check.
function winsel_check_Callback(hObject, eventdata, h)

if get(h.winsel_check, 'Value') == 1
    
    % enable:
    set(h.under_winsel, 'Enable', 'on');
    
    % update
    setDist(h, 'update');
    
else
    % if changes made:
    setDist(h, 'modif');
    
    % disable:
    set(h.under_winsel, 'Enable', 'off');
    
end




function pre_box_Callback(hObject, eventdata, h)

% Hints: get(hObject,'String') returns contents of pre_box as text
%        str2double(get(hObject,'String')) returns contents of pre_box as a double


% --- Executes during object creation, after setting all properties.
function pre_box_CreateFcn(hObject, eventdata, h)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function post_box_Callback(hObject, eventdata, h)

% Hints: get(hObject,'String') returns contents of post_box as text
%        str2double(get(hObject,'String')) returns contents of post_box as a double


% --- Executes during object creation, after setting all properties.
function post_box_CreateFcn(hObject, eventdata, h)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function distance_box_Callback(hObject, eventdata, h)
% changes distance option for onesecepoch

% --- Executes during object creation, after setting all properties.
function distance_box_CreateFcn(hObject, eventdata, h)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in add_button.
function add_button_Callback(hObject, eventdata, h)
setDist(h, 'add');

% --- Executes on button press in remove_button.
function remove_button_Callback(hObject, eventdata, h)
setDist(h, 'remove');


% --- Executes on selection change in pop_winsel.
function pop_winsel_Callback(hObject, eventdata, h)
setDist(h, 'modif');
setDist(h, 'update');

% Hints: contents = cellstr(get(hObject,'String')) returns pop_winsel contents as cell array
%        contents{get(hObject,'Value')} returns selected item from pop_winsel


% --- Executes during object creation, after setting all properties.
function pop_winsel_CreateFcn(hObject, eventdata, h)

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in eventpattern_button.
function eventpattern_button_Callback(hObject, eventdata, h)


% --- Executes on button press in conditions_button.
function conditions_button_Callback(hObject, eventdata, h)

% ===============================
% [~] Toggling types and indices:
% --- Executes on button press in typeind_toggle.
function typeind_toggle_Callback(h1, eventdata, h)
% h1 - h.typeind_toggle

vl = get(h1, 'Value');

if vl == 0
    set(h1, 'String', 'types');
    
    % get prevset:
    prevset = get(h.event_list, 'Value');
    newstr = [{'any event'}; h.event_types(:)];
    
    if isempty(prevset) || isempty(h.event_stream)
        newset = [];
    else
        newit = unique({h.event_stream(prevset).type});
        ind = cell(1, length(newit));
        
        for it = 1:length(newit)
            ind{it} = find(strcmp(newit{it}, newstr));
        end
        
        newset = [ind{:}];
        
    end
    
    % in case only 'any event' is present
    if length(newstr) == 1
        newset = 1;
    end
    
    
    set(h.event_list, 'Value', newset);
    set(h.event_list, 'String', newstr);
    
    set(h.event_list, 'Max', length(newstr));
    if ~isempty(newset)
        set(h.event_list, 'ListBoxTop', newset(1));
    end
    
else
    set(h1, 'String', 'indices');
    
    % get prevset:
    prevset = get(h.event_list, 'Value');
    
    if isempty(prevset)
        newset = [];
    elseif prevset == 1
        newset = 1:h.event_num;
    else
        % set inds of specific event types:
        % ADD
        
        previt = get(h.event_list, 'String');
        itms = previt(prevset);
        
        % look for indices of these:
        ind = cell(1, length(itms));
        
        for it = 1:length(itms)
            ind{it} = find(strcmp(itms{it}, {h.event_stream.type}));
        end
        
        newset = [ind{:}];
    end
    
    % modify event_list
    if h.event_num > 0
        newstr = 1:h.event_num;
    else
        newstr = {};
    end
    set(h.event_list, 'String', newstr);
    set(h.event_list, 'Value', newset);
    set(h.event_list, 'Max', length(newstr));
    if ~isempty(newset)
        set(h.event_list, 'ListBoxTop', newset(1));
    end
    
end


% --- Executes on button press in OK_button.
function OK_button_Callback(hObject, eventdata, h)
% if user presses OK - return db structure
opts = [];
h = guidata(h.figure1);

% check if classical epoching chosen:
if get(h.check_epoch, 'Value') == 1
    
    % epoch events
    evlst = get(h.event_list, 'String');
    chosen_evnts = get(h.event_list, 'Value');
    opts.epoch.locked = true;

    if ismember(1, chosen_evnts)
        opts.epoch.events = evlst(2:end);
    else
        opts.epoch.events = evlst(chosen_evnts);
    end
    
    % epoch limits
    opts.epoch.limits = [-1 * str2num(get(h.pre_box, 'String')), ...
        str2num(get(h.post_box, 'String'))];

    % clear onesec opts
    opts.epoch.eventname = [];
    opts.epoch.winlen    = [];
    opts.epoch.distance  = [];
    
else
    % onesec is chosen, check whether distance defined
    opts.epoch.locked = false;

    if get(h.winsel_check, 'Value') == 1
        opts.epoch.distance = h.onesecopts;
    end
    % add normal onesec options
    opts.epoch.eventname = get(h.eventname_box, 'String');
    opts.epoch.winlen = str2num(get(h.winlen_box, 'String')); %#ok<*ST2NM>
    opts.epoch.limits = [];
    opts.epoch.events = [];
end
h.db = db_copybase(h.db, opts);
h.output = h.db;
guidata(h.figure1, h);
uiresume(h.figure1);


% Hint: get(hObject,'Value') returns toggle state of OK_button


% --- Executes on button press in cancel_button.
function cancel_button_Callback(hObject, eventdata, h)
h = guidata(h.figure1);
h.output = [];
uiresume(h.figure1);

% Hint: get(hObject,'Value') returns toggle state of cancel_button
