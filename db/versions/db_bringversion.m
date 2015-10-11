function db = db_bringversion(db, r, verf)

% NOHELPINFO

% TODOs:
% [ ] PROFILE and rewrite
% [ ] if some fields are filled but are not present
%     in the version being recovered - clear those fields
%     this seems to be implemented - CHECK if this is wor-
%     king

%% check version field:
f = db_checkfields(db(r).versions, 1, {verf});
if ~f.fpres
    % field not present - it must be a name!
    versions = db_getversions(db, r);
    nmv = strcmp(verf, versions(:,2));
    verf = versions{nmv,1};
end

if ~isempty(verf)
    f = db_checkfields(db(r).versions.(verf), 1, [],...
        'ignore', {'subjectcode', 'tasktype', 'filename', 'filepath',...
        'datainfo', 'session', 'versions', 'version_name', ...
        'version_description'});
    
    f2 = db_checkfields(db, r, [],...
        'ignore', {'subjectcode', 'tasktype', 'filename', 'filepath',...
        'datainfo', 'session', 'versions'});


    % clearing fields that are currently
    % filled but not present in the version
    clearf = setdiff(f2.fields, f.fields);
    
    for c = 1:length(clearf)
        db(r).(clearf{c}) = [];
    end
    
    % copy info from version to 'surface'
    fld = f.fields;
    
    for f = 1:length(fld)
        db(r).(fld{f}) = db(r).versions.(verf).(fld{f});
    end
    
    db(r).versions.current = verf;
end