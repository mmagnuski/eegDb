% crate database for KajImp:

Pth = 'D:\Dropbox\DANE\KajImp 2013-2014\set\';
flist = prep_list(Pth, '*.set');

% we only take Eyes Closed condition:
EC = ~cellfun(@isempty, regexp(flist, ' EC', ...
    'once', 'match'));
fls = flist(EC);

ICAw = ICAw_buildbase(Pth, fls);
ICAw = ICAw_updatetonewformat(ICAw);

opts.onesecepoch.winlen = 1;
opts.onesecepoch.eventname = 'x';
opts.filter = [1, 0; 48, 52];

ICAw = ICAw_copybase(ICAw, opts);
clear opts fls flist EC
