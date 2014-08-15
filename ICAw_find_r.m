function r = ICAw_find_r(ICAw, fld, val)

% r = ICAw_find_r(ICAw, fld, val)
% looks for a record that has field 'fld'
% filled with value 'val'.
% Returns all indices that fulfill these
% constaints.

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