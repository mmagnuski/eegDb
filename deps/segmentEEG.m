function EEG = segmentEEG(EEG, seg)

% segmentEEG() allows to divide longer epochs
% into their shorter equal-sized components.
% This is useful both for automatic artifact
% rejection (for example reject epoch iff >2
% of its segments are artifactual) as well 
% as treating your data gently and rejecting 
% only segments of full epoch, and then mo-
% difying your analysis accordingly (for exam-
% ple reconstructing ERSP of full epoch from
% its remaining segments or baselining full
% epochs with mean of baseline segments etc.)
% Usage:
% EEG = segmentEEG(EEG, seg);
% ===INPUT===
% EEG     - eeglab EEG structure
% seg     - length of segments in seconds
% ===OUTPUT===
% EEG - segmented EEG structure
%
%
% coded by M. Magnuski, August 2013

% TODOs:
% [ ] move events according to their epoch latency
%     - if segment length is 250 samples and original
%       (unsegmented) epoch has an event with latency
%       of 300 then this event should be moved to second
%       segment of this epoch.



%% segment the data:
epl = length(EEG.times);
segs = seg*EEG.srate;
segnum = epl/round(segs);
if segnum == floor(segnum)
    % equal division, phew
else
    enough = floor(segnum)*segs;
    segnum = floor(segnum);
    EEG.data = EEG.data(:,1:enough,:);
end

if size(EEG.data, 3) > 1
    segnum = size(EEG.data, 3) * segnum;
end
EEG.data = reshape(EEG.data, [size(EEG.data,1), segs, segnum]);
if ~isempty(EEG.icaact)
    EEG.icaact = reshape(EEG.icaact, [size(EEG.icaact,1), segs, segnum]);
end

% later, for moving events across epochs:
% lats = {EEG.epoch.eventlatency};

% for now we don't care about events in different segments
segs = 4;
epn = ((1:length(EEG.epoch))-1)*segs + 1;
allep = size(EEG.data,3);

%% create new empty epoch structure
flds = fields(EEG.epoch);
known = {'event'};
empt = {true};
addf = setdiff(flds, known);

emp = cell(1, allep);
empc = cellfun(@(x) {cell(0,0)}, emp); %#ok<NASGU>

evstr = 'struct(';

for k = 1:length(known)
    addstr1 = ['known{', num2str(k), '}, '];
    if empt{k}
        addstr2 = 'emp, ';
    else
        addstr2 = 'empc, ';
    end
    
    evstr = [evstr, addstr1, addstr2]; %#ok<*AGROW>
end

for k = 1:length(addf)
    addstr1 = ['addf{', num2str(k), '}, empc, '];
    evstr = [evstr, addstr1];
end
evstr(end-1:end) = ');';

% evaluate:
newep = eval(evstr);

%% fill the empty epoch struct:
for e = 1:length(EEG.epoch)
    for f = 1:length(flds)
        newep(epn(e)).(flds{f}) = EEG.epoch(e).(flds{f});
    end
end

%% correct EEG fields
EEG.epoch = newep;
EEG.trials = allep;
EEG.pnts = size(EEG.data,2);
EEG.times = EEG.times(1:EEG.pnts);