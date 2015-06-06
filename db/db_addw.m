function db = db_addw(db, r, EEG)

% DB_ADDW adds ICA weights and other ICA-related variables from
% EEG to given entry of db database.
%
% db = DB_ADDW(db, r, EEG)
% 
% FIXHELPINFO - describe arguments


db(r).ICA.icaweights = EEG.icaweights;
db(r).ICA.icasphere = EEG.icasphere;
db(r).ICA.icawinv = EEG.icawinv;
db(r).ICA.icachansind = EEG.icachansind;