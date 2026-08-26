#!/bin/sh
# This script should be run both from master to create a new release's branch
# and from inside a existing release's branch to do a new point release.

([ "$(git config --get user.name)" = "Your Name" ] ||
	[ "$(git config --get user.email)" = "you@example.com" ]) &&
	echo "Error: git repository not configured" && exit 1

[ "$1" = "" ] && echo "Usage: ./release.sh <release>" && exit 1
VALID=$(echo "$1" | grep -qE "(v|)[[:digit:]]{1,4}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}" && echo 1 || echo 0)
[ "$VALID" = 0 ] && echo "Release must be <year>.<number>.<number>" && exit 1

RELEASE="$1"
case $RELEASE in v*) true ;; *) RELEASE="v$RELEASE" ;; esac
TAG="$RELEASE"
CODENAME=${2:-}
BRANCH="$(echo "$RELEASE" | grep -oE "[[:digit:]]{1,4}\.[[:digit:]]{1,3}")"
REPO="git@github.com:/libremesh/lime-packages"
SYS_MAKEFILE="packages/lime-system/Makefile"

if git rev-parse "$TAG" >/dev/null 2>&1; then
	echo "Release tag already exists"
	exit 1
fi

version_sed() {
	sed -i \
		-e "s,\(LIME_RELEASE:=\).*,\1${RELEASE}," \
		-e "s,\(LIME_CODENAME:=\).*,\1${CODENAME}," \
		"$SYS_MAKEFILE"
}

if [ "$(git branch --list $BRANCH)" = "" ]; then
	git switch -c "$BRANCH"
else
	git checkout "$BRANCH"
fi

echo "Adjust config defaults"
version_sed
git add "$SYS_MAKEFILE"
git commit -m "LibreMesh $TAG: adjust config defaults"
git tag -a -m "LibreMesh $TAG release" $TAG

echo "Restore branch defaults"
RELEASE=""
CODENAME="nightly"
version_sed
git add "$SYS_MAKEFILE"
git commit -m "LibreMesh $TAG: restore branch defaults"

echo "Do you want to continue and publish the release?"
read -p "Are you sure (Y/N)? " key

case $key in
y | Y)
	echo "Publishing the release"
	git push --follow-tags $REPO $BRANCH
	;;
n | N)
	echo "Exiting"
	exit 1
	;;
*)
	echo "Invalid input. Please press 'y' or 'n'."
	;;
esac
