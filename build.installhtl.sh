#! /bin/bash --
#
# build.installhtl.sh: builds install-htl and install.tgz from installerbin.sfx.7z and release.i386-linux/htl20[0-9][0-9].sfx.7z
#
set -ex

type -p tar
type -p xz
type -p gzip
# Created with: rm -f installerbin.sfx.7z && time 7z a -sfx../../../../../../../../../../../../../../../../"$PWD"/tiny7zx -t7z -mx=7 -md=32m -ms=on -mf=bcj installerbin{.sfx.7z,}
# -mf=bcj is important, because tiny7zx breaks for the default (because of SPARC executables), and also breaks (with ERROR: #6) for -mf=bcj2.
test -f installerbin.sfx.7z
test -f release.i386-linux/htl2010.sfx.7z
test -f install-htl0.pl
USE_7Z=
type -p 7z && USE_7Z=1

rm -rf buildtar.tmp
mkdir buildtar.tmp
for D in installerbin.sfx.7z release.i386-linux/htl20[0-9][0-9].sfx.7z; do
  R="${D%.sfx.7z}"
  R="${R##*/htl}"
  test -d "buildtar.tmp/htl$R" && exit 2
  #test -d "buildtar.tmp/installerbin" && exit 2
  if test "$USE_7Z"; then
    (cd buildtar.tmp && 7z x ../"$D") || exit "$?"
  else
    (cd buildtar.tmp && ../"$D") || exit "$?"
  fi
  if test "${D#*/htl20}" != "$D"; then
    test -f "buildtar.tmp/htl$R/tlpkg/texlive.tlpdb"
    # TODO(pts): Do we want to include lz4 for all platforms?
    rm -rf "buildtar.tmp/htl$R"/tlpkg/installerbin/xz
    rm -rf "buildtar.tmp/htl$R"/tlpkg/installerbin/wget
    rm -rf "buildtar.tmp/htl$R"/tlpkg/installerbin/lz4
    rm -rf "buildtar.tmp/htl$R"/tlpkg/installerbin/config.guess
  else
    test -f buildtar.tmp/installerbin/wget/wget.i386-freebsd.2010
    test -f buildtar.tmp/installerbin/xz/xzdec.i386-freebsd.2010
    test -f buildtar.tmp/installerbin/config.guess
  fi
done

(cd buildtar.tmp/installerbin && tar -cf - wget/wget.*) | (cd buildtar.tmp && tar -xf -) || exit "$?"
find buildtar.tmp/wget -iname '*.exe.*' | xargs -d '\n' -- rm -f --  # Windows. It doesn't work, not even cygwin.
rm -f buildtar.tmp/tar.ok
# --sort=name puts same-architecture files next to each other.
(cd buildtar.tmp && tar --posix -c --sort=name wget && :>tar.ok) | xz -8 >buildtar.tmp/wget.txz
test -f buildtar.tmp/tar.ok
test -s buildtar.tmp/wget.txz

rm -f buildtar.tmp/tar.ok
# `xz -8' needs 33 MiB memory for the decompressor.
(cd buildtar.tmp && tar --posix -c --sort=name htl20[0-9][0-9] && :>tar.ok) | xz -8 >buildtar.tmp/htl.txz
test -f buildtar.tmp/tar.ok
test -s buildtar.tmp/htl.txz

(cd buildtar.tmp/installerbin && tar -cf - xz/xz*) | (cd buildtar.tmp && tar -xf -) || exit "$?"
find buildtar.tmp/xz -iname '*.exe.*' | xargs -d '\n' -- rm -f --  # Windows. It doesn't work, not even cygwin.

(cd buildtar.tmp/installerbin && tar -cf - config.guess) | (cd buildtar.tmp && tar -xf -) || exit "$?"

rm -f buildtar.tmp/tar.ok
# `tar --posix' is the same format as in
# http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/2010/tlnet-final/archive/texlive-infra.tar.xz
(cd buildtar.tmp && tar --posix -c --sort=name xz config.guess wget.txz htl.txz && :>tar.ok) | gzip -9 >buildtar.tmp/buildtar.tgz
test -f buildtar.tmp/tar.ok
test -s buildtar.tmp/buildtar.tgz
mv buildtar.tmp/buildtar.tgz install.tgz
rm -rf buildtar.tmp
ls -l install.tgz
rm -f install-htl
cat install-htl0.pl install.tgz >install-htl
chmod +x install-htl
ls -l install-htl

: build.installhtl.sh OK.
