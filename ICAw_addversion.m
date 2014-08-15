function ICAw = ICAw_addversion(ICAw, rr, opt)

% version name must be given
f = ICAw_checkfields(opt, 1, {'version_name'});
if ~f.fnonempt
    return
end


for r = rr
    
    % check if this record has versions
    f = ICAw_checkfields(ICAw, r, {'versions'});
    
    % no versions whatsoever:
    if ~f.fsubf
        ICAw = ICAw_mainversion(ICAw, r);
    end
    
    ver = ICAw_getversions(ICAw, r);
    
    % ignoring main:
    vnames = ver(:,2);
    verf = ver(:,1);
    verf(1) = [];
    
    %% look for free version
    % create anonymous function and go by cellfun
    func = @(x) str2num(x(4:end)); %#ok<ST2NM>
    
    verf = cellfun(func, verf);
    clear func
    
    missing = setdiff(1:max(verf), verf);
    if isempty(missing)
        missing = length(verf) + 1;
    else
        missing = missing(1);
    end
    
    num = '00';
    missing = num2str(missing);
    
    num(end-length(missing)+1 : end) = missing;
    thisver = ['ver', num];
    clear missing verf num
    
    %% check if name present
    nm_acc = false;
    
    while nm_acc
        cmp = strcmp(opt.version_name, vnames);
        
        if sum(cmp) > 0
            % add a digit to name
            opt.version_name = [opt.version_name,...
                num2str( floor(rand(1)*10) )];
        else
            nm_acc = true;
        end
    end
    
    %% add version:
    f = ICAw_checkfields(opt, 1, [],...
    'ignore', {'subjectcode', 'tasktype', 'filename', 'filepath',...
    'datainfo', 'session', 'versions'});

        fld = f.fields(f.fnonempt);
        
        for f = 1:length(fld)
            ICAw(r).versions.(thisver).(fld{f}) = opt.(fld{f});
        end
end