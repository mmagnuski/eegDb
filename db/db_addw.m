function db = db_addw(db, r, EEG)

% ICAW_ADDW adds ICA weights and other ICA-related variables from
% EEG to given entry of db database.
%
% db = ICAW_ADDW(db, r, EEG)
% 
% FIXHELPINFO - describe arguments


ICAw(r).ICA.icaweights = EEG.icaweights;
ICAw(r).ICA.icasphere = EEG.icasphere;
ICAw(r).ICA.icawinv = EEG.icawinv;
ICAw(r).ICA.icachansind = EEG.icachansind;