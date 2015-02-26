classdef fastplot < handle
    
    % Properties:
    % h        -  structure of handles to:
    %     fig         - fastplot figure
    %     ax          - axis with eeg signal
    %     lines       - eeg signal lines
    %     eventlines  - lines showing event timing
    %     eventlabels - labels showing event type
    
    % REMEMBER
    % opt could contain data_names field that could inform the
    % user about the name of currently displayed dataset


    % currently - one epoch at time
    properties (SetAccess = private, GetAccess = public)
        h      % handles to the graphical objects
        opt    % options (what goes here?)
        epoch  % info about epochs
        event  % info about events
        marks  % info about marks
        spacing  % should be in opts?
        data
        data2
        data_size   % pack into a struct?
        window
    end

    properties (SetAccess = public, GetAccess = public)
        scrollmethod
    end
    
    % TODOs:
    % [ ] - think about adding time-pointers to events so that extensively
    % comparing events latency with current time window happens only once
    % [ ] - think about making faster version unique - specifically for
    %       cell arrays of strings
    % [ ] - check plotting against graphics performance tips:
    % http://www.mathworks.com/help/matlab/graphics-performance.html
    
    % PUBLIC METHODS
    % --------------
    methods
        
        function obj = fastplot(EEG, varargin)
            % define some of the class properties
            orig_size = size(EEG.data);
            obj.data_size = [orig_size(1), orig_size(2) * orig_size(3)];
            obj.data = reshape(EEG.data, obj.data_size)';
            obj.data_size = fliplr(obj.data_size);

            % default scroll method
            obj.scrollmethod = 'allset';
            obj.opt.readfield = {'data'};
            obj.opt.readfrom = 1;
            
            % get event and epoch info
            obj.get_epoch(EEG, orig_size);
            
            % calculate spacing
            obj.opt.chan_sd = std(obj.data, [], 1);
            obj.spacing = 2 * mean(obj.opt.chan_sd);
            obj.arg_parser(varargin);

            chan_pos = (0:obj.data_size(2)-1)*obj.spacing;

            % introduce spacing to the data
            obj.data = obj.data - repmat(...
                chan_pos, [obj.data_size(1), 1]);

            % electrode position
            obj.opt.electrode_names = {EEG.chanlocs.labels};
            obj.opt.electrode_positions = -chan_pos;
            obj.opt.ylabels = fliplr(obj.opt.electrode_names(5:5:end));
            obj.opt.ypos    = fliplr(obj.opt.electrode_positions(5:5:end));
            
            % window limits and step size
            obj.window.size = 1000;
            obj.window.lims = [1, obj.window.size];
            obj.window.span = obj.window.lims(1):obj.window.lims(2);
            obj.window.step = 1000;
            
            % get screen resolution:
            unts = get(0, 'unit');
            ifpix = strcmp(unts, 'pixel');
            if ~ifpix; set(0, 'unit', 'pixel'); end
            obj.opt.scrsz = get(0, 'ScreenSize');
            obj.opt.scrsz = obj.opt.scrsz([3, 4]);
            if ~ifpix; set(0, 'unit', unts); end
            % launch the plot
            obj.launchplot();
        end
        
        
        function refresh(obj, mthd) % should check if sth actually changed
            % during re-plotting:
            % always use set 'XData', 'YData'
            obj.window.span = obj.window.lims(1):obj.window.lims(2);
            
            if ~exist('mthd', 'var')
                mthd = obj.scrollmethod;
            end
            
            tic;
            dat = obj.(obj.opt.readfield{obj.opt.readfrom});
            switch mthd
                case 'replot'
                    delete(obj.h.lines);
                    obj.h.lines = plot(dat(obj.window.span, :));
                case 'allset'
                    dat = mat2cell(dat(obj.window.span, :), ...
                        diff(obj.window.lims) + 1, ones(1, ...
                        obj.data_size(2)))';
                    set(obj.h.lines, {'YData'}, dat, 'HitTest', 'off');
                case 'loopset'
                    for i = 1:length(obj.h.lines)
                        set(obj.h.lines(i), 'YData', ...
                            dat(obj.window.span, i), 'HitTest', 'off');
                    end
            end
            obj.plotevents();
            obj.plot_epochlimits();
            obj.plot_marks();
            timetaken = toc;
            fprintf('time taken: %f\n', timetaken);
        end
        
        
        function move(obj, value, mlt, unit)
            % CHANGE - mlt is temporary
            % ADD - mode of window.step?
            if ~exist('value', 'var')
                value = 1;
            end
            % do not go further if move is not possible
            if value == 0 || ...
                    ((obj.window.lims(1) == 1) && value < 0) ...
                    || ((obj.window.lims(2) == obj.data_size(1)) ...
                    && value > 0)
                return
            end
            
            if ~exist('mlt', 'var')
                mlt = 1;
            end
            if ~exist('unit', 'var')
                unit = obj.window.step;
            end
            
            % create and test new window limits
            wlims = obj.window.lims + mlt * value * unit;
            if value > 0 && wlims(2) > obj.data_size(1)
                wlims(2) = obj.data_size(1);
                wlims(1) = max([1, wlims(2) - obj.window.size + 1]);
            end
            if value < 0 && wlims(1) < 1
                wlims(1) = 1;
                wlims(2) = min([obj.data_size(1), ...
                    wlims(1) + obj.window.size - 1]);
            end
            obj.window.lims = wlims;
            obj.refresh();
        end
            
        
        % maybe should be private? :
        function ev = events_in_range(obj, rng)
            % default - range in samples
            % default - range from winlim
            if ~exist('rng', 'var')
                rng = obj.window.lims;
            end
            % look for event with latency within given range
            lookfor = obj.event.latency >= rng(1) & ...
                obj.event.latency <= rng(2);
            if any(lookfor)
                % return event latency and type
                ev.latency = obj.event.latency(lookfor);
                ev.type = obj.event.type(lookfor);
            else
                % return empty struct if none events found
                ev.latency = [];
                ev.time = [];
            end
        end

        function ep = epochlimits_in_range(obj, rng)
            % default - range in samples
            % default - range from winlim
            ep.latency = [];

            if isempty(obj.epoch)
                return
            end
            if ~exist('rng', 'var')
                rng = obj.window.lims;
            end
            % look for event with latency within given range
            lookfor = obj.epoch.limits >= rng(1) & ...
                obj.epoch.limits <= rng(2);
            if any(lookfor)
                % return event latency and type
                ep.latency = obj.epoch.limits(lookfor);
                ep.nums = find(lookfor);
                ep.nums = [ep.nums, ep.nums(end)+1];
            end
        end
        
    end


    % PRIVATE METHODS
    % ---------------
    methods (Access = private)
        
        function arg_parser(obj, args)
            % helper function that lets to parse matlab style arguments
            % (why oh why matlab doesn't have named function arguments?)
            
            if isempty(args)
                return
            end
            first_char = find(cellfun(@ischar, args));
            if isempty(first_char) || (~isempty(first_char) && first_char > 1)
                % some non-named arguments were given
                % check if EEG struct
                if isstruct(args{1}) && isfield(args{1}, 'data')
                    % another EEG data coming in!
                    obj.data2 = reshape(args{1}.data, fliplr(obj.data_size))';

                    % introduce spacing to data2:
                    obj.data2 = obj.data2 - repmat(...
                        (0:obj.data_size(2)-1)*obj.spacing, [obj.data_size(1), 1]);
                    obj.opt.readfield(end + 1) = {'data2'};
                end
            end

            % now check for 'data2' argument
            if ~isempty(first_char)
                str_args = args(first_char:end);
                ifkey = strcmp('data2', str_args);
                if any(ifkey)
                    ind = find(ifkey);
                    ind = ind(1);
                    obj.data2 = str_args{ind + 1};
                    obj.opt.readfield(end + 1) = {'data2'};
                end
            end
        end
                    

        function launchplot(obj)
            % figure setup
            ss = obj.opt.scrsz;
            obj.h.fig = figure('Position', [10, 50, ...
                ss(1)-20, ss(2)-200], 'Toolbar', 'none', ...
                'Menubar', 'none');
            obj.h.ax = axes('Position', [0.05, 0.05, 0.9, 0.85]);

            obj.h.eventlines = [];
            obj.h.eventlabels = [];
            obj.h.epochlimits = [];
            obj.h.backpatches = [];
            
            % plot data
            % ---------
            % CHANGE!
            % use 'ColorOrder' to set color of electrodes
            obj.h.lines = plot(obj.data(obj.window.span, :), 'HitTest', 'off');
            
            % set y limits and y lim mode (for faster replotting)
            obj.h.ylim = [-(obj.data_size(2)+1) * obj.spacing,...
                obj.spacing];
            set(obj.h.ax, 'YLim', obj.h.ylim, 'YLimMode', 'manual');
            
            % label electrodes
            set(obj.h.ax, 'YTickMode', 'manual');
            set(obj.h.ax, 'YTickLabelMode', 'manual');
            set(obj.h.ax, 'YTick', obj.opt.ypos);
            set(obj.h.ax, 'YTickLabel', obj.opt.ylabels);
            
            % plot events
            obj.plotevents();
            % plot epoch limits
            obj.plot_epochlimits();
            
            % set keyboard shortcuts
            obj.init_keypress();
            % set click callback
            set(obj.h.ax, 'ButtonDownFcn', @(h, e) obj.testButtonPress());

        end
        
        
        function get_epoch(obj, EEG, orig_size)
            obj.event.latency = [EEG.event.latency];
            % later add compressed lat for example by:
            % obj.event.latency(25:25:end);
            % also latency limits would be nice to have:
            % obj.event.latlims = obj.event.latency([1, end]);

            % code event types with integers
            temptype = {EEG.event.type};
            obj.event.alltypes = unique(temptype);
            sz = size(obj.event.alltypes);
            if sz(2) > sz(1)
                obj.event.alltypes = obj.event.alltypes';
            end
            obj.event.numtypes = length(obj.event.alltypes);
            type2ind = cellfun(@(x) find(strcmp(x, temptype)), ...
                obj.event.alltypes, 'UniformOutput', false);
            obj.event.type = zeros(length(temptype),1);
            for i = 1:obj.event.numtypes
                obj.event.type(type2ind{i}) = i;
            end

            % CHANGE
            % event colors - random at the moment
            obj.event.color = rand(obj.event.numtypes,3);

            % get epoch info:
            obj.opt.srate = EEG.srate;
            obj.opt.stime = 1000 / EEG.srate;
            % obj.opt.halfsample = obj.opt.stime / 2;
            if length(orig_size) > 2 && orig_size(3) > 1
                obj.epoch.mode = true;
                obj.epoch.num = orig_size(3);
                obj.epoch.limits = orig_size(2):orig_size(2):obj.data_size(1) + obj.opt.stime / 2;

                % marks
                obj.marks.names    = {'reject'};
                obj.marks.colors   = [0.85, 0.3, 0.1];
                obj.marks.current  = 1;
                obj.marks.selected = false(1, obj.epoch.num);
            end
        end


        function plotevents(obj)
            % reuse lines and labels
            numlns = length(obj.h.eventlines);
            
            % get events to plot
            ev = obj.events_in_range();
            numev = length(ev.latency);

            % check how many events to plot compared
            % to those already present
            plot_diff = numev - numlns;

            % hide unnecessary lines and tags
            if plot_diff < 0
                inds = numlns:-1:numlns + plot_diff + 1;
                set(obj.h.eventlines(inds), ...
                    'Visible', 'off'); % maybe set HitTest to 'off' ?
                set(obj.h.eventlabels(inds), ...
                    'Visible', 'off');
            end

            if numev > 0
                % get necessary info to plot:
                ylim = obj.h.ylim;
                ev.latency = ev.latency - obj.window.lims(1);
                lineX = repmat(ev.latency, [2, 1]);
                lineY = repmat(ylim', [1, numev]);
                labelX = double(ev.latency');
                labelY = double(repmat(obj.spacing * 2, [numev, 1]));
                colors = mat2cell(obj.event.color(ev.type, :), ones(numev, 1), 3);
                strVal = obj.event.alltypes(ev.type);

                % how many elements to reuse, how many new to draw:
                reuse = min([numev, numlns]);
                drawnew = max([0, plot_diff]);

                if numlns > 0
                    % set available lines and labels

                    % create indexer
                    ind = 1:reuse;
                    % create necessary data in cell format
                    X = mat2cell(lineX(:, ind), 2, ones(reuse, 1))';
                    Y = mat2cell(lineY(:, ind), 2, ones(reuse, 1))';
                    pos = mat2cell([labelX(ind), labelY(ind)], ones(reuse, 1), 2);

                    % set lines
                    set(obj.h.eventlines(ind), {'XData', 'YData', 'Color'}, ...
                        [X, Y, colors(ind)], 'Visible', 'on');
                    % set labels (this takes the longest - maybe change)
                    set(obj.h.eventlabels(ind), {'Position', 'String', 'BackgroundColor'}, ...
                        [pos, strVal(ind), colors(ind)], 'Visible', 'on');
                end

                if drawnew > 0
                    % draw new lines and labels

                    % create indexer
                    ind = reuse+1:(reuse + drawnew);

                    hold on; % change to myHoldOn later on

                    % lines
                    obj.h.eventlines(ind) = line(lineX(:,ind), ...
                        lineY(:,ind), 'LineWidth', 2.5);
                    set(obj.h.eventlines(ind), {'Color'},...
                        colors(ind));

                    % labels
                    try
                    obj.h.eventlabels(ind) = text(labelX(ind), labelY(ind), ...
                        strVal(ind), {'BackgroundColor'}, colors(ind), ...
                        'Margin', 2.5, 'VerticalAlignment', 'bottom', ...
                        'clipping', 'off');
                    catch
                        for i = ind
                            obj.h.eventlabels(i) = text(labelX(i), labelY(i), ...
                                strVal(i), 'BackgroundColor', colors{i}, ...
                                'Margin', 2.5, 'VerticalAlignment', 'bottom', ...
                                'clipping', 'off');
                        end
                    end

                    hold off; % change to myHoldOff later

                end
            end

        end


        function plot_epochlimits(obj)
            % check what epoch limits are in range
            ep = epochlimits_in_range(obj);
            ep.latency = ep.latency - obj.window.lims(1);
            obj.epoch.current_limits = ep.latency;
            obj.epoch.current_nums = ep.nums;

            if ~isempty(ep)
                drawnlims = length(obj.h.epochlimits);
                newlims = length(ep.latency);

                plot_diff = newlims - drawnlims;

                % hide unnecessary lines and tags
                if plot_diff < 0
                    inds = drawnlims:-1:drawnlims + plot_diff + 1;
                    set(obj.h.epochlimits(inds), ...
                        'Visible', 'off'); % maybe set HitTest to 'off' ?
                end

                reuse = min([newlims, drawnlims]);
                drawnew = max([0, plot_diff]);

                ylm = obj.h.ylim + [-20, 20];
                xDat = repmat(ep.latency, [2, 1]);
                yDat = repmat(ylm', [1, newlims]);

                % change those present
                if reuse > 0
                    ind = 1:reuse;
                    xDt = mat2cell(xDat(:, ind), 2, ones(reuse, 1))';
                    yDt = mat2cell(yDat(:, ind), 2, ones(reuse, 1))';
                    
                    set(obj.h.epochlimits(ind), {'XData', 'YData'}, ...
                        [xDt, yDt], 'Visible', 'on');
                end

                % draw new
                if drawnew > 0
                    ind = reuse+1:newlims;
                    obj.h.epochlimits(ind) = line(xDat(:,ind), ...
                        yDat(:, ind), 'Color', [0, 0, 0], ...
                        'LineWidth', 3);
                end
            end

        end

        
        function init_keypress(obj)
            % create shortcut patterns:
            pattern{1,1} = {'num', 'leftarrow'};
            pattern{1,2} = {@obj.move, -1};
            pattern{2,1} = {'num', 'rightarrow'};
            pattern{2,2} = {@obj.move, 1};
            pattern{3,1} = {'uparrow'};
            pattern{3,2} = {@obj.swap, 1};
            pattern{4,1} = {'downarrow'};
            pattern{4,2} = {@obj.swap, 2};
            
            % initialize 
            eegplot_readkey_new([], [], [], pattern);
            
            % add eegplot_readkey to WindowKeyPressFcn
            set(obj.h.fig, 'WindowKeyPressFcn', @eegplot_readkey_new);
        end


        function testButtonPress(obj)
            % axesHandle  = get(objectHandle,'Parent');
            coord = get(obj.h.ax,'CurrentPoint');
            coord = coord(1, 1:2);
            % fprintf('x: %1.2f, y: %1.2f\n', coord(1), coord(2));

            % test where x is located relative to epoch.current_limits
            if obj.epoch.mode
                x = coord(1);
                if ~(obj.epoch.current_limits(1) == 0)
                    epoch_lims = [0, obj.epoch.current_limits];
                else
                    epoch_lims = obj.epoch.current_limits;
                end

                % check which epoch was clicked
                selected = obj.epoch.current_nums(...
                    find(x > epoch_lims, 1, 'last'));

                c = obj.marks.current;
                if obj.marks.selected(c,selected)
                    obj.marks.selected(c,selected) = false;
                else
                    obj.marks.selected(c,selected) = true;
                end

                % plot the change
                obj.plot_marks();
            end
        end


        function swap(obj, val)
            % maybe change name to swapdata or dataswap
            % CHANGE - the tests should be a little more elaborate
            if length(obj.opt.readfield) > 1
                obj.opt.readfrom = val;
                obj.refresh();
            end
        end

        function plot_marks(obj)
            % get selected epochs
            epoch_lims = obj.epoch.current_limits;
            epoch_num = obj.epoch.current_nums;
            selected  = find(obj.marks.selected(1, epoch_num));
            
            % hide unnecessary patches
            oldnum = length(obj.h.backpatches);
            newnum = length(selected);
            plot_diff = newnum - oldnum;
            
            if plot_diff < 0
                inds = oldnum:-1:oldnum + plot_diff + 1;
                set(obj.h.backpatches(inds), ...
                    'Visible', 'off'); % maybe set HitTest to 'off' ?
            end

            if ~isempty(selected)
                reuse = min([newnum, oldnum]);
                drawnew = max([0, plot_diff]);

                % create vertices
                % ---------------

                % add edges to epoch_lims
                if ~(epoch_lims(1) == 0)
                    pre = 0;
                end
                if ~(epoch_lims(end) == 1000) %window.length
                    post = 1000;
                end
                epoch_lims = [pre, epoch_lims, post];

                % init vertices
                ylm = obj.h.ylim;
                vert = repmat(ylm([1, 1, 2, 2])', [1, newnum*2]);
                sel = [selected; selected + 1];
                x = reshape(epoch_lims(sel(:)), [2, numel(sel)/2]);
                vert(:,1:2:end) = [x; flipud(x)];
                vert = mat2cell(vert, 4, ones(newnum, 1) * 2)';

                % init colors
                colors = mat2cell(obj.marks.colors(ones(newnum, 1), :), ...
                    ones(newnum, 1), 3);
                % faces are always 1:4 so need to init

                % CHANGE:
                % change those present
                if reuse > 0
                    ind = 1:reuse;

                    set(obj.h.backpatches(ind), {'Vertices'}, ...
                        vert(ind), 'Faces', 1:4, 'Visible', 'on');
                end

                % draw new
                if drawnew > 0
                    ind = reuse+1:newnum;
                    obj.h.backpatches(ind) = patch({'Vertices', 'FaceColor'}, ...
                        [vert(ind), colors(ind)], 'Faces', 1:4, ...
                        'EdgeColor', 'none', 'HitTest', 'off');
                    uistack(obj.h.backpatches(ind), 'bottom');
                end
            end
        end

    end
    
    
end