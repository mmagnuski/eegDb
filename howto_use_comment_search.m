% how to use comment_search

% if you use some tags of where/what to 
% change in the code, write down these
% tags in a cell format:
mytags = {'ADD', 'CHECK', 'CHANGE', 'TODO',...
    '[  ]', '[ ]', 'CONSIDER', 'FIX'};

% then use comment_search to check a 
% specific function:
tgs = comment_search('maskitsweet.m', tags);

% when you also want all comments following
% a given tag in a continuous way (all comments
% not broken by uncommented line), add this key-value:
tgs = comment_search('maskitsweet.m', ...
    tags, 'allcom', true);

