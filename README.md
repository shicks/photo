# photo

Tool suite for simple photo management.

## Purpose

These tools are intended to solve problems that arise while
importing photos from multiple sources, which may have
incorrect time zones or timestamps, and for adding geotags
from KML data.

Existing tools all seem to be lacking in different ways.
In particular,

* Mac Photos has some nice features, but does not work "in place",
  and instead only operates on its own copy of photos that have
  been imported into its database.  This makes it infeasible to
  use other external tools to make up for deficiencies (such as
  automatic geotagging).
* Most visual file managers don't provide direct or easy enough
  access to EXIF data (or any access at all, for many properties).
* Other tools that operate in-place don't seem to provide either
  batch time (zone) shifting, or automatic geotagging, or else
  are more expensive than I want to pay just to find out if they
  have the features I'm looking for.
* Command-line-only tools can (obviously) do any of these things
  but are impractical for dealing with pictures because it's
  difficult to know what picture you're dealing with.  Additionally
  if they are not designed carefully, they can be very slow.

## Design Overview

The basic principle behind this suite is to separate photos
into several easy-to-edit pieces, which can be easily operated
on directly in a low-tech visual file manager, coupled with
scripts that can be invoked either directly through the UI
on selected files, or else on entire directories.  The basic
idea is to leverage existing UI paradigms, rather than
reinventing them.

Thus, the intended workflow is to run an initial processing
job on a directory, which will rename photos into a specific
format `2016-02-15T01:34:05-07:00_img1701.jpg`, which includes
the photo's timestamp and timezone (in ISO 8601 format) followed
by the original filename, delimited with an underscore.  In
addition, an `.exif` file will be written containing tag values
for each image.  The filenames and tag contents can be changed
very efficiently to adjust timestamps or other EXIF tags, and
then a finalize job is run to recombine the metadata.

