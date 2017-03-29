function db_export_rej(db, r, types, pth)

% exports marks for given db record in a tab-separated dataframe format
% assumes segmented (consecutive epochs) data by using db(r).epoch.winlen
% to check segment length, not well suited for event-related epochs

% FIX!: needs to cope with the fact that some segments can be pre-rejected
% ADD option to export in samples or s

if ~exist('types', 'var') || isempty(types)
    types = {'reject'};
end

if ~iscell(types)
    types = {types};
end

ev_nm = {db(r).marks.name};
n_tps = length(types);

try
    which_type = cellfun(@(x) find(strcmp(x, ev_nm)), types);
catch %#ok<CTCH>
    error('Could not find some of the mark types');
end

num_rej = zeros(1, n_tps);
groups = cell(1, n_tps);
for t = 1:n_tps
    sm = sum(db(r).marks(which_type(t)).value);
    if sm > 0
        grp = group(db(r).marks(which_type(t)).value);
        groups{t} = grp(grp(:,1) == 1, 2:3);
        num_rej(t) = size(groups{t}, 1);
    else
        num_rej(t) = 0;
    end
end

use_types = num_rej > 0;
if sum(use_types) == 0
    return
end
types = types(use_types);
groups = groups(use_types);
num_rej = num_rej(use_types);
n_tps = length(types);

max_rej = max(num_rej);
all_rej = zeros(max_rej, n_tps*2);

% translate segment number to time range in samples
for t = 1:n_tps
    all_rej(1:num_rej(t), t*2-1) = (groups{t}(:,1)-1) * ...
        db(r).epoch.winlen * db(r).datainfo.srate + 1;
    all_rej(1:num_rej(t), t*2) = groups{t}(:,2) * ...
        db(r).epoch.winlen * db(r).datainfo.srate;
end


if isdir(pth)
    [~, fnm, ~] = fileparts(db(r).filename);
    % open file
    f = fopen(fullfile(pth, [fnm, '.rej']), 'w');
    % write header
    fprintf(f, 'start\tend\ttype');
    
    fprintf(f, '\n');
        for t = 1:n_tps
            rej = all_rej(:, t*2-1:t*2);
            rej = rej(rej(:,1) > 0, :);
            for i = 1:size(rej, 1)
                fprintf(f, '%d\t%d\t%s\n', rej(i,1), rej(i,2), types{t});
            end
        end
    fclose(f);
else
    error('Specified directory does not exist');
end
