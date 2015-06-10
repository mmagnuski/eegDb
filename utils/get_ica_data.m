function data = get_ica_data(EEG, ind)

% returns EEG.icaact or calculates
% it if it is not present

if ~exist('ind', 'var')
    ind = 1:size(EEG.icaweights, 1);
end

if femp(EEG, 'icaact')
	data = EEG.icaact(ind,:,:);
else
	dt_size = size(EEG.data);
	dt_size(1) = length(ind);
    data = reshape((EEG.icaweights(ind, :) * EEG.icasphere) ...
    	* EEG.data(EEG.icachansind, :), dt_size);
end