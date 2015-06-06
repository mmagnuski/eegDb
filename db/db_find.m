function r = db_find(db, fld, val, opt)

% r = db_find(db, fld, val)
%
% looks for a record that has field 'fld'
% set to value 'val'.
% Returns all indices that fulfill these
% constaints.

% TODOs
% [ ] PROFILE against cellfun
% [ ] maybe add options to look deeper than one field
%     (db_getfield or sth similar?)

if ~isstruct(db)
    error('The variable passed as db is not a structure!');
end

if ~exist('opt', 'var')
    opt = '';
end

len = length(db);
r = false(1, len);
if strcmp(opt, 'substring')
	testfun = @(s) length(strfind(s.(fld), val)) > 0;
else
	testfun = @(s) isequal(s.(fld), val);
end

% loop through records:
if isfield(db, fld)
    r = arrayfun(testfun, db);
end

r = find(r);