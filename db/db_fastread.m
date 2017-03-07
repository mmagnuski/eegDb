function EEG = db_fastread(pth, fnm)

% fast version of pop_loadset for .set + .fdt files
% does not read option files, does not use eeg_checkset
% just reads the data in

% TODOs:
% - [ ] set relevant filepath? (checkset does it)
% - [ ] set 'saved' field to 'justloaded'

% load .set metadata
ld = load(fullfile(pth, fnm), '-mat');
EEG = ld.EEG;

% load .fdt EEG signal:
fdtfl = fullfile(pth, [fnm(1:end-3), 'fdt']);
fid = fopen( fdtfl, 'r', 'ieee-le');
EEG.data = fread(fid, [EEG.nbchan, EEG.pnts * EEG.trials], 'float32');
fclose(fid);

% reshape data
if EEG.trials > 1
    EEG.data = reshape(EEG.data, [EEG.nbchan, EEG.pnts, EEG.trials]);
end
