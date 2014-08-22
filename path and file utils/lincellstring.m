function str = lincellstring(cellstr)

% LINCELLSTRING transforms cell of strings into quoted string of elements
%
% str = lincellstring(cellstr)
%
% transforms cell of strings `cellstr` into a string `str`
% where elements of `cellstr` are displayed as quoted and
% separated with commas
%
% EXAMPLE:
% >> cstr = {'somthing', 'rabarbar', 'rimba'};
% >> str = lincellstring(cstr);
%    
% str =
% 
% 'somthing', 'rabarbar', 'rimba'
%    
% see also: cellstr, cellfun
% 
% Copyright 2014 Mikolaj Magnuski

str = cellfun(@(x) ['''', x, ''', '], cellstr, 'uni', false);
str = [str{:}];
str = str(1:end-2);

    