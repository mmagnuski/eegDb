function [answer, ans_adr] = ICAw_checkbase_present(ICAbase, filename, varargin)

% the function ICAw_checkbase_present
% checks whether certain fields are
% present in the databse and nonempty
% Only structure cells that correspond
% to particular filename are checked
% 
% [answer, ans_adr] = ICAw_checkbase_present(ICAbase, filename, varargin)
% INPUT:
% ==obligatory==
% ICAbase     -       database(structure)
% filename    -       name of the file
% ==optional==
% varargin    -       a cell matrix of field names to check
%
% OUTPUT:
% answer      -       boolean matrix (corresponding to checked
%                     fields - states whether they are empty or
%                     not)
%                     
% ans_adr = 

if nargin>2
    fields_to_check = varargin{1};
else
    fields_to_check = {'filter', 'winlen', 'removed', 'icaweights'};
end
fielen = length(fields_to_check);
answer = false;

% looking for filename
if ~isfield(ICAbase, 'filename');
    disp('Field ''filename'' in not present the database :(');
    ans_adr = NaN;
    return
end

filn = find(strcmp(filename, {ICAbase.filename}));

if isempty(filn)
    disp('There is no such file in the database');
    ans_adr = [];
    return
end

ans_adr = filn;
fillen = length(filn);
answer = false(fielen, fillen);


for f = 1:length(fields_to_check)
    if isfield(ICAbase, fields_to_check{f})
        for s = 1:fillen
            i = filn(s);
            answer(f,s) = ~isempty(ICAbase(i).(fields_to_check{f}));
        end
    end
end