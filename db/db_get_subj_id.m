function subj = db_get_subj_id(db)

% NOHELPINFO

fun = @(x) str2num(regexp(x, '[0-9]+', 'match', 'once'));
subj = cellfun(fun, {db.filename});