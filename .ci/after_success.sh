#!/bin/sh
openssl aes-256-cbc -K $encrypted_4ddb7c1a1584_key -iv $encrypted_4ddb7c1a1584_iv -in $TRAVIS_BUILD_DIR/.ci/travisci_rsa.enc -out $TRAVIS_BUILD_DIR/.ci/travisci_rsa -d
chmod 400 $TRAVIS_BUILD_DIR/.ci/travisci_rsa
openssl aes-256-cbc -K $encrypted_055f76aafa25_key -iv $encrypted_055f76aafa25_iv -in $TRAVIS_BUILD_DIR/.ci/commentBotKey.enc -out $TRAVIS_BUILD_DIR/.ci/commentBotKey -d
export COMMENT_BOT_KEY=`cat $TRAVIS_BUILD_DIR/.ci/commentBotKey`
if [ $TRAVIS_BUILD_DIR ]; then
    mv $TRAVIS_BUILD_DIR/sdk/output $TRAVIS_BUILD_DIR/sdk/$TRAVIS_PULL_REQUEST
    rsync -r -v -e "ssh -i $TRAVIS_BUILD_DIR/.ci/travisci_rsa -o UserKnownHostsFile=$TRAVIS_BUILD_DIR/.ci/known_hosts" $TRAVIS_BUILD_DIR/sdk/$TRAVIS_PULL_REQUEST ci@repo.libremesh.org:/var/www/ci/
    chmod +x $TRAVIS_BUILD_DIR/.ci/announce_link_in_PR
    $TRAVIS_BUILD_DIR/.ci/announce_link_in_PR
else
    echo "not a pull request branch, skip copying binaries."
fi

