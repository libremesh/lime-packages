#!/usr/bin/lua

local libuci_loaded, libuci = pcall(require, "uci")

local function config_uci_get(option)
	local result
	if libuci_loaded then
		result = libuci:cursor():get("bandwidth-test","bandwidth_test",option)
	else
		result = nil
	end
	return result
end

local PIDfile = "/tmp/bandwidth-test-wget-pid"

local singleTestDuration = tonumber(arg[1]) or tonumber(config_uci_get("single_test_duration")) or 20

local nonzeroTests = tonumber(arg[2]) or tonumber(config_uci_get("nonzero_tests")) or 5

local defaultServersList = {
	"http://speedtest-lon1.digitalocean.com/10mb.test",
	"http://www.ovh.net/files/10Mio.dat",
	"http://cloudharmony.com/probe/test10mb.jpg",
	"http://frf1-speed-02.host.twtelecom.net.prod.hosts.ooklaserver.net:8080/download?size=12000000",
	"http://cdn.google.cloudharmony.net/probe/test10mb.jpg",
	"http://deb.debian.org/debian/ls-lR.gz",
	"http://speedtest.catnix.cat.prod.hosts.ooklaserver.net:8080/download?size=12000000",
	"http://ubuntu.inode.at/ubuntu/dists/bionic/main/installer-amd64/current/images/hd-media/initrd.gz",
	"http://cdn.kernel.org/pub/linux/kernel/v4.x/patch-4.9.gz",
	"http://ftp.belnet.be/ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/current/images/hd-media/initrd.gz"
}

local serversList
if arg[3] then
	serversList = {}
	for i = 3,#arg,1
	do
		serversList[#serversList + 1] = tostring(arg[i])
	end
else
	local temp = config_uci_get("server")
	serversList = type(temp) == "table" and temp or defaultServersList
end

if not singleTestDuration or not nonzeroTests or not serversList[1]:find("http") then
	local help = {"Usage: "..arg[0].." [SINGLE_TEST_DURATION] [NONZERO_TESTS] [SERVERS_LIST]",
		"Measures maximum available download bandwidth downloading a list of files from the internet.",
		"The measurement will take approximately SINGLE_TEST_DURATION*NONZERO_TESTS seconds.",
		"Download of each URL is attempted at most one time: multiple URLs should be provided.",
		"Speed in B/s is printed to STDOUT.",
		"",
		"  SINGLE_TEST_DURATION  fixed duration of each download process,",
		"                          if missing reads from UCI status-report (default 20)",
		"  NONZERO_TESTS         minimum number of successful downloads,",
		"                          if missing reads from UCI status-report (default 5)",
		"  SERVERS_LIST          a space-separated list of files' URLs to download,",
		"                          preferably large files.",
		"                          When running with Busybox wget, has to include http://",
		"                          and will likely fail with https://",
		"                          if missing reads from UCI status-report",
		"                          (defaults to a list of 10 MB files on various domains)"}
	for i = 1,#help,1 do
		io.stderr:write(help[i],"\n")
	end
	os.exit(1)
end

local function do_split(str,pat)
	local tbl = {}
	str:gsub(pat, function(x) tbl[#tbl+1]=x end)
	return tbl
end

local function do_test(server)
	io.stderr:write("Attempting connection to "..server.."\n")
	local timeout = singleTestDuration * 0.75
	local pvCommand = "(wget -T"..timeout.." -q "..server..
		" -O- & echo $! >&3) 3> "..PIDfile..
		" | pv -n -b -t 2>&1 >/dev/null"
	local handlePv = io.popen(pvCommand, 'r')
	local handleKill = io.popen("sleep "..singleTestDuration.."; kill $(cat "..PIDfile.." 2>/dev/null) 2>/dev/null")
	local pvRaw = handlePv:read("*a")
	handleKill:close()
	handlePv:close()
	local pvArray = do_split(pvRaw,"[.%d]+")
	return pvArray
end

local function get_speed(pvArray)
	local t1 = tonumber(pvArray[#pvArray-3]) or 0
	local d1 = tonumber(pvArray[#pvArray-2]) or 0
	local t2 = tonumber(pvArray[#pvArray-1])
	local d2 = tonumber(pvArray[#pvArray])
	local speed = 0
	if t2 and d2 then
		speed = (d2 - d1) / (t2 - t1)
	end
	return speed
end

local function remove_zeros(array)
    local tbl = {}
    for i = 1, #array do
	if(array[i] ~= 0) then
            table.insert(tbl, array[i])
        end
    end
    return tbl
end

local function do_median(array)
	local temp = array
	local median = 0
	if #temp ~= 0 then
		table.sort(temp)
		median = temp[math.floor(#array/2)+1]
	end
	return median
end

local function do_tests_serie()
	local results = {}
	local i = 1
	while #results < nonzeroTests and serversList[i] do
		local test = do_test(serversList[i])
		local testResult = get_speed(test)
		io.stderr:write(math.floor(testResult).." B/s\n")
		results[#results + 1] = testResult
		results = remove_zeros(results)
		i = i + 1
	end
	local median = do_median(results)
	local attempted = i - 1
	return median, attempted, #results
end

local result, attempted, successful = do_tests_serie()

print(result)

local message = "Maximum available bandwidth "..math.floor(result)..
	" B/s, attempted connection to "..attempted..
	" servers, successful connection to "..successful..
	" servers."

io.stderr:write(message.."\n")

local handle = io.popen("logger -t bandwidth-test "..message)
handle:close()

