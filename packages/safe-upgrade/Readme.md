# safe-upgrade

safe-upgrade provides safe firmware upgrades using two partitions and a confirmation step. Only the
LibreRouter is supported.

## Usage

To perform an upgrade you have to:
1. run `safe-upgrade upgrade xxx-sysupgrade.bin` to install a firmware to the non current (other) partition.
2. reboot
3. validate that the new firmware is _good_. If it is not good just reboot.
4. `safe-upgrade confirm` before a defined period of time (the default is 10 minutes). If you don't
confirm (or you can't because the configuration is not good) in this period of time then
an automatic reboot will be performed and the device will boot the last confirmed partition.

### help

run `safe-upgade --help` to get the list of commands available. Use `safe-upgrade CMD --help` to
get the help for the command CMD.

### show

`safe-upgrade show` shows the current status of the system partitions.

### upgrade

`safe-upgrade upgrade [-n][--reboot-safety-timeout=600][--disable-reboot-safety] xxx-sysupgrade.bin`

`safe-upgrade upgrade` performs the first step of the upgrade procedure.
Options
* use `-n` or `--do-not-preserve-config` to not save the current configuration to the new partition.
* use `--disable-reboot-safety`to disable the automatic reboot safety mechanism.
* use `--reboot-safety-timeout=600` to set the timeout in seconds of the automatic reboot safety mechanism.

After running this command to test the new image you have to restart the device.

### confirm

`safe-upgrade confirm` confirms the current partition as the new default partition. Use after booting
into a new partition after running `safe-upgrade upgrade` or `safe-upgrade test-other-partition`.

### bootstrap (advanced)

Use `safe-upgrade bootstrap` to install the `safe-upgrade` mechanism in the bootloader. Run this only
if `safe-upgrade` exits with 'safe-upgrade is not installed, aborting.'

## How `safe-upgrade` works

`safe-upgrade` works installing the following script into the bootloader (in pseudo-code):

```
if testing_partition != None:
    boot_partition = testing_partition
    testing_partition = None # a testing partition will boot just once
else:
    boot_partition = stable_partition

boot(boot_partition)
```

`stable_partition` allowed values are 1 or 2. `testing_partition` allowed values are None, 1 or 2, with
None as starting value.

Lets suppose an initial state of `stable_partiton = 1` and `testing_partition = None`.
In this configuration the bootloader always boots the partition 1.
When `safe-upgade upgrade` is performed the `testing_partition` value changes to the other partition, the non stable
partition, in this case it will be the partition 2. When the device is rebooted the bootloader script will
set the testing_partition to None again but will boot the partition 2. If this partition is confirmed
then the stable_partition will change from 1 to 2.
So `safe-upgrade` works having always a stable partition value of a _good partition_ with a temporary
state (`testing_partition != None`) that only lasts for one boot.

The bootloader script and the variables `stable_partition` and `testing_partition` are stored in the flash
u-boot environment.
