function rec = eegDb_purify_record(rec)

% NOHELPINFO

flds  = fields(rec);

ignore = {'versions', 'marks', 'filepath',...
		  'notes'};
present = cellfun(@(x) any(strcmp(x, flds)),...
    ignore);
ignore(~present) = [];

% remove unnecessary fields
rec = rmfield(rec, ignore);

if femp(rec, 'ICA')
    
    inICA  = {'icasphere', 'icawinv', 'desc', ...
		      'ifremove', 'select'};
    flds = fields(rec.ICA);
    present = cellfun(@(x) any(strcmp(x, flds)),...
    inICA);  
    inICA(~present) = [];
	rec.ICA = rmfield(rec.ICA, inICA);
end