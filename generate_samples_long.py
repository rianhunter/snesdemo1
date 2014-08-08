#!/usr/bin/python

import math
import struct
import sys


def gcd(*numbers):
    """Return the greatest common divisor of the given integers"""
    from fractions import gcd
    return reduce(gcd, numbers)

def lcm(*numbers):
    """Return lowest common multiple."""
    def lcm(a, b):
        return (a * b) // gcd(a, b)
    return reduce(lcm, numbers, 1)

def f(P, T):
    if P >= 2 ** 14 or P < 0:
        raise Exception("what: %r %r" % (P, T))
    return 32000.0 * P / (2 ** 12  * T)

def find_optimal_p_t(desired_frequency):
    C = desired_frequency
    values = []
    for P in xrange(1, 2 ** 14):
        T = 32000 * P / 2 ** 12.0 / C
        if not round(T): continue
        frac = abs(f(P,round(T))- C)
        values.append((frac, P, round(T), lcm(16, round(T)) / 16.0))

    values.sort()

    return values[0][1:3]

def main():
    # this program generates the SNES sample data for a square wave
    # that highly approximates a given frequency
    desired_frequency = 440 * 2 ** (-9/12.0)

    (p, t) = find_optimal_p_t(desired_frequency)

    sys.stderr.write("optimal p is %r\n" % (p,))

    assert int(t) == t
    assert int(p) == p

    num_samples = int(lcm(16, t))

    sys.stderr.write("num samples is  %r\n" % (num_samples,))
    for brr_block in xrange(num_samples / 16):
        # output header
        # range = 12
        # filter = 0
        # loop = 1
        # end = ?
        header = 0xB3 if brr_block == (num_samples / 16 - 1) else 0xB2
        sys.stdout.write(struct.pack("B", header))

        # now generate the block
        block = []
        for i in xrange(16):
            sample_offset = (brr_block * 16 + i)
            wave_offset = sample_offset % t
            block.append(wave_offset >= (t / 2.0))

        # now write blocks 2 at a time
        for i in xrange(8):
            (sample1, sample2) = block[2 * i:2 * i + 2]
            sys.stdout.write(struct.pack("B",
                                         ((0x8 if sample1 else 0x7) << 4) |
                                         (0x8 if sample2 else 0x7)))

    return 0

if __name__ == "__main__":
    sys.exit(main())
