function [f] = db_gui_choose_chan(chan_names, chan_sel, varargin)

% NOHELPINFO

color = [0.85 0.90 0.95];
if nargin > 2
    color = varargin{1};
end

% ==GUI== 
% liczenie kana³ów
how_many_chans = length(chan_names);


% wysok = 500;
% if how_many_chans < 9
%     wysok = 400;
% end

max_wysok = 500;
min_szer = 300;

% checkbox positions (fitting)
height = 25; dist = 25;

% ile siê w maksie zmieœci:
a = floor((max_wysok-(dist+50))/(height + dist));

if how_many_chans < a
    wysok = max_wysok;
    szer = min_szer;
else
    wysok = a * (height + dist) + (dist+50);
    kolumny = ceil(how_many_chans/a);
    szer = 50 + 100*kolumny + 50;   
end

Ycoord = (a-1):-1:0; 
Ycoord = (Ycoord.*(height+dist)) + dist;


% CHANGE: szerokoœæ/wysokoœæ zale¿na od iloœci box'ów; dlugosc etykiet
% zalezna od dlugosci nazw (czyli tak aby sie wszystko miescilo)
f = figure('Visible','off','Position',...
    [500,500,szer,wysok], 'Color', color);

chan_handles = cell(1,how_many_chans);

% how many

% Tworzy komponenty (guziki itp)

uicontrol('Style','text','String',' Choose channels  ',...
    'FontSize', 12, 'Position',[120,wysok-50,170,35]);
b = 1;
while b <= how_many_chans
    c = 1;
    while c <= a && b <= how_many_chans
        % create checkbox and label
        l = 50 + 100*(ceil(b/a)-1); h = Ycoord(c);
        if sum(chan_sel == b) > 0
            val = 1;
        else
            val = 0;
        end
        
        chan_handles{b} = uicontrol('Style', 'checkbox', ...
            'Position',[l,h,height+60,height], 'BackgroundColor', color, ...
            'String', chan_names{b}, 'Value', val);
        % wstawia nazwy kanalow
        % chan_name = chan_names(b);
        % eval podobnie jak wyzej
        c = c + 1; b = b + 1;
    end
end

uicontrol('Style','pushbutton','String','Go!',...
    'FontSize', 13, 'Position',[10,wysok - (10 + 50),100,50], ...
    'Callback',@phys_gobutton1_Callback);

% Inicjalizuje GUI
% Normalizacja - aby komponenty zmienialy sie wraz z rozszerzaniem okna
% set([ hgo htext1 ],'Units','normalized');

% for ch = 1:length(chan_handles)
%     set(chan_handles{ch},'Units','normalized');
% end

% Nazwa okna
set(f,'Name','Choose electrodes');
% Centrownie okna
movegui(f,'center');
% Pokazanie okna
set(f,'Visible','on');

uiwait;

function phys_gobutton1_Callback(source,eventdata) %#ok<INUSD>
        chan_mark = zeros(1,how_many_chans);
        
        % zczytuje wartosci czekboksów
        for u = 1:how_many_chans
            Chan_Val = get(chan_handles{u}, 'Value');
            chan_mark(u) = Chan_Val;
        end
        
        mark_positions = find(chan_mark);
        mark_names = chan_names(mark_positions);
        set(f, 'UserData', {mark_positions, mark_names})
        uiresume;
end

end
