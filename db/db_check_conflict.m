function conflict_matrix = db_check_conflict(db, rs, field)
% db_check_conflict allows to check conflicts for given
% records of the database when changing a given field
%
% The output is a processing_step by records
% conflict_matrix that describes how your 
% proposed change influences (conflicts) other
% processing steps that are defined in the da-
% tabase.
% 
% conflict_matrix values:
%  0 - no conflict possible
%  1 - no conflict
% -1 - simple conflict - you are changing this step
% -2 - dependency conflict - you would have to 
% 	   change (recompute) this step too
%  2 - leave vs remove (you have to decide whether
%      to leave this step unaffected, recompute this
%      but try to adapt it to previous state of this
%      step or recompute and remove previous state
%      of this step)
%  3 - depends on choice in 2 - leave, compare, remove
%  4 - compare vs remove
ch = [-1,  0,  0,  0,  0,  0;...  % filter
	  -2, -1,  0,  0,  0,  0;...  % cleanline
	   1,  1, -1,  0,  0,  0;...  % epoch
	   1,  1,  4, -1,  0,  0;...  % pre reject
	   1,  1,  4,  4, -1,  0;...  % post reject
	   2,  2,  2,  2,  2, -1;...  % ICA
	   3,  3,  3,  3,  3,  2 ];   % remove components

% at the present one cannot change pre-rejection without
% changing epoching - this will change as pre-rejection
% could be (the act of) not including epochs with eye 
% act within some time from the stim pres or with RT 
% shorter or longer than some threshold (or some other
% field-comparison)

all_flds = {'filter', 'cleanline', 'epoch', ...
	'pre reject', 'post reject', 'ICA', ...
	'ICA remove',...
	};

% check chosen change
f = find(strcmp(fld, all_flds));

if isempty(f)
	% ADD - description of allowed operations
	error('change operation not recognized!');
end

if ~exist('rs', 'var')
    rs = 1:length(db);
end

% first scan records that will be changed
scan = db_scan(db, rs);

ispres = scan > 0;

% relevant row from ch:
ch = ch(:, f);

% multip element-wise with ispres:
prob = repmat(ch, [1, size(ispres,2)]) .* ispres;