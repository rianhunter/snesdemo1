#!/bin/sh
python tile2.py > tiledata.inc && \
#    python generate_palette.py > palettedata.inc && \
    wla.sh test2  && \
    open test2.smc
