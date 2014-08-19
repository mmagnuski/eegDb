function comm_events = comment_search(filename, evnts, varargin)

% NOHELPINFO

%% input checks
if ~exist('evnts', 'var') || isempty(evnts)
    error(['Second argument of the function (',...
        'string events to look for) was not ',...
        'passed or is empty :(']);
end

if ~(ischar(evnts) || iscell(evnts))
    error(['Second argument of the function (',...
        'string events to look for) should be ',...
        'a character string or cell array of ',...
        'string characters']);
end

if ~iscell(evnts)
    evnts = {evnts};
end

%% optional input checks:

% defaults
% ========
allcom = false;

% checks
% ======
if nargin > 2
    % keys to check:
    argchck = {'allcom'};
    % corresponding variables that get value:
    arg = {'allcom'};
    
    for a = 1:length(arg)
        % look for given key
        cmp = strcmp(argchck{a}, varargin);
        
        if sum(cmp) > 0
            % give indices
            cmp = find(cmp);
            
            % apply key <- value
            eval([arg{a}, ' = varargin{',...
                num2str(cmp(1)+1), '};']);
            
            % clear used varargin
            varargin(cmp(1):cmp(1) + 1) = [];
            
            % break if no more varargin
            if isempty(varargin)
                break
            end
        end
    end
end

%% open the m file
% given function filename - locate it on the search path:
fpth = which(filename);

% open connection to the file:
fID = fopen(fpth);

%% get comments
% set up loop
% how to allocate output?
line = 'this is junk';
cm = 0; lnum = 0;

% loop through lines:
while ischar(line)
    lnum = lnum + 1;
    ttel(1) = ftell(fID);
    line = fgetl(fID);
    ttel(2) = ftell(fID);
    comm = strfind(line, '%');
    
    if ~isempty(comm)
        cm = cm + 1;
        comments{cm,1} = lnum;
        comments{cm,2} = ttel;
        comments{cm,3} = line(1 : end);
    end
end

%% look for events in comments:
ifev = false(size(comments, 1), 1);

for ev = 1:length(evnts)
    inds = find(~ifev);
    doesmatch = strfind(comments(inds, 3), evnts{ev});
    doesmatch = ~cellfun(@isempty, doesmatch);
    ifev(inds(doesmatch)) = true;
end


% allcom
if allcom
    % look for discontinuities
    holeind = find(diff(ifev) == -1); %#ok<UNRCH>
    holeind_end = find(diff(ifev) == 1);
    holeind_end(holeind_end < holeind(1)) = [];
    
    if length(holeind) > length(holeind_end)
        holeind_end(end + 1) = length(ifev);
    end
    
    % for each discontinuity
    for d = 1:length(holeind) - 1
        hisln = comments{holeind(d), 1};
        nxtln = cell2mat(comments(holeind(d) + 1 :...
            holeind_end(d), 1));
        cmpln = nxtln == [hisln+1 : hisln+length(nxtln)]'; %#ok<NBRAK>
        ifev(holeind(d) + 1 : holeind_end(d)) = cmpln;
    end   
end

comm_events = comments(ifev,:);
fclose(fID);