#!/usr/bin/env python
#-*- coding: utf-8 -*-

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
