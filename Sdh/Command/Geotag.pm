#!/usr/bin/perl

# Usage: tag [--db=FILE] PATH...
# Updates the geotag for each image using the GPS data.

package Sdh::Command::Geotag;

use warnings;
use strict;

use Sdh::Geo::Track;
use Getopt::Long qw(:config gnu_getopt require_order bundling);
use Image::ExifTool qw(:Public);

my $db = '';
my $recursive = 0;
GetOptions(
  'db=s' => \$db,
  'recursive|r' => \$recursive,
);

my $track = Sdh::Geo::Track->new($db);

# new plan:
#  - initial process by renaming photo to
#        yyyy-mm-ddThh:mm:ss.mmm-tz:00_orig.jpg
#    dumping all exif data to a set of flat files exif_orig.jpg
#    as plain-text associative arrays (escaping newlines and backslashes)
#  - provide scripts to manipulate filenames and exifs
#  - script to add geotagging to exif files
#  - final process to merge final results, renaming back to original
# benefits:
#  - single initial wait (copy/dump), then all processing happens instantly
#  - could merge the dump with a smart import script that deduped
#  - final processor could move to a "to upload" folder?

sub tag {
  my $path = shift;
  if (-d $path) {
    if ($recursive) {
      my @contents = ();
      opendir DIR, $path;
      while ($_ = readdir DIR) {
	next if $_ eq '.' or $_ eq '..';
	tag("$path/$_");
      }
    } else {
      print STDERR "Skipping directory $path\n";
    }
    return;
  }
  # Hopefully we have an image file now, so punt over to Image::ExifTool

  our $exif = Image::ExifTool->new();
  sub must_succeed {
    my $success = shift;
    if (!$success) {
      my $error = $exif->GetValue('Error');
      die "EXIF operation failed: $error";
    }
  }

  must_succeed($exif->ExtractInfo($path, {Composite=>0}));
  
  my $write = $ENV{'WRITE'};

  if ($write) {

    my $count = $exif->SetNewValue('EXIF:GPSLatitude' => '19.125');
    $count += $exif->SetNewValue('EXIF:GPSLatitudeRef' => 'South');
    print "Changed $count tags\n";
    must_succeed($exif->WriteInfo($path));

  } else {

    my $info = $exif->GetInfo();
    my %grouped = ();
    foreach (keys %$info) {
      my $group = $exif->GetGroup($_, 0);
      my $tag = "$group:$_";
      $tag =~ s/\s+\(\d+\)$//;
      my $value = $info->{$_};
      $grouped{$tag} = $value;
    }
    foreach (sort keys %grouped) {
      print "$_ => $grouped{$_}\n";
    }

  }

  #print $exif->GetGroup('GPSLatitude (1)');

  # TODO - see if the file has a geotag, and if not, consult the database.
  # TODO - optionally allow outputting a list of untagged files, to
  #        expedite future runs

}

foreach (@ARGV) {
  tag $_;
}
