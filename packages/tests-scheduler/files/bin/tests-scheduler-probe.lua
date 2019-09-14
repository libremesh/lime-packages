#!/usr/bin/lua

local libuci_loaded, libuci = pcall(require, "uci")

local function config_uci_get(option)
	local result
	if libuci_loaded then
		result = libuci:cursor():get("tests-scheduler","probe",option)
	else
		result = nil
	end
	return result
end

local defaultTestsList = {
			"ip neigh show nud reachable",
			"ping6 -n -c 2 ff02::1%br-lan",
			"batctl tl"
			}

local temp = config_uci_get("test")
local testsList = type(temp) == "table" and temp or defaultTestsList

-- stability indicates how much of the previous measurement data
-- (which could be from the previous day) is going to be considered
-- 0 means that just the very last is used, avoid using 1
-- consider that more than one measurement is performed each hour
local stability = tonumber(config_uci_get("stability")) or 0.9

local dataFile = config_uci_get("data_file") or "/tmp/tests-scheduler-probe-data"

local function do_test(test)
	io.stderr:write("Command: "..test.."\n")
	local handle = io.popen(test, 'r')
	local output = handle:read("*a")
	handle:close()
	local _,count = output:gsub('\n', '\n')
	return count
end

local function do_sum(arr, length)
	return length == 1 and arr[1] or arr[length] + do_sum(arr, length -1)
end

local function do_tests_serie()
	local results = {}
	local i = 1
	while testsList[i] do
		local test = tostring(testsList[i])
		local testResult = tonumber(do_test(test))
		if testResult > 0 then
			io.stderr:write("Result: "..tostring(testResult).."\n")
			results[#results + 1] = testResult
		else
			io.stderr:write("Failed or no output\n")
		end
		i = i + 1
	end
	local sum = do_sum(results, #results)
	return sum
end

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

local function calculate_all_data()
	data = lines_from(dataFile)
	local hour = os.date("*t")["hour"]
	local hour1 = hour + 1
	newResult = do_tests_serie()
	for i = 1,24 do
		if not data[i] then
			data[i] = ""
		end
	end
	data[hour1] = tonumber(data[hour1]) and
		data[hour1] * stability + newResult * (1 - stability) or
		newResult
	return data,hour,newResult,data[hour1]
end

local function save_data(data, file)
	-- empty the file
	io.open(file,"w"):close()
	local handle = io.open(file,"a")
	io.output(handle)
	for _,val in pairs(data) do
		io.write(val.."\n")
	end
	io.close(handle)
end

local data,hour,result,cumulativeResult = calculate_all_data()
save_data(data, dataFile)
io.stdout:write(hour.."\t"..result.."\t"..cumulativeResult.."\n")
