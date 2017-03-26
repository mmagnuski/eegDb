function hasica = db_hasica(db)

% check which database entries have ICA weights present
% returns a boolean vector where true means that given
% db entry has ICA, and false means it doesn't

hasica = false(length(db), 1);
for r = 1:length(db)
    hasica(r) = ~isempty(db(r).ICA.icaweights);
end