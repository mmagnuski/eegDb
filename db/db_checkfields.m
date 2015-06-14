function fldch = db_checkfields(db, r, flds, varargin)

% NOHELPINFO
%
% function used to check fields of db (or any other structure)

% CHANGE - establish copyright and license info (everywhere)
% written by Miko³aj Magnuski, imponderabilion@gmail.com

%% defaults
opt.ignore = {};
opt.subfields = false;
opt.subignore = {};
opt.simplify = false;

% get fields
if ~exist('flds', 'var') || isempty(flds)
    fldch.fields = fields(db(r));
    fldch.fields = fldch.fields(:);
else
    fldch.fields = flds(:);
end

%% check inputs
if nargin > 3
    opt = parse_arse(varargin, opt);
end

%% last preparations
if opt.subfields
    fldch.subfields = {}; %#ok<UNRCH>
    fldch.subfnonempt = {};
end

% set opt.ignore
if ~isempty(opt.ignore)
    kill = false(size(fldch.fields));
    for ig = 1:length(opt.ignore)
        kill = kill | strcmp(opt.ignore{ig}, fldch.fields);
    end
    fldch.fields(kill) = [];
end

fldch.fpres = false(length(fldch.fields),1);
fldch.fnonempt = false(length(fldch.fields),1);
fldch.fsubf = false(length(fldch.fields),1);

if isempty(db) || isempty(db(r))
    return
end


%% main function
for f = 1:length(fldch.fields)
    
    % field present
    if isfield(db(r), fldch.fields{f})
        fldch.fpres(f) = true;
    else
        continue
    end
    
    % field non-empty
    if ~isempty(db(r).(fldch.fields{f}))
        fldch.fnonempt(f) = true;
    else
        continue
    end
    
    % has subfields?
    if isstruct(db(r).(fldch.fields{f}))
        fldch.fsubf(f) = true;
    else
        continue
    end
    
    if opt.subfields && fldch.fsubf(f)
        % subfields
        fldch.subfields{f,1} = fields(db(r).(fldch.fields{f}));
        fldch.subfields{f,1} = fldch.subfields{f}(:);
        
        % if we need to ignore fields:
        if ~isempty(opt.subignore)
            kill = false(size(fldch.subfields{f}));
            
            for ig = 1:length(opt.subignore)
                found = find(strcmp(opt.subignore{ig}, fldch.subfields{f}));
                
                if ~isempty(found)
                    kill(found) = true;
                end
            end
            
            fldch.subfields{f}(kill) = [];
        end
        
        fldch.subfnonempt{f,1} = false(length(fldch.subfields{f}), 1);
        
        % if subfields empty
        for sf = 1:length(fldch.subfields{f})
            if ~isempty(db(r).(fldch.fields{f}).(fldch.subfields{f}{sf}))
                fldch.subfnonempt{f,1}(sf,1) = true;
            end
        end
    end
    
end

if opt.simplify
    fldch = simplify_fldch(fldch); %#ok<UNRCH>
end
