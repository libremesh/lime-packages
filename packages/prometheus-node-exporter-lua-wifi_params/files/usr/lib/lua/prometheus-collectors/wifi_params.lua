local libuci = require("uci")

local function scrape()
  local metric_wifi_param_distance = metric("wifi_param_distance", "gauge")
  local metric_wifi_param_mcast_rate = metric("wifi_param_mcast_rate", "gauge")

  local uci = libuci.cursor()

  uci:foreach("wireless", "wifi-device",
    function(s)
      local distance = uci:get("wireless", s[".name"], "distance")
      local device = s[".name"]
      if distance ~= nil then
        metric_wifi_param_distance({device = device}, distance)
      end
    end
  )

  uci:foreach("wireless", "wifi-iface", 
    function(s)
      local mcast_rate = uci:get("wireless", s[".name"], "mcast_rate")
      local ifname = uci:get("wireless", s[".name"], "ifname")
      if mcast_rate ~= nil then
        metric_wifi_param_mcast_rate({ifname = ifname}, mcast_rate)
      end
    end
  )

  uci:close()
end

return { scrape = scrape }
