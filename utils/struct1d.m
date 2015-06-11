function s = struct1d(varargin)

% creates a structure like with struct()
% but the structure is always singular 
% (1-d of length 1) event if some of the
% value arguements are cell

if ~(mod(nargin, 2) == 0) 
	error('number of inputs must be even.');
end

% ensure that cells are enclosed in cells so that
% struct() comes out 1-d, length 1
is_cell = cellfun(@iscell, varargin);
if any(is_cell)
	varargin(is_cell) = cellfun(@(x) {x}, varargin(is_cell), 'Uni', false);
end

s = struct(varargin{:});