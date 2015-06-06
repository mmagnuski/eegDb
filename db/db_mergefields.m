function db = db_mergefields(db, fieldfrom, fieldto, force)

% db = db_mergefields(db, fieldfrom, fieldto, force)
% 
% FIXHELPINFO - add examples

if ~exist('force', 'var')
	force = false;
end

% if there is no field to take from
if ~isfield(db, fieldfrom)
	% nothing to merge
	return
end

% if there is no field to place to
if ~isfield(db, fieldto)
	% just copy
	force = true;
end


for r = 1:length(db)

	if isstruct(db(r).(fieldfrom))
		% get subfields:
		subf = fields(db(r).(fieldfrom));

		for f = 1:length(subf)

			if force
				% copy subfields from fieldfrom with possible overwrites
				db(r).(fieldto).(subf{f}) = db(r).(fieldfrom).(subf{f});
			else
				% copy subfields from fieldfrom only if not present in fieldto
				db(r).(fieldto) = merger_movefield(...
					db(r).(fieldfrom), db(r).(fieldto), subf{f});

			end
		end

	end
end

% now - removing old field:
db = rmfield(db, fieldfrom);


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