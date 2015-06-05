function db = db_cleanline_chan_thresh(db, thresh)

% NOHELPINFO

% CHANGE
% [ ] if cleanline field is logical do not use struct 
%     field assignment to ommit warnings
% [x] will fail if one of cleanline fields contains a struct

rs = find(~cellfun(@isempty, {db.cleanline}));

% cleanline values
cl = cellfun(@(x) (islogical(x) && x) || ...
    isstruct(x), {db(rs).cleanline});
cl = rs(cl);

% recover one such file:
for r = 1:length(cl)
    fprintf('recovering record %d\n', cl(r));
    EEG = recoverEEG(db, rs(3), 'local');
    
    % check spectrum
    [spectra, freqs] = pop_spectopo( EEG, 1, ...
        EEG.times([1, end]), 'EEG', 'plot', 'off');
    
    % de-dB the spectra
    spectra = 10.^(spectra / 10);
    
    % look for 50 Hz:
    [~, noisesamp] = min(abs(freqs - 50));
    
    noisepow = spectra(:,noisesamp);
    db(cl(r)).cleanline.chanlist = find(noisepow > thresh);
end