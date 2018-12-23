# -*- coding: utf-8 -*-

"""
Module implementing Control.
"""

from PyQt4.QtGui import QDialog
from PyQt4.QtCore import pyqtSignature
from PyQt4.QtCore import SIGNAL, SLOT, Qt
from Utilities import *
from generate_sin import gen as gen_sin
from generate_tri import gen as gen_tri
from generate_spikes import spike_train
from generate_sequence import gen as gen_seq
from math import floor

from Fpga import Model
from Display import View

from Ui_Controls import Ui_Dialog
class User(QDialog, Ui_Dialog):
    """
    Class documentation goes here.
    """
    def __init__(self, parent = None):
        """
        Constructor
        """
#        QDialog.__init__(self, parent, Qt.FramelessWindowHint)
        QDialog.__init__(self, parent)
        self.setupUi(self)
        
        self.nerfModel = Model()
        self.dispView = View(None, NUM_CHANNEL, DISPLAY_SCALING, VIEWER_REFRESH_RATE, \
                             CHANNEL_COLOR)
                             

        self.dispView.show()
        self.data = []
        self.isLogData = False
        
        self.connect(self.dispView.timer, SIGNAL("timeout()"), self.onCheckMoney)
#        self.connect(self, SIGNAL("initRT"), self.on_horizontalSlider_sliderMoved)
#        self.emit(SIGNAL("initRT"), 1)
        self.on_horizontalSlider_valueChanged(1)
        
#        self.connect(self.doubleSpinBox_0, SIGNAL("editingFinished()"), self.onNewWire00In)
#        self.connect(self.doubleSpinBox_0, SIGNAL("valueChanged(double)"), self.onNewWire00In)
#
#        self.connect(self.doubleSpinBox_1, SIGNAL("editingFinished()"), self.onNewWire01In)
#        self.connect(self.doubleSpinBox_1, SIGNAL("valueChanged(double)"), self.onNewWire01In)

        self.connect(self.doubleSpinBox_2, SIGNAL("editingFinished()"), self.onNewWireIn2)
        self.connect(self.doubleSpinBox_2, SIGNAL("valueChanged(double)"), self.onNewWireIn2)

#        self.connect(self.doubleSpinBox_3, SIGNAL("editingFinished()"), self.onNewWire03In)
#        self.connect(self.doubleSpinBox_3, SIGNAL("valueChanged(double)"), self.onNewWire03In)
#
        self.connect(self.doubleSpinBox_4, SIGNAL("editingFinished()"), self.onNewWireIn4)
        self.connect(self.doubleSpinBox_4, SIGNAL("valueChanged(double)"), self.onNewWireIn4)

        self.connect(self.doubleSpinBox_5, SIGNAL("editingFinished()"), self.onNewWireIn5)
        self.connect(self.doubleSpinBox_5, SIGNAL("valueChanged(double)"), self.onNewWireIn5)

#        self.connect(self.doubleSpinBox_6, SIGNAL("editingFinished()"), self.onNewWire06In)
#        self.connect(self.doubleSpinBox_6, SIGNAL("valueChanged(double)"), self.onNewWire06In)
#
#        self.connect(self.doubleSpinBox_7, SIGNAL("editingFinished()"), self.onNewWire07In)
#        self.connect(self.doubleSpinBox_7, SIGNAL("valueChanged(double)"), self.onNewWire07In)
#        
#        self.connect(self.doubleSpinBox_8, SIGNAL("editingFinished()"), self.onNewWire08In)
#        self.connect(self.doubleSpinBox_8, SIGNAL("valueChanged(double)"), self.onNewWire08In)
#
#        self.connect(self.doubleSpinBox_9, SIGNAL("editingFinished()"), self.onNewWire09In)
#        self.connect(self.doubleSpinBox_9, SIGNAL("valueChanged(double)"), self.onNewWire09In)

        self.connect(self.doubleSpinBox_14, SIGNAL("editingFinished()"), self.onNewWireIn14)
        self.connect(self.doubleSpinBox_14, SIGNAL("valueChanged(double)"), self.onNewWireIn14)
        
        self.connect(self.doubleSpinBox_15, SIGNAL("editingFinished()"), self.onNewWireIn15)
        self.connect(self.doubleSpinBox_15, SIGNAL("valueChanged(double)"), self.onNewWireIn15)


    def onCheckMoney(self):
        """
        This method is the handler for "WANT MONEY" messages,
        """
        newData = [0.0 for ix in range(NUM_CHANNEL)]
        
        for i in xrange(NUM_CHANNEL):
            #newVal[i] = self.nerfModel.ReadFPGA(DATA_OUT_ADDR[i])
            newData[i] = max(-65535, min(65535, self.nerfModel.ReadFPGA(DATA_OUT_ADDR[i], CH_TYPE[i])))
#            if i == 0:
#                print newData[i]
            
        self.dispView.newData(newData)
        if (self.isLogData):
            self.data.append(newData)
        
    def onClkRate(self, value):   
        newHalfCnt = 200 * (10 **6) / SAMPLING_RATE / NUM_NEURON / value / 2 / 4
        self.nerfModel.SendPara(newVal = newHalfCnt, trigEvent = DATA_EVT_CLKRATE)
        
#    def onNewWireIn(self, evt):
#        newWireIn = eval('self.doubleSpinBox_'+str(evt)+u'.value()')
#        self.nerfModel.SendPara(newVal = newWireIn, trigEvent = evt)
   
    def onNewWireIn2(self):
        newWireIn = eval('self.doubleSpinBox_'+str(2)+u'.value()')
        self.nerfModel.SendPara(newVal = newWireIn, trigEvent = 2)

    def onNewWireIn4(self):
        newWireIn = self.doubleSpinBox_4.value()
        print newWireIn, 
        self.nerfModel.SendPara(newVal = newWireIn, trigEvent = 4)

    def onNewWireIn5(self):
        newWireIn = self.doubleSpinBox_5.value()
        self.nerfModel.SendPara(newVal = newWireIn, trigEvent = 5)

    def onNewWireIn14(self):
        newWireIn = self.doubleSpinBox_14.value()
        self.nerfModel.SendPara(newVal = newWireIn, trigEvent = 14)
        
    def onNewWireIn15(self):
        newWireIn = self.doubleSpinBox_15.value()
        self.nerfModel.SendPara(newVal = newWireIn, trigEvent = 15)

    def plotData(self, data):
        from pylab import plot, show, subplot
        from scipy.io import savemat, loadmat
        import numpy as np
        
        if (data != []):
            forplot = np.array(data)
            for i in xrange(NUM_CHANNEL):
                subplot(NUM_CHANNEL, 1, i+1)
                plot(forplot[:, i])
            show()
            savemat("./matlab_cmn.mat", {"lce": forplot[:, 0]})
   
    @pyqtSignature("QString")
    def on_comboBox_activated(self, p0):
        """
        Slot documentation goes here.
        """
        choice = p0
        if choice == "Spike Train 1Hz":
#            pipeInData = spike_train(firing_rate = 1) 
            pipeInData = gen_sin(F = 1.0, AMP = 0.3)
        elif choice == "Spike Train 10Hz":
#            pipeInData = spike_train(firing_rate = 10)      
            pipeInData = gen_sin(F = 4.0, AMP = 0.3)
            
        elif choice == "Spike Train 20Hz":
#            pipeInData = gen_tri() 
            pipeInData = gen_seq(T =  [0.0, 0.06, 0.07,  0.24,  0.26,  0.43,  0.44,  0.5, 0.5,  0.56, 0.57,  0.74,  0.76,  0.93,  0.94,  1.0],\
                                 L = [0.0,  0.0,  1.0,  1.0,  -1.0,  -1.0,  0.0,  0.0,  0.0,  0.0,  -1.0,  -1.0,  1.0,  1.0,  0.0,  0.0], FILT = True)

#            pipeInData = spike_train(firing_rate = 100) 
        
        self.nerfModel.SendPipe(pipeInData)

    
    @pyqtSignature("int")
    def on_horizontalSlider_sliderMoved(self, position):
        """
        Slot documentation goes here.
        """
        self.onClkRate(position)
            
    @pyqtSignature("bool")
    def on_pushButton_2_clicked(self, checked):
        """
        Slot documentation goes here.
        """
        self.dispView.close()
        self.plotData(self.data)
    
    @pyqtSignature("int")
    def on_horizontalSlider_valueChanged(self, value):
        """
        Slot documentation goes here.
        """
        self.onClkRate(value)
    
    @pyqtSignature("bool")
    def on_pushButton_5_clicked(self, checked):
        """
        Slot documentation goes here.
        """
        newResetSim = checked
        self.nerfModel.SendButton(newResetSim, BUTTON_RESET_SIM)
    
    @pyqtSignature("bool")
    def on_pushButton_4_clicked(self, checked):
        """
        Slot documentation goes here.
        """
        newResetGlobal = checked
        self.nerfModel.SendButton(newResetGlobal, BUTTON_RESET)
    
    @pyqtSignature("bool")
    def on_pushButtonData_clicked(self, checked):
        """
        Slot documentation goes here.
        """
        self.isLogData = checked
