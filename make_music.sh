#!/bin/sh

python generate_samples_long.py > samples_long.bin;
wla-spc700 -o music.asm music.o
echo  '[objects]' > linkfile
echo 'music.o' >> linkfile
wlalink linkfile music.rom
