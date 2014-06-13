import colorsys
import math
import sys

print ".dw",

def out(r, g, b, last=False):
    assert r >= 0 and r <= 0x1f
    assert g >= 0 and g <= 0x1f
    assert b >= 0 and b <= 0x1f
    a = r
    a |= g << 5
    a |= b << 10
    print ("$%x" % (a,)) + ("" if last else ","),

if True:
    NUM_COLORS = 256

    for x in xrange(NUM_COLORS):
        (r, g, b) = colorsys.hsv_to_rgb(float(x) / NUM_COLORS, 1.0, 1.0)
        out(int(round(r * 0x1F)), int(round(g * 0x1F)), int(round(b * 0x1F)))
else:
    r = 0x1f
    g = b = 0
    for x in xrange(0x1f):
        out(r, g, b)
        g += 1
    for x in xrange(0x1f):
        out(r, g, b)
        r -= 1
    for x in xrange(0x1f):
        out(r, g, b)
        b += 1
    for x in xrange(0x1f):
        out(r, g, b)
        g -= 1
    for x in xrange(0x1f):
        out(r, g, b)
        r += 1
    for x in xrange(0x1f):
        out(r, g, b, x==0x1f-1)
        b -= 1
