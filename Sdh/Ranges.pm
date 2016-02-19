# Simple range set utility.

package Sdh::Ranges;

sub new {
  my ($cls,) = @_;
  bless [], $cls;
}

sub find {
  my ($self, $v) = @_;
  my @r = @$self;
  if (!@r || $v <= $r[0]) {
    return 0;
  } elsif ($v > $r[$#r]) {
    return scalar(@r);
  }
  my $a = 0;
  my $b = $#r;
  while ($b > $a + 1) {
    my $m = int(($b + $a) / 2);
    my $mv = $r[$m];
    return $m if $v == $mv;
    $b = $m if $v < $mv;
    $a = $m if $v > $mv;
  }
  return $b;
}

sub add {
  my ($self, $start, $end) = @_;
  my $si = $self->find($start);
  my $ei = $self->find($end);
  #print STDERR "start=$start, end=$end, si=$si, ei=$ei\n";
  $start = $self->[--$si] if $si % 2 == 1;
  $end = $self->[$ei++] if $ei % 2 == 1;
  $start = $self->[$si -= 2] if $si > 1 && $start == $self->[$si - 1];
  if ($ei < @$self - 1 && $end == $self->[$ei]) {
    $end = $self->[++$ei];
    $ei++;
  }
  #print STDERR "si=$si, ei=$ei, start=$start, end=$end\n";
  splice(@$self, $si, $ei - $si, $start, $end);
}

sub get {
  my ($self,) = @_;
  return @$self;
}

1;
