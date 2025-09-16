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

from PySide2.QtCore import Signal, Property, Qt
from PySide2.QtGui import QPixmap, QCursor
from . import zynthian_qt_gui_base, zynthian_gui_config
import zynconf

class zynthian_gui_ui_settings(zynthian_qt_gui_base.zynqtgui):
    data_dir = os.environ.get("ZYNTHIAN_DATA_DIR", "/zynthian/zynthian-data")
    sys_dir = os.environ.get("ZYNTHIAN_SYS_DIR", "/zynthian/zynthian-sys")

    def __init__(self, parent=None):
        super(zynthian_gui_ui_settings, self).__init__(parent)
        self.__doubleClickThreshold = int(self.zynqtgui.global_settings.value("UI/doubleClickThreshhold", 200))
        self.doubleClickThresholdChanged.emit()
        self.__hardwareSequencer = True if self.zynqtgui.global_settings.value("UI/hardwareSequencer", "false") == "true" else False
        self.hardwareSequencerChanged.emit();
        self.__debugMode = True if self.zynqtgui.global_settings.value("UI/debugMode", "false") == "true" else False
        self.__showCursor = True if os.environ.get("ZYNTHIAN_UI_ENABLE_CURSOR", "0") == "1" else False
        self.debugModeChanged.emit();

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

    ### BEGIN Property hardwareSequencer
    def get_hardwareSequencer(self):
        return self.__hardwareSequencer

    def set_hardwareSequencer(self, value):
        if value != self.__hardwareSequencer:
            self.__hardwareSequencer = value
            self.zynqtgui.global_settings.setValue("UI/hardwareSequencer", self.__hardwareSequencer)
            self.hardwareSequencerChanged.emit()

    hardwareSequencerChanged = Signal()

    hardwareSequencer = Property(bool, get_hardwareSequencer, set_hardwareSequencer, notify=hardwareSequencerChanged)
    ### END Property hardwareSequencer

    ### BEGIN Property debugMode
    def get_debugMode(self):
        return self.__debugMode

    def set_debugMode(self, value):
        if value != self.__doubleClickThreshold:
            self.__debugMode = value
            self.zynqtgui.global_settings.setValue("UI/debugMode", self.__debugMode)
            self.debugModeChanged.emit()
            zynthian_gui_config.reset_log_level()

    debugModeChanged = Signal()

    debugMode = Property(bool, get_debugMode, set_debugMode, notify=debugModeChanged)
    ### END Property debugMode

    ### BEGIN Property showCursor
    def get_showCursor(self):
        return self.__showCursor

    def set_showCursor(self, value):
        if value != self.__showCursor:
            self.__showCursor = value
            if value == True or value == "1":
                zynthian_gui_config.app.restoreOverrideCursor()
            else:
                nullCursor = QPixmap(16, 16);
                nullCursor.fill(Qt.transparent);
                zynthian_gui_config.app.setOverrideCursor(QCursor(nullCursor));
            zynconf.save_config({"ZYNTHIAN_UI_ENABLE_CURSOR": "1" if value == True or value == "1" else "0"})
            self.showCursorChanged.emit()

    showCursorChanged = Signal()

    showCursor = Property(bool, get_showCursor, set_showCursor, notify=showCursorChanged)
    ### END Property showCursor

# ------------------------------------------------------------------------------
