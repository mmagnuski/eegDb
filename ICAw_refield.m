function ICAw = ICAw_refield(ICAw, fieldfrom, fieldto)

% this function changes field names in ICAw structure
% for now it simply works as if it was renaming the
% fields - so renaming 'core' fields of ICAw (like
% 'removed' will cause ICAw to break - this will be
% later changed so that the fields cannot be renamed
% using this function)

% ADD - not possible to rename core fields?

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
