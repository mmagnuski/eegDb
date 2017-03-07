function db_convert(path_in, path_out, extension)


files = dir(fullfile(path_in, ['*', extension]));

for f = 1:length(files)
    this_file = files(f).name;
    [~, fname, ~] = fileparts(this_file);
    EEG = pop_fileio(fullfile(path_in, this_file));
    pop_saveset(EEG, fullfile(path_out, [fname, '.set']));
end