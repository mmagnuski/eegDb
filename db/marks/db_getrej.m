function outlist = db_getrej(db, r, varargin)

% rejlist = db_getrej(db, r)
%
% returns a list of markings that are present for a given file
% rejlist.name - displayed name of the marking
% rejlist.color - color of the marking
% rejlist.value - value of the marking (what is being marked)
%
% key-value options:
% nonempt - boolean, if true DB_GETREJ returns only
%           these rejection types that were used in
%           the gven eegDb record 

% CHANGE
% [ ] change name from db_getrej to db_getmarks
% [ ] clear up db_getrej
% [ ] profile and change/rewrite

%% CHANGE!! - this should probably only select nonempty
%             if this is asked for, in new structure
%             getting marks is as easy as:
%             db(r).marks
%             
%             for mark names:
%             {db(r).marks.name}

opt.nonempt = false;
if nargin > 2
    opt = parse_arse(varargin, opt);
end

% so simple now:
outlist.name = {db(r).marks.name};
outlist.color = {db(r).marks.color};
outlist.value = {db(r).marks.value};

if opt.nonempt

    kill = cellfun(@(x) isempty(x) || sum(x) == 0, outlist.value);
    
    flds = fields(outlist);

    for f = 1:length(flds)
        outlist.(flds{f})(kill) = [];
    end

    % outlist.name(kill) = [];
    % outlist.color(kill,:) = [];
    % outlist.value(kill) = [];
end
        


