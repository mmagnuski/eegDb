function ICAw = ICAw_add_badch(ICAw, r, badch)

% adds badchannels to ICAw
% assumes that if ICAw is not given
% there exists an 'ICAw' structure
% in the base workspace
% if badchans are not given as numericals
% assumes that they are space delimited
% channel labels:

if ~isnumeric(badch) && ischar(badch)
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
