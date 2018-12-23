#!/usr/bin/env python

"""
spindle_neuron.bit is supposed to:
Click "FeedData" => data fed
Click "Execution" => keep showing a sin wave
Slide "Clock Delayer" => sin wave scales
Click "Reset-FeedData" => clear the mem[] in Verilog
Click "Reset-Nerf" => sine wave starts from n=0



C. Minos Niu (minos.niu AT sangerlab.net)
License: this code is in the public domain
"""
import os
import random
import sys
sys.path.append('../../source/py/')
import wx
import wx.lib.plot as plot
import wx.lib.agw.floatspin as fs
import thread, time
from struct import pack, unpack
from scipy.io import savemat, loadmat
from wx.lib.pubsub import Publisher as pub
from generate_sin import gen as gen_sin
from generate_tri import gen as gen_tri
import opalkelly_4_0_3.ok as ok


# The recommended way to use wx with mpl is with the WXAgg backend.
#
## import matplotlib
## matplotlib.use('WXAgg')
## from matplotlib.figure import Figure
## from matplotlib.backends.backend_wxagg import \
##     FigureCanvasWxAgg as FigCanvas, \
##     NavigationToolbar2WxAgg as NavigationToolbar
import numpy as np

VIEWER_REFRESH_RATE = 20 # in ms, This the T for calculating digital freq
NUM_CHANNEL = 3 # Number of channels
FR_ADDR = 0x20 
LCE_ADDR = 0x22 
PIPE_IN_ADDR = 0x80
## II1_ADDR = 0x22 
## VAR2_ADDR = 0x24 
## VAR3_ADDR = 0x26 
## VAR4_ADDR = 0x28 
## VAR5_ADDR = 0x2A 
## VAR6_ADDR = 0x30 
## VAR7_ADDR = 0x32 

BUTTON_RESET = 0
BUTTON_RESET_SIM = 1
BUTTON_ENABLE_SIM = 2
DATA_EVT_CLKRATE = 7
DATA_EVT_GAMMA = 4
##DISPLAY_SCALING = [0.1, 500, 500, 10, 10, 10, 5, 5]
DISPLAY_SCALING =[0.1, 0.1, 50] 
DATA_OUT_ADDR = [FR_ADDR, 0x30, LCE_ADDR]
ZERO_DATA = [0.0 for ix in xrange(NUM_CHANNEL)]
BIT_FILE = "./spindle_neuron_xem6010.bit"
## BIT_FILE = "/home/minos001/nerf_project/working_spindle/projects/pipe_in_wave_2048/pipe_in_wave_2048_xem3050.bit"

class Model:
    """ Once each data point is refreshed, it publishes a message called "WANT MONEY"
    """
    def __init__(self):
        self.myMoney = 0
        self.ConfigureXEM()

    def ConfigureXEM(self):
        ## dlg = wx.FileDialog( self, message="Open the Counters bitfile (counters.bit)",
        ##         defaultDir="", defaultFile=BIT_FILE, wildcard="*.bit",
        ##         style=wx.OPEN | wx.CHANGE_DIR )
        
        # Show the dialog and retrieve the user response. If it is the OK response, 
        # process the data.
        ## if (dlg.ShowModal() == wx.ID_OK):
        ##     bitfile = dlg.GetPath()
        ## defaultDir="../local/projects/fp_spindle_test/"
        ## defaultFile="fp_spindle_test.bit"
        ## defaultFile="counters_fp_muscle.bit"

        bitfile = BIT_FILE
        assert os.path.exists(bitfile.encode('utf-8')), ".bit file NOT found!"
            
        self.xem = ok.FrontPanel()
        self.xem.OpenBySerial("")
        assert self.xem.IsOpen(), "OpalKelly board NOT found!"

        self.xem.LoadDefaultPLLConfiguration()

        self.pll = ok.PLL22393()
        self.pll.SetReference(48)        #base clock frequency
        self.baseRate = 48 #in MHz
        self.pll.SetPLLParameters(0, self.baseRate, 48,  True)            #multiply up to baseRate 
        self.pll.SetOutputSource(0, ok.PLL22393.ClkSrc_PLL0_0)  #clk1 
        self.clkRate = 40                                #mhz; 200 is fastest
        self.pll.SetOutputDivider(0, int(self.baseRate / self.clkRate)) 
        self.pll.SetOutputEnable(0, True)
        ## self.pll.SetOutputSource(1, ok.PLL22393.ClkSrc_PLL0_0)  #clk2
        ## self.pll.SetOutputDivider(1, int(self.baseRate / self.clkRate))       #div4 = 100 mhz
        ## self.pll.SetOutputEnable(1, True)
        self.xem.SetPLL22393Configuration(self.pll)
        ## self.xem.SetEepromPLL22393Configuration(self.pll)
        self.xem.ConfigureFPGA(bitfile.encode('utf-8'))
        print(bitfile.encode('utf-8'))

    def ReadFPGA(self, getAddr):

        """ getAddr = 0x20 -- 0x3F (maximal in OkHost)
        """
        self.xem.UpdateWireOuts()
        ## Read 18-bit integer from FPGA
        if False :
            intValLo = self.xem.GetWireOutValue(getAddr) & 0xffff # length = 16-bit
            intValHi = self.xem.GetWireOutValue(getAddr + 0x01) & 0x0003 # length = 2-bit
            intVal = ((intValHi << 16) + intValLo) & 0xFFFFFFFF
            if intVal > 0x1FFFF:
                intVal = -(0x3FFFF - intVal + 0x1)
            outVal = float(intVal) / 0xFFFF # in mV De-Scaling factor = 0xFFFF

        ## Read 32-bit float
        outValLo = self.xem.GetWireOutValue(getAddr) & 0xffff # length = 16-bit
        outValHi = self.xem.GetWireOutValue(getAddr + 0x01) & 0xffff
        outVal = ((outValHi << 16) + outValLo) & 0xFFFFFFFF
        outVal = ConvertType(outVal, 'I', 'f')

        ## if getAddr == DATA_OUT_ADDR[0]:
        ## print "%2.4f" % outVal, 
        ## print "%d" % (outValLo), 
        
        return outVal
    def ReadPipe(self):
        buf = "\x00"*4100
        self.xem.ReadFromPipeOut(0xA1, buf)
        ## 'buf' becomes a string buffer which is used to contain the
        ## data read from the pipeout. In both the Write and Read
        ## cases, the length of the buffer passed is the length
        ## transferred.
        return buf

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

    def SendPara(self, newVal, trigEvent):
        if trigEvent == DATA_EVT_GAMMA:
            bitVal = ConvertType(newVal, fromType = 'f', toType = 'I')
            bitValLo = bitVal & 0xffff
            bitValHi = (bitVal >> 16) & 0xffff
            self.xem.SetWireInValue(0x01, bitValLo, 0xffff)
            self.xem.SetWireInValue(0x02, bitValHi, 0xffff)
            self.xem.UpdateWireIns()
            self.xem.ActivateTriggerIn(0x50, DATA_EVT_GAMMA)
        if trigEvent == DATA_EVT_CLKRATE:
            ## print "%x" % (newVal & 0xffff),
            self.xem.SetWireInValue(0x01, newVal & 0xffff, 0xffff)
            self.xem.UpdateWireIns();
            self.xem.ActivateTriggerIn(0x50, DATA_EVT_CLKRATE)

class View(wx.Frame):
    def __init__(self, parent):
        wx.Frame.__init__(self, parent, title="Main View",\
                          size = (900, 500))
        self.paused = False
        self.data = ZERO_DATA
        self.xPos = 0
        self.dispRect = self.GetClientRect()

        self.CreateViewMenu()
        self.CreateViewStatusBar()
        self.CreateViewPanel()

        self.redrawTimer = wx.Timer(self)
        self.Bind(wx.EVT_TIMER, self.OnRedrawTimer, self.redrawTimer)        
        self.redrawTimer.Start(VIEWER_REFRESH_RATE)

    def OnRedrawTimer(self, event):
        # if paused do not add data, but still redraw the plot
        # (to respond to scale modifications, grid change, etc.)
        #
        pub.sendMessage("WANT MONEY", 0.0)
        

    def CreateViewMenu(self):
        self.menubar = wx.MenuBar()
        
        menuFile = wx.Menu()
        m_expt = menuFile.Append(-1, "&Save plot\tCtrl-S", "Save plot to file")
        ## self.Bind(wx.EVT_MENU, self.on_save_plot, m_expt)
        menuFile.AppendSeparator()
        m_exit = menuFile.Append(-1, "E&xit\tCtrl-X", "Exit")
        self.Bind(wx.EVT_MENU, self.OnExit, m_exit)
                
        self.menubar.Append(menuFile, "&File")
        self.SetMenuBar(self.menubar)

    def CreateViewPanel(self):
        self.panel = wx.Panel(self)
        self.panel.Bind(wx.EVT_PAINT, self.OnPaint)
        ## self.pause_button = wx.Button(self.panel, -1, "Pause")
        ## self.Bind(wx.EVT_BUTTON, self.OnPauseButton, self.pause_button)
        ## self.Bind(wx.EVT_UPDATE_UI, self.OnUpdatePauseButton, self.pause_button)
        
    
    def CreateViewStatusBar(self):
        self.statusbar = self.CreateStatusBar()

    def OnExit(self, event):
        self.Destroy()

    def OnPaint(self, event = None, newVal = ZERO_DATA, newSpike = ""):

        """ aksjdf
        """
        if ~hasattr(self, 'dc'):
            self.dc = wx.PaintDC(self.panel)

        self.dispRect = self.GetClientRect()
        winScale = self.dispRect.GetHeight() * 4 / 5
        self.dc.DrawText("Pos", 1, winScale / 5)
        self.dc.DrawText("Vel", 0, winScale / 5)
        self.dc.DrawText("Flex", 0, 2*winScale / 5)
        self.dc.DrawText("Ext", 0, 3*winScale / 5)

        self.dc.DrawText("S1.f", 0, winScale - 126)
        self.dc.DrawText("M1.f", 0, winScale - 94)
        self.dc.DrawText("alpha.f", 0, winScale - 62)
        self.dc.DrawText("Ia.f", 0, winScale - 30)

        self.dc.DrawText("S1.e", 0, winScale + 2)
        self.dc.DrawText("M1.e", 0, winScale + 34)
        self.dc.DrawText("alpha.e", 0, winScale + 66)
        self.dc.DrawText("Ia.e", 0, winScale + 98)

        self.dispRect = self.GetClientRect()
        winScale = self.dispRect.GetHeight() * 4 / 5
        if self.xPos == 0:
            self.dc.Clear()
        self.dc.SetPen(wx.Pen('blue', 1))

        for ix in xrange(NUM_CHANNEL):
            self.dc.DrawLine(self.xPos + 60, winScale / 3 *(1 + ix) -
                        self.data[ix] * DISPLAY_SCALING[ix],\
                        self.xPos + 61, winScale / 3 *(1 + ix) -
                        newVal[ix] * DISPLAY_SCALING[ix])

        spikeSeq = unpack("%d" % len(newSpike) + "b", newSpike)

        ## display the spike rasters
        for i in xrange(0, len(spikeSeq), 2):
            neuronID = spikeSeq[i+1]
            rawspikes = spikeSeq[i]
            ## flexors
            if (rawspikes & 32): ## S1
                self.dc.DrawLine(self.xPos+60,(winScale) - 36 - (neuronID/4),\
                                 self.xPos+62, (winScale) - 36 - (neuronID/4))
            if (rawspikes & 16) : ## M1
                self.dc.DrawLine(self.xPos+60,(winScale) - 32 - (neuronID/4),\
                                 self.xPos+62, (winScale) - 32 - (neuronID/4))
            if (rawspikes & 64) : ## MN
                self.dc.DrawLine(self.xPos+60,(winScale) - 28 - (neuronID/4),\
                                 self.xPos+62, (winScale) -  28 - (neuronID/4))
            if (rawspikes & 128) : ## Ia
                self.dc.DrawLine(self.xPos+60,(winScale) - 24 - (neuronID/4),\
                                 self.xPos+62, (winScale) - 24 - (neuronID/4))
            ## ## extensors16
            if (rawspikes & 2) : ## S1
                self.dc.DrawLine(self.xPos+60,(winScale) + 0 - (neuronID/4),\
                                 self.xPos+62, (winScale) +0 - (neuronID/4))
            if (rawspikes & 1) : ## M1
                self.dc.DrawLine(self.xPos+60,(winScale) + 4 - (neuronID/4),\
                                 self.xPos+62, (winScale) + 4 - (neuronID/4))
            if (rawspikes & 4) : ## MN
                self.dc.DrawLine(self.xPos+60,(winScale) + 8 - (neuronID/4),\
                                 self.xPos+62, (winScale) +8 - (neuronID/4))
            if (rawspikes & 8) : ## Ia
                self.dc.DrawLine(self.xPos+60,(winScale) + 12 - (neuronID/4),\
                                 self.xPos+62, (winScale) + 12- (neuronID/4))
                
        self.data = newVal
        self.xPos += 1
        if self.xPos > 300:
            self.xPos = 0


class BoundControlBox(wx.Panel):
    """ A static box with a couple of radio buttons and a text
        box. Allows to switch between an automatic mode and a 
        manual mode with an associated value.
    """
    def __init__(self, parent, ID, label, initval):
        wx.Panel.__init__(self, parent, ID)
        
        self.value = initval
        
        box = wx.StaticBox(self, -1, label)
        sizer = wx.StaticBoxSizer(box, wx.VERTICAL)
        
        self.radio_auto = wx.RadioButton(self, -1, 
            label="Auto", style=wx.RB_GROUP)
        self.radio_manual = wx.RadioButton(self, -1,
            label="Manual")
        self.manual_text = wx.TextCtrl(self, -1, 
            size=(35,-1),
            value=str(initval),
            style=wx.TE_PROCESS_ENTER)
        
        self.Bind(wx.EVT_UPDATE_UI, self.on_update_manual_text, self.manual_text)
        self.Bind(wx.EVT_TEXT_ENTER, self.on_text_enter, self.manual_text)
        
        manual_box = wx.BoxSizer(wx.HORIZONTAL)
        manual_box.Add(self.radio_manual, flag=wx.ALIGN_CENTER_VERTICAL)
        manual_box.Add(self.manual_text, flag=wx.ALIGN_CENTER_VERTICAL)
        
        sizer.Add(self.radio_auto, 0, wx.ALL, 10)
        sizer.Add(manual_box, 0, wx.ALL, 10)
        
        self.SetSizer(sizer)
        sizer.Fit(self)
    
    def on_update_manual_text(self, event):
        self.manual_text.Enable(self.radio_manual.GetValue())
    
    def on_text_enter(self, event):
        self.value = self.manual_text.GetValue()
    
    def is_auto(self):
        return self.radio_auto.GetValue()
        
    def manual_value(self):
        return self.value


class ChangerView(wx.Frame):
    def __init__(self, parent):
        wx.Frame.__init__(self, parent, -1, title="On-chip parameters",\
                          pos = wx.Point(300, 700))
        self.panel = wx.Panel(self)

        ## sizer = wx.BoxSizer(wx.VERTICAL)
        ## self.add = wx.Button(self, label="Add Money")
        ## self.remove = wx.Button(self, label="Remove Money")
        ## sizer.Add(self.add, 0, wx.EXPAND | wx.ALL)
        ## sizer.Add(self.remove, 0, wx.EXPAND | wx.ALL)
        ## self.SetSizer(sizer)


        self.clkLabel = wx.StaticText(self.panel, -1, "Clock Delayer")
        self.clkSlider = wx.Slider(self.panel, -1, 80, 0, 100, (10, 10), (250, 50),
                                  wx.SL_HORIZONTAL | wx.SL_AUTOTICKS | wx.SL_LABELS)
        self.resetTgl = wx.ToggleButton(self.panel, -1, "Reset", wx.Point(20,25), wx.Size(50,30))
        ##self.feedChoice = wx.Button(self.panel, -1, "Feed", wx.Point(20,25), wx.Size(50,30))
        self.feedChoice = wx.Choice(parent=self.panel, pos=wx.Point(10,10))
        feedChoiceList = ['Sine 1Hz', 'Sine 4Hz', 'Triangular']
        self.feedChoice.AppendItems(strings=feedChoiceList) 
        self.resetSimBtn = wx.Button(self.panel, -1, "RedoSim", wx.Point(20,25), wx.Size(50,30))

        self.gammaDynLabel = wx.StaticText(self.panel, -1, 'Gamma Dynamic', (15, 95))
        self.gammaDynSpin = fs.FloatSpin(self.panel, -1, min_val=0, max_val=120,
                                       increment=1.0, value=100.0)
					#, agwStyle=fs.FS_LEFT)
        self.gammaDynSpin.SetFormat("%f")
        self.gammaDynSpin.SetDigits(2)

        self.hbox = wx.BoxSizer(wx.VERTICAL)
        self.hbox.Add(self.clkLabel, border=5, flag=wx.ALL|wx.EXPAND)
        self.hbox.Add(self.clkSlider, border=5, flag=wx.ALL|wx.EXPAND)
        self.hbox.Add(self.gammaDynLabel, border=5, flag=wx.ALL|wx.EXPAND)
        self.hbox.Add(self.gammaDynSpin, border=5, flag=wx.ALL|wx.EXPAND)
        self.hbox.Add(self.resetTgl, border=5, flag=wx.ALL|wx.EXPAND)
        self.hbox.Add(self.feedChoice, border=5, flag=wx.ALL|wx.EXPAND)
        self.hbox.Add(self.resetSimBtn, border=5, flag=wx.ALL|wx.EXPAND)
        ## self.hbox.Add(self.resetTgl,flag=wx.ALIGN_CENTER, border=5)

        self.hbox.Fit(self)

        self.panel.SetSizer(self.hbox)

class Controller:
    def __init__(self, app):
        self.nerfModel = Model()

        #set up the first frame which displays the current Model value
        self.dispView = View(None)
        ## thread.start_new_thread(self.nerfModel.ReadFPGA, ("Refreshing data", 0.05, 0x20))
        ## self.dispView.SetMoney(self.nerfModel.myMoney)

        #set up the second frame which allows the user to modify the Model's value
        self.ctrlView = ChangerView(self.dispView)
        ## self.ctrlView.add.Bind(wx.EVT_BUTTON, self.AddMoney)
        ## self.ctrlView.remove.Bind(wx.EVT_BUTTON, self.RemoveMoney)

        ## self.ctrlView.slider1.Bind(wx.EVT_SLIDER, self.UpdateIa)
        self.ctrlView.clkSlider.Bind(wx.EVT_SLIDER, self.OnClkRate)
        self.ctrlView.resetTgl.Bind(wx.EVT_TOGGLEBUTTON, self.OnReset)
        self.ctrlView.gammaDynSpin.Bind(fs.EVT_FLOATSPIN, self.OnGammaDyn)  ## send floating firing rate
        self.ctrlView.feedChoice.Bind(wx.EVT_CHOICE, self.OnFeedChoice)
        ## self.ctrlView.enableSimTgl.Bind(wx.EVT_TOGGLEBUTTON, self.OnEnableSim)
        self.ctrlView.resetSimBtn.Bind(wx.EVT_BUTTON, self.OnResetSim)

        ## Read the default value and send to FPGA
        newClkRate = self.ctrlView.clkSlider.GetValue()
        self.nerfModel.SendPara(newVal = newClkRate, trigEvent = DATA_EVT_CLKRATE)
        newGammaDyn = self.ctrlView.gammaDynSpin.GetValue()
        self.nerfModel.SendPara(newVal = newGammaDyn, trigEvent = DATA_EVT_GAMMA)


       ## self.ctrlView.Bind(wx.EVT_TOGGLEBUTTON, self.OnReset, self.ctrlView.resetTgl)

        pub.subscribe(self.WantMoney, "WANT MONEY")

        self.dispView.Show()
        self.ctrlView.Show()

    def OnFeedChoice(self, evt):
        choice = evt.GetString()
        if choice == "Sine 1Hz":
            pipeInData = gen_sin(F = 1.0, AMP = 0.3)
        elif choice == "Sine 4Hz":
            pipeInData = gen_sin(F = 2.0, AMP = 0.3)
        elif choice == "Triangular":
            pipeInData = gen_tri()
        self.nerfModel.SendPipe(pipeInData)

    def OnClkRate(self, event):
        newClkRate = self.ctrlView.clkSlider.GetValue()
        self.nerfModel.SendPara(newVal = newClkRate, trigEvent = DATA_EVT_CLKRATE)

    def OnGammaDyn(self, event):
        newGammaDyn = self.ctrlView.gammaDynSpin.GetValue()
        self.nerfModel.SendPara(newVal = newGammaDyn, trigEvent = DATA_EVT_GAMMA)

    def OnReset(self, evt):
        newReset = self.ctrlView.resetTgl.GetValue()
        self.nerfModel.SendButton(newReset, BUTTON_RESET)
        newClkRate = self.ctrlView.clkSlider.GetValue()
        self.nerfModel.SendPara(newVal = newClkRate, trigEvent = DATA_EVT_CLKRATE)
        newGammaDyn = self.ctrlView.gammaDynSpin.GetValue()
        self.nerfModel.SendPara(newVal = newGammaDyn, trigEvent = DATA_EVT_GAMMA)

    def OnResetSim(self, evt):
        ## newExec = self.ctrlView.resetSimBtn.GetValue()
        ## self.nerfModel.SendButton(newExec, BUTTON_RESET_SIM)
        self.nerfModel.SendButton(True, BUTTON_RESET_SIM)
        self.nerfModel.SendButton(False, BUTTON_RESET_SIM)

        ## newGammaDyn = self.ctrlView.gammaDynSpin.GetValue()
        ## self.nerfModel.SendPara(newVal = newGammaDyn, trigEvent = DATA_EVT_GAMMA)

    def WantMoney(self, message):
        """
        This method is the handler for "WANT MONEY" messages,
        which pubsub will call as messages are sent from the model.

        We already know the topic is "WANT MONEY", but if we
        didn't, message.topic would tell us.
        """
        ## self.dispView.SetMoney(message.data)
        newVal = [0.0 for ix in range(NUM_CHANNEL)]
        for i in xrange(NUM_CHANNEL):
            newVal[i] = max(-65535, min(65535, self.nerfModel.ReadFPGA(DATA_OUT_ADDR[i])))
            ## if i == 1:
            ##     print "%.4f" % newVal[i],
## #
# #
#            newVal[i] = self.nerfModel.ReadFPGA16Bit(0x23)
#            hi = ConvertType(hi, 'i', 'h')
        newSpike = self.nerfModel.ReadPipe()
        self.dispView.OnPaint(newVal = newVal, newSpike = newSpike)

def ConvertType(val, fromType, toType):
    return unpack(toType, pack(fromType, val))[0]

if __name__ == "__main__":
    app = wx.App(False)
    controller = Controller(app)
    app.MainLoop()

