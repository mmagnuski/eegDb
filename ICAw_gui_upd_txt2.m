function ICAw_gui_upd_txt2(addinf, h)

% NOHELPINFO

% ICAw_txt = {'filename: '; 'badchans: '; 'rejected comps: ';...
%     'comments: '};
ICAw_txt2 = {'all ifrej comps num: '; 'current comp: '; 'comps left: ';...
    'comps removed: '; 'comps spared: '};

flds = fields(addinf);

for f = 1:length(flds)
    ICAw_txt2{f} = [ICAw_txt2{f}, num2str(addinf.(flds{f}))];
end

set(h.text3, 'String', ICAw_txt2);

