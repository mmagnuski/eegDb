function linkfun_selcomps_dir_update(hfig, dirct)

% linkfunction calling scheduler to schedule 
% topo updates in selcomps
%
% see also: pop_selcomps_new, Scheduler

% get scheduler
s = getappdata(hfig, 'scheduler');

% schedule pre, run and post
% --------------------------

% pre is always executed
add(s, 'pre', {@compsel_dir_update, hfig, dirct});
% run is only executed if the queue is free
add(s, 'run', {@selcomps_update, 'figh', hfig, 'update', 'topo'});
% post is run only if 'run' was run
add(s, 'post', {@selcomps_topocache, hfig});

% close task and ask to run:
close(s);
run(s);