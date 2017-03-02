function db_gui_refresh(handles)

% FIXHELPTINFO
% --- Refreshes eegDb GUI

% CHANGE refreshing info textbox - it should be a separate and
%        more universal function
% CHANGE - or maybe optional arguments - what to refresh


% --- title_text ---
set(handles.title_text, 'String', ['record number: ', ...
    num2str(handles.r)]);


% =================
% --- info_text ---
% =================


% text stuff
% ----------

% Fill info_text:
maxlines = 8;

% get text from eegDb structure, already wrapped
infotext = db_struct2text(handles.db(handles.r), handles.info_text);

% check wrapped size:
all_lines = length(infotext);


% get slider vars
% ---------------
sliderVal = get(handles.slider, 'Value');
sliderMax = get(handles.slider, 'Max');
current_slider_pos = round(sliderMax - sliderVal) + 1;

% set active lines (scrollable)
active_lines = all_lines - maxlines;
if active_lines < 1
    active_lines = 1;
end

% slider cannot be off max
if current_slider_pos > sliderMax + 1
    current_slider_pos = sliderMax + 1;
end

% see what part of the text to present
lastlin = current_slider_pos + maxlines - 1;
if lastlin > all_lines
    % but never more than there are lines
    lastlin = all_lines;
end


% Slider stuff
% ------------

set(handles.slider, 'Max', active_lines);
set(handles.slider, 'SliderStep', 1/active_lines * [1, 3])
if sliderVal > active_lines
    set(handles.slider, 'Value', active_lines);
else
    set(handles.slider, 'Value', max([0, active_lines - current_slider_pos + 1]));
end


%
% trim text and show:
% -------------------
infotext = infotext(current_slider_pos:lastlin);

% set the text
set(handles.info_text, 'String', infotext);


% --- CL_checkbox ---
useclean = false;
if femp(handles.db(handles.r), 'cleanline') && ...
        (isstruct(handles.db(handles.r).cleanline) ...
        || handles.db(handles.r).cleanline)
    useclean = true;
end

% change state of the toggle button
if useclean
    set(handles.CL_checkbox, 'Value', 1);
else
    set(handles.CL_checkbox, 'Value', 0);
end

% --- notes_win ---
set(handles.notes_win, 'String', handles.db(handles.r).notes);

% --- addit_text ---
if isempty(handles.rEEG) || handles.r ~= handles.rEEG
    set(handles.addit_text, 'String', 'EEG not recovered');
else
    set(handles.addit_text, 'String', 'EEG recovered');
end

guidata(handles.figure1, handles);
clear f
