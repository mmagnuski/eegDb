% tests that support development of
% pop_selectcomps_new

% setup
proj_DiamDec;
EEG = recoverEEG(ICAw, 10, 'local');

% first plot test :)
pop_selectcomps_new(EEG, 1:20, 'perfig', 10);