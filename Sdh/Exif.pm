# Wrapper around Image::ExifTool.
# Each object contains exif information for a single file.

package Sdh::Exif;

use strict;
use warnings;

use Image::ExifTool qw(:Public);

# Reads an image file.
sub new {
  my ($cls, $file) = @_;
  my @stat = stat $file;
  my $self = {
    file => $file,
    exif => Image::ExifTool->new(),
    info => {},
    read_info => 0,
    stat => \@stat,
  };
  return bless $self, $cls;
}

# Prints out a fatal error if the arg isn't true.
sub must_succeed {
  my ($self, $success) = @_;
  if (!$success) {
    my $error = $self->{'exif'}->GetValue('Error');
    die "EXIF operation failed: $error";
  }
}

# Gets the file's modification time, in seconds since the epoch.
sub mtime {
  my ($self,) = @_;
  return $self->{'stat'}->[9];
}

# Gets the info tags, returning as a hash reference.
sub info {
  my ($self,) = @_;
  my $exif = $self->{'exif'};
  return $self->{'info'} if $self->{'read_info'};
  # TODO - consider options: FastScan=1 or 2?
  $self->must_succeed($exif->ExtractInfo($self->{'file'}, {Composite => 0}));
  my $info = $exif->GetInfo();
  foreach (keys %$info) {
    my $group = $exif->GetGroup($_, 0);
    my $tag = "$group:$_";
    $tag =~ s/\s+\(\d+\)$//;
    my $value = $info->{$_};
    $self->{'info'}->{$tag} = $value;
  }
  return $self->{'info'};
}

# Writes the hash.
sub write_info {
  my $self = shift;
  my %tags = @_;
  my %info = $self->info();
  foreach (keys %info) {
    $tags{$_} = '' unless defined $tags{$_};
  }
  my $diff = 0;
  foreach (keys %tags) {
    if ($tags{$_} eq $info{$_}) {


      ##### TODO - what was supposed to go here?

    }
    $self->{'exif'}->SetNewValues($_, $tags{$_}) unless ;
  }
  
}

1;
