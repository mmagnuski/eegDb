function rejmat = eeg_rejmat(EEG, varargin)

% eeg_rejmat() returns rejection matrix used by
% eegplot to display colored rejections
%
% Usage:
% rejmat = eeg_rejmat(EEG);
%     returns rejection matrix for methods:
%     rejjp, rejmanual and rejfreq
%
% rejmat = eeg_rejmat(EEG, fields);
%     where 'fields' is a cell array with names
%     of fields in EEG.reject to check
%     returns rejection matrix corresponding
%     to these methods
%
% coded by M. Magnuski, august 2013

srt = EEG.srate;
allrej = 0;
% change check fields to include other non-standard fields
chckflds = {'rejjp', 'rejmanual', 'rejfreq', 'userreject',...
    'usermaybe', 'userdontknow'};

% check for additional arguments:
if nargin > 1
    chckflds = varargin{1};
end

rejperf = zeros(1,length(chckflds));
numep = cell(1,length(chckflds));

% get info on rejections
for f = 1:length(chckflds)
    if isfield(EEG.reject, chckflds{f}) && ...
            ~isempty(EEG.reject.(chckflds{f}))
        rejperf(f) = sum(EEG.reject.(chckflds{f}));
        numep{f} = find(EEG.reject.(chckflds{f}))';
        allrej = allrej + rejperf(f);
    end
end
clear f rejperf

rejmat = zeros(allrej, 5 + EEG.nbchan);
rejsofar = 0;
clear allrej

% fill rejection matrix
for f = 1:length(chckflds)
    % fill by matrix multiplication:
    len = length(numep{f});
    if len > 0
    rejmat(rejsofar+1 : len+rejsofar, 1 : 2) = ...
        [numep{f}(:), repmat(srt - 1, [len, 1])] ...
        * [srt, srt; -1, 0];
    rejmat(rejsofar+1 : len+rejsofar, 3 : 5) = ...
        repmat(EEG.reject.([chckflds{f}, 'col']), ...
        [len, 1]);
    rejsofar = rejsofar + len;
    end
end
clear rejsofar len f allrej rejperf numep