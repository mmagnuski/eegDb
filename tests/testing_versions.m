% simple tests for versions management

% set paths etc.
eegDb;

% load database
filepath = fileparts(which('eegDb'));
filepath = fullfile(filepath, 'tests');
eegDb = ICAw_load(filepath, 'db01.mat');
eegDb = ICAw_updatetonewformat(eegDb);

% checking versions
vers = ICAw_getversions(eegDb, 1);
verSize = size(vers);

assert( verSize(1) == 1 );


% ADDING VERSIONS
% ---------------

newVer = eegDb(1);

% change epoching
newVer.epoch.locked = false;
newVer.epoch.limits = [];
newVer.epoch.events = [];
newVer.epoch.winlen = 1.5;

% clear rejections and marks
newVer.reject.pre = [];
newVer.reject.post = [];
newVer.reject.all = [];
for m = 1:length(newVer.marks)
    newVer.marks(m).value = [];
end


newVer.version_name = 'consec windows copy';
profile on
eegDb = ICAw_addversion(eegDb, 1, newVer);
profile viewer

% ICAw_addversion uses setdiff(legacy) which is slow!
% (0.344 s with subfunctions etc.)
% ICAw_checkfields is run 4 (!) times and overall takes
% 0.208 s
% ICAw_getversions is also slow - 0.103 s
% this is almost exclusively due to
% (with long @(x)str2num(x(4:end)) inside)

% getversions again:
% 
vers = ICAw_getversions(eegDb, 1);
assert(isequal( size(vers), [3,2]));

% now test versions through winreject
winreject(eegDb, 1);