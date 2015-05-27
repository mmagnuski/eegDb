function db = db_apply(db, field, fun)

% apply function 'fun' to field 'field' in 
% each record of the structure 'db'
%
% for example:
% fun = @(x) unique(x.filepath);
% db = db_apply(db, 'filepath', fun);

% TODOs:
% [ ] add support for cell arrays of function handles

% input checks
% ------------
if ~isa(fun, 'function_handle')
	error('''fun'' must be a function handle');
end

if ~isstruct(db)
	error('''db'' must be a structure');
end

if ~ischar(field)
	error('''field'' must be a character vector (string)');
end

% apply fun
% ---------
for r = 1:length(db)
	db(r).(field) = fun(db(r));
end