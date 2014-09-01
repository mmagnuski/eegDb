function tx = addblanks_samelength(tx, mindist)

% add blanks to equalize length of strings in tx cell matrix

if ~exist('mindist', 'var')
    mindist = 0;
end

len = cellfun(@length, tx);
maxlen = max(len);

addlen = maxlen - len;

for i = 1:length(tx)
    tx{i} = [tx{i}, blanks(addlen(i) + mindist)];
end