function check_dipfit_status

ld = load(['D:\Dropbox\Dropbox\CURRENT PROJECTS\CUTTING\',...
    'DIPfit filled\ICAw_dipfit.mat']);
ICAw = ld.ICAw;
clear ld

dip = {ICAw.dipfit};
dippres = ~cellfun(@isempty, dip);
plot(dippres, 'LineWidth', 2.5, 'Color', [0.53, 0.87, 0.23]);
set(gca,  'YLim', [-1, 2]);
clear dip

% put in front
figh = get(gca, 'Parent');
figure(figh);

% display
fprintf('  %d  out of  %d  DIPfitted\n', length(find(dippres)), ...
    length(dippres));

% throw ICAw to base workspace
assignin('base', 'ICAw', ICAw);