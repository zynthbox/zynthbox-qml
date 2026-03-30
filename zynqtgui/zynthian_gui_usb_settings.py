#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthian GUI USB Settings
#
# Copyright (C) 2026 Dan Leinir Turthra Jensen <admin@leinir.dk>
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

from PySide2.QtCore import Signal, Property, Qt, QObject
from . import zynthian_qt_gui_base, zynthian_gui_config

class zynthian_gui_usb_settings(zynthian_qt_gui_base.zynqtgui):
    data_dir = os.environ.get("ZYNTHIAN_DATA_DIR", "/zynthian/zynthian-data")
    sys_dir = os.environ.get("ZYNTHIAN_SYS_DIR", "/zynthian/zynthian-sys")

    def __init__(self, parent=None):
        super(zynthian_gui_usb_settings, self).__init__(parent)
        self.__audioInterfaceStyle = int(self.zynqtgui.global_settings.value("USB/audioInterfaceStyle", 0))
        self.__midiPerTrack = True if self.zynqtgui.global_settings.value("USB/midiPerTrack", "true") == "true" else False

    def fill_list(self):
        super().fill_list()

    def set_select_path(self):
        self.select_path = "UsbSettings"
        self.select_path_element = "UsbSettings"
        super().set_select_path()

    ### BEGIN Property audioInterfaceStyle
    # 0 is no audio interface
    # 1 is global stereo pair only
    # 2 is global and per-track stereo pair
    def get_audioInterfaceStyle(self):
        return self.__audioInterfaceStyle

    def set_audioInterfaceStyle(self, value):
        if value != self.__audioInterfaceStyle:
            self.__audioInterfaceStyle = value
            self.zynqtgui.global_settings.setValue("UI/audioInterfaceStyle", self.__audioInterfaceStyle)
            self.audioInterfaceStyleChanged.emit()

    audioInterfaceStyleChanged = Signal()

    audioInterfaceStyle = Property(int, get_audioInterfaceStyle, set_audioInterfaceStyle, notify=audioInterfaceStyleChanged)
    ### END Property audioInterfaceStyle

    ### BEGIN Property midiPerTrack
    def get_midiPerTrack(self):
        return self.__midiPerTrack

    def set_midiPerTrack(self, value):
        if value != self.__midiPerTrack:
            self.__midiPerTrack = value
            self.zynqtgui.global_settings.setValue("UI/midiPerTrack", self.__midiPerTrack)
            self.midiPerTrackChanged.emit()

    midiPerTrackChanged = Signal()

    midiPerTrack = Property(bool, get_midiPerTrack, set_midiPerTrack, notify=midiPerTrackChanged)
    ### END Property midiPerTrack

# ------------------------------------------------------------------------------
