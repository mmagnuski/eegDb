function EEG = db_fastepoch(EEG, ev, lim)

% faster epoching
% 
% faster because:
% does not use various key options
% does not load eeglab_options (which is quite slow)
% does not use eeg_checkset etc. (really slow!)
% does not add AMICA probs
%
% coded by mmagnuski

% TODOs:
% [ ] check if fillig EEG.epoch could be faster...
% [x] repect boundary events

% persistent uint32_max
% if isempty(uint32_max)
%     uint32_max = int64(4294967296);
% end

all_tps = {EEG.event.type};
ms_per_sample = (1000/EEG.srate);

% if not indices turn to ind:
if ischar(ev)
    ev = {ev};
end

if iscell(ev)
    % make sure it is column-wise
    sz = size(ev);
    if sz(1) > sz(2)
        ev = ev';
    end
    % turn to event indices
    ev = cellfun(@(x) strcmp(x, all_tps), ev, 'uni', false);
    ev = cell2mat(ev');
    ev = find(sum(ev,1) > 0);
end

% get number of epochs
epoch_num = length(ev);

% get event number and event latencies
all_ev_num = length(EEG.event);
all_lats   = uint32([EEG.event.latency]);
lats       = all_lats(ev);


% compute limits
reallim(1) = round(lim(1)*EEG.srate);
reallim(2) = round(lim(2)*EEG.srate-1); % do not include the last sample (as pop_epoch does)

% get epoch ranges:
epoch_lats = uint32([lats + reallim(1); lats + reallim(2)]);

% do not include epochs that are out of limits:
good_epochs = all(epoch_lats > 0 & epoch_lats < EEG.pnts, 1);

% seelct only good epochs (within the limits of data)
if ~all(good_epochs)
    epoch_lats = epoch_lats(:, good_epochs);
    ev = ev(good_epochs);
    epoch_num = sum(good_epochs);
end

% check trial length
epoch_length = uint32(reallim(2)-reallim(1)+1);

% prepare loop variables
epdt    = zeros( EEG.nbchan, epoch_length, epoch_num );
rem_ev  = true(1, all_ev_num);
rem_ep  = false(1, epoch_num);
ee      = 1; % effective epoch - used for time correction when epochs are removed


% prepare EEG.epoch structure
empep  = cell(1, epoch_num);
flds   = fields(EEG.event);
latfld = find(strcmp('latency', flds));
epflds = cellfun(@(x) ['event', x], flds, 'uni', false);
numf   = length(flds);
fldop  = cell(1, (numf + 1) * 2);
fldop{1} = 'event';
[fldop{2:2:end}] = deal(empep);
[fldop{3:2:end}] = deal(epflds{:});
EEG.epoch = struct(fldop{:});

flds(latfld) = [];
epflds(latfld) = [];

% add epoch field to events
EEG.event(1).epoch = [];
evnt_accum         = 0;

for e = 1:epoch_num
    % check which evnts are in this range
    ev_mask = all_lats > epoch_lats(1,e) & all_lats < epoch_lats(2,e);
    num_ev  = sum(ev_mask);
    
    % check if boundary event is there:
    tps = all_tps(ev_mask);
    if any(strcmp('boundary', tps))
        rem_ep(e) = true;
        continue
    end
    
    % do not remove these events
    rem_ev(ev_mask) = false;
    
    % adjust events time
    sel_ev_lats = all_lats(ev_mask);
    lt = num2cell(sel_ev_lats - epoch_lats(1,e) + (ee-1)*epoch_length + 1);
    [EEG.event(ev_mask).latency] = deal(lt{:});
    [EEG.event(ev_mask).epoch]   = deal(ee);
    
    % fill in EEG.epoch
    EEG.epoch(ee).event = 1:num_ev + evnt_accum;
    EEG.epoch(ee).eventlatency = (sel_ev_lats - lats(e)) * ms_per_sample;
    for f = 1:numf-1
        EEG.epoch(ee).(epflds{f}) = {EEG.event(ev_mask).(flds{f})};
    end
    
    % cut out a portion of the data
    epdt(:, :, e) = EEG.data(:, epoch_lats(1,e) : epoch_lats(2,e));
    
    % increment effective epoch
    ee = ee + 1;
end

% remove epochs
if any(rem_ep)
    epdt(:,:,rem_ep) = [];
end

% remove events:
EEG.event(rem_ev) = [];

% put epoched data to EEG.data
EEG.data = epdt;

% correct field values
EEG.trials = size(EEG.data, 3);
EEG.pnts   = epoch_length;
EEG.times  = (reallim(1):reallim(end)) * ms_per_sample;
EEG.xmin   = EEG.times(1)/1000;
EEG.xmax   = EEG.times(end)/1000;