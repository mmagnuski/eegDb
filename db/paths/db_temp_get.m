function [tempdb, match] = db_temp_get(db, r)

% DB_TEMP_GET gives info on relevant tempfile for db
% record r.
%
% usage
% -----
% temp = db_temp_get(db, r);
%
% input
% -----
% db - *structure*; eegDb database
% r  - *integer*; record number
%
% output
% ------
% temp - *structure*; tempfile info, with fields:
%     .filename
%     .filepath
%     .filter
%     .cleanline
%     .epoch



tempdb = [];
match = 0;

if femp(db(r).datainfo, 'tempfiles')
	% some tempfiles are present, check which 
	% ones are present on disc
	temp = db(r).datainfo.tempfiles;
	tempok = false(1, length(temp));
	for t = 1:length(temp)
		if temp(t).filepath(1) == '+'
			% this uses a vild path from db(r).filepath
			% and a subdir in it
			tempok(t) = ~isempty(get_valid_path(...
				db(r).filepath, ...
				'file', temp(t).filename, ...
				'dir', temp(t).filepath(2:end), ...
				'noerror', true));
		else
			tempok(t) = ~isempty(get_valid_path(...
				temp(t).filepath, ...
				'file', temp(t).filename, ...
				'noerror', true));
		end
	end
	temp = temp(tempok);

	if isempty(temp)
		return
	end

	% check which tempfile matches the 
	% current database pipeline

	% get filtering and epoching from the current record:
	tst = struct('filter', [], 'epoch', [], 'cleanline', []);

	% epoching
	tst.epoch = db_getepoching(db(r));

	% filtering (should CHANGE to db_get later on)
	in = cellfun(@(x) femp(x, 'filter'), {db(r), db(r).datainfo});
	in(3) = femp(db(r).datainfo, 'filtered');

	if any(in)
		if in(1)
			tst.filter = db(r).filter;
		elseif in(2)
			tst.filter = db(r).datainfo.filter;
		elseif in(3)
			tst.filter = db(r).datainfo.filtered;
		end
	end

	% cleanline
	if femp(db(r).datainfo, 'cleanline')
		tst.cleanline = db(r).datainfo.cleanline;
	end

	% only filtering and epoching are considered
	checkflds = {'cleanline', 'filter', 'epoch'};
	test_temp = false(length(checkflds), length(temp));

	for f = 1:length(checkflds)
		test_temp(f, :) = cellfun(@(x) isequal(x, ...
			tst.(checkflds{f})), {temp.(checkflds{f})});
	end
	good_temp = all(test_temp(1:2, :), 1);
	best_temp = all(test_temp, 1);

	ind = [];
	% choose first one matching (CHANGE!)
	if any(best_temp)
		ind = find(best_temp, 1);
		match = 2;
	elseif any(good_temp)
		ind = find(good_temp, 1);
		match = 1;
	end

	if ~isempty(ind)
		% give tempdb
		tempdb = struct();
		tempdb.filename = temp(ind).filename;
		if temp(ind).filepath(1) == '+'
			tempdb.filepath = get_valid_path(temp(ind).filepath, ...
				'file', temp(ind).filename, 'dir', temp(ind).filepath(2:end));
		else
			tempdb.filepath = temp(ind).filepath;
		end
		tempdb.filter = temp(ind).filter;
		tempdb.epoch = temp(ind).epoch;
		tempdb.cleanline = temp(ind).cleanline;
	end
end
