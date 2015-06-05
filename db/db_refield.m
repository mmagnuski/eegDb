function ICAw = db_refield(ICAw, fieldfrom, fieldto)

% ICAw = db_refield(ICAw, fieldfrom, fieldto)
% 
% this function renames fields in ICAw structure.
% fieldfrom fileds are renamed to fieldto fields
% respectively.
% 
% Currently it simply works by moving the contents of
% `fieldfrom` to `fieldto` and then deleting `fieldfrom`.
%
% You can perform db_refield on any field - so re-
% naming 'core' fields of ICAw (like 'reject') will 
% cause ICAw to break.

% FIXHELPINFO - add examples, correct structure


if ~isfield(ICAw, fieldfrom)
    warning('no field %s present in ICAw base', fieldfrom);
    return
end

% otherwise - field is present
for rec = 1:length(ICAw)
    ICAw(rec).(fieldto) = ICAw(rec).(fieldfrom);
end

% now - removing old field:
ICAw = rmfield(ICAw, fieldfrom);
