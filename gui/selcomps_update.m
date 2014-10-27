function selcomps_update(varargin)
    % SELCOMPS_UPDATE refreshes selcomps figure
    % 
    % selcomps_update(varargin)
    %
    % examples:
    % FIXHELPINFO
    %
    % see also: selcomps, 
    
    % TODOs:
    % [ ] invisible is not yet used - will it be useful?
    % [ ] fix plotting components when those
    %     to plot are less than the number of axes
    
    % parase arguments
    % ----------------
    prs = inputParser;
	prs.FunctionName = 'selcomps_update';

	% addParamValue is addParameter in new MATLAB...
	% moreover addParamValue is not recommended...
	addParamValue(prs, 'figh',    [],         @ishandle);
	addParamValue(prs, 'update',  'all',      @ischar);
	addParamValue(prs, 'dir',     [],      @ischar);
	
	parse(prs, varargin{:});
	params = prs.Results;
	clear prs

	% figure
	if ~isempty(params.figh)
		figh = params.figh;

		if ~strcmp(get(figh, 'type'), 'figure')
    		figh = get(figh, 'Parent');
    	end
    else
    	% ADD
    	% look for selcomps figure?
    end

    % dir
    if ~isempty(params.dir)
    	dir = params.dir;
    	update = 'topo';
    else
    	dir = [];
    end


    h = getappdata(figh, 'h');
    info = getappdata(figh, 'info');

    if any(strcmp(update, {'topo', 'all'})) 
        % this only if we update figures:
        cachetopo = getappdata(h.fig, 'cachetopo');
        cachedcomps = cachetopo.CompNum;
        numcomps = length(info.allcomp);
    
    if ~isempty(dir)
        if strcmp(dir, '<')

            if info.comps.visible(1) == 1
                return
            end 
            
            info.comps.visible(1) = info.comps.visible(1) - info.perfig;
            
            if info.comps.visible(1) < 1 
            	info.comps.visible(1) = 1; 
            	remapping = true; 
            end
            
            info.comps.visible = info.comps.visible(1) : ...
            					 info.comps.visible(1) + info.perfig - 1;
        elseif strcmp(dir, '>')
            
            if info.comps.visible(1) == numcomps
                % CHANGE - maybe not return but do not update components
                return
            end

            info.comps.visible(1) = info.comps.visible(end) + 1;

            fin = min(info.comps.visible(1) + info.perfig - 1, numcomps);
            info.comps.visible = info.comps.visible(1) : fin;
        end
        
        % -----------
        % clear up field
        for stp = 1:length(info.comps.visible)
            
            % comp number
            cmp = h.comps.all(info.comps.visible(stp));
            
            % get axis handle:
            thisax = h.ax(stp);
            
            % clear axis children
            axchil = get(thisax, 'Children');
            
            % if has children and not invisible
            if ~isempty(axchil) && h.comps.invisible(stp) == 0
                set(axchil, 'Visible', 'off');
                h.comps.invisible(stp) = h.comps.visible(stp);
            end
            
            % change tag etc.
            h.comps.visible(stp) = toplot(stp);
            set(thisax, 'tag', ['topoaxis', num2str(cmp)]);
            
            but = h.button(stp);
            comm = sprintf(['pop_prop( %s, 0, %d, %3.15f, ',...
                '{ ''freqrange'', [1 50] });'], 'h.EEG', cmp, but);
            set( but, 'callback', comm, 'string', int2str(cmp),...
                'tag', ['comp', num2str(cmp)]);
        end
    
    
        % -----------
        % plot components
        for stp = 1:length(toplot)
            cmp = h.comps.all(toplot(stp));
            
            % get axis handle:
            thisax = h.ax(stp);
            
            % ====
            % finished here <<<---
            % ====
            
            % ------------------
            % replot from memory
            if sum(cachedcomps == cmp) > 0
                replot_topo(h.EEG, cmp, thisax);
                
                
                % CHANGE so that frequency of drawnow
                % can be controlled
                
                if mod(stp, DRAWFREQ) == 0
                    drawnow
                end
            else
                
                % clear axis children
                axchil = get(thisax, 'Children');
                delete(axchil);
                h.comps.invisible(stp) = 0;
                
                % activate axis:
                axes(thisax); %#ok<LAXES>
                
                % draw new topoplot
                if h.opt.plotelec
                    topoplot( h.EEG.icawinv(:,cmp), h.EEG.chanlocs, 'verbose', ...
                        'off', 'style' , 'fill', 'chaninfo', h.EEG.chaninfo,...
                        'numcontour', 8);
                else
                    topoplot( h.EEG.icawinv(:,cmp), h.EEG.chanlocs, 'verbose', ...
                        'off', 'style' , 'fill','electrodes','off', ...
                        'chaninfo', h.EEG.chaninfo, 'numcontour', 8);
                end
                
                % --- and change other stuff ---
                
            end
        end
    
        % topo caching - CHECK and probably CHANGE
        h.EEG = EEG_topo_cache(h.EEG, gcf);
        
        % CONSIDER - gui data updates should happen more often...
        % update guidata
        h.comps.visible = toplot;
        guidata(figh, h);
        end
    end
end
