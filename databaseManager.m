classdef databaseManager < handle

    properties
        conn
        isNewDb = false
    end

    methods  % get
        % get different types
        function trialStruct = getTrialStruct(obj, tiid)
            
            sqlquery = strcat( ...
                "SELECT t.tid, t.name, t.instructions ", ...
                "FROM trial_instance as ti ", ...
                "JOIN trial_template as t on ti.tid = t.tid ", ...
                "WHERE ti.tiid = ", tiid);

            trial = table2struct(obj.conn.fetch(sqlquery));

            if isempty(trial)
                trialStruct = [];
                return
            end

            trialStruct.trial_id = tiid;
            trialStruct.trial_name = trial.name;
            trialStruct.instructions = trial.instructions;

            sqlquery = strcat( ...
                "SELECT g.gid, g.name, tg.instruction, tg.duration, tg.repetitions ", ...
                "FROM trial_gesture as tg ", ...
                "JOIN gesture_class as g on tg.gid = g.gid ", ...
                "WHERE tg.tid = ", string(trial.tid), " ",...
                "ORDER BY tg.pos");

            gestures = table2struct(obj.conn.fetch(sqlquery));
            allGestures = cell(1, sum([gestures.repetitions]));
            allGesturesIndex = 1;

            for index = 1:numel(gestures)
                gesture = gestures(index);

                for gestureRep = 1:gesture.repetitions
                    gestureStruct.gesture_id = string(gesture.gid);
                    gestureStruct.gesture_name = gesture.name;
                    gestureStruct.instruction = gesture.instruction;
                    gestureStruct.duration = gesture.duration;

                    allGestures{allGesturesIndex} = gestureStruct;
                    allGesturesIndex = allGesturesIndex + 1;
                end
            end

            trialStruct.gestures = allGestures;
        end

        % aggregate gets
        function attrs = getAllAttributesOfAllCompleteGestureInstances(obj)
            sqlquery = strcat(...
                "SELECT ", ...
                "gc.name as gesture_name, ", ...
                "tt.name as trial_name, ", ...
                "gi.giid, ", ...
                "gi.gid, ", ...
                "gi.tiid, ", ...
                "tt.tid, ", ...
                "tg.pos, ", ...
                "ti.pid, ", ...
                "tg.instruction, ", ...
                "tg.repetitions, ", ...
                "tg.duration ", ...
                "FROM gesture_instance as gi ", ...
                "JOIN gesture_class as gc on gi.gid = gc.gid ", ...
                "JOIN trial_instance as ti on gi.tiid = ti.tiid ", ...
                "JOIN trial_template as tt on ti.tid = tt.tid ", ...
                "JOIN trial_gesture as tg on gi.gid = tg.gid ", ...
                "JOIN gesture_annotation as ga on gi.giid = ga.giid ", ...
                "WHERE ga.status == 'complete'");

            attrs = obj.conn.fetch(sqlquery);
        end

        function gestureInstances = getGestureInstances(obj)
            sqlquery = strcat( ...
                "SELECT gc.name, ti.pid, gi.giid, COALESCE(ga.status, 'unannotated') as annotStatus ", ...
                "FROM gesture_instance as gi ", ...
                "LEFT JOIN gesture_annotation as ga on gi.giid = ga.giid ", ...
                "JOIN trial_instance as ti on gi.tiid = ti.tiid ", ...
                "JOIN gesture_class as gc on gi.gid = gc.gid");

            gestureInstances = obj.conn.fetch(sqlquery);
        end

        function gestureInstances = getInstancesOfGesture(obj, gid)
            sqlquery = strcat( ...
                "SELECT gi.giid, ti.pid, COALESCE(ga.status, 'unannotated') as status ", ...
                "FROM gesture_instance as gi ", ...
                "LEFT JOIN gesture_annotation as ga on gi.giid = ga.giid ", ...
                "JOIN trial_instance as ti on gi.tiid = ti.tiid ", ...
                "WHERE gi.gid = ", string(gid));

            gestureInstances = obj.conn.fetch(sqlquery);
        end

        function gestureInstances = getGesturesOfParticipant(obj, pid)
            sqlquery = strcat( ...
                "SELECT gc.name, gi.giid, COALESCE(ga.status, 'unannotated') as status ", ...
                "FROM gesture_instance as gi ", ...
                "LEFT JOIN gesture_annotation as ga on gi.giid = ga.giid ", ...
                "JOIN gesture_class as gc on gi.gid = gc.gid ", ...
                "JOIN trial_instance as ti on gi.tiid = ti.tiid ", ...
                "WHERE ti.pid = ", pid);

            gestureInstances = obj.conn.fetch(sqlquery);
        end

        function trials = getTrialsOfParticipant(obj, pid)
            sqlquery = strcat( ...
                "SELECT ti.tiid, t.name, ti.status ", ...
                "FROM participant as p ", ...
                "JOIN trial_instance as ti on p.pid = ti.pid ", ...
                "JOIN trial_template as t on ti.tid = t.tid ", ...
                "WHERE p.pid = ", pid);
            trials = obj.conn.fetch(sqlquery);
        end

        function gestures = getGesturesOfTrial(obj, id)
            sqlquery = strcat("SELECT tg.pos as pos, g.name, tg.instruction, tg.duration, tg.repetitions ", ...
                "FROM trial_gesture as tg ", ...
                "JOIN gesture_class as g on tg.gid = g.gid ", ...
                "WHERE tg.tid = ", id, " ",...
                "ORDER BY tg.pos");
            gestures = obj.conn.fetch(sqlquery);
            gestures.Properties.RowNames = string(gestures{:, "pos"});
            gestures = removevars(gestures, "pos");
        end

        function [gids, pid, repetitions] = getGestureInfoInTrialInstance(obj, tiid)
            sqlquery = strcat( ...
                "SELECT tg.gid, ti.pid, tg.repetitions ", ...
                "FROM trial_instance as ti ", ...
                "JOIN trial_gesture as tg on ti.tid = tg.tid ", ...
                "WHERE ti.tiid = ", tiid, " ", ...
                "ORDER BY tg.pos");
            result = obj.conn.fetch(sqlquery);

            try
                pid = result{1, 'pid'};
                gids = result{:, 'gid'};
                repetitions = result{:, 'repetitions'};
            catch
                warning("Attempting to get gestures of a nonexistent trial instance");
                pid = 0;
                gids = {};
            end
        end

        function tiids = getUnpushedTrialInstances(obj)
            sqlquery = strcat( ...
                "SELECT tiid ", ...
                "FROM trial_instance ", ...
                "WHERE status = 'unpushed'");
            data = obj.conn.fetch(sqlquery);
            tiids = string(data{:, 'tiid'});
        end


        % get cell from id
        function [val, exists] = getCell(obj, id_name, id_val, table, field)
            sqlquery = strcat("SELECT ", field, " FROM ", table, " WHERE ", id_name, " = ", id_val);
            data = obj.conn.fetch(sqlquery);
        
            try
                val = data{1, 1};
                exists = true;
            catch
                val = [];
                exists = false;
            end
        end

        function file = getDataFileOfGiid(obj, giid)
            file = obj.getCell("giid", string(giid), "gesture_instance", "data_file");
        end

        function gid = getGidOfGiid(obj, giid)
            gid = obj.getCell("giid", string(giid), "gesture_instance", "gid");
        end

        function [exists, annotFile] = getAnnotFile(obj, giid)
            [annotFile, exists] = obj.getCell("giid", string(giid), "gesture_annotation", "annot_file");
        end

        function pid = getPidFromTiid(obj, tiid)
            pid = obj.getCell("tiid", tiid, "trial_instance", "pid");
        end

        function tid = getTidFromTiid(obj, tiid)
            tid = obj.getCell("tiid", tiid, "trial_instance", "tid");
        end

        function json = getGestureJson(obj, gid)
            json = obj.getCell("gid", string(gid), "gesture_class", "json");
        end

        function info = getParticipantInfo(obj, pid)
            info = obj.getCell("pid", pid, "participant", "info");
        end

        % get row from id
        function vals = getRowWithId(obj, id_name, id_val, table)
            sqlquery = strcat("SELECT * FROM ", table, " WHERE ", id_name, " = ", id_val);
            data = obj.conn.fetch(sqlquery);

            vals = table2struct(data);
        end

        function trial = getTrialFromId(obj, id)
            trial = obj.getRowWithId("tid", id, "trial_template");
        end

        function trialInstance = getTrialInstanceFromId(obj, tiid)
            trialInstance = obj.getRowWithId("tiid", tiid, "trial_instance");
        end

        % 'get all' functions
        function vals = getAll(obj, fields, table)
            
            sqlquery = strcat("SELECT ", strjoin(fields, ","), " FROM ", table);

            data = obj.conn.fetch(sqlquery);
            vals = data{:, fields};
        end

        function ids = getParticipantIds(obj)
            ids = string(obj.getAll("pid", "participant"));
        end

        function [ids, names] = getIdsAndNames(obj, id_name, table)
            vals = obj.getAll([id_name, "name"], table);  
            
            if (isempty(vals))
                ids = {}; names = {};
            else
                ids = vals(:, 1); names = string(vals(:, 2));
            end
        end

        function [tids, names] = getTemplateIdsAndNames(obj)
            [tids, names] = obj.getIdsAndNames("tid", "trial_template");
        end

        function [gids, names] = getAllGestureIdsAndNames(obj)
            [gids, names] = obj.getIdsAndNames("gid", "gesture_class");
        end
    end

    methods  % set / add / update
        % add
        function addParticipant(obj)
            data = table("", 'VariableNames', {'info'});
            obj.conn.sqlwrite("participant", data);
        end

        function addGesture(obj, name, json)
            row = {name, json};
            data = cell2table(row,'VariableNames', {'name', 'json'});
            obj.conn.sqlwrite("gesture_class", data);
        end

        function addGestureInstance(obj, tiid, gid, data_file)
            row = {gid, tiid, data_file};
            data = cell2table(row,'VariableNames', {'gid', 'tiid', 'data_file'});
            obj.conn.sqlwrite("gesture_instance", data);
        end

        function addTrialToParticipant(obj, pid, tid)
            % update trial_instance
            data = table( ...
                tid, pid, "unpushed", ...
                'VariableNames', ...
                {'tid', 'pid', 'status'});
            obj.conn.sqlwrite("trial_instance", data);
        end

        function addGestureToTrial(obj, gid, tid)
            posData = obj.conn.fetch("SELECT COALESCE(MAX(pos), 0) FROM trial_gesture");
            pos = posData{1, 1} + 1;
            data = table(tid, gid, pos, " ", 5, 1, " ", 'VariableNames', ...
                {'tid', 'gid', 'pos', 'instruction', 'duration', 'repetitions', 'options_json'});
            obj.conn.sqlwrite("trial_gesture", data);
        end

        function addTrialTemplate(obj)
            obj.conn.sqlwrite("trial_template", ...
                table("Unnamed template", "Instructions here", false, 'VariableNames', ...
                {'name', 'instructions', 'is_generated'}));
        end

        function addGestureAnnotation(obj, giid, fileLocation)
            obj.conn.sqlwrite("gesture_annotation", ...
                table(giid, fileLocation, "incomplete", 'VariableNames', ...
                {'giid', 'annot_file', 'status'}));
        end

        % update
        function updateTextField(obj, table, keyField, keyValue, field, value)
            sqlquery = strcat("UPDATE ", table, ...
                " SET ", field, " = '", value, ...
                "' WHERE ", keyField, " = ", keyValue);
            obj.conn.execute(sqlquery);
        end

        function updateNumField(obj, table, keyField, keyValue, field, value)
            sqlquery = strcat("UPDATE ", table, ...
                " SET ", field, " = ", value, ...
                " WHERE ", keyField, " = ", keyValue);
            obj.conn.execute(sqlquery);
        end
        
        function updateGestureInTrial(obj, tid, pos, field, value)
            basequery = strcat("UPDATE trial_gesture", ...
                " SET ", field, " = ");

            if field == "instruction"
                query = strcat(basequery, ...
                    "'", value, "'");
            else  % repetitions, instruction, gid
                query = strcat(basequery, ...
                    string(value));
            end

            query = strcat(query, " WHERE tid = ", tid, " and pos = ", pos);
            obj.conn.execute(query);
        end

        function updateGesture(obj, gid, name, json)
            updateThisGestureField("name", name);
            updateThisGestureField("json", json);

            function updateThisGestureField(field, value)
                obj.updateTextField("gesture_class", "gid", gid, field, value);
            end
        end

        function updateTrialName(obj, tid, newName)
            obj.updateTextField("trial_template", "tid", tid, "name", newName);
        end
    
        function updateGestureAnnotationStatus(obj, giid, status)
            obj.updateTextField("gesture_annotation", "giid", string(giid), "status", status);
        end

        function updateTrialInstructions(obj, tid, newInstructions)
            instructions = strjoin(newInstructions, newline);
            obj.updateTextField("trial_template", "tid", tid, "instructions", instructions);
        end
   
        function updateTrialInstanceStatus(obj, tiid, status)
            obj.updateTextField("trial_instance", "tiid", tiid, "status", status);
        end
    
        function updateParticipantInfo(obj, pid, info)
            obj.updateTextField("participant", "pid", pid, "info", info);
        end
    end

    methods  % deletion
        % assumes ids are integers
        function deleteRowWithId(obj, table, id_name, id_value)
            sqlquery = strcat( ...
                "DELETE FROM ", table, " ",...
                "WHERE ", id_name, " = ", id_value);
            obj.conn.execute(sqlquery);
        end

        function deleteParticipant(obj, pid)
            deleteRowWithId(obj, "participant", "pid", pid);
        end

        function deleteGestureFromTrial(obj, tid, pos)
            sqlquery = strcat( ...
                "DELETE FROM trial_gesture ",...
                "WHERE tid = ", tid, " and pos = ", pos);
            obj.conn.execute(sqlquery);
        end

        function deleteGesture(obj, gid)
            obj.deleteRowWithId("gesture_class", "gid", gid);
        end
    end

    methods  % utility
        function lastId = getLastIdOfTable(obj, table)
            sqlquery = strcat( ...
                "SELECT seq FROM sqlite_sequence ", ...
                "WHERE name = '", table, "'");
            lastIdData = obj.conn.fetch(sqlquery);
            lastId = lastIdData{1, 1};
        end
    end

    methods  % db management
        function obj = databaseManager(dbFile)
            try 
                obj.conn = sqlite(dbFile);
            catch 
                obj.conn = sqlite(dbFile, "create");
                obj.initDb();
            end
        end

        function initDb(obj)
            % create all tables

            sqlqueries = { 
                strcat("CREATE TABLE participant (", ...                 
                            "pid INTEGER PRIMARY KEY AUTOINCREMENT, ", ...
                            "info TEXT)"), ...
                strcat("CREATE TABLE trial_instance(", ...
                            "tiid INTEGER PRIMARY KEY AUTOINCREMENT, ", ...
                            "tid INTEGER, ", ...
                            "pid INTEGER, ", ...
                            "status TEXT)"), ...
                strcat("CREATE TABLE gesture_instance(", ...
                            "giid INTEGER PRIMARY KEY AUTOINCREMENT, ", ...
                            "gid INTEGER, ", ...
                            "tiid INTEGER, ", ...
                            "data_file TEXT)"), ...
                strcat("CREATE TABLE gesture_annotation(", ...
                            "giid INTEGER PRIMARY KEY AUTOINCREMENT, ", ...
                            "annot_file TEXT, ", ...
                            "status TEXT)"), ...
                strcat("CREATE TABLE trial_template(", ...
                            "tid INTEGER PRIMARY KEY AUTOINCREMENT, ", ...
                            "name TEXT, ", ...
                            "instructions TEXT, ", ...
                            "is_generated INTEGER)"), ...
                strcat("CREATE TABLE gesture_class(", ...
                            "gid INTEGER PRIMARY KEY AUTOINCREMENT, ", ...
                            "name TEXT, ", ...
                            "json TEXT)"), ...
                strcat("CREATE TABLE trial_gesture(", ...
                            "tid INTEGER, ", ...
                            "pos INTEGER, ", ...
                            "gid INTEGER, ", ...
                            "duration REAL, ", ...
                            "instruction TEXT, ", ...
                            "repetitions INT, ", ...
                            "options_json, ", ...
                            "PRIMARY KEY(tid, pos))")...
            };



            obj.isNewDb = true;
            cellfun(@(command) obj.conn.execute(command), sqlqueries);

        end

        function delete(obj)
            close(obj.conn);
        end
    end
end