% how to establish mapping 
% between two ica matrices
% (the same decompositions,
% different number of compo-
% nents)

winv1 = EEG.icawinv;
winv2 = ICAw(1).icawinv;
outc = corr(winv1, winv2);

% the correlation output gives us
% the correspondence (correlation of
% exactly 1 - the same component)
% nevertheless it is sometimes not
% exactly 1 (numerical imprecision)
% so we look up to the seventh digit
n_dig = 7;
outc = round(outc * 10^n_dig)/10^n_dig;
[~, comp_ind] = find(outc == 1);

% now comp_ind gives the indices of the 
% retained components in the ori-
% ginal order