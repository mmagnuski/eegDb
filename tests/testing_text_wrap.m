% testing text wrap
figure('Units', 'pixels', 'Position', ...
    [25 25 350 350]);
ht = uicontrol('Style', 'text', 'Position',...
    [20 20 160 280]);


[a, b] = textwrap(ht, ...
    {'This is the text I want to fit in'});

set(ht, 'String', a);
