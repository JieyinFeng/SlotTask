#!/usr/bin/env bash

# use imagemagick to resize all images to the same
# dimensions
find -iname '*jpeg' -or -iname '*jpg' | while read f; do
 identify $f
done
