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
            data_size = [orig_size(1), orig_size(2) * orig_size(3)];
            obj.data = reshape(data, data_size)';
            obj.data_size = fliplr(data_size);
            
            % calculate spacing (
            chan_sd = std(fulldata, [], 2);
            spacing = 2 * max(chan_sd);
            fulldata = fulldata .* repmat((0:data_size(2)-1)*spacing, data_size(1));
            
            % figure setup
            obj.h.fig = figure();
            obj.h.ax = axis();
            
            obj.win_lims = [1, 1000];
            obj.win_span = obj.win_lims(1):obj.win_lims(2);
            obj.win_step = 1000;
            
            % plot data
            % ---------
            
            % CHANGE!
            % use 'ColorOrder' to set color of electrodes
            
            % first time plot - then set 'YData' or so...
            plot(obj.data(oobj.win_span, :));
        end
        
        function refresh(obj)
            % during re-plotting:
            % always use set 'XData', 'YData'
            obj.win_span = obj.win_lims(1):obj.win_lims(2);
            set(obj.h.ax, 'YData', obj.data(oobj.win_span, :));
        end
    end
    
end