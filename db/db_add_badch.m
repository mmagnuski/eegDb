function db = db_add_badch(db, r, badch)

% adds badchannels to db
% assumes that if db is not given
% there exists an 'db' structure
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
    if ~isempty(db)
        db(r).chan.bad = sort(unique([db(r).chan.bad, badch]));
    else
        % CHANGE - !!this is dangerous:
        % evalin base workspace:
        evalin('base', ['db(', num2str(r), ').badchan = ',...
            'sort(unique([db(', num2str(r), ').badchan, ',...
            num2str(badch'), ']));']);
    end
end
