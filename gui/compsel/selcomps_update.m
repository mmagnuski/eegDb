function selcomps_update(varargin)

% SELCOMPS_UPDATE refreshes selcomps figure
%
% selcomps_update(s, varargin)
%
% input:
% s      - update scheduler object
% 
% optional input:
% FIXHELPINFO
%
% examples:
% FIXHELPINFO
%
% see also: selcomps,


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

parse(prs, varargin{:});
params = prs.Results;
clear prs

% setup
% -----
% get figure
if ~isempty(params.figh)
    figh = params.figh;
    
    if ~strcmp(get(figh, 'type'), 'figure')
        figh = get(figh, 'Parent');
    end
else
    % ADD
    % look for selcomps figure?
end


% get basic appdata
% -----------------
h      = getappdata(figh, 'h');
info   = getappdata(figh, 'info');
s      = getappdata(figh, 'scheduler');
snc    = getappdata(figh, 'syncer');

if any(strcmp(params.update, {'topo', 'all'}))

    % CHECK / CHANGE - prev_visible are no longer previous
    %                  (appdata?)
    % appdata needed for update:
    topopts   = getappdata(h.fig, 'topopts');
    topocache = getappdata(h.fig, 'topocache');
    prev_visible = info.comps.visible;
    
    
    % check cached topos
    if ~isempty(topocache)
        iscached    = true;
        cachedcomps = [topocache.CompNum];
    else
        iscached    = false;
    end
    
    
    % -----------
    % clear up field
    numvis = length(info.comps.visible);
    
    for stp = 1:length(h.ax)
        
        % check if this update is still valid
        if s.waiting()
            setappdata(figh, 'info', info);
            return
        end

        % get axis handle:
        thisax = h.ax(stp);
        
        % clear axis children
        axchil = get(thisax, 'Children');
        
        % if has children and not invisible
        if ~isempty(axchil) && info.comps.invisible(stp) == 0
            set(axchil, 'Visible', 'off');
            info.comps.invisible(stp) = prev_visible(stp); % this may not work right
        end
        
        if stp <= numvis
            % comp number
            cmp = info.comps.all(info.comps.visible(stp));
            
            but = h.button(stp);
            comm = '';
            set( but, 'string', int2str(cmp), ...
                'tag', ['comp', num2str(cmp)], ...
                'callback', comm, ...
                'backgroundcolor', [1, 1, 1]);
        else
            % CHANGE - the tag is not correct, 
            %          but may not be needed
            % CHANGE - calculate cmp correctly
            %          (from invisible - this re-
            %           quires some changes in 'pre')
            % CHANGE - invisible may not be accurate 
            % CONDIDER if main task is switched
            %          what should I do?
            but = h.button(stp);
            comm = '';
            set( but, 'callback', comm, 'string', '',...
                'tag', ['nocomp', num2str(stp)], ...
                'backgroundcolor', [1, 1, 1]);
        end

        % change tag etc.
        set(thisax, 'tag', ['cleared', num2str(cmp)]);
    end
    
    % get things for plotting 
    opts_unrolled = struct_unroll(topopts);
    icawinv  = getappdata(h.fig, 'icawinv');
    chanlocs = getappdata(h.fig, 'chanlocs');
    
    % -----------
    % plot components
    for stp = 1:length(info.comps.visible)

        % check if this update is still valid
        if s.waiting()
            setappdata(figh, 'info', info);
            return
        end

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
            
            % CHECK - is axis tag changed?
            % replot the cached topo
            replot_topo(topocache, cmp, thisax);

            % if axis tag not changed:
            % add tags
            set(thisax, 'tag', ['topoaxis', num2str(cmp)]);
            
            if mod(stp, info.drawfreq) == 0
                drawnow
            end
        else
            
            % clear axis children
            axchil = get(thisax, 'Children');
            delete(axchil);
            h.comps.invisible(stp) = 0;
            
            % CHANGE - this may not be necessary
            % maybe change topoplot to plot to passed handle
            % activate axis:
            axes(thisax); %#ok<LAXES>
            
            % draw new topoplot
            topoplot2( icawinv(:,cmp), chanlocs,...
                opts_unrolled{:}, 'backcolor', info.FIGBACKCOLOR);
            
            % add tags
            set(thisax, 'tag', ['topoaxis', num2str(cmp)]);
            
        end

        % change button callbacks
        set(h.button(stp), 'callback', @(src, ev) linkfun_comp_prop(h.fig, src, cmp));
        set(h.button(stp), 'ButtonDownFcn', @(src, ev) compsel_rightclick_changestatus(src, cmp, snc) );

        % change button color
        update_main_button(snc, cmp);
    end
    
    % update info (because of visible invisible)
    setappdata(h.fig, 'info', info);
    
    % CACHING
    % topos are cached in 'post' fun from scheduler
end

% CHANGE - should be earlier because of the scheduler
% updating buttons
if any(strcmp(params.update, {'buttons'}))

end

end

