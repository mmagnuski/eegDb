classdef fastplot < handle
    
    % Properties:
    % h        -  structure of handles to:
    %     fig         - fastplot figure
    %     ax          - axis with eeg signal
    %     lines       - eeg signal lines
    %     eventlines  - lines showing event timing
    %     eventlabels - labels showing event type
    
    % currently - one epoch at time
    properties (SetAccess = private, GetAccess = public)
        h      % handles to the graphical objects
        opt    % options (what goes here?)
        epoch  % info about epochs
        event  % info about events
        marks  % info about marks
        spacing  % should be in opts?
        data
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
        
        function obj = fastplot(EEG)
            % define some of the class properties
            orig_size = size(EEG.data);
            obj.data_size = [orig_size(1), orig_size(2) * orig_size(3)];
            obj.data = reshape(EEG.data, obj.data_size)';
            obj.data_size = fliplr(obj.data_size);

            % default scroll method
            obj.scrollmethod = 'allset';
            
            % get event and epoch info
            obj.get_epoch(EEG, orig_size);
            
            % calculate spacing
            chan_sd = std(obj.data, [], 1);
            obj.spacing = 2 * max(chan_sd);
            obj.data = obj.data - repmat(...
                (0:obj.data_size(2)-1)*obj.spacing, [obj.data_size(1), 1]);
            
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
            switch mthd
                case 'replot'
                    delete(obj.h.lines);
                    obj.h.lines = plot(obj.data(obj.window.span, :));
                case 'allset'
                    dat = mat2cell(obj.data(obj.window.span, :), ...
                        diff(obj.window.lims) + 1, ones(1, ...
                        obj.data_size(2)))';
                    set(obj.h.lines, {'YData'}, dat);
                case 'loopset'
                    for i = 1:length(obj.h.lines)
                        set(obj.h.lines(i), 'YData', obj.data(obj.window.span, i));
                    end
            end
            obj.plotevents();
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
        
    end
    
    
    % PRIVATE METHODS
    % ---------------
    methods (Access = private)
        
        function launchplot(obj)
            % figure setup
            ss = obj.opt.scrsz;
            obj.h.fig = figure('Position', [10, 50, ss(1)-20, ss(2)-200]);
            obj.h.ax = axes('Position', [0.05, 0.05, 0.9, 0.85]);
            obj.h.eventlines = [];
            obj.h.eventlabels = [];
            obj.h.epochlimits = [];
            
            % plot data
            % ---------
            % CHANGE!
            % use 'ColorOrder' to set color of electrodes
            obj.h.lines = plot(obj.data(obj.window.span, :));
            
            % set y limits and y lim mode (for faster replotting)
            obj.h.ylim = [-(obj.data_size(2)+1) * obj.spacing,...
                obj.spacing];
            set(obj.h.ax, 'YLim', obj.h.ylim, 'YLimMode', 'manual');
            
            % plot events
            obj.plotevents();
            
            % set keyboard shortcuts
            obj.init_keypress();
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
                obj.epoch.num = orig_size(3);
                obj.epoch.limits = orig_size(2):orig_size(2):obj.data_size(1) + obj.opt.stime / 2;
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
                labelX = ev.latency';
                labelY = repmat(obj.spacing * 2, [numev, 1]);
                colors = mat2cell(obj.event.color(ev.type, :), ones(numev, 1), 3);
                strVal = obj.event.alltypes(ev.type)';

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
                        [X(ind), Y(ind), colors(ind)]);
                    % set labels
                    set(obj.h.eventlabels(ind), {'Position', 'String', 'BackgroundColor'}, ...
                        [pos, strVal(ind), colors(ind)]);
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
                    obj.h.eventlabels(ind) = text(labelX(ind), labelY(ind), ...
                        strVal(ind), {'BackgroundColor'}, colors(ind), ...
                        'Margin', 2.5, 'VerticalAlignment', 'bottom', ...
                        'clipping', 'off');

                    hold off; % change to myHoldOff later

                end
            end

        end
        
        
        function init_keypress(obj)
            % create shortcut patterns:
            pattern{1,1} = {'num', 'leftarrow'};
            pattern{1,2} = {@obj.move, -1};
            pattern{2,1} = {'num', 'rightarrow'};
            pattern{2,2} = {@obj.move, 1};
            
            % initialize 
            eegplot_readkey_new([], [], [], pattern);
            
            % add eegplot_readkey to WindowKeyPressFcn
            set(obj.h.fig, 'WindowKeyPressFcn', @eegplot_readkey_new);
        end
    end
    
    
end