function [outp, ifcancel] = gui_chooselist(optnames, varargin)

% NOHELPINFO

% TODOs
% [ ] add enter - to accept
% [ ] escape to cancel
% [ ] enter to activate buttons

if isempty(optnames)
    outp = [];
    ifcancel = true;
    return
end

% defaults
txtstr = {'Select rejections',...
    'to apply'};

if nargin > 1
    inp = {'text'};
    tovar = {'txtstr'};
    
    for i = 1:length(inp)
        ind = find(strcmp(inp{i}, varargin));
        eval([tovar{ind}, ' = varargin{', num2str(ind + 1), '};']);
    end
end

peropt = 24;
maxopt = 10;
minopt = 5;

options = length(optnames);

% list height
if options <= maxopt && options >= minopt
    lh = options*peropt;
elseif options > maxopt
    lh = maxopt*peropt;
else
    lh = minopt*peropt;
end

% window height
wh = 150 + lh;

% create figure:
h.fig = figure('Units', 'pixels', 'Position',...
    [250 250 250 wh], 'Color', [0.9 0.9 0.9],...
    'menubar', 'none', 'Visible', 'off');

% move figure to the centre
movegui(h.fig, 'center');

%% create controls
h.txt = uicontrol('Style', 'text', 'Position',...
    [25 wh-55 200 50], 'String', txtstr, 'FontSize', 14, ...
    'Parent', h.fig);

h.list = uicontrol('Style', 'listbox', 'Position',...
    [25 wh-65-lh 200 lh], 'Min', 0, 'Max',...
    options, 'String', optnames, 'FontSize',...
    14, 'Parent', h.fig);

h.okbutt = uicontrol('Style', 'pushbutton', 'Position',...
    [25 15 96 35], 'String', 'Apply', ...
    'FontSize', 16, 'Callback', {@ok_Callback, h.fig}, ...
    'Parent', h.fig);

h.cancbutt = uicontrol('Style', 'pushbutton', 'Position',...
    [126 15 96 35], 'String', 'Cancel', ...
    'FontSize', 16, 'Callback', {@canc_Callback, h}, ...
    'Parent', h.fig);

h.clearbutt = uicontrol('Style', 'pushbutton', 'Position',...
    [25 55 96 25], 'String', 'Clear', ...
    'FontSize', 14, 'Callback', {@clear_Callback, h.fig}, ...
    'Parent', h.fig);

ifcancel = false;
h.ifcancel = ifcancel;
set(h.fig, 'CloseRequestFcn', @close_Callback);
set(h.fig, 'WindowKeyPressFcn', @resolve_buttonpress);

%% the rest
guidata(h.fig, h);
set(h.fig, 'Visible', 'on');
uicontrol(h.list);
uiwait(h.fig);

if ishandle(h.fig)
    h = guidata(h.fig);
    outp = get(h.list, 'Value');
    if isequal(outp, 0)
        outp = [];
    end
    ifcancel = h.ifcancel;
    if ifcancel
        outp = [];
    end
    close(h.fig)
else
    outp = [];
end

function ok_Callback(hObject, eventdata, h) %#ok<*INUSL>

    uiresume(h);

function canc_Callback(hObject, eventdata, h)
    h = guidata(h.fig);
    listlen = length(get(h.list, 'String'));

    if listlen > 1
        set(h.list, 'Value', []);
    end

    h.ifcancel = true;
    guidata(h.fig, h);

    uiresume(h.fig);
    % delete(h.fig);

function close_Callback(hObject, eventdata) %#ok<INUSD>

    if isequal(get(hObject, 'waitstatus'), 'waiting')
        
        % inform gui that its cancel and resume
        cancel_fun(hObject);
    else
        % The GUI is no longer waiting, just close it
        delete(hObject);
    end

function cancel_fun(hObject)

    % get guidata
    h = guidata(hObject);
    % set ifcancel to true
    h.ifcancel = true;

    % Update handles structure
    guidata(hObject, h);

    % Resume GUI
    uiresume(hObject);


function clear_Callback(hObject, eventdata, h)
    h = guidata(h);

    listlen = length(get(h.list, 'String'));

    if listlen > 1
        set(h.list, 'Value', []);
    end

% button press function
function resolve_buttonpress(hObj, evnt)

    % get pressed character
    ch = evnt.Character;

    if ~isempty(ch)
        
        if strcmp(evnt.Key, 'return')
            uiresume(hObj);
        elseif strcmp(evnt.Key, 'escape')
            cancel_fun(hObj);
        elseif strcmp(evnt.Key, 'backspace')
            clear_Callback(hObj, [], hObj);
        end
    end