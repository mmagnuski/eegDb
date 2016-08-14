function mark_id = db_find_mark(db, r, mark_name)

mrk_nms = {db(r).marks.name};
mark_id = find(strcmp(mark_name, mrk_nms));
if isempty(mark_id)
    error('Could not find mark %s', mark_name);
end
