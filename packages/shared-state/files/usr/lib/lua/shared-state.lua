#!/usr/bin/lua

--! Minimalistic CRDT-like shared state structure suitable for mesh networks
--!
--! Copyright (C) 2019-2020  Gioacchino Mazzurco <gio@altermundi.net>
--!
--! This program is free software: you can redistribute it and/or modify
--! it under the terms of the GNU Affero General Public License version 3 as
--! published by the Free Software Foundation.
--!
--! This program is distributed in the hope that it will be useful,
--! but WITHOUT ANY WARRANTY; without even the implied warranty of
--! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--! GNU Affero General Public License for more details.
--!
--! You should have received a copy of the GNU Affero General Public License
--! along with this program.  If not, see <http://www.gnu.org/licenses/>.

local fs = require("nixio.fs")
local JSON = require("luci.jsonc")
local nixio = require("nixio")
local uci = require("uci")
local utils = require("lime.utils")

local shared_state = {}
shared_state.DATA_DIR = '/var/shared-state/data/'
shared_state.PERSISTENT_DATA_DIR = '/var/shared-state/persistent-data/'
shared_state.ERROR_LOCK_FAILED = 165

local SharedStateBase = {}

function SharedStateBase:load()
	for key, value in pairs(JSON.parse(self.storageFD:readall()) or {}) do
		self.storage[key] = value
	end
end

function SharedStateBase:lock(maxwait)
	if self.locked then return end
	maxwait = maxwait or 10

	fs.mkdirr(shared_state.DATA_DIR)
	self.storageFD = nixio.open(
		self.dataFile, nixio.open_flags("rdwr", "creat") )
		for i=1,maxwait do
			if not self.storageFD:lock("tlock") then
				nixio.nanosleep(1)
			else
				self.locked = true
				break
			end
		end
	if not self.locked then
		self.log( "err", self.dataFile, "Failed acquiring lock on data!" )
		os.exit(shared_state.ERROR_LOCK_FAILED)
	end
end

function SharedStateBase:merge(stateSlice)
	self:lock()
	self:load()
	self:_merge(stateSlice)
	self:save()
	self:unlock()
	self:notifyHooks()
end

function SharedStateBase:notifyHooks()
	if self.changed then
		local jsonString = self:toJsonString()
		if not fs.dir(self.hooksDir) then return end
		for hook in fs.dir(self.hooksDir) do
			local cStdin = io.popen(self.hooksDir.."/"..hook, "w")
			cStdin:write(jsonString)
			cStdin:close()
		end
	end
end

function SharedStateBase:save()
	if self.changed then
		local outFd = io.open(self.dataFile, "w")
		outFd:write(self:toJsonString())
		outFd:close()
		outFd = nil
	end
end

function SharedStateBase:httpRequest(url, body)
	local tmpfname = os.tmpname()

	local tmpfd = io.open(tmpfname, "w")
	tmpfd:write(body)
	tmpfd:close()
	tmpfd = nil

	local cmd = "uclient-fetch --no-check-certificate -q -O- --timeout=3 "
	cmd = cmd.."--post-file='"..tmpfname.."' '"..url.."' ; "
	cmd = cmd.."rm -f '"..tmpfname.."'"
	local fd = io.popen(cmd)

	local value = fd:read("*a")
	fd:close()

	return value
end

function SharedStateBase:_sync(urls)
	urls = urls or {}

	if #urls < 1 then
		local uci_cursor = uci:cursor()
		local fixed_candidates =
				uci_cursor:get("shared-state", "options","candidates") or {}
		for _, line in pairs(fixed_candidates) do
			table.insert(
				urls,
				line.."/"..self.dataType )
		end

		io.input(io.popen(arg[0].."-get_candidates_neigh"))
		for line in io.lines() do
			table.insert(
				urls,
				"http://["..line.."]/cgi-bin/shared-state/"..self.dataType )
		end
	end

	for _,url in ipairs(urls) do
		local body = self:toJsonString()

		local response = self:httpRequest(url, body)

		if type(response) == "string" and response:len() > 1  then
			local parsedJson = JSON.parse(response)
			if parsedJson then self:_merge(parsedJson) end
		else
			self.log( "debug", "error requesting "..url )
		end
	end
end

function SharedStateBase:sync(urls)
	self:lock()
	self:load()
	self:unlock()
	self:_sync(urls)
	self:lock()
	self:load() -- Take in account changes happened during sync
	self:save()
	self:unlock()
	self:notifyHooks()
end

function SharedStateBase:toJsonString()
	return JSON.stringify(self.storage)
end

function SharedStateBase:get()
	self:lock()
	self:load()
	self:unlock()
	return self.storage
end

function SharedStateBase:unlock()
	if not self.locked then return end
	self.storageFD:lock("ulock")
	self.storageFD:close()
	self.storageFD = nil
	self.locked = false
end

function createSharedStateBase(dataType, logger, dataFile)
	local logger = (type(logger) == "function") and logger or function() end
	local newInstance = {
		dataType = dataType,
		log = logger,
		--! Map<Key, {bleachTTL, author, data}>
		--!   bleachTTL is the count of how much bleaching should occur before the
		--!     entry expires
		--!   author is the name of the host who generated that entry
		--!   data is the value of the entry
		storage={},
		--! true if self_storage has changed after loading
		changed=false,
		-- File descriptor of the persistent file storage
		storageFD=nil,
		--! true when persistent storage file is locked by this instance
		locked=false,
		dataFile = dataFile,
		hooksDir = "/etc/shared-state/hooks/"..dataType.."/"
	}
	return newInstance
end

local SharedState = {}
setmetatable(SharedState, {__index = SharedStateBase})

function SharedState:new(dataType, logger)
	local dataFile = shared_state.DATA_DIR..dataType..".json"
	local newInstance = createSharedStateBase(dataType, logger, dataFile)
	setmetatable(newInstance, {__index = SharedState})
	return newInstance
end

function SharedState:_bleach()
	local substancialChange = false
	for k,v in pairs(self.storage) do
		if(v.bleachTTL < 2) then
			self.storage[k] = nil
			substancialChange = true
		else
			v.bleachTTL = v.bleachTTL-1
		end
		self.changed = true
	end
	return substancialChange
end

function SharedState:bleach()
	self:lock()
	self:load()
	local shouldNotify = self:_bleach()
	self:save()
	self:unlock()
	--! Avoid hooks being called if data hasn't substantially changed
	if(shouldNotify) then self:notifyHooks() end
end

function SharedState:_insert(key, data, bleachTTL)
	bleachTTL = bleachTTL or 30
	self.storage[key] = {
		bleachTTL=bleachTTL,
		author=io.input("/proc/sys/kernel/hostname"):read("*line"),
		data=data
	}
	self.changed = true
end

function SharedState:insert(data, bleachTTL)
	self:lock()
	self:load()
	for key, lv in pairs(data) do self:_insert(key, lv, bleachTTL) end
	self:save()
	self:unlock()
	self:notifyHooks()
end

function SharedState:_merge(stateSlice)
	local stateSlice = stateSlice or {}
	for key,rv in pairs(stateSlice) do
		if rv.bleachTTL <= 0 then
			self.log( "debug", "sharedState:merge got expired entry" )
			self.changed = true
		else
			local lv = self.storage[key]
			if( lv == nil or lv.bleachTTL < rv.bleachTTL ) then
				self.log( "debug", "Updating entry for: "..key.." older: "..
						  (lv and lv.bleachTTL or 'no entry').." newer: "..rv.bleachTTL )
				self.storage[key] = rv
				self.changed = true
			end
		end
	end
end

function SharedState:_remove(key)
	if(self.storage[key] ~= nil and self.storage[key].data ~= nil)
	then self:_insert(key, nil) end
end

function SharedState:remove(keys)
	self:lock()
	self:load()
	for _,key in ipairs(keys) do self:_remove(key) end
	self:save()
	self:unlock()
	self:notifyHooks()
end


local SharedStatePersistent = {}
setmetatable(SharedStatePersistent, {__index = SharedStateBase})

function SharedStatePersistent:new(dataType, logger)
	local dataFile = shared_state.PERSISTENT_DATA_DIR..dataType..".json"
	local newInstance = createSharedStateBase(dataType, logger, dataFile)
	setmetatable(newInstance, {__index = SharedStatePersistent})
	return newInstance
end

function SharedStatePersistent:_merge(stateSlice)
	-- Make merge based on timestamp
	local stateSlice = stateSlice or {}
	for key,rv in pairs(stateSlice) do
		local lv = self.storage[key]
		if ( lv == nil or lv.lastModified < rv.lastModified ) then
			self.log( "debug", "Updating entry for: "..key.." older: "..
					  (lv and lv.lastModified or 'no entry') .." newer: "..rv.lastModified )
			self.storage[key] = rv
			self.changed = true
		end
	end
end

function SharedStatePersistent:insert(data)
	self:lock()
	self:load()
	for key, lv in pairs(data) do self:_insert(key, lv) end
	self:save()
	self:unlock()
	self:notifyHooks()
end

function SharedStatePersistent:_insert(key, data)
	local lv = self.storage[key]
	if (lv == nil or not utils.deepcompare(lv.data, data)) then
		self.storage[key] = {
			lastModified=os.time(),
			author=io.input("/proc/sys/kernel/hostname"):read("*line"),
			data=data
		}
		self.changed = true
	end	
end

shared_state.SharedState = SharedState
shared_state.SharedStatePersistent = SharedStatePersistent
return shared_state
