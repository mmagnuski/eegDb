function ICAw_gui_upd_txt(ICAw, r, h)

ICAw_txt = {'filename: '; 'badchans: '; 'rejected comps: ';...
    'comments: '};

flds = {'filename', 'badchan', 'ica_remove', 'notes'};

for f = 1:length(flds)
    cont = ICAw(r).(flds{f});
    if isnumeric(cont)
        cont = num2str(cont);
    end
    
    ICAw_txt{f} = [ICAw_txt{f}, cont];
end

set(h.text1, 'String', ICAw_txt);

