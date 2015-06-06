function db = db_cleantopo(db)

% DB_CLEANTOPO removes cached topoplot images
% from db base thus significantly reducing size
% of the database.
%
% db = db_cleantopo(db)
%
% see also: topo_cache, rmfield, db_copybase

for r = 1:length(db)
    if femp(db(r).ICA, 'topo')
        db(r).ICA = rmfield(db(r).ICA, 'topo');
    end
end