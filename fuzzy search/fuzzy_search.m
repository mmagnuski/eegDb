function inds = fuzzy_search(str, match)

strLen = length(str);
inds = cell(strLen, 1);

for i = 1:strLen
    word = str{i};
    ind = zeros(1,length(match)+1);
    fin = true;
    
    for l = 1:length(match)
        val = find(word(ind(l)+1:end) == match(l), 1, 'first');
        if ~isempty(val)
            ind(l+1) = val + ind(l);
        else
            fin = false;
            break
        end
    end
    
    if fin
        inds{i} = ind(2:end);
    end
end