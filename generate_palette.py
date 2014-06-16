import colorsys
import math
import sys
import numpy


def x_rot(th):
    return numpy.mat([[1, 0, 0],
                      [0, math.cos(th), -math.sin(th)],
                      [0, math.sin(th), math.cos(th)]])

def y_rot(th):
    return numpy.mat([[math.cos(th), 0, math.sin(th)],
                      [0, 1, 0],
                      [-math.sin(th), 0, math.cos(th)]])

def z_rot(th):
    return numpy.mat([[math.cos(th), -math.sin(th), 0],
                      [math.sin(th), math.cos(th), 0],
                      [0, 0, 1]])

def rotate_matrix(th):
    return x_rot(th) * y_rot(th) * z_rot(th)

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

    NUM_ROTATIONS = 64
    for th_int in xrange(NUM_ROTATIONS):
        print ".dw",

        th = th_int * 2 * math.pi / NUM_ROTATIONS
        for x in xrange(NUM_COLORS):
            (r1, g1, b1) = colorsys.hsv_to_rgb(float(x) / NUM_COLORS, 1.0, 1.0)
            mat = rotate_matrix(th) * numpy.mat([[r1 - 0.5], [g1 - 0.5], [b1 - 0.5]])
            triple_ = [mat[0][0], mat[1][0], mat[2][0]]
            triple = map(lambda x: min(1, max(0, x + 0.5)), triple_)
            (r, g, b) = triple
            out(int(round(r * 0x1F)), int(round(g * 0x1F)), int(round(b * 0x1F)),
                last=x == NUM_COLORS - 1)
        print
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
