function file_list = getfiles(PTH, whatfiles, regex)

% file_list = getfiles(PTH, whatfiles, regex)
%
% get a list of files that:
% - reside in PTH directory (absolute or relative path) 
% - fullfil requirements specified in whatfiles
% by default whatfiles requirements are understood
% as a system-level string like '*.set'.
%
% file_list is returned as a cell matrix (N-files by one)
% PTH       is a string specifying full or relative path
%              of a directory
% whatfiles is a string defining what files to look for,
%              by default a a system-level string like 
% 			   '*.set' but can be interpreted as a regular 
% 			   expression - see the next parameter - 'regex'
% regex     is an optional argument that controls whether
%              whatfiles is understood as a regular expression
%			   The default value of regex is false.
%
% EXAMPLES:
% FIXHELPINFO
% Using regex parameter:
%              (to look for all set files with:
%				regular expression       --> '.\.set'
%				not a regular expression --> '*.set')

% check if regex exists
if ~exist('regex', 'var')
	regex = false;
end
if ~exist('whatfiles', 'var')
	whatfiles = '';
	regex = false;
end


if ~regex
	% if it is not a regular expression join and pass to dir
	fls = dir( fullfile(PTH, whatfiles) );
	% get all files
	file_list = {fls(~[fls.isdir]).name}';
else
	% it is a regular expression, first list all in PTH
	fls = dir( PTH );
	% then get all files
	fls = fls(~[fls.isdir]);
	fls = {fls.name};
	% evaluate which files fulfill regular expression
	ind = ~cellfun( @isempty, regexp(fls, whatfiles, 'once') );
	file_list = fls(ind)';
end

