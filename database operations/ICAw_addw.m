function ICAw = ICAw_addw(ICAw, r, EEG)

% ICAW_ADDW adds ICA weights and other ICA-related variables from
% EEG to given entry of ICAw database.
%
% ICAw = ICAW_ADDW(ICAw, r, EEG)
% 
% FIXHELPINFO - describe arguments


ICAw(r).ICA.icaweights = EEG.icaweights;
ICAw(r).ICA.icasphere = EEG.icasphere;
ICAw(r).ICA.icawinv = EEG.icawinv;
ICAw(r).ICA.icachansind = EEG.icachansind;