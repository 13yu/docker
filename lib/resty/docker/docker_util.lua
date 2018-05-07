local cjson_safe = require('cjson.safe')


local _M = {}


function _M.json_encode(value)
    local json_text, err = cjson_safe.encode(value)
    if err ~= nil then
        return nil, 'JsonEncodeError',
                string.format('json encode error: %s', err)
    end

    return json_text, nil, nil
end


function _M.json_encode(json_text)
    local value, err = cjson_safe.decode(json_text)
    if err ~= nil then
        return nil, 'JsonDecodeError',
                string.format('json decode error: %s', err)
    end

    return value, nil, nil
end


return _M
