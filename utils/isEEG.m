function isit = isEEG(dat)

% checks if input is eeglab EEG structure

isit = false;
if ~isstruct(dat)
    return
end

flds = {'nbchan', 'trials', 'pnts', 'srate', 'times', ...
'data', 'icaweights', 'icachansind', 'chanlocs', ...
'event', 'epoch'}; % 'ref', 'urevent'

isit = all(isfield(dat, flds));