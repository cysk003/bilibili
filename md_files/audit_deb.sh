#!/bin/bash
# Audit vendor provided .deb package
# 引入第三方包时，审计软件包是否符合 Debian Policy
# Author: (LeisureLinux@Bilibili)[https://space.bilibili.com/517298151]
# Initial version date: 2025-9-20
# Steps:
# 1. Extract .deb
# 2. check md5sum
# 3. check package control file including package dependancy
# 4. check file system permission
# 5. check all preinst/prerm/postinst/postrm steps for permission and dangerous operations
# 6. security check for binary
syntax() {
  case $1 in
  "command") echo "Error: command: dpkg-deb not found!" ;;
  "file") echo "Error: pkg file $2 not exist!" ;;
  "no_md5sums") echo "Error: pkg has no md5sums file!" ;;
  "error_md5sums") echo "Error: pkg md5sums failed!" ;;
  "wrong_priority") echo "Error: pkg priority value [$2] wrong!" ;;
  "wrong_arch") echo "Error: pkg Architecture value [$2] wrong!" ;;
  "wrong_maintainer") echo "Error: pkg maintainer [$2] wrong, should contain Email address!" ;;
  "wrong_section") echo "Error: pkg section value [$2] wrong, should accordance with Debian Policy!" ;;
  "wrong_permission") echo "Error: wrong directory/file permission found!" ;;
  "wrong_depends") echo "Error: depends packages [$2] not installed!" ;;
  "dangerous_script") echo "Error: dangerous operations in installation scripts!" ;;
  "av_error") echo "Error: scan virus encounter error!" ;;
  "scanelf_error") echo "Error: scanelf encounter error!" ;;
  *) echo "Syntax: $0 deb_name" ;;
  esac
  test -n "$1" && test "$1" != "file" && echo "Audit failed, please check dir: $DIR for detail."
  exit
}

# Main Prog.
# removed root requirement: test "$(id -u)" = 0 || syntax root
# command -v md5sum >/dev/null || syntax command
# dpkg-deb and dpkg-query are in the essential package dpkg, md5sum is in coreutils also essential.
test -n "$1" || syntax
DEB=$1
test -f "$DEB" || syntax file $DEB
echo "Auditing .deb file $DEB ..."
DIR="$(basename $DEB .deb)"
test -d "$DIR" && rm -rf "$DIR" || mkdir "$DIR"
# Step 1: extract package with control info.
dpkg-deb -R $DEB "$DIR"
#
# Step 2: Check md5sums
test -f $DIR/DEBIAN/md5sums || syntax no_md5sums
cd $DIR
md5sum --quiet -c DEBIAN/md5sums >/dev/null || syntax error_md5sums
#
# Step 3: Check Package control Info, Per "Debian Policy"
# sections=LC_ALL=C aptitude search --disable-columns '~s !~v' -F '%s'|grep -v "\/"|sort|uniq | xargs -n 1 | paste -s -d '|' -
# current_os_sections="admin|cli-mono|comm|database|debug|default|devel|doc|editors|education|electronics|embedded|fonts|games|gnome|gnu-r|gnustep|golang|graphics|hamradio|haskell|httpd|interpreters|introspection|java|javascript|kde|kernel|libdevel|libs|lisp|localization|mail|math|metapackages|misc|net|news|ocaml|oldlibs|otherosfs|perl|php|python|ruby|rust|science|shells|sound|tasks|tex|text|utils|vcs|video|web|x11|xfce|zope"
# Exclude Unknown
# official_sections:
sections="admin|cli-mono|comm|database|debug|devel|doc|editors|education|electronics|embedded|fonts|games|gnome|gnu-r|gnustep|graphics|hamradio|haskell|httpd|interpreters|introspection|java|javascript|kde|kernel|libdevel|libs|lisp|localization|mail|math|metapackages|misc|net|news|ocaml|oldlibs|otherosfs|perl|php|python|ruby|rust|science|shells|sound|tasks|tex|text|utils|vcs|video|web|x11|xfce|zope"
#
while IFS=: read -r key value; do
  case $key in
  "Architecture") test -n "$(echo $value | grep -E "all|amd64|arm64")" || syntax wrong_arch $value ;;
  "Maintainer") test -n "$(echo $value | grep -E ".*\<.*\@.*\..*\>")" || syntax wrong_maintainer $value ;;
  "Section") test -n "$(echo $value | grep -E "${sections}")" || syntax wrong_section $value ;;
  "Priority") test -n "$(echo $value | grep -E "optional|standard|important|required|extra")" || syntax wrong_priority $value ;;
  "Depends")
    while IFS=" " read -r p v; do
      # echo "pkg:$p, version:[$v]"
      # if no version specified, just check package exist
      test -n "$v" || test -z "$(dpkg-query --show --showformat='${db:Status-Status}\n' $p | grep -v installed)" || syntax wrong_depends "$p"
      test -z "$v" && continue
      # 如果有版本要求，比较版本号
      required=$(echo "$v" | sed -e 's_<=_le_g' -e 's_>=_ge_g' -e 's_!=_ne_g' |
        sed -e 's_<_lt_g' -e 's_=_eq_g' -e 's_>_gt_g' | tr -d '(' | tr -d ')')
      installed_version=$(dpkg-query -W --showformat='${Version}' $p 2>/dev/null)
      # echo "$p Req:[$required]"
      test -n "$installed_version" || syntax wrong_depends "$p"
      dpkg --compare-versions "$installed_version" $required || syntax wrong_depends "$p"
    done <<<$(echo "$value" | tr ',' "\n")
    ;;
  esac
done <DEBIAN/control
#
# Step 4. check file system permission
# Exclude DEBIAN dir.
test -z "$(find . -path "./DEBIAN" -prune -o -perm /go+w -ls | grep -v DEBIAN)" || syntax wrong_permission
#
# Step 5. check all preinst/prerm/postinst/postrm steps for dangerous operations
for f in preinst prerm postinst postrm; do
  test ! -f DEBIAN/$f && continue
  test -z "$(grep -w -E "rm|chmod|chown|sudo" "DEBIAN/$f")" || syntax dangerous_script
done
#
# Step 6. security check
# 6.1 clamav AntiVirus
# 6.2 scanelf elf check
# Todo 6.3 use lynis to audit system after install
#
! command -v clamscan >/dev/null || clamscan --quiet -r . || syntax av_error
! command scanelf >/dev/null || scanelf -qR . || syntax scanelf_error
#
echo "All audit passed." && rm -rf ../$DIR
