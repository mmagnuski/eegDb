function ICAw = db_newrejtype(ICAw, newtypes)

% NOHELPINFO

if isempty(newtypes)
    ex = evalin('base', 'exist(''TMPNEWREJ'', ''var'');');
    
    if ex
        newtypes = evalin('base', 'TMPNEWREJ;');
    else
        return
    end
    
end

% scan for rejtypes
% now scanmarks is MUCH faster so it can be performed every time :)
% CHANGE - this should be only performed
%          for consistency checks one time
%          (at the beginning)
%          - use persistent option?
rejt = db_scanmarks(ICAw);

% take only userrem types:

newlen = length(newtypes.name);
rejNames = rejt.name;
isnew = cellfun(@(x) ~any(strcmp(x, rejNames)),...
    newtypes.name);


newt = find(isnew);
clear isnew

if ~isempty(newt)
    % there are some new types
    
    % apply to all ICAw records
    for r = 1:length(ICAw)
        for n = 1:length(newt)
            ICAw(r).marks(end + 1).name = newtypes.name{newt(n)};
            ICAw(r).marks(end).color = newtypes.color(newt(n),:);
            % additional?
        end
        
    end
    
end
