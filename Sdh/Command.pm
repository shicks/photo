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

# Maps command to package
my %commands = ();
# Maps package to usage string
my %usages = ();
# Maps package to one-line summaries
my %summaries = ();
# Maps package to options
my %options = ();
# Maps package to extra argument spec ('', FILE, RECURSIVE)
my %extra = ();



# Called by main
sub run {


}



sub import {
  my $pkg = shift;
  my %args = @_;
  return unless $args{'command'};
  
  my $callpkg = caller(0);
  
  use Attribute::Handlers;




}


# Usage:
#   my $whatever :flag(help => 'Some flag', default => 3, spec => 'foo|f=s');
#   my @list :flag(help => 'blah', spec => 'blah=s@');
#   my @comma :flag(help => 'blah', spec => 'stuff=s', delim => /,/);

sub ::flag :ATTR {
  my @arg = @{$_[4]};
  die "Bad flag" unless @arg == 2;
  my $pkg = $_[0];
  my $spec = $arg[0]; # string
  my $desc = $arg[1]; # string
  ### todo - check that we have a var reference, find out what kind
  # parse the $spec -> if there's an = then it takes an argument
  #   -- changes how we deal with the reference

  my $parsed = $spec;
  my $argtype = '';
  $argtype = $1 if $parsed =~ s/=(.+)$//;
  my $multi = $1 = $argtype =~ s/^.\K([@%])$//;
  die "Don't support multiple args: $spec" if length($argtype) > 1;
  my $falseable = $parsed =~ s/!$//;
  my $incremental = $parsed =~ s/\+$//;

  my $reftype = ref $_[2];
  if ($reftype eq 'SCALAR') {
    
  } elsif ($reftype eq '
}




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
