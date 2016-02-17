# Performs initial import on a directory.
#  - For each photo/video, renames based on time, and extracts exif info
#  - Filename format is ISO datetime w/ millis and TZ, followed by underscore
#    and original filename (lowercased)
#  - Exif file is exif_ followed by original filename

# TODO(sdh): consider a --copy option that would
# make a new timestamped directory and copy into it
# from some external source (e.g. memory card or phone)

package Sdh::Command::Import;

use strict;
use warnings;

use Date::Parse;
use File::Basename qw(basename dirname);
use Getopt::Long qw(:config gnu_getopt bundling);
use Sdh::Command;
use Sdh::Exif;
use Sdh::Time;
use Sdh::Tree;

sub run {
  my $recursive = 0;
  GetOptions('recursive|r' => \$recursive);

  @main::ARGV = Sdh::Tree::recurse(@main::ARGV) if $recursive;
  foreach my $path (@main::ARGV) {
    my $base = basename($path);
    my $dir = dirname($path);

    # Skip the file if it's already renamed...
    my $timere = qr/
      (?:19|20)\d\d(?:-\d\d?){2}       # 2016-01-25
      T                                # T
      \d\d?(?::\d\d){1,2}              # 01:12:25
      (?:\.\d{1,6})?                   # .123456
      (?:[-+]?\d\d?(?::?\d\d?){0,2})?  # +02:00
    /x;

    return if $base =~ /^${timere}_/; # already handled.

    print STDERR "Importing photo $path\n";
    my $exif = Sdh::Exif->new($path);
    my %info = $exif->info();

    # Extract time information and change the filename.
    my $time = $info{'EXIF:DateTimeOriginal'};
    my $zone = $info{'MakerNotes:TimeZone'};

    if ($time) {
      # Convert the time to valid ISO8601 by changing the
      # first two ':' to '-' and changing the space to 'T'.
      $time =~ s/:/-/;
      $time =~ s/:/-/;
      $time =~ s/ /T/;
      if ($zone) {
        $zone = "+$zone" if $zone =~ /^\d/;
        $time = "$time$zone";
      }
      $time = Sdh::Time::parse($time);
    } else {
      $time = DateTime->from_epoch(epoch => $exif->mtime(), time_zone => 'UTC');
    }

    $time = Sdh::Time::iso8601($time);
    my $newpath = $base;
    $newpath =~ tr/A-Z/a-z/;
    $newpath = "$dir/${time}_$newpath";
    rename $path, $newpath;

    # Write all the exif data to a separate file.
    print STDERR "Writing $newpath.exif\n";
    open EXIF, ">$newpath.exif";
    foreach (sort keys %info) {
      print EXIF "$_\t$info{$_}\n";
    }
    close EXIF;
  }
}

our $command = Sdh::Command->new(
  run => \&run,
  summary => 'Imports photos by splitting out metadata.',
  usage => <<EOF,
Usage: photo import [OPTIONS...] PATH...
Options:
  --recursive, -r    Process directories recursively.
EOF
);

1;
