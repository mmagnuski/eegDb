function pattern = ICAw_scan4patterns(DIR, pat, varargin)

% NOHELPINFO

%%
% default parameters
verbose = true;

%%
% checking additional parameters

if nargin > 2
    adr = find(strcmp('verbose', varargin));
    if ~isempty(adr)
        verbose = varargin{adr + 1};
    end
end


%%
% looking for files in LOAD_DIR
pattern = prep_list(DIR, '*.set');

cnt.curr = 0;

% loop through files
for s = 1:length(pattern)
    loaded = load([DIR, pattern{s,1}], '-mat');
    EEGch = loaded.EEG;
    clear loaded
    eventpattern = event_pattern_search(EEGch, pat);
    pattern{s,2} = eventpattern;
    
    % notify about progress
    if verbose
        cnt.per = 1;
        cnt.maxl = 20;
        cnt.dsp = '.';
        
        cnt.curr = cnt.curr + 1;
        if floor(cnt.curr/cnt.per) > cnt.maxl
            fprintf('\n');
            cnt.curr = 1;
        end
        
        if mod(cnt.curr, cnt.per) == 0
            fprintf(cnt.dsp);
        end
    end
end

%% reduce:
nanny = cellfun(@isstruct, pattern(:,2));
pattern(~nanny, :) = [];

fld = fields(pattern{1,2});
empta = false(length(pat), 1);

for p = 1:size(pattern, 2)
    emp = false(length(fld), 1);
    
    for f = 1:length(fld)
        if isempty(pattern{p, 2})
            emp(f) = true;
        end
    end
    
    if sum(emp) == length(emp)
        empta(p) = true;
    end
end

pattern(empta, :) = [];


if verbose
    fprintf('\n');
end