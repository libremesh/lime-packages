--[[
LuCI - Lua Configuration Interface

Copyright 2014 Nicolas Echaniz <nicoechaniz@altermundi.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

]]--

module("luci.controller.location", package.seeall)

function index()
   local page

   node("lime")
   page = entry({"lime", "location"}, template("location/location"), _("Location"), 60)
   page.index = true

   page = node("lime", "location", "set_location")
   page.target = call("set_location")
   page.leaf = true

end

function set_location(lat, lon)
   local uci = require "uci"                         
   local uci = uci.cursor() 
   uci:set('libremap', 'location', {latitude=lat, longitude=lon})
   uci:save('libremap')
   uci:commit('libremap')
end
 
