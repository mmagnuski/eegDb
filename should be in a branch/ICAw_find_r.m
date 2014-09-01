function r = ICAw_find_r(ICAw, fld, val)

% r = ICAw_find_r(ICAw, fld, val)
%
% looks for a record that has field 'fld'
% set to value 'val'.
% Returns all indices that fulfill these
% constaints.

% TODOs
% [ ] PROFILE against cellfun
% [ ] maybe add options to look deeper than one field
%     (ICAw_getfield or sth similar?)

if ~isstruct(ICAw)
    error('The variable passed as ICAw is not a structure!');
end

len = length(ICAw);

r = false(1, len);

% loop through records:
if isfield(ICAw, fld)
    for i = 1:len
        if isequal(ICAw(i).(fld), val)
            r(i) = true;
        end
    end
end

r = find(r);