#!/usr/bin/env python
#-*- coding: utf-8 -*-

# MIT License

# Copyright (c) 2021 Gui Iribarren <gui@altermundi.net>

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

DOCUMENTATION = '''
---
module: linux_tuntap
short_description: Manage Linux tuntap devices
requirements: [ ip ]
description:
    - Manage Linux tuntap devices
options:
    name:
        required: true
        description:
            - Name of tuntap device to manage
    state:
        required: false
        default: "present"
        choices: [ present, absent ]
        description:
            - Whether the tuntap device should exist
'''

EXAMPLES = '''
# Create tuntap named tap0 with mode tap
- linux_tuntap: name=tap0 mode=tap state=present
'''

class LinuxTunTap (object) :

    def __init__ (self, module) :
        self.module = module
        self.name = module.params['name']
        self.mode = module.params['mode']
        self.state = module.params['state']

        return

    def ip (self, cmd) :

        return self.module.run_command (['ip'] + cmd)


    def tuntap_exists (self) :

        syspath = "/sys/class/net/" + self.name
        if os.path.exists (syspath) :
            return True
        else :
            return False

        return


    def add_tuntap (self) :

        (rc, out, err) = self.ip (['tuntap', 'add', 'name', self.name, 'mode', self.mode])

        if rc != 0 :
            raise Exception (err)

        self.ip (['link', 'set', 'up', self.name])

        return


    def del_tuntap (self) :

        (rc, out, err) = self.ip (['link', 'del', self.name])

        if rc != 0 :
            raise Exception (err)

        return


    def check (self) :

        try :
            if self.state == 'absent' and self.tuntap_exists () :
                changed = True
            elif self.state == 'present' and not self.tuntap_exists () :
                changed = True
            else :
                changed = False

        except Exception as e :
            self.module.fail_json (msg = str (e))

        self.module.exit_json (changed = changed)

        return


    def run (self) :

        changed = False

        try :
            if self.state == 'absent' and self.tuntap_exists () :
                self.del_tuntap ()
                changed = True

            elif self.state == 'present' and not self.tuntap_exists () :
                self.add_tuntap ()
                changed = True

        except Exception as e :
            self.module.fail_json (msg = str (e))


        self.module.exit_json (changed = changed)

        return


def main () :

    module = AnsibleModule (
        argument_spec = {
            'name' : { 'required' : True },
            'mode' : {'default' : 'tap',
                      'choices' : ['tun', 'tap']
                      },
            'state' : {'default' : 'present',
                       'choices' : ['present', 'absent']
                       }
            },
        supports_check_mode = True,
        )

    tuntap = LinuxTunTap (module)

    if module.check_mode :
        tuntap.check ()
    else :
        tuntap.run ()

    return

from ansible.module_utils.basic import *
main ()
