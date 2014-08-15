Pth = 'D:\Dropbox\DANE\KajImp 2013-2014\raw\';
flist = prep_list(Pth, '*.txt');

tasktype = {'EO', 'EC'};
pattern = '[^ ]+ ';
subID = regexp(flist, pattern, 'match', 'once');
EC = cellfun(@isempty, regexp(flist, 'EO', 'match', 'once'));

orig_names = flist;

% anonimize files
% all file get IDs as follows:
% KajImp01 EC.edt
% KajImp01 EO.edt
% KajImp02 EC.edt
% (...)
pre = 'KajImp';
uni = unique(subID);

for S = 1:length(uni)
    % find files with this ID:
    fn = find(strcmp(uni{S}, subID));
    
    % there should be at least one such file
    if length(fn) <= 2
        
        for f = 1:length(fn)
            % check condition type
            cond = tasktype{EC(fn(f)) + 1};
            
            % generate new file name:
            Sstr = '00';
            strS = num2str(S);
            Sstr(end-length(strS)+1:end) = strS;
            newfnm = [pre, Sstr, ' ', cond, '.edf'];
            orig_names{fn(f), 2} = newfnm;
            
            movefile([Pth, orig_names{fn(f), 1}], ...
                [Pth, orig_names{fn(f), 2}]);
        end
        
    else
        disp('Oops... more than two file from one subject?');
        disp(flist(fn));
    end
end