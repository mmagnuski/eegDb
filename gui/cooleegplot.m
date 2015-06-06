function varargout = cooleegplot(EEG, varargin)

% help info is in progress FIXHELPINFO
% cooleegplot() is a shortcut to EEGlab's eegplot.
% It eases up calls to eegplot and adds some fancy
% features like color palettes for electrode signal.
% cooleegplot() is designed especially for usage
% with db plugin.
%
% Examples:
% try watching your signal this way:
% >> cooleegplot(EEG, 'ecol', 'cosmic bubblegum');
%
% you can also ask for specific number of epochs/seconds
% in one eegplot window:
% >> cooleegplot(EEG, 5);
%
% or if you wanted to plot 3 epochs per window and at
% the same time 12 electrodes per window:
% >> cooleegplot(EEG, [3, 12]);
%
%
% ==INPUT==
% EEG      - obligatory input, EEGlab's EEG structure
%
% =optional inputs=
% ____________________________________________________________
%    KEY    |  value        |    description
% __________|_______________|___________________________________
%           |               |
%  'ecol'   |  string       | color electrode traces for
%           |               | easier tracking of single
%           |               | electrodes. For more options
%           |               | see color_palette().
% __________|_______________|____________________________________
%           |               |
% 'elec'    | vector of in- | electrode indices (if vector
%           |   tegers or   | of integers) or labels (if cell
%           |    cell of    | of strings) - these electrodes
%           |    strings    | will be plotted
% __________|_______________|____________________________________
%           |               | electrode indices (if vector
% 'badchan' | vector of in- | of integers) or labels (if cell
%           |   tegers or   | of strings) - these electrodes
%           |    cell of    | are considered bad channels and
%           |    strings    | are either ommitted (removed from
%           |               | the elec vector), plotted with a
%           |               | specific color or interpolated.
%           |               | The default is to plot them in gray
% __________|_______________|____________________________________
% 'badplot' |    'grey'     |
%           |   [R, G, B]   |
%           |    'hide'     |
%           |  or 'interp'  |
%           |               |
% __________|_______________|____________________________________
% 'lsmo'    |   'on'/'off'  | Whether to smooth electrode traces
%           |               | (antialiasing).
% __________|_______________|____________________________________
%           |               |
%'selcol'   | [R,G,B]       | color of manual rejection.
%           |each value     | (the color that highlights given
%           |between 0      |  epoch / timerange if it is
%           | and 1         |  clicked)
%           |               | Should be different from color of
%           |               | other selection methods.
% __________|_______________|____________________________________
%           |               |
%'data2'    |  float,       | Data to plot along with standard data
%           |  matrix,      | for comparison
%           |  EEG data     | 
%
% coded by M. Magnuski, august 2013

% =================
% info for hackers:
% =================
% ---> recoverEEG uses db_getrej and places
%      rejlist (list of rejections) in
%      EEG.reject.db
%
% --> left arguments in varargin are checked this way:
%       - if it is a structure then it is assumed it
%         is db structure
%       - if it is numerical it is assumed to be 'r' if
%         len == 1 and db location in varargin is one before;
%       - it is assumed to be ['wlen'] or ['wlen', 'elec']
%         if no db is present or db adress is after
%
% --> varargout are set this way:
%       - h if 'nowait'
%       - EEG if db is not passed
%       - db if db was passed (second arg - EEG)


% TODOS:
% [ ] !! CHANGE the way post-window rejection adding
%        works - it seems not to work now!
%        possibly winreject adds it differently...
% [ ] update EEG by changing db field (what?)
% [ ] returned EEG has less electrodes if
%     'elec' was defined, origEEG can be
%     created at the beginning and all
%     necessary changes applied there
%     to solve this issue
% [ ] rewrite the HELPINFO to be easier to
%     maintain and read
% [ ] check updating db - change the current mess
% [ ] multiple rejections in eegplot2
% [X] handle default EEG rejections...
% [ ] work a little bit with button commands
%     so that for example user can pass the button
%     command (just like in eegplot)
% [ ] LATER add file (possibly .m) with default settings
%     that can be changed by the user


%% defaults:
tag = 'cooleegplot';
com = 'fprintf(''Updated EEG marks\n'')';
update = true;

elec = 1:EEG.nbchan;
nelec = EEG.nbchan;

butlabel = 'UPDATE MARKS';
badplot = 'grey'; badchan = [];
lsmo = 'on';
wlen = 4;

db_present = false;

% CHANGE so that other rejection types can be applied
%        may be of use later - to have a connection manual --> reject for example
% chckflds = {'rejjp', 'rejmanual', 'rejfreq', 'userreject', 'usermaybe',...
    % 'userdontknow'};



% electrode colors
cpal = color_palette(); nowait = false;
elec_color = mat2cell(cpal, ones(size(cpal,1), 1), 3);

if nargout > 0
    for nin = 1:nargout
        varargout{nin} = []; %#ok<AGROW>
    end
end

%% check optional input
if nargin > 1
    
    args = {'ecol', 'selcol', 'tag', 'butlab', ...
        'comm', 'winlen', 'nowait', 'elec', ...
        'nelec', 'update', 'badplot', 'badchan', 'lsmo'};
    vars = {'elec_color', 'EEG.reject.rejmanualcol',...
        'tag', 'butlabel', 'com', 'wlen', 'nowait',...
        'elec', 'nelec', 'update', 'badplot', 'badchan',...
        'lsmo'};
    
    for a = 1:length(args)
        reslt = find(strcmp(args{a}, varargin));
        if ~isempty(reslt)
            reslt = reslt(1);
            eval([vars{a}, ' = varargin{reslt+1};']);
            varargin([reslt, reslt+1]) = [];
            if isempty(varargin)
                break
            end
        end
    end
    
    %% check db presence etc.
    if ~isempty(varargin)
        % look for db:
        db_adr = find(cellfun(@isstruct, varargin));
        if ~isempty(db_adr)
            db_present = true;
            db = varargin{db_adr}; r = 1;
            to_field = {'prob', 'manual', 'mscl', 'reject', 'maybe',...
                'dontknow'};
            % field name within which the ones below are hidden:
            to_ftype = [1, 1, 1, 2, 2, 2];
            ftype = {'autorem', 'userrem'};
            
            com = ['fprintf(''Updated relevant EEG and db fileds\n',...
                'First returned argument is the db database\n'')'];
            
        end
        
        % look for numeric values:
        num_adr = find(cellfun(@isnumeric, varargin));
        
        for n = 1:length(num_adr)
            if ~db_present || (db_present ...
                    && num_adr(n) < db_adr)
                nm = varargin{num_adr(n)};
                wlen = nm(1);
                if length(nm) > 1
                    nelec = nm(2);
                end
            elseif db_present && num_adr(n) > db_adr
                r = varargin{num_adr(n)};
            end
        end
    end
end



%% ~~==welcome to the code==~~
rejmat = eeg_rejmat(EEG);

labels = {'happy bunny'};
labcol = {[0.85 1 0]};
% get rejection types (from db field)
if isfield(EEG.reject, 'db') && ~isempty(EEG.reject.db)...
        && isfield(EEG.reject.db, 'name')
    labels = EEG.reject.db.name;
    labcol = EEG.reject.db.color;
end

% formatting color
if ischar(elec_color) && ~strcmp('off', elec_color)
    cpal = color_palette(elec_color);
    elec_color = mat2cell(cpal, ...
        ones(size(cpal,1), 1), 3);
elseif isnumeric(elec_color)
    elec_color = mat2cell(elec_color, ...
        ones(size(elec_color,1), 1), 3);
elseif strcmp('off', elec_color)
    elec_color = {[0, 0, 0]};
end

% changing elec
if length(elec) ~= EEG.nbchan
    % EEG.nbchan = length(elec);
end

% if badchan not provided
if isempty(badchan) && db_present
    if femp(db(r), 'chan') && femp(db(r).chan, 'bad')
        badchan = db(r).chan.bad;
    end
end

% if badchan is present and badplot is not 'plot':
if ~isempty(badchan)&& ~(ischar(badplot) &&...
        strcmp(badchan, 'plot'))
    
    done = false;
    colplot = false;
    
    % check mapping badchan --> elec
    kill = zeros(length(badchan),1);
    for k = 1:length(badchan)
        temp = find(elec == badchan(k));
        if temp
            kill(k) = temp;
        end
    end
    kill(kill == 0) = [];
    clear k temp
    
    if isempty(kill)
        done = true;
    end
        
    if ~done && ischar(badplot) && strcmp(badplot, 'hide') 
        % delete given elecs:
        elec(kill) = [];
        clear kill
        done = true;
    end
    
    if ~done && ischar(badplot) && strcmp(...
            badplot, 'grey')
        colplot = true;
        color = [195, 195, 195]/255;
    end
    
    if ~done && isnumeric(badplot) && size(...
            badplot, 2) == 3
        colplot = true;
        color = badplot(1,:);
        
        % from 0-255 colors to 0-1
        if sum(color > 1) > 0
            color = color/255;
        end
    end
    
    if colplot
        rep = ceil(length(elec) / length(elec_color));
        
        if rep > 1
            elec_color = repmat(elec_color, [rep, 1]);
            elec_color = elec_color(1:length(elec));
        end
        
        elec_color(length(elec) + 1 - kill) = deal({color});
    end
    
    clear colplot done
end


% button name
if db_present
    butlabel = ['UPDATE db(', num2str(r), ')'];
end

% if no eegplot2
if isempty(which('eegplot2'))
    % plot EEG.data
    eegplot(EEG.data(elec,:,:), 'srate', EEG.srate, 'color', ...
        elec_color, 'dispchans', nelec, 'eloc_file',...
        EEG.chanlocs(elec), 'events', EEG.event, 'winrej',...
        rejmat, 'tag', tag, 'wincolor', ...
        EEG.reject.rejmanualcol, 'butlabel', butlabel,...
        'command', com, 'winlength', wlen, 'limits', ...
        [EEG.times(1), EEG.times(end)]);
else
    % plot EEG.data
    eegplot2(EEG.data(elec,:,:), 'srate', EEG.srate, 'color', ...
        elec_color, 'dispchans', nelec, 'eloc_file',...
        EEG.chanlocs(elec), 'events', EEG.event, 'winrej',...
        rejmat, 'tag', tag, 'wincolor', ...
        EEG.reject.rejmanualcol, 'butlabel', butlabel,...
        'command', com, 'winlength', wlen, 'limits', ...
        [EEG.times(1), EEG.times(end)], 'labels', ...
        labels, 'labcol', labcol, 'linesmoothing',...
        lsmo);
end

h = findobj('tag', tag);

if nowait && nargout > 0
    varargout{1} = h; %#ok<*UNRCH>
end

if ~nowait
    uiwait(h);
    
    % update db autorem
    % search by colors
    
    % !!!!!!!!!!!!!
    % FINISHED HERE
    % !!!!!!!!!!!!!
    % 1. why is isfield(EEG, fld) used? - does not have any sense!

    % CHANGE - is this ever used?, maybe should be
    %          put into a separate function?
    if evalin('base', 'exist(''TMPREJ'', ''var'');') == 1
        % get TMPREJ from workspace
        TMPREJ = evalin('base', 'TMPREJ;');
        
        if update
            tmpsz = size(TMPREJ);
            
            % check for segments
            if db_present && isfield(db(r).epoch, 'segment') && ...
                    isnumeric(db(r).epoch.segment)
                nseg = floor(db(r).epoch.winlen/db(r).epoch.segment);
                seg_pres = true;
            else
                seg_pres = false;
            end
            
            % checking rejection methods
            % CHANGE - this should not work - it looks whether fields are in EEG - bad
            for f = 1:length(chckflds)
                if isfield(EEG, chckflds{f})

                    rejcol = repmat(EEG.reject.([chckflds{f},...
                        'col']), [tmpsz(1), 1]);
                    foundadr = sum(TMPREJ(:, 3:5)...
                        - rejcol, 2) == 0;
                    newrej = TMPREJ(foundadr, 2)/ EEG.srate;
                    zerovec = zeros(EEG.trials,1);
                    zerovec(newrej) = 1;
                    clear rejcol foundadr newrej
                    
                    EEG.reject.(chckflds{f}) = zerovec';
                    
                    if db_present
                        % reshaping to segment rules
                        if seg_pres
                            rejected = reshape(zerovec,...
                                [nseg, EEG.trials/nseg]);
                            rejected = rejected';
                        else
                            rejected = zerovec;
                        end
                        
                        % fill the field (field name depends on
                        % method - autorem is for automatic remo-
                        % val userrem is for removal done by the
                        % user
                        db(r).(ftype{to_ftype(f)}).(to_field{f}) =...
                            rejected;
                        
                        % this may be unnecessary:
                        db(r).(ftype{to_ftype(f)}).color.(to_field{f}) =...
                            rejcol;
                        clear rejected rejcol
                    end
                end
            end
            clear tmpsz nseg
        end
        
    elseif ~update
        TMPREJ = []; %#ok<NASGU>
    end
    
    % returning output
    if db_present && nargout > 0
        if update
            varargout{1} = db;
            if nargout > 1, varargout{2} = EEG; end;
        else
            varargout{1} = TMPREJ;
        end
    elseif nargout > 0
        if update
            varargout{1} = EEG;
        else
            varargout{1} = TMPREJ;
        end
    end
end