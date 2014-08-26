function fnm = str2fieldname(str)

% STR2FIELDNAME formats string into proper field name - special
% characters like '?' or '.' are turned to strings like 
% 'questionmark' and 'dot'
% 
% fnm = STR2FIELDNAME(str)
%
%
% see also: strfind, regexprep

from   = {'?', '\.', ',', ';', '!'};
to     = {'questionmark', 'dot', 'comma', 'colon', 'bang'};
remove = '<>/\{}[]()@#$%^&*';

% replace
for f = 1:length(from)
	str = regexprep(str, from{f}, to{f});
end

% remove
for f = 1:length(remove)
	i = strfind(str, remove(f));

	if ~isempty(i)
		str(i) = [];
	end
end