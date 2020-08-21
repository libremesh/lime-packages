# Testing guide

LibreMesh has unit tests that help us add new features while keeping maintenance effort contained.

We encourage contributors to write tests when adding new functionality and also while fixing regressions.

LibreMesh unit testing is based in the powerful [busted](https://olivinelabs.com/busted/) library which has a very good documentation.

Tests are run inside a x86_64 Docker image with some lua and openwrt libraries avaible.

We also have a development qemu virtual machine, this is a full libremesh image that can be used
in development.

## How to run the tests

Just execute `./run_tests`:
![run_tests](https://i.imgur.com/TBIE7Gp.png)


This will build the testing Docker image automaticaly in the first run and then execute the tests and create the coverage report.
Note: you must have Docker installed and running.

Use `LUA_ENABLE_LOGGING=1 ./run_tests` if you want to send the logging to stdout.

## Testing directory structure

The lua code of package `foo` should be in the *expanded files tree structure* form:
`package/foo/files/usr/lib/lua/foo.lua`

Test files live inside a `tests` directory with its names begining with `test_`:
```
package/foo/tests/test_foo.lua
package/foo/tests/test_utils.lua
```

Testing utilities, fake libraries and integration tests live inside a root `tests/` directory:

```
tests/test_some_integration_tests.lua
tests/test_other_general_tests.lua
tests/fake/bazlib.lua
tests/tests/test_bazlib.lua
```

## How to write tests

Here is a very simple test of a library `foo`:
```[lua]
local foo = require 'foo'

describe('foo library tests', function()
    it('very simple test of f_sum(a, b)', function()
        assert.is.equal(4, foo.f_sum(2, 2))
        assert.is.equal(2, foo.f_sum(2, 0))
        assert.is.equal(0, foo.f_sum(2, -2))
    end)
end)
```
### Using `lime.config` or the `uci` library

If you need to test something that directly or indirectly uses the configuration `uci` library then you **must** do the following in order to have a clean and temporary `uci` environment for each test:

```[lua]
local foo = require 'foo'
local test_utils = require 'tests.utils'

local uci -- do not forget this line!

describe('foo lib tests', function()
    it('test directly using uci', function()
        uci:set('wireless', 'radio0', 'wifi-device')
        uci:set('wireless', 'radio0', 'type', 'mac80211')
        -- this updates a config file in /tmp/tmpdir.XYZ/config/wireless
        uci:commit('wireless')

        assert.is.equal('mac80211', foo.get_radio_type('radio0')
    end)

    before_each('', function()
        -- this creates a temporary and fresh uci envornment for each test. There is no initial configuration, you have to create the config somehow inside the test.
        uci = test_utils.setup_test_uci()
    end)

    after_each('', function()
        -- this cleans the temporary uci envornment
        test_utils.teardown_test_uci(uci)
    end)
end)
```

You also **must use `lime.config.get_uci_cursor()`** when you need a `uci` cursor, instead of using `libuci:cursor()`.
This way the functions `test_utils.setup_test_uci()` and `test_utils.teardown_test_uci(uci)` can do its work providing a shared and clean `uci` config environment for each test. (Note: if something is not working as expected make sure all the uci cursors in all the code you use and its dependencies use the cursor provided by ` lime.config.get_uci_cursor()`)


## Testing advices and hints

* Libraries should provide a way to change *hardcoded things. For example using module variables to declare paths and then at the test code override this variable:
```[lua]
-- file foo.lua
foo.search_paths = {"/usr/lib/lua/lime/hwd/*.lua"}
```
* Execution of *commands with side effects*, like `os.execute('reboot')`, should be put inside a library function like `foo._reboot()` and then using [stubs or mocks in the tests](https://olivinelabs.com/busted/#spies-mocks-stubs). Even better is to separate the *logic part* of the code of the *executional part* so in the test you don't even have to `mock` this.
* Put special atention on untrivial logic: regex, parsing, multiple ifs, nested conditions.
* Testing trivialities is not helpful, but if you have trivial code you should have at least one test just to *run through the code* so you know you don't have syntax or require errors. This helps to future developers when then want to perform refactoring.
* Use `setup() / teardown()` and `before_each() / after_each()` to refactor repeated code in the tests.
* Look to existing tests to find inspiration.
* Ask for help or advice in a pull request!

## Coverage report

Coverage is measured using the [luacov](https://keplerproject.github.io/luacov/) library each time the tests are run. The results statistics are merged at `./luacov.stats.out` and a human friendly report is generated at `luacov.report.out`.

## Under the hood: tools in detail

As one of the goals is that it must be easy for developers to write, modify and run the tests we created some simple tools to do this:

* testing image -> `Dockerfiles/Dockerfile.unittests`
* testing shell environment -> `tools/dockertestshell`
* running the tests -> `./run_tests` script

### Testing shell environment

To provide an easy way to develop or test things within the docker image there is a tool that opens a bash shell inside the docker image that has some features that allows easy development:

* `/home/$USER` is mounted inside the docker image so each change you do to the code from inside is maintained when you close the docker container
* the same applies to `/tmp`
* you have the same user outside and inside
* network access is garanted
* and some goodies like bashrc, some useful ENV variables, PS1 modification, etc.

To enter the shell environment run:
```
[lime-packages]$ ./tools/dockertestshell
(docker) [lime-packages]$
```

You can see that the prompt is changed adding `(docker)` in the left part so you can easily remember that you are inside the docker container.

This environment is also used by `run_tests` script.


### `run_tests` script in detail

The idea behind this script is simple:
* creates the testing docker image if it is not available
* sets the search path of the tests for `buster`
* sets the lua library paths, prepending the fake library paths and adding the paths to the libremesh packages with `packages/lime-system/files/usr/lib/lua/?.lua`. This doesn't work automaticaly for every package if the paths does not use the *files/path/to/final/destination*. So if you want to test some package without the files convention maybe it would be good to move the package to this convention. Also it does not work if the lua module we want to test does not finish with `.lua`, in this case the path must be explicitly added (how to do this [here](https://blog.freifunk.net/2019/06/03/gsoc-2019-evaluating-options-to-do-unit-and-integration-tests-in-libremesh-and-a-first-working-example/)).
* runs the tests using the dockertestshell

`run_tests` also passes the first argument as an argument to busted so you can do things like`./run_tests --help` to see the busted help, or `./run_tests '--tags=footag --verbose'` so only the tests that have the tag `#footag` in the description of the test are run


## Development with qemu virtual machine

This image is not a perfect firmware image, it does not have wifi for example but ethernet network
LAN and WAN is supported. All the files inside the packages `files/` can be copied into the rootfs,
overwriting a precooked image that is a full LibreMesh x86_64 image.
So don't expect that everything runs exactly as in a wireless router but most things will perform
as expected:

* initialization scripts: uci-defaults, init.d, etc
* lime-config
* ubus / rpcd
* lime-app


### How to start and stop the image

You will need a rootfs and ramfs LibreMesh files. To generate one you can use a libremesh buildroot
and select x86_64 target and select the option to generate an initramfs.

Prebuilt development images can be downloaded from here:
* http://repo.libremesh.org/tmp/openwrt-18.06-x86-64-generic-rootfs.tar.gz
* http://repo.libremesh.org/tmp/openwrt-18.06-x86-64-ramfs.bzImage

Install the package `qemu-system-x86_64` if you don't have already installed.

### Build a mesh network

Up to 10 qemu nodes can be setup. Use the `--node-id N`. All the node's LAN interfaces are
bridged together. You can use `--enable-wan` in only one of the nodes to share your internet connection
to the network.

#### Start it

```
$ sudo ./tools/qemu_dev_start  path/to/openwrt-x86-64-generic-rootfs.tar.gz path/to/openwrt-x86-64-ramfs.bzImage
```

#### Stop it

```
$ ./tools/qemu_dev_stop
```

#### Update with local libremesh code

If you want to update the qemu image with new LibreMesh files of a local repository you can use
the option `--libremesh-workdir path/to/workdir`, for example:

```
$ sudo ./tools/qemu_dev_start  path/to/rootfs.tar.gz path/to/bzImage --libremesh-workdir .
```

#### Enable WAN and share internet to the virtual machine

Use the `--enable-wan IFC`, this will create a NAT and share your internet connection to the virtual machine
using the specified interface IFC.

### Lime-App

If you want to test a specific version of the Lime-App you can copy the build files into the
lime-app package after each build:

```
[lime-app ]$ mkdir -p path/to/lime-packages/packages/lime-app/files/www/app/
[lime-app ]$ npm run build:dev_router  && cp -r build/* path/to/lime-packages/packages/lime-app/files/www/app/
```
