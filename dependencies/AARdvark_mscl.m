function [EEG, rejn, more] = AARdvark_mscl(EEG, optin)

% AARdvark_mscl() marks epochs with excessive
% muscle noise.
% Usage:
% EEG = AARdvark_mscl(EEG, AbvHz, ChanRat);
% [EEG, rejn, rawfreq] = AARdvark_mscl(EEG, AbvHz,...
%     ChanRat, channels, nw);
%
% ===INPUT===
% EEG       - eeglab EEG structure
% opt       - options strucutre, with optional fields:
%    .thresh    - how many dB (or STD) above channel mean (
%                 within a Hz range) should a channel (in a
%                 given epoch) be to be marked as artifactual.
%                 (default: 5 dB)
%    .chrat     - ratio of all channels (0 - 1) marked as
%                 artifactual needed to reject given epoch
%                 (default: 1/3)
%    .range     - frequency range inspected for artifacts
%                 (default: 65 - 100 Hz)
%    .chn       - which channels to analyse
%                 (default: all)
%    .display   - if set to true this option allows you to
%                 inspect the rejections immediately after
%                 AARdvark finishes its work - EEGlab's
%                 eegplot function is called 
%    .nw        -  time-bandwidth product for the discrete
%                  prolate spheroidal sequences. If you
%                  specify nw as the empty vector [], a
%                  default value of 4 is used. Other typical
%                  choices are 2, 5/2, 3, or 7/2.
% ===OUTPUT===
% EEG       - eeglab EEG structure with respective
%             reject fields filled
% rejn      - epoch numbers marked for rejection
% more      - structure with following fields:
%     .rawfreq   - channel X freq X epoch matrix of
%                  spectral estimates  straight from
%                  pmtm function
%     [and other...]

% coded by Miko³aj Magnuski, 2013, august
%
% TODOs:
% [ ] display option finished
% [ ] smart clustering (?)
% [ ] aardvark clears (itself/data)

%% defaults:
opt.chn = 1:size(EEG.data, 1);
opt.nw = [];
opt.remmean = 'after'; opt.mode = 'mean';
opt.measure = []; opt.thresh = 5;
opt.chrat = 1/3; opt.spect_measure = 'dB'; 
opt.range = [65, 100]; opt.spect = [];
opt.freqs = []; opt.display = false;

%% checking opt input
% flds = fields(opt);
if isstruct(opt)
    fldsin = fields(optin);
    for fld = 1:length(fldsin)
        if ~isempty(fldsin{fld})
            opt.(fldsin{fld}) = optin.(fldsin{fld});
        end
    end
    opt.range = sort(opt.range);
end

%% running AARdvark
% disp:
fprintf('\n');
fprintf('Running AARdvark to reject epochs with muscle noise\n');
try
    path = which('AARdvark_mscl');
    [ardv_img, cmap] = imread([fileparts(path), filesep, 'aardvark.gif']);
    h = figure('Position', [200, 450, 450, 250], 'menubar', 'none');
    image(ardv_img); axis image; colormap(cmap);
    set(gca, 'XTick', [], 'YTick', []);
    title('AARdvark is cleaning your data', 'FontSize', 14);
    drawnow;
catch %#ok<CTCH>
    % :(
end

% EEG size:
EEGs = size(EEG.data);

%% spectral estimation
% freq resolution:
fres = 2^(nextpow2(EEGs(2))-1) + 1;
if isempty(opt.spect)
    fprintf('Estimating spectrum with multiple tapirs and aardvarks\n');
    % allocate spec
    spec = zeros(EEGs(1), fres, EEGs(3));
    EEGs(1) = length(opt.chn);
    
    % initialize mywaitbar:
    nSteps = 24;
    step = 0;
    fprintf(1, 'AARdvark_mscl(): |');
    strLength = fprintf(1,...
        [repmat(' ', 1, nSteps - step) '|   0%%']);
    tic % needed for mywaitbar
    
    % multitapering with default settings:
    for ch = 1:EEGs(1)
        for ep = 1:EEGs(3)
            % multitapering
            [spec(opt.chn(ch),:,ep), opt.freqs] = ...
                pmtm(EEG.data(opt.chn(ch),:,ep), opt.nw, [], EEG.srate);
        end;
        % mywaitbar
        [step, strLength] = mywaitbar(ch, ...
            EEGs(1), step, nSteps, strLength);
    end;
    fprintf('\n');
else
    % user has provided spectral input
    spec = opt.spect;
    if isempty(opt.freqs)
        % assuming linear frequencies from zero to Nyquist
        opt.freqs = linspace(0, fres, EEG.srate/2);
    end
end

% raw output of pmtm
more.rawfreq = spec;
more.freqs = opt.freqs;

%% spectrum analysis
if strcmp(opt.spect_measure,'dB');
% log base 10
spec  = 10*log(spec);
end

if strcmp(opt.remmean, 'before')
    more.beforedemean = spec;
    % remove channel mean
    spec = spec - repmat( mean(spec,3), [1 1 size(EEG.data,3)]);
end

% find closeset Hz's to defined range
[~, Hzlow] = min(abs(opt.freqs - opt.range(1)));
[~, Hzhi] = min(abs(opt.freqs - opt.range(2)));

switch opt.mode
    case 'mean'
        % mean power for Hz range
        rej1 = squeeze(mean(spec(:,Hzlow:Hzhi,:),2));
    case 'max'
        % max power for Hz range
        rej1 = squeeze(max(spec(:,Hzlow:Hzhi,:),2));
end
more.rej1 = rej1;

if strcmp(opt.remmean, 'after') || (...
        ~strcmp(opt.remmean, 'before') && opt.remmean)
    % remove channel mean
    rej1  = rej1 - repmat( mean(rej1,2), [1 size(EEG.data,3)]);
    more.rej2 = rej1;
end

if strcmp(opt.measure, 'STD');
    rej1 = zscore(rej1, 0, 2);
end

chanartif = rej1>opt.thresh;

% if more than ChanRat of channels is AbvHz above the mean:
rej = sum(chanartif, 1)>=round(length(opt.chn)*opt.chrat);

%% output preparation, finishing remarks
% show ONLY the channels contributing to rejection:
chanartif(:,~rej) = false;

% fill EEG rejection field
EEG.reject.rejfreq = rej;
EEG.reject.rejfreqE = chanartif;

% epoch id's:
rejn = find(rej);

% display (like EEGlab does :P)
fprintf('%d/%d epochs marked for rejection\n', length(rejn),...
    size(EEG.data, 3));

% add code for display
% rejected epochs will be collored with
% 'winrej'     - [start end R G B e1 e2 e3 ...]
% option for the eegplot function

try
    close(h);
    refresh % necessary?
    drawnow % necessary?
catch %#ok<CTCH>
    % :(
end