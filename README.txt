historic-texlive: convenient installers for old TeX Live releases
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
historic-texlive is a set of scripts and binary executable for Unix for easy
and convenient installation of TeX Live 2010--2018. Currently only the
i386-linux platform is supported.

How to install and use:

* Download your desired release (any of TeX Live 2010--2018) an .sfx.7z file from
  https://github.com/pts/historic-texlive/tree/master/release.i386-linux

* Make the .sfx.7z file executable with chmod +x.

* Run the .sfx.7z file as non-root.

* Run

    $ HTLDIR/bin/i386-linux/tlmgr install scheme-basic

  to get plain TeX and LaTeX. Specify HTLDIR as an absolute pathname.

  (Alternatively you can install other schemes.
  For TeX Live 2016 or later, the smallet scheme is scheme-infraonly, and
  scheme-minial also works. For TeX Live 2015 and earlier the smallest
  scheme is scheme-minimal.)

* To try pdflatex, run

    $ HTLDIR/bin/i386-linux/pdflatex hello

historic-texlive downloads packages from this repository (mirror):
http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/YYYY/tlnet-final

Alternatively, change the repository by running:

  $ HTLDIR/tlmgr option repository ftp://tug.org/historic/systems/texlive/YYYY/tlnet-final

__END__
