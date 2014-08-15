function [answer, ans_adr] = ICAw_checkbase(ICAbase, EEG, varargin)

% [answer, ans_adr] = ICAw_checkbase(ICAbase, EEG, varargin)
% Function used for checking whether given EEG structure is
% represented in a database and to what degree.
% It takes as arguments the database (structure) and the
% EEG structure and returns a boolean vector (answer), where:
% answer(1) states whether such file is present
%           in the ICA weights database
% answer(2) states whether this file has a variant
%           with the same filtering
% answer(3) states whether this file has a variant
%           with the same window length or epoching
% answer(4) states whether this file has a variant
%           with the same window/epoch rejections
% answer(5) states whether this file has any
%           weights associated in the datatabase
% answer(6) states whether these weights are the same
%           as in the given file
% additionally, second output contains adresses of
% corresponding celles in the database structure
% (so that later this structure cell can be updated with
% IC weights for example)
%
% coded by M. Magnuski, march 2013
% imponderabilion@gmail.com
% :)

filename_mod = false;
filter_mod = false; full_mod = true;
answer = false(1,6); ans_adr = cell(1,6);
check_icaw = false; silent = false;

if nargin > 2
    filename_mod = sum(strcmp('filename', varargin)) > 0;
    filter_mod = sum(strcmp('filter', varargin)) > 0;
    silent = sum(strcmp('silent', varargin)) > 0;
end

if full_mod
    fil = true;
    rst = true;
end

if filter_mod
    fil = true;
    rst = false;
end

if filename_mod
    fil = false;
    rst = false;
end

% chcecking fields
fields = {ICAbase.filename};
samef = find(strcmp(EEG.filename ,fields));
if ~silent
    disp('~~~~~~~~');
end

% if there are already fields for the same file:
if ~isempty(samef)
    if ~silent
        disp('file present in database.');
    end
    
    answer(1) = true;
    ans_adr{1} = samef;
    
    if fil && isfield(EEG, 'filter') && ~isempty(EEG.filter)
        % checking whether these files have same
        % filtering:
        fltr = find(EEG.filter(1) == ICAbase(samef).filter(1) & ...
            EEG.filter(2) == ICAbase(samef).filter(2));
        
        % if filtering is the same
        if ~isempty(fltr)
            if ~silent
                disp('same filter variation present.');
            end
            answer(2) = true;
            ans_adr{2} = samef(fltr);
            
            if rst
                % if so: checking for windowing/epoching
                % CHANGE - ADD epoch checks!
                wincheck = find(EEG.winlen == ICAbase(ans_adr{2}).winlen);
                
                if ~isempty(wincheck) && ~  filename_mod
                    if ~silent
                        disp('same window length.');
                    end
                    
                    answer(3) = true;
                    ans_adr{3} = ans_adr{2}(wincheck);
                    samerej = false(1,length(ans_adr{3}));
                    
                    % checking rejections:
                    for i = 1:length(ans_adr{3})
                        rejcheck(i) = mean(EEG.removed == ICAbase(ans_adr{3}(i)).removed); %#ok<AGROW>
                        if rejcheck(i) == 1; samerej(i) = true; end
                    end
                    
                    % if rejections are the same
                    if ~isempty(find(samerej,1))
                        if ~silent
                            disp('same windows/epochs rejected.');
                        end
                        check_icaw = true;
                        answer(4) = true;
                        ans_adr{4} = ans_adr{3}(samerej);
                    else
                        if ~silent
                            disp('different windows/epochs rejected.');
                        end
                    end
                    
                else
                    if ~silent
                        disp('different window length.');
                    end
                end
            end
        else
            if ~silent
                disp('different filter variation present.');
            end
        end
    end
else
    if ~silent
        disp('file not present in database.');
    end
end

% checking weights:
if check_icaw && rst % rst can be omitted here
    icas_to_check = ans_adr{4};
    for i = 1:length(icas_to_check)
        % checking if icaweights are present
        if ~isempty(ICAbase(icas_to_check(i)).icaweights)
            if ~silent
                disp('icaweights present');
            end
            answer(5) = true;
            if isfield(EEG.icaweights) && ~isempty(EEG.icaweights)
                % checking if icaweights are the same
                if isequal(ICAbase(icas_to_check(i)).icaweights,...
                        EEG.icaweights)
                    if ~silent
                        disp('icaweights are different...');
                    end
                    answer(6) = false;
                else
                    if ~silent
                        disp('icaweights are the same!');
                    end
                    answer(6) = true;
                end
                
            else
                if ~silent
                    disp('icaweights absent');
                end
                answer(5) = false;
            end
        end
    end
end

% alternatively:
% displaying info about number matching files and so on...
% not neccessary now