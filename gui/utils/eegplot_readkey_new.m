function eegplot_readkey_new(hObj, evnt, hBox, new_pattern)

% eegplot_buttonpress_new implements a new
% buttonpress handler for eegplot

% TODOs:
% [ ] selector mode (?)
% [ ] consider adding variable arguments (varargin)
% [ ] change into an object?

persistent h
persistent buffer
persistent patterns
persistent fullstr % may not be needed
persistent numstr
persistent nums
persistent selected_patterns

if isempty(h)
    h = hObj;
end
if ~isequal(h, hObj)
    h = hObj;
    patterns = [];
end

if isempty(nums)
    nums = '0123456789';
    nums = mat2cell(nums, 1, ones(1, length(nums)));
end
if isempty(buffer)
    buffer = {};
end
if exist('new_pattern', 'var')
    patterns = new_pattern;
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
    patterns{5,1} = {'m'};
    patterns{5,2} = {@linkfun_select_mark, hObj};
    patterns{6,1} = {'a', 'm'};
    patterns{6,2} = {@add_rejcol_callb, hObj};
    patterns{7,1} = {'x'};
    patterns{7,2} = {@guifun_maxim_eegaxis, hObj};    
end

if isempty(selected_patterns)
    selected_patterns = patterns;
end
if ~exist('hBox', 'var')
    hBox = [];
end

% do not go further if no events to handle
if isempty(evnt)
    return
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
    fullstr = [fullstr, k];

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
        fullstr = '';
        % etc.
    elseif size(selected_patterns, 1) == 1 && ...
            length(selected_patterns{1,1}) == atlen
        % the pattern has been selected!
        fun = selected_patterns{1,2};
        if ~isempty(numstr)
            num = str2num(numstr);
            fun{end + 1} = num;
        end

        % clear up:
        numstr = [];
        buffer = {};
        fullstr = '';
        selected_patterns = [];
        update_hBox(hBox, fullstr);

        % evaluate action:
        feval(fun{:});
        
    end
    update_hBox(hBox, fullstr);    
end

function update_hBox(h, str)
if isempty(h) || ~ishandle(h)
    return
end
if ~isempty(str)
    if strcmp(get(h, 'Visible'), 'off')
        set(h, 'Visible', 'on');
    end
    set(h, 'String', str);
else
    set(h, 'Visible', 'off');
end
