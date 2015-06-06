function db_gui_buttonpress(h, ev)

% HOW to check if textbox is selected?
% d = guidata(h);
% if strcmp(get(d.notes_win, 'Selected'), 'on')
% 	return
% end


if length(ev.Modifier) == 1 && ...
    strcmp(ev.Modifier{1}, 'control') && ...
        strcmp(ev.Key, 'e')
	linkfun_db_edit(h);
end