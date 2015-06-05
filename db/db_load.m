function ICAw = db_load(filepath, filename)

% db_load loads a ICAw database

% FIXHELPINFO

pth = db_path(filepath);
loaded = load(fullfile(pth, filename));
fld = fields(loaded);

% ADD in future - search through fields
% for ICAw and other info about the data
ICAw = loaded.(fld{1});

