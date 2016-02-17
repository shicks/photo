# Scans a directory tree and runs a function on each file.

package Sdh::Tree;

use strict;
use warnings;

sub _run {
  my ($func, $path, $opts) = @_;
  if (-d $path) {
    if ($opts->{'recursive'}) {
      my @files = (); # Collect first
      opendir DIR, $path;
      while ($_ = readdir DIR) {
	next if $_ eq '.' or $_ eq '..';
        push @files, $_;
      }
      foreach (@files) {
	_run($func, "$path/$_", $opts);
      }
    } else {
      print STDERR "Skipping directory $path\n";
    }
  } elsif (!-e $path) {
    print STDERR "No such file $path\n";
  } else {
    &$func($path);
  }  
}

# Usage: Sdh::Tree::run(\&process, \@paths, {recursive => 1});
sub run {
  my ($func, $paths, $opts) = @_;

  foreach (@$paths) {
    _run($func, $_, $opts);
  }
}

1;
