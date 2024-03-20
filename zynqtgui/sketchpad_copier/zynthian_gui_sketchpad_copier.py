#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthian Sketchpad Copier: A page to copy channels between sketchpads in a session
#
# Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
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
import logging

from PySide2.QtCore import Property, QObject, Signal, Slot

from .. import zynthian_qt_gui_base
from zynqtgui.sketchpad.sketchpad_channel import sketchpad_channel


class zynthian_gui_sketchpad_copier(zynthian_qt_gui_base.zynqtgui):
    def __init__(self, parent=None):
        super(zynthian_gui_sketchpad_copier, self).__init__(parent)
        self.__channel_copy_cache__ = None
        self.__channel_copy_source__ = None
        self.__add_sketchpad_path__ = ""

    ### Property isCopyInProgress
    def get_is_copy_in_progress(self):
        return self.__channel_copy_cache__ is not None
    is_copy_in_progress_changed = Signal()
    isCopyInProgress = Property(bool, get_is_copy_in_progress, notify=is_copy_in_progress_changed)
    ### END Property isCopyInProgress

    ### Property addSketchpadPath
    def get_add_sketchpad_path(self):
        return self.__add_sketchpad_path__
    def set_add_sketchpad_path(self, path):
        self.__add_sketchpad_path__ = path
        self.add_sketchpad_path_changed.emit()
    add_sketchpad_path_changed = Signal()
    addSketchpadPath = Property(str, get_add_sketchpad_path, set_add_sketchpad_path, notify=add_sketchpad_path_changed)
    ### END Property addSketchpadPath

    ### Property channelCopySource
    def get_channel_copy_source(self):
        return self.__channel_copy_source__
    channel_copy_source_changed = Signal()
    channelCopySource = Property(QObject, get_channel_copy_source, notify=channel_copy_source_changed)
    ### END Property channelCopySource

    @Slot(QObject)
    def copyChannel(self, channel):
        self.__channel_copy_cache__ = channel.serialize()
        self.__channel_copy_source__ = channel
        self.is_copy_in_progress_changed.emit()
        self.channel_copy_source_changed.emit()

        logging.info(f"Copied channel : {self.__channel_copy_cache__}")

    @Slot(None)
    def cancelCopyChannel(self):
        self.__channel_copy_cache__ = None
        self.__channel_copy_source__ = None
        self.is_copy_in_progress_changed.emit()
        self.channel_copy_source_changed.emit()

        logging.info(f"Channel Copy Cancelled")

    @Slot(QObject)
    def pasteChannel(self, sketchpad):
        logging.info(f"Pasting channel to sketchpad : {sketchpad.name}")

        pasted_channel = sketchpad_channel(sketchpad.channelsModel.count, sketchpad, self)
        sketchpad.channelsModel.add_channel(pasted_channel)
        pasted_channel.deserialize(self.__channel_copy_cache__)
        self.__channel_copy_cache__ = None
        self.__channel_copy_source__ = None
        self.is_copy_in_progress_changed.emit()
        self.channel_copy_source_changed.emit()

    @Slot(int)
    def setSketchpadSlot(self, slot):
        self.zynqtgui.session_dashboard.setSketchpadSlot(slot, self.__add_sketchpad_path__)
        self.__add_sketchpad_path__ = ""
        self.add_sketchpad_path_changed.emit()
