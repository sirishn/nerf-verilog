from struct import pack, unpack
from PyQt4.QtCore import Qt

VIEWER_REFRESH_RATE = 10 # in ms, This the T for calculating digital freq
NUM_CHANNEL = 6 # Number of channels
PIPE_IN_ADDR = 0x80
PIPE_IN_ADDR1 = 0x81
BUTTON_RESET = 0
BUTTON_RESET_SIM = 1
#BUTTON_ENABLE_SIM = 2
#BUTTON_1 = 2
#BUTTON_2 = 3


#DATA_EVT_PPS_I_COEF = 2
#DATA_EVT_GAMMA_DYN = 5
DATA_EVT_CLKRATE = 7
SEND_TYPE = ['', '', 'float32', 'int32', 'float32', '', 'int32', 'int32', '', '', \
             '', '', '', '', 'float32', 'float32']

DISPLAY_SCALING =[5, 5,  50,   5, 0,  0]
DATA_OUT_ADDR = [0x24, 0x24,  0x24, 0x24,  0x28, 0x30]
CH_TYPE = ['float32', 'float32', 'float32', 'float32', 'float32', 'float32']
CHANNEL_COLOR = [Qt.blue, Qt.red, Qt.green, Qt.black, Qt.yellow, Qt.gray]
ZERO_DATA = [0.0 for ix in xrange(NUM_CHANNEL)]
BIT_FILE = "../board2_spindle_muscle_xem6010.bit"
SAMPLING_RATE = 1024
NUM_NEURON = 512


def ConvertType(val, fromType, toType):
    return unpack(toType, pack(fromType, val))[0]
