function linkfun_multiselect(h)

% NOHELPINFO

% TODOs
% [ ] separate function that updates h.sel? (might be useful)
% [ ] add option (button?) to choose by file name not r
% [ ] consider new behavior when multiple selected:
%       - summary display
%       - or/and navigate with arrows only among the selected

% CHANGE - some old notes, recov was used previously:
% cansel = find(handles.recov);%check
% strsel = cellfun(@num2str, num2cell(cansel), 'UniformOutput', false);
% strsel = strsel(:);


% if h is one handle, not guidata structure - get guidata
if length(h) == 1 && ishandle(h)
    h = guidata(h);
end

% prepare GUI variables
% ---------------------
allsel = 1:length(h.db);
allstr = cellfun(@num2str, num2cell(allsel), 'UniformOutput', false);
allstr = allstr(:);

% select records through GUI:
% ---------------------------
sel = gui_chooselist(allstr, 'text', 'Select records:');

% set selection based on GUI output
% ---------------------------------
if length(sel) == 1
    
    % just jumping
    h.r = allsel(sel);
    h.selected = [];
    set(h.multisel, 'BackgroundColor', ...
        h.multisel_col);
    
    % refresh
    db_gui_refresh(h);

elseif length(sel) > 1
    
    % chosen multiple
    h.r = sel(1);
    h.selected = sel;
    set(h.multisel, 'BackgroundColor', ...
        [0.9, 0.2, 0.1]);
    
    % refresh
    db_gui_refresh(h);

elseif isempty(sel)

    % empty selection (cancel fo example)
    h.selected = [];
    set(h.multisel, 'BackgroundColor', ...
        h.multisel_col);
end

% Update h structure
guidata(h.figure1, h);