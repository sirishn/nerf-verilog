from numpy import *

def gen(F = 1.0, T =1.0, BIAS = 1.0, AMP = 0.2, SAMPLING_RATE = 1024, PHASE = 0.0):
    """ f = 1.0 # in Hz, continuous freq
    T = 1.0 # Total time in sec
    BIAS = 1.0
    AMP = 0.2
    """    
    dt = 1.0 / SAMPLING_RATE # Sampling interval in seconds
    periods = T / (1/F)

    w = F * 2 * pi * dt
    max_n = int(T * SAMPLING_RATE) - 1
    n = linspace(0 , max_n + 1, max_n + 1)

    ## x = AMP * cos(pi + w * n) + BIAS
    x = AMP * sin(w * n + PHASE) + BIAS
    return x


if __name__ == '__main__':
    from pylab import *
    x = gen(F = 1.0, BIAS = 0.0, AMP = 2.0*pi*1.0*0.1, PHASE = pi/2)
    SAMPLING_RATE = 1024
    intx_list = []
    intx_i1 = 0.0
    for x_i in x:
        intx_i = intx_i1 + x_i * (1.0 /SAMPLING_RATE)
        intx_list.append(intx_i)
        intx_i1 = intx_i
    plot(intx_list)
    # plot(x)
    show()
    print "len_x = %d" % len(x)
