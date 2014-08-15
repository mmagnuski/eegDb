% for rejcompare:

fld = 'usermaybe';
rejcol = reshape(ICAw(2).userrem.color.(fld), [1 1 3]);
modrejc = mean([rejcol, ones(1,1,3)]);
image([rejcol; modrejc]);


% ICAw rej to EEG
% opts - 'overwrite' is the default
%         but user can specify 
%         'overwrite', false

% [ ] do we allow writing into EEGlab fields?
%     not necessarily...
% [ ] do we use name additionally for naming 
%     rejections in a way that escapes limitations
%     of a field name?

% if removal fields in ICAw not specified
% look through 'userrem' and 'autorem'

% check fields
flds = {'userrem'; 'autorem'};
f = ICAw_checkfields(ICAw, r, flds, 'subfields', true,...
    'subignore', {'color'});

% allocate variables
subfN = sum(cellfun(@length, f.subfields));
namesmat = cell(subfN,1);
colormat = zeros(subfN,3);
lastfill = 0;

for fl = 1:length(f.fields)
    % subfields for given field:
    % (we check nonemtpy fields only)
    % (and use them only if their color is defined)
    f.subfields{fl} = f.subfields{fl}(subfnonempt{fl});
    
    % color subfields:
    fcol = ICAw_checkfields(ICAw(r).(f.fields{fl}), 1, , 'subfields', true,...
    'subignore', {'color'});
    
    for subf = 1:length(f.subfields{fl})
        