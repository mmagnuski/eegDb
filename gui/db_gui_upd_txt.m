function db_gui_upd_txt(db, r, h)

% NOHELPINFO

ICAw_txt = {'filename: '; 'badchans: '; 'rejected comps: ';...
    'comments: '};

flds = {'filename', 'badchan', 'ica_remove', 'notes'};

for f = 1:length(flds)
    cont = db(r).(flds{f});
    if isnumeric(cont)
        cont = num2str(cont);
    end
    
    db_txt{f} = [db_txt{f}, cont];
end

set(h.text1, 'String', db_txt);

