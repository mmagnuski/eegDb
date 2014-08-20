function info = ICAw_scanica(ICAw, r_rng)

% info = ICAw_scanica(ICAw, r_rng)
% Scans the ICAw database for ICA related
% info.
% Returns structure with fields:
% type           - types of component

% CHANGE
% [ ] type to class and class to type
% ADD
% [ ] build HELPINFO
% [ ] deal with new type-subtype pairings

deftypes = {'artifact'; 'brain'; '?'};
defsubtypes{1} = {'none'; 'blink'; 'horiz eye movement';...
    'heart'; 'muscle'; 'neck'};
defsubtypes{2} = {'none'};
defsubtypes{3} = {'none'};

info.type.val = deftypes;
info.type.icaind = cell(length(deftypes), 1);
info.type.r = cell(length(deftypes), 1);

info.subtype.val = [defsubtypes{1}(:);...
    defsubtypes{2}; defsubtypes{3}];
info.subtype.oftype = [1; 1; 1; 1; 1; 1; 2; 3];
info.subtype.icaind = cell(length(info.subtype.val), 1);
info.subtype.r = cell(length(info.subtype.val), 1);


r = r_rng(1);
tps = {ICAw(r).ICA_desc.type};
sbtps = {ICAw(r).ICA_desc.subtype};
% newtps = unique(info.type.val);

% we evaluate each known subtype-type pair:
ev = false(size(ICAw(r).ICA_desc));
newtp = false(size(ICAw(r).ICA_desc));

for stp = 1:length(info.subtype.val)
    compind = find(strcmp(info.subtype.val{stp}, sbtps));
    
    % do sth only if found any such types
    if isempty(compind)
        continue
    end
    
    
    % check whether it is this type
    tp = strcmp(info.type.val{info.subtype.oftype(stp)},...
        tps(compind));
    
    % any new?
    newtp(compind(~tp)) = true;
    
    
    % adding info
    % ===========
    % add type info:
    info.type.icaind{info.subtype.oftype(stp)} = [...
        info.type.icaind{info.subtype.oftype(stp)}; ...
        compind(tp)];
    
    % r info to type
    info.type.r{info.subtype.oftype(stp)} = ...
        [info.type.r{info.subtype.oftype(stp)}; ...
        repmat(r, [length(compind(tp)), 1])];
    
    % add component indices:
    info.subtype.icaind{stp} = [...
        info.subtype.icaind{stp}; compind(tp)];
    
    % add r info:
    info.subtype.r{stp} = [info.subtype.r{stp}; ...
        repmat(r, [length(compind(tp)), 1])];
    
    ev(compind(tp)) = true;
end
