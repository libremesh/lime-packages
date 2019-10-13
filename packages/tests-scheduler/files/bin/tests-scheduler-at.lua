#!/usr/bin/lua

local JSON = require("luci.jsonc")

local libuci_loaded, libuci = pcall(require, "uci")

local function config_uci_get(option)
	local result
	if libuci_loaded then
		result = libuci:cursor():get("tests-scheduler","at",option)
	else
		result = nil
	end
	return result
end

local peakTestsList = config_uci_get("peak_test") or {arg[1]}

local nightTestsList = config_uci_get("night_test") or {arg[2]}

local dataFile = config_uci_get("data_file") or "/tmp/tests-scheduler-probe-data"

-- see if the file exists
function file_exists(file)
	local f = io.open(file, "rb")
	if f then f:close() end
	return f ~= nil
end

-- get all lines from a file, returns an empty 
-- list/table if the file does not exist
function lines_from(file)
	if not file_exists(file) then return {} end
	local lines = {}
	for line in io.lines(file) do 
		lines[#lines + 1] = line
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

local data = lines_from(dataFile)
local complete = true
for _,val in pairs(data) do
	if not tonumber(val) then
		complete = false
		break
	end
end

if complete then
	io.stderr:write("Found enough data in "..dataFile..", continuing.\n")
	local peakHour1,_ = max(data)
	local peakHour = peakHour1 - 1
	for _,peakCommand in pairs(peakTestsList) do
		local peakAt = "echo '"..peakCommand.."' | at -Mv "..peakHour..":30 2>&1"
		local handlePeakAt = io.popen(peakAt, 'r')
		local peakAtRaw = handlePeakAt:read("*a")
		handlePeakAt:close()
		local peakAtTime = do_split(peakAtRaw,"%C+")[1]
		print("Scheduled time:\t"..peakAtTime.."\tCommand:\t"..peakCommand)
	end
	if nightTestsList then
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
				local val5minute = 1 + int((val%60)/5)
				hits5minute[val5minute] = hits5minute[val5minute] + 1
			end
		end

		local min5minute1,_ = min(hits5minute)
		local min5minute = min5minute1 - 1
		local nightMinute = min5minute * 5 + math.random(0,4)
		local myTime = nightHour * 60 + nightMinute 
		local myTimeTable = {}
		local hostname = io.input("/proc/sys/kernel/hostname"):read("*line")
		myTimeTable[hostname] = myTime
		io.popen("shared-state insert tests-scheduler-night", "w"):write(JSON.stringify(myTimeTable))
		for index,nightCommand in ipairs(nightTestsList) do
			local nightMinuteIdx = nightMinute + index - 1
			local nightMinuteIdxPad = string.format("%02d", nightMinuteIdx)
			local nightAt = "echo '"..nightCommand.."' | at -Mv "..nightHour..":"..
			  nightMinuteIdxPad.." 2>&1"
			local handleNightAt = io.popen(nightAt, 'r')
			local nightAtRaw = handleNightAt:read("*a")
			handleNightAt:close()
			local nightAtTime = do_split(nightAtRaw,"%C+")[1]
			print(nightAtTime.."\t"..nightCommand)
		end
	end
else
	io.stderr:write("Data from at least one whole day is needed in "..dataFile..", stopping.\n")
	os.exit(1)
end


