function ICAw = ICAw_applyrej(ICAw, rs, varargin)

% ADD help text
% function used to apply rejections to ICAw database

% written by M Magnuski, imponderabilion@gmail.com

flds = {'autorem', 'userrem'};
subflds = {};
ignore = {'color', 'name'};
checksel = false;
clear_rej = false;

if nargin > 2
    inp = {'checksel', 'fields', 'subfields', 'clear'};
    tovar = {'checksel', 'flds', 'subflds', 'clear_rej'};
    
    for i = 1:length(inp)
        ind = find(strcmp(inp{i}, varargin));
        if ~isempty(ind)
            eval([tovar{i}, ' = varargin{', num2str(ind + 1), '};']);
        end
    end
end

if checksel
    outsel.fields = flds(:); %#ok<UNRCH>
    outsel.fieldpres = false(length(outsel.fields), 1);
    outsel.subfields = cell(length(outsel.fields), 1);
end

for r = rs
    
    % clearing rejections is simple:
    if clear_rej
        ICAw(r).postrej = []; %#ok<UNRCH>
        ICAw(r).removed = ICAw(r).prerej;
        continue
    end
     
    % no inds
    inds = [];
    
    % checking fields
    fldch = ICAw_checkfields(ICAw, r, flds,...
        'subfields', true, 'subignore', ignore);
    
    if checksel
        % just scouting
        outsel = update_outsel(outsel, fldch, ICAw, r); %#ok<UNRCH>
    else
        %% applying rejections
        fldch = simplify_fldch(fldch);
        
        for f = 1:length(fldch.fields)
            if ~isempty(subflds)
                % check subfields
                checkfields = intersect(subflds, ...
                    fldch.subfields{f});
            else
                checkfields = fldch.subfields{f};
            end
            
            % checking theese fields
            for sf = 1:length(checkfields)
                inds = joinrej(inds, ICAw(r)...
                    .(fldch.fields{f}).(checkfields{sf}));
            end
            
        end
        
        % fill 'removed' field :)
        ICAw = ICAw_addrej(ICAw, r, inds);
    end
    
end

if checksel
    outsel.fields = outsel.fields(outsel.fieldpres); %#ok<UNRCH>
    outsel.subfields = outsel.subfields(outsel.fieldpres);
    outsel = rmfield(outsel, 'fieldpres');
    
    ICAw = outsel;
end

% fill scouting structure
% (scouting structure looks for rejection categories
%  present in the data before applying these rejections)
function outsel = update_outsel(outsel, fldch, ICAw, r)

outsel.fieldpres = outsel.fieldpres | fldch.fpres;

for f = 1:length(outsel.fieldpres)
    if outsel.fieldpres(f)
        prop = fldch.subfields{f}(fldch.subfnonempt{f});
        zerokill = false(size(prop));
        
        for sf = 1:length(prop)
            fld = ICAw(r).(outsel.fields{f}).(prop{sf});
            logi = islogical(fld) || sum(fld)==0;
            if logi
                zerokill(sf) = true;
            end
        end
        
        prop(zerokill) = [];
        outsel.subfields{f} = union(outsel.subfields{f}, ...
            prop);
    end
end

% function for joining inds
function ind = joinrej(ind, fld)

uni = unique(fld);
uni = uni(:);
logi = islogical(fld) || isequal(uni, [0; 1]) ...
    || isequal(uni, 0);

if logi
    fld = find(fld);
end

if isnumeric(fld)
    ind = union(ind, fld);
else
    return
end
