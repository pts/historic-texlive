historic-texlive: convenient installers for old TeX Live releases
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
historic-texlive is a set of scripts and binary executable for Unix for easy
and convenient installation of TeX Live 2008--2018. All Unix platforms are
supported. Windows (i386-cygwin, x86_64-cygwin, win32) isn't supported.
historic-texlive is useful for compiling old .tex documents reliably, to
reproduce the original output files (.dvi, .ps and .pdf). For writing new
documents, the latest release of TeX Live is recommended.

How to install and use on Unix:

1. Download
   https://github.com/pts/historic-texlive/releases/download/install-htl-v1/install-htl

   As a regular user (non-root), run this to install TeX Live 2016 to the
   directory htl2016:

     $ perl install-htl 2016

   This shows you the tlmgr command to install packages with.

   install-htl has some command-line flags, e.g.

     $ perl install-htl --platform=i386-linux 2016

   Instead of 2016 above, any TeX Live release between 2008 and 2018 works.

   install-htl is self-contained, it doesn't download everything. However,
   you need to run tlmgr after it, which downloads packages from a TeX Live
   repository the usual way.

2. (This step is optional.) If you want to download TeX Live from a specific
   repostory URL, change it by running:

     $ "$PWD"/htl2016/tlmgr option repository ftp://tug.org/historic/systems/texlive/YYYY/tlnet-final

    By default, historic-texlive downloads packages from this repository
    (mirror):
    http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/YYYY/tlnet-final

3. Run this to install LaTeX:

     $ "$PWD"/htl2016/bin/i386-linux/tlmgr install scheme-basic

4. Compile a document with pdflatex:

     $ "$PWD"/htl2016/bin/i386-linux/latex MYDOC.tex

For platform i386-linux there is a simple and leightweight alternative of
step 1 above:

1a. Run this:

     $ sh -c "$(wget -qO- https://github.com/pts/historic-texlive/raw/master/install.sh )" . 2016

The manual alternative of the installation step 1 above is:

1b. Download your desired release (any of TeX Live 2008--2018) as an .sfx.7z
    file from
    https://github.com/pts/historic-texlive/tree/master/release.i386-linux

    Make the .sfx.7z file executable with chmod +x.

    Run the .sfx.7z file as non-root.

An alternative to the installation step 2 above to install plain TeX only
(without LaTeX) is:

2a. Run this:

      $ "$PWD"/htl2016/bin/i386-linux/tlmgr install scheme-minimal

An alternative to the installation step 2 above for TeXLive 2016-- to
install teX Live packaging infrastructure (without any TeX) is:

2k. Run this:

     $ "$PWD"/htl2016/bin/i386-linux/tlmgr install scheme-infraonly

If you need to install a TeX Live release newer than what install-htl
supports, then please request this feature by filing an issue at
https://github.com/pts/historic-texlive/issues

Compatibility notes:

* The earliest possible release historic-texlive will ever support is 2008,
  because that's the earliest release with a net-installer and tlnet folder.
  TeX Live releases --1996--2007 will not be supported.

* As of now, TeX Live 2008 releases on platforms other than i386-linux in
  historic-texlive are missing the lzmadec tool to extract .lzma compressed
  package files. You have to install this tool first to make tlmgr succeed.

__END__
