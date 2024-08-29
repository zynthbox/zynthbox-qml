#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian GUI Class for editing midi controllers settings
# 
# Copyright (C) 2024 Dan Leinir Turthra Jensen <admin@leinir.dk>
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

# Zynthian specific modules
from . import zynthian_qt_gui_base

#------------------------------------------------------------------------------
# UI class for editing midi controller settings
#------------------------------------------------------------------------------

class zynthian_gui_midicontroller_settings(zynthian_qt_gui_base.zynqtgui):

    def __init__(self, parent = None):
        super(zynthian_gui_midicontroller_settings, self).__init__(parent)

    def show(self):
        pass

    def refresh_loading(self):
        pass
