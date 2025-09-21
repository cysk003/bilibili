#!/bin/bash
# Search music cover and lyrics
# Copyright: LeisureLinux@Bilibili
# VERSION: 1.0.2
# License: MIT
#
[ -z "$1" ] && echo "Syntax: $0 mp3_file" && exit
if ! command -v eyeD3 sacad syncedlyrics >/dev/null; then
  echo "Please [pip3 or apt] install eyeD3 or sacad or syncedlyrics"
  exit 1
fi
while
  read artist
  read album
do
  [ -z "$artist" -o -z "$album" ] && echo "Error: failed to read artist/album" && break
  echo "Info: Found artist: $artist, album: $album"
  if [ -z "$(eyeD3 "$1" | grep ^FRONT_COVER)" ]; then
    img="/tmp/$album.jpg"
    echo "Info: Searching and write temp image to $img"
    proxychains -q sacad -v quiet "$artist" "$album" 400 "$img"
    [ -s "$img" ] && eyeD3 -Q --add-image "$img":FRONT_COVER "$1" && echo "Info:Added cover img to music"
    # echo "Error: failed to find image."
    rm "$img"
  else
    echo "Info: Front cover already there"
  fi
  f=$(basename "$1" ".mp3")
  if [ ! -r "$f.lrc" ]; then
    echo "Info: Searching lyrics"
    syncedlyrics -v -p lrclib netease --synced-only --enhanced $(basename "$1" .mp3) -o "$f.lrc"
    # -p {musixmatch,lrclib,netease,megalobiz,genius}
  fi
  if [ -s "$f.lrc" ]; then
    echo "New lyric downloaded as $f.lrc"
  else
    echo "Failed to find any lyrics online for $1"
  fi
done < <(eyeD3 "$1" | grep -E "^album:|^artist:" | awk -F: '{print $NF}')
