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

import mido
import typing
import logging
import sys
import ctypes as ctypes

from PySide2.QtCore import (
    Slot,
    Qt,
    QObject,
    Property,
    Signal,
)
from . import zynthian_qt_gui_base
from .zynthiloops import zynthian_gui_zynthiloops

sys.path.insert(1, "./zynthiloops/libzl")
from .zynthiloops.libzl import libzl

@ctypes.CFUNCTYPE(None, ctypes.c_int)
def playgrid_cb(beat):
    zynthian_gui_playgrid.__zynquick_pgmanager__.metronomeTick(beat)

class zynthian_gui_playgrid(zynthian_qt_gui_base.ZynGui):

    __zynquick_pgmanager__ = None
    __metronome_manager__ = None

    def __init__(self, parent=None):
        super(zynthian_gui_playgrid, self).__init__(parent)
        self.__midi_port__ = mido.open_output("Midi Through Port-0")
        zynthian_gui_playgrid.__metronome_manager__: zynthian_gui_zynthiloops = self.zyngui.screens["zynthiloops"]

    def show(self):
        pass

    def zyncoder_read(self):
        pass

    def refresh_loading(self):
        pass

    def __set_pitch__(self):
        midi_pitch_message = mido.Message(
            "pitchwheel", channel=0, pitch=zynthian_gui_playgrid.__zynquick_pgmanager__.property("pitch")
        )
        self.__midi_port__.send(midi_pitch_message)

    def __set_modulation__(self):
        modulation_message = mido.Message(
            "control_change", channel=0, control=1, value=zynthian_gui_playgrid.__zynquick_pgmanager__.property("modulation")
        )
        self.__midi_port__.send(modulation_message)

    def __get_zynquick_pgmanager__(self):
        return zynthian_gui_playgrid.__zynquick_pgmanager__

    @Slot(QObject)
    def __set_zynquick_pgmanager__(self, thing:QObject):
        # This thing is a singleton, don't set it more than once
        if zynthian_gui_playgrid.__zynquick_pgmanager__ is None:
            zynthian_gui_playgrid.__zynquick_pgmanager__ = thing
            zynthian_gui_playgrid.__zynquick_pgmanager__.requestMetronomeStart.connect(self.startMetronomeRequest)
            zynthian_gui_playgrid.__zynquick_pgmanager__.requestMetronomeStop.connect(self.stopMetronomeRequest)
            zynthian_gui_playgrid.__zynquick_pgmanager__.pitchChanged.connect(self.__set_pitch__)
            zynthian_gui_playgrid.__zynquick_pgmanager__.modulationChanged.connect(self.__set_modulation__)

            # These two should only be the second option... Please, someone fix this, i have no idea what is wrong.
            zynthian_gui_playgrid.__zynquick_pgmanager__.setSyncTimerObj(libzl.getSyncTimerInstance())
            #zynthian_gui_playgrid.__zynquick_pgmanager__.syncTimer = libzl.getSyncTimerInstance()

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
