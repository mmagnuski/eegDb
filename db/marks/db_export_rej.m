function db_export_rej(db, r, types, pth)

% exports marks for given db record in a tab-separated dataframe format
% assumes segmented (consecutive epochs) data by using db(r).epoch.winlen
% to check segment length, not well suited for event-related epochs

% FIX!: needs to cope with the fact that some segments can be pre-rejected
% ADD option to export in samples or s

if ~exist('types', 'var') || isempty(types)
    types = {'reject'};
end

if ~exist('pth', 'var') || isempty(pth)
    pth = pwd;
end

if ~iscell(types)
    types = {types};
end

mark_names = {db(r).marks.name};
n_types = length(types);

try
    which_type = cellfun(@(x) find(strcmp(x, mark_names)), types);
catch %#ok<CTCH>
    error('Could not find some of the mark types');
end

% max marks length:
max_marks_len = max(cellfun(@length, {db(r).marks.value}));


% check post window numbering
% ---------------------------
prerej = db(r).reject.pre;
if ~isempty(prerej)

    % check how many were not removed (at least)
    spared = prerej(end) - length(prerej);

    % some windows extend beyond prerej
    if max_marks_len > 0
        tooshort = max_marks_len - spared;
    end

    if max_marks_len == 0 || tooshort < 0
        tooshort = 0;
    end

    % constuct pre and post window numbering
    full_pre_size = prerej(end) + tooshort;
    pre_win_nums = 1:full_pre_size;
    post_win_nums = pre_win_nums;
    post_win_nums(prerej) = [];
else
    full_pre_size = max_marks_len;
    post_win_nums = 1:max_marks_len;
end

% step through mark types, apply prerej window numbering
% and group marked windows into longer chunks
num_rej = zeros(1, n_types);
groups = cell(1, n_types);
for t = 1:n_types
    sm = sum(db(r).marks(which_type(1)).value);
    if sm > 0
        current_marks = false(full_pre_size, 1);
        marks_placement_post = db(r).marks(which_type(1)).value;
        marks_placement_pre = post_win_nums(...
            find(marks_placement_post)); %#ok<FNDSB>
        current_marks(marks_placement_pre) = true;
        grp = group(current_marks);
        groups{t} = grp(grp(:, 1) == 1, 2:3);
        num_rej(t) = size(groups{t}, 1);
    else
        num_rej(t) = 0;
    end
end

% finish early if no active marks were found
use_types = num_rej > 0;
if sum(use_types) == 0
    return
end

% select only active marks
types = types(use_types);
groups = groups(use_types);
num_rej = num_rej(use_types);
n_types = length(types);

max_rej = max(num_rej);
all_rej = zeros(max_rej, n_types * 2);

% turn units in windows to samples
for t = 1:n_types
    all_rej(1:num_rej(t), t * 2 - 1) = (groups{t}(:, 1) - 1) * ...
        db(r).epoch.winlen * db(r).datainfo.srate + 1;
    all_rej(1:num_rej(t), t * 2) = groups{t}(:, 2) * ...
        db(r).epoch.winlen * db(r).datainfo.srate;
end


% save in dataframe format
if isdir(pth)
    [~, fnm, ~] = fileparts(db(r).filename);
    % open file
    f = fopen(fullfile(pth, [fnm, '.rej']), 'w');
    % write header
    fprintf(f, 'start\tend\ttype\n');

    for t = 1:n_types
        rej = all_rej(:, t * 2 - 1:t * 2);
        rej = rej(rej(:,1) > 0, :);
        for i = 1:size(rej, 1)
            fprintf(f, '%d\t%d\t%s\n', rej(i,1), rej(i,2), types{t});
        end
    end
    fclose(f);
else
    error('Specified directory does not exist');
end
