#!/usr/bin/lua

system = {}

function system.sanitize_hostname(hostname)
	hostname = hostname:gsub(' ', '-')
	hostname = hostname:gsub('[^-a-zA-Z0-9]', '')
	hostname = hostname:gsub('^-*', '')
	hostname = hostname:gsub('-*$', '')
	hostname = hostname:sub(1, 32)
	return hostname
end

return system
