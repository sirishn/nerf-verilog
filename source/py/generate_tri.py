from numpy import *

def gen(L1 = 0.8, L2 = 1.2, T =1.0, SAMPLING_RATE = 1024):
    """ f = 1.0 # in Hz, continuous freq
    T = 1.0 # Total time in sec
    BIAS = 1.0
    AMP = 0.2
    """    
    dt = 1.0 / SAMPLING_RATE # Sampling interval in seconds

    max_n = int(T * SAMPLING_RATE) - 1
    n = linspace(0 , max_n + 1, max_n + 1)
    x_up = [L1 + i*2*(L2-L1)/max_n for i in xrange(max_n) if i <= max_n / 2]
    x_down = [L1 + 2*(max_n - i)*(L2-L1)/max_n for i in xrange(max_n) if i >= max_n / 2]
    x =  x_up + x_down

    return x


if __name__ == '__main__':
    from pylab import *
    x = gen()
    plot(x)
    show()
    print "len_x = %d" % len(x)
