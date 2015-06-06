function iseq = db_recov_compare(recov, rec)

% NOHELPINFO

% compare non-empty fields of databases
rec = db_purify_record(rec);

iseq = isequal(recov, rec);

