local socket = require("socket")
local server_address = "127.0.0.1"
local server_port = 3490
local interval = 10

local function debug(...)
	print(socket.gettime(), unpack(arg))
end

local function get(collectors_output)
	local tcp, status, err
	if tcp then
		tcp:close()
	end
	tcp = assert(socket.tcp6())
	tcp:settimeout(10) -- seconds
	debug("### try connecting to " .. server_address .. " over IPv6")
	status, err = tcp:connect(server_address, server_port)
	if not status then -- retry falling back to ipv4
		debug("tcp status:", status, "err:", err)
		debug("# retry connecting to " .. server_address .. " over IPv4")
		tcp = assert(socket.tcp())
		tcp:settimeout(10) -- seconds
		status, err = tcp:connect(server_address, server_port)
	end
	debug("tcp status:", status, "err:", err)
	returnstring = ""
	if status then
		debug("sending ... : " .. string.len(collectors_output) )
		status, err, last_byte = tcp:send(collectors_output)
		debug('### sent: ', status, err, last_byte)
		debug('### receive: ')
		while true do
			s, status, partial = tcp:receive('*a')
			if status == "closed" then
				break
			end
			returnstring=s
			print("s " ..returnstring)
		end
		print("s " ..returnstring)
		debug('### end receive')
	end
	tcp:close()
	return returnstring
end

local function gethttp()
	local tcp, status, err
	local start_time = socket.gettime()

	--while 1 do
	local lastrun_time = socket.gettime()
	local drift = (lastrun_time - start_time) % interval

	if tcp then
		tcp:close()
	end
	tcp = assert(socket.tcp6())
	tcp:settimeout(10) -- seconds
	debug("### try connecting to " .. server_address .. " over IPv6")
	status, err = tcp:connect(server_address, server_port)
	if not status then -- retry falling back to ipv4
		debug("tcp status:", status, "err:", err)
		debug("# retry connecting to " .. server_address .. " over IPv4")
		tcp = assert(socket.tcp())
		tcp:settimeout(10) -- seconds
		status, err = tcp:connect(server_address, server_port)
	end
	
	debug("tcp status:", status, "err:", err)

	if status then
		tcp:send("POST /write HTTP/1.1\n")
		tcp:send("User-Agent: prometheus-node-push-influx\n")
		tcp:send("Host: " .. server_address .. ":" .. server_port .. "\n")
		tcp:send("Content-Type: application/x-www-form-urlencoded\n")
		tcp:send("Transfer-Encoding: chunked\n")
		tcp:send("\n")
		local collectors_output = "hola"
		debug("run_all_collectors done: " .. string.len(collectors_output) .. " bytes to send")
		tcp:send(string.len(collectors_output) .. "\n")
		status, err, last_byte = tcp:send(collectors_output)
		debug('### sent: ', status, err, last_byte)
		status, err, last_byte = tcp:send("0\n\n")
		debug('### sent: ', status, err, last_byte)
		debug('### receive: ')
		while true do
			s, status, partial = tcp:receive('*a')
			print(s or partial)
			if status == "closed" then
				break
			end
		end
		debug('### end receive')
		tcp:close()
	end
	--end
	tcp:close()
	return 4
end

describe('test async echo server', function()
    it('sends a piece of texh and expects to get it back', function()
        assert.is.equal("hola", get("hola"))
		assert.is.equal("holaholaholaholaholaholaholaholaholaholaholaholaholaholaholahola", get("holaholaholaholaholaholaholaholaholaholaholaholaholaholaholahola"))
    end)
end)

