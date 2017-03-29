function subj = db_get_subj_id(db)

% get subject numerical identifiers in the order they are present in the db
%
% subj = db_get_subj_id(db)

fun = @(x) str2num(regexp(x, '[0-9]+', 'match', 'once'));
subj = cellfun(fun, {db.filename});