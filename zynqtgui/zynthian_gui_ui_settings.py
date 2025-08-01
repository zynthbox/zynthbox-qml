#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthian GUI UI Settings
#
# Copyright (C) 2025 Anupam Basak <anupam.basak27@gmail.com>
#
# ******************************************************************************
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
# ******************************************************************************

import os
import logging

from PySide2.QtCore import Signal, Property
from . import zynthian_qt_gui_base

class zynthian_gui_ui_settings(zynthian_qt_gui_base.zynqtgui):
    data_dir = os.environ.get("ZYNTHIAN_DATA_DIR", "/zynthian/zynthian-data")
    sys_dir = os.environ.get("ZYNTHIAN_SYS_DIR", "/zynthian/zynthian-sys")

    def __init__(self, parent=None):
        super(zynthian_gui_ui_settings, self).__init__(parent)
        self.__doubleClickThreshold = int(self.zynqtgui.global_settings.value("UI/doubleClickThreshhold", 200))
        self.doubleClickThresholdChanged.emit()

    def fill_list(self):
        super().fill_list()

    def set_select_path(self):
        self.select_path = "UiSettings"
        self.select_path_element = "UiSettings"
        super().set_select_path()

    ### BEGIN Property doubleClickThreshhold
    def get_doubleClickThreshhold(self):
        return self.__doubleClickThreshold

    def set_doubleClickThreshhold(self, value):
        if value != self.__doubleClickThreshold:
            logging.debug(f"Setting doubleClickThreshhold : {value}")
            self.__doubleClickThreshold = value
            self.zynqtgui.global_settings.setValue("UI/doubleClickThreshhold", self.__doubleClickThreshold)
            self.doubleClickThresholdChanged.emit()

    doubleClickThresholdChanged = Signal()

    doubleClickThreshold = Property(int, get_doubleClickThreshhold, set_doubleClickThreshhold, notify=doubleClickThresholdChanged)
    ### END Property doubleClickThreshhold

# ------------------------------------------------------------------------------
