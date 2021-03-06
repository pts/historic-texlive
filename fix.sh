#! /bin/bash
#
# fix.sh: convert TeXlive scheme-basic direcrtory to much smaller historic-texlive (htl) directory
# by pts@fazekas.hu at Fri Jan 18 21:01:49 CET 2019

set -ex

test -z "$HTLFIXDIR" && HTLFIXDIR="${0%/*}"

test -f "$HTLFIXDIR/mktexlsr"
test -f tlpkg/texlive.tlpdb

# for F in 201{1,2,3,4,5,6}; do cp -a "$(find htl"$F" -name tlmgr.pl)"{,.orig};  cp -a "$(find htl"$F" -name TLUtils.pm)"{,.orig}; done

grep -Fx 'name texlive.infra' tlpkg/texlive.tlpdb
grep -Fx 'name texlive.infra.i386-linux' tlpkg/texlive.tlpdb

# The user should edit tlpkg/texlive.tlpdb first. and remove packages.
grep -Fx 'name tetex' tlpkg/texlive.tlpdb && exit 2
grep -Fx 'name kpathsea' tlpkg/texlive.tlpdb && exit 2
grep -F 'x86_64' tlpkg/texlive.tlpdb && exit 2
grep -F 'amd64' tlpkg/texlive.tlpdb && exit 2

TLMGRPL="$(find texmf*/ -type f -name tlmgr.pl)"
test "$TLMGRPL"
test "$TLMGRPL" = texmf-dist/scripts/texlive/tlmgr.pl || test "$TLMGRPL" = texmf/scripts/texlive/tlmgr.pl

# The user should apply the patch first.
grep -qF '$::_platform_ =' "$TLMGRPL"

# The user should apply the patch first.
grep -F SELFAUTOPARENT tlpkg/TeXLive/*.pm | grep -vF 'C<$SELFAUTOPARENT>' | grep -vF '$::installerdir or' && exit 2

(<tlpkg/texlive.tlpdb perl -ne 'print if s@^ @./@'
echo '
./texmf.cnf
./texmfcnf.lua
./tlpkg/texlive.profile
./tlpkg/texlive.tlpdb
./texmf-config/web2c/updmap.cfg
./texmf-dist/web2c/updmap.cfg
./texmf-var/tex/generic/config/language.def
./texmf-var/tex/generic/config/language.dat.lua
./texmf-var/tex/generic/config/language.dat
./texmf/scripts/texlive/tlmgr.pl
./texmf-dist/scripts/texlive/tlmgr.pl
') >keep.lst || exit "$?"
find -type l | grep -vFxf keep.lst | xargs -d '\n' -- rm -f --
find -type f | grep -vFxf keep.lst | xargs -d '\n' -- rm -f --  # Also deletes keep.lst.

rm -f texmf.bin
find -type f -name '*~' | xargs -d '\n' -- rm -f --
rm -f texmf*/ls-R
find texmf* -depth -mindepth 1 -type d | xargs -d '\n' -- rmdir -- ||:  # Remove empty directories.
# Create the file so that it shows up in ls-R by mktexlsr, so that
# `kpsewhich fmtutil.cnf' run by fmtutil-sys will find
# texmf-var/web2c/fmtutil.cnf rather than texmf/web2c/fmtutil.cnf, and thus
# will prevent the creation of omega.fmt (and it won't fail).
grep -q '^catalogue-version 2008' tlpkg/texlive.tlpdb && mkdir -p texmf-var/web2c && touch texmf-var/web2c/fmtutil.cnf

("$HTLFIXDIR/mktexlsr" texmf texmf-*) || exit "$?"
ln -s bin/i386-linux texmf.bin  # For compatibility with portable-tetex.
rm -rf bin/*
mkdir bin/i386-linux
ln -s ../../"$TLMGRPL" bin/i386-linux/tlmgr

: fix.sh OK.
