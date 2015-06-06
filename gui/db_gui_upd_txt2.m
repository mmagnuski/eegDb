function db_gui_upd_txt2(addinf, h)

% NOHELPINFO

% db_txt = {'filename: '; 'badchans: '; 'rejected comps: ';...
%     'comments: '};
ICAw_txt2 = {'all ifrej comps num: '; 'current comp: '; 'comps left: ';...
    'comps removed: '; 'comps spared: '};

flds = fields(addinf);

for f = 1:length(flds)
    db_txt2{f} = [db_txt2{f}, num2str(addinf.(flds{f}))];
end

set(h.text3, 'String', db_txt2);

