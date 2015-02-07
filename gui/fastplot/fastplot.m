classdef fastplot < handle
    
    % currently - one epoch at time
    properties
        h
        spacing
        data
        data_size
        win_lims
        win_span
        win_step
    end
    
    
    
    methods
        
        function obj = fastplot(data)
            % CHANGE - these should be class properties
            orig_size = size(data);
            obj.data_size = [orig_size(1), orig_size(2) * orig_size(3)];
            obj.data = reshape(data, obj.data_size)';
            obj.data_size = fliplr(obj.data_size);
            
            % calculate spacing (
            chan_sd = std(obj.data, [], 1);
            obj.spacing = 2 * max(chan_sd);
            obj.data = obj.data + repmat(...
                (0:obj.data_size(2)-1)*obj.spacing, [obj.data_size(1), 1]);
            
            % window limits and step size
            obj.win_lims = [1, 1000];
            obj.win_span = obj.win_lims(1):obj.win_lims(2);
            obj.win_step = 1000;
        end
        
        
        function launchplot(obj)
            % figure setup
            obj.h.fig = figure();
            obj.h.ax = axes();
            
            % plot data
            % ---------
            % CHANGE!
            % use 'ColorOrder' to set color of electrodes
            obj.h.lines = plot(obj.data(obj.win_span, :));
        end
            
        
        function refresh(obj, mthd)
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
            timetaken = toc;
            fprintf('time taken: %f\n', timetaken);
        end
        
    end
    
    
end