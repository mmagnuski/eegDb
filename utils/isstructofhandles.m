function is = isstructofhandles(s)

% ISSTRUCTOFHANDLES checks whether input is a 
% structure with handles as field values
%
% is = ISSTRUCTOFHANDLES(s)
%
% input:
% s    - structure
%
% output:
% is   - boolean; whether input is a structure of
%        handles
% 
% see also: structfun


if ~isstruct(s)
	is = false;
	return
end

try
	is = all(structfun(@ishandle, s));
catch err
	% field values are not of length 1
	is = false;
	return
end