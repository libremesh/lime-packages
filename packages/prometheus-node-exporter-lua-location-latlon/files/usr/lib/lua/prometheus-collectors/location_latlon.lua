local ubus = require "ubus"

local function scrape()
  local u = ubus.connect()
  local latitude = u:call("uci", "get", {config = "location", section = "settings", option = "node_latitude"})
  local longitude = u:call("uci", "get", {config = "location", section = "settings", option = "node_longitude"})
  if not latitude or not longitude then -- try to fallback to libremap location
    latitude = u:call("uci", "get", {config = "libremap", section = "location", option = "latitude"})
    longitude = u:call("uci", "get", {config = "libremap", section = "location", option = "longitude"})
  end

  if latitude and longitude then
    metric("node_location_latitude", "gauge", nil, latitude.value)
    metric("node_location_longitude", "gauge", nil, longitude.value)
  end
end

return { scrape = scrape }
