historic-texlive: convenient installers for old TeX Live releases
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
historic-texlive is a set of scripts and binary executable for Unix for easy
and convenient installation of TeX Live 2010--2018. Currently only the
i386-linux platform is supported.

How to install and use:

1. Run this (without the leading $) on an i386-linux system to install TeX
   Live 2016 to the directory htl2016:

     $ sh -c "$(wget -qO- https://github.com/pts/historic-texlive/raw/master/install.sh )" . 2016

   Instead of 2016 above, any TeX Live release between 2010 and 2018 works.

2. Run this to install LaTeX:

     $ "$PWD"/htl2016/bin/i386-linux/tlmgr install scheme-basic

3. Compile a document with pdflatex:

     $ "$PWD"/htl2016/bin/i386-linux/tlmgr install MYDOC.tex

The manual alternative of the installation step 1 above:

1a. Download your desired release (any of TeX Live 2010--2018) as an .sfx.7z
    file from
    https://github.com/pts/historic-texlive/tree/master/release.i386-linux

1b. Make the .sfx.7z file executable with chmod +x.

1c. Run the .sfx.7z file as non-root.

As an alternative to the installation step 2 above:

2a. Install only plain TeX:

     $ "$PWD"/htl2016/bin/i386-linux/tlmgr install scheme-minimal

As an alternative to the installation step 2 above for TeXLive 2016--:

2k. Install only TeX Live packaging infrastructure (no TeX):

     $ "$PWD"/htl2016/bin/i386-linux/tlmgr install scheme-infraonly

Additionally, between steps 1 and 2 above, change the repository:

12. Run:

      $ "$PWD"/htl2016/tlmgr option repository ftp://tug.org/historic/systems/texlive/YYYY/tlnet-final

    Without change the repository, historic-texlive downloads packages from
    this repository (mirror):
    http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/YYYY/tlnet-final

__END__
