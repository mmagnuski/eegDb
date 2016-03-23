function db_export_rej(db, r, types, pth)

% exports marks for given db record in a tab-separated dataframe format

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
for t = 1:n_tps
    num_rej(t) = sum(db(r).marks(which_type(t)).value);
end

use_types = num_rej > 0;
types = types(use_types);
num_rej = num_rej(use_types);
n_tps = length(types);
which_type = which_type(use_types);

max_rej = max(num_rej);
all_rej = zeros(max_rej, n_tps);

for t = 1:n_tps
    all_rej(1:num_rej(t), t) = find(db(r).marks(which_type(t)).value);
end


if isdir(pth)
    [~, fnm, ~] = fileparts(db(r).filename);
    % open file
    f = fopen(fullfile(pth, [fnm, '.rej']), 'w');
    % write header
    for t = 1:n_tps
        if t > 1
            fprintf(f, '\t');
        end
        fprintf(f, types{t});
    end
    fprintf(f, '\n');
    for l = 1:max_rej
        for t = 1:n_tps
            if t > 1
                fprintf(f, '\t');
            end
            fprintf(f, '%d', all_rej(l, t));
        end
        fprintf(f, '\n');
    end
    fclose(f);
    
else
    error('Specified directory does not exist');
end
