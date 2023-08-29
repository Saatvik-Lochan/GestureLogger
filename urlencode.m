function urlOut = urlencode(urlIn)
%URLENCODE Replace special characters with escape characters URLs need

% Copyright 1984-2022 The MathWorks, Inc.

arguments
    urlIn {mustBeText}
end

urlOut = "";

urlIn = char(urlIn);
for i = 1:length(urlIn)
    if strcmp(urlIn(i), ' ')
        urlOut = urlOut.append('+');
    elseif (isSafeCharacter(urlIn(i)))
        urlOut = urlOut.append(urlIn(i));
    else
        decChars = unicode2native(urlIn(i), 'UTF-8');
        hexChars = dec2hex(decChars, 2);
        for j = 1:size(hexChars,1)
            urlOut = urlOut.append('%').append(hexChars(j,:));
        end
    end
end

urlOut = char(urlOut);
end

function safe = isSafeCharacter(c)
safe = ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ...
     || (c >= '0' && c <= '9') || strcmp(c, '-') || strcmp(c, '_') ... 
     || strcmp(c, '.') || strcmp(c, '*'));
end