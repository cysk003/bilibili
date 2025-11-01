#!/bin/bash
# Re-package binary package by modifying the control file only.
# New .deb will be gererated by dpkg-name, which named by the control file info.
# If DEBFULLNAME and DEBEMAIL defined in env., will read that as Maintainer.
# Send unknown section name warning if not in the known list per Debian Policy.
# Priority will be auto verified by dpkg-deb, and send warning if not in known priority.
# LeisureLinux@BiliBili
# 2025-11-1 14:27
CWD=$(pwd -P)

clean() {
  rm -rf $CWD/deb_temp
}

trap clean EXIT

DEB=$1
[ ! -r "$DEB" ] && echo "Syntax: $0 path_to_package.deb" && exit
! command -v fakeroot >/dev/null && echo "Please install package: fakeroot" && exit
! command -v dpkg-name >/dev/null && echo "Please install package: dpkg-dev" && exit
[ -n "$DEBFULLNAME" -a -n "$DEBEMAIL" ] && MAINTAINER="$DEBFULLNAME \<$DEBEMAIL\>"

ORIGINAL_DEB=$(basename $DEB)
NEW_DEB="$(basename $DEB .deb)-new.deb"
[ ! -f "$ORIGINAL_DEB" ] && cp $DEB .
mkdir deb_temp && cd deb_temp
#
fakeroot sh -c "mkdir unpacked_deb && dpkg-deb -R ../$ORIGINAL_DEB unpacked_deb"
CTL="unpacked_deb/DEBIAN/control"
[ ! -f $CTL ] && echo "Error: unpack $DEB failed!" && exit
# replace maintainer
[ -n "$MAINTAINER" ] && sed -i "s/^Maintainer: .*$/Maintainer: $MAINTAINER/" $CTL
# Modify control file as well as scripts
vim $CTL
# edit scripts one by one
for f in unpacked_deb/DEBIAN/post* unpacked_deb/DEBIAN/pre*; do
  vim $f
done
# KNOWN_PRIORITIES="required,important,standard,optional,extra"
#
# Note: This list may need to be updated as policy changes.
KNOWN_SECTIONS="main,contrib,non-free,non-free-firmware,admin,app-arch,base,comm,database,debian-installer,devel,doc,editors,electronics,embedded,games,gnome,gnu-r,graphics,hamradio,haskell,httpd,introspection,kde,kernel,libdevel,libs,lisp,localization,mail,math,metapackages,misc,net,news,nodejs,ocaml,oldlibs,otherosfs,perl,php,python,ruby,rust,science,shells,sound,tasks,tex,text,utils,vcs,video,web,x11,xfce,zope"

# 1. Grab the Section field content using awk
SECTION_VALUE=$(awk -F': ' '/^Section:/ { print $2 }' "$CTL" | tr -d '\r')
[ -z "$SECTION_VALUE" ] && echo "Warning: Could not find or extract the Section field."

# 2. Check if the extracted value exists in the comma-separated string
if [[ ",$KNOWN_SECTIONS," != *",$SECTION_VALUE,"* ]]; then
  echo "Warning: Section value '$SECTION_VALUE' is NOT in the known list."
fi

fakeroot dpkg-deb -b unpacked_deb ../$NEW_DEB && dpkg-name -o ../$NEW_DEB
