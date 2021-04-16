local ubus = require "ubus"
local iwinfo = require "iwinfo"

local function scrape()

  local metric_wifi_stations_retries = metric("tx_retries", "counter")
  local metric_wifi_stations_failed = metric("tx_failed", "counter")

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
             if l and l:match("tx retries:%s+(%d+)") then
              local tx_retries = l:match("tx retries:%s+(%d+)")
                if tx_retries then
                  metric_wifi_stations_retries(labels, tx_retries)
                end
              end
             if l and l:match("tx failed:%s+(%d+)") then
              local tx_failed = l:match("tx failed:%s+(%d+)")
                if tx_failed then
                  metric_wifi_stations_failed(labels, tx_failed)
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
