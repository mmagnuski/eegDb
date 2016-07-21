function [ind, val] = regexpWhere(cellArray, regularExpression, match)

% REGEXPWHERE gives back indices of cells in cell array
% where strings fulfill a regular expression (the ex-
% pression is checked once for each string)
%
% ind = regexpWhere(cellArray, regularExpression)
%
% REGEXPWHERE can also give back string matches
% is used as follows:
%
% ind = regexpWhere(cellArray, regularExpression, true)
%
% see also: regexp

% Copyright 2014 Miko³aj Magnuski (mmagnuski@swps.edu.pl)

if ~exist('match', 'var')
    match = false;
end

% check for empty cells of cellArray and fill with ''
empt = cellfun(@isempty, cellArray);
cellArray(empt) = '';

if ~match
    ind = find(...
        ~cellfun(@isempty, ...
        regexp(cellArray, regularExpression, 'once')...
        )...
        );
    val = [];
else
    tmp = regexp(cellArray, regularExpression, 'once', 'match');
    ind = find(~cellfun(@isempty, tmp));
    val = tmp(ind);
end