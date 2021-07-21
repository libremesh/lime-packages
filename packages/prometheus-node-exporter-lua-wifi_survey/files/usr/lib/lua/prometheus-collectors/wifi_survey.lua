local ubus = require "ubus"

local function scrape()
  local metric_wifi_survey_channel_noise_dbm        = metric("wifi_survey_channel_noise_dbm", "gauge")
  local metric_wifi_survey_channel_active_time_ms   = metric("wifi_survey_channel_active_time_ms", "counter")
  local metric_wifi_survey_channel_busy_time_ms     = metric("wifi_survey_channel_busy_time_ms", "counter")
  local metric_wifi_survey_channel_receive_time_ms  = metric("wifi_survey_channel_receive_time_ms", "counter")
  local metric_wifi_survey_channel_transmit_time_ms = metric("wifi_survey_channel_transmit_time_ms", "counter")

  local u = ubus.connect()
  local status = u:call("network.wireless", "status", {})

  for dev, dev_table in pairs(status) do
    for _, intf in ipairs(dev_table['interfaces']) do
      local ifname = intf['ifname']
      if ifname ~= nil then

        local iwsurvey = io.popen("iw "..ifname.." survey dump", "r")
        if iwsurvey then
          local l
          repeat
            l = iwsurvey:read("*l")
            if l and l:match("%[in use%]") then -- catch the frequency in use
              local freq = l:match("frequency:%s+(%d+) MHz")
              local labels = {
                ifname = ifname,
                freq = freq,
              }
              local count = 0
              while count < 5 do -- and scrape the next 5 lines for survey values
                l = iwsurvey:read("*l")
                if not l then break end

                channel_noise         = l:match("noise:%s+(-?%d+) dBm")
                channel_active_time   = l:match("channel active time:%s+(%d+) ms")
                channel_busy_time     = l:match("channel busy time:%s+(%d+) ms")
                channel_receive_time  = l:match("channel receive time:%s+(%d+) ms")
                channel_transmit_time = l:match("channel transmit time:%s+(%d+) ms")

                if channel_noise then metric_wifi_survey_channel_noise_dbm(labels, channel_noise) end
                if channel_active_time then metric_wifi_survey_channel_active_time_ms(labels, channel_active_time) end
                if channel_busy_time then metric_wifi_survey_channel_busy_time_ms(labels, channel_busy_time) end
                if channel_receive_time then metric_wifi_survey_channel_receive_time_ms(labels, channel_receive_time) end
                if channel_transmit_time then metric_wifi_survey_channel_transmit_time_ms(labels, channel_transmit_time) end

                count = count + 1
              end
            end
          until not l
          iwsurvey:close()
        end
      end
    end
  end
end

return { scrape = scrape }
