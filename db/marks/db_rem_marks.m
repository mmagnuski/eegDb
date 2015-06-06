function db = db_rem_marks(db)

% NOHELPINFO

not = {'color', 'name'};

for r = 1:length(db)
    clr = fields(db(r).userrem);
    clr = setdiff(clr, not);
    for c = 1:length(clr)
        if femp(db(r).userrem, (clr{c}))
            db(r).userrem.(clr{c}) = [];
        end
    end
end