% how to spot one elec comps automatically:
r = 3;
tags = ICAw_search_by_tag(ICAw, r);
findtag = strcmp('[one elec]', tags(:,1));
ICs = tags{findtag, 2};

% plot histograms:
icaw = ICAw(r).icaweights * ICAw(r).icasphere; % weights*sphere

for c = 1:length(ICs)
    comp_w = icaw(ICs(c),:);
    figure;
    subplot(1,2,1);
    hist(comp_w);
    subplot(1,2,2);
    bar(comp_w);
end

% all hist:
% plot histograms:

for c = 1:length(icaw)
    comp_w = icaw(c,:);
    figure;
    subplot(1,2,1);
    hist(comp_w);
    subplot(1,2,2);
    bar(comp_w);
end

% based on diagrams:
% ? - 4, 60, 46?, 40?
% 59 (2el?), 55(2el?), 42, 17
% ! - 53(52?), 44, 41
r = 2;
ICs = [44];
icaw = ICAw(r).icaweights * ICAw(r).icasphere; % weights*sphere

for c = 1:length(ICs)
    comp_w = icaw(ICs(c),:);
    figure;
    subplot(1,2,1);
    hist(comp_w);
    subplot(1,2,2);
    bar(comp_w);
end

% above 4 SD & one such elec --> one elec comp!
zsc = zscore(icaw2, 1, 2);
% figure; plot(zsc(44,:));
outl = zsc >= 4;
onel = find(sum(outl, 2) == 1);

% out of proposed onels take only those where
% the strong weight is at least 3 times stronger
% than the rest:
single_el = false(size(onel));
for o = 1:length(onel)
    el = find(zsc(onel(o),:) >= 4);
    val = zsc(onel(o),el);
    fprintf('Comp: %d', onel(o));
    fprintf('Elec number: %d\n', el);
    fprintf('Elec zscore: %.2f\n', val);
    
    % divided by other el
    vals = zsc(onel(o),:);
    divs = abs(val ./ vals);
    divs(el) = [];
    
    tm3 = divs>=3.5;
    sm = sum(tm3);
    
    fprintf('weights 3 less than the main: %d out of %d\n', sm, length(divs));
    
    if sm == length(divs)
        single_el(o) = true;
    end
    
    % 
end