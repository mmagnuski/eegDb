function selcomps_topocache(hfig)

% this function is used as a 'post' function
% in the scheduler
% 
% see also: Scheduler

topocache =  getappdata(hfig, 'topocache');
[topocache, ifnew] = topo_cache(hfig, topocache);

if ifnew
    setappdata(hfig, 'topocache', topocache);
end