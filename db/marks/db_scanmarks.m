function rejt = db_scanmarks(db)

% NOHELPINFO

% TODOs:
% [X] this is not a particulary fast way to check this
%     check other methods?
% [ ] this kind of check should be performed only at
%     the beginning of winreject...

% get for r = 1
% only name, color (ind?) should be kept...

rejName = cell(100,1);
rejColor = cell(100,1);

newName = {db(1).marks.name};
newColor = {db(1).marks.color};

track = length(newName);
rejName(1:track) = newName;
rejColor(1:track) = newColor;


for r = 2:length(db)
    newName = {db(r).marks.name};
    newColor = {db(r).marks.color};
    
    % if new name
    % ADD maybe - check for name - color consistency
    new = cellfun(@(x) ~any(strcmp(x, rejName)), newName);
    
    if any(new)

        % select only new
        newName = newName(new);
        newColor = newColor(new);

        % check length, move track to next row
        addlen = length(newName) - 1;
        track = track + 1;

        % add new names
        rejName(track:track+addlen) = newName;
        rejColor(track:track+addlen) = newColor;

        % adjust track by length
        track = track + addlen;
    end

end

% trim cell arrays:
rejName(track + 1 : end) = [];
rejColor(track + 1 : end) = [];

rejt.name = rejName;
rejt.color = rejColor;
