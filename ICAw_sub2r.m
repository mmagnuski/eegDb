function sub2r = ICAw_sub2r(ICAw, varargin)

% ICAw_sub2r() retruns cell matrix
% subjects X 2 representing for each
% subject (first column) registries of 
% ICAw where it occurs (second column).
% ICAw_sub2r() can also return just
% the registers of ICAw where a specified 
% subject is present (see Usage 2)
% 
% Usage 1:
% sub2r = ICAw_sub2r(ICAw);
%
% where :
% ICAw  - ICAw structure (as used by ICAw
%         plugin
%
% sub2r - output cell matrix where each row
%         of the first column represents a
%         subject and each row of the second
%         column contains indices of ICAw
%         that contain data corresponding to
%         this subject
% 
% Usage 2:
% sub2r = ICAw_sub2r(ICAw);
%
% where :
% ICAw  - ICAw structure (as used by ICAw
%         plugin
% s     - requested subject ID
%
% sub2r - indices of ICAw that contain data 
%         corresponding to this subject
%
% coded by M. Magnuski, august, 2013

%% defaults
sub = false;

%% input checks
if nargin > 1
    sub = varargin{1};
end

%% the code
flds = {'subject', 'subjectcode'};
fcor = [];
for f = flds
    if isfield(ICAw, f{1})
        fcor = f{1};
        break
    end
end

if ~isempty(fcor)
    allsub = [ICAw.(fcor)];
    
    if sub
        sub2r = find(allsub == sub);
        return
    end
    
    subid = unique([ICAw.(fcor)]);
    
    % allocate cell output:
    sub2r = cell(length(subid), 2);
    
    for s = 1:length(subid)
        sub2r{s,1} = subid(s);
        sub2r{s,2} = find(allsub == subid(s));
    end
end
