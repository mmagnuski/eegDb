function compsel_dir_update(fig, dir)

% updates visibility info
% (what topos should be displayed on the page)


info = getappdata(fig, 'info');

% get number of components
numcomps  = length(info.comps.all);

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

setappdata(fig, 'info', info);