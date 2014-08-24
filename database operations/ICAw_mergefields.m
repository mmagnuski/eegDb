function ICAw = ICAw_mergefields(ICAw, fieldfrom, fieldto)

% ICAw = ICAw_mergefields(ICAw, fieldfrom, fieldto)
% 
% FIXHELPINFO - add examples

% if there is no field to take from
if ~isfield(ICAw, fieldfrom)
	% nothing to merge
	return
end

% if there is no field to place to
if ~isfield(ICAw, fieldto)
	% just copy
	performChecks = false;
end


for r = 1:length(ICAw)
	% get subfields:
	subf = fields(ICAw(r).(fieldfrom));

	for f = 1:length(subf)

		if ~performChecks
			ICAw(r).(fieldto).(subf{f}) = ICAw(r).(fieldfrom).(subf{f});
		else
			% CHANGE
			% ADD
		end
	end
end


flds = fieldnames(ICAw);
fldpos = find(strcmp(fieldfrom, flds));

if isempty(fldpos)
    warning('no such field present in ICAw base');
    return
end

% otherwise - field is present
for rec = 1:length(ICAw)
    ICAw(rec).(fieldto) = ICAw(rec).(fieldfrom);
end

% now - removing old field:
ICAw = rmfield(ICAw, fieldfrom);

% orderfields
if ifsort
	flds{fldpos} = fieldto;
	ICAw = ICAw_sorter(ICAw, flds);
end
