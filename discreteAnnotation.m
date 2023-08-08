classdef discreteAnnotation < annotation
    properties (Constant)
        annotType = "discrete"
    end

    properties
        triggerFrame
        
    end

    methods (Static)
        function obj = default()
            obj = discreteAnnotation("Unnamed", 500);
        end

        function obj = from(annot)
            if annot.annotType == "discrete"
                obj = annot;
                return;
            end

            % previous annot becomes a dud
            obj = discreteAnnotation.default();
            obj.name = annot.name;

            if (annot.parent ~= "Unassigned")
                annot.parent.removeChild(annot);
                annot.parent.addChild(obj);
            end
        end
    end

    methods
        function obj = discreteAnnotation(name, triggerFrame)
            obj@annotation(name, [1 0 0]);
            obj.triggerFrame = triggerFrame;
        end

        function record = getExportRecord(obj)
            record = strcat(",", obj.name, ",", string(obj.triggerFrame));
        end

        function dist = distanceTo(obj, x, ~)
            dist = abs(obj.triggerFrame - x);
        end

        function [sframe, eframe] = getPlaybackFrames(obj)
            sframe = obj.triggerFrame;
            eframe = obj.triggerFrame;
        end
                

        function res = isValid(obj)
            res = 1 <= obj.triggerFrame;
        end

        function json = getJson(obj)
            superStruct = jsondecode(getJson@annotation(obj));
            jsonStruct.name = superStruct.name;
            jsonStruct.triggerFrame = obj.triggerFrame;
            jsonStruct.annotType = obj.annotType;

            json = jsonencode(jsonStruct, PrettyPrint=true);
        end

        function boundsResize(obj) 
            newTrigger = obj.parent.clampToBounds(obj.triggerFrame);
            
            if (newTrigger ~= obj.triggerFrame)
                obj.triggerFrame = newTrigger;
                obj.updateAnnot();
            end
        end

        function clampOwnBounds(obj, startFrame, endFrame)
            obj.triggerFrame = basicReplayGrid.clamp(obj.triggerFrame, startFrame, endFrame);
        end

        function clamped = clampToBounds(obj, ~)
            clamped = obj.triggerFrame;
        end

        function result = containsFrame(obj, frame)
            result = (obj.triggerFrame == frame);
        end

        function handleDrag(obj, newX)
            obj.triggerFrame = newX;
            obj.updateAnnot();
        end

        function updateAlpha(obj)
            if (obj.annot ~= "Unassigned")
                obj.annot.Alpha = obj.alpha;
            end
        end

        function updateAnnot(obj)
            obj.annot.Value = obj.triggerFrame;
        end

        function drawAnnot(obj, axes, ~)
            if (obj.annot == "Unassigned")
                obj.annot = xline(axes, obj.triggerFrame, ...
                    "Color", obj.colour, ...
                    "LineWidth", 2, ...
                    "Alpha", obj.alpha);
            else
                updateAnnot(obj);
            end
        end
    end
end