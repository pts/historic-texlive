#!/usr/bin/env perl
#
# install.pl: historic-texlive Unix install script
#
# Requirements:
#
# * a Unix system (e.g. Linux, macOS)
# * perl
# * gzip, gunzip or zcat
# * tar which can extract POSIX tar archives
# * a reasonable (Bourne) shell as /bin/sh
#

# Like `use strict;', but succeed if strict.pm is missing.
BEGIN { eval { require strict; strict->import() } }
BEGIN { eval { require integer; integer->import() } }
BEGIN { $^W = 1 }  # use warnings;

{
  my $handler = sub { $SIG{$_[0]} = 'DEFAULT'; kill($_[0], $$); };
  for my $sig (qw(HUP INT QUIT ABRT TERM)) {
    $SIG{$sig} = $handler;
  }
}

# --- Command-line processing.

my $release;
my $targetdir;
my $is_unix = 0;
my $do_keep_tmp = 0;
my $installer;  # Filename, file in .tar.gz format.
my $platform;  # E.g. 'i386-linux'.

die "This is historic-texlive net-installer for Unix.
Usage: $0 <release-year> [<targetdir>]
Default <targetdir> is htl<release-year>
The historic-texlive project: https://github.com/pts/historic-texlive
Command-line flags:
--release=<release-year>
--targetdir=<targetdir>  Specify directory to install to.
--force-unix  Disable operating system detection, force Unix.
--platform=<platform>  Set platform to use instead of autodetect.
--keep-tmp  Keep the temporary directory on exit.
    Example: sparc-solaris i386-linux x86_64-linux
" if !@ARGV or $ARGV[0] eq "--help";

{
  my $i = 0;
  while ($i < @ARGV) {
    my $arg = $ARGV[$i];
    last if $arg !~ m@\A-@;
    $i++;
    last if $arg eq "--";
    if ($arg =~ m@\A--release(?:-year)?=(.*)@s) { $release = $1 }
    elsif ($arg =~ m@\A--targetdir=(.*)@s) { $targetdir = $1 }
    elsif ($arg =~ m@\A--installer=(.*)@s) { $installer = $1 }
    elsif ($arg =~ m@\A--platform=(.*)@s) { $platform = $1 }
    elsif ($arg eq "--force-unix") { $is_unix = 1 }
    elsif ($arg eq "--keep-tmp") { $do_keep_tmp = 1 }
    else { die "fatal: unknown command-line flag: $arg\n" }
  }
  $release = $ARGV[$i++] if $i < @ARGV;
  $targetdir = $ARGV[$i++] if $i < @ARGV;
  die "fatal: too many command-line arguments\n" if $i > @ARGV;
}

# ---

# Doesn't indicate failure.
sub delete_recursively_silently($);
sub delete_recursively_silently($) {
  if (!lstat($_[0])) {}
  elsif (!-d(_)) { unlink($_[0]) }
  else {
    my $dh;
    if (opendir($dh, $_[0])) {
      my @entries = grep { $_ ne '.' and $_ ne '..' } readdir($dh);
      closedir($dh);
      my $prefix = "$_[0]/";
      for my $e (@entries) { delete_recursively_silently($prefix . $e) }
    }
    rmdir($_[0]);
  }
}

my $tmpdir;

sub cleanup() {
  # TODO(pts): Kill tar first to make sure it is not creating files in a
  # directory we are deleting.
  delete_recursively_silently($tmpdir) if !$do_keep_tmp and defined($tmpdir);
}
END { cleanup(); }  # Not called on SIGINT.
{
  my $handler = sub { $SIG{$_[0]} = 'DEFAULT'; cleanup(); kill($_[0], $$); };
  for my $sig (qw(HUP INT QUIT ABRT TERM)) {
    $SIG{$sig} = $handler;
  }
}

die "fatal: --release not specified, specify e.g. --release=2018\n" if
    !defined($release);
die "fatal: invalid release syntax: $release\n" if
    $release !~ m@\A20\d\d[^/\0\x27\"\\\$]*\Z(?!\n)@;
$targetdir = "htl$release" if !defined($targetdir);
$targetdir =~ s@\A-@./-@;  # For easier argument passing to cd.

print STDERR "info: installing TeX Live $release to: $targetdir\n";

die "fatal: this script needs a Unix system, running on $^O\n" if
    !$is_unix and $^O =~ m@mswin|dos|amigaos|epoc|os2@i;


die "fatal: target directory $targetdir already exists, not clobbering\n" if
    -d($targetdir);
$tmpdir = "$targetdir.htltmp";
delete_recursively_silently($tmpdir);
die "fatal: could not create temporary directory $tmpdir: $!\n" if
    !mkdir($tmpdir) or !-d($tmpdir);

# Quote string from Bourne-like shells.
sub shqe($) {
  return $_[0] if $_[0]=~/\A[-.\/\w][-.\/\w=]*\Z(?!\n)/;
  my $S=$_[0];
  $S=~s@'@'\\''@g;
  "'$S'"
}

my $zcat_cmd;
sub detect_zcat() {
  if (!defined($zcat_cmd)) {
    my $ztbindat = "ZT\0\xff";
    my $ztbingz = "$tmpdir/zt.bin.gz";
    my $fh;
    die "fatal: open-write $ztbingz: $!\n" if !open($fh, ">", $ztbingz);
    # .gz-compressed $ztbindat.
    my $s = pack("H*", "1f8b08000231435c02038b0a61f80f003b5943c304000000");
    if ((syswrite($fh, $s, length($s)) or 0) != length($s)) {
      my $msg = "$!";
      unlink($ztbingz);
      die "fatal: error writing to $ztbingz: $msg\n";
    }
    close($fh);
    for my $cmd ("gzip -cd", "gunzip -c", "zcat") {
      my $t = readpipe("$cmd <" . shqe($ztbingz) . " #\#");
      if (defined($t) and $t eq $ztbindat) { $zcat_cmd = $cmd; last }
    }
    unlink($ztbingz);
    die "fatal: zcat, gzip or gunzip not found\n" if !defined($zcat_cmd);
  }
  $zcat_cmd
}

sub extract_embedded_targz_to_tmpdir(;$) {
  my $s = $_[0];  # .tar.gz input bytes to write first.
  $s = "" if !defined($s);
  my $fh;
  unlink("$tmpdir/zcat.ok");
  my $cmd = "| cd " . shqe($tmpdir) . " && (" . detect_zcat() . " && :>zcat.ok) | tar -xf - #\$";
  die "fatal: error opening tar-x embedded\n" if !open($fh, $cmd);
  while (1) {
    if (length($s)) {
      die "fatal: error writing to tar-x embedded: $!\n" if
          (syswrite($fh, $s, length($s)) or 0) != length($s);
    }
    # sysread doesn't work well for DATA> Using read.
    last if !read(DATA, $s, 65536);
  }
  die "fatal: tar-x embedded failed\n" if !close($fh);
  die "fatal: zcat failed for tar-x embedded\n" if !-f("$tmpdir/zcat.ok");
  unlink("$tmpdir/zcat.ok");
}

sub extract_targz_to_tmpdir($) {
  my $fn = $_[0];
  die "fatal: missing targz $fn: $!\n" if !-f($fn);
  unlink("$tmpdir/zcat.ok");
  my $cmd = "exec < " . shqe($fn) . " && (" . detect_zcat() . " && :>" . shqe("$tmpdir/zcat.ok") . ") | (cd " . shqe($tmpdir) . " && tar -xf -) #\$";
  die "fatal: tar-x failed\n" if system($cmd);
  die "fatal: zcat failed for tar-x\n" if !-f("$tmpdir/zcat.ok");
  unlink("$tmpdir/zcat.ok");
}

sub extract_tarxz_to_tmpdir($$;$) {
  my ($fn, $xzcat_cmd, $tar_args) = @_;
  $tar_args = "" if !defined($tar_args);
  die "fatal: missing tarxz $fn: $!\n" if !-f($fn);
  unlink("$tmpdir/xzcat.ok");
  my $cmd = "exec < " . shqe($fn) . " && ($xzcat_cmd && :>" . shqe("$tmpdir/xzcat.ok") . ") | (cd " . shqe($tmpdir) . " && tar -xf - $tar_args) #\$";
  die "fatal: tar-x failed\n" if system($cmd);
  die "fatal: xzcat failed for tar-x\n" if !-f("$tmpdir/xzcat.ok");
  unlink("$tmpdir/xzcat.ok");
}

print STDERR "info: extracting installer to $tmpdir\n";
{
  my $s;
  if (!defined($installer) and read(DATA, $s, 64) and length($s) == 64) {
    $s =~ s@\A\s+@@;  # Not needed if .xz starts after "__DATA__\n".
    extract_embedded_targz_to_tmpdir($s);
  } else {
    my $installer0 = $installer;
    if (!defined($installer)) {
      my $basedir = $0;
      die "fatal: specify full pathname for installer: $0\n" if
          $basedir !~ s@/+[^/]+(?!\n)\Z@@;
      $installer = "$basedir/install.tgz";
    }
    if (!-f($installer)) {
      my $extra = "";
      $extra = "; use install-htl instead to solve this" if
          !defined($installer0) and $0 =~ m@-htl0[.]pl\Z(?!\n)@;
      die "fatal: missing installer targz $installer$extra\n";
    }
    extract_targz_to_tmpdir($installer);
  }
}
die "fatal: installer file not found: $tmpdir/config.guess\n" if
    !-f("$tmpdir/config.guess");
die "fatal: installer file not found: $tmpdir/wget.txz\n" if
    !-f("$tmpdir/wget.txz");
die "fatal: installer dir not found: $tmpdir/xz\n" if
    !-d("$tmpdir/xz");

sub detect_platform() {
  # Adding #$ so that Perl will run /bin/sh.
  my $guessed_platform = readpipe(". " . shqe($tmpdir) . "/config.guess #\$");
  chomp($guessed_platform) if defined($guessed_platform);
  die "fatal: $tmpdir/config.guess has failed\n" if !$guessed_platform;
  print STDERR "info: output of config.guess: $guessed_platform\n";
  # The rest of this function is based on Tex Live 2018 TeXLive/TLUtils.pm.
  $guessed_platform =~ s/^x86_64-(.*-k?)(free|net)bsd/amd64-$1$2bsd/;
  my $CPU; # CPU type as reported by config.guess.
  my $OS;  # O/S type as reported by config.guess.
  ($CPU = $guessed_platform) =~ s/(.*?)-.*/$1/;
  $CPU =~ s/^alpha(.*)/alpha/;   # alphaev whatever
  $CPU =~ s/mips64el/mipsel/;    # don't distinguish mips64 and 32 el
  $CPU =~ s/powerpc64/powerpc/;  # don't distinguish ppc64
  $CPU =~ s/sparc64/sparc/;      # don't distinguish sparc64
  # armv6l-unknown-linux-gnueabihf -> armhf-linux (RPi)
  # armv7l-unknown-linux-gnueabi   -> armel-linux (Android)
  if ($CPU =~ /^arm/) {
    $CPU = $guessed_platform =~ /hf$/ ? "armhf" : "armel";
  }
  my @OSs = qw(aix cygwin darwin freebsd hpux irix
               kfreebsd linux netbsd openbsd solaris);
  for my $os (@OSs) {
    # Match word boundary at the beginning of the os name so that
    #   freebsd and kfreebsd are distinguished.
    # Do not match word boundary at the end of the os so that
    #   solaris2 is matched.
    $OS = $os if $guessed_platform =~ /\b$os/;
  }
  if ($OS eq "linux") {
    # deal with the special case of musl based distributions
    # config.guess returns
    #   x86_64-pc-linux-musl
    #   i386-pc-linux-musl
    $OS = "linuxmusl" if $guessed_platform =~ /\blinux-musl/;
  }
  if ($OS eq "darwin") {
    # We have two versions of Mac binary sets.
    # 10.10/Yosemite and newer (Yosemite specially left over):
    #   -> x86_64-darwin [MacTeX]
    # 10.6/Snow Leopard through 10.10/Yosemite:
    #   -> x86_64-darwinlegacy if 64-bit
    #
    # (BTW, uname -r numbers are larger by 4 than the Mac minor version.
    # We don't use uname numbers here.)
    #
    # this changes each year, per above:
    my $mactex_darwin = 10;  # lowest minor rev supported by x86_64-darwin.
    #
    # Most robust approach is apparently to check sw_vers (os version,
    # returns "10.x" values), and sysctl (processor hardware).
    chomp (my $sw_vers = `sw_vers -productVersion`);
    my ($os_major,$os_minor) = split (/\./, $sw_vers);
    if ($os_major != 10) {
      warn "$0: only MacOSX is supported, not $OS $os_major.$os_minor "
           . " (from sw_vers -productVersion: $sw_vers)\n";
      return "unknown-unknown";
    }
    if ($os_minor >= $mactex_darwin) {
      ; # current version, default is ok (x86_64-darwin).
    } elsif ($os_minor >= 6 && $os_minor < $mactex_darwin) {
      # in between, x86 hardware only.  On 10.6 only, must check if 64-bit,
      # since if later than that, always 64-bit.
      my $is64 = $os_minor == 6
                 ? `/usr/sbin/sysctl -n hw.cpu64bit_capable` >= 1
                 : 1;
      if ($is64) {
        $CPU = "x86_64";
        $OS = "darwinlegacy";
      } # if not 64-bit, default is ok (i386-darwin).
    } else {
      ; # older version, default is ok (i386-darwin, powerpc-darwin).
    }
  } elsif ($CPU =~ /^i.86$/) {
    $CPU = "i386";  # 586, 686, whatever
  }
  ($OS = $guessed_platform) =~ s/.*-(.*)/$1/ if !defined($OS);
  return "$CPU-$OS";
}

my $detected_platform;
$platform = $detected_platform = detect_platform() if !defined($platform);
print STDERR "info: using platform: $platform\n";

sub find_progs($$) {
  my ($dir, $prog) = @_;
  my @progs = ($prog);
  if ($progs[0] =~ s@[.]YEAR\Z(?!\n)@.@) {
    my $prefix = pop(@progs);
    my $dh;
    die "fatal: opendir $dir: $!\n" if !opendir($dh, $dir);
    my @entries = readdir($dh);  # TODO(pts): Don't read twice for xz and xzdec.
    closedir($dh);
    # reverse so that the last year comes first.
    # It's OK if @progs is empty.
    @progs = reverse sort grep { substr($_, 0, length($prefix)) eq $prefix and m@[.]20\d\d\Z(?!\n)@ }
        @entries;
    if ($prefix =~ s@[.]([^-./]+)-([^-./]+)[.]\Z(?!\n)@@ and $1 ne "universal") {
      $prefix .= ".universal-$2.";  # For xzdec.universal-darwin.2010 .
      push @progs, reverse sort grep
          { substr($_, 0, length($prefix)) eq $prefix } @entries;
    }
  }
  @progs
}

my $dtbindat = "DT\0\xff";
sub create_dtbinxz($) {
  my $fh;
  die "fatal: open-write $_[0]: $!\n" if !open($fh, ">", $_[0]);
  # .xz-compressed $dtbindat.
  my $s = pack("H*", "fd377a585a000004e6d6b4460200210116000000742fe5a3010003445400ff0087d9341b4930069900011c046f2c9cc11fb6f37d010000000004595a");
  die if (syswrite($fh, $s, length($s)) or 0) != length($s);
  close($fh);
}

sub find_xz($$$$) {
  my ($dir, $prog, $args, $expected_output) = @_;
  my @progs = find_progs($dir, $prog);
  for $prog (@progs) {
    my $cmd = shqe($dir) . "/" . shqe($prog) . " $args 2>/dev/null #\$";
    my $s = readpipe($cmd);
    return "$dir/$prog" if defined($s) and $s eq $expected_output;
  }
  undef  #die "fatal: working xz not found: %dir/$prog\n";
}

sub list_platforms() {
  my $dh;
  my %h;
  if (opendir($dh, "$tmpdir/xz")) {
    %h = map { m@\Axz(?:dec)?[.]([^./]+)@ ? ($1 => 1) : () } readdir($dh);
    closedir($dh);
  }
  sort keys %h
}

my $dtbinxz = "$tmpdir/dt.bin.xz";
my ($xz_prog, $xzdec_prog);
eval {
  create_dtbinxz($dtbinxz);
  $xz_prog = find_xz("$tmpdir/xz", "xz.$platform.YEAR", "-dcf <" . shqe($dtbinxz), $dtbindat);
  if (defined($xz_prog)) { print STDERR "info: found xz: $xz_prog\n" }
  else {
    my @progs = find_progs("$tmpdir/xz", "xz.$platform.YEAR");
    if (@progs) { print STDERR "info: xz not working, found: @progs\n" }
    else { print STDERR "info: xz not found\n" }
  }
  $xzdec_prog = find_xz("$tmpdir/xz", "xzdec.$platform.YEAR", "-dc <" .shqe($dtbinxz), $dtbindat);
  if (defined($xzdec_prog)) { print STDERR "info: found xzdec: $xzdec_prog\n" }
  else {
    my @progs = find_progs("$tmpdir/xz", "xzdec.$platform.YEAR");
    if (@progs) { print STDERR "info: xzdec not working, found: @progs\n" }
    else { print STDERR "info: xzdec not found\n" }
  }
};
my $error = $@;
unlink($dtbinxz);
die $@ if $@;
my $xzcat_cmd;
if (defined($xzdec_prog)) {
  $xzcat_cmd = shqe($xzdec_prog) . " -dc";
} elsif (defined($xz_prog)) {
  $xzcat_cmd = shqe($xz_prog) . " -dc";
} else {
  my $extra = "";
  if (!defined($detected_platform)) {
    $detected_platform = detect_platform();
    print STDERR "info: detected platform: $detected_platform\n";
  }
  # Not all TeX Live releases are available on all platforms.
  # TODO(pts): Add a release-specific platform list here.
  print STDERR "info: available platforms: @{[list_platforms()]}\n";
  if ($platform ne $detected_platform) {
    $extra = " (maybe because bad --platform=$platform value?)";
  }
  # TODO(pts): Better failure condition: for TeX Live 2018, we need xz, otherwise we need xzdec.
  die "fatal: neither xz nor xzdec work$extra\n" if !defined($xz_prog) and !defined($xzdec_prog);
}

print STDERR "info: extracting release htl$release to $tmpdir\n";
eval { extract_tarxz_to_tmpdir("$tmpdir/htl.txz", $xzcat_cmd, shqe("htl$release")) };
if ($@ or !-f("$tmpdir/htl$release/tlpkg/texlive.tlpdb")) {
  my $error = "$@";
  my %r;
  my $s = (readpipe("$xzcat_cmd <".shqe("$tmpdir/htl.txz") . " | tar -tf -") or "");
  while ($s =~ m@^htl(\d\d\d\d[^/]*)@mg) {
    $r{$1} = 1;
  }
  my @releases = sort keys %r;
  die $error if !@releases;
  die "fatal: release $release not supported by this installer; these releases are supported: @releases\n" .
      "fatal: get newest installer from https://github.com/pts/historic-texlive\n";
}

die "fatal: requested release not found: $release\n" if
    !-f("$tmpdir/htl$release/tlpkg/texlive.tlpdb");

print STDERR "info: extracting wget to $tmpdir\n";
extract_tarxz_to_tmpdir("$tmpdir/wget.txz", $xzcat_cmd);

sub find_wget($$) {
  my ($dir, $prog) = @_;
  my @progs = find_progs($dir, $prog);
  for $prog (@progs) {
    my $cmd = (defined($dir) ? shqe($dir) . "/" : "") . shqe($prog) . " --help 2>&1 #\$";
    my $s = readpipe($cmd);
    return defined($dir) ? "$dir/$prog" : "$prog" if
        defined($s) and $s =~ m@[ \t]-q[, \t][^\n]*[Qq]uiet@;
  }
  undef
}

my $wget_prog = find_wget("$tmpdir/wget", "wget.$platform.YEAR");
$wget_prog = find_wget(undef, "wget") if !defined($wget_prog);
if (defined($wget_prog)) { print STDERR "info: found wget: $wget_prog\n" }
else                     { print STDERR "info: wget not found\n" }
# TeX Live 2018 can use curl, LWP etc. instead of wget.

sub get_installer_basename($) {
  my $basename = $_[0];
  $basename =~ s@\A.*/@@s;
  # Rmove .20XX year suffix.
  die "fatal: bad basename: $basename\n" if $basename !~ s@[.][^./]+\Z(?!\n)@@;
  $basename;
}

sub do_move($$) {
  my ($old, $new) = @_;
  print STDERR "info: moving $old to $new\n";
  die "fatal: rename: $!\n" if !rename($old, $new);
}

sub create_symlink($$) {
  my ($old, $new) = @_;
  print STDERR "info: creating symlink $new to $old\n";
  unlink($new);
  die "fatal: symlink from $new: $!\n" if !symlink($old, $new);
}

sub create_platform_symlink($$) {
  my ($dir, $basename) = @_;
  my $basename0 = $basename;
  # Make sure we have an exectuable named after our $platform, i.e. create
  # symlink xz.x86_64-darwin to xz.universal-darwin.
  if ($basename =~ s@[.][^-./]+-[^-./]+\Z(?!\n)@.$platform@s and $basename ne $basename0) {
    create_symlink($basename0, "$dir/$basename");
  }
}

my $xz_dir = "$tmpdir/htl$release/tlpkg/installer/xz";
mkdir($xz_dir);  # Don't check for errors.
if (defined($xz_prog)) {
  my $basename = get_installer_basename($xz_prog);
  do_move($xz_prog, "$xz_dir/$basename");
  create_platform_symlink($xz_dir, $basename);
}
if (defined($xzdec_prog)) {
  my $basename = get_installer_basename($xzdec_prog);
  do_move($xzdec_prog, "$xz_dir/$basename");
  create_platform_symlink($xz_dir, $basename);
}

my $wget_dir = "$tmpdir/htl$release/tlpkg/wget";
mkdir($wget_dir);  # Don't check for errors.
if (defined($wget_prog) and $wget_prog =~ m@/@) {
  my $basename = get_installer_basename($wget_prog);
  do_move($xz_prog, "$wget_dir/$basename");
  create_platform_symlink($wget_dir, $basename);
}

sub set_tlpdb_platform($;$) {
  my ($fn, $platform2) = @_;
  $platform2 = $platform if !defined($platform2);
  my $fh;
  die "fatal: open $fn: $!\n" if !open($fh, '+<', $fn);
  my $s = join('', <$fh>);
  die "fatal: platform not defined in: $fn\n" if
      $s !~ s@^(depend setting_available_architectures:)\S+$@$1$platform2@gm;
  die "fatal: seek $fn: $!\n" if !seek($fh, 0, 0);
  die "fatal: write $fn: $!\n" if !print($fh $s);
  die "fatal: close $fn: $!\n" if !close($fh);
}

print STDERR "info: setting tlpdb platform in: $tmpdir/htl$release/tlpkg/texlive.tlpdb\n";
set_tlpdb_platform("$tmpdir/htl$release/tlpkg/texlive.tlpdb");

do_move("$tmpdir/htl$release/bin/i386-linux", "$tmpdir/htl$release/bin/$platform") if
    $platform ne "i386-linux";
unlink("$tmpdir/htl$release/texmf.bin");  # Don't check for errors.
create_symlink("bin/$platform", "$tmpdir/htl$release/texmf.bin");

sub path_to_absolute($) {
  # We could `use Cwd', but better not rely on that.
  return $_[0] if substr($_[0], 0, 1) eq "/";
  my $path = $_[0];
  my $s = readpipe("pwd");
  chomp($s) if defined($s);
  die "fatal: pwd failed\n" if !defined($s) or !length($s);
  die "fatal: not an absolute path: $s\n" if $s !~ m@\A/@;
  $path =~ s@\A(?:[.]/)+@@;
  "$s/$path"
}

do_move("$tmpdir/htl$release", $targetdir);
delete_recursively_silently($tmpdir);
$do_keep_tmp = 1;

my $abstargetdir = path_to_absolute($targetdir);
print "
Run this to get latex:      $abstargetdir/bin/$platform/tlmgr install scheme-basic
latex will be available as: $abstargetdir/bin/$platform/latex\n"

__DATA__
