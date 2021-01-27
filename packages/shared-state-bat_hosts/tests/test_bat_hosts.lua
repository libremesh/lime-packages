local bat_hosts = require('bat-hosts')
local utils = require('lime.utils')
local test_utils = require('tests.utils')
local shared_state = require('shared-state')

it('test get_bathost #bathost', function()
    shared_state.DATA_DIR = test_utils.setup_test_dir()
    local sharedState = shared_state.SharedState:new('bat-hosts')
    sharedState:insert({
        ["02:95:39:ab:cd:00"] = "LiMe_abcd00_wlan1_mesh",
        ["52:00:00:ab:cd:a0"] = "LiMe_abcd01_wlan2_mesh_17",
        ["d6:67:58:8e:cd:92"] = "LiMe_abcd02_wlan0_adhoc_29",
        ["12:00:00:00:00:00"] = "LiMe_abcd03_wlan1_adhoc"
    })
    local ifaces = {'wlan1-mesh', 'wlan2-mesh', 'wlan2-mesh_17', 'wlan0-adhoc_29', 'wlan1-adhoc'}
    stub(utils, "get_ifnames", function () return ifaces end)
    assert.is.same({hostname='LiMe-abcd00', iface='wlan1-mesh'}, bat_hosts.get_bathost('02:95:39:ab:cd:00'))
    assert.is.same({hostname='LiMe-abcd01', iface='wlan2-mesh_17'}, bat_hosts.get_bathost('52:00:00:ab:cd:a0'))
    assert.is.same({hostname='LiMe-abcd02', iface='wlan0-adhoc_29'}, bat_hosts.get_bathost('d6:67:58:8e:cd:92'))
    assert.is.same({hostname='LiMe-abcd03', iface='wlan1-adhoc'}, bat_hosts.get_bathost('12:00:00:00:00:00'))
    local ipv6ll = utils.mac2ipv6linklocal('52:00:00:ab:cd:00') .. '%wlan1-mesh'
    local dataTypeOfSync = nil
    local urlsOfSync = nil
    local function syncMock (self, urls)
        dataTypeOfSync = self.dataType
        urlsOfSync = urls
        self:insert({['52:00:00:ab:cd:00'] = "Lime_abcd04_wlan1_mesh"})
    end
    stub(shared_state.SharedState, "sync", syncMock)
    local bathost = bat_hosts.get_bathost('52:00:00:ab:cd:00', 'wlan1-mesh')
    assert.is.same(urlsOfSync, { ipv6ll })
    assert.is.equal(dataTypeOfSync, 'bat-hosts')
    assert.is.same({hostname='Lime-abcd04', iface='wlan1-mesh'}, bathost)
    assert.is_nil(bat_hosts.get_bathost('00:aa:bb:cc:dd:00', 'wlan1'))
    assert.is_nil(bat_hosts.get_bathost('00:aa:bb:cc:dd:00'))
end)