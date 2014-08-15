% test dipfitizing:

% BEFORE you run it, make sure you have 
% loaded the correct database

% then, set your temporary save path:
pth = 'E:\Dropbox\CURRENT PROJECTS\ADHD 2013-2014\';

% make sure that FieldTrip is not on your
% path, but rather only EEGlab and its
% FiledTrip 'lite' functions
% (and that you have the correct egg_checkset)
% THIS IS IMPORTANT, DO YOU UNDERSTAND?!?!

% if everything is set up, the last thing is
% to specify rejection criteria:
rv_rej = 0.15; % above this residual variance --> reject

% add path to eeglab
% WARNING! - eeg_path does not yet add plugin functions
% therefore dipfit is not added, it is recommended to
% run eeglab instead:
eeglab;
% eeg_path('add');

% run dipfit on database files:
ICAw = ICAw_dipfit(ICAw, 'savepath', pth, ...
    'rmout', 'on', 'norpl', true);

for r = 1:length(ICAw)
    
    % if no dipfit - continue to the next r
    if ~femp(ICAw(r).dipfit, 'model')
        continue
    end
    
% then, we create a vector info about
% which componenets not to include in
% clustering steps:
donotclust = [];
rv = [ICAw(r).dipfit.model.rv];

% reject dipoles outside of head:
donotclust = [donotclust, find(isnan(rv))]; %#ok<*AGROW>

% Residual Variance cirterion:
donotclust = [donotclust, find(rv > rv_rej)];

% look for one electrode components:
ICAw = ICAw_onechan_comp(ICAw, r);

% add this info:
donotclust = [donotclust, ICAw(r).ic_onechan'];

% also, do not use rejected components in
% clustering:
donotclust = unique([donotclust, ICAw(r).ica_remove]);

% add this info to ICA field (in future
% all ICA info will reside in this field)
ICAw(r).ICA.donotclust = donotclust;

end 