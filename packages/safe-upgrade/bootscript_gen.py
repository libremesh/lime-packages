script = """
run preboot;
boot_part=${stable_part};
if test ${testing_part} -ne 0; then
    echo Testing part ${testing_part};
    boot_part=${testing_part};
    # saving environment so next boot it defaults to stable_part
    set testing_part 0;
    saveenv;
fi;
if test ${boot_part} -eq 2; then
    fw_addr=${fw2_addr};
    run boot_2;
else
    fw_addr=${fw1_addr};
    run boot_1;
fi;
# if some error happened
run boot_1;
# everythong else failed, raw booting
bootm ${fw1_addr};
"""


def onelinerize(data):
    import re
    # remove comments
    data = re.sub(r'#.*', '', data)
    return data.replace("\n", " ").replace("    ", "").replace("  ", " ").strip()

print("set bootcmd '%s'" % onelinerize(script))
