function rejt = ICAw_scanrejtypes(ICAw)

% NOHELPINFO

% TODOs:
% [ ] this is not a particulary fast way to check this
%     check other methods?
% [ ] this kind of check should be performed only at
%     the beginning of winreject...

% get for r = 1
% only name, color, field and infield should be kept
rejs = ICAw_getrej(ICAw, 1);
rejs = rmfield(rejs, 'value');

for r = 2:length(ICAw)
    newrejs = ICAw_getrej(ICAw, r);
    newrejs = rmfield(newrejs, 'value');
    
    % if new name
    % ADD ? - new name in a field?
    %      better checks
    
    new = false(length(newrejs.name), 1);
    
    for nm = length(newrejs.name)
        cmp = find(strcmp(newrejs.name{nm}, rejs.name), 1);
        
        if isempty(cmp)
            new(nm) = true;
        end
    end
    clear cmp
    
    if sum(new) > 0
        new = find(new);
        for n = new
            rejs.name{end+1} = newrejs.name{n};
            rejs.color(end+1,:) = newrejs.color(n, :);
            rejs.field{end+1} = newrejs.field{n};
            rejs.infield{end+1} = newrejs.infield{n};
        end
    end
    
    clear newrejs n new 
end
    
rejt = rejs;
    