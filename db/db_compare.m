function cmp = db_compare(db1, db2, field)

% compare two eegDb databases with respect to some fieled

if ~exist('field', 'var')
    field = [];
end

if isempty(field)
    for r = 1:length(db1)
        cmp(r) = isequal(db1(r), db2(r));
    end
end