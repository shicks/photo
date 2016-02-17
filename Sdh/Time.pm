# Time utilities.

package Sdh::Time;

use Scalar::Util qw/blessed/;
use Date::Parse;
use DateTime;
use DateTime::Duration;

my $duration_re = qr/
  P
  (?:(?<Y>\d+)Y)?
  (?:(?<M>\d+)M)?
  (?:(?<W>\d+)W)?
  (?:(?<D>\d+)D)?
  (?:
    T
    (?:(?<h>\d+)H)?
    (?:(?<m>\d+)M)?
    (?:(?<s>\d+)
      (?<ns>\.\d+)?
      S)?
  )?
/x;

# Takes an ISO8601 string and returns either a DateTime or a Duration.
sub parse {
  my ($str,) = @_;
  #print STDERR "PARSE => $str\n";
  if ($str =~ /^$duration_re$/) {
    # Parse a duration
    my $nanos = 0;
    if ($+{'ns'}) {
      $nanos = int($+{'ns'} * 1000000000);
    }
    return DateTime::Duration->new(
      years => int($+{'Y'} || 0),
      months => int($+{'M'} || 0),
      weeks => int($+{'W'} || 0),
      days => int($+{'D'} || 0),
      hours => int($+{'h'} || 0),
      minutes => int($+{'m'} || 0),
      seconds => int($+{'s'} || 0),
      nanoseconds => $nanos,
     );
  } else {
    # Parse a datetime
    my $epoch = str2time($str);
    my $timezone = 'local';
    if ($str =~ /([-+])(\d\d?)(?::(\d\d?))?$/) {
      #print STDERR "TIMEZONE PARSE => $&\n";
      my $sign = $1;
      my $hours = sprintf('%02d', $2);
      my $minutes = sprintf('%02d', $3 || 0);
      $timezone = "$sign$hours$minutes";
      #print STDERR "TIMEZONE => $timezone\n";
    } elsif ($str =~ /Z$/) {
      $timezone = 'UTC';
    }
    #print STDERR "TIMEZONE?? => $timezone\n";
    return DateTime->from_epoch(epoch => $epoch, time_zone => $timezone);
  }
}

# Prints a DateTime or Duration object in full ISO8601 w/ timezone
sub iso8601 {
  my ($obj,) = @_;
  if (blessed($obj) eq 'DateTime') {
    my $tz = $obj->time_zone();
    if ($tz->is_floating()) {
      $tz = '';
    } elsif ($tz->is_utc()) {
      $tz = 'Z';
    } else {
      $tz = offset($obj);
    }
    return $obj->iso8601() . $tz;
  } elsif (blessed($obj) eq 'DateTime::Duration') {
    my $sign = '';
    if ($obj->is_negative()) {
      $sign = '-';
      $obj = $obj->clone()->multiply(-1);
    }
    my @a = $obj->in_units('years', 'months', 'days', 'hours', 'minutes', 'seconds', 'nanoseconds');
    my $ns = sprintf('%09d', $a[6]);
    my $str = "P$a[0]Y$a[1]M$a[2]DT$a[3]H$a[4]M$a[5].${ns}S";
    $str =~ s/\.?0*S/S/;
    $str =~ s/(?<!\d)0[YMDHS]//g;
    $str =~ s/T$//;
    return $str;
  } else {
    die "Formatting unknown type $obj\n";
  }
}

# Returns the offset for a given DateTime, as a "±hh:mm" string.
sub offset {
  my ($datetime,) = @_;
  my $offset = $datetime->offset();
  #print STDERR "OFFSET => $offset\n";
  $offset /= 60;
  my $sign = $offset < 0 ? '-' : '+';
  $offset = abs($offset);
  return sprintf('%s%02d:%02d', $sign, int($offset / 60), int($offset % 60));
}

# # Param: a UTC time, in seconds since the epoch
# # Result: an offset string.
# sub offset_at {
#   my ($time,) = @_;
#   my $offset = `date -j -f \%s $time +\%z`;
#   $offset =~ /^([-+]?)(\d\d)(\d\d)/;
#   my $sign = $1 eq '-' ? '-' : '+';
#   return "$sign$2:$3";
# }

# # Parses a time from string:
# #   Sdh::Time->parse('2016-2-3T1:23:34pm+5')
# sub parse {
#   my ($cls, $str) = @_;

#   my $time = str2time($str);
#   my $offset = ($str =~ /$shift_re$/) ? _parse_shift($&) : 0;
#   bless {time => $time, offset => $offset, location => '', rel => 0}, $cls;
# }

# # Parses a relative time from string:
# #   Sdh::Time->parse_relative('+2:30')
# sub parse_relative {
#   my ($cls, $str) = @_;

#   my $time = _parse_shift($str);
#   bless {time => $time, offset => 0, location => '', rel => 1}, $cls;
# }

# # Adds a relative time:
# sub plus {
#   my ($self, $other) = @_;
#   die "RHS must be a relative time: $other"
# }

1;
