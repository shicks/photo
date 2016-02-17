# Module for registering commands.

package Sdh::Command;

my %allowed = (
  summary => 1,
  usage => 1,
  run => 1,
);

sub new {
  my $cls = shift;
  my $self = {};
  while (@_) {
    die "Bad argument: $_" unless $allowed{$_[0]};
    $self->{$_[0]} = $_[1];
    shift;
    shift;
  }
  foreach (keys %allowed) {
    die "Missing argument: $_" unless $self->{$_};
  }
  return bless $self, $cls;
}

sub run {
  my $self = shift;
  my $run = $self->{'run'};
  &$run();
}

sub usage {
  my $self = shift;
  return $self->{'usage'};
}

sub summary {
  my $self = shift;
  return $self->{'summary'};
}

1;
