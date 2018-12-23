#!/usr/bin/env python

"""
C. Minos Niu (minos.niu AT sangerlab.net)
License: this code is in the public domain
"""
import os
import sys
from scipy.io import savemat, loadmat
from wx.lib.pubsub import Publisher as pub
from opalkelly_4_0_3 import ok
import numpy as np
from Utilities import *

class Model:
    """ Once each data point is refreshed, it publishes a message called "WANT MONEY"
    """
    def __init__(self):
        self.myMoney = 0
        self.ConfigureXEM()

    def ConfigureXEM(self):
        bitfile = BIT_FILE
        assert os.path.exists(bitfile.encode('utf-8')), ".bit file NOT found!"
            
        self.xem = ok.FrontPanel()
        self.xem.OpenBySerial("")
        assert self.xem.IsOpen(), "OpalKelly board NOT found!"

        self.xem.LoadDefaultPLLConfiguration()

        self.pll = ok.PLL22393()
        self.pll.SetReference(48)        #base clock frequency
        self.baseRate = 200 #in MHz
        self.pll.SetPLLParameters(0, self.baseRate, 48,  True)            #multiply up to baseRate 
        self.pll.SetOutputSource(0, ok.PLL22393.ClkSrc_PLL0_0)  #clk1 
        self.clkRate = 200                                #mhz; 200 is fastest
        self.pll.SetOutputDivider(0, int(self.baseRate / self.clkRate)) 
        self.pll.SetOutputEnable(0, True)
        ## self.pll.SetOutputSource(1, ok.PLL22393.ClkSrc_PLL0_0)  #clk2
        ## self.pll.SetOutputDivider(1, int(self.baseRate / self.clkRate))       #div4 = 100 mhz
        ## self.pll.SetOutputEnable(1, True)
        self.xem.SetPLL22393Configuration(self.pll)
        self.xem.ConfigureFPGA(bitfile.encode('utf-8'))
        print(bitfile.encode('utf-8'))

    def ReadFPGA(self, getAddr, type):

        """ getAddr = 0x20 -- 0x3F (maximal in OkHost)
        """
        self.xem.UpdateWireOuts()
        ## Read 18-bit integer from FPGA
        if type == "int18" :
            intValLo = self.xem.GetWireOutValue(getAddr) & 0xffff # length = 16-bit
            intValHi = self.xem.GetWireOutValue(getAddr + 0x01) & 0x0003 # length = 2-bit
            intVal = ((intValHi << 16) + intValLo) & 0xFFFFFFFF
#            intVal = ConvertType(intVal, 'I', 'i')
            if intVal > 0x1FFFF:
                intVal = -(0x3FFFF - intVal + 0x1)
            outVal = float(intVal) # in mV De-Scaling factor = 0xFFFF

        ## Read 32-bit float
        elif type == "float32" :
            outValLo = self.xem.GetWireOutValue(getAddr) & 0xffff # length = 16-bit
            outValHi = self.xem.GetWireOutValue(getAddr + 0x01) & 0xffff
            outVal = ((outValHi << 16) + outValLo) & 0xFFFFFFFF
            outVal = ConvertType(outVal, 'I', 'f')
            #print outVal
        ## Read 32-bit signed integer from FPGA
        elif type == "int32" :
            intValLo = self.xem.GetWireOutValue(getAddr) & 0xffff # length = 16-bit
            intValHi = self.xem.GetWireOutValue(getAddr + 0x01) & 0xffff # length = 16-bit
            intVal = ((intValHi << 16) + intValLo) & 0xFFFFFFFF
            outVal = ConvertType(intVal, 'I',  'i')  # in mV De-Scaling factor = 128  #????

        ## if getAddr == DATA_OUT_ADDR[0]:
        ## print "%2.4f" % outVal, 
        ## print "%d" % (outValLo), 
        
        return outVal

    def SendButton(self, buttonValue, evt = None):
        if evt == BUTTON_RESET:
            if (buttonValue) :
                self.xem.SetWireInValue(0x00, 0x01, 0xff)
            else :
                self.xem.SetWireInValue(0x00, 0x00, 0x01)
            self.xem.UpdateWireIns()
        elif evt == BUTTON_RESET_SIM:
            if (buttonValue) :
                self.xem.SetWireInValue(0x00, 0x02, 0xff)
            else :
                self.xem.SetWireInValue(0x00, 0x00, 0x02)
            self.xem.UpdateWireIns()
        elif evt == BUTTON_ENABLE_SIM:
            if (buttonValue) :
                self.xem.SetWireInValue(0x00, 0x04, 0xff)
            else :
                self.xem.SetWireInValue(0x00, 0x00, 0x04)
            self.xem.UpdateWireIns()
    def SendPipe(self, pipeInData):
        """ Send byte stream to OpalKelly board
        """
        # print pipeInData

        buf = "" 
        for x in pipeInData:
            ##print x
            buf += pack('<f', x) # convert float_x to a byte string, '<' = little endian

        byteSent = self.xem.WriteToBlockPipeIn(PIPE_IN_ADDR, 4, buf)

        if byteSent == len(buf):
            print "%d bytes sent via PipeIn!" % byteSent 
        else:
            print "Send pipe filed! %d bytes sent" % byteSent
            
    def SendPipeInt(self, pipeInData):
        """ Send byte stream to OpalKelly board
        """
        # print pipeInData

        buf = "" 
        for x in pipeInData:
            ##print x
            buf += pack('<I', x) # convert float_x to a byte string, '<' = little endian

        byteSent = self.xem.WriteToBlockPipeIn(PIPE_IN_ADDR, 4, buf)

        if byteSent == len(buf):
            print "%d bytes sent via PipeIn!" % byteSent 
        else:
            print "Send pipe filed! %d bytes sent" % byteSent

    def SendPara(self, bitVal, trigEvent):
        bitValLo = bitVal & 0xffff
        bitValHi = (bitVal >> 16) & 0xffff
        self.xem.SetWireInValue(0x01, bitValLo, 0xffff)
        self.xem.SetWireInValue(0x02, bitValHi, 0xffff)
        self.xem.UpdateWireIns()            
        self.xem.ActivateTriggerIn(0x50, trigEvent)   

    def ReadPipe(self, addr, len = 1000):
        buf = "\x00" * len
        self.xem.ReadFromPipeOut(addr, buf)
        ## 'buf' becomes a string buffer which is used to contain the
        ## data read from the pipeout. In both the Write and Read
        ## cases, the length of the buffer passed is the length
        ## transferred.
        return buf
