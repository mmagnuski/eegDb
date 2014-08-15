
flds{1} = fields(ICAw(6).versions.rej);
flds{2} = fields(ICAw(6).versions.ver01);

fnotpr12 = setdiff(flds{1}, flds{2});
fnotpr21 = setdiff(flds{2}, flds{1});

if ~isempty(fnotpr12) || ~isempty(fnotpr12)
    
    disp('Fields in flds1 and not in flds2: ');
    disp(fnotpr12);
    
    disp('Fields in flds2 and not in flds1: ');
    disp(fnotpr21);
end

for f = 1:length(flds{1})
    a = isequal(ICAw(6).versions.rej.(flds{1}{f}),...
        ICAw(6).versions.ver01.(flds{1}{f}));
    if ~a
        disp(flds{1}{f});
    end
end

