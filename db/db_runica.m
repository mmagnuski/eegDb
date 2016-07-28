function db = db_runica(db, rs)

% run extended infomax ica on selected records of the
% eegDb database
%
% db = db_runica(db, rs);
%
% arguments
% ---------
% db - eegDb database
% rs - record indices
%
% returns
% -------
% db - modified eegDb database (with ICA weights added)

if ~exist('rs', 'var')
	rs = 1:length(db);
end

for r = rs
    if isempty(db(r).ICA.icaweights)

        % recover
        EEG = recoverEEG(db, r, 'local');

        % select good channels:
        allchan = 1:size(EEG.data,1);
        allchan(db(r).chan.bad) = [];

        % perform ICA
        EEG = pop_runica(EEG, 'extended', 1, 'interupt',...
            'off', 'verbose', 'on', 'chanind', allchan);

        % apply weights
        db = db_addw(db, r, EEG);

    end
end
