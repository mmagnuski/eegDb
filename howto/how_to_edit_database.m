% edit IGF ICAw database:
% transform it to a form that would
% recover epoched data from antisac
% condition

% one way to copy database with changes
opt.onesecepoch = false;
opt.distance = [];
opt.usecleanline = false;
opt.prerej = [];
opt.postrej = [];
opt.removed = [];
opt.epoch_events = '\code:find(strcmp(''fix'', {EEG.event.type}) & strcmp(''antisac'', {EEG.event.task}))';
opt.epoch_limits = [-1 1.5];
opt.winlen = diff(opt.epoch_limits);

ICAw_A1 = ICAw_copybase(newICAw, opt);

% another way:
opt.removed = [];
opt.epoch_events = ['\code:find(strcmp(''fix'', {EEG.event.type})',...
    ' & strcmp(''antisac'', {EEG.event.task}) & [EEG.event.time] > 1);'];
opt.epoch_limits = [-1 3];
opt.epoch_segment = '1s';
opt.winlen = diff(opt.epoch_limits);

ICAw_3s = ICAw_copybase(ICAw, opt);