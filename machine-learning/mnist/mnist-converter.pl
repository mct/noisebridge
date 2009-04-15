#!/usr/bin/perl
# vim:set ts=4 sw=4 ai et:

# Michael C. Toren <mct@toren.net>
# mct, Thu Apr  9 21:38:00 PDT 2009

use Getopt::Long qw(:config gnu_getopt);

use strict;
use warnings;

sub usage
{
    die <<EOT

mnist-converter.pl -- A utility to read MNIST handwriting files from
<http://yann.lecun.com/exdb/mnist/>.  The format of the MNIST data is
described under the "FILE FORMATS" section of that URL.  Command line
argument:

        --imagefile <image file>
            Filename of image data to read from (required)

        --labelfile <label file>
            Filename of image labels to read from (required)

        --num <number of images>
            Number of images to read (required)

        --to-ascii
            Dump an ASCII representation of each image to stdout, along
            with its label.  Good for debugging.

        --to-ppm
            Write each image to a PPM graphics file named
            imageNNNNN_N.ppm (where NNNNN is the image number, and N is
            the image label) in the current directory.  These PPM files
            can later be converted to GIFs using ppmtogif(1), or to other
            image formats using ImageMagick's convert(1) program.

        --to-fann
            Convert the MNIST data to a file format suitable for use with
            the Fast Artificial Neural Network Library (fann) library.
            The fann data will be printed to stdout.  The fann file format
            is described in the doc/gettingstarted.txt file of the
            fann-2.1.0 release.

EOT
}

my ($imagefile, $labelfile, $num_images);
my ($ascii, $ppm, $fann);

GetOptions('imagefile=s'  => \$imagefile,
           'labelfile=s'  => \$labelfile,
           'num=i'        => \$num_images,
           'to-ascii'     => \$ascii,
           'to-ppm'       => \$ppm,
           'to-fann'      => \$fann)
                or usage;

usage unless $imagefile and $labelfile and $num_images;
usage unless $ascii or $ppm or $fann;

# Read from $fd exactly $num bytes, or die
sub read_or_die
{
    my ($fd, $num) = @_;
    my $buf;

    my $ret = read $fd, $buf, $num;
    die "read: $!\n" unless defined $ret;
    die "read: wanted $num bytes, only got $ret?\n" unless $ret == $num;
    return $buf;
}

open my $imagefd, $imagefile or die "open: $imagefile: $!\n";
open my $labelfd, $labelfile or die "open: $labelfile: $!\n";

# Skip past the headers of input files
read_or_die $imagefd, 16;
read_or_die $labelfd, 8;

if ($fann)
{
    # Print our header
    print join(" ", $num_images, 28*28, 10), "\n";
}

for my $num (1 .. $num_images)
{
    my @image = map { ord } split //, read_or_die $imagefd, 28*28;
    my $label = ord read_or_die $labelfd, 1;

    if ($fann)
    {
        print join(" ", @image), "\n";
        print join(" ", map { $label == $_ ? 1 : 0 } (0 .. 9)), "\n";
    }

    if ($ascii)
    {
        print "Image $num, Label $label\n";
        print +(map { $_ > 128 ? "@" : " "} splice @image, 0, 28), "\n"
            for (1 .. 28)
    }

    if ($ppm)
    {
        my $filename = sprintf "image%05d_%d.ppm", $num, $label;
        open my $fd, "> $filename" or die "open: $filename: $!\n";
        print $fd "P3 28 28 255\n";
        print $fd "$_ $_ $_\n" for (@image);
    }
}
