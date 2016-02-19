# Geo::Track module
# Uses sqlite3 to read/write a track from KML files.
# Provides the following API:
#   my $track = Geo::Track->open("$HOME/.track");
#   $track->add(time, location);
#   $track->get(time);

package Sdh::Geo::Track;

use strict;
use warnings;

use Date::Parse qw(str2time);

sub new {
  my ($class, $db) = @_;
  $db = $db || "$ENV{'HOME'}/.track";
  my $self = {db => $db,
	      tol => 3600};
  if (! -e $db) {
    # Initialize if it doesn't exit yet.
    open SQL, "| sqlite3 $db";
    print SQL "CREATE TABLE track(time INTEGER PRIMARY KEY, loc TEXT);\n";
    close SQL;
  }
  return bless $self, $class;
}

# Sets the tolerance (in seconds) for get() calls.
sub tol {
  my ($self, $tol) = @_;
  $self->{'tol'} = $tol;
}

sub add {
  my ($self, $time, $loc) = @_;
  $time = sprintf '%d', $time;  # Truncate fractional part
  $loc =~ s/'//g;
  my $db = $self->{'db'};
  open SQL, "| sqlite3 $db";
  print SQL "INSERT OR IGNORE INTO track VALUES($time, '$loc');\n";
  close SQL;
}

# $track->bulk_add [t1, l1], [t2, l2], ...
# Takes a list of two-element array refs.
sub bulk_add {
  my $self = shift;
  my @values = ();
  while (my $ref = shift) {
    my $time = sprintf '%d', $ref->[0];  # Truncate fractional part
    my $loc = $ref->[1];
    $loc =~ s/'//g;
    push @values, "($time, '$loc')";
  }
  my $db = $self->{'db'};
  open SQL, "| sqlite3 $db";
  local($") = ',';
  print SQL "INSERT OR IGNORE INTO track VALUES@values;\n";
  close SQL;
}

sub get {
  my ($self, $time) = @_;
  $time = sprintf '%d', $time;  # Truncate fractional part
  my $db = $self->{'db'};

  # Plan: Get the nearest two points, forward and backwards.
  my $select = "SELECT * FROM track";
  my $query1 = "$select WHERE time <= $time ORDER BY time DESC LIMIT 1;";
  my $query2 = "$select WHERE time >= $time ORDER BY time LIMIT 1;";
  open SQL, "sqlite3 $db '$query1 $query2' |";
  my $bestTime = 0;
  my $bestLoc = '';
  while (<SQL>) {
    /(\d+)\|(.*)/ or die "Bad output from SQL: $&";
    my $trackTime = $1;
    my $trackLoc = $2;
    if (abs($time - $trackTime) < abs($time - $bestTime)) {
      $bestTime = $trackTime;
      $bestLoc = $trackLoc;
    }
  }
  my $delta = abs($time - $bestTime);
  return $delta <= $self->{'tol'} ? $bestLoc : '';
}

sub add_kml {
  my ($self, $kml) = @_;
  my $time = 0;
  my @points = ();
  while ($kml =~ /<(when|gx:coord)>([^<]*)<\/\g1>/g) {
    #print STDERR "Entry: $1 => $2\n";
    if ($1 eq 'when') {
      $time = str2time($2);
    } else {
      push @points, [$time, $2];
      if (@points > 100000) {
        print STDERR "Writing 100000 points ending at $time\n";
        $self->bulk_add(@points);
        @points = ();
      }
    }
  }
  if (@points) {
    $self->bulk_add(@points);
  }
}

sub all_times {
  local $_;
  my ($self,) = @_;
  my $db = $self->{'db'};
  my @result = ();
  my $query = "SELECT time FROM track ORDER BY time;";
  open SQL, "sqlite3 $db '$query' |";
  while (<SQL>) {
    chomp $_;
    push @result, int($_);
  }
  close SQL;
  return @result;
}

1;
