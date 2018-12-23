#! /usr/bin/python
import numpy as np
from pylab import *
from struct import pack, unpack


def ConvertType(val, fromType, toType):
    return unpack(toType, pack(fromType, val))[0]

def isFloat(string):
    try:
            float(string)
            return True
    except ValueError:
            return False
    
SAMPLING_RATE = 1024

#newData = open('/home/eric/eric_nerf_verilog/source/py/dataout.txt',  'r')

newData = open('../response.txt',  'r')

#for item in data:
#   newData = ConvertType(item, 'i', 'f')
#
newData_list_a = []
newData_list_b = []
newData_list_c = []


for x_i in newData:
    #newData_i = newData_i1 + x_i * (1.0 /SAMPLING_RATE)
    #if (isFloat(x_i)):
    #tx_i = ConvertType(x_i, 'i', 'f')
    [x_a,   x_b,  x_c] =  x_i.split()
    tx_a= ConvertType(int("0x"+x_a,  0),  'I',  'f')
    tx_b= ConvertType(int("0x"+x_b,  0),  'I',  'f')
    tx_c= ConvertType(int("0x"+x_c,  0),  'I',  'f')
    newData_list_a.append(tx_a) 
    newData_list_b.append(tx_b) 
    newData_list_c.append(tx_c)    
        
subplot(311)
plot(newData_list_a)
ylim([0.7,  1.3])
subplot(312)
plot(newData_list_b)
ylim([0.0,  800])
subplot(313)
plot(newData_list_c)
show()


#pl.plot(newData[:, 0],  newData[:, 1],  'ro')
#pl.xlabel('x')
#pl.ylabel('y')
#
#pl.show()
