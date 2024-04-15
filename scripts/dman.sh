#!/bin/sh
# TL'DR: My own dman, grab man page from manpages.debian.org
# Ver 0.2.1
# Author: Bilibili ID: LeisureLinux
# Last Modified: 2024年 04月 14日 星期日 21:26:23 CST
#
set -e
[ -z "$1" ] && echo "Syntax: $0 prog_name" && exit 0
BASE_URL="https://manpages.debian.org"
raw=$(curl -sSL "$BASE_URL/$1" | awk -F'"' '/raw man page/ {print $2}')
[ -z "$raw" ] && echo "Error: raw man page for $1 not found!" && exit 1
curl -sSf "$BASE_URL"/"$raw" -o - | man -l -
