function EEG = onesecepoch(options)

% onsecepoch - funkcja dzieli podany plik EEG na epoki
% o podanej d�ugo�ci (w sekundach, domy�lnie 1s)
% opcjonalnie przed epokowaniem dokonuje filtrowania
% sygna�u (tylko je�eli w opcjach jest pole 'filter').
% wi�cej opcjonalnych parametr�w ni�ej w 'PE�NE OPCJE'
%
% do pookienkowania sygna�u w najprostszej wersji wystarczy:
% options.filename = EEG;   % wrzucamy do pola filename struktur� EEG
% EEG = onesecepoch(options);  % dostajemy pookienkowane EEG
% 
% !! je�eli korzystamy z filtrowania: wymagana !!
% !!  jest wersja eeglaba 12.0100 lub nowsza   !!
% 
% PE�NE OPCJE:
% funkcja przyjmuje jako input strukur� o nast. polach:
% filename - nazwa pliku (albo struktura EEG)
% filepath - �cie�ka dost�pu do pliku (tylko je�eli 'filename'
%            jest nazw� pliku, a nie struktur� EEG)
% filter  -  opcjonalnie: wektor [dolny g�rny] pr�g filtrowania
%            np. options.filter = [1 0]; (filtruje tylko g�rnoprzpustowo)
% winlen  -  opcjonalnie: dlugosc okna do epokowania
% leave   -  opcjonalnie: [true/false] - czy zostawia� w danych
%            pookienkowanych oryginalne eventy, czy te� je wywa-
%            la�.
% eventname- opcjonalnie: [string] jak ma nazywa� si� event epokuj�cy.
% distance - opcjonalnie: maksymalna odleg�o�� okien od podanych event�w
%            (w sekundach). Okna wykraczaj�ce poza podane odleg�o�ci
%            s� automatycznie odrzucane - zostaj� nam okienka odpowiednio
%            bliskie w stosunku do interesuj�cych nas event�w.
%            Wszystkie warunki 'odleg�o�ciowe' traktowane s� roz��cznie
%            (wystarczy spe�nia� chocia� jeden aby nie zosta� wywalonym)
%            np.: options.distance = {'DIN8', [-2, 5]; 'DI32', 2; [], 4};
%            znaczy, �e okno musi by� najdalej 2 sekundy przed eventem
%            'DIN8' lub najdalej 5 sekund po nim LUB w odleg�o�ci dw�ch
%            sekund od eventu 'DI32' (przed lub po) LUB 4 sekundy od 
%            dowolnego innego eventu.
% !! DODA� INFO O U�YWANIU POLA .DISTANCE JAK EVENT_PATTERN_SEARCH !!
% fill    -  opcjonalne: je�eli warto�� to prawda logiczna - dodaje do
%            EEG pola oznaczaj�ce opcje u�yte do okienkowania
%
% ===dodatkowa opcja===
% zamiast nazwy pliku mo�na w miejsce 'filename' wrzuci� sam�
% strkutur� EEG - wtedy wczytywanie pliku zostanie pomini�te
% nie trzeba wtedy te� dodawa� do struktury z opcjami pola
% 'filepath'
%
% ==za�o�enie==
% musz� by� ju� wczytane �cie�ki do eeglaba
% funkcja nie uruchamia sama eeglaba
% wczytuje pojedynczo pliki aby mo�na by�o j�
% �atwo doda� do dowolnej rutyny w ramach
% pipeline_coordinate (patrz: folder coordination
% w dropboxowym 'EEGlab scripts')
%
% coded by M. Magunski, march 2013
% :)


%% defaults:
load_set = true; isdist = false; evname = 'dummy';
winlen = 1; leave_ev = true; fill = false;

%% checks for optional parameters
% opcjonalnie pomijamy wczytywanie
if isfield(options, 'filename') && isstruct(options.filename) && ...
        isfield(options.filename, 'data') && isfield(options.filename, 'srate')
    load_set = false;
end

% sprawdzamy czy podana zosta�a d�ugo�� okna:
if isfield(options, 'winlen') && ~isempty(options.winlen) 
    winlen = options.winlen;
end

% sprawdzamy czy podana preferencja co do zostawiania event�w:
if isfield(options, 'leave') && ~isempty(options.leave) 
    leave_ev = options.leave;
end

% sprawdzamy czy i jak podany jest dystans do event�w:
if isfield(options, 'distance') && ~isempty(options.distance) 
    isdist = true;
    leave_ev = true;
end

% checking fill
if isfield(options, 'fill') && ~isempty(options.fill) 
    fill = options.fill;
end

% checking eventname
if isfield(options, 'eventname') && ~isempty(options.eventname) 
    evname = options.eventname;
end


%% ~~WELCOME TO THE CODE~~

%% loading (+filtering)
% getting EEG structure
if load_set
    % wczytujemy plik
    EEG = pop_loadset('filepath', options.filepath, 'filename',...
        options.filename);
else
    EEG = options.filename;
    options.filename = [];
end

% optional filtering
if isfield(options, 'filter') && ~isempty(options.filter)
    EEG = pop_eegfiltnew(EEG, options.filter(1), options.filter(2));
end

%% event checks
% opcja zachowania oryginalnych event�w 
% (aby je widzie� gdy r�cznie odrzuca si� okienka
% - czasem b�dziemy preferowa� aktywno�� m�zgu 
% podczas zadania a nie w innym czasie pod k�tem ICA

% sprawdzamy ile wynosi jedna sekunda:
onesec = EEG.srate;
window = round(onesec*winlen);

% patrzymy ile trzeba wygenerowa� 
% 'sztucznych' event�w:
ile_ev = floor(size(EEG.data,2)/window);

if ~leave_ev
% wypierdzielamy stare eventy
EEG.event = []; EEG.urevent = [];
evs = [1 ile_ev]; urs = [1 ile_ev];

else
    evs = [length(EEG.event)+1, length(EEG.event) + ile_ev];
    urs = [length(EEG.urevent)+1, length(EEG.urevent) + ile_ev];
end


lat = 1;

%% adding fake events ('dummy'):
for i = evs(1):evs(2)
    
    % event creation:
    EEG.event(i).type = evname;
    EEG.event(i).latency = lat;
    EEG.event(i).duration = 0;
    EEG.event(i).urevent = i;
    EEG.event(i).win_num = (i - evs(1)) + 1;
    
    % urevent creation:
    uradr = urs(1) + (i-1);
    EEG.urevent(uradr).type = evname;
    EEG.urevent(uradr).latency = EEG.event(i).latency;
    EEG.urevent(uradr).win_num = EEG.event(i).win_num;
    
    lat = lat + window;
    
end

% czy checkset potrzebny?
EEG = eeg_checkset(EEG);

% epokujemy
EEG = pop_epoch(EEG, {evname}, [0 winlen]);

%% wywalamy zdublowane fake-eventy (EEGLAB dziwnie epokuje):
dumev = find(strcmp(evname, {EEG.event.type}));
lats = [EEG.event(dumev).latency];

% looking for 'dummy' sametimers:
% this step is not necessary, EEGlab
% just epochs events in a slightly
% odd way (so that some 'dummy' events
% are duplicated) - it may be related
% to event duration, I will check it
% in future
indx = length(dumev); evdel = false(size(EEG.event));
while indx >= 1
    current_lat = EEG.event(dumev(indx)).latency;
    
    % looking for same latencies:
    samelat = find(lats == current_lat);
    
    % there will be obviously one the same (which
    % is the current event), any additional are
    % removed
    if length(samelat) > 1
        del = samelat(1:end-1);
        del_ev = dumev(samelat(1:end-1));
        evdel(del_ev) = true;
        lats(del) = []; dumev(del) = [];
    end
    
    indx = indx - 1;
end

EEG.event(evdel) = [];
clear del del_ev dumev evdel lats samelat current_lat


%% remove distant
%  if 'distance' is set - removing windows 
%  that are too far from defined events
%  ADD - option to pre-select (?)
%  ADD - option to select based on the window
%        being between some two events!
%        the option above will use 
%        event_pattern_search.m


if isdist
    % prealloc vector marking epochs to
    % leave (true = fulfills some rule, leave)
    wins = false(1, length(EEG.epoch));
    winlim = 1:window:(ile_ev*window);
    rules = options.distance;
    
    % going through all the rules:
    for r = 1:size(rules,1);
        %% checking rule type:
        % CHANGE this description and ADD to help doc:
        % normal rule starts with event type
        % another type of rule begins with
        % definition of a sequence of events that
        % constitute a big window within which all
        % smaller windows will be selected.
        % the sequence of events is defined along
        % standards of event_pattern_search
        % the second element of rules cell matrix
        % should be either {[]} for normal window
        % defined by the event pattern, or for example:
        % {[-2 3]}, to have the pattern window extend-
        % ded by 2 seconds before and 3 seconds after
        % the given event pattern.
        
        if ~iscell(rules{r,2})       
        %% normal rule, checking event type:
        
        % if any event else specific event:
        if isempty(rules{r,1})
            % any nondummy event:
            ev_ind = ~strcmp(evname,{EEG.event.type});
            
            % if previous rules present, 
            % do not include their event types:
            if r >= 2
                for pt = 1:r-1
                    rem_ev = strcmp(rules{pt,1},{EEG.event.type});
                    ev_ind(rem_ev) = false;
                end
            end
            ev_ind = find(ev_ind);
        else
            % specific event
            rls = rules{r,1};
            tps = {EEG.event.type};
            if ~iscell(rls)
                ev_ind = find(strcmp(rls, tps));
            else
                ev_ind = cellfun(@(x) find(strcmp(x, tps)), ...
                    rls, 'UniformOutput', false);
                ev_ind = unique([ev_ind{:}]);
            end
        end
        
        % once we have event indices, we extract their latencies:
        ev_lats = [EEG.event(ev_ind).latency];
        
        %% distance
        % then we set acceptable distances:
        dists = rules{r,2};
        if length(dists) == 1
            dists = [dists, -dists]; %#ok<AGROW>
        end
        dists = dists(1:2); % just for sure
        dists = sort(dists)*onesec;
        
        %% window loop
        % now we loop only through those epochs that
        % have not yet been decided upon:
        undecid = find(~wins);
        for un = 1:length(undecid)
            ep_n = undecid(un);
            ep_lims = [window*(ep_n-1)+1, window*(ep_n)];
            
            %~~~~( - )~~~~%
            % checking distance on the 'minus side':
            before = find(ev_lats >= ep_lims(1)  & ...
                ev_lats <= (ep_lims(2)-dists(1)), 1, 'first');
            % if fullfilled, continue:
            if ~isempty(before)
                wins(ep_n) = true;
                continue
            end
            
            %~~~~( + )~~~~%
            % minus side did not pass checks, checking
            % the 'plus side':
            after = find(ev_lats <= ep_lims(2)  & ...
                ev_lats >= (ep_lims(1)-dists(2)), 1, 'first');
            % if fullfilled, continue:
            if ~isempty(after)
                wins(ep_n) = true;
                continue
            end
            
            % CHANGE - ADD oversight - not checking windows
            % that are bound to fulfill the rule (because
            % of previous check results)
            
        end
        
        else
            %% event_pattern_search required!
            pattern = rules{r,1};
            edges = rules{r,2}{1};
            
            % be sure to set 'ignore' to 'dummy':
            if length(pattern) <= 3
                pattern{3} = 'ignore';
                pattern{4} = {evname};
            elseif length(pattern) == 4
                pattern{3} = 'ignore';
                pattern{4} = [pattern{4}, evname];
            end
            
            % setting edges
            if isempty(edges)
                edges = [0, 0];
            else
                edges = round(edges * onesec);
            end
            
            % using event_pattern_search:
            locate_pattern = event_pattern_search(EEG, pattern);
            
            % extracting event numbers:
            event_inds = locate_pattern.(pattern{1});
            
            %% for each pattern sequence:
            for pat = 1:length(event_inds)
                lats(1) = EEG.event(event_inds{pat}(1)).latency;
                lats(2) = EEG.event(event_inds{pat}(end)).latency;
                latrange = lats + edges;
                
                % now checking which windows are within latrange:
                low_e = find(winlim<=latrange(1),1,'last');
                high_e = find(winlim<=latrange(2),1,'last');
                
                % setting these windows to true
                wins(low_e:high_e) = true;
            end
        end
    end
    
    % deleting events not fulfilling any distance condition:
    EEG = pop_selectevent( EEG, 'epoch', find(wins) ,'deleteevents','off',...
    'deleteepochs','on','invertepochs','off');
end

if fill
    if isfield(options, 'filter')
        EEG.onesecepoch.filter = options.filter;
    end
    EEG.onesecepoch.initwins = ile_ev;
    EEG.onesecepoch.winlen = winlen;
    
    if isdist; EEG.onesecepoch.prerej = find(~wins); 
        EEG.onesecepoch.distopt = rules; end
    
    % winlen is not neccessary - it can be calculated from:
    % EEG.pnts/EEG.srate
end