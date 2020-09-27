function EEG = ft2eeglab(data, varargin)

% FT2EEGLAB converts fieldtrip data structure to eeglab structure.
%
% Parameters
% ----------
% data : struct
%     Fieldtrip data structure.
% 'partial' : str
%     How to treat partial epochs. The default is 'ignore' which causes
%     partial epochs to be dropped. Another option: 'nan' is currently
%     not implemented.
% 'ica' : cell or struct
%     Either cell array of {weights, sphere} or {weights, sphere, inv} or
%     fieldtrip comp structure.
%
% Returns
% -------
% EEG : struct
%     EEGlab data structure.

% TODOs:
% - [ ] compare with some actual EEG struct from Tomek or Ola
% - [x] allow to fill unavailable parts of trials with NaN
% - [x] add chanlocs
% - [x] add ica

% assert that all dimensions agree
n_chan = cellfun(@(x) size(x, 1), data.trial);
assert(all(n_chan(1) == n_chan), 'Mismatch of channel number across trials.');

n_samp = cellfun(@(x) size(x, 2), data.trial);

opt.ica = [];
opt.partial = 'ignore';
opt = parse_arse(varargin, opt);

% partial has to be 'ignore' or 'NaN'
% ...

% safety checks
% -------------
% assumption - the trials with max n_samples represent original 'uncut'
% epochs and therefore contain the same time
max_samples = max(n_samp);
tri_maxsamp_mask = n_samp == max_samples;
tri_maxsamp_idx = find(tri_maxsamp_mask);
time = data.time{tri_maxsamp_idx(1)};
tmin = min(time); tmax = max(time);

n_trials = length(data.trial);

for idx = 2:length(tri_maxsamp_idx)
    this_tri = tri_maxsamp_idx(idx);
    same_time = all(time == data.time{this_tri});
    if ~same_time
        error(['Longest trials do not have the same time. See trial %d', ...
               ' and trial %d.'], tri_maxsamp_idx(1), this_tri);
    end
end

% therefore all other trials do not exceed the times
% of the max n_sample trials
other_tri_idx = find(~tri_maxsamp_mask);
for idx = other_tri_idx
    tmin_ok = tmin <= data.time{idx}(1);
    tmax_ok = tmax >= data.time{idx}(end);
    
    if ~tmin_ok || ~tmax_ok
        error(['At least one trial (%d) that is shorter than the ', ...
               'longest trial has time that exceeds the time of the ', ...
               'longest trial.'], idx);
    end
end

% select longest trials if partial trials should be ignored
if strcmp(opt.partial, 'ignore') && length(tri_maxsamp_idx) < n_trials
    cfg = []; cfg.trials = tri_maxsamp_idx;
    data = ft_selectdata(cfg, data);
    n_trials = length(data.trial);
elseif strcmpi(opt.partial, 'nan') && length(tri_maxsamp_idx) < n_trials
    for idx = other_tri_idx
        tmin = data.time{idx}(1);
        tmax = data.time{idx}(end);
        tmin_idx = find(time == tmin, 1, 'first');
        tmax_idx = find(time == tmax, 1, 'last');
        
        this_data = data.trial{idx};
        data.time{idx} = time;
        data.trial{idx} = nan(n_chan(1), max_samples);
        data.trial{idx}(:, tmin_idx:tmax_idx) = this_data;
    end
end

% create EEG structure
fields = {'setname', '', 'filename', '', 'filepath', '', 'subject', '', ...
          'group', '', 'condtion', '', 'comments', '', 'ref', [], ...
          'icawinv', [], 'icasphere', [], 'icaweights', [], 'icaact', ...
          [], 'saved', 'no', 'session', [], 'srate', data.fsample, ...
          'nbchan', n_chan(1), 'trials', n_trials, 'pnts', n_samp(1), ...
          'times', time, 'xmin', data.time{1}(1), 'xmax', ...
          data.time{1}(end)};
EEG = struct(fields{:});
EEG.data = cell2mat(data.trial);
EEG.data = reshape(EEG.data, [n_chan(1), max_samples, n_trials]);

zero_samp = find(data.time{1} == 0);
add_smp = 0:n_samp(1):n_samp(1)*(n_trials - 1);
lats = num2cell(zero_samp + add_smp');

% get data from trialinfo
if isfield(data, 'trialinfo') && size(data.trialinfo, 2) == 1
    types = arrayfun(@num2str, data.trialinfo, 'uni', false);
else
    types = repmat({'X'}, n_trials, 1);
end

epoch_idx = num2cell((1:n_trials)');
args = {'latency', lats, 'type', types, 'epoch', epoch_idx};
EEG.event = struct(args{:});

EEG.epoch = struct('event', epoch_idx);

% add channel positions (chanlocs):
if isfield(data, 'elec') && isfield(data.elec, 'chanpos')
    pos = data.elec.chanpos;
    lab = data.elec.label;
    chanlocs = struct();
    for ch = 1:n_chan
        chanlocs(ch).labels = lab{ch};
        chanlocs(ch).X = pos(ch, 2);
        chanlocs(ch).Y = pos(ch, 1) * -1;
        chanlocs(ch).Z = pos(ch, 3);
    end
    EEG.chanlocs = chanlocs;
end

% make sure channel locations get converted to other systems
EEG.chaninfo = [];
EEG = eeg_checkchanlocs(EEG);

% add ica info if present
if iscell(opt.ica)
    % FIXME - cover situation with only weights and sphere
    if length(opt.ica) == 3
        [weights, sphere, winv] = deal(opt.ica{:});
    end
    EEG.icachansind = 1:n_chan(1);
    EEG.icaweights = weights;
    EEG.icasphere = sphere;
    EEG.icawinv = winv;
    EEG.reject.gcompreject = zeros(size(weights, 1), 1);
end