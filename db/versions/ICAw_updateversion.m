function ICAw = ICAw_updateversion(ICAw, r, verf)

% ICAw = ICAw_updateversion(ICAw, r, verf)
%
% ICAw_updateversion updates given version of 
% ICAw(r) record with its current main
% content (contents of ICAw(r) nonempty fields)
% 
% FIXHELPINFO
% verf is not explained - version field name?


%% check version field:
f = ICAw_checkfields(ICAw(r).versions, 1, {verf});
if ~f.fpres
    % field not present - it must be a name!
    versions = ICAw_getversions(ICAw, r);
    nmv = strcmp(verf, versions(:,2));
    verf = versions{nmv,1};
end

%% update version:
f = ICAw_checkfields(ICAw, r, [],...
    'ignore', {'subjectcode', 'tasktype', 'filename', 'filepath',...
    'datainfo', 'session', 'versions'});

% update from fields that are non-empty
fld = f.fields(f.fnonempt);

for ff = 1:length(fld)
    ICAw(r).versions.(verf).(fld{ff}) = ICAw(r).(fld{ff});
end

% check also fields that are present in
% the version but empty in the front manifestation:
v_fld = fields(ICAw(r).versions.(verf));
fld = intersect(f.fields(~f.fnonempt), v_fld);

if ~isempty(fld)
    for f = 1:length(fld)
        ICAw(r).versions.(verf).(fld{f}) = ICAw(r).(fld{f});
    end
end