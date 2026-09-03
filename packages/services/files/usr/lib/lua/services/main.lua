#!/bin/lua

local utils = require('lime.utils')

function services.list()
    local services = {}
    -- clients = read('/etc/dhcp.leases').get_ip()
	-- mkirp /tmp/services
	-- data = []
	-- for client in $(clients) ; do
	-- 	wget $client/v2/local/target-state proxy=on http_proxy=$client:48484 -O /tmp/services/$client.json
	-- 	uci pirania set whitelist for $client?
	-- done
	-- for $server in $(/tmp/services/*)
	-- 	finalServer = {}
	-- 	services = []
	-- 	server = json.parse(server)
	-- 	finalServer.name = server.name
	-- 	finalServer.id = server.id
	-- 	finalServer.device = server.device
	-- 	server.apps.map(app => finalServer.apps = name, ui, service, description, icon)
	-- 	finalServer.apps = services
	-- 	data.push(finalServer)
	-- done
	-- write(data, '/www/cgi-bin/services')
end

return services
