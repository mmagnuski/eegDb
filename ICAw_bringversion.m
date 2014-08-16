function ICAw = ICAw_bringversion(ICAw, r, verf)

% NOHELPINFO

% TODOs:
% [ ] CHECK more thoroughly - testing
% [ ] if some fields are filled but are not present
%     in the version being recovered - clear those fields
%     this seems to be implemented - CHECK if this is wor-
%     king

%% check version field:
f = ICAw_checkfields(ICAw(r).versions, 1, {verf});
if ~f.fpres
    % field not present - it must be a name!
    versions = ICAw_getversions(ICAw, r);
    nmv = strcmp(verf, versions(:,2));
    verf = versions{nmv,1};
end

if ~isempty(verf)
    f = ICAw_checkfields(ICAw(r).versions.(verf), 1, [],...
        'ignore', {'subjectcode', 'tasktype', 'filename', 'filepath',...
        'datainfo', 'session', 'versions', 'version_name', ...
        'version_description'});
    
    f2 = ICAw_checkfields(ICAw, r, [],...
        'ignore', {'subjectcode', 'tasktype', 'filename', 'filepath',...
        'datainfo', 'session', 'versions'});
    
    clearf = setdiff(f2.fields, f.fields);
    
    for c = 1:length(clearf)
        ICAw(r).(clearf{c}) = [];
    end
    
    % we include empty fields too
    % (to clear icaweights of another version
    %  for example)
    fld = f.fields;
    
    for f = 1:length(fld)
        ICAw(r).(fld{f}) = ICAw(r).versions.(verf).(fld{f});
    end
    
    ICAw(r).versions.current = verf;
end