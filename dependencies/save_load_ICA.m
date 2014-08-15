% saving ICA
ICA.icawinv = EEG.icawinv;
ICA.icasphere = EEG.icasphere;
ICA.icaweights = EEG.icaweights;
ICA.icachansind = EEG.icachansind;

% loading ICA:
EEG.icawinv = ICA.icawinv;
EEG.icasphere = ICA.icasphere;
EEG.icaweights = ICA.icaweights;
EEG.icachansind = ICA.icachansind;
