classdef (Abstract) gestureAnnotation < handle
    % ANNOTATION a class to facilitiate annotations

    properties
        name
        children = {}
        colour
        isVisible = false
        alpha = 0.25
        annot = "Unassigned"
        parent = "Unassigned"
        hasParent = false
    end

    methods
        function obj = gestureAnnotation(name, colour)
            obj.name = name;
            obj.colour = colour;
        end

        function setVisibility(obj, value)
            if (obj.annot ~= "Unassigned")
                obj.annot.Visible = value;

                if (obj.parent ~= "Unassigned" && value)
                    obj.parent.setVisibility(true);
                end
            end
        end

        function setParent(obj, parent)
            obj.parent = parent;
            obj.hasParent = true;
        end

        function setSelected(obj, isSelected)
            if isSelected
                obj.alpha = 1;
            else
                obj.alpha = 0.25;
            end

            obj.updateAlpha();
        end

        function delete(obj)
            cellfun(@(child) child.delete(), obj.children);

            if obj.annot ~= "Unassigned"
                obj.annot.delete();
            end

            if obj.parent ~= "Unassigned"
                obj.parent.removeChild(obj);
            end
        end

        function drag(obj, newX)
            if obj.annot == "Unassigned" || ~obj.annot.Visible 
                return;
            end
    
            % ensure you can not drag out of bounds
            if (obj.hasParent)
                newX = obj.parent.clampToBounds(newX);
            end

            obj.handleDrag(newX);

            % make children conform to new bounds
            cellfun(@(child) child.boundsResize(), obj.children);
        end
        
        function json = getJson(obj)
            json = jsonencode(struct("name", obj.name, "colour", obj.colour), ...
                "PrettyPrint", true);
        end
    end

    methods (Abstract, Static)
        obj = from(annot)
        obj = default()
    end

    methods (Abstract)
        res = isValid(obj)
        dist = distanceTo(obj, x, y)
        boundsResize(obj)
        clampOwnBounds(obj)
        result = containsFrame(obj, newX)
        clamped = clampToBounds(obj, x)
        updateAlpha(obj)
        handleDrag(obj, newX)
        drawAnnot(obj, axes, depth)
        [sframe, eframe] = getPlaybackFrames(obj)
        record = getExportRecord(obj)
    end
end