#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthian PlayGrid: A page to play ntoes with buttons
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

from PySide2.QtCore import (
    Property,
    QObject,
    Signal,
    Slot,
)

from . import zynthian_qt_gui_base
from .sketchpad import zynthian_gui_sketchpad

class zynthian_gui_playgrid(zynthian_qt_gui_base.zynqtgui):

    __zynquick_pgmanager__ = None
    __metronome_manager__ = None

    def __init__(self, parent=None):
        super(zynthian_gui_playgrid, self).__init__(parent)
        zynthian_gui_playgrid.__metronome_manager__: zynthian_gui_sketchpad = self.zynqtgui.screens["sketchpad"]

    def show(self):
        pass

    def refresh_loading(self):
        pass

    def __get_zynquick_pgmanager__(self):
        return zynthian_gui_playgrid.__zynquick_pgmanager__

    @Slot(QObject)
    def __set_zynquick_pgmanager__(self, thing:QObject):
        # This thing is a singleton, don't set it more than once
        if zynthian_gui_playgrid.__zynquick_pgmanager__ is None:
            zynthian_gui_playgrid.__zynquick_pgmanager__ = thing
            zynthian_gui_playgrid.__zynquick_pgmanager__.requestMetronomeStart.connect(self.startMetronomeRequest)
            zynthian_gui_playgrid.__zynquick_pgmanager__.requestMetronomeStop.connect(self.stopMetronomeRequest)

            self.__zynquick_pgmanager_changed__.emit()

    @Signal
    def __zynquick_pgmanager_changed__(self):
        pass

    @Slot(None)
    def startMetronomeRequest(self):
        zynthian_gui_playgrid.__metronome_manager__.start_metronome_request()

    @Slot(None)
    def stopMetronomeRequest(self):
        zynthian_gui_playgrid.__metronome_manager__.stop_metronome_request()

    zynquickPgmanager = Property(QObject, __get_zynquick_pgmanager__, __set_zynquick_pgmanager__, notify=__zynquick_pgmanager_changed__)

    @Slot(str)
    def setCurrentTaskMessage(self, msg):
        self.zynqtgui.currentTaskMessage = msg
