# Re-exports photos.
#  - Finds photo/exif pairs.
#  - Sets the date from filename into the exif
#  - Writes the exif into the image
# TODO(sdh): should we bother renaming the files? the timestamp could be nice.
# TODO(sdh): can we upload directly to google?

package Sdh::Command::Export;

use strict;
use warnings;

use Date::Parse;
use File::Basename qw(basename dirname);
use Getopt::Long qw(:config gnu_getopt bundling);
use Sdh::Command;
use Sdh::Exif;
use Sdh::ExifPair;
use Sdh::Time;
use Sdh::Tree;

sub run {
  my $recursive = 0;
  GetOptions('recursive|r' => \$recursive);

  our %visited = ();

  sub process {
    my $path = shift or die 'No path given';
    return unless -e $path; # note: we sometimes move files
    my $pair = Sdh::ExifPair->new($path);
    $pair->fix();
    my $date = $pair->date();
    my $image = $pair->image();
    return if $visited{$image};
    $visited{$image} = 1;
    my $exif = Sdh::Exif->new($image);
    my %info = $pair->info();
    $exif->save(%info);
  }
  Sdh::Tree::run(\&process, \@main::ARGV, {recursive => $recursive});
}

our $command = Sdh::Command->new(
  run => \&run,
  summary => 'Exports photos by re-merging metadata.',
  usage => <<EOF,
Usage: photo export [OPTIONS...] PATH...
Options:
  --recursive, -r    Process directories recursively.
EOF
);

1;
