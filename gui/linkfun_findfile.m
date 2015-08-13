function linkfun_findfile(hObj)

h = guidata(hObj);
db = h.db;
fnames = {db.filename};

r = fuzzy_gui(fnames);
if ~isempty(r) && r > 0
	h.r = r;
    db_gui_refresh(h);
end
