function iseq = db_vers_compare(ver01, ver02)

% NOHELPINFO

% compare non-empty fields of databases
ign = {'subjectcode', 'tasktype', 'filename', 'filepath',...
    'datainfo', 'session', 'versions', 'version_name', ...
    'version_description', 'marks', 'dipfit', 'notes'};

f1 = db_checkfields(ver01, 1, [],...
    'ignore', ign);
f1.fields(~f1.fnonempt) = [];
fields1 = fields(ver01);
ver01 = rmfield(ver01, setdiff(fields1, f1.fields));


f2 = db_checkfields(ver02, 1, [],...
    'ignore', ign);
f2.fields(~f2.fnonempt) = [];
fields2 = fields(ver02);
ver02 = rmfield(ver02, setdiff(fields2, f2.fields));

iseq = isequal(ver01, ver02);

