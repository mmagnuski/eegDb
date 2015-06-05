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


allrej = 0;
% change check fields to include other non-standard fields
chckflds = {'rejjp', 'rejmanual', 'rejfreq'}; % CHANGE

% check for additional arguments:
if nargin > 1
    chckflds = varargin{1};
end

len = length(chckflds);
numep = cell(1,len);
eplen = size(EEG.data, 2);

% get info on rejections
for f = 1:len
    if isfield(EEG.reject, chckflds{f}) && ...
            ~isempty(EEG.reject.(chckflds{f}))
        rejperf = sum(EEG.reject.(chckflds{f}));
        numep{f} = find(EEG.reject.(chckflds{f}))';
        allrej = allrej + rejperf;
    end
end


% CHANGE - a dirty workaround (rejections were not shown)
% if db is present:
if isfield(EEG.reject, 'db')
    templen = length(EEG.reject.db.name);
    track = 0;
    for f = 1:templen
        if ~isempty(EEG.reject.db.value{f})
            
            rejperf = sum(EEG.reject.db.value{f});
            
            if rejperf > 0
                track = track + 1;
                fname = sprintf('tempfield%d', track);
                
                chckflds{len + track} = fname;
                numep{len + track} = find(EEG.reject.db.value{f});
                EEG.reject.([fname, 'col']) = EEG.reject.db.color{f};
                
                allrej = allrej + rejperf;
            end
        end
    end
    len = len + track;
end
clear f rejperf
        
rejmat = zeros(allrej, 5 + EEG.nbchan);
rejsofar = 0;
clear allrej

% fill rejection matrix
for f = 1:len
    % fill by matrix multiplication:
    lent = length(numep{f});
    if lent > 0
        rejmat(rejsofar+1 : lent+rejsofar, 1 : 2) = ...
            [numep{f}(:), repmat(eplen - 1, [lent, 1])] ...
            * [eplen, eplen; -1, 0];
        rejmat(rejsofar+1 : lent+rejsofar, 3 : 5) = ...
            repmat(EEG.reject.([chckflds{f}, 'col']), ...
            [lent, 1]);
        rejsofar = rejsofar + lent;
    end
end
clear rejsofar lent numep