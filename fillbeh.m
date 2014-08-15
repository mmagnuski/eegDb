%%
function EEG=fillbeh(EEG, path)

if ismac
    path = '/Users/icacs/Dropbox/dane/S1 YOUNG/newans/';
end

maint = strcmp('DIN8', {EEG.event.type});
if  sum(maint)==120
    filname=regexp(EEG.filename, '[0-9]+', 'match');
    filname= filname{1};
    try
        dane= importdata([path, filname, '.dat']);
        dane = dane.textdata;
        cor = strcmp('correct',dane(1,:));
        rt=strcmp('latency',dane(1,:));
        inout=strcmp('trialcode',dane(1,:));
        dane(1:end-120,:)=[];
        if size(dane,1)==120
            maint = find(maint);
            for tr=1:length(maint)
                EEG.event(maint(tr)).correct=strcmp('1',dane{tr, cor});
                EEG.event(maint(tr)).rt=str2num(dane{tr, rt});
                EEG.event(maint(tr)).inout=strcmp('in', dane{tr, inout});
                EEG.event(maint(tr)).trial=tr;
            end
        else
            disp(EEG.filename);
            error('cos nie tak z tym plikiem 1')
        end
    catch error
        disp('No such file:')
        disp(EEG.filename)
    end
else
    disp(EEG.filename);
    error('cos nie tak z tym plikiem 2')
end