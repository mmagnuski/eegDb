function outlist = ICAw_getrej(ICAw, r, varargin)

% rejlist = ICAw_getrej(ICAw, r)
%
% returns a list of markings that are present for a given file
% rejlist.name - displayed name of the marking
% rejlist.color - color of the marking
% rejlist.value - value of the marking (what is being marked)

% CHANGE
% [ ] change name from ICAw_getrej to ICAw_getmarks
% [ ] clear up ICAw_getrej
% [ ] profile and change/rewrite
% [X] ICAw_checkfields takes up about 80% of execution time
%     - should we resign from ICAw_checkfields?
%     it shouldn't be called so often...

%% CHANGE!! - this should probably only select nonempty
%             if this is asked for, in new structure
%             getting marks is as easy as:
%             ICAw(r).marks
%             
%             for mark names:
%             {ICAw(r).marks.name}

return_nonempt = false;
if nargin > 2
    isit = strcmp('nonempt', varargin);
    if ~isempty(isit)
        return_nonempt = true;
    end
    clear isit
end

% so simple now:
outlist.name = {ICAw(r).marks.name};
outlist.color = {ICAw(r).marks.color};
outlist.value = {ICAw(r).marks.value};

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
        


