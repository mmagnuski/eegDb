function versions = ICAw_getversions(ICAw, r)

% provides info about versions in cell matrix
% first row: version field; second row: version
% name

% TODOs:
% [ ] ignore empty versions (?)

f = ICAw_checkfields(ICAw, r, {'versions'}, 'subfields', true,...
            'subignore', {'current'});
    fld = f.subfields{1};
    
        main_present = sum(strcmp('main', fld))  > 0;
        
        % ver versions
    verf = regexp(fld, 'ver[0-9]+', 'match', 'once');
    verf = verf(~cellfun(@isempty, verf));
    
    nvers = length(verf) + 1*main_present;
    versions = cell(nvers, 2);
    
    if main_present
        versions{1,1} = 'main';
        versions{1,2} = 'main';
    end
    
    if ~isempty(verf)
    versions((1 + 1*main_present):end,1) = verf; 
    
    for i = (1 + 1*main_present):nvers
        v = i - 1*main_present;
        versions{i, 2} = ICAw(r).versions.(verf{v})...
            .version_name;
    end
    end
    