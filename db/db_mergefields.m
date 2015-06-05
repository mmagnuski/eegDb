function ICAw = db_mergefields(ICAw, fieldfrom, fieldto, force)

% ICAw = db_mergefields(ICAw, fieldfrom, fieldto, force)
% 
% FIXHELPINFO - add examples

if ~exist('force', 'var')
	force = false;
end

% if there is no field to take from
if ~isfield(ICAw, fieldfrom)
	% nothing to merge
	return
end

% if there is no field to place to
if ~isfield(ICAw, fieldto)
	% just copy
	force = true;
end


for r = 1:length(ICAw)

	if isstruct(ICAw(r).(fieldfrom))
		% get subfields:
		subf = fields(ICAw(r).(fieldfrom));

		for f = 1:length(subf)

			if force
				% copy subfields from fieldfrom with possible overwrites
				ICAw(r).(fieldto).(subf{f}) = ICAw(r).(fieldfrom).(subf{f});
			else
				% copy subfields from fieldfrom only if not present in fieldto
				ICAw(r).(fieldto) = merger_movefield(...
					ICAw(r).(fieldfrom), ICAw(r).(fieldto), subf{f});

			end
		end

	end
end

% now - removing old field:
ICAw = rmfield(ICAw, fieldfrom);


function dbto = merger_movefield(dbfrom, dbto, fld)

	
	if ~isfield(dbto, fld)
		% move field without problems if it is not present
		% in bdto - this is equivalent to adding field
		dbto.(fld) = dbfrom.(fld);

	else
		% if this field is not epmty - do not overwrite
		if isempty(dbto.(fld))
			dbto.(fld) = dbfrom.(fld);
		end
	end