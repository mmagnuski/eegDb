function ICAw = ICAw_add_badch(ICAw, r, badch)

% adds badchannels to ICAw
% assumes that if ICAw is not given
% there exists an 'ICAw' structure
% in the base workspace
% if badchans are not given as numericals
% assumes that they are space delimited
% channel labels:
% FIXHELPINFO

if ~isnumeric(badch) && ischar(badch)
    % CHANGE - doesn't make sense to require EEG in base workspace for this
    % CHANGE - chanlocs should be in datainfo
    chans = strsplit(badch, ' ');
    badch = zeros(size(chans));
    
    for a = 1:length(chans)
        badch(a) = evalin('base', ['find(strcmp(''', chans{a},...
            ''', {EEG.chanlocs.labels}));']);
    end
end

if ~isempty(badch)
    if ~isempty(ICAw)
        ICAw(r).badchan = sort(unique([ICAw(r).badchan, badch]));
    else
        % evalin base workspace:
        evalin('base', ['ICAw(', num2str(r), ').badchan = ',...
            'sort(unique([ICAw(', num2str(r), ').badchan, ',...
            num2str(badch'), ']));']);
    end
end
