
local http = require('resty.http')
local docker_util = require('resty.docker.docker_util')
local json = require('cjson.safe')

local _M = {
    _VERSION = '0.0.1'
}

local mt = {
    __index = _M
}

local function request_dockerd(self, method, uri, opts)
    opts = opts or {}
    local httpc = http.new()
    httpc:set_timeout(500)

    if self.dockerd_ip ~= nil then
        httpc:connect(self.dockerd_ip, self.dockerd_port)
    else
        httpc:connect('unix:/var/run/docker.sock')
    end

    local headers = opts.headers or {}
    if headers['Host'] == nil then
        headers['Host'] = 'http'
    end

    local http_request = {
        method = method,
        path = uri,
        headers = headers,
        body = opts.body or '',
    }

    local http_resp, err = httpc:request(http_request)
    if err ~= nil then
        return nil, 'RequestDockerdError', string.format(
                'failed to request docker deamon http api: %s', err)
    end

    local http_resp_body, err = http_resp:read_body()
    if err ~= nil then
        return nil, 'RequestDockerdError', string.format(
                'failed to read response body: %s', err)
    end

    local resp = {
        status = http_resp.status,
        headers = http_resp.headers,
        body = http_resp_body,
    }

    return resp, nil, nil
end

function _M.list_images(self)
    local resp, err, errmsg = request_dockerd(self, 'GET', '/images/json')
    if err ~= nil then
        return nil, err, errmsg
    end

    local json_value, err = json.decode(resp.body)
    if err ~= nil then
        return nil, 'RequestDockerdError', string.format(
                'failed to json decode response body: %s, %s',
                tostring(resp.body), err)
    end

    return json_value, nil, nil
end

function _M.list_containers(self)
    local resp, err, errmsg = request_dockerd(self, 'GET', '/containers/json')
    if err ~= nil then
        return nil, err, errmsg
    end

    local json_value, err = json.decode(resp.body)
    if err ~= nil then
        return nil, 'RequestDockerdError', string.format(
                'failed to json decode response body: %s, %s',
                tostring(resp.body), err)
    end

    return json_value, nil, nil

end


function _M.create_container(self, container)
    local body, err, errmsg = docker_util.json_encode(container)
    if err ~= nil then
        return nil, err, errmsg
    end

    local resp, err, errmsg = request_dockerd('POST', '/containers/create', {body=body})
    if err ~= nil then
        return nil, err, errmsg
    end

    local result, err, errmsg = parse_create_container_resp(resp)
    if err ~= nil then
        return nil, err, errmsg
    end

    return result, nil, nil
end


function _M.new(opts)
    opts = opts or {}

    local self = {
        dockerd_unix_sock = 'unix:/var/run/docker.sock',
    }

    if opts.dockerd_ip ~= nil then
        if type(opts.dockerd_ip) ~= 'string' then
            return nil, 'InvalidArgument', string.format(
                    'the dockerd_ip: %s is not a string',
                    tostring(opts.dockerd_ip))
        end

        if type(opts.dockerd_port) ~= 'number' then
            return nil, 'InvalidArgument', string.format(
                    'the dockerd_port: %s is not a number',
                    tostring(dockerd_port))
        end

        self.dockerd_ip = opts.dockerd_ip
        self.dockerd_port = opts.dockerd_port
    end

    if opts.dockerd_unix_sock ~= nil then
        if type(opts.dockerd_unix_sock) ~= 'string' then
            return nil, 'InvalidArgument', string.format(
                    'the dockerd_unix_sock: %s is not a string',
                    tostring(opts.dockerd_unix_sock))
        end

        self.dockerd_unix_sock = opts.dockerd_unix_sock
    end

    return setmetatable(self, mt)

end

return _M
