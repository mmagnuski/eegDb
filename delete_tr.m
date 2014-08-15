% deleting training session in Sternberg
% input:
%
% EEG       - EEG structure;
% event     - event for the end of training sesion (string)
% false     - if you do not want to delete anything (optional)
%
% exBEFIN (optional output) = latency of exp. begining.
%
%use:
%     delete_tr(EEG, event);
%     [EEG, expBEFIN]=delete_tr(EEG, 'DI64');
%     delete_tr(EEG,event, false)
%%
function [EEG, expBEFIN]=delete_tr(EEG, event,varargin)

perform=true;
if nargin>2
   perform=varargin{:};
end

if perform
    
    laten=[EEG.event.latency];
    expBEFIN=laten(strmatch(event, {EEG.event.type})); %#ok<MATCH2>
    if length(expBEFIN)==1
        EEG = pop_select(EEG,'nopoint',[1 expBEFIN]);
    else
        EEG = pop_select(EEG,'nopoint',[1 expBEFIN(2)]);
        expBEFIN(1)=[];
    end
end
