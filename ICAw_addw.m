function ICAw = ICAw_addw(ICAw, r, EEG)

% NOHELPINFO
% NOTUSED

        ICAw(r).icaweights = EEG.icaweights;
        ICAw(r).icasphere = EEG.icasphere;
        ICAw(r).icawinv = EEG.icawinv;
        ICAw(r).icachansind = EEG.icachansind;