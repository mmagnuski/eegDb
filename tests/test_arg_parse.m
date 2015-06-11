% testing parse_arse, setup
varg = {'this', false, 'that', 1:5, ...
    'other_thing', {'a', 1:2}};

% Test 1: simple case
out = parse_arse(varg);

for v = 1:length(varg)/2
    assert(isequal(out.(varg{(v*2)-1}), varg{v*2}));
end