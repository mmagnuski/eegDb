function db = db_refield(db, fieldfrom, fieldto)

% db = db_refield(db, fieldfrom, fieldto)
% 
% this function renames fields in db structure.
% fieldfrom fileds are renamed to fieldto fields
% respectively.
% 
% Currently it simply works by moving the contents of
% `fieldfrom` to `fieldto` and then deleting `fieldfrom`.
%
% You can perform db_refield on any field - so re-
% naming 'core' fields of db (like 'reject') will 
% cause db to break.

% FIXHELPINFO - add examples, correct structure


if ~isfield(db, fieldfrom)
    warning('no field %s present in db base', fieldfrom);
    return
end

% otherwise - field is present
for rec = 1:length(db)
    db(rec).(fieldto) = db(rec).(fieldfrom);
end

% now - removing old field:
db = rmfield(db, fieldfrom);
