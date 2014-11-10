function EEG = ICAw_stampEEG(ICAw, r, EEG)

% EEG = ICAw_stampEEG(ICAw, r, EEG)
% transports recovery info to EEG.etc.recov
% allows the interface/user to know later whether
% currently recovered EEG corresponds to currently
% active version in database


% get record
recov = ICAw(r);
% purify
recov = eegDb_purify_record(recov);
% put into etc.recov
EEG.etc.recov = recov;