#!/bin/sh

for i in *.bmp; do bmp2mif333 $i; mv image.colour.mif ${i%.bmp}.mif; done

exit 0
