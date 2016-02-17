#!/usr/bin/perl

# Usage: tag [--db=FILE] PATH...
# Updates the geotag for each image using the GPS data.

package Sdh::Command::Geotag;

use warnings;
use strict;

use Sdh::ExifPair;
use Sdh::Geo::Track;
use Getopt::Long qw(:config gnu_getopt require_order bundling);
use Image::ExifTool qw(:Public);


our $command = Sdh::Command->new(
  summary => 'Adds geotags to files based on database.',
  usage => <<EOF,
Usage: photo geotag [OPTIONS...] FILES...
Options:
  --db=DATABASE      Sets the geotag database file [~/.track]
  --recursive,   -r  Scan paths recursively
EOF
  run => sub {
    my $db = '';
    my $recursive = '';
    GetOptions(
      'recursive|r' => \$recursive,
      'db=s' => \$db,
    );

    my $track = Sdh::Geo::Track->new($db);
    @main::ARGV = Sdh::Tree::recurse(@main::ARGV) if $recursive;

    foreach my $path (@main::ARGV) {
      my $exif = Sdh::ExifPair->new($path);
      my %info = $exif->info();
      next if defined $info{'EXIF:GPSLatitude'}; # Skip already-tagged files
      my $date = $exif->date();
      my $loc = $track->get($date->epoch()) or next;
      my ($lat, $lon, $alt) = split /\s+/, $loc;
      # TODO(sdh): currently ignoring altitude because don't know how to do ref
      my $latref = $lat < 0 ? 'S' : 'N';
      my $lonref = $lon < 0 ? 'W' : 'E';
      my $altref = $alt < 0 ? '1' : '0';
      $exif->set_tags(
        'EXIF:GPSLatitude' => abs($lat) . '',
        'EXIF:GPSLatitudeRef' => $latref,
        'EXIF:GPSLongitude' => abs($lon) . '',
        'EXIF:GPSLongitudeRef' => $lonref,
        'EXIF:GPSAltitude' => abs($alt) . '',
        'EXIF:GPSAltitudeRef' => $altref,
      );
    }
  },
);

1;
