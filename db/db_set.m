function db_set(ICAw, fld, val, rs)

% ICAw_set allows for introducing controlled (safe) changes to 
% the ICAw structure
%
% ICAw_set(ICAw, fld, val)

conflict_matrix = db_check_conflict(db, rs, field);

% different GUI options for different conflicts

% current "recompute and compare" options would be:
% - for rejections --> moving them from the previous
%   state of the database to the current by an operation
%   like:
%    > compare % or sample coverage and mark
% - for ICA --> comparing previous components with current
%   (if they exist) and moving component labels.