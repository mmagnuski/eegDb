function varargout = ICAw_adj_conf_GUI(varargin)
% ICAW_ADJ_CONF_GUI MATLAB code for ICAw_adj_conf_GUI.fig
%      ICAW_ADJ_CONF_GUI, by itself, creates a new ICAW_ADJ_CONF_GUI or raises the existing
%      singleton*.
%
%      H = ICAW_ADJ_CONF_GUI returns the handle to a new ICAW_ADJ_CONF_GUI or the handle to
%      the existing singleton*.
%
%      ICAW_ADJ_CONF_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ICAW_ADJ_CONF_GUI.M with the given input arguments.
%
%      ICAW_ADJ_CONF_GUI('Property','Value',...) creates a new ICAW_ADJ_CONF_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ICAw_adj_conf_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ICAw_adj_conf_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ICAw_adj_conf_GUI

% Last Modified by GUIDE v2.5 21-Jul-2013 23:00:18

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ICAw_adj_conf_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ICAw_adj_conf_GUI_OutputFcn, ...
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


% --- Executes just before ICAw_adj_conf_GUI is made visible.
function ICAw_adj_conf_GUI_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ICAw_adj_conf_GUI (see VARARGIN)

% Choose default command line output for ICAw_adj_conf_GUI
handles.nums = [];
handles.output = handles.nums;

% create string if varargin not empty:
if ~isempty(varargin)
    handles.nums = varargin{1};
    handles.numsq = [];
    handles.output = handles.nums;
    
    str = num2str(varargin{1});
    [~,j] = regexp(str, '[0-9]+ ');
    str(j) = ',';
    set(handles.edit1, 'String', str);
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ICAw_adj_conf_GUI wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ICAw_adj_conf_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.nums;
varargout{2} = handles.numsq;
close(handles.figure1)



function edit1_Callback(hObject, eventdata, handles) %#ok<*INUSD,*DEFNU>
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% extract data from edit box:
out = get(hObject,'String');
handles.nums = cellfun(@str2num, regexp(out, '[0-9]+', 'match'));
handles.numsq = cellfun(@(x) str2num(x(1:end-1)),...
    regexp(out, '[0-9]+\?', 'match')); %#ok<ST2NM>
if ~isempty(handles.numsq)
    handles.nums = setdiff(handles.nums, handles.numsq);
end

% Update handles structure:
guidata(hObject, handles);

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double


% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(handles.figure1)