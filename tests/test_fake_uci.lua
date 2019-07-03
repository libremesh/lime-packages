local libuci = require "uci"

describe("Fake uci tests", function()
    it("test simple get and set", function()

        uci = libuci:new_cursor()

        assert.is_nil(uci:get('foo'))

        uci:set('foo', 1)
        assert.is.equal(1, uci:get('foo'))
    end)

    it("test multiple cursors", function()

        uci = libuci:cursor()

        assert.is_nil(uci:get('foo'))

        uci:set('foo', 1)
        assert.is.equal(1, uci:get('foo'))

        uci = libuci:cursor()
        assert.is.equal(1, uci:get('foo'))

        uci = libuci:new_cursor(true)
        assert.is_nil(uci:get('foo'))

    end)

    it("test nested get and set", function()
        uci = libuci:new_cursor()

        assert.is_nil(uci:get('foo', 'bar'))

        uci:set('foo', 'bar', 'value')
        assert.is.equal('value', uci:get('foo', 'bar'))

        uci:set('foo', 'bar', 'value2')
        assert.is.equal('value2', uci:get('foo', 'bar'))

        uci:set('foo', 'bar', 'baz', 'othervalue')
        assert.is.equal('othervalue', uci:get('foo', 'bar', 'baz'))

        uci:set('foo', 'tree2', 2)
        assert.is.equal(2, uci:get('foo', 'tree2'))
    end)

    it("test state not preserved between tests", function()
        uci = libuci:new_cursor()
        assert.is_nil(uci:get('foo'))
    end)

    it("test save", function()
        uci = libuci:new_cursor()
        uci.save()
    end)

    it("test delete", function()
        uci = libuci:new_cursor()

        uci:set('foo', 'bar1', 'value1')
        uci:set('foo', 'bar2', 'value2')
        assert.is.equal('value1', uci:get('foo', 'bar1'))
        assert.is.equal('value2', uci:get('foo', 'bar2'))

        uci:delete('foo', 'bar1')

        assert.is_nil(uci:get('foo', 'bar1'))
        assert.is.equal('value2', uci:get('foo', 'bar2'))
    end)

    it("test foreach", function()
        uci = libuci:new_cursor()

        uci:set('type', 'elem1', {})
        uci:set('type', 'elem2', {})
        uci:set('type', 'elem3', {})
        outs = {}
        uci.foreach('type', function(e) table.insert(outs, e[".name"]) end)

        assert.is.equal('elem1', outs[1])
        assert.is.equal('elem2', outs[2])
        assert.is.equal('elem3', outs[3])
    end)

    it("test get_all", function()
        uci = libuci:new_cursor()

        uci:set('type', 'elem1', 1)
        uci:set('type', 'elem2', 2)
        uci:set('type', 'elem3', 3)
        assert.is.equal(1, uci:get_all('type').elem1)
        assert.is.equal(2, uci:get_all('type').elem2)
        assert.is.equal(3, uci:get_all('type').elem3)
    end)
end)
