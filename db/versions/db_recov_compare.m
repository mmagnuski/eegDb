function iseq = db_recov_compare(recov, rec)

% NOHELPINFO

% compare non-empty fields of databases
rec = eegDb_purify_record(rec);

iseq = isequal(recov, rec);

