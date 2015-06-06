function db_tempsave(db, rs)

% save the current version of given records 
% of the db database and modify the database
% accordingly.

% if no rs - create
if ~exist('rs', 'var')
    rs = 1:length(db);
end

% for all given records:
for r = rs(:)
	% first we need to recover the eeg file, but without
	% removing epochs or components
	% (what about interpolation etc?)
	EEG = recoverEEG(db, r, 'ICAnorem', 'prerej', 'local'); 

	% then we save:
	pth = db_path(db(r).filepath);
	newpath = fullfile(pth, 'tmp');
	if ~isdir(newpath)
		mkdir(newpath);
	end
	fname = [db(r).filename, '_tmp_', round(rand(1)*100)];
	pop_saveset(EEG, fullfile(pth, fname));

	% modify db
	% ---------
	flds = {'filter', 'epoch'};
	for f = flds
		if femp(db(r), f{1})
			db(r).datinfo.(f{1}) = db(r).(f{1});
			db(r).(f{1}) = [];
		end
	end

	if ~femp(db(r).datainfo, 'filename')
		db(r).datainfo.filename = db(r).filename;
		db(r).datainfo.filepath = db(r).filepath;
	end

	db(r).filename = fname;
	db(r).filepath = pth;
end