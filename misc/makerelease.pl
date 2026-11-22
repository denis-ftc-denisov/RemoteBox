#!/usr/bin/perl
#
# Makes a remotebox release
#
use strict;
use warnings;
my $releasedir = '~/Documents/Programming/RemoteBoxReleases';
my $srcdir = '~/Documents/Programming/code-repos/git/RemoteBox';


print "Creating Release...\n";
print "Release Directory: $releasedir\n";
print "Source Directory: $srcdir\n";

my $ver = $ARGV[0];
print "$ver\n";

if ($ver) {
    print "Discovered Version: $ver\n";
    print "Creating directory: $releasedir/RemoteBox-$ver\n";
    mkdir ("$releasedir/RemoteBox-$ver", 0755);
    print "Installing Files...\n";
    system("cp -av $srcdir/packagers-readme $releasedir/RemoteBox-$ver");
    system("cp -av $srcdir/docs $releasedir/RemoteBox-$ver");
    system("cp -av $srcdir/share $releasedir/RemoteBox-$ver");
    system("install -m0755 $srcdir/remotebox $srcdir/remotebox-web $releasedir/RemoteBox-$ver");
    print "Creating BZIP Tarball...";
    system("cd $releasedir ; tar --owner=root --group=root -cvjf RemoteBox-$ver.tar.bz2 RemoteBox-$ver");

}
else {
    die "Could not determine version\n";
}
