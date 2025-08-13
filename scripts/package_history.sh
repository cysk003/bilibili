#!/bin/sh
# Check package installation history
# Tested on Debian only so far
# Last Modified: 2025-08-02
#
# MIT License
#
# Copyright (c) 2025 LeisureLinux
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
export LC_ALL=C
[ -z "$1" ] && echo "Syntax: $0 <package_name>" && exit 0
PKG="$1"
(for L in /var/log/dpkg.log /var/log/dpkg.log.1 $(ls /var/log/dpkg.log.*.gz); do
  sudo zgrep -E "(install|upgrade|remove|purge) ${PKG}.+:" $L
done) | sort
