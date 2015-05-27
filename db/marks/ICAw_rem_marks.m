function ICAw = ICAw_rem_marks(ICAw)

% NOHELPINFO

not = {'color', 'name'};

for r = 1:length(ICAw)
    clr = fields(ICAw(r).userrem);
    clr = setdiff(clr, not);
    for c = 1:length(clr)
        if femp(ICAw(r).userrem, (clr{c}))
            ICAw(r).userrem.(clr{c}) = [];
        end
    end
end