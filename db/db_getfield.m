function val = db_getfield(db, fld)

% gives field value for string description of field
% even in a nested case ('epoch.winlen')

dt = strfind(fld, '.');

if dt > 0
    val = eval(['db.', fld, ';']);
else
    val = db.(fld);
end