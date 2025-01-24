#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian GUI Class for the Sample library
# 
# Copyright (C) 2025 Dan Leinir Turthra Jensen <admin@leinir.dk>
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

class zynthian_gui_sample_library(zynthian_qt_gui_base.zynqtgui):

    def __init__(self, parent = None):
        super(zynthian_gui_sample_library, self).__init__(parent)
        self.__show_only_favorites = False

    def show(self):
        pass

    def refresh_loading(self):
        pass

    # BEGIN Property show_only_favorites
    def get_show_only_favorites(self):
        return self.__show_only_favorites
    def set_show_only_favorites(self, newValue):
        if self.__show_only_favorites != newValue:
            self.__show_only_favorites = newValue
            self.show_only_favorites_changed.emit()
    show_only_favorites_changed = Signal()
    show_only_favorites = Property(bool, get_show_only_favorites, set_show_only_favorites, notify=show_only_favorites_changed)
    # END Property show_only_favorites
#------------------------------------------------------------------------------
