#!/bin/sh

for i in *.bmp; do ./bmp2mif $i; mv image.colour.mif ${i%.bmp}.mif; done

exit 0
