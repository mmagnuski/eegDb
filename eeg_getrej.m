function rejf = eeg_getrej(EEG)

% NOHELPINFO

% out.fld = [];
% out.col = [];
% out.isica = [];

flds = fields(EEG.reject);


allrej = strfind(flds, 'rej');
emp = cellfun(@isempty, allrej);
allrej(emp) = {123};
allrej = cellfun(@(x) x == 1, allrej);

rejs = flds(allrej);

rejcol = ~cellfun(@isempty, regexp(rejs, '.+col', 'once'));
rejE = ~cellfun(@isempty, regexp(rejs, '.+E', 'once'));

rejf = rejs(~(rejcol | rejE));