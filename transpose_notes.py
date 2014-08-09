import sys

# this generates P settings for a sample with pariod T (in samples)
def main():
    sample_period = 84.0

    # usually base_freq should have low error when used with sample_period
    base_freq = (440 * 2 ** (-9/12.0))
    for i in xrange(12):
        desired_freq = base_freq * 2 ** (i / 12.0)
        P = int(round(((2 ** 12 * sample_period)  * desired_freq / 32000.0)))
        result_freq = 32000.0 * P / (2 ** 12.0 * sample_period)
        print hex(P), abs(result_freq - desired_freq)
    

if __name__ == "__main__":
    sys.exit(main())
