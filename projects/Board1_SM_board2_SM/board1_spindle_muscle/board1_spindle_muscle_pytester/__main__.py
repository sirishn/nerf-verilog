#!/usr/bin/env python
# -*- coding: utf-8 -*-

if __name__ == "__main__":
    import sys, PyQt4
    sys.path.append('../../../../source/py/')
    from Controls import User
    app = PyQt4.QtGui.QApplication(sys.argv)
    user = User()
    user.show()
    sys.exit(app.exec_())
