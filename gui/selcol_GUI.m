function varargout = selcol_GUI(varargin)

% NOHELPINFO
% SELCOL_GUI MATLAB code for selcol_GUI.fig
%      SELCOL_GUI, by itself, creates a new SELCOL_GUI or raises the existing
%      singleton*.
%
%      H = SELCOL_GUI returns the handle to a new SELCOL_GUI or the handle to
%      the existing singleton*.
%
%      SELCOL_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SELCOL_GUI.M with the given input arguments.
%
%      SELCOL_GUI('Property','Value',...) creates a new SELCOL_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before selcol_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to selcol_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help selcol_GUI

% Last Modified by GUIDE v2.5 16-Dec-2013 06:40:52

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @selcol_GUI_OpeningFcn, ...
    'gui_OutputFcn',  @selcol_GUI_OutputFcn, ...
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


% --- Executes just before selcol_GUI is made visible.
function selcol_GUI_OpeningFcn(hObject, eventdata, h, varargin)
% initialize GUI data, refresh etc.
% ADD:
% [ ] use of varargin as default/previous options for this GUI

% Choose default command line output for selcol_GUI
h.output = color_palette('default');

set(h.list_cpal, 'String', color_palette('get'));

% Update handles structure
guidata(hObject, h);

% refresh GUI
refresh_gui(h);

% uiwait for accepting
uiwait(h.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = selcol_GUI_OutputFcn(hObject, eventdata, handles) %#ok<*INUSL>
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% Get default command line output from handles structure
if exist('handles', 'var') && isstruct(handles) && ...
        isfield(handles, 'figure1') && ishandle(handles...
        .figure1)
    close(handles.figure1);
    varargout{1} = handles.output;
else
    varargout{1} = [];
end

function refresh_gui(h, varargin)

% this function is responsible for
% refreshing user interface

if isstruct(h)
h = guidata(h.figure1);
else
    h = guidata(h);
end

if isempty(varargin)
    refr = {'colup', 'fig', 'but'};
else
    refr = varargin;
end

if sum(strcmp('colup', refr)) > 0 || ...
        ~isfield(h, 'act_pal') || isempty(h.act_pal)
    % get color pal:
    allstr = get(h.list_cpal, 'String');
    choice = get(h.list_cpal, 'Value');
    h.act_pal = color_palette(allstr{choice});
    h.out_pal = h.act_pal;
end

% refreshing select buttons
if sum(strcmp('but', refr)) > 0
    
    bt1_pos = get(h.colbut1, 'Position');
    ypos = bt1_pos([2, 4]);
    xpos = bt1_pos([1, 3]);
    endx = 0.95;
    
    % if no colbuts: generate
    if ~isfield(h, 'colbuts')
        h.colbuts(1) = h.colbut1;
    end
    
    % we need N colors
    N = size(h.act_pal, 1);
    
    allen = endx - xpos(1);
    lenbits = allen/((N*5)-1);
    
    % change position of
    set(h.colbut1, 'Position', [xpos(1), ypos(1), lenbits*4,...
        ypos(2)], 'BackgroundColor',...
                h.act_pal(1, :), 'Value', 1, 'callback', ...
                {@refresh_gui,'fig'});
    
    for n = 2:N
        if length(h.colbuts) < n
            h.colbuts(n) = uicontrol(h.panel_showpal,...
                'style', 'togglebutton',...
                'value', 1, 'units', 'normalized',...
                'Position', [xpos(1) + (lenbits * 5 * (n-1)),...
                ypos(1), lenbits*4, ypos(2)], 'BackgroundColor',...
                h.act_pal(n, :), 'listboxtop', 1, 'callback', ...
                {@refresh_gui,'fig'});
        else
            set(h.colbuts(n),...
                'value', 1, 'Position', [xpos(1) + lenbits * 5 * (n-1),...
                ypos(1), lenbits*4, ypos(2)], 'BackgroundColor',...
                h.act_pal(n, :));
        end
    end
    
    if length(h.colbuts) > N
        delete(h.colbuts(N+1:end));
        h.colbuts(N+1:end) = [];
    end
end


if sum(strcmp('fig', refr)) > 0
    cols = h.act_pal;
    
    if isfield(h, 'colbuts') && length(h.colbuts) == size(h.act_pal, 1)
        ign = logical(cell2mat(get(h.colbuts, 'Value')));
        cols = cols(ign,:);
    end
    h.out_pal = cols;  
    
    % update h.palette_show
    axes(h.palette_show);
    show_col = reshape(cols, [1, size(cols, 1), 3]);
    image(show_col);
    set(gca, 'xticklabel',[], 'yticklabel',[],...
        'ticklength', [0, 0]);
    
    % update h.elec_plot
    % we have N active colors
    N = size(cols, 1);
    
    axes(h.elec_plot);
    plot(1:50, rand(1,50) + (N*2 - 1)*2 + 1, 'LineWidth', 1.5, 'Color',...
        cols(1,:));
    hold on
    
    thiscols = [cols; cols];
    
    for thisn = N*2 - 1 : -1 : 1
        plot(1:50, rand(1,50) + (thisn - 1)*2 + 1, 'LineWidth',...
            1.5, 'Color', thiscols(size(thiscols,1) - (thisn-1),:));
    end
    hold off
    set(h.elec_plot, 'xticklabel',[], 'yticklabel',[],...
        'ticklength', [0, 0]);
    set(h.elec_plot, 'ylim', [-1.5, (N*2 - 1)*2 + 1 + 3.5]);
    
end


% update gui data:
guidata(h.figure1, h);

% --- Executes on button press in use_cpal.
function use_cpal_Callback(hObject, eventdata, handles)

% Hint: get(hObject,'Value') returns toggle state of use_cpal


% --- Executes on button press in use_mycol.
function use_mycol_Callback(hObject, eventdata, handles)

% Hint: get(hObject,'Value') returns toggle state of use_mycol


% --- Executes on selection change in list_cpal.
function list_cpal_Callback(hObject, eventdata, h)

refresh_gui(h);


% --- Executes during object creation, after setting all properties.
function list_cpal_CreateFcn(hObject, eventdata, handles)

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ok_button.
function ok_button_Callback(hObject, eventdata, handles)

h = guidata(hObject);
h.output = h.out_pal;
guidata(h.figure1, h);
uiresume(h.figure1);


% --- Executes on button press in cancel_button.
function cancel_button_Callback(hObject, eventdata, handles)


h = guidata(hObject);
h.output = [];
guidata(h.figure1, h);
uiresume(h.figure1);


% --- Executes on button press in colbut1.
function colbut1_Callback(hObject, eventdata, handles) %#ok<*DEFNU,*INUSD>


% Hint: get(hObject,'Value') returns toggle state of colbut1


% --- Executes on button press in reorder_button.
function reorder_button_Callback(hObject, eventdata, handles)



% --- Executes on button press in inter_button.
function inter_button_Callback(hObject, eventdata, handles)

