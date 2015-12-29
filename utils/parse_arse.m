function opt = parse_arse(varin, varargin)

% currently - a simple input parser
% 
% opt = parse_arse(varin, opt);
% opt = parse_arse(varin);
%
% varin - a cell array of alternating keys and
%         values.
% opt   - structure with default options
% 
% see also: InputParser

if nargin > 1 && isstruct(varargin{1})
	opt = varargin{1};
	if iscell(varin)
        if isempty(varin)
            varin = struct();
        elseif ~isstruct(varin{1})
            varin = struct1d(varin{:});
        else
            varin = varin{1};
        end
	end
else
    if ~isstruct(varin)    
        opt = struct1d(varin{:});
    end
	return
end

optflds = fields(opt);
varflds = fields(varin);

for v = 1:length(varflds)
	inopt = strcmp(varflds{v}, optflds);
	if any(inopt)
		opt.(varflds{v}) = varin.(varflds{v});
	end
end
