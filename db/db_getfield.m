function val = db_getfield(eegDb, fld)

% gives field value for string description of field
% even in a nested case ('epoch.winlen')

dt = strfind(fld, '.');

if dt > 0
    val = eval(['eegDb.', fld, ';']);
else
    val = eegDb.(fld);
end