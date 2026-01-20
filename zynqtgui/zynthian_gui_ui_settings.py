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
from subprocess import check_output

from PySide2.QtCore import Signal, Property, Qt
from PySide2.QtGui import QPixmap, QCursor, QGuiApplication
from . import zynthian_qt_gui_base, zynthian_gui_config

class zynthian_gui_ui_settings(zynthian_qt_gui_base.zynqtgui):
    data_dir = os.environ.get("ZYNTHIAN_DATA_DIR", "/zynthian/zynthian-data")
    sys_dir = os.environ.get("ZYNTHIAN_SYS_DIR", "/zynthian/zynthian-sys")

    def __init__(self, parent=None):
        super(zynthian_gui_ui_settings, self).__init__(parent)
        self.__doubleClickThreshold = int(self.zynqtgui.global_settings.value("UI/doubleClickThreshhold", 200))
        self.__hardwareSequencer = True if self.zynqtgui.global_settings.value("UI/hardwareSequencer", "true") == "true" else False
        self.__hardwareSequencerPreviewStyle = int(self.zynqtgui.global_settings.value("UI/hardwareSequencerPreviewStyle", 0))
        self.__hardwareSequencerEditInclusions = int(self.zynqtgui.global_settings.value("UI/hardwareSequencerEditInclusions", 0))
        self.__temporaryLiveRecordStyle = int(self.zynqtgui.global_settings.value("UI/temporaryLiveRecordStyle", 1))
        self.__debugMode = True if self.zynqtgui.global_settings.value("UI/debugMode", "false") == "true" else False
        self.__showCursor = True if self.zynqtgui.global_settings.value("UI/showCursor", "false") == "true" else False
        self.__touchEncoders = True if self.zynqtgui.global_settings.value("UI/touchEncoders", "false") == "true" else False
        self.__vncserverEnabled = True if self.zynqtgui.global_settings.value("UI/vncserverEnabled", "false") == "true" else False
        self.__fontSize = self.zynqtgui.global_settings.value("UI/fontSize", None)

    def fill_list(self):
        super().fill_list()

    def set_select_path(self):
        self.select_path = "UiSettings"
        self.select_path_element = "UiSettings"
        super().set_select_path()

    def start_vncserver(self):
        logging.info("STARTING VNC SERVICES")
        try:
            check_output("systemctl start vncserver0; systemctl start novnc0", shell=True)
            self.vncserverEnabled = True
        except Exception as e:
            logging.error(e)

    def stop_vncserver(self):
        logging.info("STOPPING VNC SERVICES")

        try:
            check_output("systemctl stop novnc0;", shell=True)
            self.vncserverEnabled = False
        except Exception as e:
            logging.error(e)

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

    ### BEGIN Property hardwareSequencerPreviewStyle
    def get_hardwareSequencerPreviewStyle(self):
        return self.__hardwareSequencerPreviewStyle

    def set_hardwareSequencerPreviewStyle(self, value):
        if value != self.__hardwareSequencerPreviewStyle:
            self.__hardwareSequencerPreviewStyle = value
            self.zynqtgui.global_settings.setValue("UI/hardwareSequencerPreviewStyle", self.__hardwareSequencerPreviewStyle)
            self.hardwareSequencerPreviewStyleChanged.emit()

    hardwareSequencerPreviewStyleChanged = Signal()

    hardwareSequencerPreviewStyle = Property(int, get_hardwareSequencerPreviewStyle, set_hardwareSequencerPreviewStyle, notify=hardwareSequencerPreviewStyleChanged)
    ### END Property hardwareSequencerPreviewStyle

    ### BEGIN Property hardwareSequencerEditInclusions
    def get_hardwareSequencerEditInclusions(self):
        return self.__hardwareSequencerEditInclusions

    def set_hardwareSequencerEditInclusions(self, value):
        if value != self.__hardwareSequencerEditInclusions:
            self.__hardwareSequencerEditInclusions = value
            self.zynqtgui.global_settings.setValue("UI/hardwareSequencerEditInclusions", self.__hardwareSequencerEditInclusions)
            self.hardwareSequencerEditInclusionsChanged.emit()

    hardwareSequencerEditInclusionsChanged = Signal()

    hardwareSequencerEditInclusions = Property(int, get_hardwareSequencerEditInclusions, set_hardwareSequencerEditInclusions, notify=hardwareSequencerEditInclusionsChanged)
    ### END Property hardwareSequencerEditInclusions

    ### BEGIN Property temporaryLiveRecordStyle
    # 0 is no temporary live recording
    # 1 is temporary live recording when record is held down
    # 2 is sticky (live recording will remain active if at least one note was recorded)
    def get_temporaryLiveRecordStyle(self):
        return self.__temporaryLiveRecordStyle

    def set_temporaryLiveRecordStyle(self, value):
        if value != self.__temporaryLiveRecordStyle:
            self.__temporaryLiveRecordStyle = value
            self.zynqtgui.global_settings.setValue("UI/temporaryLiveRecordStyle", self.__temporaryLiveRecordStyle)
            self.temporaryLiveRecordStyleChanged.emit()

    temporaryLiveRecordStyleChanged = Signal()

    temporaryLiveRecordStyle = Property(int, get_temporaryLiveRecordStyle, set_temporaryLiveRecordStyle, notify=temporaryLiveRecordStyleChanged)
    ### END Property temporaryLiveRecordStyle

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

    def set_showCursor(self, value, force_set=False):
        if value != self.__showCursor or force_set:
            self.__showCursor = value
            if value == True:
                zynthian_gui_config.app.restoreOverrideCursor()
            else:
                nullCursor = QPixmap(16, 16);
                nullCursor.fill(Qt.transparent);
                zynthian_gui_config.app.setOverrideCursor(QCursor(nullCursor));
            self.zynqtgui.global_settings.setValue("UI/showCursor", self.__showCursor)
            self.showCursorChanged.emit()

    showCursorChanged = Signal()

    showCursor = Property(bool, get_showCursor, set_showCursor, notify=showCursorChanged)
    ### END Property showCursor

    ### BEGIN Property touchEncoders
    def get_touchEncoders(self):
        return self.__touchEncoders

    def set_touchEncoders(self, value, force_set=False):
        if value != self.__touchEncoders or force_set:
            self.__touchEncoders = value
            self.zynqtgui.global_settings.setValue("UI/touchEncoders", self.__touchEncoders)
            self.touchEncodersChanged.emit()

    touchEncodersChanged = Signal()

    touchEncoders = Property(bool, get_touchEncoders, set_touchEncoders, notify=touchEncodersChanged)
    ### END Property touchEncoders

    ### BEGIN Property vncserverEnabled
    def get_vncserverEnabled(self):
        return self.__vncserverEnabled

    def set_vncserverEnabled(self, value, force_set=False):
        if value != self.__vncserverEnabled or force_set:
            self.__vncserverEnabled = value
            self.zynqtgui.global_settings.setValue("UI/vncserverEnabled", self.__vncserverEnabled)
            if value == True:
                self.start_vncserver()
            else:
                self.stop_vncserver()
            self.vncserverEnabledChanged.emit()

    vncserverEnabledChanged = Signal()

    vncserverEnabled = Property(bool, get_vncserverEnabled, set_vncserverEnabled, notify=vncserverEnabledChanged)
    ### END Property vncserverEnabled

    ### BEGIN Property fontSize
    def get_fontSize(self):
        return self.__fontSize

    def set_fontSize(self, value):
        if value != self.__fontSize:
            self.__fontSize = value
            self.zynqtgui.global_settings.setValue("UI/fontSize", self.__fontSize)
            app = QGuiApplication.instance()
            font = app.font()
            font.setPointSize(self.__fontSize)
            app.setFont(font)
            self.fontSizeChanged.emit()

    def reset_fontSize(self):
        self.zynqtgui.global_settings.remove("UI/fontSize")
        self.zynqtgui.theme_chooser.apply_font()

    fontSizeChanged = Signal()

    fontSize = Property(int, get_fontSize, set_fontSize, notify=fontSizeChanged)
    ### END Property fontSize

# ------------------------------------------------------------------------------
