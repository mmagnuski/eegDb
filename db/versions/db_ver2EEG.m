function EEG = db_ver2EEG(db, r, EEG)

% EEG = db_ver2EEG(db, r, EEG)
% transports current version to EEG.etc.recov
% this is for the interface to know later whether
% currently recovered EEG corresponds to currently
% active version

% CHANGE - this may not be the best way
%          to do it...

% current version:
cvf = db(r).versions.current;
cv = db(r).versions.(cvf);

% move fields to EEG.etc.recov
f = db_checkfields(cv, 1, [], 'ignore', {'version_name',...
    'version_description'});
fld = f.fields(f.fnonempt);

% loop
for f = 1:length(fld)
    EEG.etc.recov.(fld{f}) = db(r).versions.(cvf)...
        .(fld{f});
end