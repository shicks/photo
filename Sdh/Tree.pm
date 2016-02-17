# Scans a directory tree and runs a function on each file.

package Sdh::Tree;

use strict;
use warnings;

# Usage: @main::ARGV = Sdh::Tree::recurse(@main::ARGV) if $recursive;
sub recurse {
  local $_;
  my @files = ();
  while (my $path = shift) { 
    if (-d $path) {
      opendir DIR, $path;
      while ($_ = readdir DIR) {
	next if $_ eq '.' or $_ eq '..';
	push @files, recurse("$path/$_");
      }
      closedir DIR;
    } elsif (-e $path) {
      push @files, $path;
    } else {
      print STDERR "No such file $path\n";
    }
  }
  return @files;
}

1;
