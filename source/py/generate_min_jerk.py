from numpy import *

def gen(xi = 0.0, xf = 1.0, T = 1.0, SAMPLING_RATE = 1024):
   """ 
   xi = initial position
   xf = final position
   T = 1.0 # Total time in sec
   BIAS = 1.0
   AMP = 0.2
   """    
   dt = 1.0 / SAMPLING_RATE # Sampling interval in seconds
   
   tau = linspace(0, T, T * SAMPLING_RATE)
   
   x = xi + (xi - xf) * ((15.0 * pow(tau, 4.0)) - (6.0 * pow(tau, 5.0)) - (10.0 * pow(tau, 3.0)))
   dx = gradient(x) /dt

   return x, dx


if __name__ == '__main__':
   from pylab import *
   x, dx = gen()
   plot(dx)
   plot(x)
   show()
   print "len_x = %d" % len(dx)
