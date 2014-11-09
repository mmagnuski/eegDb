function outstr = gui_editbox(varargin)

% NOHELPINFO

if nargin > 0
    start_txt = varargin{1};
else
    start_txt = '';
end

if nargin > 1
    txtstr = varargin{2};
else
    txtstr = {'Type it here,',...
    'whatever it is:'};
end


% if nargin > 1
%     inp = {'text'};
%     tovar = {'txtstr'};
%     
%     for i = 1:length(inp)
%         ind = find(strcmp(inp{i}, varargin));
%         eval([tovar{ind}, ' = varargin{', num2str(ind + 1), '};']);
%     end
% end

wh = 200;
wb = 250;
lh = 40;

% create figure:
h.fig = figure('Units', 'pixels', 'Position',...
    [250 250 wb wh], 'Color', [0.9 0.9 0.9],...
    'menubar', 'none', 'Visible', 'off');

% move figure to the centre
movegui(h.fig, 'center');

%% create controls
h.txt = uicontrol('Style', 'text', 'Position',...
    [25 wh-55 200 50], 'String', txtstr, 'FontSize', 14);

h.editb = uicontrol('Style', 'edit', 'Position',...
    [25 wh-65-lh 200 lh], 'String', start_txt, 'FontSize',...
    14);

h.okbutt = uicontrol('Style', 'pushbutton', 'Position',...
    [25 15 96 35], 'String', 'Apply', ...
    'FontSize', 16, 'Callback', {@ok_Callback, h.fig});

h.cancbutt = uicontrol('Style', 'pushbutton', 'Position',...
    [126 15 96 35], 'String', 'Cancel', ...
    'FontSize', 16, 'Callback', {@canc_Callback, h});

h.clearbutt = uicontrol('Style', 'pushbutton', 'Position',...
    [25 55 96 25], 'String', 'Clear', ...
    'FontSize', 14, 'Callback', {@clear_Callback, h.fig});

ifcancel = false;
h.ifcancel = ifcancel;
set(h.fig, 'CloseRequestFcn', @close_Callback);

%% the rest
guidata(h.fig, h);
set(h.fig, 'Visible', 'on');
uiwait(h.fig);

if ishandle(h.fig)
    h = guidata(h.fig);
    outstr = get(h.editb, 'String');
    ifcancel = h.ifcancel;
    if ifcancel
        outstr = [];
    end
    close(h.fig)
else
    outstr = [];
end

function ok_Callback(hObject, eventdata, h) %#ok<*INUSL>

h = guidata(h);
if ~isempty(get(h.editb, 'String'))
uiresume(h.fig);
end

function canc_Callback(hObject, eventdata, h)
h = guidata(h.fig);
set(h.editb, 'String', []);

h.ifcancel = true;
guidata(h.fig, h);

uiresume(h.fig);
% delete(h.fig);

function close_Callback(hObject, eventdata) %#ok<INUSD>

if isequal(get(hObject, 'waitstatus'), 'waiting')
    
    h = guidata(hObject);
    h.ifcancel = true;
    
    % Update handles structure
    guidata(hObject, h);
    
    % Resume GUI
    uiresume(hObject);
else
    % The GUI is no longer waiting, just close it
    delete(hObject);
end

function clear_Callback(hObject, eventdata, h)
h = guidata(h);

set(h.editb, 'String', []);
