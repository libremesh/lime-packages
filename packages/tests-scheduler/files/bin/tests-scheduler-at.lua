#!/usr/bin/lua

local JSON = require("luci.jsonc")
local utils = require("lime.utils")
local fs = require("nixio.fs")
local libuci = require("uci")

result = libuci:cursor():get("tests-scheduler","probe",option)
local function config_uci_get(sectionname, option)
	local result
	result = libuci:cursor():get("tests-scheduler",sectionname,option)
	return result
end

local dataFile = arg[1] or config_uci_get("probe","data_file")
local peakHooksDir = arg[2] or config_uci_get("at","peak_hooks_dir")
local nightHooksDir = arg[3] or config_uci_get("at","night_hooks_dir")


-- check if a file exists
function file_exists(file)
	local f = io.open(file, "rb")
	if f then f:close() end
	return f ~= nil
end

-- get all lines from a file, returns an empty 
-- list/table if the file does not exist
function lines_from_tonumber(file)
	if not file_exists(file) then return {} end
	local lines = {}
	for line in io.lines(file) do 
		lines[#lines + 1] = tonumber(line) or "missing"
	end
	return lines
end

local function do_split(str,pat)
	local tbl = {}
	str:gsub(pat, function(x) tbl[#tbl+1]=x end)
	return tbl
end

local function max(t)
	if #t == 0 then return nil, nil end
	local key, value = 1, tonumber(t[1])
	for i = 2, #t do
		temp = tonumber(t[i])
		if value < temp then
			key, value = i, temp
		end
	end
    return key, value
end

local function min(t)
	if #t == 0 then return nil, nil end
	local key, value = 1, tonumber(t[1])
	for i = 2, #t do
		temp = tonumber(t[i])
		if value > temp then
			key, value = i, temp
		end
	end
    return key, value
end

local data = lines_from_tonumber(dataFile)

for _,val in pairs(data) do
	if val == "missing" then
		io.stderr:write("Data from at least one whole day is needed in "..
		  dataFile..", stopping.\n")
		os.exit(1)
	end
end

io.stderr:write("Found enough data in "..dataFile..", continuing.\n")

local peakHour1,_ = max(data)
local peakHour = peakHour1 - 1

local peakDirFun = fs.dir(peakHooksDir) or {}
local peakIndex = 0
for hook in fs.dir(peakHooksDir) do
	local peakMinute = (peakIndex * 5) % 60
	local peakMinutePad = string.format("%02d", peakMinute)
	local peakAt = "echo '"..peakHooksDir.."/"..hook.."' | at -Mv "..peakHour..":"..
	  peakMinutePad.." 2>&1"
	local handlePeakAt = io.popen(peakAt, 'r')
	local peakAtRaw = handlePeakAt:read("*a")
	handlePeakAt:close()
	local peakAtTime = do_split(peakAtRaw,"%C+")[1]
	utils.log("Scheduled time:\t"..peakAtTime.."\tCommand:\t"..peakHooksDir.."/"..hook)
	peakIndex = peakIndex + 1
end

local nightDirFun = fs.dir(nightHooksDir) or {}
if not nightDirFun(1) then
	io.stderr:write("No tests configured to be run at the night time.\n")
	os.exit(0)
end
local nightDirFun = fs.dir(nightHooksDir) or {}

local datatemp = data
local nightHours = {}

for i = 1,6 do
	nightHour1,_ = min(datatemp)
	nightHours[i] = nightHour1 - 1
	datatemp[nightHour1] = math.huge
end

local getCommand = "shared-state get tests-scheduler-night"
local handleAllTimesJson = io.popen(getCommand, "r")
local allTimesJson = handleAllTimesJson:read("*a")
handleAllTimesJson:close()
local allTimes = {}
for _,value in pairs(JSON.parse(allTimesJson)) do
	allTimes[#allTimes + 1] = tonumber(value.data)
end

local hitsHours = {0,0,0,0,0,0}
for _,val in pairs(allTimes) do
	for i = 1,6 do
		local valHourFract = val / 60
		local valHour = valHourFract - (valHourFract % 1)
		if valHour == nightHours[i] then
			hitsHours[i] = hitsHours[i] + 1
			break
		end
	end
end

local minHourIndex,_ = min(hitsHours)
local nightHour = nightHours[minHourIndex]

local hits5minute = {0,0,0,0,0,0,0,0,0,0,0,0}
for _,val in pairs(allTimes) do
	local valHourFract = val / 60
	local valHour = valHourFract - (valHourFract % 1)
	if valHour == nightHour then
		local val5minuteFract = (val % 60) / 5
		local val5minute = val5minuteFract - (val5minuteFract % 1)
		hits5minute[val5minute + 1] = hits5minute[val5minute + 1] + 1
	end
end

local min5minute1,_ = min(hits5minute)
local min5minute = min5minute1 - 1
local nightMinute = min5minute * 5
local myTime = nightHour * 60 + nightMinute 
local myTimeTable = {}
local hostname = io.input("/proc/sys/kernel/hostname"):read("*line")
myTimeTable[hostname] = myTime
local handle = io.popen("shared-state insert tests-scheduler-night", "w")
handle:write(JSON.stringify(myTimeTable))
handle:close()

local nightIndex = 0
for hook in nightDirFun do
	local nightMinuteIdx = (nightMinute + nightIndex) % 60
	local nightMinuteIdxPad = string.format("%02d", nightMinuteIdx)
	local nightAt = "echo '"..nightHooksDir.."/"..hook.."' | at -Mv "..nightHour..":"..
	  nightMinuteIdxPad.." 2>&1"
	local handleNightAt = io.popen(nightAt, 'r')
	local nightAtRaw = handleNightAt:read("*a")
	handleNightAt:close()
	local nightAtTime = do_split(nightAtRaw,"%C+")[1]
	utils.log("Scheduled time:\t"..nightAtTime.."\tCommand:\t"..nightHooksDir.."/"..hook)
	nightIndex = nightIndex + 1
end
