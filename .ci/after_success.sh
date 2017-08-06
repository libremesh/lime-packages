#!/bin/sh
set -x
openssl aes-256-cbc -K $encrypted_4ddb7c1a1584_key -iv $encrypted_4ddb7c1a1584_iv -in $TRAVIS_BUILD_DIR/.ci/travisci_rsa.enc -out $TRAVIS_BUILD_DIR/.ci/travisci_rsa -d
chmod 400 $TRAVIS_BUILD_DIR/.ci/travisci_rsa
openssl aes-256-cbc -K $encrypted_055f76aafa25_key -iv $encrypted_055f76aafa25_iv -in $TRAVIS_BUILD_DIR/.ci/announce_link_in_PR.enc -out $TRAVIS_BUILD_DIR/.ci/announce_link_in_PR -d
chmod +x $TRAVIS_BUILD_DIR/.ci/announce_link_in_PR
if [ $TRAVIS_BUILD_DIR ]; then
    mv $TRAVIS_BUILD_DIR/sdk/output $TRAVIS_BUILD_DIR/sdk/$TRAVIS_BRANCH
    rsync -r -v -e "ssh -i $TRAVIS_BUILD_DIR/.ci/travisci_rsa -o UserKnownHostsFile=$TRAVIS_BUILD_DIR/.ci/known_hosts" $TRAVIS_BUILD_DIR/sdk/$TRAVIS_BRANCH ci@repo.libremesh.org:/var/www/ci/
    $TRAVIS_BUILD_DIR/.ci/announce_link_in_PR
else
    echo "not a pull request branch, skip copying binaries."
fi

