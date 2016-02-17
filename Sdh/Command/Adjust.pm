# Command to shift/adjust time information

# In particular, operate in two modes:
#   1. --timezone=America/Denver --location=Albuquerque
#      assumes UTC time from camera is correct, but changes TZ and localtime
#   2. --shift=PT1H
#      retains same time zone, shifts the UTC time

# Would also be useful to have a 'filter' command to only pick
# e.g. photos w/in a given range, or photos from a given camera.
# Might want to be flexible (for grep/globbing purposes) about
# whether we accept image or exif files here - whichever we do,
# we should find the equivalent image file and operate on that
# (or else always keep both in sync, as well as exif contents?)
#   -- could also provide a tool to resync
#      (1) exif-to-jpg, (2) jpg-to-exif, or (3) reread-exif
# 

# Usage: photo adjust --timezone=America/Denver --location=Albuquerque files...

package Sdh::Command::Adjust;

use strict;
use warnings;

use Getopt::Long qw(:config gnu_getopt bundling);
use Sdh::Command;
use Sdh::ExifPair;
use Sdh::Tree;

sub run {
  my $recursive = 0;
  our $timezone = '';
  our $location = '';
  our $shift = '';
  GetOptions(
    'recursive|r' => \$recursive,
    'shift|s=s' => \$shift,
    'location|l=s' => \$location,
    'timezone|z=s' => \$timezone,
  );
  sub process {
    my ($file,) = @_;
    my $exif = Sdh::ExifPair->new($file);
    if ($timezone) {
      my $date = $exif->date();
      $date->set_time_zone($timezone);
      $exif->set_date($date);
    }
    if ($location) {
      $exif->set_tags('MakerNotes:TimeZoneLocation' => $location);
    }
    if ($shift) {
      my $date = $exif->date();
      my $duration = Sdh::Time::parse($shift);
      $exif->set_date($date + $duration);
    }
  }
  Sdh::Tree::run(\&process, \@main::ARGV, {recursive => $recursive});
}

our $command = Sdh::Command->new(
  run => \&run,
  summary => 'Adjusts photos\'s timezones, locations, or timestamps.',
  usage => <<EOF,
Usage: photo adjust [OPTIONS...] PATH...
Options:
  --recursive,     -r   Process directories recursively.
  --timezone=ZONE, -z   Set photos to the given timezone.
                        May be numeric (e.g. -08:00) or
                        absolute (e.g. EST5EDT) or a location
                        (e.g. America/Los_Angeles).
  --location=LOC,  -l   Sets the reference location.
  --shift=SHIFT,   -s   Shifts the timestamp, retaining the
                        timezone unchanged.
EOF
);

1;
