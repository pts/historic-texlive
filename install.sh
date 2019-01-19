#! /bin/bash --
#
# install.sh: easy net-installer of historic-texlive
# by pts@fazekas.hu at Sat Jan 19 02:34:00 CET 2019
#

function die() {
  echo "historic-texlive installer: fatal: $*" >&2
  exit 2
}

if test $# = 0 || test "$0" = --help; then
  echo "This is historic-texlive net-installer for i386-linux.
Usage: $0 <release-year>
Output directory is htl<release-year>
The historic-texlive project: https://github.com/pts/historic-texlive" >&2
  exit 1
fi

RELEASE="$1"
case "$RELEASE" in
20[0-9][0-9]) ;;
*) die "bad release ID: $RELEASE" >&2
exit 1
esac

test -d htl"$RELEASE" && die "directory already exists, not clobbering: htl$RELEASE"

if test "$0" != . && test "${0%*[a-z]sh}" = "$0" && test -f "${0%/*}/release.i386-linux/htl$RELEASE.sfx.7z"; then
  ./"${0%/*}/release.i386-linux/htl$RELEASE.sfx.7z" -y ||
      die "extraction failed: ${0%/*}/release.i386-linux/htl$RELEASE.sfx.7z"
else
  URL=https://github.com/pts/historic-texlive/raw/master/release.i386-linux/htl"$RELEASE".sfx.7z
  rm -f htl"$RELEASE".7z.sfx.tmp
  wget -nv -O htl"$RELEASE".7z.sfx.tmp "$URL" || die "download failed; $URL"
  if ! chmod +x htl"$RELEASE".7z.sfx.tmp; then
    rm -f htl"$RELEASE".7z.sfx.tmp
    die "chmod failed:  htl$RELEASE.7z.sfx"
  fi
  ./htl"$RELEASE".7z.sfx.tmp -y  # This works only on i386-linux.
  STATUS="$?"
  rm -f htl"$RELEASE".7z.sfx.tmp
  test "$STATUS" = 0 || die "extraction failed: ./htl$RELEASE.7z.sfx -y"
fi

test -f htl"$RELEASE"/tlpkg/texlive.tlpdb ||
    die "missing file: htl$RELEASE/tlpkg/texlive.tlpdb"
test -f htl"$RELEASE"/bin/i386-linux/tlmgr ||
    die "missing file: htl$RELEASE/bin/i386-linux/tlmgr"

# TODO(pts): Escape spaces in $PWD etc.
echo
echo "Run this to get latex:      $PWD/htl$RELEASE/bin/i386-linux/tlmgr install scheme-basic"
echo "latex will be available as: $PWD/htl$RELEASE/bin/i386-linux/latex"

: install.sh OK.
