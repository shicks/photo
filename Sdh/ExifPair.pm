# An image+exif file pair.
# Stores two filenames, allows mutating them in parallel.

package Sdh::ExifPair;

use strict;
use warnings;

use Sdh::Time;

# Timestamp prefix.
my $timestamp_re = qr/
  (?:^|\/\K)
  (?:19|20)\d\d-\d\d?-\d\d?
  T
  \d\d?:\d\d?
  [^_]*
  (?=_)
/x;

sub _find {
  my ($pat,) = @_;
  open RESULTS, "ls $pat |";
  my @lines = <RESULTS>;
  close RESULTS;
  @lines = grep { chomp $_; $_ } @lines;
  die "Ambiguous or missing matches for $pat" unless @lines == 1;
  return $lines[0];
}

# Given a filename, finds its pair.
sub new {
  my ($cls, $file) = @_;
  die "Could not find file: $file" unless -e $file;
  die "All exif pair files must be timestamp-prefixed: $file"
    unless $file =~ /$timestamp_re/;
  my $date = Sdh::Time::parse($&);
  my ($image, $exif);
  if ($file =~ /\.exif$/) {
    $exif = $file;
    ($image = $exif) =~ s/\.exif$//;
    if (! -e $image) {
      (my $pattern = $image) =~ s/$timestamp_re/*/;
      $image = _find($pattern);
      die "Bad prefix for image: $image" unless $image =~ /$timestamp_re/;
    }
  } else {
    $image = $file;
    $exif = "$image.exif";
    if (! -e $exif) {
      (my $pattern = $exif) =~ s/$timestamp_re/*/;
      $exif = _find($pattern);
      die "Bad prefix for exif: $exif" unless $exif =~ /$timestamp_re/;
    }
  }

  bless {image => $image, exif => $exif, date => $date}, $cls;
}

sub _rename {
  my ($self, $type, $name) = @_;
  die "Cowardly refusing to clobber $name" if -e $name;
  rename $self->{$type}, $name;
  $self->{$type} = $name;
  $name =~ /$timestamp_re/ or die "impossible";
  $self->{'date'} = Sdh::Time::parse($&);
}

# Renames the image file to match the exif file.
sub fix_image {
  my ($self,) = @_;
  my $newimage = $self->{'exif'};
  $newimage =~ s/\.exif$//;
  $self->_rename('image', $newimage);
}

# Renames the exif file to match the image file.
sub fix_exif {
  my ($self,) = @_;
  my $newexif = $self->{'image'} . '.exif';
  $self->_rename('exif', $newexif);
}

# Renames whichever is not consistent with the stored date.
sub fix {
  my ($self,) = @_;
  $self->set_date($self->date());
}

# Renames both files, keeping the suffix the same.
sub set_prefix {
  my ($self, $newprefix) = @_;
  die "Bad prefix: $newprefix" unless "${newprefix}_" =~ /$timestamp_re/;
  my $newimage = $self->{'image'};
  $newimage =~ s/$timestamp_re/$newprefix/;
  $self->_rename('image', $newimage);
  $self->_rename('exif', "$newimage.exif");
}

# Changes exif data, argument is a direct hash.
sub set_tags {
  my $self = shift;
  my %tags = @_;
  my @lines = ();
  open EXIF, "<$self->{'exif'}";
  while (<EXIF>) {
    next unless /\S/;
    die "Bad data in exif file: $_" unless /^(.*?)\t/;
    push @lines, $_ unless defined $tags{$1};
  }
  close EXIF;
  foreach (keys %tags) {
    push @lines, "$_\t$tags{$_}\n";
  }
  @lines = sort @lines;
  local($") = '';
  open EXIF, ">$self->{'exif'}";
  print EXIF "@lines";
  close EXIF;
}

# Returns all the exif info as a hash.
sub info {
  my ($self,) = @_;
  my %tags = ();
  open EXIF, "<$self->{'exif'}";
  while (<EXIF>) {
    next unless /\S/;
    chomp $_;
    die "Bad data in exif file: $_" unless /^(.*?)\t(.*)$/;
    $tags{$1} = $2;
  }
  close EXIF;
  return %tags;
}

# Returns the image name.
sub image {
  my ($self,) = @_;
  return $self->{'image'};
}

# Gets the current date.
sub date {
  my ($self,) = @_;
  return $self->{'date'}->clone();
}

# Sets the date, both in filenames and in exif data.
# Affects the following EXIF tags:
#   EXIF:DateTimeOriginal => "2016:02:14 22:02:23"
#   EXIF:CreationDate => "2016:02:14 22:02:23"
#   EXIF:ModifyDate => "2016:02:14 22:02:23"
#   MakerNotes:TimeZone => "-07:00"
#   MakerNotes:TimeZoneCity => "Los Angeles"
sub set_date {
  my ($self, $date) = @_;
  $self->set_prefix(Sdh::Time::iso8601($date));
  my $exiftime = $date->ymd(':') . ' ' . $date->hms(':');
  my %tags = (
    'EXIF:DateTimeOriginal' => $exiftime,
    'EXIF:CreationDate' => $exiftime,
    'EXIF:ModifyDate' => $exiftime,
  );
  my $tz = $date->time_zone();
  if ($tz && !$tz->is_floating()) {
    $tags{'MakerNotes:TimeZone'} = Sdh::Time::offset($date);
    my $name = $tz->name();
    if ($name =~ /^[a-z_]+\/([a-z_]+)$/i) {
      my $city = $1;
      $city =~ s/_/ /g;
      $tags{'MakerNotes:TimeZoneCity'} = $city;
    }
  }
  $self->set_tags(%tags);
}

1;
