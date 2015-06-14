classdef KeyboardManager < handle

% eegplot_buttonpress_new implements a new
% buttonpress handler for eegplot

% TODOs:
% [ ] finish eval method
% [ ] add a method to clear registered patterns
% [ ] think how registering method should work

properties (SetAccess = private, GetAccess = public)
    h
    buffer
    patterns
    fullstr
    numstr
    nums
    selected
    hBox
end

methods

    function obj = KeyboardManager(h, varargin)
        obj.h = h;
        obj.patterns = {};
        obj.selected = {};
        obj.nums = mat2cell('0123456789', 1, ones(1, 10));
        obj.numstr = [];
        obj.buffer = {};
        obj.hBox = [];

        opt.hbox = [];
        opt = parse_arse(varargin, opt);

        if ~isempty(opt.hbox)
            obj.hBox = opt.hbox;
        end
    end

    function eval(obj, string)
        % KeyboardManager.eval() allows to evaluate strings
        % as if they were actual sequences of keyboard button presses

        string_chars = mat2cell(string, 1, ones(1, length(string)));
        rgt = cellfun(@(x) x == '>', string_chars);
        lft = cellfun(@(x) x == '<', string_chars);
        string_chars(rgt) = {'rightarrow'};
        string_chars(lft) = {'leftarrow'};

        % pass character by character to read function:
        for k = string_chars
            ev.Modifier = [];
            ev.Key = k{1};
            obj.read(ev);
        end
    end

    function register(obj, patterns)
        % KeyboardManager.register() allows to register specific
        % sequences of key presses and link them to evaluation of
        % specific functions
        % FIXHELPINFO

        obj.patterns = [obj.patterns; patterns];
        if isempty(obj.buffer)
            obj.selected = obj.patterns;
        end
    end

    function read(obj, event)
        % read keypress event and act on it
        % if it completes a matching registered pattern

        % do not go further if no events to handle
        if isempty(event)
            return
        end
        % currently we don't care about case and modifiers
        if ~isempty(event.Modifier)
            return
        end
        % get pressed character and key
        % (currently we only use key, but
        %  this may change in the future)
        k  = event.Key;

        if ~isempty(k)
            obj.update_buffer(k);
            obj.select();
            obj.check_selected();
            obj.update_hBox();    
        end
    end
end


methods (Access = private)

    function select(obj)
        % check which patterns fit by length
        atlen = length(obj.buffer);
        % CHANGE pattern length should be cached
        pat_len = cellfun(@length, obj.selected(:,1));
        take_pat = (pat_len >= atlen);
        obj.selected = obj.selected(take_pat,:);

        % check which patterns fit by value
        kill = true(size(obj.selected(:,1)));
        for s = 1:size(obj.selected, 1)

            % numeric's are not obligatory
            if ~strcmp(obj.buffer{atlen}, 'num') && ...
                strcmp(obj.selected{s,1}{atlen}, 'num')
                obj.selected{s,1}(atlen) = [];
            end

            % compare current:
            comp = strcmp(obj.buffer{atlen}, obj.selected{s,1}{atlen});

            if comp
                kill(s) = false;
            end
        end
        obj.selected(kill,:) = [];
    end


    function check_selected(obj)
        % check if no patterns or pattern selected:
        if isempty(obj.selected)
            obj.reset();
        elseif size(obj.selected, 1) == 1 && ...
                length(obj.selected{1,1}) == length(obj.buffer)
            % the pattern has been selected!
            fun = obj.selected{1,2};
            if ~isempty(obj.numstr)
                num = str2num(obj.numstr); %#ok<ST2NM>
                fun{end + 1} = num;
            end

            obj.update_hBox();
            obj.reset();

            % evaluate action:
            feval(fun{:});
        end
    end

    function update_buffer(obj, k)
        % check if key is numeric:
        % if numeric and numeric is in progress
        % merge with numeric element in buffer
        isnum = any(strcmp(k, obj.nums));
        if isnum
            if isempty(obj.numstr)
                obj.numstr = k;
                % add to buffer:
                obj.buffer{end + 1} = 'num';
            elseif strcmp(obj.buffer{end}, 'num')
                obj.numstr = [obj.numstr, k];
            end
        else
            % add to buffer:
            obj.buffer{end + 1} = k;
        end
        obj.fullstr = [obj.fullstr, k];
    end

    function reset(obj)
        % clear up:
        obj.numstr = [];
        obj.buffer = {};
        obj.fullstr = '';
        obj.selected = obj.patterns;
    end

    function update_hBox(obj)
        if isempty(obj.hBox) || ~ishandle(obj.hBox)
            return
        end
        if ~isempty(obj.fullstr)
            if strcmp(get(obj.hBox, 'Visible'), 'off')
                set(obj.hBox, 'Visible', 'on');
            end
            set(obj.hBox, 'String', obj.fullstr);
        else
            set(obj.hBox, 'Visible', 'off');
        end
    end
end

end