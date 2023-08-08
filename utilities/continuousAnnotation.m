classdef continuousAnnotation < annotation
    properties (Constant)
       annotType = "continuous" 
    end

    properties
        startFrame
        endFrame
    end

    methods (Static)
        function obj = default()
            obj = continuousAnnotation("Unnamed", 0, 1000);
        end

        function obj = from(annot)
            if annot.annotType == continuousAnnotation.annotType
                obj = annot;
                return;
            end

            % previous annot becomes a dud
            obj = continuousAnnotation.default;
            obj.name = annot.name;

            if (annot.parent ~= "Unassigned")
                annot.parent.removeChild(annot);
                annot.parent.addChild(obj);
            end

            obj.children = annot.children;
        end
    end

    methods
        function obj = continuousAnnotation(name, startFrame, endFrame)
            obj@annotation(name, [0 0 1]);

            obj.startFrame = startFrame;
            obj.endFrame = endFrame;
        end

        function record = getExportRecord(obj)
            record = strcat(",", obj.name, ",", string(obj.startFrame), ",", string(obj.endFrame));

            if ~isempty(obj.children)
                childrenRecords = strjoin(cellfun(@(child) child.getExportRecord, obj.children, 'UniformOutput', true), "");
                record = strcat(record, childrenRecords);
            end
        end

        function [sframe, eframe] = getPlaybackFrames(obj)
            sframe = obj.startFrame;
            eframe = obj.endFrame;
        end
        
        function res = isValid(obj)
            res = ( ...
                obj.startFrame <= obj.endFrame && ...
                1 <= obj.startframe && ...
                all(cellfun(@(child) child.isValid(), obj.children)));
        end
            
        function dist = distanceTo(obj, x, ~)
            dist = min(abs([obj.startFrame - x, obj.endFrame - x]));

            %% issue with y scale being magnitudes smaller than x
            % minx = pos(1); miny = pos(2); w = pos(3); h = pos(4);
            % maxx = minx + w; maxy = miny + h;
            % if (minx <= x && x <= maxx && miny <= y && y <= maxy)
            %     disp([minx miny; maxx maxy]);
            %     disp ([x, y]);
            %     dist = min(abs([minx - x, maxx -x, miny - y, maxy - y]));
            % else
            %     distX = max([minx - x, 0, x - maxx]);
            %     distY = max([miny - y, 0, y - maxy]);
            % 
            %     dist = hypot(distX, distY);
        end

        function json = getJson(obj)
            superStruct = jsondecode(getJson@annotation(obj));
            jsonStruct.name = superStruct.name;
            jsonStruct.startFrame = obj.startFrame;
            jsonStruct.endFrame = obj.endFrame;
            jsonStruct.annotType = obj.annotType;

            jsonStruct.children = cellfun(@(child) jsondecode(child.getJson()), ...
                obj.children, "UniformOutput", false);
 
            json = jsonencode(jsonStruct, PrettyPrint=true);
        end

        function clampOwnBounds(obj, startFrame, endFrame)
            obj.startFrame = basicReplayGrid.clamp(obj.startFrame, startFrame, endFrame);
            obj.endFrame = basicReplayGrid.clamp(obj.endFrame, startFrame, endFrame);

            cellfun(@(child) child.boundsResize(), obj.children);
        end

        function boundsResize(obj) 
            newStart = obj.parent.clampToBounds(obj.startFrame);
            newEnd = obj.parent.clampToBounds(obj.endFrame);

            if (newStart ~= obj.startFrame || newEnd ~= obj.endFrame)
                obj.startFrame = newStart;
                obj.endFrame = newEnd;

                cellfun(@(child) child.boundsResize(), obj.children);
                obj.updateAnnot();
            end
        end

        function clamped = clampToBounds(obj, x)
            clamped = basicReplay.clamp(x, obj.startFrame, obj.endFrame);
        end

        function result = containsFrame(obj, frame)
            result = (obj.startFrame <= frame && frame <= obj.endFrame);
        end

        function handleDrag(obj, newX)
            distToStart = abs(newX - obj.startFrame);
            distToEnd = abs(newX - obj.endFrame);

            if obj.startFrame == obj.endFrame
                if newX < obj.startFrame
                    obj.startFrame = newX;
                else
                    obj.endFrame = newX;
                end
            elseif distToStart < distToEnd
                obj.startFrame = newX;
            else
                obj.endFrame = newX;
            end
            
            obj.updateAnnot();
        end

        function updateAlpha(obj)
            if (obj.annot ~= "Unassigned")
                obj.annot.EdgeColor = [obj.colour, obj.alpha];
            end
        end

        function updateAnnot(obj)
            x = obj.startFrame;
            w = obj.endFrame - obj.startFrame;
            obj.annot.Position = [x obj.annot.Position(2) w obj.annot.Position(4)];
        end

        function drawAnnot(obj, axes, depth)
            cellfun(@(annot) drawAnnot(annot, axes, depth + 1), obj.children);

            if (obj.annot == "Unassigned")
                obj.annot = rectangle(axes, ...
                        "EdgeColor", [obj.colour, obj.alpha], ...
                        "Position", getPos(depth), ...
                        "LineWidth", 2);
            else
                updateAnnot(obj);
            end

            function pos = getPos(depth)
                x = obj.startFrame;
                y = depth / 10;
                w = obj.endFrame - obj.startFrame;
                h = 1 - 2 * y;

                pos = [x y w h];
            end
        end
        
        function setChildren(obj, children)
            obj.children = children;
            cellfun(@(node) node.setParent(obj), children);
        end

        function addChild(obj, child)
            if (isempty(obj.children))
                obj.children = {child};
            else
                obj.children{end+1} = child;
            end

            child.setParent(obj);
        end

        function removeChild(obj, toRemove)
            newChildren = cell(1, length(obj.children)-1);

            current = 1
            for i = 1:length(obj.children)
                child = obj.children{i};
                if child ~= toRemove
                    newChildren{current} = child;
                    current = current + 1;
                end
            end
            
            obj.children = newChildren;
        end
    end
end