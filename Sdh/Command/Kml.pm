# Command for reading KML files and storing into the geotag database.

package Sdh::Command::Kml;

use strict;
use warnings;

use Getopt::Long qw(:config gnu_getopt bundling);
use Sdh::Command;
use Sdh::Geo::Track;
use Sdh::Tree;

our $command = Sdh::Command->new(
  summary => 'Read KML data into the database.',
  usage => <<EOF,
Usage: photo kml [OPTIONS...] FILES...
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

    local ($/) = undef;
    $_ = <>;

    $track->add_kml($_);
  },
);

1;
