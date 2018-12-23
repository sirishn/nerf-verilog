from numpy import *
from scipy.signal import butter, filtfilt

def gen(T = [0.0, 0.1, 0.9, 1.0], L = [0.0, 0.0, 200.0, 200.0], SAMPLING_RATE = 1024, FILT = False):
   """ f = 1.0 # in Hz, continuous freq
   T = 1.0 # Total time in sec
   BIAS = 1.0
   AMP = 0.2
   """    
   dt = 1.0 / SAMPLING_RATE # Sampling interval in seconds

   len_x = int(T[-1] * SAMPLING_RATE) + 1
   #x = zeros(len_x)
   x = []
   N = [int(t / dt) for t in T]

   for n1, l1, n2, l2 in zip(N[0:-1], L[0:-1], N[1:], L[1:]):
       n_seg = n2 - n1;
       x = x + ([l1 + i*(l2-l1)/n_seg for i in xrange(n_seg)])

   if (FILT):
      b, a = butter(N=3, Wn=2*pi*10/SAMPLING_RATE , btype='low', analog=0, output='ba')
      x = filtfilt(b=b, a=a, x=x)

   return x


if __name__ == '__main__':
   from pylab import *
   x = gen(T =  [0.0, 0.06, 0.07,  0.24,  0.26,  0.43,  0.44,  0.5, 0.5,  0.56, 0.57,  0.74,  0.76,  0.93,  0.94,  1.0],\
            L = [0.0,  0.0,  1.0,  1.0,  -1.0,  -1.0,  0.0,  0.0,  0.0,  0.0,  -1.0,  -1.0,  1.0,  1.0,  0.0,  0.0], FILT = True)
   plot(x)
   show()
   print "len_x = %d" % len(x)
