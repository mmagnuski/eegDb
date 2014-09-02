% crate database for KajImp:

% variable that holds directory name
Pth = 'D:\Dropbox\DANE\KajImp 2013-2014\set';

% we only take set files that belong 
% to Eyes Closed condition:
fls = getfiles(Pth, ' EC.+\.set', true);

% build empty database
ICAw = ICAw_buildbase(Pth, fls);

% set epoching to consecutive windows
% 1-second long, set filtering to 1 Hz
% highpass and 48 - 52 Hz notch
opt.epoch.locked = false;
opt.epoch.winlen = 1;
opt.epoch.eventname = 'x';
opt.filter = [1, 0; 48, 52];

ICAw = ICAw_copybase(ICAw, opt);

% clear up unnecessary variables
clear opt fls flist EC
