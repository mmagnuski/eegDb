function fig = cachefig(h, tp)

% HELPINFO

% TODOs
% [ ] add figure info if necassary (?)
% [ ] check if complete
% [ ] allocate fig

if strcmp(tp, 'figure')
    % axis children;
    h = findobj('parent', h, 'type', 'axes');
end


for step = 1:length(h)
    fig(step) = cacheax(h(step));
end
    

