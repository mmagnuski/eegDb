function varargout = ICAw_ep_proc_GUI(varargin)

% NOHELPINFO
% ICAW_EP_PROC_GUI MATLAB code for ICAw_ep_proc_GUI.fig
%      ICAW_EP_PROC_GUI, by itself, creates a new ICAW_EP_PROC_GUI or raises the existing
%      singleton*.
%
%      H = ICAW_EP_PROC_GUI returns the handle to a new ICAW_EP_PROC_GUI or the handle to
%      the existing singleton*.
%
%      ICAW_EP_PROC_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ICAW_EP_PROC_GUI.M with the given input arguments.
%
%      ICAW_EP_PROC_GUI('Property','Value',...) creates a new ICAW_EP_PROC_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ICAw_ep_proc_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ICAw_ep_proc_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ICAw_ep_proc_GUI

% Last Modified by GUIDE v2.5 25-Jul-2013 17:29:35

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ICAw_ep_proc_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ICAw_ep_proc_GUI_OutputFcn, ...
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


% --- Executes just before ICAw_ep_proc_GUI is made visible.
function ICAw_ep_proc_GUI_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ICAw_ep_proc_GUI (see VARARGIN)

% Choose default command line output for ICAw_ep_proc_GUI
handles.ICAw_r = varargin{1};
% handles.txt1 = varargin{2};
% handles.txt2 = varargin{3};

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ICAw_ep_proc_GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ICAw_ep_proc_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles) %#ok<*INUSD,*DEFNU>
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(handles.figure1);


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
textlab = get(handles.edit1, 'String');
ICAw_add_badch([], handles.ICAw_r, textlab);



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

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
