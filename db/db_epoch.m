function EEG = db_epoch(EEG, db, r, segmentinfo)

% DB_EPOCH is the function used by eegDb for epoching
% files are epoched automatically when they are recovered
% FIXHELPINFO


if femp(db(r), 'epoch')

    % defaults
    % --------
    code_id = '\code:'; 
    cidlen = length(code_id);

    if ~exist('r', 'var')
        r = 1;
    end

    if ~exist('segmentinfo', 'var')
        % is segment given:
        if isfield(db(r).epoch, 'segment') && ...
                ~isempty(db(r).epoch.segment) && isnumeric(db(r).epoch.segment)
            segmentinfo = true;
        end
    end

    % windowing 
    % ---------
    % (consecutive epochs, not event locked)
    if femp(db(r).epoch, 'locked') && ~db(r).epoch.locked
        
        % ==============
        % onesec options
        options.fill = true;
        
        flds = {'filter', 'winlen', 'distance',...
            'leave', 'eventname'};
        
        % checking fields for onesecepoch
        for f = 1:length(flds)
            if femp(db(r).epoch, flds{f})
                options.(flds{f}) = db(r).epoch.(flds{f});
            end
        end

        % if prerej is present then no need to use distance
        if femp(db(r).reject, 'pre')
            options.distance = [];
        end
        
        % ===================
        % call to onesecepoch
        EEG = onesecepoch(EEG, options);
        clear options
        
    elseif ~isempty(db(r).epoch.events) && ...
            ~isempty(db(r).epoch.limits)
        
        % ==================
        % classical epoching
        epoc = db(r).epoch.events;
        
        % checking for code generator of epochs
        % ADD - function handle for epoching?
        %       or maybe not necessary - there is an
        %       option for user-defined function
        if ischar(epoc) && length(epoc) > cidlen && ...
                strcmp(epoc(1:cidlen), code_id)
            
            epoc = eval(epoc(cidlen+1:end));
        end
        
        EEG = db_fastepoch(EEG, epoc, db(r).epoch.limits);
        
        % =======================
        % checking for segmenting
        if segmentinfo && ~nosegment
            EEG = segmentEEG(EEG, db(r).epoch.segment);
        end
    end
end

% CHANGE
% [ ] if we segment then orig_numep should be adjusted too
% [ ] instead of numep this all can be done in a smarter way
%                1) generally - onesec can add numep too
%                2) numep can be inferred from length of rejections
%                   in db(r)!
%                3) ...
% [ ] in the current version only onesecepoching is checked
%     for while in future releases we want to include also
%     conditional epoch extraction (only correct etc.) which
%     is another prerej
%
%
% ======================
% adding orig_numep info
%
% (this is later used when rejections are added
%  using a recovered file that has some of the
%  rejections already removed)
%
% if epoched signal add orig_numep
EEG.etc.orig_numep = size(EEG.data, 3);

% if onesecepoch was perfromed add onesec info
if femp(db(r).epoch, 'locked') && ~db(r).epoch.locked
    
    % either prerej is nonempty  % or what?
    if femp(db(r).reject, 'pre')
        % there is some info about prerej,
        % we correct orig_numep
        EEG.etc.orig_numep = EEG.etc.orig_numep - length(db(r).reject.pre);
    end
end
