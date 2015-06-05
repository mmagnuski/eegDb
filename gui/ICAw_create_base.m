function varargout = db_create_base(varargin)

% db_CREATE_BASE - GUI for creating eegDb database
% The same can be performed using specific calls
% to functions like db_buildbase etc.
% FIXHELPINFO

% Last Modified by GUIDE v2.5 24-May-2014 17:54:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @db_create_base_OpeningFcn, ...
                   'gui_OutputFcn',  @db_create_base_OutputFcn, ...
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
% [ ] add additional parameters (like filepath)
%     that can narrow GUI usage
% [ ] add choose by rule

% --- Executes just before db_create_base is made visible.
function db_create_base_OpeningFcn(hObject, ~, handles, varargin)
% This function has no output args, see OutputFcn.

% Choose default command line output for db_create_base
handles.output = [];
handles.path = [];
handles.GoodToGo = false;
handles.CorrectPath = false;
handles.ChosenFiles = [];
handles.ChooseFilesMethod = 'all';
handles.PassFilt = [];
handles.StopFilt = [];

handles.cancel = false;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes db_create_base wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = db_create_base_OutputFcn(a, b, handles)  %#ok<INUSL>
% varargout  cell array for returning output args (see VARARGOUT);

% Get default command line output from handles structure
if nargout > 0
    varargout{1} = handles.output;
else
    % save db with such a name that it 
    % does not overwrite any user db in the 
    % base workspace
    anybase = evalin('base', 'who');
    
    name = 'db';
    
    if sum(strcmp(name, anybase)) > 0
        % db is present, add postfix
        num = 1; WouldOverwrite = true;
        
        while WouldOverwrite
            num = num + 1;
            postfx = num2str(num);
            newname = [name, postfx];
            
            WouldOverwrite = sum(strcmp(...
                newname, anybase)) > 0;
        end
        
        name = newname;
    end
    
    if isstruct(handles)
        assignin('base', name, handles.output);
        close(handles.figure1);
    end
    
end


function EnterPath_Callback(~,~,h)
%  check if this is a correct path
CheckPathCorrect(h.figure1)


% -----------
% check PATH CORRECTNESS 
% and files presence
function CheckPathCorrect(hfig)
% check path correctness

h = guidata(hfig);
strPth = get(h.EnterPath, 'String');
CorrectDir = isdir(strPth);

if ~CorrectDir
    set(h.EnterPath, 'ForegroundColor', 'r');
    set(h.EnterPath, 'ToolTip', 'Incorrect path');
    set(h.ChooseByHand, 'Enable', 'off');
    h.CorrectPath = false;
else
    set(h.EnterPath, 'ForegroundColor', [0.2, 0.75, 0.4]);
    set(h.EnterPath, 'ToolTip', 'Correct path');
    set(h.ChooseByHand, 'Enable', 'on');
    h.CorrectPath = true;
    
    % check if set files are present
    % LATER ADD - checking for rules!
    if strcmp(h.ChooseFilesMethod, 'all')
        flist = dir(fullfile(strPth, '*.set'));
    else
        flist = h.ChosenFiles;
    end
    
    if isempty(h.ChooseFilesMethod) || isempty(flist)
        set(h.EnterPath, 'ToolTip', 'Correct path but no files chosen');
        set(h.EnterPath, 'ForegroundColor', 'r');
        h.ChosenFiles = [];
    else
        set(h.EnterPath, 'ToolTip', 'Correct path and files chosen');
        set(h.EpochOpt, 'Enable', 'on');
        h.ChosenFiles = flist;
    end
end

% update guidata
guidata(hfig, h);


% -----------
% check BANDs CORRECTNESS
function CheckBands(hObject)
% Check if band is ok
str = get(hObject, 'String');
numb = str2num(str); %#ok<ST2NM>

if ~(length(numb) == 2) || sum(numb < 0) > 0
    set(hObject, 'ForegroundColor', 'r');
else
    % other checks?
    if sum(numb == 0) == 0
        numb = sort(numb);
    end
    set(hObject, 'String', num2str(numb));
    set(hObject, 'ForegroundColor', [0.2, 0.75, 0.4]);
    
    objtag = get(hObject, 'Tag');
    h = guidata(hObject);
    switch objtag
        case 'PassBand'
            h.PassFilt = numb;
        case 'StopBand'
            h.StopFilt = numb;
    end
    guidata(hObject, h);
end



% --- Executes during object creation, after setting all properties.
function EnterPath_CreateFcn(hObject, ~, ~)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in BrowseButton.
function BrowseButton_Callback(~, ~, h)
% 
h = guidata(h.figure1);
if femp(h, 'path')
    prev_path = h.path;
else
    prev_path = '';
end

% get path through uigetdir
getpath = uigetdir(prev_path, ...
    'Where are your files located?');

if ~isnumeric(getpath) && ~isempty(getpath)
    % set handles path
    h.path = getpath;
    set(h.EnterPath, 'String', getpath);
    guidata(h.figure1, h);
end
CheckPathCorrect(h.figure1);



% --- Executes on button press in ChooseAllFiles.
function ChooseAllFiles_Callback(hOb, ~, h)

val = get(hOb, 'Value');
h = guidata(h.figure1);
if val == 0
    h.ChooseFilesMethod = '';
else
    h.ChooseFilesMethod = 'all';
    h.ChosenFiles = [];
end

% update guidata and perform path/files checks
guidata(h.figure1, h);
CheckPathCorrect(h.figure1);



% ------------
% ChooseByHand
function ChooseByHand_Callback(~, ~, h) %#ok<*DEFNU>

h = guidata(h.figure1);
strPth = get(h.EnterPath, 'String');
flist = dir(fullfile(strPth, '*.set'));
flist = {flist.name};
[outp, ifcancel] = gui_chooselist(flist,...
    'text', 'Choose files');

% if we did not cancel - update
if ~ifcancel
    h.ChosenFiles = flist(outp);
    set(h.ChooseAllFiles, 'Value', 0);
    h.ChooseFilesMethod = 'hand';
    guidata(h.figure1, h);
    CheckPathCorrect(h.figure1);
end

% --- Executes on button press in ChooseByRule.
function ChooseByRule_Callback(hObject, eventdata, handles)
% ADD - this is not ready yet, but will be a nice addition

%--------
%PassBand
function PassBand_Callback(hObject, ~, ~)
% Check correctness of the input
CheckBands(hObject);

% --- Executes during object creation, after setting all properties.
function PassBand_CreateFcn(hObject, ~, ~)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function StopBand_Callback(hObject, ~, ~)
CheckBands(hObject);

% --- Executes during object creation, after setting all properties.
function StopBand_CreateFcn(hObject, eventdata, handles) %#ok<*INUSD>
% hObject    handle to StopBand (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in EpochOpt.
function EpochOpt_Callback(hObject, eventdata, h)

h = guidata(hObject);

% create a temporary eegDb base and pass it to 
% db_gui_epoch

[strPth, flist] = get_path_and_files(h);

eegDb_temp = struct('filepath', strPth, 'filename', flist);

% here ADD some code to fill this temp eegDb struct
% with epoch data present in 
if femp(h, 'eegDb')
    % add epoching options
    opt = [];
    if femp(h.eegDb(1), 'epoch')
        opt.epoch = h.eegDb(1).epoch;
    end
    
    % update if relevant
    if ~isempty(opt)
        db_temp = db_copybase(eegDb, opt);
    end
end

eegDb_temp = db_gui_epoch(eegDb_temp);
if isstruct(db_temp)
    h.eegDb = db_temp;
    set(h.OK, 'Enable', 'on');
    guidata(h.figure1, h);
end

% --- Executes on button press in OK.
function OK_Callback(hObject, ~, h)

h = guidata(hObject);

if femp(h, 'eegDb')
    % db = h.db;
    opt = [];
    if femp(h, 'PassFilt')
        opt.filter(1,:) = h.PassFilt;
        if femp(h, 'StopFilt')
            opt.filter(2,:) = h.PassFilt;
        end
    elseif femp(h, 'StopFilt')
        opt.filter(1,:) = [0 0];
        opt.filter(2,:) = h.PassFilt;
    end
    
    if femp(h.eegDb(1), 'epoch')
        opt.epoch = h.eegDb(1).epoch;
    end
    
    [strPth, flist] = get_path_and_files(h);
    eegDb = db_buildbase(strPth, flist);
    
    if ~isempty(opt)
        eegDb = db_copybase(eegDb, opt);
    end
    
    % db = db_updatetonewformat(db);
    h.output = eegDb;
    guidata(hObject, h);
    uiresume(h.figure1);
end
    
% --- Executes on button press in cancel.
function cancel_Callback(hObject, eventdata, handles)
% hObject    handle to cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function [strPth, flist] = get_path_and_files(h)

strPth = get(h.EnterPath, 'String');
if strcmp(h.ChooseFilesMethod, 'all')
    flist = dir(fullfile(strPth, '*.set'));
    flist = {flist.name};
else
    flist = h.ChosenFiles;
end

% make sure the last sign is a separator:
if strPth(end) ~= filesep
    strPth(end+1) = filesep;
end
