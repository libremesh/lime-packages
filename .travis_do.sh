#!/bin/bash
#
# MIT Alexander Couzens <lynxis@fe80.eu>

#set -e

if [[ "$TRAVIS_BRANCH" == "master" ]]; then
    SDK_URL="https://downloads.openwrt.org/snapshots/targets/"
    STORE_PATH="snapshots"
    SDK=openwrt-sdk
else
    SDK_URL="https://downloads.openwrt.org/releases/$OPENWRT_RELEASE/targets/"
    STORE_PATH="releases/$TRAVIS_BRANCH"
    SDK=lede-sdk
fi

SDK_PATH="$SDK_URL$SDK_TARGET"
SDK_HOME="$HOME/sdk/$SDK_TARGET"
PACKAGES_DIR="$PWD"
REPO_NAME="libremesh"
CHECK_SIG=1

echo_red()   { printf "\033[1;31m$*\033[m\n"; }
echo_green() { printf "\033[1;32m$*\033[m\n"; }
echo_blue()  { printf "\033[1;34m$*\033[m\n"; }

get_sdk_file() {
    if [ -e "$SDK_HOME/sha256sums" ] ; then
        grep -- "$SDK" "$SDK_HOME/sha256sums" | awk '{print $2}' | sed 's/*//g'
    else
        false
    fi
}

# download will run on the `before_script` step
# The travis cache will be used (all files under $HOME/sdk/). Meaning
# We don't have to download the file again
setup() {
    mkdir -p "$SDK_HOME/sdk"
    cd "$SDK_HOME"

    echo_blue "=== download SDK"
    wget "$SDK_PATH/sha256sums" -O sha256sums
    wget "$SDK_PATH/sha256sums.gpg" -O sha256sums.asc

    if [[ "$CHECK_SIG" == 1 ]]; then
        # LEDE Build System (LEDE GnuPG key for unattended build jobs)
        gpg --import $PACKAGES_DIR/.keys/626471F1.asc
        echo '54CC74307A2C6DC9CE618269CD84BCED626471F1:6:' | gpg --import-ownertrust
        # LEDE Release Builder (17.01 "Reboot" Signing Key)
        gpg --import $PACKAGES_DIR/.keys/D52BBB6B.asc
        echo 'B09BE781AE8A0CD4702FDCD3833C6010D52BBB6B:6:' | gpg --import-ownertrust

        echo_blue "=== Verifying sha256sums signature"
        gpg --verify sha256sums.asc
        echo_blue "=== Verified sha256sums signature"
    else
        echo_red "=== Not checking SDK signature"""
    fi
    if ! grep -- "$SDK" sha256sums > sha256sums.small ; then
        echo_red "=== Can not find $SDK file in sha256sums."
        echo_red "=== Is \$SDK out of date?"
        false
    fi

    # if missing, outdated or invalid, download again
    if ! sha256sum -c ./sha256sums.small ; then
        sdk_file="$(get_sdk_file)"
        echo_blue "=== sha256 doesn't match or SDK file wasn't downloaded yet."
        echo_blue "=== Downloading a fresh version"
        wget "$SDK_PATH/$sdk_file" -O "$sdk_file"
        echo_blue "=== Removing old SDK directory"
        rm -rf "./sdk/" && mkdir "./sdk"

        echo_blue "=== Setting up SDK"
        tar Jxf "$sdk_file" --strip=1 -C "./sdk"

        # use github mirrors to spare lede servers
        cat > ./sdk/feeds.conf <<EOF
src-git base https://github.com/openwrt/openwrt.git;master
src-git packages https://github.com/openwrt/packages.git;master
src-git luci https://github.com/openwrt/luci.git;master
src-git libremesh https://github.com/libremesh/lime-packages.git;master
src-git libremap https://github.com/libremap/libremap-agent-openwrt.git;master
src-git limeui https://github.com/libremesh/lime-packages-ui.git;master
EOF
    fi

    if [[ "$TRAVIS_PULL_REQUEST" == "false" ]]; then
        cat > ./sdk/key-build <<EOF
untrusted comment: private key 7546f62c3d9f56b1
$KEY_BUILD
EOF
    else
        sed -i s/CONFIG_SIGNED_PACKAGES=y/CONFIG_SIGNED_PACKAGES=n/g ./sdk/.config
    fi

    # check again and fail here if the file is still bad
    echo_blue "Checking sha256sum a second time"
    if ! sha256sum -c ./sha256sums.small ; then
        echo_red "=== SDK can not be verified!"
        false
    fi
    echo_blue "=== SDK is up-to-date"
}

# test_package will run on the `script` step.
# test_package call make download check for very new/modified package
build() {
    cd "$SDK_HOME/sdk"

    ./scripts/feeds update -a > /dev/null
    ./scripts/feeds uninstall -a > /dev/null
    ./scripts/feeds install -p $REPO_NAME -a -d m > /dev/null
    make defconfig > /dev/null

    if [[ "$TRAVIS_PULL_REQUEST" == "false" ]]; then
        make -j$(($(nproc)+1))
    else
        make -j1 V=s
    fi
}

upload() {
    if [[ "$TRAVIS_PULL_REQUEST" == "false" ]]; then
        rsync -L -r -v -e "sshpass -p $SSH_PASS ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $CI_PORT" \
            --exclude 'base/*' \
            --exclude 'packages/*' \
            --exclude 'luci/*' \
            --exclude 'routing/*' \
            --exclude 'telephony/*' \
            $SDK_HOME/sdk/bin/packages/x86_64/ "${CI_USER}@${CI_SERVER}:${CI_STORE_PATH}/$STORE_PATH/packages/"
    else
        echo_blue "=== No PR uploads"
    fi
}

if [ $# -ne 1 ] ; then
    cat <<EOF
Usage: $0 (setup_sdk|build_packages|upload_packages)

setup - download the SDK to $HOME/sdk.tar.xz
build do a make check on the package
upload - upload packages to ci server
EOF
exit 1
fi

$@
