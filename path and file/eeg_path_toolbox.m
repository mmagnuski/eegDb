function eeg_path_toolbox(tlbx)

% currently works only for adding paths
% to eeglab toolboxes (without having to
% run eeglab)

tlbx = lower(tlbx);
err = @(s) error('%s toolbox not found.', s);

flp = fileparts(which('eeglab'));
lst = dir([flp, '\plugins']);

if length(lst) < 3
    err(tlbx);
end

lst = lst(3:end);
nms = {lst.name};

tl = cellfun(@(x) ~isempty(strfind(lower(x), tlbx)), nms);

if any(tl)
    addtl = nms(tl);
    pths = cellfun(@(x) fullfile(flp, 'plugins',...
        x), addtl, 'Uni', false);
    addpath(pths{:});
else
    err(tlbx);
end