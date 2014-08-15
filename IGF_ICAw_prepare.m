% set up file path to EEG files:
LOAD_DIR = 'D:\Dropbox\DANE\MGR\EEG\set\';

% look through files:
IGF_fls = IGF_patterns(LOAD_DIR);

% next, select files with search task
file_list = select_file_with_pattern(IGF_fls, ...
    {'searchL', 'searchR'});
clear IGF_fls

% then, build ICAw database
ICAw = ICAw_buildbase(LOAD_DIR, file_list(:,1));

% then, we have to modify some of its
% properties:

% we want to take windows that are close to
% given event patterns:
events_pattern{1} = {'searchL', {'fix', 1; 'target L', 1;...
    'mask', 1}, 'ignore', {'DIN2','DIN1','DIN4'}};
events_pattern{2} = {'searchR', {'fix', 1; 'target R', 1;...
    'mask', 1}, 'ignore', {'DIN2','DIN1','DIN4'}};

opt.onesecepoch.distance = {events_pattern{1}, {[-1 2.5]};...
    events_pattern{2}, {[-1 2.5]}};
clear events_pattern

% and not use cleanline:
opt.usecleanline = false;

% here we update the database:
ICAw = ICAw_copybase(ICAw, opt);
clear opt

