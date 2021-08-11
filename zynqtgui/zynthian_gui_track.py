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

from PySide2.QtCore import Qt, QObject, Signal, Property

#------------------------------------------------------------------------------
# Zynthian Option Selection GUI Class
#------------------------------------------------------------------------------

class zynthian_gui_track(zynthian_qt_gui_base.ZynGui):
    def __init__(self, parent=None):
        super(zynthian_gui_track, self).__init__(parent)
        self.title = "Tracks"
        self.__track_id__ : int = 0

    def show(self):
        pass

    @Signal
    def __track_id_changed__(self):
        pass

    @Property(int, notify=__track_id_changed__)
    def trackId(self):
        return self.__track_id__

    @trackId.setter
    def setTrackId(self, tId):
        self.__track_id__ = tId
        self.__track_id_changed__.emit()
        self.__track_changed__.emit()


    @Signal
    def __track_changed__(self):
        pass

    @Property(QObject, notify=__track_changed__)
    def track(self):
        return self.zyngui.screens['zynthiloops'].song.tracksModel.getTrack(self.__track_id__)


    def set_select_path(self):
        self.select_path = self.title


#------------------------------------------------------------------------------
