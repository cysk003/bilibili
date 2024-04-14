#!/bin/sh
# TL'DR: My own dman, grab man page from debian.org
# Ver 0.1.1
# Author: Bilibili ID: LeisureLinux
# Last Modified: 2024年 04月 14日 星期日 21:26:23 CST
#
set -e
PROG=$1
[ -z "$PROG" ] && echo "Syntax: $0 prog_name" && exit 0
tmp_file="/tmp/dman.$PROG.$$"
BASE_URL="https://manpages.debian.org"
CURL_OPT="-sSL"
raw=$(curl $CURL_OPT "$BASE_URL/$PROG" | awk -F'"' '/raw man page/ {print $2}')
[ -z "$raw" ] && echo "Error: raw man page for $PROG not found!" && exit 1
curl -sSf "$BASE_URL"/"$raw" -o "$tmp_file"
man -l "$tmp_file" && rm "$tmp_file"
