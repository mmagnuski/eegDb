function ICAw = db_mainversion(ICAw, rr)

% NOHELPINFO

% if no - create
% else - give back(?)

for r = rr
f = db_checkfields(ICAw, r, [],...
    'ignore', {'subjectcode', 'tasktype', 'filename', 'filepath',...
    'datainfo', 'session', 'versions'});
fld = f.fields(f.fnonempt);
        ICAw(r).versions.current = 'main';
        ICAw(r).versions.main.version_name = 'main';
        ICAw(r).versions.main.version_description = 'main version';
        
        for f = 1:length(fld)
            ICAw(r).versions.main.(fld{f}) = ICAw(r).(fld{f});
        end
end
        