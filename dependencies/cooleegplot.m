function varargout = cooleegplot(EEG, varargin)

% FIXHELPINFO
% cooleegplot() is a shortcut to EEGlab's eegplot.
% It eases up calls to eegplot and adds some fancy
% features like color palettes for electrode signal.
% cooleegplot() is designed especially for usage
% with ICAw plugin.
%
% Example:
% try watching your signal this way:
% >> cooleegplot(EEG, 'ecol', 'cosmic bubblegum');
%
% ==INPUT==
% EEG      - obligatory input, EEGlab's EEG structure
%
% =optional inputs=
% __________________________________________________
%    KEY  |  value   |    description
% ________|__________|______________________________
%         |          |
%  'ecol' |  string  | color electrode traces for
%         |          | easier tracking of single
%         |          | electrodes. For more options
%         |          | see color_palette().
% ________|__________|______________________________
%         |          |
%'selcol' | [R,G,B]  | color of manual rejection.
%         |each value| (the color that highlights
%         |between 0 | given epoch / timerange if
%         | and 1    | it is clicked)
%         |          | Should be different than
%         |          | color of other selection
%         |          | methods.
% ________|__________|______________________________
%
% coded by M. Magnuski, august 2013

% TODOS:
% [X] test whether passing ICAw, r and keys
%     - values works together well.
% [ ] should r be really given? It can be checked
%     by comparing EEG and ICAw...
% [ ] option to recover and plot?
% [ ] LATER add file (possibly .m) with default settings
%     that can be changed by the user
% [X] left arguments in varargin are checked:
%     if it is a structure then it is assumed it
%     is ICAw structure
%     if it is numerical it is assumed to be 'r' if
%     len == 1 and ICAw adress is one before;
%     it is assumed to be ['wlen'] or ['wlen', 'elec']
%     if no ICAw is present or ICAw adress is after
% [X] set varargout:
%     h if 'nowait'
%     EEG if ICAw is not passed
%     ICAw if ICAw was passed (second arg - EEG)

%% defaults:
tag = 'cooleegplot';
com = 'fprintf(''Updated EEG marks\n'')';
update = true;

elec = 1:EEG.nbchan;
nelec = EEG.nbchan;

butlabel = 'UPDATE MARKS';

wlen = 4;

ICAw_present = false;
% CHANGE so that other rejection types can be applied
chckflds = {'rejjp', 'rejmanual', 'rejfreq', 'userreject', 'usermaybe',...
    'userdontknow'};

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
        'nelec', 'update'};
    vars = {'elec_color', 'EEG.reject.rejmanualcol',...
        'tag', 'butlabel', 'com', 'wlen', 'nowait',...
        'elec', 'nelec', 'update'};
    
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
    
    % formatting color
    if ischar(elec_color)
        cpal = color_palette(elec_color);
        elec_color = mat2cell(cpal, ...
            ones(size(cpal,1), 1), 3);
    elseif isnumeric(elec_color)
        elec_color = mat2cell(elec_color, ...
            ones(size(elec_color,1), 1), 3);
    end
    
    % changing elec
    if length(elec) ~= EEG.nbchan
        EEG.data = EEG.data(elec,:,:);
        EEG.nbchan = length(elec);
        EEG.chanlocs = EEG.chanlocs(elec);
    end
    
    %% check ICAw presence etc.
    if ~isempty(varargin)
        % look for ICAw:
        ICAw_adr = find(cellfun(@isstruct, varargin));
        if ~isempty(ICAw_adr)
            ICAw_present = true;
            ICAw = varargin{ICAw_adr}; r = 1;

            % CHANGE to_field needs to be changed
            to_field = {'prob', 'manual', 'mscl', 'reject', 'maybe',...
                'dontknow'};
            % field name within which the ones below are hidden:
            to_ftype = [1, 1, 1, 2, 2, 2];
            ftype = {'autorem', 'userrem'};
            
            butlabel = ['UPDATE ICAw(', num2str(r), ')'];
            com = ['fprintf(''Updated relevant EEG and ICAw fileds\n',...
                'First returned argument is the ICAw database\n'')'];
            
        end
        
        % look for numeric values:
        num_adr = find(cellfun(@isnumeric, varargin));
        
        for n = 1:length(num_adr)
            if ~ICAw_present || (ICAw_present ...
                    && num_adr(n) < ICAw_adr)
                nm = varargin{num_adr(n)};
                wlen = nm(1);
                if length(nm) > 1
                    nelec = nm(2);
                end
            elseif ICAw_present && num_adr(n) > ICAw_adr
                r = varargin{num_adr(n)};
            end
        end
    end
end



%% ~~==welcome to the code==~~
rejmat = eeg_rejmat(EEG);

% if no eegplot2
if isempty(which('eegplot2'))
    % plot EEG.data
    eegplot(EEG.data, 'srate', EEG.srate, 'color', ...
        elec_color, 'dispchans', nelec, 'eloc_file',...
        EEG.chanlocs, 'events', EEG.event, 'winrej',...
        rejmat, 'tag', tag, 'wincolor', ...
        EEG.reject.rejmanualcol, 'butlabel', butlabel,...
        'command', com, 'winlength', wlen, 'limits', ...
        [EEG.times(1), EEG.times(end)]);
else
    % plot EEG.data
    eegplot2(EEG.data, 'srate', EEG.srate, 'color', ...
        elec_color, 'dispchans', nelec, 'eloc_file',...
        EEG.chanlocs, 'events', EEG.event, 'winrej',...
        rejmat, 'tag', tag, 'wincolor', ...
        EEG.reject.rejmanualcol, 'butlabel', butlabel,...
        'command', com, 'winlength', wlen, 'limits', ...
        [EEG.times(1), EEG.times(end)]);
end

h = findobj('tag', tag);

if nowait && nargout > 0
    varargout{1} = h; %#ok<*UNRCH>
end

if ~nowait
    uiwait(h);
    
    % update ICAw autorem
    % search by colors
    if evalin('base', 'exist(''TMPREJ'', ''var'');') == 1
        % get TMPREJ from workspace
        TMPREJ = evalin('base', 'TMPREJ;');
        
        if update
            tmpsz = size(TMPREJ);
            
            % check for segments
            if ICAw_present && isfield(ICAw, 'segment') && ...
                    isnumeric(ICAw(r).segment)
                nseg = floor(ICAw(r).winlen/ICAw(r).segment);
                seg_pres = true;
            else
                seg_pres = false;
            end
            
            % checking rejection methods
            for f = 1:length(chckflds)
                % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                % CHANGE ? - the code below does not work because
                %            it checks EEG instead of EEG.reject
                % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
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
                    
                    if ICAw_present
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
                        ICAw(r).(ftype{to_ftype(f)}).(to_field{f}) =...
                            rejected;
                        
                        % this may be unnecessary:
                        ICAw(r).(ftype{to_ftype(f)}).color.(to_field{f}) =...
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
    if ICAw_present && nargout > 0
        if update
            varargout{1} = ICAw;
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