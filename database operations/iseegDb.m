function is = iseegDb(s, rs)

% ISEEGDB checks whether input is eegDb structure
% 
% is = ISEEGDB(s)
%
% input:
% s  - structure
%
% output:
% is - boolean; whether passed input is an eegDb structure
%
% see also: sistruct, fields

if ~isstruct(s)
	is = false;
	return
end

% check if obligatory fields are present
obligatory_fields = {'filename', 'filepath', 'datainfo', 'filter',...
					 'epoch', 'marks', 'reject', 'ICA'};

flds = fields(s);
hasfld = cellfun(@(x) any(strcmp(x, flds)), obligatory_fields);

if ~all(hasfld)
	is = false;
	return
end

if ~exist('rs', 'var')
    rs = 1:length(s);
end
ischarorcell = @(x) ischar(x) || iscell(x);
isnumorstruct = @(x) isnumeric(x) || isstruct(x);

% check fields content
check_fields = {ischarorcell, ischarorcell, @isstruct, isnumorstruct,...
				@isstruct, @isstruct, @isstruct, @isstruct};

for r = rs
	for f = 1:length(obligatory_fields)
		is = feval(check_fields{f}, s(r).(obligatory_fields{f}));
		if ~is
			return
		end
	end
end