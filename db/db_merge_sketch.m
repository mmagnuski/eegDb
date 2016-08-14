function db = db_merge_sketch(db1, db2)

% compare and merge two db by ICA:
db = db1;
for r = 1:length(db1)
    isdiff = ~isequal(db1(r).ICA, db2(r).ICA);
    if isempty(db1(r).ICA.icaweights)
        db(r).ICA = db2(r).ICA;
    end
end