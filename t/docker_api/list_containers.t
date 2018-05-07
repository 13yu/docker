use Test::Nginx::Socket::Lua 'no_plan';
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
    lua_package_path  '$pwd/lib/?.lua;;';
};

no_long_string();
run_tests();

__DATA__

=== TEST 1: test list containers
This test will test the list containers docker api

--- http_config eval: $::HttpConfig
--- config
location = /t {
    rewrite_by_lua_block {
        local docker_api = require('resty.docker.docker_api')

        local resp, err, errmsg = docker_api:list_containers()
        if err ~= nil then
            ngx.say('error:' .. err .. ' ' .. errmsg)
        else
            ngx.say(resp)
        end

    }
}
--- request
GET /t

--- response_body
affected_rows:1
WriteIgnored
affected_rows:0
affected_rows:1
WriteIgnored

--- error_code: 200
