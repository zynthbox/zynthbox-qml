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
    # Use this when something needs to be signalled to /all/ the instances (such as note states)
    __playgrid_instances__ = []

    __input_ports__ = []
    __zynquick_pgmanager__ = None
    __metronome_manager__ = None

    def __init__(self, parent=None):
        super(zynthian_gui_playgrid, self).__init__(parent)
        zynthian_gui_playgrid.__playgrid_instances__.append(self)
        self.__midi_port__ = mido.open_output("Midi Through Port-0")
        self.__play_grid_index__ = 0
        zynthian_gui_playgrid.__metronome_manager__: zynthian_gui_zynthiloops = self.zyngui.screens["zynthiloops"]
        self.listen_to_everything()

    @staticmethod
    def listen_to_everything():
        for port in zynthian_gui_playgrid.__input_ports__:
            try:
                port.close()
            except:
                logging("Attempted to close a port that apparently is broken. It seems we can safely ignore this, so let's do that.")
        zynthian_gui_playgrid.__input_ports__.clear()
        # It's entirely possible we'll need to nab this out of zyngine or somesuch, but for now...
        #for input_name in mido.get_input_names():
        try:
            #input_port = mido.open_input(input_name)
            input_port = mido.open_input()
            input_port.callback = zynthian_gui_playgrid.handle_input_message
            zynthian_gui_playgrid.__input_ports__.append(input_port)
            logging.error("Successfully opened midi input for reading: " + str(input_port))
        except:
            logging.error("Failed to open midi input port for reading")

    @staticmethod
    def handle_input_message(message):
        zynthian_gui_playgrid.__zynquick_pgmanager__.updateNoteState(message.dict())

    def show(self):
        pass

    def zyncoder_read(self):
        pass

    def refresh_loading(self):
        pass

    def __get_play_grids__(self):
        return self.__play_grids__

    @Signal
    def __play_grids_changed__(self):
        pass

    def __get_play_grid_index__(self):
        return self.__play_grid_index__

    def __set_play_grid_index__(self, play_grid_index):
        self.__play_grid_index__ = play_grid_index
        self.__play_grid_index_changed__.emit()

    @Signal
    def __play_grid_index_changed__(self):
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

    @Slot(int, int, int, bool)
    def doAMidiNoteThing(self, midiNote:int, velocity:int, channel:int, setOn:bool):
        command = "note_on" if setOn else "note_off"
        midi_message = mido.Message(command, note=midiNote, channel=channel, velocity=velocity)
        self.__midi_port__.send(midi_message)

    def __get_zynquick_pgmanager__(self):
        return zynthian_gui_playgrid.__zynquick_pgmanager__

    @Slot(QObject)
    def __set_zynquick_pgmanager__(self, thing:QObject):
        # This thing is a singleton, don't set it more than once
        if zynthian_gui_playgrid.__zynquick_pgmanager__ is None:
            zynthian_gui_playgrid.__zynquick_pgmanager__ = thing
            zynthian_gui_playgrid.__zynquick_pgmanager__.sendAMidiNoteMessage.connect(self.doAMidiNoteThing)
            zynthian_gui_playgrid.__zynquick_pgmanager__.requestMetronomeStart.connect(self.startMetronomeRequest)
            zynthian_gui_playgrid.__zynquick_pgmanager__.requestMetronomeStop.connect(self.stopMetronomeRequest)
            zynthian_gui_playgrid.__zynquick_pgmanager__.pitchChanged.connect(self.__set_pitch__)
            zynthian_gui_playgrid.__zynquick_pgmanager__.modulationChanged.connect(self.__set_modulation__)

            # These two should only be the second option... Please, someone fix this, i have no idea what is wrong.
            zynthian_gui_playgrid.__zynquick_pgmanager__.setSyncTimerObj(libzl.getSyncTimerInstance())
            #zynthian_gui_playgrid.__zynquick_pgmanager__.syncTimer = libzl.getSyncTimerInstance()

            self.__zynquick_pgmanager_changed__.emit()
            #logging.error("Really, we should be registering this function, but we need to get at it properly. Maybe pass the libzl instance into the qtquick module instead, though (which needs libzl to be installed and findable, with headers). " + str(getattr(zynthian_gui_playgrid.__zynquick_pgmanager__, "metronomeTick")))
            #libzl.registerTimerCallback(playgrid_cb)

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
    playgrids = Property('QVariantList', __get_play_grids__, notify=__play_grids_changed__)
    playGridIndex = Property(int, __get_play_grid_index__, __set_play_grid_index__, notify=__play_grid_index_changed__)
