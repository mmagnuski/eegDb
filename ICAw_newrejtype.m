function ICAw = ICAw_newrejtype(ICAw, newtypes)

% NOHELP

if isempty(newtypes)
    ex = evalin('base', 'exist(''TMPNEWREJ'', ''var'');');
    
    if ex
        newtypes = evalin('base', 'TMPNEWREJ;');
    else
        return
    end
    
end

% scan for rejtypes
% CHANGE - this should be only performed
%          for consistency checks one time
%          (at the beginning)
%          !! use persistent option :)
rejt = ICAw_scanrejtypes(ICAw);

% take only userrem types:
urem = strcmp('userrem', rejt.infield);
rejt.field = rejt.field(urem);
rejt.name = rejt.name(urem);
clear urem

isnew = false(length(newtypes.name), 1);

for n = 1:length(newtypes.name)
    isnew(n) = sum(strcmp(newtypes.name{n}, rejt.name)) == 0;
end

newt = find(isnew);
clear isnew

if ~isempty(newt)
    % there are some new types
    
    % we code new rejs with rej05, rej12 etc.
    fbeg = 'rej';
    fnum = '00';
    
    % find free field name
    freefld = 1:99;
    fnms = regexp(rejt.field, 'rej[0-9]{2}', 'once');
    nonemp = ~cellfun(@isempty, fnms);
    bsfld = rejt.field(nonemp);
    clear fnms nonemp
    
    if ~isempty(bsfld)
        bsnm = regexp(bsfld, '[0-9][0-9]', 'once','match');
        bsnm = unique(cellfun(@str2num, bsnm));
        
        freefld(bsnm) = [];
        clear bsnm bsfld
    end
    
    
    for n = 1:length(newt)
        
        % field name:
        nm = num2str(freefld(n));
        nnm = fnum;
        nnm(end-(length(nm)-1):end) = nm;
        clear nm
        fnm = [fbeg, nnm];
        
        % apply to all ICAw records
        for r = 1:length(ICAw)
            ICAw(r).userrem.(fnm) = [];
            ICAw(r).userrem.name.(fnm) = newtypes.name{newt(n)};
            ICAw(r).userrem.color.(fnm) = newtypes.color(newt(n), :);
        end
        
    end
    
end
