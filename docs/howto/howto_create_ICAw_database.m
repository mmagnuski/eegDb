pth = 'C:\Users\TOSHIBA\Desktop\outa\';

% build base for files in the given folder:
ICAw = ICAw_buildbase(pth);
 
% now we apply changes to the database:
% we want to filter the data
% and epoch relative to chosen markers:
opt.filter = [1, 0];
opt.epoch.locked = true;
opt.epoch.events = ['\code:find(~[EEG.event.question]',...
    '& ~[EEG.event.poczatek]);'];
opt.epoch.limits = [-0.25, 3];

ICAw = ICAw_copybase(ICAw, opt);