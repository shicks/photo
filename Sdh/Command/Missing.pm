# Determines which time ranges are missing geo data.

package Sdh::Command::Missing;

use strict;
use warnings;

use Getopt::Long qw(:config gnu_getopt bundling);
use Sdh::Command;
use Sdh::Geo::Track;
use Sdh::Ranges;

our $command = Sdh::Command->new(
  summary => 'Displays the missing time ranges.',
  usage => <<EOF,
Usage: photo missing [OPTIONS...]
Options:
  --db=DATABASE      Sets the geotag database file [~/.track]
EOF
  run => sub {
    my $db = '';
    GetOptions(
      'db=s' => \$db,
    );

    my $track = Sdh::Geo::Track->new($db);
    die "Unxpected arguments: @main::ARGV" if @main::ARGV;

    my $ranges = Sdh::Ranges->new();
    foreach ($track->all_times()) {
      $ranges->add($_ - 86400, $_ + 86400);
    }
    my @ranges = $ranges->get();
    print "                          -∞ .. ";
    for (my $i = 0; $i < @ranges; $i += 2) {
      my $end = `date -jf \%s $ranges[$i]`;
      my $start = `date -jf \%s $ranges[$i + 1]`;
      chomp $start; chomp $end;
      print "$end\n$start .. ";
    }
    print "∞\n";
  },
);

1;
