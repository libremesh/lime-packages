local ubus = require "ubus"
local iwinfo = require "iwinfo"

local function scrape()

-- Agregamos signal en promedio para obtener solo la métrica de signal avg y agregamos medición para cada antena.
  local metric_wifi_station_signal_iwavg = metric("wifi_station_signal_iwavg","gauge")
  local metric_wifi_station_signal_iwchain0 = metric("wifi_station_signal_iwchain0", "gauge")
  local metric_wifi_station_signal_iwchain1 = metric("wifi_station_signal_iwchain1", "gauge")
  local metric_wifi_station_signal_iwchain2 = metric("wifi_station_signal_iwchain2", "gauge")
  local metric_wifi_station_transmit_retries = metric("wifi_station_transmit_retries", "counter")
  local metric_wifi_station_transmit_failed = metric("wifi_station_transmit_failed", "counter")


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

              regexp = "signal avg:[^-%d]*(-?%d*)[^-%d]*(-?%d*)[^-%d]*(-?%d*)[^-%d]*(-?%d*)"
              if l and l:match(regexp) then
                local avg, chain0, chain1, chain2 = l:match(regexp)
                if avg ~= "" then
                  metric_wifi_station_signal_iwavg(labels, avg)
                end
                if chain0 ~= "" then
                  metric_wifi_station_signal_iwchain0(labels, chain0)
                end
                if chain1 ~= "" then
                  metric_wifi_station_signal_iwchain1(labels, chain1)
                end
                if chain2 ~= "" then
                  metric_wifi_station_signal_iwchain2(labels, chain2)
                end
              end

              regexp = "tx retries:%s+(%d+)"
              if l and l:match(regexp) then
                local tx_retries = l:match(regexp)
                if tx_retries then
                  metric_wifi_station_transmit_retries(labels, tx_retries)
                end
              end

              regexp = "tx failed:%s+(%d+)"
              if l and l:match(regexp) then
                local tx_failed = l:match(regexp)
                if tx_failed then
                  metric_wifi_station_transmit_failed(labels, tx_failed)
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
