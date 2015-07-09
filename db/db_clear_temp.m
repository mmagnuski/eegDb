function db = db_clear_temp(db, rs)

% DB_CLEAR_TEMP allows to clear unused temporary files from disc
% (or remove from the database information about temporary files
% that no longer exist) 

if ~exist('rs', 'var')
    rs = 1:length(db);
end
% remove unused temp files
for r = rs
	[tmp, mtch, ind] = db_temp_get(db, r);
	if ~mtch
		db = db_remove_temp(db, r, 'all');
	else
		temp_inds = 1:length(db(r).datainfo.tempfiles);
		temp_inds(ind) = [];
		db = db_remove_temp(db, r, temp_inds);
	end
end