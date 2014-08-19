function ICAw = ICAw_updatetonewformat(ICAw)

% OUTDATED
% updates ICAw structure to its most current form



%% check if some fields are present:
flds = {'userrem', 'autorem'};
inflds = {{'color', 'name'}, {'color', 'name'}};

for f = 1:length(flds)
    fp = isfield(ICAw(1), flds{f});
    if ~fp
        ICAw(1).(flds{f}) = [];
        for r = 1:length(ICAw)
            for ff = 1:length(inflds{f})
                ICAw(r).(flds{f}).(inflds{f}{ff}) = [];
            end
        end
    else
        for r = 1:length(ICAw)
            for ff = 1:length(inflds{f})
                fp = isfield(ICAw(r).(flds{f}), inflds{f}{ff});
                
                if ~fp
                    ICAw(r).(flds{f}).(inflds{f}{ff}) = [];
                end
                
            end
        end
    end
end
clear ff fp f flds inflds

% check mscnum - this is no longer needed
if isfield(ICAw(1).autorem, 'mscnum')
    for r = 1:length(ICAw)
        ICAw(r).autorem = rmfield(ICAw(r).autorem, 'mscnum');
    end
end



%% check rejection name and color fields

% known rejection types:
rejfields = {'autorem', 'userrem'};
rejsub{1} = {'prob', 'mscl'};
rejsub{2} = {'userreject', 'usermaybe', 'userdontknow'};

% ADD - take color options from options file
rejcol{1} = [1, 0.6991, 0.7537; 0.9596 0.7193 1];
rejcol{2} = [252 177 158; 254 239 156; 196 213 253]./255;
rejnam{1} = {'low probability', 'muscular artifact'};
rejnam{2} = {'reject', 'maybe', '?'};

% loop through all entries
for r = 1:length(ICAw)
    for rj = 1:length(rejfields)
        fld = ICAw_checkfields(ICAw(r).(rejfields{rj}), 1, [], 'ignore',...
            {'name', 'color'});
        flds = fld.fields;
        
        % for each field:
        for f = 1:length(flds)
            % check if its known
            ifk = find(strcmp(flds{f}, rejsub{rj}));
            
            % check if color is present;
            chf = ICAw_checkfields(ICAw(r).(rejfields{rj})...
                .color, 1, flds(f));
            if ~chf.fnonempt(1) || (chf.fnonempt(1) && ...
                    ~(numel(size(ICAw(r).(rejfields{rj}).color...
                    .(flds{f}))) == 3))
                % color is not present or badly formatted
                if ifk
                    % color is known
                    ICAw(r).(rejfields{rj}).color.(flds{f}) = ...
                        rejcol{rj}(ifk,:);
                else
                    % use random color
                    ICAw(r).(rejfields{rj}).color.(flds{f}) = ...
                        rand(1,3);
                end
            end
            
            % check if name is present;
            chf = ICAw_checkfields(ICAw(r).(rejfields{rj})...
                .name, 1, flds(f));
            if ~chf.fnonempt(1) || (chf.fnonempt(1) && ...
                    ~ischar(ICAw(r).(rejfields{rj}).name...
                    .(flds{f})))
                % name is not present or badly formatted
                if ifk
                    % name is known
                    ICAw(r).(rejfields{rj}).name.(flds{f}) = ...
                        rejnam{rj}{ifk};
                else
                    % copy field name as rej name
                    ICAw(r).(rejfields{rj}).name.(flds{f}) = ...
                        flds{f};
                end
            end
        end
        
    end
end
% for r = 1:length(ICAw)

%% check previous onesecepoch settings:
flds = {'winlen', 'distance'};

for r = 1:length(ICAw)
    if isfield(ICAw, 'onesecepoch') && islogical(ICAw(r).onesecepoch)
        ICAw(r).onesecepoch = [];
        ep = ICAw_checkfields(ICAw, 1, {'epoch_events',...
            'epoch_limits'});
        if sum(ep.fnonempt) == 0
            for f = 1:length(flds)
                if isfield(ICAw(r), flds{f})
                    ICAw(r).onesecepoch.(flds{f}) = ...
                        ICAw(r).(flds{f});
                end
            end
        end
    end
end

if isfield(ICAw,flds)
    ICAw = rmfield(ICAw, flds);
end
