function ICAw = ICAw_load(filepath, filename)

% ICAw_load loads a ICAw database

% FIXHELPINFO

pth = ICAw_path(filepath);
loaded = load(fullfile(pth, filename));
fld = fields(loaded);

% ADD in future - search through fields
% for ICAw and other info about the data
ICAw = loaded.(fld{1});

