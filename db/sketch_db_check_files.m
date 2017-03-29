PTH = 'E:\Dropbox\CURRENT PROJECTS\Córko moja\cnt';
fls = dir(fullfile(PTH, '*.cnt'));

% loop over files and see whether they can be found in the db
file2db = cell(length(fls), 1);
for f = 1:length(fls)
    fname = strrep(fls(f).name, 'cnt', 'set');
    r = db_find(db, 'filename', fname);
    if ~isempty(r)
        file2db{f} = r;
    end
end

% find empty
lengths = cellfun(@length, file2db);
ind = find(lengths == 0);
if ~isempty(ind)
    fprintf('\n\nfiles not present in the db:\n');
    fprintf('----------------------------\n');
    for fn = 1:length(ind)
        fprintf('%s\n', strrep(fls(ind(fn)).name, 'cnt', 'set'));
    end
    fprintf('\n');
end

% find doubles
ind = find(lengths > 1);
if ~isempty(ind)
    fprintf('\n\nfiles present more than once in the db:\n');
    fprintf('----------------------------\n');
    for fn = 1:length(ind)
        fprintf('%s\n', strrep(fls(ind(fn)).name, 'cnt', 'set'));
    end
    fprintf('\n');
end

% find files without ICA
hasica = db_hasica(db);