function db = db_load(filepath, filename)

% db_load loads a db database

% FIXHELPINFO

pth = db_path(filepath);
loaded = load(fullfile(pth, filename));
fld = fields(loaded);

% ADD in future - search through fields
% for db and other info about the data
db = loaded.(fld{1});

