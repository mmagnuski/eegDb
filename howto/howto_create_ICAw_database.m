pth = 'C:\Users\TOSHIBA\Desktop\outa\';

% build base for files in the given folder:
ICAw = ICAw_buildbase(pth);
% update ICAw to new format (this will be fixed
% soon so that ICAw_buildbase creates the data-
% base in the new format)
ICAw = ICAw_updatetonewformat(ICAw); 
 
% now we apply changes to the database:
% when recovering we want to filter the data:
opt.filter = [1, 0];
% and epoch relative to chosen markers:
opt.epoch_events = ['\code:find(~[EEG.event.question]',...
    '& ~[EEG.event.poczatek]);'];
opt.epoch_limits = [-0.25, 3];

ICAw = ICAw_copybase(ICAw, opt);