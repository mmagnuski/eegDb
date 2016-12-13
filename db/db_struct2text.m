function infotext = db_struct2text(db, h)

% DB_STRUCT2TEXT returns a string representation of eegDb 
% database contents
%
% infotext = db_struct2text(db)
%
% EXAMPLE:
% >> db_struct2text(db(2));
%    
% filename:  crazy_study_01.set
% filter:    [ 1  x ] (highpass)
% epoch:     -250 to 650 ms
%            with respect to:
%            'face_up', 'face_down',
%             'no_face_at_all'
% reject:    35 epochs rejected
%            (18% of all)
% marks:     reject
%              3 (02.0%)
%            check later
%              12 (08.0%)
% ICA:       done (took 15 min 8.23 s)
%            mutual info: +2.5 z
%            rejected components:
%            13
%            4 brain components
%              (none rejected)
%            5 muscle components
%              (4 rejected)
%    
% see also: db_buildbase, db_gui

% TODOs:
% [ ] - add text-wrapping with respect to h uicontrol
% [ ] - add reject display
% [ ] - add option to change marks display 
%       so that only marks in unrejected 
%       data are shown
% [ ] - if no 'r' passed it is assumed to be 1:length(eegDb) (?)
% [ ] - if r > 1 - present a text summary of all chosen entries

% currently we assume eegDb is one chosen entry
if length(db) > 1
    warning('more than one eegDb entry passed, choosing first');
    % choose first
    db = bd(1);
end

% check for h
if ~exist('h', 'var')
    h = [];
end

ttl = {'filename:', 'filter:', 'epoch:', ...
    'marks:', 'reject:', 'ICA:'};

infotext = addblanks_samelength(ttl, 2)';
startCol = length(infotext{1});


% filename:
% -----------------
infotext{1} = [infotext{1}, db.('filename')];

% filter:
% --------
currentRow = 2;

if femp(db, 'filter')
    infotext{currentRow} = [infotext{currentRow}, ...
        sprintf('[ %3.2f   %3.2f ]', db.filter(1,1), db.filter(1,2))];
end


% epochs:
% -------
currentRow = 3;
addtx{1} = 'no epoching defined';
[ep, eptp] = db_getepoching(db);

if eptp == 1
    addtx{1} = 'cut into consecutive windows';
    % ADD epoch.nwin info (filled after/during epoching)
    % addtx{1} = sprintf('cut into %d consecutive windows', ep.nwin);
    
    addtx{2} = sprintf('of %4.2f seconds long (each)', ep.winlen);
    
    if femp(ep, 'distance')
        addtx{3} = 'preselected based on distance to';
        % ADD 'preselected 230 / 450 (51%) based on distance to'
        
        % formatting distance rules
        % -------------------------
        for i = 1:size(ep.distance, 1)
            evtp = ep.distance{i, 1};
            dist = ep.distance{i, 2};
            
            % format event type
            if isempty(evtp); evtp = 'any event'; 
            elseif ~iscell(evtp); evtp = {evtp}; 
            evtp = lincellstring(evtp); 
            else evtp = lincellstring(evtp); 
            end
            
            % format distance
            if length(dist) == 1; 
                dist = abs(repmat(dist, [1,2])) .* [-1, 1];
            end
            dist = sprintf('%4.2f to %4.2f s', dist(1), dist(2));
            
            addtx{3 + i} = [evtp, ' - ', dist]; %#ok<AGROW>
            
        end
    end
    
elseif eptp == 2
    addtx{1} = 'event-locked epoching';
    % ADD addtx{1} = sprintf('%d event-locked epochs', ep.winlen);
    
    addtx{2} = sprintf('%4.2f to %4.2f s', ep.limits(1), ep.limits(2));
    addtx{3} = 'with respect to:';
    
    % format event types
    evtp = ep.events;
    if ~iscell(evtp); evtp = {evtp}; end
    evtp = cellfun(@deblank, evtp, 'UniformOutput', false);
    evtp = lincellstring(evtp);
    
    % add event types to text
    addtx{4} = evtp;
    
end

% add the addtx:
[infotext, currentRow] = addtotext(infotext, addtx', ...
    currentRow, startCol);

% marks:
% ------
currentRow = currentRow + 1;
nmarks = length(db.marks);
addtx = {};
addtx{1}  = 'no marks';

if nmarks > 0
    mrkNums = cellfun(@sum, {db.marks.value});
    
    nonzero = find(mrkNums > 0);
    nonzerN = length(nonzero);
    
    if nonzerN > 0
        
        % show only marks that are used
        % in format:
        % markname
        %     num   (perc%)
        addtx = cell(nonzerN * 2, 1);
        
        for i = 1:nonzerN
            % mark name
            addtx{2 * (i-1) + 1} = db.marks(nonzero(i)).name;
            
            % no marked
            marked = db.marks(nonzero(i)).value;
            markedN = sum(marked);
            % marked perc
            markedP = sprintf('%3.1f%%', markedN/length(marked) * 100);
            
            addtx{2 * (i-1) + 2} = ['  ', num2str(markedN),...
                '  (', markedP, ')'];
        end
        
        % NOW there is no btw-mrk spacing
        % delete last between-mark spacing
        % addtx(end) = [];
    end
end 

% put addtx into infotext
[infotext, currentRow] = addtotext(infotext, addtx, ...
    currentRow, startCol);


% REJECTIONS
% ----------
currentRow = currentRow + 1;

if eptp == 1
    unit = 'windows';
else
    unit = 'epochs';
end          

is.pre = femp(db.reject, 'pre');
is.post = femp(db.reject, 'post');
is.all = femp(db.reject, 'all');


% CHANGE - currently we do not ensure that reject.pre is logical
%          so it is displayed without % if we do not know the ori-
%          ginal number of epochs (from EEG.etc.orig_numep kept
%          as epochNum or origNum ?)
is.orig = femp(db.epoch, 'origNum');

tracker = 1;
addtx = {};

% PRE-REJECTIONS
% -------------
if is.pre 
    prelen = length(db.reject.pre);
    addtx{tracker} = 'pre-rejected:';
    if is.orig
        addtx{tracker + 1} = sprintf(['  %d  (%3.2f%%) ', unit],...
            prelen, prelen/db.epoch.origNum * 100);
    else
        addtx{tracker + 1} = sprintf(['  %d  ', unit], prelen);
    end
    tracker = tracker + 2;
end

% POST-REJECTIONS
% -------------
if is.post
    postlen = length(db.reject.post);
    % postrej = sum(db.epoch.post);
    % addtx{tracker} = fprintf(['pre-rejected:  %d  (%3.2f%%) ', unit],...
    %      prelen, prelen/db.epoch.origNum * 100);
    addtx{tracker} = 'rejected:';

    if is.orig
        if is.pre
            origNumAfterPre = db.epoch.origNum - prelen;
        else
            origNumAfterPre = db.epoch.origNum;
        end
        addtx{tracker + 1} = sprintf(['  %d  (%3.2f%%) ', unit],...
            postlen, postlen/origNumAfterPre * 100);
    else
        addtx{tracker + 1} = sprintf(['  %d  ', unit], postlen);
    end
    tracker = tracker + 2;
end

% ALL (pre + post)
% ----------------
if is.post && is.pre && is.all && ~isequal(db.reject.pre, db.reject.all)
   alllen = length(db.reject.all);
   addtx{tracker} = 'alltogether:';

   if is.orig
        addtx{tracker + 1} = sprintf(['  %d  (%3.2f%%) ', unit],...
            alllen, alllen/db.epoch.origNum * 100);
    else
        addtx{tracker + 1} = sprintf(['  %d  ', unit], alllen);
    end
    tracker = tracker + 2;
end 

% if none
% -------

if ~is.post && ~is.pre && ~is.all
    addtx{tracker} = ['no ', unit, ' rejected'];
end

% add to infotext
[infotext, currentRow] = addtotext(infotext, addtx, ...
    currentRow, startCol);



%     ICA
% -------
addtx = {};
currentRow = currentRow + 1;
if femp(db.ICA, 'icaweights')
    if femp(db.ICA, 'time')
        time = seconds2time(db.ICA.time);
        addtx{1} = ['done  (took ', time, ')'];
    else
        addtx{1} = 'done';
    end
else
    addtx{1} = 'not done';
end

% add to infotext
[infotext, currentRow] = addtotext(infotext, addtx, ...
    currentRow, startCol);


% text wrapping
% -------------
if ~isempty(h)

    % we need to do some wrapping!

    % 1. assume the text is monospaced:
    % 2. get the longest line:
    lineLen = cellfun(@length, infotext);
    [maxLines, maxLenInd] = max(lineLen);

    % 3. wrap the longest line
    testwrap = textwrap(h, infotext(maxLenInd));
    % 4. get the length of the longest line of wrapped text
    wrapLen = max(cellfun(@length, testwrap));

    % 5. check which original text lines are longer than that
    tooLong = lineLen > wrapLen;

    if any(tooLong)

        % 6. check which are too long
        % whichTooLong = find(tooLong);

        % 7. see by how too long
        tooLongBy = lineLen(tooLong) - wrapLen;

        % 8. how many second column characters fit
        secColChar = wrapLen - startCol; % this MUST be positive!

        % CHANGE, TEMPORARY; currently - give error, FUTURE - resize window etc.
        if secColChar < 5
            error('Second column is shorter than 5 characters, this is too short :(');
        end

        % 9. see how many new rows:
        newLines = ceil(tooLongBy / secColChar);

        % 10. allocate new cell matrix
        newtext = cell(length(lineLen) + sum(newLines), 1);

        tracker = 1;
        % now, fill it up!
        for l = 1:length(lineLen)
            if ~tooLong(l)
                % just add the line
                newtext{tracker} = infotext{l};
                tracker = tracker + 1;
            else
                % add first line (trimmed)
                newtext{tracker} = infotext{l}(1:wrapLen);
                tracker = tracker + 1;

                % get the rest of the text 
                % wrapped the way we prefer
                textfit = wrapThisText(infotext{l}(wrapLen+1:end), ...
                    secColChar, startCol);
                
                %
                len = length(textfit);
                newtext(tracker : tracker+len-1) = textfit;
                tracker = tracker + len;
            end
        end
        infotext = newtext;
    end
end

function [infotext, currentRow] = addtotext(infotext, addtx, ...
    currentRow, startCol)
    
    infotext{currentRow} = [infotext{currentRow}, addtx{1}];
    txlen = length(addtx);
    
    if txlen > 1
       % test addtx size (should be N by 1)
       if size(addtx,2) > size(addtx,1)
           addtx = addtx';
       end
        
        % TEST how faster cellfun is:
        for i = 2:txlen
            addtx{i} = [blanks(startCol), addtx{i}];
        end
        
        infotext = [infotext(1:currentRow);...
            addtx(2:end); infotext(currentRow+1:end)];
        currentRow = currentRow + txlen - 1;
        
    end


function tx = wrapThisText(text, toLen, front)

    textLen = length(text);
    div = textLen / toLen;
    nLines = ceil(div);
    
    % CHECK - this SHOULD be integer but sometimes is not
    addblanks = round((nLines - div)* toLen);
    tx = reshape([text, blanks(addblanks)], [toLen, nLines])';
    tx = [reshape(blanks(nLines * front),...
        [nLines, front]), tx];
    tx = mat2cell(tx, ones(nLines, 1), size(tx,2));