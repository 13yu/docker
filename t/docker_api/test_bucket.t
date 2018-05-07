use Test::Nginx::Socket::Lua 'no_plan';
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
    lua_package_path  '$pwd/?.lua;/usr/local/s2/current/nginx/conf/lua/dep/?.lua;;';
    lua_package_cpath '/usr/local/s2/current/nginx/conf/lua/lib/?.so;;';
};

no_long_string();
$ENV{TEST_NGINX_ACCESS_KEY} = '"core2accesskey"';
$ENV{TEST_NGINX_SECRET_KEY} = '"jifiewjaifjiewajifjeiwajfijii"';
$ENV{TEST_NGINX_CORE2_PORT} = 7011;
run_tests();

__DATA__

=== TEST 1: test add and remove bucket
This test will add a new bucket, and then add the same bucket, and then add the same bucket
whit ignore == true,  and then remove that bucket twice.

--- http_config eval: $::HttpConfig
--- config
location = /t {
    rewrite_by_lua_block {
        math.randomseed(ngx.time() * 1000)
        local core2cli = require('core2cli')
        local cjson = require('cjson')
        local cli = core2cli.new({'127.0.0.1'},
                                 $TEST_NGINX_CORE2_PORT,
                                 $TEST_NGINX_ACCESS_KEY,
                                 $TEST_NGINX_SECRET_KEY)

        local params = {
            bucket_id=string.rep('1', 14) .. tostring(math.random(10000, 99999)),
            bucket='test-core2-bucket-' .. tostring(math.random(10000)),
            owner='renzhi',
            ts='1234',
        }

        local result, err, msg = cli:req('bucket', 'add', params)
        if err ~= nil then
            ngx.say('failed to add bucket: ' .. err .. '  ' .. msg)
        else
            ngx.say('affected_rows:' .. result.affected_rows)
        end

        local result, err, msg = cli:req('bucket', 'add', params)
        if err == nil then
            ngx.say('without setting ignore to true, should return error')
        else
            ngx.say(err)
        end

        local result, err, msg = cli:req('bucket', 'add', params, {ignore=true})
        if err ~= nil then
            ngx.say('failed to add bucket with ignore == true: ' .. err .. '  ' .. msg)
        else
            ngx.say('affected_rows:' .. result.affected_rows)
        end

        local result, err, msg = cli:req('bucket', 'remove', {bucket_id = params.bucket_id})
        if err ~= nil then
            ngx.say('failed to remove bucket: ' .. err .. '  ' .. msg)
        else
            ngx.say('affected_rows:' .. result.affected_rows)
        end

        local result, err, msg = cli:req('bucket', 'remove', {bucket_id = params.bucket_id})
        if err == nil then
            ngx.say('without setting ignore to true, should return error')
        else
            ngx.say(err)
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


=== TEST 2: test markdel and undel bucket
This test will markdel a inexistent bucket, and then add that bucket, and them markdel that bucket
twice, and then undel that bucket twice, and then remove that bucket.

--- http_config eval: $::HttpConfig
--- config
location = /t {
    rewrite_by_lua_block {
        math.randomseed(ngx.time() * 1000)
        local core2cli = require('core2cli')
        local cjson = require('cjson')
        local cli = core2cli.new({'127.0.0.1'},
                                 $TEST_NGINX_CORE2_PORT,
                                 $TEST_NGINX_ACCESS_KEY,
                                 $TEST_NGINX_SECRET_KEY)

        local params = {
            bucket_id=string.rep('1', 14) .. tostring(math.random(10000, 99999)),
            bucket='test-core2-bucket-' .. tostring(math.random(10000)),
            owner='renzhi',
            ts='1234',
        }

        local result, err, msg = cli:req('bucket', 'markdel', {bucket_id = params.bucket_id})
        if err == nil then
            ngx.say('without setting ignore to true, should return error')
        else
            ngx.say(err)
        end

        local result, err, msg = cli:req('bucket', 'add', params)
        if err ~= nil then
            ngx.say('failed to add bucket: ' .. err .. '  ' .. msg)
        else
            ngx.say('affected_rows:' .. result.affected_rows)
        end

        local result, err, msg = cli:req('bucket', 'markdel', {bucket_id = params.bucket_id})
        if err ~= nil then
            ngx.say('failed to markdel bucket: ' .. err .. '  ' .. msg)
        else
            ngx.say('affected_rows:' .. result.affected_rows)
        end

        local result, err, msg = cli:req('bucket', 'markdel', {bucket_id = params.bucket_id})
        if err ~= nil then
            ngx.say('failed to markdel bucket the second time: ' .. err .. '  ' .. msg)
        else
            ngx.say('affected_rows:' .. result.affected_rows)
        end

        local result, err, msg = cli:req('bucket', 'undel', {bucket_id = params.bucket_id})
        if err ~= nil then
            ngx.say('failed to undel bucket: ' .. err .. '  ' .. msg)
        else
            ngx.say('affected_rows:' .. result.affected_rows)
        end

        local result, err, msg = cli:req('bucket', 'undel', {bucket_id = params.bucket_id})
        if err ~= nil then
            ngx.say('failed to undel bucket the second time: ' .. err .. '  ' .. msg)
        else
            ngx.say('affected_rows:' .. result.affected_rows)
        end

        local result, err, msg = cli:req('bucket', 'remove', {bucket_id = params.bucket_id})
        if err ~= nil then
            ngx.say('failed to remove bucket: ' .. err .. '  ' .. msg)
        else
            ngx.say('affected_rows:' .. result.affected_rows)
        end
    }
}

--- request
GET /t

--- response_body
WriteIgnored
affected_rows:1
affected_rows:1
affected_rows:1
affected_rows:1
affected_rows:1
affected_rows:1

--- error_code: 200


=== TEST 3: test incr bucket
This test will incr a inexistent bucket, and then add that bucket, and them incr that bucket
with value 100, and then incr that bucket with value 0, and then get that bucket,
and then remove that bucket.

--- http_config eval: $::HttpConfig
--- config
location = /t {
    rewrite_by_lua_block {
        math.randomseed(ngx.time() * 1000)
        local core2cli = require('core2cli')
        local cjson = require('cjson')
        local cli = core2cli.new({'127.0.0.1'},
                                 $TEST_NGINX_CORE2_PORT,
                                 $TEST_NGINX_ACCESS_KEY,
                                 $TEST_NGINX_SECRET_KEY)

        local params = {
            bucket_id=string.rep('1', 14) .. tostring(math.random(10000, 99999)),
            bucket='test-core2-bucket-' .. tostring(math.random(10000)),
            owner='renzhi',
            ts='1234',
        }

        local result, err, msg = cli:req('bucket', 'incr', {bucket_id = params.bucket_id, space_used = 100})
        if err == nil then
            ngx.say('without setting ignore to true, should return error')
        else
            ngx.say(err)
        end

        local result, err, msg = cli:req('bucket', 'add', params)
        if err ~= nil then
            ngx.say('failed to add bucket: ' .. err .. '  ' .. msg)
        else
            ngx.say('affected_rows:' .. result.affected_rows)
        end

        local result, err, msg = cli:req('bucket', 'incr', {bucket_id = params.bucket_id, space_used = 100})
        if err ~= nil then
            ngx.say('failed to incr bucket: ' .. err .. '  ' .. msg)
        else
            ngx.say('affected_rows:' .. result.affected_rows)
        end

        local result, err, msg = cli:req('bucket', 'incr', {bucket_id = params.bucket_id, space_used = 0})
        if err ~= nil then
            ngx.say('failed to incr bucket with space_used == 0: ' .. err .. '  ' .. msg)
        else
            ngx.say('affected_rows:' .. result.affected_rows)
        end

        local result, err, msg = cli:req('bucket', 'getbyid', {bucket_id = params.bucket_id})
        if err ~= nil then
            ngx.say('failed to get bucket: ' .. err .. '  ' .. msg)
        else
            ngx.say(result.space_used)
        end

        local result, err, msg = cli:req('bucket', 'remove', {bucket_id = params.bucket_id})
        if err ~= nil then
            ngx.say('failed to remove bucket: ' .. err .. '  ' .. msg)
        else
            ngx.say('affected_rows:' .. result.affected_rows)
        end

    }
}
--- request

GET /t
--- response_body
WriteIgnored
affected_rows:1
affected_rows:1
affected_rows:1
100
affected_rows:1

--- error_code: 200


=== TEST 4: test list bucket
This test will add a bucket, and then list that bucket, and then  remove that bucket.

--- http_config eval: $::HttpConfig
--- config
location = /t {
    rewrite_by_lua_block {
        math.randomseed(ngx.time() * 1000)
        local core2cli = require('core2cli')
        local cjson = require('cjson')
        local cli = core2cli.new({'127.0.0.1'},
                                 $TEST_NGINX_CORE2_PORT,
                                 $TEST_NGINX_ACCESS_KEY,
                                 $TEST_NGINX_SECRET_KEY)

        local params = {
            bucket_id=string.rep('1', 14) .. tostring(math.random(10000, 99999)),
            bucket='test-core2-bucket-' .. tostring(math.random(10000)),
            owner='renzhi',
            ts='1234',
        }

        local result, err, msg = cli:req('bucket', 'add', params)
        if err ~= nil then
            ngx.say('failed to add bucket: ' .. err .. '  ' .. msg)
        else
            ngx.say('affected_rows:' .. result.affected_rows)
        end

        local result, err, msg = cli:req('bucket', 'ls', {bucket_id = params.bucket_id, nlimit = 1})
        if err ~= nil then
            ngx.say('failed to list bucket: ' .. err .. '  ' .. msg)
        else
            ngx.say(result[1].bucket_id == params.bucket_id)
        end

        local result, err, msg = cli:req('bucket', 'remove', {bucket_id = params.bucket_id})
        if err ~= nil then
            ngx.say('failed to remove bucket: ' .. err .. '  ' .. msg)
        else
            ngx.say('affected_rows:' .. result.affected_rows)
        end

    }
}
--- request

GET /t
--- response_body
affected_rows:1
true
affected_rows:1

--- error_code: 200


=== TEST 5: test add and get bucket
This test will add a new bucket, and then the bucket, and check all fields

--- http_config eval: $::HttpConfig
--- config
location = /t {
    rewrite_by_lua_block {
        math.randomseed(ngx.time() * 1000)
        local tableutil = require('acid.tableutil')
        local core2cli = require('core2cli')
        local cjson = require('cjson')
        local cli = core2cli.new({'127.0.0.1'},
                                 $TEST_NGINX_CORE2_PORT,
                                 $TEST_NGINX_ACCESS_KEY,
                                 $TEST_NGINX_SECRET_KEY)

        local params = {
            bucket_id=string.rep('1', 14) .. tostring(math.random(10000, 99999)),
            bucket='test-core2-bucket-' .. tostring(math.random(10000)),
            owner='renzhi',
            acl={user1={'READ', 'WRITE'}, user2={'FULL_CONTROL'}},
            redirect=123,
            relax_upload=1,
            cors={foo='bar'},
            conf={foo='bar'},
            serversidekey={foo='bar'},
            ts=123,
            is_del=1,
        }

        local result, err, msg = cli:req('bucket', 'add', params)
        if err ~= nil then
            ngx.say('failed to add bucket: ' .. err .. '  ' .. msg)
        else
            ngx.say('affected_rows:' .. result.affected_rows)
        end

        local result, err, msg = cli:req('bucket', 'getbyid', {bucket_id = params.bucket_id})
        if err ~= nil then
            ngx.say('failed to get bucket: ' .. err .. '  ' .. msg)
        else
            result.bucket = nil
            result.bucket_id = nil
            ngx.say(tableutil.str(result))
        end

        local result, err, msg = cli:req('bucket', 'remove', {bucket_id = params.bucket_id})
        if err ~= nil then
            ngx.say('failed to remove bucket: ' .. err .. '  ' .. msg)
        else
            ngx.say('affected_rows:' .. result.affected_rows)
        end

    }
}

--- request
GET /t

--- response_body
affected_rows:1
{acl={user1={READ,WRITE},user2={FULL_CONTROL}},conf={foo=bar},cors={foo=bar},is_del=1,num_del=0,num_down=0,num_up=0,num_used=0,owner=renzhi,redirect=123,relax_upload=1,serversidekey={foo=bar},space_del=0,space_down=0,space_up=0,space_used=0,ts=123}
affected_rows:1

--- error_code: 200
