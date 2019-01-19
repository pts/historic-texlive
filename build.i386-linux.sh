#! /bin/bash --
set -ex

test -z "$PTLFIXDIR" && PTLFIXDIR="${0%/*}"
cd "$PTLFIXDIR"

test $# = 0 && set htl20[0-9][0-9]

test -f fix.sh
test -f tiny7zx
test -f htl2011/tlpkg/texlive.tlpdb
type -p 7z

for D in "$@"; do
  test -d "$D" || continue
  (cd "$D" && PTLFIXDIR=.. && . ../fix.sh) || exit "$?"
  rm -f release.i386-linux/"$D".sfx.7z
  time 7z a -sfx../../../../../../../../../../../../../../../../"$PWD"/tiny7zx -t7z -mx=7 -md=32m -ms=on release.i386-linux/"$D".sfx.7z "$D"
done

: build.sh OK.
