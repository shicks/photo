package Sdh::Util;

use strict;
use warnings;

# Validates that a hash has only certain keys.
# Args:
#   0. requird arguments as array ref
#   1. optional args as hash to defaults
#   2. actual hash
# Returns:
#   Hash elements filled in and validated.
sub validate_hash {
  local $_;
  my ($req, $opt, $act) = @_;
  my %allowed = ();
  my %result = ();
  foreach (@$req) {
    $allowed{$_} = 1;
    die "Missing hash key: $_" unless defined $act->{$_};
    $result{$_} = $act->{$_}
  }
  foreach (keys %$opt) {
    $allowed{$_} = 1;
    $result{$_} = defined $act->{$_} ? $act->{$_} : $opt->{$_};
  }
  foreach (keys %$act) {
    die "Illegal hash key: $_" unless $allowed{$_};
  }
  return %result;
}
