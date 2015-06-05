function fldch = db_checkfields(ICAw, r, flds, varargin)

% NOHELPINFO
%
% function used to check fields of ICAw (or any other structure)

% CHANGE - establish copyright and license info (everywhere)
% written by Miko³aj Magnuski, imponderabilion@gmail.com

%% defaults
ignore = {};
subf = false;
subignore = {};
simplify = false;

% get fields
if isempty(flds)
    fldch.fields = fields(ICAw(r));
    fldch.fields = fldch.fields(:);
else
    fldch.fields = flds(:);
end

%% check inputs
if nargin > 3
    inp = {'subfields', 'ignore', 'subignore', 'simplify'};
    tovar = {'subf', 'ignore', 'subignore', 'simplify'};
    
    for i = 1:length(inp)
        ind = find(strcmp(inp{i}, varargin));
        if ~isempty(ind)
            % CHANGE - try to avoid eval + num2str
            %          num2str takes a lot of time...
            eval([tovar{i}, ' = varargin{', num2str(ind + 1), '};']);
        end
    end
end

%% last preparations
if subf
    fldch.subfields = {}; %#ok<UNRCH>
    fldch.subfnonempt = {};
end

% set ignore
if ~isempty(ignore)
    kill = false(size(fldch.fields));
    for ig = 1:length(ignore)
        kill = kill | strcmp(ignore{ig}, fldch.fields);
    end
    fldch.fields(kill) = [];
end

fldch.fpres = false(length(fldch.fields),1);
fldch.fnonempt = false(length(fldch.fields),1);
fldch.fsubf = false(length(fldch.fields),1);

if isempty(ICAw) || isempty(ICAw(r))
    return
end


%% main function
for f = 1:length(fldch.fields)
    
    % field present
    if isfield(ICAw(r), fldch.fields{f})
        fldch.fpres(f) = true;
    else
        continue
    end
    
    % field non-empty
    if ~isempty(ICAw(r).(fldch.fields{f}))
        fldch.fnonempt(f) = true;
    else
        continue
    end
    
    % has subfields?
    if isstruct(ICAw(r).(fldch.fields{f}))
        fldch.fsubf(f) = true;
    else
        continue
    end
    
    if subf && fldch.fsubf(f)
        % subfields
        fldch.subfields{f,1} = fields(ICAw(r).(fldch.fields{f}));
        fldch.subfields{f,1} = fldch.subfields{f}(:);
        
        % if we need to ignore fields:
        if ~isempty(subignore)
            kill = false(size(fldch.subfields{f}));
            
            for ig = 1:length(subignore)
                found = find(strcmp(subignore{ig}, fldch.subfields{f}));
                
                if ~isempty(found)
                    kill(found) = true;
                end
            end
            
            fldch.subfields{f}(kill) = [];
        end
        
        fldch.subfnonempt{f,1} = false(length(fldch.subfields{f}), 1);
        
        % if subfields empty
        for sf = 1:length(fldch.subfields{f})
            if ~isempty(ICAw(r).(fldch.fields{f}).(fldch.subfields{f}{sf}))
                fldch.subfnonempt{f,1}(sf,1) = true;
            end
        end
    end
    
end

if simplify
    fldch = simplify_fldch(fldch); %#ok<UNRCH>
end
