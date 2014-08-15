% WRITE MORE ABOUT THIS SCRIPT
% !! remember to add (after ICA), also
%    the information about channels
%    chanica?
% this script loads a dataset from directory
% uses onesecepoch to epoch the data to 1-sec
% windows, lets user mark windows to reject,
% and then updates structure with info about the set

% a GUI would be useful...

pre = '\\Swps-01143\e';
% pre = 'D:';

% defaults:
LOAD_DIR = [pre '\Dropbox\DANE\MGR\EEG\set\'];
info_file = [pre '\Dropbox\DANE\MGR\EEG\ICAw_set.mat'];
cont = true; i = 1; choosefiles = true;

% default onsec options
options.filename = [];
options.filter = [1 0];
options.leave = true;
options.fill = true;
% options.distance = {[], [-3 10]}; % optional - distance
events_pattern1 = {'antisac16', {'D128', 1; 'DI64', 1; 'DI16', 1;...
    'DIN8', 1}, 'ignore', {'DIN2','DIN1'}};
events_pattern2 = {'antisac32', {'D128', 1; 'DI64', 1; 'DI32', 1;...
    'DIN8', 1}, 'ignore',{'DIN2','DIN1'}};
options.distance = {events_pattern1, {[-1 1.5]};...
    events_pattern2, {[-1 3]}};
clear events_pattern1 events_pattern2

% declare globals:
global EEG ALLEEG CURRENTSET

% first - get list of files:
if choosefiles
    FilterSpec = [LOAD_DIR, '*.set'];
    DialogTitle = 'select files to clean...';
    % DefaultName = LOAD_DIR;
    [file_list, LOAD_DIR] = uigetfile(FilterSpec, DialogTitle, ...
         'MultiSelect', 'on');
    if ischar(file_list)
        file_list = {file_list};
    end
    clear FilterSpec DialogTitle DefaultName
else
    file_list = prep_list(LOAD_DIR, '*.set'); %#ok<UNRCH>
end

% starting eeglab
EEG = eeglab; %#ok<NASGU>
CURRENTSET = 1; CURRENTSTUDY = 0; %#ok<NASGU>
LASTCOM = ''; ALLCOM = {}; %#ok<NASGU>

% looping through files
while cont && i <= length(file_list)
    
    % selecting file
    file = file_list{i};
    disp('   . . .');
    disp('=~=~=~=~=~=');
    disp(['File ', file]);
    
    %% checking if given subject has relevant data,
    %  if not - create
    
    % loading info file
    loaded = load(info_file);
    newICAw = loaded.newICAw;
    clear loaded
    
    % chcecking fields
    fields = {newICAw.filename};
    samef = find(strcmp(file ,fields));
    
    % if there are already fields for the same file:
    if ~isempty(samef)
        txt1 = 'file present in the database in ';
        if length(samef) == 1
            txt1 = [txt1, '1 variant.']; %#ok<AGROW>
        else
            txt1 = [txt1, num2str(length(samef)),' variants.']; %#ok<AGROW>
        end
        disp(txt1); clear txt1
        
        % using ICAw_checkbase_present
        [answer, ans_adr] = ICAw_checkbase_present(newICAw,...
            file, {'postreject'});
        
        if sum(sum(answer)) == 0
            disp('This file does not have postrejections, loading...');
            load_set = true; writein = samef(1);
        else
            % we do not process this file
            disp('You already have some rejections for this file...');
            disp(answer);
            load_set = input('Load set anyway? (true/false):  ');
            if load_set
                writein = length(newICAw)+1;
            end
        end
    else
        disp('file not present in database, loading...');
        writein = length(newICAw)+1; load_set = true;
    end
    disp('=~=~=~=~=~=');
    disp('   . . .');
    
    %% loading and marking
    if load_set
        % loading set file:
        EEG = pop_loadset('filename', file, 'filepath', LOAD_DIR);
        options.filename = EEG;
        
        % epoching:
        EEG = onesecepoch(options);
        
        % cleaning filename option (no need to store EEG twice)
        options.filename = [];
        % just for EEGlab GUI we update ALLEEG:
        % ALLEEG = EEG;
        
        % opening marking menu:
        % eeglab redraw
        pop_eegplot( EEG, 1, 1, 0);
        disp('   . . .');
        disp('=~=~=~=~=~=');
        disp('Waiting. Enter your badchannels, notes (''n: '') below:  ');
        wtng = input('>>   ');
        
        if length(wtng)>1
            % analiza inputu tekstowego:
            [~, in] = regexp(wtng, 'n:', 'once');
            
            % updating notes
            if ~isempty(in)
                newICAw(writein).notes = wtng(in+1:end);
                disp('notes recorded.');
                
                % checking usecleanline:
                a = regexp(newICAw(writein).notes, 'usecleanline', 'once');
                if ~isempty(a)
                    newICAw(writein).usecleanline = true;
                    disp('the need for clean line noted.');
                else
                    newICAw(writein).usecleanline = false;
                end
                
            else
                in = length(wtng);
            end
            
            % looking for tasktype:
            [d, a] = regexp(wtng(1:in), 'tasktype:', 'once');
            if ~isempty(a)
                newICAw(writein).tasktype = wtng(a+1:in-2);
                disp('tasktype noted.');
            else
                newICAw(writein).tasktype = [];
            end
            
            
            % looking for channels
            badchan = regexp(wtng(1:in), '[0-9]+', 'match');
            badchan = cellfun(@str2num, badchan);
            
            if ~isempty(badchan)
                newICAw(writein).badchan = badchan;
                disp('bad channels recorded.');
            end
            clear d a wtng in
        end
        
        % updating structure
        newICAw(writein).filename = file;
        newICAw(writein).filepath = LOAD_DIR;
        newICAw(writein).epoch_events = 'dummy';
        newICAw(writein).epoch_limits = [];
        newICAw(writein).winlen = EEG.winlen;
        newICAw(writein).distance = options.distance;
        newICAw(writein).prerej = EEG.prerej;
        newICAw(writein).postreject = find(EEG.reject.rejmanual);
        newICAw(writein).filter = options.filter;
        
        % translating postrej and prerej to removed:
        dums = find(strcmp('dummy', {EEG.event.type}));
        winnums = [EEG.event(dums).win_num];
        postrej_norm = winnums(newICAw(writein).postreject);
        newICAw(writein).removed = sort([newICAw(writein).prerej, postrej_norm]);
        
        disp('rejections recorded.');
        
        % save(info_file, 'newICAw');
        clear newICAw
        clear writein winnimd dums badchan postrej_norm
        EEG = []; ALLEEG = []; %#ok<NASGU>
    end
    
    % ending - asking user to continue
    disp('=~=~=~=~=~=');
    cont = input('Continue? (true/false):  ');
    i = i + 1;
    disp('   . . .');
    disp('=~=~=~=~=~=');
end

clear ALLCOM ALLEEG CURRENTSET CURRENTSTUDY EEG LASTCOM
clear LOAD_DIR PLUGINLIST STUDY ans choosefiles cont
clear eeglabUpdater fields file file_list i info_file
clear load_set options pre samef tmpstr winnums