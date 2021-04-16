local ubus = require "ubus"
local iwinfo = require "iwinfo"

local function scrape()

-- Agregamos signal en promedio para obtener solo la métrica de signal avg y agregamos medición para cada antena.
  local metric_wifi_station_signal_iwavg = metric("wifi_station_signal_iwavg","gauge")
  local metric_wifi_station_signal_iwchain0 = metric("wifi_station_signal_iwchain0", "gauge")
  local metric_wifi_station_signal_iwchain1 = metric ("wifi_station_signal_iwchain1", "gauge")

  local u = ubus.connect()
  local status = u:call("network.wireless", "status", {})

  for dev, dev_table in pairs(status) do
    for _, intf in ipairs(dev_table['interfaces']) do
      local ifname = intf['ifname']
      if ifname ~= nil then
        local iw = iwinfo[iwinfo.type(ifname)]

        local assoclist = iw.assoclist(ifname)
        for mac, station in pairs(assoclist) do
          local labels = {
            ifname = ifname,
            mac = mac,
          }

        local iwstation = io.popen("iw "..ifname.." station get "..mac, "r")
        if iwstation then
         local l
         repeat
           l = iwstation:read("*l")
           if l and l:match("signal avg:[^%d]+(%d+)[^%d]+(%d+)[^%d]+(%d+)") then
             local mix, chain0, chain1 = l:match("signal avg:[^%d]+(%d+)[^%d]+(%d+)[^%d]+(%d+)")
             if chain0 and chain1 then
               metric_wifi_station_signal_iwavg(labels, "-"..mix)
               metric_wifi_station_signal_iwchain0(labels, "-"..chain0)
               metric_wifi_station_signal_iwchain1(labels, "-"..chain1)
            else
              metric_wifi_station_signal_iwavg(labels, "-"..mix)
            end
          end
         until not l
        iwstation:close()
        end
       end
      end
    end
  end
end
return { scrape = scrape }
