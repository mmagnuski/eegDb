function ICAw = db_applyrej(ICAw, rs, varargin)

% NOHELPINFO
% function used to apply rejections to ICAw database

% written by M Magnuski, imponderabilion@gmail.com

byname = {};
checksel = false;
clear_rej = false;

if nargin > 2
    inp = {'byname', 'checksel', 'clear'};
    tovar = {'byname', 'checksel', 'clear_rej'};
    
    for i = 1:length(inp)
        ind = find(strcmp(inp{i}, varargin));
        if ~isempty(ind)
            eval([tovar{i}, ' = varargin{', num2str(ind + 1), '};']);
        end
    end
end

% checksel is a mode where rejections are only scanned
% CHANGE - this does not seem to be needed anylonger
if checksel
    outsel.fields = flds(:); %#ok<UNRCH>
    outsel.fieldpres = false(length(outsel.fields), 1);
    outsel.subfields = cell(length(outsel.fields), 1);
end

for r = rs
    
    % clearing rejections is simple:
    if clear_rej
        ICAw(r).reject.post = []; %#ok<UNRCH>
        ICAw(r).reject.all = ICAw(r).reject.pre;
        continue
    end
    
    % no inds
    ind = [];
    
    % checking fields
    % fldch = db_checkfields(ICAw, r, flds,...
    %     'subfields', true, 'subignore', ignore);
    
    if checksel
        % just scouting
        % outsel = update_outsel(outsel, fldch, ICAw, r); %#ok<UNRCH>
    else
        %% applying rejections
        %fldch = simplify_fldch(fldch);
        
        if ~isempty(byname)
            mrknames = {ICAw(r).marks.name};
            marknums = cellfun(@(x) strcmp(x, mrknames), byname, 'uni', false);
            marknums = reshape(cell2mat(marknums), [length(byname), length(mrknames)]);
            marknums = sum(marknums, 1) > 0;
            
            mrkvals = {ICAw(r).marks(marknums).value};
            clear marknums mrknames
            
            % check mark length:
            mrklen = cellfun(@length, mrkvals);
            if sum(diff(mrklen)) > 0
                error('Mark value lengths are not equal! :(');
            end
            
            % CHANGE later - if we are sure they are column vectors
            %                then find(sum(reshape(cellfun), 1))
            for m = 1:length(mrkvals)
                ind = unique([ind; find(mrkvals{m})]);
            end
            
            % fill 'removed' field :)
            ICAw = db_addrej(ICAw, r, ind);
        end
        
    end
    
    if checksel
        outsel.fields = outsel.fields(outsel.fieldpres); %#ok<UNRCH>
        outsel.subfields = outsel.subfields(outsel.fieldpres);
        outsel = rmfield(outsel, 'fieldpres');
        
        ICAw = outsel;
    end
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

% CHANGE - maybe a new fun for joining rejections?
% function for joining inds
% function ind = joinrej(ind, fld)

% uni = unique(fld);
% uni = uni(:);
% logi = islogical(fld) || isequal(uni, [0; 1]) ...
%     || isequal(uni, 0);

% if logi
%     fld = find(fld);
% end

% if isnumeric(fld)
%     ind = union(ind, fld);
% else
%     return
% end
