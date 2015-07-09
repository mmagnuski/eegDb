function db_remove_temp(db, r, optind)

% 
ind = optind;
if ischar(optind)
	if strcmp(optind, 'all')
		ind = 1:length(db(r).datainfo.tempfiles);
	end
end
ind = ind(:)';

% remove file
for rmv = ind
	pth = db_test_temp_path(db, r, rmv);
	delete(fullfile(pth, db(r).datainfo...
		.tempfiles(rmv).filename));
end

% clear info from the db
db(r).datainfo.tempfiles(ind) = [];
