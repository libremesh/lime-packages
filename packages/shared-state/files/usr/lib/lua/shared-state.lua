#!/usr/bin/lua
--! SPDX-License-Identifier: AGPL-3.0-only
--!
--! Copyright (C) 2019  Gioacchino Mazzurco <gio@altermundi.net>

--! Minimalistic CRDT-like shared state structure suitable for mesh networks

local fs = require("nixio.fs")
local JSON = require("luci.jsonc")
local nixio = require("nixio")
local uci = require("uci")
local utils = require("lime.utils")

local shared_state = {}
shared_state.DATA_DIR = '/var/shared-state/data/'
shared_state.PERSISTENT_DATA_DIR = '/etc/shared-state/persistent-data/'
shared_state.ERROR_LOCK_FAILED = 165
shared_state.CANDIDATE_NEIGHBORS_BIN = '/usr/bin/shared-state-get_candidates_neigh'

local SharedStateBase = {}

function SharedStateBase:load(mergeWithCurrentState)
	local onDiskData = JSON.parse(self.storageFD:readall()) or {}
	if mergeWithCurrentState then
		self:_merge(onDiskData)
	else
		for key, value in pairs(onDiskData) do
			self.storage[key] = value
		end
	end
end

function SharedStateBase:lock(maxwait)
	if self.locked then return end
	maxwait = maxwait or 10
	fs.mkdirr(fs.dirname(self.dataFile))
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

		io.input(io.popen(shared_state.CANDIDATE_NEIGHBORS_BIN))
		for line in io.lines() do
			table.insert(
				urls,
				self:getSyncUrl(line, self.dataType))
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
	self:load(true) -- Take in account changes happened during sync
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
		--! File descriptor of the persistent file storage
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

function SharedState:getSyncUrl(host)
	return "http://["..host.."]/cgi-bin/shared-state/"..self.dataType
end


local SharedStateMultiWriter = {}
setmetatable(SharedStateMultiWriter, {__index = SharedStateBase})

function SharedStateMultiWriter:new(dataType, logger)
	local dataFile = shared_state.PERSISTENT_DATA_DIR..dataType..".json"
	local newInstance = createSharedStateBase(dataType, logger, dataFile)
	setmetatable(newInstance, {__index = SharedStateMultiWriter})
	return newInstance
end


function SharedStateMultiWriter:_merge(stateSlice)
	--! Make merge based on an incremental counter (changes) and a random number (fortune)
	local stateSlice = stateSlice or {}
	for key,rv in pairs(stateSlice) do
		local lv = self.storage[key]
		if ( lv == nil or lv.changes < rv.changes or
			 ( lv.changes == rv.changes and lv.fortune < rv.fortune )) then
			self.log( "debug", "Updating entry for: "..key.." older: "..
					  (lv and lv.changes or 'no entry') .." newer: "..rv.changes )
			self.storage[key] = rv
			self.changed = true
		end
	end
end

function SharedStateMultiWriter:insert(data)
	self:lock()
	self:load()
	for key, lv in pairs(data) do self:_insert(key, lv) end
	self:save()
	self:unlock()
	self:notifyHooks()
end

function shared_state._getFortune()
	return math.random(1, 100000)
end

function SharedStateMultiWriter:_insert(key, data)
	local lv = self.storage[key]
	if (lv == nil or not utils.deepcompare(lv.data, data)) then
		local changes = lv and lv.changes + 1 or 0
		self.storage[key] = {
			lastModified=os.time(),
			changes=changes,
			fortune=shared_state._getFortune(),
			author=io.input("/proc/sys/kernel/hostname"):read("*line"),
			data=data
		}
		self.changed = true
	end
end

function SharedStateMultiWriter:getSyncUrl(host)
	return "http://["..host.."]/cgi-bin/shared-state-multiwriter/"..self.dataType
end

shared_state.SharedState = SharedState
shared_state.SharedStateMultiWriter = SharedStateMultiWriter
return shared_state
