#!/usr/bin/python2.5
import numpy as np
#from scipy.signal.waveforms import chirp, sweep_poly
from numpy import poly1d
from pylab import figure, plot, show, xlabel, ylabel, subplot, grid, title, \
                    yscale, savefig, clf
                    
                    
## Chirp spike train using peudo-sine wave
## Using poly1d function (3rd order polynomial  that imitates sine wave) and sample the points where the sign of a slope change to make spike

def chirping_spike_train(filename=None, coeff_a = 20,  fig_size=(9.5, 8.5)):
    t1 = 2.0   # get 2 seconds from polynomial function
    coeff_2a = coeff_a*2  # to prevent negative firing rate
    p = poly1d([coeff_2a*1.0, coeff_2a*(-3.0), coeff_2a*2.0, coeff_a*1.0])
    t = np.linspace(0, t1, 1024)
    w = sweep_poly(t, p)
    
    d2train=[]
    for i in xrange(len(w)):
        print i
        if (i == 1022 or i == 1023):
            sign1 = 0x1
            sign2 = 0x1
        else:
            sign1 = (0x1 if ((w[i+2] -w[i+1]) > 0) else 0) 
            sign2 = (0x1 if ((w[i+1] -w[i]) >0)  else 0) 
            
        if (sign1 != sign2) :
            spike = 0x1
        else:
            spike = 0x0
        d2train.append(spike)
    
    return d2train
    

if __name__ == "__main__":
    coeff_a = 40  # decides spike density 
    d2train = chirping_spike_train(coeff_a)
    fig_size=(9.5, 8.5)
    figure(1, figsize=fig_size)
    clf()
    
    t1 = 2.0   # get 2 seconds from polynomial function
    coeff_2a = coeff_a*2  # to prevent negative firing rate
    p = poly1d([coeff_2a*1.0, coeff_2a*(-3.0), coeff_2a*2.0, coeff_a*1.0])
    t = np.linspace(0, t1, 1024)
    w = sweep_poly(t, p)
    subplot(3,1,1)
    plot(t, w)
    tstr = "Sweep Poly, $f(t) = 2a*(t^3 - 3t^2 + 2t) + a*1 )$"
    title(tstr)

    subplot(3,1,2)
    plot(d2train) 
    grid(True)
    ylabel('spike')
    xlabel('time (1s)')
    
    subplot(3,1,3)
    plot(t, p(t), 'r')
    grid(True)
    ylabel('height')
    xlabel('polynocial function used for chirping')
    show()


