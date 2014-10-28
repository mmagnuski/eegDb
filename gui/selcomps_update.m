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

% check if hObj or events passed:
varlen = length(varargin);
varkill = false(1, varlen);
if varlen >= 1 && ~ischar(varargin{1})
    varkill(1) = true;
end
if varkill(1) && varlen >= 2 && ~ischar(varargin{2})
    varkill(2) = true;
end
varargin(varkill) = [];

prs = inputParser;
prs.FunctionName = 'selcomps_update';

% addParamValue is addParameter in new MATLAB...
% moreover addParamValue is not recommended...
addParamValue(prs, 'figh',    [],         @ishandle);
addParamValue(prs, 'update',  'all',      @ischar);
addParamValue(prs, 'dir',     [],         @ischar);

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
    % CHANGE - maybe we should add to update
    %          not change it, or change/add
    %          only if not 'all'...
    params.update = 'topo';
else
    dir = [];
end


h = getappdata(figh, 'h');
info = getappdata(figh, 'info');

if any(strcmp(params.update, {'topo', 'all'}))
    
    % appdata needed for update:
    topopts   = getappdata(h.fig, 'topopts');
    topocache = getappdata(h.fig, 'topocache');
    prev_visible = info.comps.visible;
    
    % get number of components
    numcomps  = length(info.comps.all);
    
    % check cached topos
    if ~isempty(topocache)
        iscached    = true;
        cachedcomps = [topocache.CompNum];
    else
        iscached    = false;
    end
    
    
    % check dir if present
    if ~isempty(dir)
        if strcmp(dir, '<')
            
            if info.comps.visible(1) == 1
                return
            end
            
            info.comps.visible(1) = info.comps.visible(1) - info.perfig;
            
            if info.comps.visible(1) < 1
                info.comps.visible(1) = 1;
                % remapping = true;
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
    end
    
    
    % -----------
    % clear up field
    numvis = length(info.comps.visible);
    
    for stp = 1:length(h.ax)
        
        % get axis handle:
        thisax = h.ax(stp);
        
        % clear axis children
        axchil = get(thisax, 'Children');
        
        % if has children and not invisible
        if ~isempty(axchil) && info.comps.invisible(stp) == 0
            set(axchil, 'Visible', 'off');
            info.comps.invisible(stp) = prev_visible(stp);
        end
        
        if stp <= numvis
            % comp number
            cmp = info.comps.all(info.comps.visible(stp));
            
            % change tag etc.
            set(thisax, 'tag', ['topoaxis', num2str(cmp)]);
            
            but = h.button(stp);
            comm = sprintf(['pop_prop( %s, 0, %d, %3.15f, ',...
                '{ ''freqrange'', [1 50] });'], 'h.EEG', cmp, but);
            set( but, 'callback', comm, 'string', int2str(cmp),...
                'tag', ['comp', num2str(cmp)]);
        else
            but = h.button(stp);
            comm = '';
            set( but, 'callback', comm, 'string', '',...
                'tag', ['comp', num2str(cmp)]);
        end
    end
    
    opts_unrolled = struct_unroll(topopts);
    icawinv  = getappdata(h.fig, 'icawinv');
    chanlocs = getappdata(h.fig, 'chanlocs');
    
    % -----------
    % plot components
    for stp = 1:length(info.comps.visible)
        cmp = info.comps.all(info.comps.visible(stp));
        
        % get axis handle:
        thisax = h.ax(stp);
        
        % visible so not invisible :)
        info.comps.invisible(stp) = 0;
        
        % ADD - if is invisible and can be 
        %       used relocate if needed and
        %       make visible
        
        % ------------------
        % replot from memory
        if iscached && any(cachedcomps == cmp)
            
            % CHECK - does replotting change axis tag?
            % replot the cached topo
            replot_topo(topocache, cmp, thisax);

            % make sure it is visible
            % set(thisax, 'Visible', 'on');
            
%             if mod(stp, DRAWFREQ) == 0
%                 drawnow
%             end
        else
            
            % clear axis children
            axchil = get(thisax, 'Children');
            delete(axchil);
            h.comps.invisible(stp) = 0;
            
            % CHANGE - this may not be necessary
            % maybe change topoplot to plot to passed handle
            % activate axis:
            axes(thisax); %#ok<LAXES>
            
            % draw new topoplot and make sure it is visible
            topoplot( icawinv(:,cmp), chanlocs,...
                opts_unrolled{:});
            
            % add tags
            set(thisax, 'tag', ['topoaxis', num2str(cmp)]);
            
        end
    end
    
    % update info (because of visible invisible)
    setappdata(h.fig, 'info', info);
    
    % cache topos
    [topocache, ifnew] = topo_cache(h.fig, topocache);

    if ifnew
        setappdata(h.fig, 'topocache', topocache);
    end
end

end

