local utils = require 'lime.utils'
local test_utils = require 'tests.utils'
local shared_state = require 'shared-state'

local test_dir

describe('LiMe Utils tests #sharedstate', function()
    it('test load a new and empty db', function()
        shared_state.DATA_DIR = test_dir
        local sharedState = shared_state.SharedState:new('foo')
        local data = sharedState:get()
        assert.are.same({}, data)
    end)

    before_each('', function()
        test_dir = test_utils.setup_test_dir()
        shared_state.DATA_DIR = test_dir
    end)

    after_each('', function()
        test_utils.teardown_test_dir()
    end)

    it('test insert new data to empty db', function()
        local sharedState = shared_state.SharedState:new('foo')
        sharedState:insert({ bar = 'foo', baz = 'qux' })
        local db = sharedState:get()
        assert.is.equal('foo', db.bar.data)
        assert.is.equal('qux', db.baz.data)
    end)

    it('test remove data', function()
        local sharedState = shared_state.SharedState:new('foo')
        sharedState:insert({ bar = 'foo' })
        sharedState:remove({'bar'})
        local db = sharedState:get()
        assert.is_nil(db.bar.data)
    end)

    it('test two instances with different dataTypes are independent', function ()
        local a = shared_state.SharedState:new('A')
        a:insert({ bar = 'foo' })
        local b = shared_state.SharedState:new('B')
        b:insert({ baz = 'qux' })
        local a_db = a:get()
        assert.is.equal('foo', a_db.bar.data)
        assert.is.equal(nil, a_db.baz)
        local b_db = b:get()
        assert.is.equal('qux', b_db.baz.data)
        assert.is.equal(nil, b_db.bar)
    end)

    it('test two instances with the same dataType have the same data', function ()
        local a = shared_state.SharedState:new('foo')
        a:insert({ bar = 'foo' })
        local b = shared_state.SharedState:new('foo')
        b:insert({ baz = 'qux' })
        local a_db = a:get()
        assert.is.equal('foo', a_db.bar.data)
        assert.is.equal('qux', a_db.baz.data)
        local b_db = b:get()
        assert.is.equal('qux', b_db.baz.data)
        assert.is.equal('foo', b_db.bar.data)
    end)

    it('test data is removed if bleachTTL reaches 0', function ()
        local sharedState = shared_state.SharedState:new('foo')
        sharedState:insert({ bar = 'foo' }, 1)
        assert.is.equal('foo', sharedState:get().bar.data)
        sharedState:bleach()
        assert.is.equal(nil, sharedState:get().bar)
    end)

    it('test merge data from remote db with bigger ttl', function()
        local sharedStateA = shared_state.SharedState:new('A')
        local sharedStateB = shared_state.SharedState:new('B')
        sharedStateA:insert({ bar = 'foo', baz = 'qux', zig = 'zag'})
        sharedStateA:bleach()
        sharedStateB:insert({ zig = 'very_old_zag'})
        sharedStateB:bleach()
        sharedStateB:bleach()
        sharedStateB:insert({ bar = 'new_foo', baz = 'new_qux' })
        sharedStateA:merge(sharedStateB:get())
        local dbA = sharedStateA:get()
        assert.is.equal(dbA.bar.data, 'new_foo')
        assert.is.equal(dbA.baz.data, 'new_qux')
        assert.is.equal(dbA.zig.data, 'zag')
    end)

    it('test same process locks dont lock but  #locks', function()
        shared_state.DATA_DIR = test_dir
        local sharedStateA = shared_state.SharedState:new('foo')
        assert.is_false(sharedStateA.locked)
        sharedStateA:lock()
        assert.is_true(sharedStateA.locked)
        -- locks in the same process don't lock
        local sharedStateB = shared_state.SharedState:new('foo')
        sharedStateB:lock()
        assert.is_true(sharedStateB.locked)

        -- but for other process it does lock
        script = [[#!/usr/bin/lua
        shared_state = require('shared-state')
        shared_state.DATA_DIR = ']] .. test_dir .. [['
        ss = shared_state.SharedState:new('foo')
        maxwait_s = 0
        ss:lock(maxwait_s)
        ]]
        local f = io.open(test_dir .. "script.lua", "w")
        f:write(script)
        f:close()

        local exit_code = utils.unsafe_shell("lua "..test_dir .. "script.lua; echo -n $?")
        assert.equal(shared_state.ERROR_LOCK_FAILED, tonumber(exit_code))

    end)

end)
