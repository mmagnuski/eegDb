function varargout = plotopts(varargin)
%
% NOHELPINFO
% PLOTOPTS MATLAB code for plotopts.fig
%      PLOTOPTS, by itself, creates a new PLOTOPTS or raises the existing
%      singleton*.
%
%      H = PLOTOPTS returns the handle to a new PLOTOPTS or the handle to
%      the existing singleton*.
%
%      PLOTOPTS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PLOTOPTS.M with the given input arguments.
%
%      PLOTOPTS('Property','Value',...) creates a new PLOTOPTS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before plotopts_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to plotopts_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help plotopts

% Last Modified by GUIDE v2.5 19-Dec-2013 16:21:04

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @plotopts_OpeningFcn, ...
                   'gui_OutputFcn',  @plotopts_OutputFcn, ...
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

%% TO DO:
% [ ] - normalize for mac
% [X] - colors


% --- Executes just before plotopts is made visible.
function plotopts_OpeningFcn(hObject, eventdata, h, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to plotopts (see VARARGIN)

% Choose default command line output for plotopts
h.output = hObject;
h.fig2=varargin{1};
h.winl = 3;  

% mac adjustments
if ismac
    maccol = [0.94,0.94,0.94];
    set(h.figure1, 'Color',maccol);
    flds = fields(h);
    for i =1:length(flds)
        if ishandle(h.(flds{i})) && ~(strcmp('pushbutton', get(h.(flds{i}), ...
                'Type')) || strcmp('figure', get(h.(flds{i}), 'Type'))...
                || strcmp('win_len', flds{i}))
            set(h.(flds{i}), 'BackgroundColor', maccol);
        end
    end
end

% Update handles structure
guidata(hObject, h);

% UIWAIT makes plotopts wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = plotopts_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function win_len_Callback(hObject, eventdata, handles)
% hObject    handle to win_len (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of win_len as text
%        str2double(get(hObject,'String')) returns contents of win_len as a double
h = guidata(hObject);
val = get(hObject, 'String'); 
 if isnumeric(str2double(val))
 h.winl = str2double(val);
 else
 h.winl = 3;  
 end
 guidata(hObject, h);
 

% --- Executes during object creation, after setting all properties.
function win_len_CreateFcn(hObject, eventdata, handles)
% hObject    handle to win_len (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in all_rej.
function all_rej_Callback(hObject, eventdata, handles)
% hObject    handle to all_rej (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of all_rej
h = guidata(hObject);
val = get(hObject, 'Value');
h.allrej = val;
guidata(hObject, h);

% --- Executes on button press in sig_all.
function sig_all_Callback(hObject, eventdata, handles)
% hObject    handle to sig_all (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of sig_all
h = guidata(hObject);
val = get(hObject, 'Value');
h.sigall = val;
guidata(hObject, h);


% --- Executes on button press in OK_plot.
function OK_plot_Callback(hObject, eventdata, handles)
% hObject    handle to OK_plot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
h = guidata(hObject);
h2 = h.fig2;
if  isfield(h, 'sigall') && h.sigall == 1;
    h2.opt.plot.sigall = true;
else
    h2.opt.plot.sigall = false;
end

if  isfield(h, 'allrej') && h.allrej == 1;
    h2.opt.plot.remall = true;
else
    h2.opt.plot.remall = false;
end

if  isfield(h, 'eegplot2on') && h.eegplot2on == 1;
    h2.opt.plot.eegplot2on = true;
else
    h2.opt.plot.eegplot2on = false;
end

h2.opt.plot.winl = h.winl;
guidata(hObject, h);
guidata(h2.figure1, h2);
close(h.figure1)

% --- Executes on button press in Cancel_plot.
function Cancel_plot_Callback(hObject, eventdata, handles)
% hObject    handle to Cancel_plot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
h = guidata(hObject);
close(h.figure1)


% --- Executes on button press in eegplot2on.
function eegplot2on_Callback(hObject, eventdata, handles)
% hObject    handle to eegplot2on (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
h = guidata(hObject);
val = get(hObject, 'Value');
h.eegplot2on = val;
guidata(hObject, h);
