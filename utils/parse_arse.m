function opt = parse_arse(varin, varargin)

% currently - a simple input parser
% 
% opt = parse_arse(varin, opt);
%
% varin is a cell array of alternating keys and
% values.
% 
% see also: InputParser

if nargin > 1 && isstruct(varargin{1})
	opt = varargin{1};
	varin = struct1d(varin{:});
else
	opt = struct1d(varin{:});
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
