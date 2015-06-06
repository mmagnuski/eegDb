function outlist = db_getrej(db, r, varargin)

% rejlist = db_getrej(db, r)
%
% returns a list of markings that are present for a given file
% rejlist.name - displayed name of the marking
% rejlist.color - color of the marking
% rejlist.value - value of the marking (what is being marked)

% CHANGE
% [ ] change name from db_getrej to db_getmarks
% [ ] clear up db_getrej
% [ ] profile and change/rewrite
% [X] db_checkfields takes up about 80% of execution time
%     - should we resign from db_checkfields?
%     it shouldn't be called so often...

%% CHANGE!! - this should probably only select nonempty
%             if this is asked for, in new structure
%             getting marks is as easy as:
%             db(r).marks
%             
%             for mark names:
%             {db(r).marks.name}

return_nonempt = false;
if nargin > 2
    isit = strcmp('nonempt', varargin);
    if ~isempty(isit)
        return_nonempt = true;
    end
    clear isit
end

% so simple now:
outlist.name = {db(r).marks.name};
outlist.color = {db(r).marks.color};
outlist.value = {db(r).marks.value};

if return_nonempt

    kill = cellfun(@(x) isempty(x) || sum(x) == 0, outlist.value);
    
    flds = fields(outlist);

    for f = 1:length(flds)
        outlist.(flds{f})(kill) = [];
    end

    % outlist.name(kill) = [];
    % outlist.color(kill,:) = [];
    % outlist.value(kill) = [];
end
        


