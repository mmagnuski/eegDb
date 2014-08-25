function ICAw = ICAw_pushfields(ICAw, flds, fieldto, asflds)

% NOHELPINFO

if ~exist('asflds', 'var')
	asflds = flds;
end

hasFields = isfield(ICAw, flds);

if ~isfield(ICAw, fieldto)
    ICAw(1).ICA = [];
end

if any(hasFields)
    flds = flds(hasFields);
    asflds = asflds(hasFields);

for r = 1:length(ICAw)
    for f = 1:length(flds)
        % if moved field not empty and field moved to not present or empty
        if ~empty(ICAw.(flds{f})) && ~femp(ICAw.(fieldto), (asflds{f}))
            ICAw.(fieldto).(asflds{f}) = ICAw.(flds{f});
        end
    end
end

% remove fields
ICAw = rmfield(ICAw, flds(hasFields));

end