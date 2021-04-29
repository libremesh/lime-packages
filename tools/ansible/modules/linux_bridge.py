#!/usr/bin/env python
#-*- coding: utf-8 -*-

# MIT License

# Copyright (c) 2021 Ryo Nakamura

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
module: linux_bridge
short_description: Manage Linux bridges
requirements: [ brctl ]
description:
    - Manage Linux bridges
options:
    bridge:
        required: true
        description:
            - Name of bridge to manage
    state:
        required: false
        default: "present"
        choices: [ present, absent ]
        description:
            - Whether the bridge should exist
'''

EXAMPLES = '''
# Create bridge a named br-int
- linux_bridge: bridge=br-int state=present
'''

class LinuxBridge (object) :

    def __init__ (self, module) :
        self.module = module
        self.bridge = module.params['bridge']
        self.state = module.params['state']

        return

    def brctl (self, cmd) :

        return self.module.run_command (['brctl'] + cmd)


    def ifconfig (self, cmd) :

        return self.module.run_command (['ifconfig'] + cmd)


    def br_exists (self) :
        
        syspath = "/sys/class/net/" + self.bridge
        if os.path.exists (syspath) :
            return True
        else :
            return False

        return 


    def addbr (self) :
        
        (rc, out, err) = self.brctl (['addbr', self.bridge])

        if rc != 0 :
            raise Exception (err)

        self.ifconfig ([self.bridge, 'up'])

        return


    def delbr (self) :
        
        self.ifconfig ([self.bridge, 'down'])

        (rc, out, err) = self.brctl (['delbr', self.bridge])

        if rc != 0 :
            raise Exception (err)
    
        return


    def check (self) :

        try :
            if self.state == 'absent' and self.br_exists () :
                changed = True
            elif self.state == 'present' and not self.br_exists () :
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
            if self.state == 'absent' and self.br_exists () :
                self.delbr ()
                changed = True

            elif self.state == 'present' and not self.br_exists () :
                self.addbr ()
                changed = True

        except Exception as e :
            self.module.fail_json (msg = str (e))


        self.module.exit_json (changed = changed)

        return
            

def main () :

    module = AnsibleModule (
        argument_spec = {
            'bridge' : { 'required' : True },
            'state' : {'default' : 'present', 
                       'choices' : ['present', 'absent']
                       }
            },
        supports_check_mode = True,
        )

    br = LinuxBridge (module)

    if module.check_mode :
        br.check ()
    else :
        br.run ()

    return

from ansible.module_utils.basic import *
main ()
