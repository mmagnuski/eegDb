function db = db_updateversion(db, r, verf)

% db = db_updateversion(db, r, verf)
%
% db_updateversion updates given version of 
% db(r) record with its current main
% content (contents of db(r) nonempty fields)
% 
% FIXHELPINFO
% verf is not explained - version field name?


%% check version field:
f = db_checkfields(db(r).versions, 1, {verf});
if ~f.fpres
    % field not present - it must be a name!
    versions = db_getversions(db, r);
    nmv = strcmp(verf, versions(:,2));
    verf = versions{nmv,1};
end

%% update version:
f = db_checkfields(db, r, [],...
    'ignore', {'subjectcode', 'tasktype', 'filename', 'filepath',...
    'datainfo', 'session', 'versions'});

% update from fields that are non-empty
fld = f.fields(f.fnonempt);

for ff = 1:length(fld)
    db(r).versions.(verf).(fld{ff}) = db(r).(fld{ff});
end

% check also fields that are present in
% the version but empty in the front manifestation:
v_fld = fields(db(r).versions.(verf));
fld = intersect(f.fields(~f.fnonempt), v_fld);

if ~isempty(fld)
    for f = 1:length(fld)
        db(r).versions.(verf).(fld{f}) = db(r).(fld{f});
    end
end