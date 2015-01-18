function eegplot_readkey_new(hObj, evnt)

% eegplot_buttonpress_new implements a new
% buttonpress handler for eegplot

% TODOs:
% [x] implement 'nm' as next mark
% [x] 'pm' as previous mark?
% [x] 2m - two marks further
% [ ] think it over: this function has enough 
%     persistent values to be an object

persistent buffer
persistent patterns
persistent fullstr % may not be needed
persistent numstr
persistent nums
persistent selected_patterns

if isempty(nums)
    nums = '0123456789';
    nums = mat2cell(nums, 1, ones(1, length(nums)));
end
if isempty(buffer)
    buffer = {};
end
if isempty(patterns)
    patterns{1,1} = {'num', 'leftarrow'};
    patterns{1,2} = {@eegplot2, 'drawp', 1};
    patterns{2,1} = {'num', 'rightarrow'};
    patterns{2,2} = {@eegplot2, 'drawp', 4};
    patterns{3,1} = {'num', 'n', 'm'};
    patterns{3,2} = {@eegplot2, 'drawp', 5, 'next'};
    patterns{4,1} = {'num', 'p', 'm'};
    patterns{4,2} = {@eegplot2, 'drawp', 5, 'prev'};
end
if isempty(selected_patterns)
    selected_patterns = patterns;
end

% CHANGE:
% we don't care about case so we don't want modifiers
if ~isempty(evnt.Modifier)
    return
end

% get pressed character and key
ch = evnt.Character;
k  = evnt.Key;

if ~isempty(k)
    % ifnumeric and numeric is in progress
    % merge with numeric element in buffer
    
    isnum = any(strcmp(k, nums));
    if isnum
        if isempty(numstr)
            numstr = k;
            % add to buffer:
            buffer{end + 1} = 'num';
        elseif strcmp(buffer{end}, 'num')
            numstr = [numstr, k];
        end
    else
        % add to buffer:
        buffer{end + 1} = k;
    end

    % check which patterns fit by length
    atlen = length(buffer);
    pat_len = cellfun(@length, selected_patterns(:,1));
    take_pat = find(pat_len >= atlen);
    selected_patterns = selected_patterns(take_pat,:);
    kill = true(size(selected_patterns(:,1)));

    % check which patterns fit by value
    for s = 1:length(take_pat)

        % numeric's are not obligatory
        if ~strcmp(buffer{atlen}, 'num') && ...
            strcmp(selected_patterns{s,1}{atlen}, 'num')
            selected_patterns{s,1}(atlen) = [];
        end

        % compare current:
        comp = strcmp(buffer{atlen}, selected_patterns{s,1}{atlen});

        if comp
            kill(s) = false;
        end
    end

    selected_patterns(kill,:) = [];

    % check if no patterns or pattern selected:
    if isempty(selected_patterns)
        % clear up:
        numstr = [];
        buffer = {};
        fullstr = [];
        % etc.
    elseif size(selected_patterns, 1) == 1 && ...
            length(selected_patterns{1,1}) == atlen
        % the pattern has been selected!
        fun = selected_patterns{1,2};

        if ~isempty(numstr)
            num = str2num(numstr);
            fun{end + 1} = num;
        end

        feval(fun{:});
        % clear up:
        numstr = [];
        buffer = {};
        fullstr = [];
        selected_patterns = [];
    end
end
