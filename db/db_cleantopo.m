function ICAw = db_cleantopo(ICAw)

% ICAW_CLEANTOPO removes cached topoplot images
% from ICAw base thus significantly reducing size
% of the database.
%
% ICAw = db_cleantopo(ICAw)
%
% see also: topo_cache, rmfield, db_copybase

for r = 1:length(ICAw)
    if femp(ICAw(r).ICA, 'topo')
        ICAw(r).ICA = rmfield(ICAw(r).ICA, 'topo');
    end
end