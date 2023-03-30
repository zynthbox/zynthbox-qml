#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian GUI Option Selector Class
# 
# Copyright (C) 2015-2020 Fernando Moyano <jofemodo@zynthian.org>
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

# Zynthian specific modules
from . import zynthian_qt_gui_base
from PySide2.QtCore import Qt, QObject, Signal, Slot, Property

#------------------------------------------------------------------------------
# Zynthian Option Selection GUI Class
#------------------------------------------------------------------------------

class zynthian_gui_channel(zynthian_qt_gui_base.zynqtgui):
    def __init__(self, parent=None):
        super(zynthian_gui_channel, self).__init__(parent)
        self.title = "Channels"
        self.__channel_id__ = 0
        self.__part_id__ = 0

    def show(self):
        pass

    @Signal
    def __channel_id_changed__(self):
        pass

    @Property(int, notify=__channel_id_changed__)
    def channelId(self):
        return self.__channel_id__

    @channelId.setter
    def setChannelId(self, tId):
        self.__channel_id__ = tId
        self.__channel_id_changed__.emit()
        self.__channel_changed__.emit()

    @Signal
    def __part_id_changed__(self):
        pass

    @Property(int, notify=__part_id_changed__)
    def partId(self):
        return self.__part_id__

    @partId.setter
    def setPartId(self, pId):
        self.__part_id__ = pId
        self.__part_id_changed__.emit()
        self.__part_changed__.emit()

    @Signal
    def __channel_changed__(self):
        pass

    @Property(QObject, notify=__channel_changed__)
    def channel(self):
        return self.zynqtgui.screens['sketchpad'].song.channelsModel.getChannel(self.__channel_id__)


    @Signal
    def __part_changed__(self):
        pass

    @Property(QObject, notify=__part_changed__)
    def part(self):
        return self.zynqtgui.screens['sketchpad'].song.partsModel.getPart(self.__part_id__)

    def set_select_path(self):
        self.select_path = self.title
        self.select_path_element = self.title


#------------------------------------------------------------------------------
