classdef Scheduler < handle
    
    
    properties ( Access = private )
        running          % currently running function
        isrunning        % if something is running
        runningField     % name of the field executed
        locked           % if something on waiting list is
        gotFinishedSignal% 
        waitingList      %
    end
    
    
    methods (Access = private)
        
        function placeOnTrack(obj) 
            obj.locked(1) = [];
            obj.isrunning = true;
            obj.running = obj.waitingList(1);
            obj.gotFinishedSignal = false;
            obj.waitingList(1) = [];
            obj.runningField   = 'pre';
        end
        
        function internalRun(obj)
            % if field pre or post --> run
            % if field run --> run only if no waiting
            
            f = strcmp(obj.runningField, {'pre', 'run', 'post'});
            
            if any(f([1, 3]))
                if femp(obj.running, obj.runningField)
                    feval(obj.running.(obj.runningField){:});
                end
                    
                if f(1)
                    obj.runningField = 'run';
                    internalRun(obj);
                    
                else
                    clearTask(obj);
                end
            end
            
            if f(2) && femp(obj.running, obj.runningField)
                if ~waiting(obj)
                    currentID = obj.running.id;
                    feval(obj.running.(obj.runningField){:});
                    % waits for finish signal
                    if ~isempty(obj.running) && ...
                            obj.running.id == currentID && ...
                            ~obj.gotFinishedSignal
                        finished(obj);
                    end
                else
                    clearTask(obj);
                end
            end
        end
           
        % clearTask
        % clears up (isrunning = false) and calls run if some are waiting
        function clearTask(obj)
            obj.running = [];
            obj.isrunning = false;
            obj.runningField   = [];
            obj.gotFinishedSignal = false;
            if waiting(obj)
                run(obj)
            end
        end
        
    end
    
    
    methods (Access = public)
        
        function obj = Scheduler
            obj.running = [];
            obj.runningField = [];
            obj.isrunning = false;
            obj.locked = [];
            obj.waitingList = [];
        end
        
        function add( obj, fld, fun )
            if isempty(obj.waitingList)
                s.(fld) = fun;
                s.id    = rand(1);
                obj.waitingList = s;
                obj.locked      = false;
            else
                if obj.locked(end)
                    obj.locked(end + 1) = false;
                    obj.waitingList(end + 1).(fld) = fun;
                    obj.waitingList(end).id = rand(1);
                else
                    obj.waitingList(end).(fld) = fun;
                end
            end
        end
        
        function close(obj)
            notlckd = find(~obj.locked);
            
            if ~isempty(notlckd)
                obj.locked(notlckd(1)) = true;
            end
        end
        
        function run(obj)
            
            if ~obj.isrunning && ~isempty(obj.waitingList) ...
                    && obj.locked(1)
                placeOnTrack(obj);
                internalRun(obj);
            end
        end        
        
        % finishSignal        
        function finished(obj)
            obj.gotFinishedSignal = true;
            obj.runningField = 'post';
            internalRun(obj);
        end
        
        function c = waiting(obj)
            c = ~isempty(obj.waitingList) && any(obj.locked);
        end
    end
end