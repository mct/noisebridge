#!/bin/bash
# vim:set ts=4 sw=4 ai et:

set -e
set -x

# too many files for wildcard expansion to work; use xargs instead
find -iname '*.gif' -print0 | xargs -0r rm
find -iname '*.ppm' -print0 | xargs -0r rm

mnist-converter.pl \
    --imagefile t10k-images-idx3-ubyte \
    --labelfile t10k-labels-idx1-ubyte \
    --num 10000 --to-ppm

for i in *.ppm
do ppmtogif < $i > $i.gif
done

for i in $(seq 0 9)
do montage *_$i.ppm.gif -tile 32x -geometry 28x28 -background black $i.gif
done

find -iname '*.ppm*' -print0 | xargs -0r rm
