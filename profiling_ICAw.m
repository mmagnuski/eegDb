profile on
rejt = ICAw_scanrejtypes(ICAw);
profile viewer

% around one second at the beginning
% 0.459 s after first revision
% 0.145 s after second revision
% ICAw_checkfields should be used with caution
% if checking if field is present and nonempty
% use femp(struct, fieldname) instead

rej = ICAw_getrej(ICAw, 12);

%% profiling recoverEEG:

profile on
EEG = recoverEEG(ICAw, r, 'ICAnorem', 'local');
profile viewer

% does not filter, creates 90 epochs
% removes some, adds ICA weights:
% recoverEEG    1   3.512 s   0.102 s
% pop_loadset   1   2.456 s   0.151 s
% eeg_checkset  5   2.420 s   0.254 s
% eeg_getdatact 1   1.716 s   1.672 s
% pop_epoch     1   0.572 s   0.039 s
% epoch         1   0.257 s   0.082 s
% seems checkset is quite shitty...
% we will have to change it

% testing eeg_checkset:
profile on
EEG = eeg_checkset(EEG);
profile viewer
% icadefs
%  - calls which('eeglab') twice
%    (unnecessarily)
%
% eeg_checkset:
%  - eeglab_options takes 38.9% of 
%    its time
%  - EEG = eeg_checkchanlocs(EEG);
%    takes 37.4%
%  - uses getfield and setfield which
%    are slow, better use dynamic
%    fields
