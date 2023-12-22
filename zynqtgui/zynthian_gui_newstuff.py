#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian GUI Class for KNewStuff downloaders
# 
# Copyright (C) 2023 Dan Leinir Turthra Jensen <admin@leinir.dk>
#
#******************************************************************************
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# For a full copy of the GNU General Public License see the LICENSE.txt file.
# 
#******************************************************************************

import sys
import logging
import os
from pathlib import Path

import requests
import threading

from PySide2.QtCore import Qt, Property, Signal, Slot, QObject

# Zynthian specific modules
from . import zynthian_qt_gui_base

#------------------------------------------------------------------------------
# UI class for helping with store access
#------------------------------------------------------------------------------

class zynthian_gui_newstuff(zynthian_qt_gui_base.zynqtgui):

    def __init__(self, parent = None):
        super(zynthian_gui_newstuff, self).__init__(parent)

    def show(self):
        pass

    def refresh_loading(self):
        pass

    @Slot(None)
    def checkStoreConnection(self):
        def task(zynqtgui, channel):
            try:
                reply = requests.head("https://api.kde-look.org/")
                reply.raise_for_status()
                self.storeConnectionStateChecked.emit(True, "")
            except requests.HTTPError as e:
                self.storeConnectionStateChecked.emit(False, f"The store's server returned an error: {e.response.status_code} - {e.response.reason}")
            except requests.ConnectionError:
                self.storeConnectionStateChecked.emit(False, "No internet connection available")
            except Exception as e:
                self.storeConnectionStateChecked.emit(False, f"Unknown error occurred while checking the internet connection: {e}")

        worker_thread = threading.Thread(target=task, args=(self.zynqtgui, self))
        worker_thread.start()

    storeConnectionStateChecked = Signal(bool, str, arguments=["state","message"])

#------------------------------------------------------------------------------
