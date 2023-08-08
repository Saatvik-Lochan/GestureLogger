classdef httpManager
    properties
        baseUrl
        token
    end

    methods (Static)
        function [obj, success] = register(baseUrl, name, password, description)
            request = struct( ...
                'project_name', name, ...
                'password', password, ...
                'description', description);
            url = strcat(baseUrl, "/project/register");

            [status, respData] = httpManager.postData(url, request);

            if status == matlab.net.http.StatusCode.Created
                success = true;
                obj = httpManager(baseUrl, respData.token);
            else
                success = false;
                obj = respData;
            end
        end

        function [obj, success] = fromLogin(baseUrl, name, password)
            request = struct( ...
                'project_name', name, ...
                'password', password);
            url = strcat(baseUrl, "/project/login");

            [status, respData] = httpManager.postData(url, request);

            if status == matlab.net.http.StatusCode.OK
                success = true;
                obj = httpManager(baseUrl, respData.token);
            else
                success = false;
                obj = respData;
            end
        end

        function [status, respData] = postData(url, body)
            import matlab.net.http.*
        
            packaged = MessageBody(body);
        
            r = RequestMessage(RequestMethod.POST, ...
                [HeaderField("Accept", "*/*"), ...
                 HeaderField("Content-Type", "application/json"), ...
                 HeaderField("Connection", "keep-alive")], ...
                 packaged);

            resp = send(r, url);
            status = resp.StatusCode;
            respData = resp.Body.Data;
        end
    
        function [status, respData] = getData(url)
            import matlab.net.http.*
        
            r = RequestMessage(RequestMethod.GET, ...
                [HeaderField("Accept", "*/*"), ...
                 HeaderField("Content-Type", "application/json"), ...
                 HeaderField("Connection", "keep-alive")]);

            resp = send(r, url);
            status = resp.StatusCode;
            respData = resp.Body.Data;
        end
    end

    methods

        function [success, shortCode] = getDemonstrationShortCode(obj, gid)
            reqUrl = strcat(obj.baseUrl, ...
                "/demonstration", ...
                "/get-shortcode", ...
                "/", string(gid), ...
                "?token=", obj.token);

            [status, shortCode] = httpManager.getData(reqUrl);
            success = status == matlab.net.http.StatusCode.OK;
        end

        function [success, urlCode] = getUrl(obj, pid)
            reqUrl = strcat(obj.baseUrl, ...
                "/participant", ...
                "/", string(pid), ...
                "/get-url", ...
                "?token=", obj.token);

            [status, urlCode] = httpManager.getData(reqUrl);
            success = status == matlab.net.http.StatusCode.OK;
        end

        function success = removeTrial(obj, pid, tiid)
            url = strcat(obj.baseUrl, ...
                "/participant/remove-trial");

            data = struct( ...
                'participant_id', string(pid), ...
                'trial_id', string(tiid), ...
                'token', obj.token);

            status = httpManager.postData(url, data);
            success = status == matlab.net.http.StatusCode.OK;
        end

        function [success, outfileLocation] = downloadGesture(obj, tiid, pid, gesture_index, fileLocation)
            try
                tiid = string(tiid);
                gesture_index = string(gesture_index);
                pid = string(pid);

                url = strcat(obj.baseUrl, ...
                    "/gesture-data/get-gesture/", pid, ... 
                    "/", tiid, ...
                    "/", gesture_index);
    
                saveLocation = fullfile(fileLocation, getFileName());
                outfileLocation = websave(saveLocation, url, "token", obj.token);
                disp(strcat("Downloaded file at ", outfileLocation));
                success = true;
            catch
                warning("problem downloading gesture from " + tiid + ", index: " + gesture_index);
                outfileLocation = "";
                success = false;
            end

            function filename = getFileName() 
                filename = strcat(tiid, "-", gesture_index, ".csv");
            end
        end

        function [success, trials] = getCompletedTrials(obj)
            url = strcat(obj.baseUrl, ...
                "/participant/get-completed-trials?token=", ...
                obj.token);

            [status, trials] = httpManager.getData(url);
            success = status == matlab.net.http.StatusCode.OK;
        end

        function success = pushTrial(obj, pid, trialStruct)
            data = struct( ...
                'participant_id', string(pid), ...
                'trial', trialStruct, ...
                'token', obj.token);

            url = strcat(obj.baseUrl, "/participant/push-trial");
            
            status = httpManager.postData(url, data);

            success = status == matlab.net.http.StatusCode.Created;
        end
    end

    methods
        function obj = httpManager(baseUrl, token)
            obj.baseUrl = baseUrl;
            obj.token = token;
        end
    end
end