#!/usr/bin/python
#-*- coding: utf-8 -*-

DOCUMENTATION = '''
module: linux_bridge_port
short_description: Manage Linux bridge ports
requirements: [ brctl ]
descroption:
    - Manage Linux bridge ports
options:
    bridge:
        required: true
        description:
            - Name of bridge to manage
    port:
        requirement: true
        description:
            - Name of port to manage on the bridge
    state:
        required: false
        default: "present"
        choices: [ present, absent ]
        description:
            - Whether the port should exist
'''

EXAMPLES = '''
# create port eth0 on bridge br-int
- linux_bridge_port: bridge=br-int port=eth0 state=present
'''

class LinuxPort (object) :
    def __init__ (self, module) :
        self.module = module
        self.bridge = module.params['bridge']
        self.port = module.params['port']
        self.state = module.params['state']

        return


    def brctl (self, cmd) :
        
        return self.module.run_command (['brctl'] + cmd)


    def port_exists (self) :

        syspath = "/sys/class/net/%s/brif/%s" % (self.bridge, self.port)

        if os.path.exists (syspath) :
            return True
        else :
            return False

        return

    def addif (self) :

        (rc, out, err) = self.brctl (['addif', self.bridge, self.port])
        
        if rc != 0 :
            raise Exception (err)

        return


    def delif (self) :

        (rc, out, err) = self.brctl (['delif', self.bridge, self.port])
        
        if rc != 0 :
            raise Exception (err)

        return


    def check (self) :

        try :
            if self.state == 'absent' and self.port_exists () :
                changed = True
            elif self.state == 'present' and not self.port_exists () :
                changed = True
            else :
                changed = False
        except Exception, e :
            self.module.fail_json (msg = str (e))

        self.module.exit_json (changed = changed)

        return

    
    def run (self) :

        changed = False

        try :
            if self.state == 'absent' :
                if self.port_exists () :
                    self.delif ()
                    changed = True

            elif self.state == 'present' :
                if not self.port_exists () :
                    self.addif ()
                    changed = True

        except Exception, e :
            self.module.fail_json (msg = str (e))

        self.module.exit_json (changed = changed)

        return

def main () :

    module = AnsibleModule (
        argument_spec = {
            'bridge' : { 'required': True},
            'port' : {'required' : True},
            'state' : {'default' : 'present', 
                       'choices' : ['present', 'absent']}
            },
        supports_check_mode = True,
        )

    port = LinuxPort (module)

    if module.check_mode :
        port.check ()
    else :
        port.run ()

    return


from ansible.module_utils.basic import *
main ()