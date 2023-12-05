local lime_mesh_upgrade = require 'lime-mesh-upgrade'
local eupgrade = require 'eupgrade'

local network = require("lime.network")
print (tostring(network.primary_address()))

print(tostring(eupgrade.get_upgrade_api_url()))

local utils = require "lime.utils"
os.execute('echo librerouter-v1 > /tmp/sysinfo/board_name')


print(eupgrade._get_board_name())

eupgrade.set_custom_api_url('http://repo.librerouter.org/lros/api/v1/')
print(tostring(eupgrade.get_upgrade_api_url()))

print(tostring(eupgrade.is_new_version_available()))
lime_mesh_upgrade.set_up_firmware_repository()
utils.printJson(lime_mesh_upgrade.become_master_node())

os.execute("sleep " .. tonumber(6))

utils.printJson(lime_mesh_upgrade.become_master_node())

os.execute("sleep " .. tonumber(6))

utils.printJson(lime_mesh_upgrade.become_master_node())

os.execute("sleep " .. tonumber(20))

utils.printJson(lime_mesh_upgrade.become_master_node())

