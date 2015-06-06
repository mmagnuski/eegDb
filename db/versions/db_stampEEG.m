function EEG = db_stampEEG(db, r, EEG)

% EEG = db_stampEEG(db, r, EEG)
% transports recovery info to EEG.etc.recov
% allows the interface/user to know later whether
% currently recovered EEG corresponds to currently
% active version in database


% get record
recov = db(r);
% purify
recov = db_purify_record(recov);
% put into etc.recov
EEG.etc.recov = recov;