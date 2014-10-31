function nonemp = femp(st, fld)

% complete MAGIC!
% nonempty = femp(structure, field)
% returns boolean that tells whether the
% field exists AND is nonempty
% false means that the field is either
% absent or is empty - which means that
% the parameter that is described by the
% field is absent.
%
% femp is a shortcut to writing:
% nonempty = isfield(st, fld) && ~isempty(st.(fld));

nonemp = isfield(st, fld) && ~isempty(st.(fld));