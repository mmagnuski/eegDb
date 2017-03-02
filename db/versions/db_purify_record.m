function rec = db_purify_record(rec)

% function used for checking whether the EEG dataset held in memory
% has to be reconstructed again or is it up to date
% db_purify_record clears up current db record by removing fields that
% are not needed to check whether file is up to date later

flds  = fields(rec);

ignore = {'marks', 'filepath', 'notes'};
present = cellfun(@(x) any(strcmp(x, flds)),...
    ignore);
ignore(~present) = [];

% remove unnecessary fields
rec = rmfield(rec, ignore);

if femp(rec, 'ICA')

    inICA  = {'icasphere', 'icawinv', 'desc', ...
		      'ifremove', 'select', 'topo'};
    flds = fields(rec.ICA);
    present = cellfun(@(x) any(strcmp(x, flds)),...
    inICA);
    inICA(~present) = [];
	rec.ICA = rmfield(rec.ICA, inICA);
end
