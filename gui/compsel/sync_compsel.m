classdef sync_compsel < handle
    
    % sync_compsel allows to sync
    % compsel subguis (pop_prop windows)
    % with the main compsel window
    %
    % does not handle litening to guis (yet)
    % relies on being called from relevant callbacks
    
    properties
        figh
        subh
        colorcycle
        stateNames
    end
    
    
    methods (Access = public)
        
        function obj = sync_compsel(h)
            obj.figh = h;
            obj.subh = [];
            info = getappdata(h, 'info');
            obj.colorcycle = info.comps.colorcycle;
            obj.stateNames = info.comps.stateNames;
            addlistener(h, 'ObjectBeingDestroyed', @(o, e) obj.close_children());
        end
        
        function add(obj, h, cmp)
            % add subgui to syncing
            % assumes the subgui is pop_prop
            if isempty(obj.subh)
                obj.subh(1).h = h;
                obj.subh(1).cmp = cmp;
            elseif ~any([obj.subh.h] == h)
                    obj.subh(end + 1).h = h;
                    obj.subh(end).cmp = cmp;
            end
        end
        
        
        function chng_comp_status(obj, cmp)
            
            % get info
            [info, curr_stat, indcmp] = get_info_and_status(obj, cmp);
            
            % generate new state
            newstat = mod(curr_stat + 1, ...
                size(info.comps.colorcycle, 1));
            info.comps.state(indcmp) = newstat;
            setappdata(obj.figh, 'info', info);
            
            % change main gui
            % if given component is visible
            set_main_button(obj, cmp, newstat);
            
            set_sub_button(obj, cmp, newstat);
            
        end
        
        function set_main_button(obj, cmp, newstat)
            
            % get info
            [info, ~, indcmp] = get_info_and_status(obj, cmp);
            nbut   = info.comps.visible == indcmp;
            
            if ~isempty(nbut)
                h = getappdata(obj.figh, 'h');
                set_button_status(obj, h.button(nbut), newstat, false);
            end
        end
        
        function set_sub_button(obj, cmp, newstat)
            
            % check if subguis are registered
            if isempty(obj.subh)
                return
            end

            % look for subguis representing given component
            ifcmp = [obj.subh.cmp] == cmp;
            
            if any(ifcmp)
                cmph = obj.subh(ifcmp).h;
                setappdata(cmph, 'status', newstat);
                h = getappdata(cmph, 'h');
                set_button_status(obj, h.status, newstat, true);
            end
        end
        
        function update_sub_button(obj, cmp)
            
            % get info
            [~, curr_stat] = get_info_and_status(obj, cmp);
            % change status
            set_sub_button(obj, cmp, curr_stat);
            
        end

        function update_main_button(obj, cmp)
            
            % get info
            [~, curr_stat] = get_info_and_status(obj, cmp);
            % change status
            set_main_button(obj, cmp, curr_stat);
            
        end
        
        function clear_h(obj, h)
            
            % remove handle
            obj.subh([obj.subh.h] == h) = [];
        end


        function close_children(obj)
            
            len = length(obj.subh);
            tocls = false(1, len);
            for i = 1:len
                if ishandle(obj.subh(i).h)
                    tocls(i) = true;
                end
            end
            
            if any(tocls)
                close(obj.subh(tocls).h);
            end
        end
    end
    
    methods (Access = private)
        
        function [info, curr_stat, indcmp] = get_info_and_status(obj, cmp)
            
            info = getappdata(obj.figh, 'info');
            
            % check current status of cmp:
            indcmp    = find(info.comps.all == cmp);
            curr_stat = info.comps.state(indcmp);
        end
        
        function set_button_status(obj, but, stt, ifstr)
            
            set(but, 'backgroundcolor', ...
                obj.colorcycle(stt+1,:))
            
            if ifstr
                set(but, 'string', obj.stateNames{stt+1});
            end
            
        end
        
    end
end