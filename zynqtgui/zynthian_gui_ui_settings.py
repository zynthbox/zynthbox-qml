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
from pathlib import Path
from PySide2.QtCore import Signal, Property, Qt, QObject, QFileSystemWatcher
from PySide2.QtGui import QPixmap, QCursor, QGuiApplication
from . import zynthian_qt_gui_base, zynthian_gui_config

class DisplaySettings(QObject):
    def __init__(self, id, parent=None):
        super(DisplaySettings, self).__init__(parent)
        
        self.__id = id
        self.__name = ""
        self.__brightness = 0
        self.__min_brightness = 0
        self.__max_brightness = 0

        # Read display settings from /sys/class/backlight/{id}
        self.backlight_path = Path(f"/sys/class/backlight/{id}")
        if self.backlight_path.exists():
            try:
                display_name_file = self.backlight_path / "display_name"
                if display_name_file.exists():
                    self.__name = display_name_file.read_text().strip()
                
                brightness_file = self.backlight_path / "brightness"
                if brightness_file.exists():
                    self.__brightness = int(brightness_file.read_text().strip())
                
                max_brightness_file = self.backlight_path / "max_brightness"
                if max_brightness_file.exists():
                    self.__max_brightness = int(max_brightness_file.read_text().strip())
            except Exception as e:
                logging.error(f"Error reading backlight settings for {id}: {e}")
    
    ### BEGIN Property id
    def get_id(self):
        return self.__id
    
    id = Property(str, get_id, constant=True)
    ### END Property id

    ### BEGIN Property name
    def get_name(self):
        return self.__name

    name = Property(str, get_name, constant=True)
    ### END Property name

    ### BEGIN Property brightness
    def get_brightness(self):
        return self.__brightness

    def set_brightness(self, value):
        if value != self.__brightness:
            self.__brightness = value
            brightness_file = self.backlight_path / "brightness"
            if brightness_file.exists():
                brightness_file.write_text(str(value))
            self.brightnessChanged.emit()

    brightnessChanged = Signal()
    brightness = Property(int, get_brightness, set_brightness, notify=brightnessChanged)
    ### END Property brightness
    
    ### BEGIN Property min_brightness
    def get_min_brightness(self):
        return self.__min_brightness
    
    min_brightness = Property(int, get_min_brightness, constant=True)
    ### END Property min_brightness
    
    ### BEGIN Property max_brightness
    def get_max_brightness(self):
        return self.__max_brightness
    
    max_brightness = Property(int, get_max_brightness, constant=True)
    ### END Property max_brightness

class zynthian_gui_ui_settings(zynthian_qt_gui_base.zynqtgui):
    data_dir = os.environ.get("ZYNTHIAN_DATA_DIR", "/zynthian/zynthian-data")
    sys_dir = os.environ.get("ZYNTHIAN_SYS_DIR", "/zynthian/zynthian-sys")

    def __init__(self, parent=None):
        super(zynthian_gui_ui_settings, self).__init__(parent)
        self.__doubleClickThreshold = int(self.zynqtgui.global_settings.value("UI/doubleClickThreshhold", 200))
        self.__recordButtonInteractionStyle = int(self.zynqtgui.global_settings.value("UI/recordButtonInteractionStyle", 0))
        self.__hardwareSequencer = True if self.zynqtgui.global_settings.value("UI/hardwareSequencer", "true") == "true" else False
        self.__hardwareSequencerPreviewStyle = int(self.zynqtgui.global_settings.value("UI/hardwareSequencerPreviewStyle", 0))
        self.__hardwareSequencerEditInclusions = int(self.zynqtgui.global_settings.value("UI/hardwareSequencerEditInclusions", 0))
        self.__temporaryLiveRecordStyle = int(self.zynqtgui.global_settings.value("UI/temporaryLiveRecordStyle", 1))
        self.__sampleAutoPreview = True if self.zynqtgui.global_settings.value("UI/sampleAutoPreview", "true") == "true" else False
        self.__debugMode = True if self.zynqtgui.global_settings.value("UI/debugMode", "false") == "true" else False
        self.__showExperimentalFeatures = True if self.zynqtgui.global_settings.value("UI/showExperimentalFeatures", "false") == "true" else False
        self.__showCursor = True if self.zynqtgui.global_settings.value("UI/showCursor", "false") == "true" else False
        self.__touchEncoders = True if self.zynqtgui.global_settings.value("UI/touchEncoders", "false") == "true" else False
        self.__vncserverEnabled = True if self.zynqtgui.global_settings.value("UI/vncserverEnabled", "false") == "true" else False
        self.__fontSize = self.zynqtgui.global_settings.value("UI/fontSize", None)
        self.__displays = [DisplaySettings(d.name, self) for d in Path("/sys/class/backlight").iterdir() if d.is_dir()]
        self.__ledBrightness = int(self.zynqtgui.global_settings.value("UI/ledBrightness", 15))

        self.__qmlFileWatcher = QFileSystemWatcher()
        self.__qmlFileWatcher.addPath("/ZB_QML_TEST_FILE")
        self.__qmlFileWatcher.addPath(self.get_qmlTestFile())
        self.__qmlFileWatcher.fileChanged.connect(self.on_qmlFileChanged)

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

    ### BEGIN Property recordButtonInteractionStyle
    # 0: press record button to open the recording dialogue, hold alt then press record button to immediately start recording. If recording is running, press record to open recording dialogue.
    # 1: press record button to immediately start recording, hold alt then press record button to open recording dialogue. If recording is running, press record to open recording dialogue.
    def get_recordButtonInteractionStyle(self):
        return self.__recordButtonInteractionStyle

    def set_recordButtonInteractionStyle(self, value):
        if value != self.__recordButtonInteractionStyle:
            self.__recordButtonInteractionStyle = value
            self.zynqtgui.global_settings.setValue("UI/recordButtonInteractionStyle", self.__recordButtonInteractionStyle)
            self.recordButtonInteractionStyleChanged.emit()

    recordButtonInteractionStyleChanged = Signal()

    recordButtonInteractionStyle = Property(int, get_recordButtonInteractionStyle, set_recordButtonInteractionStyle, notify=recordButtonInteractionStyleChanged)
    ### END Property recordButtonInteractionStyle

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

    ### BEGIN Property sampleAutoPreview
    def get_sampleAutoPreview(self):
        return self.__sampleAutoPreview

    def set_sampleAutoPreview(self, value):
        if value != self.__sampleAutoPreview:
            self.__sampleAutoPreview = value
            self.zynqtgui.global_settings.setValue("UI/sampleAutoPreview", self.__sampleAutoPreview)
            self.sampleAutoPreviewChanged.emit()

    sampleAutoPreviewChanged = Signal()

    sampleAutoPreview = Property(bool, get_sampleAutoPreview, set_sampleAutoPreview, notify=sampleAutoPreviewChanged)
    ### END Property sampleAutoPreview

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

    ### BEGIN Property showExperimentalFeatures
    def get_showExperimentalFeatures(self):
        return self.__showExperimentalFeatures

    def set_showExperimentalFeatures(self, value):
        if value != self.__doubleClickThreshold:
            self.__showExperimentalFeatures = value
            self.zynqtgui.global_settings.setValue("UI/showExperimentalFeatures", self.__showExperimentalFeatures)
            self.showExperimentalFeaturesChanged.emit()
            zynthian_gui_config.reset_log_level()

    showExperimentalFeaturesChanged = Signal()

    showExperimentalFeatures = Property(bool, get_showExperimentalFeatures, set_showExperimentalFeatures, notify=showExperimentalFeaturesChanged)
    ### END Property showExperimentalFeatures

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
    
    ### BEGIN Property displays
    def get_displays(self):
        return self.__displays
    
    displays = Property('QVariantList', get_displays, constant=True)
    ### END Property displays

    ### BEGIN Property qmlTestFIle
    def get_qmlTestFile(self):
        try:                
            with open('/ZB_QML_TEST_FILE', 'r') as f:
                return f.readline().strip()
        except FileNotFoundError:
            with open('/ZB_QML_TEST_FILE', 'w') as f:
                f.write("")
            return ""
        except (PermissionError, IsADirectoryError) as e:
            print(f"An unexpected error occurred: {e}")
            return ""    

    def on_qmlFileChanged(self, path):       
        if(path == "/ZB_QML_TEST_FILE"):
            self.qmlTestFileChanged.emit()
            self.__qmlFileWatcher.addPath(self.get_qmlTestFile())
            self.__qmlFileWatcher.addPath("/ZB_QML_TEST_FILE")
        else: 
            self.qmlTestFileModified.emit()
            self.__qmlFileWatcher.addPath(path) 


    qmlTestFileChanged = Signal()
    qmlTestFileModified = Signal()

    qmlTestFile = Property(str, get_qmlTestFile, notify=qmlTestFileChanged)
    ### END Property qmlTestFIle

    ### BEGIN Property ledBrightness
    def get_ledBrightness(self):
        return self.__ledBrightness

    def set_ledBrightness(self, value):
        if value != self.__ledBrightness:
            self.__ledBrightness = value
            self.zynqtgui.global_settings.setValue("UI/ledBrightness", self.__ledBrightness)
            self.ledBrightnessChanged.emit()

    ledBrightnessChanged = Signal()

    ledBrightness = Property(int, get_ledBrightness, set_ledBrightness, notify=ledBrightnessChanged)
    ### END Property ledBrightness

# ------------------------------------------------------------------------------
