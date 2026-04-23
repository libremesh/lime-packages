--! Unit tests for URL encoding/decoding utilities in voucher/utils.lua
--! Tests the pure Lua implementation that replaces lucihttp

local utils = require('voucher.utils')

-- Override log function for tests
function utils.log(...)
    print(...)
end

describe('URL utilities #urlutils', function()

    describe('urlencode', function()
        it('returns nil for nil input', function()
            assert.is_nil(utils.urlencode(nil))
        end)

        it('does not encode unreserved characters (RFC 3986)', function()
            -- Unreserved: A-Z a-z 0-9 - _ . ~
            assert.is.equal('abcXYZ', utils.urlencode('abcXYZ'))
            assert.is.equal('0123456789', utils.urlencode('0123456789'))
            assert.is.equal('-_.~', utils.urlencode('-_.~'))
        end)

        it('encodes spaces as %20', function()
            assert.is.equal('hello%20world', utils.urlencode('hello world'))
            assert.is.equal('%20%20%20', utils.urlencode('   '))
        end)

        it('encodes special characters', function()
            assert.is.equal('%40', utils.urlencode('@'))
            assert.is.equal('%23', utils.urlencode('#'))
            assert.is.equal('%24', utils.urlencode('$'))
            assert.is.equal('%26', utils.urlencode('&'))
            assert.is.equal('%3D', utils.urlencode('='))
            assert.is.equal('%3F', utils.urlencode('?'))
            assert.is.equal('%2F', utils.urlencode('/'))
            assert.is.equal('%3A', utils.urlencode(':'))
        end)

        it('encodes complex URLs', function()
            local url = 'http://example.com/path?a=1&b=2'
            local encoded = utils.urlencode(url)
            assert.is.equal('http%3A%2F%2Fexample.com%2Fpath%3Fa%3D1%26b%3D2', encoded)
        end)

        it('converts numbers to strings', function()
            assert.is.equal('123', utils.urlencode(123))
        end)

        it('encodes unicode characters', function()
            -- UTF-8 bytes get encoded
            local encoded = utils.urlencode('café')
            assert.is_not_nil(encoded)
            assert.is_true(encoded:find('%%') ~= nil)
        end)
    end)

    describe('urldecode', function()
        it('returns nil for nil input', function()
            assert.is_nil(utils.urldecode(nil))
        end)

        it('decodes percent-encoded sequences', function()
            assert.is.equal('@', utils.urldecode('%40'))
            assert.is.equal('#', utils.urldecode('%23'))
            assert.is.equal('/', utils.urldecode('%2F'))
            assert.is.equal(':', utils.urldecode('%3A'))
            assert.is.equal('?', utils.urldecode('%3F'))
            assert.is.equal('=', utils.urldecode('%3D'))
            assert.is.equal('&', utils.urldecode('%26'))
        end)

        it('decodes spaces encoded as %20', function()
            assert.is.equal('hello world', utils.urldecode('hello%20world'))
        end)

        it('decodes plus signs as spaces', function()
            assert.is.equal('hello world', utils.urldecode('hello+world'))
        end)

        it('handles mixed encoding', function()
            assert.is.equal('a b+c', utils.urldecode('a+b%2Bc'))
        end)

        it('handles lowercase hex digits', function()
            assert.is.equal(' ', utils.urldecode('%20'))
            assert.is.equal(' ', utils.urldecode('%2a'):gsub('%*', ' ') or utils.urldecode('%2a'))
        end)

        it('decodes complex URLs', function()
            local encoded = 'http%3A%2F%2Fexample.com%2Fpath%3Fa%3D1%26b%3D2'
            local decoded = utils.urldecode(encoded)
            assert.is.equal('http://example.com/path?a=1&b=2', decoded)
        end)

        it('leaves unencoded strings unchanged', function()
            assert.is.equal('hello', utils.urldecode('hello'))
            assert.is.equal('test123', utils.urldecode('test123'))
        end)
    end)

    describe('urlencode/urldecode roundtrip', function()
        it('roundtrips simple strings', function()
            local original = 'hello world'
            -- Note: urlencode uses %20, urldecode handles both %20 and +
            assert.is.equal(original, utils.urldecode(utils.urlencode(original)))
        end)

        it('roundtrips URLs', function()
            local original = 'http://example.com/path?a=1&b=2'
            assert.is.equal(original, utils.urldecode(utils.urlencode(original)))
        end)

        it('roundtrips special characters', function()
            local original = 'email@example.com'
            assert.is.equal(original, utils.urldecode(utils.urlencode(original)))
        end)
    end)

    describe('urldecode_params', function()
        it('returns empty table for nil input', function()
            local params = utils.urldecode_params(nil)
            assert.is.same({}, params)
        end)

        it('parses simple key=value pairs', function()
            local params = utils.urldecode_params('a=1&b=2')
            assert.is.equal('1', params.a)
            assert.is.equal('2', params.b)
        end)

        it('parses URL with query string', function()
            local params = utils.urldecode_params('http://example.com?foo=bar&baz=qux')
            assert.is.equal('bar', params.foo)
            assert.is.equal('qux', params.baz)
        end)

        it('decodes URL-encoded keys and values', function()
            local params = utils.urldecode_params('key%20name=value%20data')
            assert.is.equal('value data', params['key name'])
        end)

        it('decodes plus signs as spaces in values', function()
            local params = utils.urldecode_params('msg=hello+world')
            assert.is.equal('hello world', params.msg)
        end)

        it('handles empty values', function()
            local params = utils.urldecode_params('key=')
            assert.is.equal('', params.key)
        end)

        it('handles keys without values', function()
            local params = utils.urldecode_params('key')
            assert.is.equal('', params.key)
        end)

        it('supports semicolon as separator', function()
            local params = utils.urldecode_params('a=1;b=2')
            assert.is.equal('1', params.a)
            assert.is.equal('2', params.b)
        end)

        it('supports mixed separators', function()
            local params = utils.urldecode_params('a=1&b=2;c=3')
            assert.is.equal('1', params.a)
            assert.is.equal('2', params.b)
            assert.is.equal('3', params.c)
        end)

        it('handles multiple values for same key', function()
            local params = utils.urldecode_params('key=val1&key=val2')
            assert.is.same({'val1', 'val2'}, params.key)
        end)

        it('uses provided table as base', function()
            local base = {existing = 'value'}
            local params = utils.urldecode_params('new=data', base)
            assert.is.equal('value', params.existing)
            assert.is.equal('data', params.new)
        end)

        it('parses voucher query strings correctly', function()
            -- Real-world use case from pirania
            local qs = 'voucher=secret_code&prev=http%3A%2F%2Fexample.com%2F'
            local params = utils.urldecode_params(qs)
            assert.is.equal('secret_code', params.voucher)
            assert.is.equal('http://example.com/', params.prev)
        end)

        it('parses complex prev URLs', function()
            -- Test case from existing test_cgi_handlers.lua
            local original_url = 'http://original.url/baz?a=1&b=2'
            local encoded_url = utils.urlencode(original_url)
            local qs = 'voucher=code&prev=' .. encoded_url
            local params = utils.urldecode_params(qs)
            assert.is.equal('code', params.voucher)
            assert.is.equal(original_url, params.prev)
        end)
    end)

end)
