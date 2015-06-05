function ICAw = db_pushfields(ICAw, flds, fieldto, asflds)

% NOHELPINFO

if ~exist('asflds', 'var')
	asflds = flds;
end

hasFields = isfield(ICAw, flds);

if ~isfield(ICAw, fieldto)
    ICAw(1).(fieldto) = [];
end

if any(hasFields)
    flds = flds(hasFields);
    asflds = asflds(hasFields);

    for r = 1:length(ICAw)
        for f = 1:length(flds)
            % if moved field not empty and field moved to not present or empty
            if ~isempty(ICAw(r).(flds{f})) && ~femp(ICAw(r).(fieldto), (asflds{f}))
                ICAw(r).(fieldto).(asflds{f}) = ICAw(r).(flds{f});
            end
        end
    end
    
    % remove fields
    ICAw = rmfield(ICAw, flds(hasFields));

end