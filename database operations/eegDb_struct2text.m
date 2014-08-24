function infotext = eegDb_struct2text(eegDb)

% EEGDB_STRUCT2TEXT returns a string representation of eegDb contents
%
% infotext = eegDb_struct2text(eegDb)
%
% EXAMPLE:
% >> eegDb_struct2text(eegDb(2));
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
% ICA:       done (took 00:15:08)
%            mutual info: +2.5 z
%            rejected components:
%            13
%            4 brain components
%              (none rejected)
%            5 muscle components
%              (4 rejected)
%    
% see also: eegDb_buildbase

% ADD
% if no 'r' passed it is assumed to be 1:length(eegDb) (?)
% if r > 1 - present a text summary of all chosen entries

% currently we assume eegDb is one chosen entry
if length(eegDb) > 1
    warning('more than one eegDb entry passed, choosing first');
    % choose first
    eegDb = eegDb(1);
end

getfld = {'filename'; 'filter'; 'epoch';...
    'reject'; 'marks'; 'ICA'};

ttl = {'filename:', 'filter:', 'epoch:', ...
    'reject:', 'marks:', 'ICA:'};

infotext = addblanks_samelength(ttl, 2);
startCol = length(infotext{1});



% straight copying:
% -----------------
currentRow = 1;
%style.copy = [1]; %#ok<NBRAK>

for i = currentRow
    ttl{i} = [ttl{i}, eegDb_getfield(eegDb, getfld{i})];
end


% epochs:
% -------
currentRow = 2;
addtx{1} = 'no epoching defined';
[ep, eptp, dtinf] = eegDb_getepoching(eegDb);

if eptp == 1
    addtx{1} = 'cut into consecutive windows';
    % ADD epoch.nwin info (filled after/during epoching)
    % addtx{1} = sprintf('cut into %d consecutive windows', ep.nwin);
    
    addtx{2} = sprintf('of %4.2 seconds long (each)', ep.winlen);
    
    if femp(ep, 'distance')
        addtx{3} = 'preselected based on distance to';
        % ADD 'preselected 230 / 450 (51%) based on distance to'
        
        % formatting distance rules
        % -------------------------
        for i = 1:size(ep.distance, 1)
            evtp = ep.distance{i, 1};
            dist = ep.distance{i, 2};
            
            % format event type
            if isempty(etp); evtp = 'any event'; 
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
    
    addtx{2} = sprintf('%d to %d ms', ep.limits(1), ep.limits(2));
    addtx{3} = 'with respect to:';
    
    % format event types
    evtp = ep.events;
    if ~iscell(evtp); evtp = {evtp}; end
    evtp = lincellstring(evtp);
    
    % add event types to text
    addtx{4} = evtp;
    
end

% add the addtx:
[infotext, currentRow] = addtotext(infotext, addtx, ...
    currentRow, startCol);

% marks:
% ------
currentRow = currentRow + 1;
nmarks = length(eegDb.marks);
addtx = {};
addtx{1}  = 'no marks';

if nmarks > 0
    mrkNums = structfun(@(x) sum(x.value), eegDb.marks);
    
    nonzero = find(mrkNums > 0);
    nonzerN = length(nonzero);
    
    if nonzerN > 0
        
        % show only marks that are used
        % in format:
        % markname
        %     num   (perc%)
        addtx = cell(nonzerN * 3, 1);
        
        for i = 1:nonzerN
            % mark name
            addtx{3 * (i-1) + 1} = eegDb.marks(nonzero(i)).name;
            
            % no marked
            marked = eegDb.marks(nonzero(i)).value;
            markedN = str2num(sum(marked));
            % marked perc
            markedP = sprintf('%3.1f%%', markedN/length(marked) * 100);
            
            addtx{3 * (i-1) + 2} = [markedN, '  (', markedP, ')'];
            addtx{3 * (i-1) + 3} = '';
        end
        
        % delete last between-mark spacing
        addtx(end) = [];
    end
end 

% put addtx into infotext
[infotext, currentRow] = addtotext(infotext, addtx, ...
    currentRow, startCol);

% ---------------
% ADD reject
% ADD ICA
% ---------------

function [infotext, currentRow] = addtotext(infotext, addtx, ...
    currentRow, startCol)
    
    infotext{currentRow} = [infotext{currentRow}, addtx{1}];
    txlen = length(addtx);
    
    if txlen > 1
       
        % TEST how faster cellfun is:
        for i = 2:txlen
            addtx{i} = [blanks(startCol), addtx{i}];
        end
        
        infotext = [infotext(1:currentRow);...
            addtx(2:end)'; infotext(currentRow+1:end)];
        currentRow = currentRow + txlen - 1;
        
    end
end

end


