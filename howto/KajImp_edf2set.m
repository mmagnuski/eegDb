% create set files for KajImp 2013 - 2014
%

% first load files to EEGlab and save as set
Pth = 'D:\Dropbox\DANE\KajImp 2013-2014\raw\new\';
flist = prep_list(Pth, '*.edf');
SaveTo = 'D:\Dropbox\DANE\KajImp 2013-2014\set\';

% create save folder:
if ~isdir(SaveTo)
    mkdir(SaveTo);
end

% channels to remove:
chnind = [20, 21];

for f = 1:length(flist)
    try
        % load files and save to set format
        EEG = pop_biosig([Pth, flist{f}]);
        
        % remove electrodes 20 and 21:
        EEG.chanlocs(chnind) = [];
        EEG.data(chnind,:,:) = [];
        EEG.nbchan = EEG.nbchan - length(chnind);
        
        % load electrode locations
        EEG=pop_chanedit(EEG, 'lookup',['D:\\MATLAB\\',...
            'toolbox\\eeglab12_0_2_0b\\plugins\\',...
            'dipfit2.2\\standard_BEM\\elec\\standard_1005.elc']);
        
        % save
        [~, fnm, ~] = fileparts(flist{f});
        pop_saveset(EEG, 'filename', [fnm, '.set'],...
            'filepath', SaveTo);
        clear EEG fnm
    catch %#ok<CTCH>
        fprintf('Error in file %s', flist{f});
    end
end