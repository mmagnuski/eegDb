% set path to the *.set files:
pth = 'D:\Dropbox\DANE\CAT N170\EEG\SET\';

% build base for files in the given folder:
ICAw = ICAw_buildbase(pth);
% update ICAw to new format (this will be fixed
% soon so that ICAw_buildbase creates the data-
% base in the new format)
ICAw = ICAw_updatetonewformat(ICAw); 
 
% now we apply changes to the database:
% when recovering we want to filter the data:
opt.epoch_events = {'car_0','car_180','car_90',...
    'face_0','face_180','face_90'};
opt.epoch_limits = [-0.25, 0.5];
opt.filter = [1, 0];

ICAw = ICAw_copybase(ICAw, opt);