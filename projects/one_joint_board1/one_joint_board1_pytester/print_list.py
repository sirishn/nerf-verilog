#! /usr/bin/python
import sys
sys.path.append('../../../source/py/')
from generate_sin import *
from generate_spikes import *
from pylab import *
from struct import pack, unpack
import pickle

def ConvertType(val, fromType, toType):
    return unpack(toType, pack(fromType, val))[0]

x =  gen(F = 4.0, T = 2.0,  BIAS = 1.1,  AMP = 0.1)
#x = spike_train(firing_rate = 150)
file = open('../stimulus.txt', 'w')

SAMPLING_RATE = 1024
intx_list = []
intx_i1 = 0.0
buf = ""
for x_i in x:
#    intx_i = intx_i1 + x_i * (1.0 /SAMPLING_RATE)
    intx_list.append(x_i)
    tx_i = ConvertType(x_i, 'f', 'I')
    print>>file, "%x" % tx_i

plot(intx_list)
# plot(x)
show()
print "len_x = %d" % len(x)

file.close()
