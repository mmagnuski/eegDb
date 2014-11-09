function c = struct_unroll(s)

% STRUCT_UNROLL unrolls singleton structure into a cell array
%
% function c = struct_unroll(s)
%
% input:
% s - singleton structure
%
% output:
% c - cell array
%
% see also: struct2cell

if ~isstruct(s)
	error('Structure required as input!');
end

if ~(length(s) == 1)
	error('Structure must be of length one.');
end

flds = fields(s);
c = cell(1,length(flds)*2);
c(1:2:end) = flds;
c(2:2:end) = struct2cell(s);
