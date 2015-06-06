function db = db_mainversion(db, rr)

% NOHELPINFO

% if no - create
% else - give back(?)

for r = rr
f = db_checkfields(db, r, [],...
    'ignore', {'subjectcode', 'tasktype', 'filename', 'filepath',...
    'datainfo', 'session', 'versions'});
fld = f.fields(f.fnonempt);
        db(r).versions.current = 'main';
        db(r).versions.main.version_name = 'main';
        db(r).versions.main.version_description = 'main version';
        
        for f = 1:length(fld)
            db(r).versions.main.(fld{f}) = db(r).(fld{f});
        end
end
        