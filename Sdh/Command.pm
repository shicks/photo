# Module for registering commands.


# TODO - consider a :tag interface where modules can
# specify a function or two, and tag args w/ their
# key and helptext, etc.  different "modes" for the
# main function -> all files, imagepairs, etc
#   - the latter would automatically maintain a list
#     of visited images and would pass in ExifPair objs
# also, auto-add to the list of commands...
# also add --help support everywhere...?


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
