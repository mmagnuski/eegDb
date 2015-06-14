classdef fastplot < handle
    
    % fastplot is a fast and friendly signal plotter.
    % 
    % plt = fastplot(EEG);
    %
    % input
    % -----
    % EEG - eeglab EEG structure, must have following fields:
    %    .data
    %    .srate
    %    .epoch
    %    .event
    %    .times
    %    
    %
    % the output is a fastplot object
    % fastplot properties:
    % --------------------
    % h        -  structure of handles to:
    %     fig         - fastplot figure
    %     ax          - axis with eeg signal
    %     lines       - eeg signal lines
    %     eventlines  - lines showing event timing
    %     eventlabels - labels showing event type
    %
    % epoch    -  structure with information about epochs
    %      mode    - whether signal has epochs or not (epoch mode)
    %      num     - how many epochs are present in the data
    %      limits  - what are the limits of each epoch
    %
    % marks    -  structure containing information about marks
    %             (marks should optimally have different name AND color)
    %             contains following fields:
    %     names       - cell array of mark names
    %     colors      - M by 3 matrix of mark colors (M - number of marks)
    %     current     - integer; informs which mark is currently selected
    %     selected    - M by E boolean matrix; informs which epochs are marked
    %                   with which mark types (M - number of marks, E - number
    %                   of epochs)
    % opt      -  various options, including:
    %    .step    - step values for different movement and scaling types:
    %         .epoch_move
    %         .epoch_scale
    %         .signal_scale
    % keys     -  a KeyboardManager instance - it is responsible for keyboard
    %             interactions with the gui including sequences of key presses

    % REMEMBER
    % opt could contain data_names field that could inform the
    % user about the name of currently displayed dataset


    % PROPERTIES - PRIVATE
    % --------------------
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
        keys
    end

    % PROPERTIES - PUBLIC
    % -------------------
    properties (SetAccess = public, GetAccess = public)
        scrollmethod
    end
    
    % TODOs:
    % [ ] - check profiling and then only worry about optimisation
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

            % default opt settings
            obj.opt.step.move_unit = 'epoch';
            obj.opt.step.move = 1;
            obj.opt.step.epoch_scale = 1;

            % check varargin for 'comp' or 'chan'
            isind = false;
            show_signal = 'chan';
            ischan = strcmp('chan', varargin);
            if any(ischan)
                where = find(ischan);
                isind = true;
            end

            if ~isind
                iscomp = strcmp('comp', varargin);
                if any(iscomp)
                    show_signal = 'comp';
                    where = find(iscomp);
                    isind = true;
                end
            end

            % check comp vs chan and inds
            % eeg_getdataact
            if ~isind
                signal_ind = 1:EEG.nbchan;
            else
                signal_ind = varargin{where + 1};
            end

            % define some of the class properties
            if strcmp(show_signal, 'comp')
                obj.opt.electrode_names = arrayfun(@(x) ...
                    ['IC', num2str(x)], signal_ind, 'Uni', false);
                obj.data = get_ica_data(EEG, signal_ind);
            else
                obj.opt.electrode_names = { ...
                    EEG.chanlocs(signal_ind).labels};
                obj.data = EEG.data(signal_ind, :, :);
            end

            orig_size = size(obj.data);
            obj.opt.nbchan = orig_size(1);
            obj.data_size = [orig_size(1), orig_size(2) * orig_size(3)];
            obj.data = reshape(obj.data, obj.data_size)';
            obj.data_size = fliplr(obj.data_size);

            % default scroll method
            obj.scrollmethod = 'allset'; % how signal refresh is performed

            % default options
            obj.opt.num_epoch_per_window = 3; % this should be set via options
            obj.opt.readfield = {'data'}; % later - add support for multiple fields
            obj.opt.readfrom = 1;

            % calculate spacing and scale step
            obj.opt.chan_sd = std(obj.data, [], 1); % this kind of thing can be in info property
            obj.opt.step.signal_scale = 0.1;
            obj.opt.signal_scale = 1;
            obj.spacing = 4.5 * mean(obj.opt.chan_sd);
            obj.arg_parser(varargin); % arg_parser should be used at the top

            chan_pos = (0:obj.data_size(2)-1)*obj.spacing;

            % set y limits
            obj.h.ylim = [-(obj.data_size(2)+1) * obj.spacing,...
                obj.spacing];

            % get event and epoch info
            obj.get_epoch(EEG, orig_size);

            % electrode position
            obj.opt.electrode_positions = -chan_pos;
            if obj.opt.nbchan > 20
                chanind = 5:5:obj.opt.nbchan;
            elseif obj.opt.nbchan > 10
                chanind = 2:2:obj.opt.nbchan;
            else
                chanind = 1:obj.opt.nbchan;
            end

            obj.opt.ylabels = fliplr(obj.opt.electrode_names(chanind));
            obj.opt.ypos    = fliplr(obj.opt.electrode_positions(chanind));

            % window limits and step size
            obj.window.size = length(obj.epoch.time) * obj.opt.num_epoch_per_window;
            obj.window.lims = [1, obj.window.size];
            obj.window.span = obj.window.lims(1):obj.window.lims(2);
            obj.window.step = length(obj.epoch.time);

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


        function refresh(obj, elements, mthd)
            % refresh fastplot window

            % CHANGE maybe should check if sth actually changed

            % during re-plotting:
            % always use set 'XData', 'YData'
            obj.window.span = obj.window.lims(1):obj.window.lims(2);
            if ~exist('elements', 'var')
                elements = {'all'};
            elseif ~iscell(elements)
                elements = {elements};
            end
            
            if ~exist('mthd', 'var')
                mthd = obj.scrollmethod;
            end

            if any(strcmp('all', elements))
                refresh_elem = true(4, 1);
            else
                elem_order = {'signal', 'events', 'limits', 'marks'}';
                refresh_elem = cellfun(@(x) any(strcmp(x, elements)), ...
                    elem_order);
            end
            
            % tic;
            if refresh_elem(1)
                chan_pos = (0:obj.data_size(2)-1)*obj.spacing;

                dat = obj.(obj.opt.readfield{obj.opt.readfrom}) * ...
                    obj.opt.signal_scale;
                dat = bsxfun(@minus, dat(obj.window.span, :), chan_pos);
                switch mthd
                    case 'replot'
                        delete(obj.h.lines);
                        obj.h.lines = plot(dat);
                    case 'allset'
                        dat = mat2cell(dat, diff(obj.window.lims) + 1, ...
                            ones(1, obj.data_size(2)))';
                        set(obj.h.lines, {'YData'}, dat, 'HitTest', 'off');
                    case 'loopset'
                        for i = 1:length(obj.h.lines)
                            set(obj.h.lines(i), 'YData', ...
                                dat(:, i), 'HitTest', 'off');
                        end
                end
            end
            if refresh_elem(2); obj.plotevents(); end;
            if refresh_elem(3); obj.plot_epochlimits(); end;
            if refresh_elem(4); obj.plot_marks(); end;
            % timetaken = toc;
            % fprintf('time taken: %f\n', timetaken);
        end
        
        
        function move(obj, value, unit, mlt)
            % move the current view a number of units.
            %
            % fastplot.move(value, unit)
            % 
            % value:
            % positive value indicates forward motion
            % negative value indicates backward motion
            %
            % unit:
            % 'epoch'
            % 'window'

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
            if ~exist('unit', 'var') || isempty(unit)
                unit = obj.window.step;
            elseif strcmp(unit, 'window')
                unit = obj.window.size;
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
            % gives latency of events that are
            % present within given range. If no range
            % is given, the range of current fastplot
            % view is taken.
            %
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

        function scale_signal(obj, val, num)

            if ~exist('num', 'var')
                num = 1;
            end

            obj.opt.signal_scale = obj.opt.signal_scale + ...
                obj.opt.step.signal_scale * val * num;
            obj.opt.signal_scale = max([0, obj.opt.signal_scale]);

            obj.refresh('signal');
        end

        function ep = epochlimits_in_range(obj, rng)
            % gives latency of epoch limits that are
            % present within given range. If no range
            % is given, the range of current fastplot
            % view is taken.
            %
            % default - range in samples
            % default - range from winlim

            ep.latency = [];

            if isempty(obj.epoch)
                return
            end
            if ~exist('rng', 'var')
                rng = obj.window.lims;
            end
            % look for epochs with latency within given range
            lookfor = obj.epoch.limits >= rng(1) & ...
                obj.epoch.limits <= rng(2);
            if any(lookfor)
                % return event latency and type
                ep.latency = obj.epoch.limits(lookfor);
                ep.nums = find(lookfor);
                if ~(ep.nums(end) == obj.epoch.num)
                    ep.nums = [ep.nums, ep.nums(end)+1];
                end
            end
        end

        function add_mark(obj, mark)
            % allows to add new mark types to fastplot
            % this does not mark epochs but adds new mark types 
            % 
            % Arguments:
            % mark  - structure containing fields:
            %     name - string; name of the mark
            %     color - 1 by 3 matrix; color of the mark
            %
            % Example:
            % p = fastplot(EEG);
            % new_mark.name = 'new mark';
            % new_mark.color = [0.4, 0.7, 0.2];
            % p.add_mark(new_mark);
            %
            % see also: fastplot

            % CHANGE later - support for mark structs longer than one entry

            % check if input is correct
            if ~isstruct(mark)
                error('fastplot add_mark error: mark should be a structure');
            end

            flds = fields(mark);
            needs_fields = {'name', 'color'};
            has_fields = cellfun(@(x) any(strcmp(x, flds)), needs_fields);
            if ~all(has_fields)
                error(['fastplot add_mark error: mark structure should ',...
                    'contain both name and color fields;']);
            end

            % check if the name is not present:
            name_new = ~any(strcmp(mark.name, obj.marks.names));
            if ~name_new
                % currently pass silently, later maybe more checks
                return
            end

            % CONSIDER: pass mark to _add_mark 
            %           (private function without safety checks)

            % CHANGE - check color too

            % add mark to obj.marks
            obj.marks.names{end + 1} = mark.name;
            obj.marks.colors(end + 1, :) = mark.color;
            obj.marks.selected(end + 1, :) = false(1, ...
                length(obj.marks.selected(1,:)));
            obj.marks.lastclick(end + 1) = 0;

            % update num2vertx
            num_marks = length(obj.marks.names);
            obj.marks.num2vertx = arrayfun(@(x) create_vert_y(x, obj.h.ylim), ...
                1:num_marks, 'UniformOutput', false);

        end

        function gui_add_mark(obj)
            % ask for mark name:
            markname = gui_editbox('', {'Type mark name'; 'here:'});
            marknames = obj.marks.names;
            markcolors = obj.marks.colors;

            % if user aborts do not go any further
            if isempty(markname)
                return
            end

            % if the name is present in rejs ask for another
            while any(strcmp(markname, marknames))
                markname = gui_editbox('', {'This name is already in use.'; ...
                    'Please, try another.'});
                
                % if user aborts do not go any further
                if isempty(markname)
                    return
                end
            end

            % ask for mark color
            badcol = true;
            while badcol
                % gui for setting color
                c = uisetcolor;

                % check color:
                badcol = any(all(bsxfun(@eq, c, markcolors), 2));

                if badcol
                    warndlg(['This color is already in use, ', ...
                        'please choose another one.']);
                end
            end

            % now - use add_mark to add new mark
            new_mark = struct('name', markname, 'color', c);
            obj.add_mark(new_mark);
        end


        function use_mark(obj, mark)
            % allows to select given mark type as currently active.
            % 
            % Arguments:
            % mark - integer indicating which mark type to activate or
            %        string with mark name
            %
            % Example:
            % p = fastplot(EEG);
            % new_mark.name = 'new mark';
            % new_mark.color = [0.4, 0.7, 0.2];
            % p.add_mark(new_mark);
            % p.use_mark('new mark');
            %
            % see also: fastplot, add_mark

            if isnumeric(mark) && length(mark) == 1
                if mark <= length(obj.marks.names)
                    obj.marks.current = mark;
                else
                    warning(['You asked for mark number %d but only', ...
                        '%d marks are present.'], mark, length(obj.marks.names));
                end
            elseif ischar(mark)
                markind = find(strcmp(mark, obj.marks.names));
                if mark
                    obj.marks.current = markind;
                else
                    warning('There is no mark named %s', mark);
                end
            end
        end

        function select_mark(obj)
            % SELECT_MARK brings up fuzzy menu for mark selection
            %
            % Usage:
            % p = fastplot(EEG);
            % new_mark.name = 'new mark';
            % new_mark.color = [0.4, 0.7, 0.2];
            % p.add_mark(new_mark);
            % p.select_mark();
            %
            % see also: fastplot, fuzzy_gui

            % get mark names
            marknames = obj.marks.names;

            % ask for mark name:
            marknum = fuzzy_gui(marknames);

            % if user aborts do not go any further
            if isempty(marknum) || marknum == 0
                return
            end

            % update used mark
            obj.use_mark(marknum);
        end

        function mark(obj, mark_type, epoch_ind)
            % MARK allows to mark specific epochs with given mark type

            % check if mark type is present
            mark_ind = find(strcmp(mark_type, obj.marks.names));

            if isempty(mark_ind)
                error('Specified mark type does not exist. Please add it first.');
            end

            if all(epoch_ind > 0 & epoch_ind < (obj.epoch.num + 1))
                obj.marks.selected(mark_ind, epoch_ind) = true;
            end
        end

        function eval(obj, string)
            % EVAL evaluates a string as if it was a series of button presses
            obj.keys.eval(string);
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
            midpoint = round(ss(2)/2);
            edges_relative2midpoint = [-midpoint + 50, midpoint - 50];
            if obj.opt.nbchan < 10
                edges_relative2midpoint = round(edges_relative2midpoint * ...
                    (obj.opt.nbchan/10));
            end
            figure_ylims = midpoint + edges_relative2midpoint;


            obj.h.fig = figure('Units', 'pixels', ...
                'Position', [10, figure_ylims(1), ...
                ss(1)-20, figure_ylims(2) - figure_ylims(1)], ...
                'Color', [0.93, 0.93, 0.93], ...
                'Toolbar', 'none', 'Menubar', 'none');
            obj.h.ax = axes('Position', [0.05, 0.05, 0.9, 0.85], ...
                'Parent', obj.h.fig);

            obj.h.eventlines = [];
            obj.h.eventlabels = [];
            obj.h.epochlimits = [];
            obj.h.backpatches = [];
            
            % plot data
            % ---------
            % CHANGE
            % use 'ColorOrder' to set color of electrodes
            chan_pos = (0:obj.data_size(2)-1)*obj.spacing;
            dat = obj.(obj.opt.readfield{obj.opt.readfrom}) * ...
                obj.opt.signal_scale;
            dat = bsxfun(@minus, dat(obj.window.span, :), chan_pos);
            obj.h.lines = plot(dat, 'HitTest', 'off', ...
                'Parent', obj.h.ax);

            % set y limits and y lim mode (for faster replotting)
            set(obj.h.ax, 'YLim', obj.h.ylim, 'YLimMode', 'manual');
            set(obj.h.ax, 'XLim', [1, length(obj.epoch.time) * ...
                obj.opt.num_epoch_per_window], 'XLimMode', 'manual');

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

            % make sure that event names have \_ in place 
            % of _ because matlab renders it as lower index
            % CONSIDER - alltypes (rawtypes) vs disptypes
            obj.event.alltypes = cellfun(@(x) strrep(x, '_', '\_'), ...
                obj.event.alltypes, 'UniformOutput', false);

            % CHANGE
            % event colors - random at the moment
            obj.event.color = rand(obj.event.numtypes,3);

            % get epoch info:
            obj.opt.srate = EEG.srate;
            obj.opt.stime = 1000 / EEG.srate;
            % obj.opt.halfsample = obj.opt.stime / 2;
            if length(orig_size) > 2 && orig_size(3) > 1
                obj.epoch.mode       = true;
                obj.epoch.num        = orig_size(3);
                obj.epoch.time       = EEG.times;
                obj.epoch.timelimits = EEG.times([1, end]);
                obj.epoch.limits     = orig_size(2):orig_size(2):...
                    obj.data_size(1) + obj.opt.stime / 2;

                % set default marks
                if isempty(obj.marks)
                    obj.marks.names    = {'reject'};
                    obj.marks.colors   = [0.95, 0.73, 0.71];
                    obj.marks.current  = 1;
                    obj.marks.selected = false(1, obj.epoch.num);
                    obj.marks.lastclick = 0;
                end

                % set mark limits
                num_marks = length(obj.marks);
                obj.marks.num2vertx = arrayfun(@(x) create_vert_y(x, obj.h.ylim), ...
                    1:num_marks, 'UniformOutput', false);
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
                    catch %#ok<CTCH>
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

            % get instance of KeyboardManager
            km = KeyboardManager(obj.h.fig);

            % create shortcut patterns:
            pattern{1,1} = {'num', 'leftarrow'};
            pattern{1,2} = {@obj.move, -1, []};
            pattern{2,1} = {'num', 'rightarrow'};
            pattern{2,2} = {@obj.move, 1, []};
            pattern{3,1} = {'uparrow'};
            pattern{3,2} = {@obj.swap, 1};
            pattern{4,1} = {'downarrow'};
            pattern{4,2} = {@obj.swap, 2};
            pattern{5,1} = {'m'};
            pattern{5,2} = {@obj.select_mark};
            pattern{6,1} = {'a', 'm'};
            pattern{6,2} = {@obj.gui_add_mark};
            pattern{7,1} = {'num', 'equal'};
            pattern{7,2} = {@obj.scale_signal, 1};
            pattern{8,1} = {'num', 'hyphen'};
            pattern{8,2} = {@obj.scale_signal, -1};

            % vim-like:
            pattern{9,1} = {'num', 'h'};
            pattern{9,2} = {@obj.move, -1, []};
            pattern{10,1} = {'num', 'l'};
            pattern{10,2} = {@obj.move, 1, []};
            pattern{11,1} = {'num', 'w'};
            pattern{11,2} = {@obj.move, 1, 'window'};
            pattern{12,1} = {'num', 'b'};
            pattern{12,2} = {@obj.move, -1, 'window'};

            % initialize 
            km.register(pattern);
            
            % connect keyboard manager to windowkeypress callback
            set(obj.h.fig, 'WindowKeyPressFcn', @(o, e) km.read(e));
            obj.keys = km;
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

                modifiers = get(obj.h.fig, 'currentModifier');
                if length(modifiers) == 1 && strcmp(modifiers{1}, 'shift') ...
                    && obj.marks.lastclick(c) > 0 && ~(obj.marks.lastclick(c) ...
                    == selected)
                    if obj.marks.lastclick(c) > selected
                        ind = selected:(obj.marks.lastclick(c) - 1);
                    else
                        ind = (obj.marks.lastclick(c) + 1):selected;
                    end
                else
                    ind = selected;
                end

                % update lastclick
                obj.marks.lastclick(c) = selected;

                % revert activated windows
                obj.marks.selected(c, ind) = ...
                    logical(1 - obj.marks.selected(c, ind));

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
            selected  = obj.marks.selected(:, epoch_num);
            num_selected = sum(sum(selected));
            
            % hide unnecessary patches
            oldnum = length(obj.h.backpatches);
            newnum = num_selected;
            plot_diff = newnum - oldnum;
            
            if plot_diff < 0
                inds = oldnum:-1:oldnum + plot_diff + 1;
                set(obj.h.backpatches(inds), ...
                    'Visible', 'off'); % maybe set HitTest to 'off' ?
            end

            if any(any(selected))
                reuse = min([newnum, oldnum]);
                drawnew = max([0, plot_diff]);

                % create vertices
                % ---------------

                % add edges to epoch_lims
                [pre, post] = deal([]);
                if ~(epoch_lims(1) == 0)
                    pre = 0;
                end
                if ~(epoch_lims(end) == obj.window.size)
                    post = obj.window.size;
                end
                epoch_lims = [pre, epoch_lims, post];

                % init vertices and colors
                vert = cell(num_selected, 1);
                colors = cell(num_selected, 1);
                n_mrk_ep = sum(selected, 1);

                % this is ugly and slow, but works
                current_mark = 1;
                for ep = 1:size(selected, 2)
                    if n_mrk_ep(ep) > 0
                        mrk_tps = find(selected(:, ep));
                        this_y = obj.marks.num2vertx{n_mrk_ep(ep)};

                        for mr = 1:n_mrk_ep(ep)
                            x = epoch_lims(ep:ep+1);
                            x = [x(:); flipud(x(:))];
                            y = this_y(((mr-1)*2)+1:mr*2 + 2);
                            vert{current_mark} = [x, y];
                            colors{current_mark} = obj.marks.colors(...
                                mrk_tps(mr), :);
                            current_mark = current_mark + 1;
                        end
                    end
                end

                % TODO - the code below was nice, multimark should
                %        go back to something similar
                %
                % vert = repmat(ylm([1, 1, 2, 2])', [1, newnum*2]);
                % sel = [selected; selected + 1];
                % x = reshape(epoch_lims(sel(:)), [2, numel(sel)/2]);
                % vert(:,1:2:end) = [x; flipud(x)];
                % vert = mat2cell(vert, 4, ones(newnum, 1) * 2)';

                % faces are always 1:4 so need to init

                % CHANGE:
                % change those present
                if reuse > 0
                    ind = 1:reuse;

                    set(obj.h.backpatches(ind), {'Vertices', 'FaceColor'}, ...
                        [vert(ind), colors(ind)], 'Faces', 1:4, 'Visible', 'on');
                end

                % draw new
                if drawnew > 0
                    ind = reuse+1:newnum;
                    try
                        obj.h.backpatches(ind) = patch({'Vertices', 'FaceColor'}, ...
                            [vert(ind), colors(ind)], 'Faces', 1:4, ...
                            'EdgeColor', 'none', 'HitTest', 'off');
                    catch matlabBug %#ok<NASGU>
                        for i = ind
                            obj.h.backpatches(i) = patch('Vertices', vert{i}, ...
                                'FaceColor', colors{i}, 'Faces', 1:4, ...
                                'EdgeColor', 'none', 'HitTest', 'off');
                        end
                    end
                    uistack(obj.h.backpatches(ind), 'bottom');
                end
            end
        end

    end
    
    
end


% additional utility functions
function verty = create_vert_y(x, ylim)
    verty = repmat(linspace(ylim(1), ylim(2), x+1), [2, 1]);
    verty = verty(:);
end