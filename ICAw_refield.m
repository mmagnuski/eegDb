function ICAw = ICAw_refield(ICAw, fieldfrom, fieldto)

% ICAw = ICAw_refield(ICAw, fieldfrom, fieldto)
% 
% this function renames fields in ICAw structure.
% fieldfrom fileds are renamed to fieldto fields
% respectively.
% 
% Currently it simply works by renaming the
% fields - so renaming 'core' fields of ICAw (like
% 'removed' will cause ICAw to break - this will be
% later changed so that the fields cannot be renamed
% using this function)

% FIXHELPINFO - add examples
% CHANGE, ADD - not possible to rename core fields?

flds = fieldnames(ICAw);
fldpos = find(strcmp(fieldfrom, flds));

if isempty(fldpos)
    warning('no such field present in ICAw base');
    return
end

% otherwise - field is present
for rec = 1:length(ICAw)
    ICAw(rec).(fieldto) = ICAw(rec).(fieldfrom);
end

% now - removing old field:
ICAw = rmfield(ICAw, fieldfrom);

% orderfields
flds{fldpos} = fieldto;
ICAw = orderfields(ICAw, flds);
