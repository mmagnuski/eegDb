classdef fastplot < handle
    
    % Properties:
    % h        -  structure of handles to:
    %     fig    - fastplot figure
    %     ax     - axis with eeg signal
    %     lines  - eeg signal lines
    
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
        win_span    % pack into a struct?
        win_size    % pack into a struct?
        win_lims    % pack into a struct?
        win_step    % pack into a struct?
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
            
            % get event and epoch info
            obj.get_epoch(EEG);
            
            % calculate spacing
            chan_sd = std(obj.data, [], 1);
            obj.spacing = 2 * max(chan_sd);
            obj.data = obj.data - repmat(...
                (0:obj.data_size(2)-1)*obj.spacing, [obj.data_size(1), 1]);
            
            % window limits and step size
            obj.win_size = 1000;
            obj.win_lims = [1, obj.win_size];
            obj.win_span = obj.win_lims(1):obj.win_lims(2);
            obj.win_step = 1000;
            
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
            obj.win_span = obj.win_lims(1):obj.win_lims(2);
            
            if ~exist('mthd', 'var')
                mthd = 'set';
            end
            
            tic;
            switch mthd
                case 'replot'
                    delete(obj.h.lines);
                    obj.h.lines = plot(obj.data(obj.win_span, :));
                case 'set'
                    for i = 1:obj.data_size(2)
                        set(obj.h.lines(i), 'YData', obj.data(obj.win_span, i));
                    end
            end
            obj.plotevents();
            timetaken = toc;
            fprintf('time taken: %f\n', timetaken);
        end
        
        
        function move(obj, value, mlt, unit)
            % CHANGE - mlt is temporary
            % ADD - mode of win_step?
            if ~exist('value', 'var')
                value = 1;
            end
            % do not go further if move is not possible
            if value == 0 || ...
                    ((obj.win_lims(1) == 1) && value < 0) ...
                    || ((obj.win_lims(2) == obj.data_size(1)) ...
                    && value > 0)
                return
            end
            
            if ~exist('mlt', 'var')
                mlt = 1;
            end
            if ~exist('unit', 'var')
                unit = obj.win_step;
            end
            
            % create and test new window limits
            wlims = obj.win_lims + mlt * value * unit;
            if value > 0 && wlims(2) > obj.data_size(1)
                wlims(2) = obj.data_size(1);
                wlims(1) = max([1, wlims(2) - obj.win_length + 1]);
            end
            if value < 0 && wlims(1) < 1
                wlims(1) = 1;
                wlims(2) = min([obj.data_size(1), ...
                    wlims(1) + obj.win_length - 1]);
            end
            obj.win_lims = wlims;
            obj.refresh();
        end
            
        
        % maybe should be private? :
        function ev = events_in_range(obj, rng)
            % default - range in samples
            % default - range from winlim
            if ~exist('rng', 'var')
                rng = obj.win_lims;
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
            
            % plot data
            % ---------
            % CHANGE!
            % use 'ColorOrder' to set color of electrodes
            obj.h.lines = plot(obj.data(obj.win_span, :));
            
            % set y limits and y lim mode (for faster replotting)
            set(obj.h.ax, 'YLim', [-(obj.data_size(2)+1) * obj.spacing,...
                obj.spacing], 'YLimMode', 'manual');
            
            % plot events
            obj.plotevents();
            
            % set keyboard shortcuts
            obj.init_keypress();
        end
        
        
        function get_epoch(obj, EEG)
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
            % TODO
        end
        
        
        function plotevents(obj)
            % currently previous event lines are deleted
            % not reused (this should change soon)
            if ~isempty(obj.h.eventlines)
                delete(obj.h.eventlines);
                obj.h.eventlines = [];
            end
            
            ev = obj.events_in_range();
            
            if ~isempty(ev.latency)
                numev = length(ev.latency);
                ev.latency = ev.latency - obj.win_lims(1);
                ylim = get(obj.h.ax, 'YLim');
                % plot lines
                hold on;
                obj.h.eventlines = line( ...
                    repmat(ev.latency, [2, 1]), ...
                    repmat(ylim', [1, numev]), ...
                    'Color', [0.5, 0.2, 0.3], ...
                    'LineWidth', 3.5);
                hold off;
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