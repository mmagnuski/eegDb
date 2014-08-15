function outlist = ICAw_getrej(ICAw, r, varargin)

% rejlist = ICAw_getrej(ICAw, r)
% returns a list of markings that are present for a given file
% rejlist.name - displayed name of the marking
% rejlist.color - color of the marking
% rejlist.value - value of the marking (what is being marked)

% CHANGE
% [ ] clear up ICAw_getrej
% [ ] ICAw_checkfields takes up about 80% of execution time
%     - should we resign from ICAw_checkfields?
%     it shouldn't be called so often...

return_nonempt = false;
if nargin > 2
    isit = strcmp('nonempt', varargin);
    if ~isempty(isit)
        return_nonempt = true;
    end
    clear isit
end

sel = ICAw_checkfields(ICAw, r, {'userrem', 'autorem'},...
    'subfields', true, 'subignore', {'color', ...
    'name', 'chans'});

kill = false(size(sel.fields));
% if subfields empty - remove
for f = 1:length(sel.fields)
    if isempty(sel.subfields{f})
        kill(f) = true;
    end
end

sel.fields(kill) = [];
sel.subfields(kill) = [];

% check names of these files
sel.names = [];

for f = 1:length(sel.fields)
    nm = femp(ICAw(r).(sel.fields{f}), 'name');
    
%     if nm
%         nmflds = fields(ICAw(r).(sel.fields{f}).name);
%     else
%         nmflds = [];
%     end
    
    % CHECK = do we need names? 
    if nm
        for subf = 1:length(sel.subfields{f})
            nms = femp(ICAw(r).(sel.fields{f})...
                .name, sel.subfields{f}{subf});
            
            if nms
                sel.names{f}{subf,1} = ICAw(r).(sel.fields{f})...
                    .name.(sel.subfields{f}{subf});
            else
                sel.names{f}{subf,1} = sel.subfields{subf};
            end
        end
    end
end

% create outstruct
outlist.name = [];
outlist.color = [];
outlist.value = [];

counter = 1;
% another deadly loop - getting colors
for f = 1:length(sel.fields)
    col_pres = femp(ICAw(r).(sel.fields{f}), 'color');
    
    for subf = 1:length(sel.subfields{f})
        % get name and value
        outlist.name{counter,1} = sel.names{f}{subf};
        outlist.value{counter,1} = ICAw(r).(sel.fields{f})...
            .(sel.subfields{f}{subf});
        
        % make sure value is horizontal:
        % ADD ? segment check ?
        outlist.value{counter,1} = outlist.value{counter,1}(:)';
        outlist.field{counter,1} = sel.subfields{f}{subf};
        outlist.infield{counter,1} = sel.fields{f};
        
        % next, check colors if color field is present:
        % should generate colors maybe if color not present?
        if col_pres
            % check if current mark has color specified:
            fi = femp(ICAw(r)...
                .(sel.fields{f}).color, sel.subfields{f}{subf});
            
            % if not - random color:
            if fi
                outlist.color(counter,:) = ICAw(r)...
                    .(sel.fields{f}).color...
                    .(sel.subfields{f}{subf});
            else
                outlist.color(counter,:) = rand(1,3);
            end
            clear fi
        else
            % if not - random color:
            outlist.color(counter,:) = rand(1,3);
        end
        
        % next element in outlist
        counter = counter + 1;
    end
end

if return_nonempt
    kill = false(length(outlist.value), 1);
    
    for v = 1:length(outlist.value)
        kill(v) = isempty(outlist.value{v}) || ...
            sum(outlist.value{v}) == 0;
    end
    
    outlist.name(kill) = [];
    outlist.color(kill,:) = [];
    outlist.value(kill) = [];
    outlist.field(kill) = [];
    outlist.infield(kill) = [];
end
        


