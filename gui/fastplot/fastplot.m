classdef fastplot < handle

    % FASTPLOT is a fast and friendly signal plotter.
    % It has full keyboard support, with some vim-like features
    % (see'keyboard shortcuts' section for details).
    %
    % Basic usage:
    % plt = fastplot(EEG);
    %
    % arguments
    % ---------
    % EEG - eeglab EEG structure, must have following fields:
    %    .data
    %    .srate
    %    .event  (with subfields: 'latency' and 'type')
    %    .times
    %
    % optional arguments
    % ------------------
    % second EEG struct can be given to compare between the two using up/down
    % buttons to switch between the first and second file given.
    %
    % key-value arguemnts
    % -------------------
    % 'show' - *logical*, whether to immediately plot the signal
    %          default: true
    % 'ecol' - electrode color cycle
    % 'vim' - *logical*, whether vim keybindings are active
    %         (more information in 'keyboard shortcuts' section)
    %         default: true
    % 'data2' - *structure* second dataset to compare with the first one. It
    %           must be an EEG structure of the same size as the first EEG
    %           passed. If data2 is passed the user can switch between viewing
    %           one or the other of the two datasets with up/down key presses
    %           (or k / j if vim mode is on <- is that really true)
    % 'sampleinfo' - *array*, epoch sample info - defining epoch limits in
    %                         samples of the original raw file
    %
    % examples
    % --------
    % run fastplot with vim keybindings on:
    % > plt = fastplot(EEG, 'vim', true);
    %
    % run fastplot comparing two datasets (for example one with all components
    % and the other with a sub-set of components removed):
    % > plt = fastplot(EEG, EEG2);
    %
    % the same as above can be also done with key-value pairs:
    % > plt = fastplot(EEG, 'data2', EEG2);
    %
    % returns
    % -------
    % plt : fastplot instance
    %     the output is a fastplot object. Below you can find the description
    %     of its properties and methods.
    %
    % fastplot properties
    % -------------------
    % ! warning ! these properties should not be modified directly (unless you
    %             really know what you are doing) - its much better to use
    %             designated methods for that
    %
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
    %                (FIXME - limits should be taken as in fieldtrip)
    %
    % marks    -  structure containing information about marks
    %             (marks should optimally have different name AND color)
    %             contains following fields:
    %     names       - cell array of mark names
    %     colors      - M by 3 matrix of mark colors (M - number of marks)
    %     current     - integer; informs which mark is currently selected
    %     selected    - M by E boolean matrix; informs which epochs are marked
    %                   with which mark types (M - number of mark types,
    %                   E - number of epochs)
    %     samples     - m x 4 matrix of selections entered in sample limits
    %                   where the rows denote consecutive marks (m - all
    %                   marked segments, not mark types) and columns represent:
    %                   [start sample, end sample, mark_type, which_epoch]
    % opt      -  various options, including:
    %    .step    - step values for different movement and scaling types:
    %         .move - FIXME
    %         .move_unit - FIXME
    %         .epoch_move - FIXME
    %         .epoch_scale - FIXME
    %         .signal_scale - FIXME
    %    .nbchan - FIXME
    %    .badchan - FIXME
    % keys     -  a KeyboardManager instance - it is responsible for keyboard
    %             interactions with the gui including processing of sequences
    %             of key presses
    %
    % fastplot methdos
    % ----------------
    % plot
    % move
    % windowsize
    % mark
    % use_mark
    % ... FIXME
    %
    % keyboard shortcuts
    % ------------------
    %
    % 1. movement-like commands:
    % movement-like commands can be prepended with a numerical value to be
    % evaluated that number of times (3w -> move three windows right)
    % left arrow - go one unit left
    % right arrow - go one unit right
    % b - move one window left
    % w - move one window right
    % = - scale signal up by one step
    % - - scale signal down by one step
    % e= - extend the view length by one epoch
    % e- - shorten the view length by one epoch
    %
    % 2. FIXME
    %

    % REMEMBER
    % opt could contain data_names field that could inform the
    % user about the name of currently displayed dataset


    % PROPERTIES - PRIVATE
    % --------------------
    properties (SetAccess = private, GetAccess = public)
        h      % handles to the graphical objects
        epoch  % info about epochs
        event  % info about events
        marks  % info about marks
        samplemarks % info about marks at below-epoch precision
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
        opt    % options (what goes here?)
    end

    % TODOs:
    % ------
    % USABILITY:
    % [ ] - time scroll bar at the bottom (turn on and off)
    % [ ] - turn off specific event labels/lines
    % [ ] - channel scroll?
    % [ ] - continuous mode
    % [ ] - remove ticks for epochs (or set epoch-relevant ticks)
    % PERFORMANCE-RELATED:
    % [ ] - downsampled mode?
    % [ ] - check profiling and then only worry about optimisation
    % [ ] - think about making faster version unique - specifically for
    %       cell arrays of strings
    % [ ] - check plotting against graphics performance tips:
    % http://www.mathworks.com/help/matlab/graphics-performance.html

    % PUBLIC METHODS
    % --------------
    methods

        function obj = fastplot(EEG, varargin)
            % initialize FASTPLOT object.

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

            % FIXME - in the future there should be no need to segment
            % segment if continuous
            if length(size(EEG.data)) < 3
                EEG = segment_eeg(EEG);
            end

            % define some of the class properties
            if strcmp(show_signal, 'comp')
                obj.opt.electrode_names = arrayfun(@(x) ...
                    ['IC', num2str(x)], signal_ind, 'Uni', false);
                obj.data = get_ica_data(EEG, signal_ind);
            else
                if isfield(EEG, 'chanlocs')
                    obj.opt.electrode_names = { ...
                        EEG.chanlocs(signal_ind).labels};
                else
                    obj.opt.electrode_names = arrayfun(@(x) ...
                        num2str(x), signal_ind, 'Uni', false);
                end
                obj.data = EEG.data(signal_ind, :, :);
            end

            orig_size = size(obj.data);
            obj.opt.nbchan = orig_size(1);
            obj.opt.badchan = false(obj.opt.nbchan, 1);
            obj.opt.badchan_color = [0.8, 0.8, 0.8];
            if length(orig_size) > 2
                obj.data_size = [orig_size(1), orig_size(2) * orig_size(3)];
            else
                obj.data_size = orig_size;
                orig_size = size(EEG.data);
            end
            obj.data = reshape(obj.data, obj.data_size)';
            obj.data_size = fliplr(obj.data_size);

            % default scroll method
            obj.scrollmethod = 'allset'; % how signal refresh is performed

            % default options (FIXME - move)
            obj.opt.num_epoch_per_window = 3; % this should be set via options
            obj.opt.readfield = {'data'}; % later - add support for multiple fields
            obj.opt.readfrom = 1;

            % calculate spacing and scale step
            obj.opt.chan_sd = nanstd(obj.data, [], 1); % this kind of thing can be in info property
            obj.opt.step.signal_scale = 0.1;
            obj.opt.signal_scale = 1;
            obj.spacing = 4.5 * mean(obj.opt.chan_sd);
            obj.arg_parser(varargin); % arg_parser should be used at the top

            chan_pos = (1:obj.data_size(2)) * obj.spacing;

            % get channel locations
            if isfield(EEG, 'chanlocs')
                obj.opt.chanloc = EEG.chanlocs;
                obj.opt.has_locs = ~isempty([EEG.chanlocs.X]);
            else
                obj.opt.has_locs = false;
            end

            % set y limits
            obj.h.ylim = [-(obj.data_size(2)+1) * obj.spacing, 0];

            % get event and epoch info
            obj.get_epoch(EEG, orig_size);
            obj.opt.badchan_inepoch = false(obj.opt.nbchan, obj.epoch.num);
            obj.opt.click_mode = 'epoch';
            obj.epoch.n_samples = length(obj.epoch.time);

            % sampleinfo
            has_samp_info = strcmp('sampleinfo', varargin);
            if any(has_samp_info)
                obj.epoch.sampleinfo = varargin{find(has_samp_info) + 1};
            else
                n_epochs = obj.epoch.num;
                n_samples = obj.epoch.n_samples;
                epoch_ends = (n_samples:n_samples:(n_samples * n_epochs))';
                obj.epoch.sampleinfo = [epoch_ends - (n_samples - 1), epoch_ends];
            end

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
            if obj.opt.show
                obj.launchplot();
            end
        end


        function refresh(obj, elements, mthd)
            % refresh the fastplot window.
            %
            % > plt.refresh(element, mthd)
            %
            % Parameters
            % ----------
            % element : str or cell array of str, optional
            %     Which elements should be updated. Can be 'all' or one of the
            %     following: {'signal', 'events', 'limits', 'marks', 'epochnum'}
            %     By default all elements are refreshed.
            % mthd : str, optional
            %     Refresh method. Mostly used for performance checks. Can be
            %     one of the following: 'replot', 'set', 'loopset'
            %     Default can be set through scrollmethod property of fastplot
            %     instance.

            % CONSIDER maybe refresh should check if sth actually changed
            %          and should be refreshed?

            % during re-plotting:
            % always use set 'XData', 'YData'
            if ~obj.opt.show
                return
            end
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
                refresh_elem = true(5, 1);
            else
                elem_order = {'signal', 'events', 'limits', ...
                    'marks', 'epochnum'}';
                refresh_elem = cellfun(@(x) any(strcmp(x, elements)), ...
                    elem_order);
            end

            % tic;
            if refresh_elem(1)
                % FIXME - move this to a separate function refresh_signal
                % FIXME - chan_pos should be held in the obj
                chan_pos = (1:obj.data_size(2))*obj.spacing;

                dat = obj.(obj.opt.readfield{obj.opt.readfrom});
                dat = bsxfun(@minus, dat(obj.window.span, :) * ...
                             obj.opt.signal_scale, chan_pos);
                switch mthd
                    case 'replot'
                        delete(obj.h.lines);
                        obj.h.lines = plot(dat);
                    case 'allset'
                        dat = mat2cell(dat, diff(obj.window.lims) + 1, ...
                                       ones(1, obj.data_size(2)))';
                        % FIXME - channel hit test could be set only during
                        %         launch or set on/off when switching from
                        %         epoch to channel mode
                        set(obj.h.lines, {'YData'}, dat, 'HitTest', 'off');
                    case 'loopset'
                        for i = 1:length(obj.h.lines)
                            set(obj.h.lines(i), 'YData', ...
                                dat(:, i), 'HitTest', 'off');
                        end
                end
                refresh_badchan_inepoch(obj, dat);
            end
            if refresh_elem(2); obj.plotevents(); end
            if refresh_elem(3); obj.plot_epochlimits(); end
            if refresh_elem(4); obj.plot_marks(); end
            if refresh_elem(5); obj.plot_epoch_numbers(); end
            % timetaken = toc;
            % fprintf('time taken: %f\n', timetaken);
        end


        function move(obj, value, unit, mlt)
            % MOVE the current view a number of units.
            %
            % > plt.move(value, unit)
            %
            % Parameters
            % ----------
            % value: int, optional
            %     positive value indicates forward motion
            %     negative value indicates backward motion
            %     The default is to move by one unit.
            % unit: str, optional
            %     Unit to use in movement. Can be 'epoch' or 'window'.
            %     By default uses window.step property of fastplot instance.
            % mlt : int, optional
            %     Additional argument used for vim mode movement. Defines
            %     multiplication of the value argument. In vim mode this is
            %     used internally to allow for `3w` to move by three windows.

            % CHANGE - mlt is temporary?
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

            % check whether variables are present
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

            % update epoch limits
            % FIXME - separate function
            ep = epochlimits_in_range(obj);
            ep.latency = ep.latency - obj.window.lims(1);
            obj.epoch.current_limits = ep.latency;
            obj.epoch.current_nums = ep.nums;

            % refresh view
            obj.refresh();
        end

        function move_to_mark(obj, mark, whichone)
            % MOVE_TO_MARK - move view to specific (next/previous) mark.
            %
            % > plt = fastplot(EEG)
            % > plt.move_to_mark('badchan', 'next')
            %
            % Parameters
            % ----------
            % mark : str
            %     Name of the mark type to move to.
            % whichone : str
            %     Direction of movement: 'next' or 'previous'.

            % check mark
            if ~exist('mark', 'var') || isempty(mark)
                % check current mark
                mark = obj.marks.current;
            end
            if ischar(mark)
                mark = find(strcmp(mark, obj.marks.current));
                % error if mark not found
            end

            % check current epochs
            ep = obj.epochlimits_in_range();
            current_epochs = ep.nums;
            mid = round(length(current_epochs) / 2);
            central_epoch = current_epochs(mid);

            switch whichone
                case 'next'
                    ind1 = min([size(obj.marks.selected, 2), central_epoch+1]);
                    move = find(obj.marks.selected(mark, ind1:end), 1, 'first');
                case 'previous'
                    ind1 = max([1, central_epoch - 1]);
                    move = find(obj.marks.selected(mark, 1:ind1), 1, 'last');
                    if ~isempty(move)
                        move = move - central_epoch;
                    end
            end

            if ~isempty(move)
                obj.move(move);
                obj.refresh();
            end
        end


        % CONSIDER - maybe this function should be private? :
        function ev = events_in_range(obj, rng)
            % EVETNS_IN_RANGE gives latency of events that are present within
            % given range. If no range is given, the range of current fastplot
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
            % SCALE_SIGNAL - scale the signal traces.
            %
            % Parameters
            % ----------
            % val : FIXME
            %     FIXME
            % num : FIXME
            %     FIXME

            if ~exist('num', 'var')
                num = 1;
            end

            obj.opt.signal_scale = obj.opt.signal_scale + ...
                obj.opt.step.signal_scale * val * num;
            obj.opt.signal_scale = max([0, obj.opt.signal_scale]);

            obj.refresh('signal');
        end


        function ep = epochlimits_in_range(obj, rng)
            % gives latency of epoch limits that are present within given
            % range. If no range is given, the range of current fastplot view
            % is taken.
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
%                 if ~(ep.nums(end) == obj.epoch.num)
%                     ep.nums = [ep.nums, ep.nums(end)+1];
%                 end
            end
        end


        function windowsize(obj, val, num)
            % FIXME - add description
            if ~exist('val', 'var')
                val = 1;
            end
            if ~exist('num', 'var')
                num = 1;
            end

            % FIXME - ADD !!! check limits, safty checks !!!
            obj.opt.num_epoch_per_window = obj.opt.num_epoch_per_window + (val*num);
            obj.window.size = length(obj.epoch.time) * obj.opt.num_epoch_per_window;
            obj.window.lims = [obj.window.lims(1), obj.window.lims(1) + obj.window.size - 1];
            obj.window.span = obj.window.lims(1):obj.window.lims(2);

            % check what epoch limits are in range
            % FIXME - specialized function for this
            ep = epochlimits_in_range(obj);
            ep.latency = ep.latency - obj.window.lims(1);
            obj.epoch.current_limits = ep.latency;
            obj.epoch.current_nums = ep.nums;

            if obj.opt.show
                set(obj.h.ax, 'XLim', [1, length(obj.epoch.time) * ...
                    obj.opt.num_epoch_per_window]);
            end
            obj.refresh();
        end

        function set_window(obj, varargin)
            % FIXME - add description
            if isstruct(varargin{1})

            % this will need some safty checks etc.
            % previous_window = obj.window;
            obj.window = varargin{1};
            % check number of epochs:
            epoch_length = length(obj.epoch.time);
            obj.opt.num_epoch_per_window = length(obj.window.span) / epoch_length;
            if obj.opt.show
                set(obj.h.ax, 'XLim', [1, length(obj.epoch.time) * ...
                    obj.opt.num_epoch_per_window]);
            end
            end
        end

        function add_mark(obj, mark)
            % allows to add new mark types to fastplot.
            % Note that this method does not mark epochs but adds new mark
            % types instead.
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

            % FIXME - CONSIDER: pass mark to _add_mark
            %           (private function without safety checks)

            % FIXME - CHANGE - check color too

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


        function add_samplemark(obj, mark_name, mark_color)
            % ADD_SAMPLEMARK - FIXME
            n_marktypes = length(obj.samplemarks.name);
            obj.samplemarks.name{n_marktypes + 1} = mark_name;
            obj.samplemarks.color(n_marktypes + 1, :) = mark_color;
        end

        function samplemark(obj, mark_name, sample_range)
            % SAMPLEMARK - FIXME
            n_added_marks = size(sample_range, 1);
            marktype_idx = find(strcmp(mark_name, obj.samplemarks.name));
            if isempty(marktype_idx)
                error('Could not find mark %s, available marks: %s.', ...
                      mark_name, strjoin(obj.samplemarks.name, ', '));
            end
            % FIXME - could also check sample_range size

            % concat types and selected
            obj.samplemarks.type = [obj.samplemarks.type; ...
                                    ones(n_added_marks, 1) * marktype_idx];
            obj.samplemarks.selected = [obj.samplemarks.selected; sample_range];

            add_relinfo = zeros(n_added_marks, 3);
            add_indata = false(n_added_marks, 1);
            for idx = 1:n_added_marks
                this_mrk = sample_range(idx, :);
                overlap = (this_mrk(1) <= obj.epoch.sampleinfo(:, 2)) & ...
                          (this_mrk(2) >= obj.epoch.sampleinfo(:, 1));
                epoch_idx = find(overlap);
                % currenly ignore muli-epoch spanning artifacts...
                if ~isempty(epoch_idx)
                    epoch_idx = epoch_idx(1);
                end
                add_indata(idx) = ~isempty(epoch_idx);
                if add_indata(idx)
                    add_relinfo(idx, :) = [...
                      this_mrk - obj.epoch.sampleinfo(epoch_idx, 1), epoch_idx];
                end
            end
            obj.samplemarks.indata = [obj.samplemarks.indata; add_indata];
            obj.samplemarks.reldata = [obj.samplemarks.reldata; add_relinfo];
        end


        function gui_add_mark(obj)
            % FIXME - add description
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
                    warndlg(['This color is already in use, please choose', ...
                             ' another one.']);
                end
            end

            % now - use add_mark to add new mark
            new_mark = struct('name', markname, 'color', c);
            obj.add_mark(new_mark);
        end


        function use_mark(obj, mark)
            % USE_MARK allows to select given mark type as currently active.
            %
            % Arguments
            % ---------
            % mark - *integer* indicating which mark type to activate or
            %        string with mark name
            %
            % Example
            % -------
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
            opt.boxColor = obj.marks.colors; %#ok<*PROP>

            % ask for mark name:
            marknum = fuzzy_gui(marknames, opt);

            % if user aborts do not go any further
            if isempty(marknum) || marknum == 0
                return
            end

            % update used mark
            obj.use_mark(marknum);
        end


        % CONSIDER mark -> mark_epochs
        function mark(obj, mark_type, epoch_ind)
            % MARK allows to mark specific epochs with given mark type.
            %
            % > plt.mark(mark_type, epoch_ind)
            %
            % Parameters
            % ----------
            % mark_type : str
            %     Name of mark type.
            %
            % epoch_ind : int | vec of int
            %     Epoch indices to mark .

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


        function plot(obj)
            obj.opt.show = true;
            if ~femp(obj.h, 'fig') || ~ishandle(obj.h.fig)
                obj.launchplot();
            else
                obj.refresh();
            end
        end
    end


    % PRIVATE METHODS
    % ---------------
    methods (Access = private)

        function arg_parser(obj, args)
            % helper function that lets to parse matlab style arguments
            % (why oh why matlab doesn't have named function arguments?)

            obj.opt.vim = false;
            obj.opt.show = true;
            obj.opt.data2 = [];
            obj.opt.ecol =[0, 0, 0];

            if isempty(args)
                return
            end
            first_char = find(cellfun(@ischar, args), 1, 'first');
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
                obj.opt = parse_arse(args(first_char:end), obj.opt);
            end
            if ~isempty(obj.opt.data2)
                obj.data2 = obj.opt.data2;
                obj.opt.data2 = true;
                obj.opt.readfield(end + 1) = {'data2'};
            end
        end


        function launchplot(obj)
            % LAUNCHPLOT - figure setup

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

            % set color cycle
            if isempty(obj.opt.ecol)
                obj.opt.ecol = [1. 1. 1.];
            end

            % if ecol is < n_chan, rep it
            numrep = ceil(obj.opt.nbchan / size(obj.opt.ecol, 1));
            obj.opt.ecol = repmat(obj.opt.ecol, [numrep, 1]);
            obj.opt.ecol = obj.opt.ecol(1:obj.opt.nbchan, :);

            set(obj.h.ax, 'ColorOrder', obj.opt.ecol);
            % could set the NextPlot property to 'replacechildren'
            % instead of using hold on

            obj.h.eventlines = [];
            obj.h.eventlabels = [];
            obj.h.epochlimits = [];
            obj.h.backpatches = [];
            obj.h.epochnumbers = [];
            obj.h.topofigure = [];

            % FIXME - this is already in one place else - a function for
            %         such updates?
            % check what epoch limits are in range
            ep = epochlimits_in_range(obj);
            ep.latency = ep.latency - obj.window.lims(1);
            obj.epoch.current_limits = ep.latency;
            obj.epoch.current_nums = ep.nums;

            % plot data
            % ---------
            % CHANGE
            % use 'ColorOrder' to set color of electrodes
            dat = obj.(obj.opt.readfield{obj.opt.readfrom});
            chan_pos = (1:obj.data_size(2)) * obj.spacing;
            dat = bsxfun(@minus, dat(obj.window.span, :) * ...
                         obj.opt.signal_scale, chan_pos);
            hold on; % hold is set so that plot uses ColorOrder
            obj.h.lines = plot(dat, 'HitTest', 'off', ...
                'Parent', obj.h.ax, 'LineWidth', 1);
            if any(obj.opt.badchan)
                set(obj.h.lines(obj.opt.badchan), 'LineWidth', 0.25, ...
                    'Color', obj.opt.badchan_color);
            end
            hold off;

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
            % plot events too
            obj.plot_marks();
            % plot epoch numbers
            obj.plot_epoch_numbers();

            % set keyboard shortcuts
            obj.init_keypress();
            % set click callback
            set(obj.h.ax, 'ButtonDownFcn', @(h, e) obj.onButtonPress());
            set(obj.h.fig, 'ButtonDownFcn', @(h, e) obj.onButtonPress());
        end


        function get_epoch(obj, EEG, orig_size)
            % FIXME, DOCS - what does it do

            has_events = ~isempty(EEG.event);
            if has_events
                obj.event.latency = [EEG.event.latency];
            else
                obj.event.latency = [];
            end

            % code event types with integers

            if has_events
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
            else
                obj.event.alltypes = {};
                obj.event.numtypes = [];
                obj.event.type = [];
            end

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

                % FIXME - separate function
                % set default marks
                if isempty(obj.marks)
                    obj.marks.names    = {'reject'};
                    obj.marks.colors   = [0.95, 0.73, 0.71];
                    obj.marks.current  = 1;
                    obj.marks.selected = false(1, obj.epoch.num);
                    obj.marks.lastclick = 0;
                end

                % add empty samplemarks
                if ~isfield(obj, 'samplemarks') || isempty(obj.samplemarks)
                    obj.samplemarks.name = {};
                    obj.samplemarks.color = [];
                    obj.samplemarks.type = [];
                    obj.samplemarks.selected = [];
                    obj.samplemarks.indata = [];
                    obj.samplemarks.reldata = [];
                end

                % set mark limits
                num_marks = length(obj.marks);
                obj.marks.num2vertx = arrayfun(@(x) create_vert_y(x, obj.h.ylim), ...
                    1:num_marks, 'UniformOutput', false);
            end
        end


        function plotevents(obj)
            % FIXME, DOCS - add docs

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
                        lineY(:,ind), 'LineWidth', 2);
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
            % FIXME, DOCS - add docs

            if ~isempty(obj.epoch.current_limits)
                drawnlims = length(obj.h.epochlimits);
                newlims = length(obj.epoch.current_limits);

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
                xDat = repmat(obj.epoch.current_limits, [2, 1]);
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
                        yDat(:, ind), 'Color', [0.7, 0.7, 0.7], ...
                        'LineWidth', 1);
                end
            end

        end


        function init_keypress(obj)
            % FIXME, DOCS - add docs

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
            pattern{9,1} = {'num', 'e', 'equal'};
            pattern{9,2} = {@obj.windowsize, 1};
            pattern{10,1} = {'num', 'e', 'hyphen'};
            pattern{10,2} = {@obj.windowsize, -1};
            pattern{11,1} = {'n', 'm'};
            pattern{11,2} = {@obj.move_to_mark, [], 'next'};
            pattern{12,1} = {'p', 'm'};
            pattern{12,2} = {@obj.move_to_mark, [], 'previous'};


            % vim-like:
            if obj.opt.vim
                pattern{13,1} = {'num', 'h'};
                pattern{13,2} = {@obj.move, -1, []};
                pattern{14,1} = {'num', 'l'};
                pattern{14,2} = {@obj.move, 1, []};
                pattern{15,1} = {'num', 'w'};
                pattern{15,2} = {@obj.move, 1, 'window'};
                pattern{16,1} = {'num', 'b'};
                pattern{16,2} = {@obj.move, -1, 'window'};
            end

            pattern{17, 1} = {'x'};
            pattern{17, 2} = {@obj.change_click_mode};

            % initialize
            km.register(pattern);

            % connect keyboard manager to windowkeypress callback
            set(obj.h.fig, 'WindowKeyPressFcn', @(o, e) km.read(e));
            obj.keys = km;
        end


        function onButtonPress(obj)
            % FIXME, DOCS - add docs

            % axesHandle  = get(objectHandle,'Parent');
            coord = get(obj.h.ax, 'CurrentPoint');
            coord = coord(1, 1:2);

            % test where x is located relative to epoch.current_limits
            if obj.epoch.mode

                % check selection type
                selection_type = get(obj.h.fig, 'SelectionType');
                % 'normal': left-click, 'open': double-click, 'alt': right-click,
                % 'extend': left and right together (who uses that?)

                x = coord(1);
                modifiers = get(obj.h.fig, 'currentModifier');
                if x > 0
                    % epoch clicking
                    if any(strcmp(selection_type, {'normal', 'extend'}))
                        if ~(obj.epoch.current_limits(1) == 0)
                            epoch_lims = [0, obj.epoch.current_limits];
                        else
                            epoch_lims = obj.epoch.current_limits;
                        end

                        % check which epoch was clicked
                        selected = obj.epoch.current_nums(...
                            find(x > epoch_lims, 1, 'last'));

                        % marks mode - select full epoch
                        % ------------------------------
                        if strcmp(obj.opt.click_mode, 'epoch')
                            mark_full_epoch(obj, selected, modifiers)
                        elseif strcmp(obj.opt.click_mode, 'channel')
                            clicked_chan = which_chan_clicked(obj, coord);
                            mark_channel_in_epoch(obj, selected, clicked_chan);
                        end

                    elseif strcmp(selection_type, 'alt')
                        plot_topo_for_timepoint(obj, x)
                    end
                else
                    % click on the left side - mark channel as bad
                    % --------------------------------------------
                    clicked_chan = which_chan_clicked(obj, coord);
                    mark_channel(obj, clicked_chan);
                end
            end
        end


        function swap(obj, val)
            % FIXME, DOCS - add docs

            % maybe change name to swapdata or dataswap
            % CHANGE - the tests should be a little more elaborate
            if length(obj.opt.readfield) > 1
                obj.opt.readfrom = val;
                obj.refresh();
            end
        end


        function plot_marks(obj)
            % PLOT_MARKS plots the marks that are withing window range.

            % get selected epochs
            epoch_lims = obj.epoch.current_limits;
            epochs_visible = obj.epoch.current_nums;
            marked_epochs = obj.marks.selected(:, epochs_visible);
            num_marked_epochs = sum(sum(marked_epochs));

            % FIXME - adding left and right edges shouldn't be necessary
            %         it could be automatically in current epochs info
            %         or could never be - and then the checks would not be
            %         necessary
            % add edges to epoch_lims
            [pre, post] = deal([]);
            if ~(epoch_lims(1) == 0)
                pre = 0;
            end
            if ~(epoch_lims(end) == obj.window.size)
                post = obj.window.size;
            end
            epoch_lims = [pre, epoch_lims, post];

            if ~isempty(obj.samplemarks.selected)
                % find by visible epochs
                visible_mask = obj.samplemarks.reldata(:, end) >= ...
                    epochs_visible(1) & obj.samplemarks.reldata(:, end) <= ...
                    epochs_visible(end);
                if any(visible_mask)
                    samplemarks_types = obj.samplemarks.type(visible_mask);
                    samplemarks_visible = obj.samplemarks.reldata(visible_mask, :);
                    addlim = repmat(epoch_lims(...
                      samplemarks_visible(:, 3) - epochs_visible(1) + 1)', 1, 2);
                    samplemarks_visible = samplemarks_visible(:, 1:2) + addlim;
                    n_samplemarks = size(samplemarks_visible, 1);
                else
                    n_samplemarks = 0;
                end
            else
                n_samplemarks = 0;
            end

            % hide unnecessary patches
            oldnum = length(obj.h.backpatches);
            newnum = num_marked_epochs + n_samplemarks;
            plot_diff = newnum - oldnum;

            if plot_diff < 0
                inds = oldnum:-1:oldnum + plot_diff + 1;
                set(obj.h.backpatches(inds), ...
                    'Visible', 'off'); % maybe set HitTest to 'off' ?
            end

            % init vertices and colors
            if newnum > 0
                current_mark = 1;
                vert = cell(newnum, 1);
                colors = cell(newnum, 1);

                reuse = min([newnum, oldnum]);
                drawnew = max([0, plot_diff]);

                if any(any(marked_epochs))
                    % create vertices
                    % ---------------
                    n_marks_per_epoch = sum(marked_epochs, 1);

                    % the code below was changed/introduced to handle multiple
                    % marks per window
                    % this is ugly and probably slow, but works
                    % FIXME, CHECK is it really slow? can we change it?
                    %              is it worth changing?
                    % CONSIDER - some of these computations can be done before
                    %            plotting and saved (vertices etc.)
                    %            plotting methods could also be chosen
                    %            (if sub-epoch marks present, if overlapping marks
                    %             present)
                    for ep = 1:size(marked_epochs, 2)
                        if n_marks_per_epoch(ep) > 0
                            mrk_tps = find(marked_epochs(:, ep));
                            this_y = obj.marks.num2vertx{n_marks_per_epoch(ep)};

                            for mr = 1:n_marks_per_epoch(ep)
                                x = epoch_lims(ep:ep + 1);
                                x = [x(:); flipud(x(:))];
                                y = this_y(((mr - 1) * 2) + 1:mr * 2 + 2);
                                vert{current_mark} = [x, y];
                                colors{current_mark} = obj.marks.colors(...
                                    mrk_tps(mr), :);
                                current_mark = current_mark + 1;
                            end
                        end
                    end

                    % the code below seems to be uncommented because multiple marks
                    % per epoch were easier to implement using what is now shown
                    % above
                    % TODO - the code below was nice, multimark should
                    %        go back to something similar
                    %
                    % vert = repmat(ylm([1, 1, 2, 2])', [1, newnum*2]);
                    % sel = [marked_epochs; marked_epochs + 1];
                    % x = reshape(epoch_lims(sel(:)), [2, numel(sel)/2]);
                    % vert(:,1:2:end) = [x; flipud(x)];
                    % vert = mat2cell(vert, 4, ones(newnum, 1) * 2)';

                    % faces are always 1:4 so need to init
                end

                if n_samplemarks > 0
                    for mr = 1:n_samplemarks
                        x = samplemarks_visible(mr, :);
                        x = [x(:); flipud(x(:))];
                        y = [obj.h.ylim(1); obj.h.ylim(1); ...
                             obj.h.ylim(2); obj.h.ylim(2)];
                        vert{current_mark} = [x, y];
                        colors{current_mark} = obj.samplemarks.color(...
                            samplemarks_types(mr), :);
                        current_mark = current_mark + 1;
                    end
                end

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

        % draw epoch numbers
        function plot_epoch_numbers(obj)
            % plot epoch numbers over epochs.

            % get selected epochs
            epoch_lims = obj.epoch.current_limits;
            epoch_num = obj.epoch.current_nums;
            epoch_num = epoch_num(1:end-1);
            numep = length(epoch_num);

            % reuse lines and labels
            numeplab = length(obj.h.epochnumbers);

            % check how many events to plot compared
            % to those already present
            plot_diff = numep - numeplab;

            % hide unnecessary lines and tags
            if plot_diff < 0
                inds = numeplab:-1:numeplab + plot_diff + 1;
                set(obj.h.epochnumbers(inds), ...
                    'Visible', 'off'); % maybe set HitTest to 'off' ?
                set(obj.h.epochnumbers(inds), ...
                    'Visible', 'off');
            end

            if numep > 0
                % get necessary info to plot:
                labelX = mean([0, epoch_lims(1:end-1); epoch_lims], 1)';
                labelY = double(repmat(obj.spacing, [numep, 1]));
                strVal = arrayfun(@num2str, epoch_num, 'UniformOutput', false)';

                % how many elements to reuse, how many new to draw:
                reuse = min([numeplab, numep]);
                drawnew = max([0, plot_diff]);

                % set properties of available lines and labels
                % --------------------------------------------
                if numeplab > 0

                    % create indexer
                    ind = 1:reuse;
                    pos = mat2cell([labelX(ind), labelY(ind)], ones(reuse, 1), 2);

                    % set labels (this takes the longest - maybe change)
                    set(obj.h.epochnumbers(ind), {'Position', 'String'}, ...
                        [pos, strVal(ind)], 'Visible', 'on');
                end

                % draw new lines and labels if more is needed
                % -------------------------------------------
                if drawnew > 0

                    % create indexer
                    ind = reuse+1:(reuse + drawnew);

                    hold on; % change to myHoldOn later on

                    % labels
                    try
                    obj.h.epochnumbers(ind) = text(labelX(ind), labelY(ind), ...
                        strVal(ind), 'VerticalAlignment', 'bottom', ...
                        'clipping', 'off');
                    catch %#ok<CTCH>
                        for i = ind
                            obj.h.epochnumbers(i) = text(labelX(i), labelY(i), ...
                                strVal(i), 'VerticalAlignment', 'bottom', ...
                                'clipping', 'off');
                        end
                    end

                    hold off; % change to myHoldOff later
                end
            end
        end

        function change_click_mode(obj)
            if strcmp(obj.opt.click_mode, 'epoch')
                obj.opt.click_mode = 'channel';
            elseif strcmp(obj.opt.click_mode, 'channel')
                obj.opt.click_mode = 'epoch';
            end
        end
    end
end


% additional utility functions
function verty = create_vert_y(x, ylim)
    verty = repmat(linspace(ylim(1), ylim(2), x+1), [2, 1]);
    verty = verty(:);
end

function chan_ind = which_chan_clicked(plt, coord)
    y = coord(2);
    ylm = plt.h.ylim;
    fromtop = 1 - abs(ylm(1) - y) / diff(ylm);
    chan_ind = round(fromtop * (plt.opt.nbchan + 1));
end

function mark_full_epoch(plt, selected, modifiers)
    c = plt.marks.current;
    if length(modifiers) == 1 && strcmp(modifiers{1}, 'shift') ...
        && plt.marks.lastclick(c) > 0 && ~(plt.marks.lastclick(c) ...
        == selected)
        if plt.marks.lastclick(c) > selected
            ind = selected:(plt.marks.lastclick(c) - 1);
        else
            ind = (plt.marks.lastclick(c) + 1):selected;
        end
    else
        ind = selected;
    end

    % update lastclick
    plt.marks.lastclick(c) = selected;

    % revert activated windows
    plt.marks.selected(c, ind) = ...
        logical(1 - plt.marks.selected(c, ind));

    % plot the marks
    plt.plot_marks();
end

function plot_topo_for_timepoint(plt, x)
    % check which datapoint this is:
    data_ind = plt.window.span(round(x));
    chan_data = plt.(plt.opt.readfield{plt.opt.readfrom})(data_ind, :);

    % create topo figure if it is not present
    if isempty(plt.h.topofigure) || ~ishandle(plt.h.topofigure)
        plt.h.topofigure = figure(...
            'toolbar', 'none', 'menubar', 'none', 'units', 'normalized', ...
            'Position', [0.05, 0.8, 0.11, 0.16], 'WindowKeyPressFcn', ...
            @(o,e) figure(plt.h.fig));
    end

    % activate figure and clear
    figure(plt.h.topofigure);
    cla;

    % plot topography
    if plt.opt.has_locs
        % CONSIDER - allow fieldtrip's topoplot
        topoplot(chan_data, plt.opt.chanloc);
    end
end

function mark_channel(plt, clicked_chan)
    if plt.opt.badchan(clicked_chan)
        % turn back to good channel
        plt.opt.badchan(clicked_chan) = false;
        set(plt.h.lines(clicked_chan), 'color', ...
            plt.opt.ecol(clicked_chan, :), ...
            'LineWidth', 1);
    else
        % turn to bad channel
        plt.opt.badchan(clicked_chan) = true;
        % FIXME - this should use bad channel color arg from
        %         db...
        % FIXME - z order should be also changed when turning
        %         channel bad
        newcol = [1, 0, 0];
        set(plt.h.lines(clicked_chan), 'color', newcol, ...
            'LineWidth', 2);
    end
end

function mark_channel_in_epoch(plt, selected, clicked_chan)
        if plt.opt.badchan_inepoch(clicked_chan, selected)
        % turn back to good channel
        plt.opt.badchan_inepoch(clicked_chan, selected) = false;
        % FIXME - change visual state directly here
    else
        % turn to bad channel
        plt.opt.badchan_inepoch(clicked_chan, selected) = true;
        % FIXME - change visual state directly here
        % FIXME - this should use bad channel color arg from
        %         db...
        % FIXME - z order should be also changed when turning
        %         channel bad
    end
    % FIXME - could be made more optimal later (to refresh only what needs
    %         to be refreshed, not all signals)
    plt.refresh('signal');
end

function refresh_badchan_inepoch(plt, dat)
    epoch_span = plt.epoch.current_nums;
    bads = plt.opt.badchan_inepoch(:, epoch_span);
    n_bads_epoch = sum(bads, 1);
    n_bads = sum(n_bads_epoch);

    % remove previous bad lines
    if isfield(plt.h, 'badlines') && ~isempty(plt.h.badlines)
        for idx = 1:length(plt.h.badlines)
            % FIXME - can this be done without a loop?
            delete(plt.h.badlines{idx});
        end
    end
    if n_bads > 0
        % FIXME - dat should always have the same type here
        if iscell(dat)
            n_pnts = length(dat{1});
        else
            n_pnts = size(dat, 1);
        end
        epoch_limits = [0, plt.epoch.current_limits, n_pnts];
        % plot bad channels in epoch
        hold on; % <- FIXME, this should be set for the fastplot figure
        plt.h.badlines = cell(sum(n_bads_epoch > 0), 1);

        % plot the lines
        line_idx = 0;
        for epoch_idx = find(n_bads_epoch)
            line_idx = line_idx + 1;
            ch_idx = find(bads(:, epoch_idx));
            lims1 = epoch_limits(epoch_idx) + 1;
            lims2 = epoch_limits(epoch_idx + 1);

            % FIXME - one dat type only
            if iscell(dat)
                data_to_plot = [dat{ch_idx}];
                data_to_plot = data_to_plot(lims1:lims2, :);
            else
                data_to_plot = dat(lims1:lims2, ch_idx);
            end
            plt.h.badlines{line_idx} = plot(...
                lims1:lims2, data_to_plot, 'color', [0.75, 0.75, 0.75], ...
                'HitTest', 'off', 'Parent', plt.h.ax, 'LineWidth', 2.5);
        end
        hold off;
    end
end
