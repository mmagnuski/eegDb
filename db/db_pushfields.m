function db = db_pushfields(db, flds, fieldto, asflds)

% NOHELPINFO

if ~exist('asflds', 'var')
	asflds = flds;
end

hasFields = isfield(db, flds);

if ~isfield(db, fieldto)
    db(1).(fieldto) = [];
end

if any(hasFields)
    flds = flds(hasFields);
    asflds = asflds(hasFields);

    for r = 1:length(db)
        for f = 1:length(flds)
            % if moved field not empty and field moved to not present or empty
            if ~isempty(db(r).(flds{f})) && ~femp(db(r).(fieldto), (asflds{f}))
                db(r).(fieldto).(asflds{f}) = db(r).(flds{f});
            end
        end
    end
    
    % remove fields
    db = rmfield(db, flds(hasFields));

end