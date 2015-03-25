function spect = SpectPwelch(EEG, opt)

% SpectPwelch(EEG, opt) computes spectra
% using pwelch's method and returns them
% in FieldTrip format.
% (they can be later passed to FieldTrip for
%  clustering analysis etc.)
%
% Output is in power, not dB, but can be easily
% tranformed to dB by:
% >> spect.powspctrm = 10*log10(spect.powspctrm);
%
% ==INPUT==
%  EEG      - EEGlab EEG structure
%  opt      - options structure with following optional fields:
%     .elec     - [indices or labels or 'all']
%                 electrodes to analyse
%     .epochs   - [indices] epochs to analyse
%     .wintimes - [start, end] in ms or samples of EEG 
%                 times to analyse
%     .winlen   - [numerical] pwelch window size
%                 (in ms or samples - see .timeval field)
%     .winmove  - [numerical] window step
%                 (in ms or samples - see .timeval field)
%     .wintype  - name of the windowing function to use
%                 (default is 'hanning')
%     .overlap  - [numerical, 0-1] ratio of overlap
%                 (0.5 --> 50% overlap)
%                 (overwrites .winmove)
%     .seglen   - [numerical] (in ms or samples)
%     .segmove  - [numerical] (in ms or samples) for continuous
%                 data, how to move the window (time-frequency
%                 style) through the continuous, but potentially
%                 segmented data (boundary events).
%     .padding  - [numerical, 1-inf] n times to oversample
%                 (defines zero padding length, 1 is none)
%     .padto    - [numerical] pad to specific sample length
%                 (overwrites .padding)
%     .timeval  - ['ms' or 'samp'] defines whether all 
%                 time values are in milliseconds or samples
%                 (default: milliseconds)
%     .verbose  - [boolean] whether SpectPwelch should inform
%                 about it's progress. 
%     .comp    - [boolean] whether to compute spectrum from
%                 components (true) or electrodes (false)
% ==OUTPUT==
% spect     - structure of FieldTrip format
%
%
% coded by Miko³aj Magnuski

% TODOs:
% [ ] compare with EEGlabs spectopo - are they the same?
% [ ] check if any updates are necessary
% [ ] event info export
% [ ] analysis of continuous signal
%     [in progress |##___| ]

%% checking opt fields

if ~isfield(opt, 'elec') || isempty(opt.elec)
    opt.elec = 1:size(EEG.data,1);
end
if ~isfield(opt, 'wintimes') || isempty(opt.wintimes)
    if ~femp(opt, 'timeval') || (femp(opt, 'timeval')...
            && strcmp(opt.timeval, 'ms'))
        opt.wintimes = [EEG.times(1), EEG.times(end)];
    else
        opt.wintimes = [1, length(EEG.times)];
    end
end
if ~isfield(opt, 'winlen') || isempty(opt.winlen)
    opt.winlen = diff([EEG.times(1), EEG.times(end)])/2;
end
if ~isfield(opt, 'winmove') || isempty(opt.winmove)
    opt.winmove = opt.winlen/4;
end
if ~isfield(opt, 'overlap') || isempty(opt.overlap)
    opt.overlap = opt.winlen / (opt.winlen - opt.winmove);
end
if ~isfield(opt, 'padding') || isempty(opt.padding)
    opt.padding = 2;
end
if ~isfield(opt, 'verbose') || isempty(opt.verbose)
    opt.verbose = true;
end
if ~isfield(opt, 'timeval') || isempty(opt.timeval)
    opt.timeval = 'ms';
end
if ~isfield(opt, 'epochs') || isempty(opt.timeval)
    opt.epochs = 1:EEG.trials;
end
if ~isfield(opt, 'comp') || isempty(opt.comp)
    opt.comp = false;
end


%% =WELCOME TO THE CODE=

% ==INFOWINDOW====================
if opt.verbose
    handles = info_window;
    set(handles.fig_handle, 'menubar', 'none');
    set(handles.text1, 'String', ...
        'Estimating spectra using Welch''s method');
    % set(handles.text2, 'String', 'Loading to EEGlab');
end
% ================================

%% electrodes
if ischar(opt.elec)
    if strcmp(opt.elec, 'all')
        opt.elec = 1:size(EEG.data,1);
    else
        opt.elec = {opt.elec};
    end
end

if isnumeric(opt.elec)
    elecs = opt.elec;
end

% looking for electrodes
if iscell(opt.elec) && ~opt.comp
    elecs = zeros(1,length(opt.elec));
    for e = 1:length(elecs)
        elecs(e) = find(strcmp(opt.elec{e},...
            {EEG.chanlocs.labels}));
    end
end

%% wintimes
ranges = zeros(1, 2);

if ~(strcmp(opt.timeval, 'samples') || ...
        strcmp(opt.timeval, 'samp'))
    % looking for times fitting these intervals:
    [~, samp1] = min(abs(EEG.times - opt.wintimes(1)));
    [~, samp2] = min(abs(EEG.times - opt.wintimes(2)));
    samp1 = max([samp1, 1]);
    ranges(1, :) = [samp1, samp2];
    clear samp1 samp2
else
    % values are in samples:
    ranges = opt.wintimes;
    ranges = ranges(:)';
end

%% window time values to samples:
sampt = 1000/EEG.srate;
if ~(strcmp(opt.timeval, 'samples') || ...
        strcmp(opt.timeval, 'samp'))
    % winlen
    opt.winlen = round(opt.winlen/sampt);
    opt.winlen = min(opt.winlen, length(EEG.times));
    
    % overlap
    opt.overlap = round(opt.overlap*opt.winlen);
    opt.overlap = min(opt.overlap, opt.winlen - 1);
end

%% checks for continuous signal
% CNT = false;
% bound = find(strcmp('boundary', {EEG.events.type})); %#ok<EFIND>
% if EEG.trials == 1 && (~isempty(bound) || ...
%         femp(opt, 'segmove') || femp(opt, 'seglen'))
%     % this means that signal is continuous or
%     % can be treated this way
%     CNT = true;
%     
%     % ================================
%     % checking seglen (segment length)
%     if ~femp(opt, 'seglen')
%         % the default is four weleches
%         % per segment:
%         opt.seglen = min(opt.winlen + 3 * ...
%             (opt.winlen - opt.overlap), ...
%             dif(opt.wintimes) + 1);
%     else
%         % check if samples or not:
%         if ~(strcmp(opt.timeval, 'samples') || ...
%         strcmp(opt.timeval, 'samp'))
%             % not in samples, convert:
%             opt.seglen = round(opt.seglen / sampt);
%         end
%         
%         % if fits the wintimes:
%         opt.seglen = min(opt.seglen, ...
%             dif(opt.wintimes) + 1);
%     end
%     
%     % ================================
%     % checking segmove (segment step):
%     if ~femp(opt, 'segmove')
%         % the default is 1/4 of seglen:
%         opt.segmove = round(opt.seglen / 4);
%     else
%         % check if samples or not:
%         if ~(strcmp(opt.timeval, 'samples') || ...
%         strcmp(opt.timeval, 'samp'))
%             % not in samples, convert:
%             opt.segmove = round(opt.segmove / sampt);
%         end
%     end
%     
%     % ==============================
%     % checking segments generated by 
%     % chosen options
%     
%     
% end
%     
% if ~isfield(opt, 'segmove') || isempty(opt.segmove)
%     % we have to define segmove
%     
%     
%     opt.segmove = ;
% end
% end

% padding
if ~isfield(opt, 'padto') || isempty(opt.padto)
    opt.padto = round(opt.padding * opt.winlen);
end

% freqlen from padto:
freqlen = opt.padto/2 + 1;


%% fieldtrip structure
% spect.cumtapcnt seems to be all ones
% with dimesions: [trials X freqs]
% dimord: 'rpt_chan_freq_time'
spect.label = {EEG.chanlocs.labels};
spect.label = spect.label(elecs);
spect.dimord = 'rpt_chan_freq';
spect.freq = linspace(0, EEG.srate/2, freqlen);
spect.powspctrm = zeros(length(opt.epochs), length(opt.elec),...
    freqlen);
spect.cumtapcnt = ones(length(opt.epochs), freqlen);
% additional field with info about epochs:
if femp(EEG, 'epoch')
    spect.epochinfo = EEG.epoch(opt.epochs);
end


% elec:
% [ ] CHANGE to component
spect.elec.pnt   = zeros(length( EEG.chanlocs ), 3);
for ind = 1:length( EEG.chanlocs )
    spect.elec.label{ind} = EEG.chanlocs(ind).labels;
    if ~isempty(EEG.chanlocs(ind).X)
        spect.elec.pnt(ind,1) = EEG.chanlocs(ind).X;
        spect.elec.pnt(ind,2) = EEG.chanlocs(ind).Y;
        spect.elec.pnt(ind,3) = EEG.chanlocs(ind).Z;
    else
        spect.elec.pnt(ind,:) = [0 0 0];
    end;
end;

% ==INFOWINDOW====================
if opt.verbose
    numep = num2str(length(opt.epochs));
    maks = length(opt.epochs) * length(opt.elec);
    counter = 0;
end
% ================================

%% choose data:
% elec or comp
if ~opt.comp
    % just electrodes
    alldata = EEG.data(elecs,ranges(1,1):...
        ranges(1,2),opt.epochs);
else
    % components, check whether icaact present:
    if isfield(EEG, 'icaact') && ~isempty(...
            EEG.icaact)
        % present, take it from there
        alldata = EEG.icaact(elecs,ranges(1,1):...
            ranges(1,2),opt.epochs);
    else
        % not present - construct
        icaact = eeg_getdatact(EEG, ...
            'component', elecs);
        alldata = icaact(:,ranges(1,1):...
            ranges(1,2),opt.epochs);
        clear icaact
    end
end

% CHANGE - demean needed?
alldata = alldata - repmat(mean(alldata,2),...
    [1, size(alldata, 2), 1]);

%% loop across trials
% looping through epochs:
for ep = 1:length(opt.epochs)
    
    % ==INFOWINDOW====================
    if opt.verbose
        set(handles.text2, 'String', ['Epoch ', num2str(ep),...
            ' out of ', numep]);
        drawnow
    end
    % ================================
    
    % looping through channels/comps:
    for e = 1:length(opt.elec)
        
        % pwelch
        [spect.powspctrm(ep,e,:), freq] = pwelch(alldata(e,...
            :, ep), opt.winlen, opt.overlap, opt.padto, EEG.srate);
        
        % ==INFOWINDOW====================
        if opt.verbose
            counter = counter + 1;
            info_window(counter, maks, handles);
        end
        % ================================
    end
    
end

% if small differences in freqency vector
% assume the one returned by pwelch is correct
if ~isequal(spect.freq, freq)
    spect.freq = freq;
end

% wyci¹gamy info o epokach z EEG.epoch
%     if ~isempty(export_evinf)
%         for exp = 1:length(export_evinf)
%             Data(sub).(export_evinf{exp}) = zeros(length(EEG.epoch),1);
%             for ep = 1:length(EEG.epoch)
%                 i = cell2mat([EEG.epoch(ep).eventlatency]) == 0;
%
%                 Data(sub).(export_evinf{exp})(ep) = EEG.epoch(ep)...
%                     .(['event', export_evinf{exp}]){i};
%
%             end
%         end
%     end


%% close and clear up

% ==INFOWINDOW====================
if opt.verbose
    close(handles.fig_handle);
    clear handles
end
% ================================
