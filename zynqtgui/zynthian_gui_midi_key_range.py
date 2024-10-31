#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian GUI MIDI key-range config class
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
from ctypes import c_ubyte, c_byte

# Zynthian specific modules
from zyncoder import *
from zyngine import zynthian_controller
from zyngine import zynthian_midi_filter
from . import zynthian_gui_config
from . import zynthian_qt_gui_base
from . import zynthian_gui_controller

from PySide2.QtCore import Qt, QObject, Slot, Signal, Property

#------------------------------------------------------------------------------
# Zynthian MIDI key-range GUI Class
#------------------------------------------------------------------------------

class zynthian_gui_midi_key_range(zynthian_qt_gui_base.zynqtgui):

    black_keys_pattern = (1,0,1,1,0,1,1)


    def __init__(self, parent=None):
        super(zynthian_gui_midi_key_range, self).__init__(parent)
        self.chan = None
        self.note_low = 0
        self.note_high = 127
        self.octave_trans = 0
        self.halftone_trans = 0

        self.learn_toggle = 0

        self.nlow_zctrl=None
        self.nhigh_zctrl=None
        self.octave_zctrl=None
        self.halftone_zctrl=None

        self.replot = True

        self.__was_current_page = False
        self.zynqtgui.current_screen_id_changed.connect(self.check_current_screen, Qt.QueuedConnection)

        ## TODO: Heuristics to automatically split keyboard
        #if self.note_high < 127:
            #zynthian_gui_config.midi_filter_rules = "MAP CH#{ch} NON#0:{high} => CH#{ch2} NON#0:{high}\nMAP CH#{ch} NOFF#0:{high} => CH#{ch2} NOFF#0:{high}\n".format(ch = self.chan, high = self.note_high, ch2 = self.chan+1)
        #else:
            #zynthian_gui_config.midi_filter_rules = None
        #if self.zynqtgui.midi_filter_script:
            #self.zynqtgui.midi_filter_script.clean()
        #self.zynqtgui.midi_filter_script = zynthian_midi_filter.MidiFilterScript(
            #zynthian_gui_config.midi_filter_rules
        #)

    def check_current_screen(self):
        if self.__was_current_page:
            self.zynqtgui.screens["fixed_layers"].fill_list()
        self.__was_current_page = (self.zynqtgui.current_screen_id == "midi_key_range")

    def config(self, chan):
        self.chan = chan
        if -1 < chan and chan < 16:
            self.note_low = zyncoder.lib_zyncoder.get_midi_filter_note_low(chan)
            self.note_high = zyncoder.lib_zyncoder.get_midi_filter_note_high(chan)
            self.octave_trans = zyncoder.lib_zyncoder.get_midi_filter_octave_trans(chan)
            self.halftone_trans = zyncoder.lib_zyncoder.get_midi_filter_halftone_trans(chan)
        self.set_select_path()

    @Slot(int, result=str)
    def get_midi_note_name(self, num):
        note_names = ("C","C#","D","D#","E","F","F#","G","G#","A","A#","B")
        scale = int(num/12)-1
        num = int(num%12)
        return "{}{}".format(note_names[num],scale)

    def set_zctrls(self):
        logging.debug(f"### Setting midi_key_range zctrl")

        if self.shown:
            if self.nlow_zctrl:
                self.nlow_zctrl.setup_zyncoder()
            else:
                self.nlow_ctrl=zynthian_controller(None, 'note_low', 'note_low', { 'midi_cc':0, 'value_max':127 })
                self.nlow_zctrl=zynthian_gui_controller(1, self.nlow_ctrl, self)
            self.nlow_zctrl.val0 = 0

            if self.nhigh_zctrl:
                self.nhigh_zctrl.setup_zyncoder()
            else:
                self.nhigh_ctrl=zynthian_controller(None, 'note_high', 'note_high', { 'midi_cc':0, 'value_max':127 })
                self.nhigh_zctrl=zynthian_gui_controller(3, self.nhigh_ctrl, self)
            self.nhigh_zctrl.val0 = 0

            if self.octave_zctrl:
                self.octave_zctrl.setup_zyncoder()
            else:
                self.octave_ctrl=zynthian_controller(None, 'octave transpose', 'octave transpose', { 'midi_cc':0, 'value_max':11 })
                self.octave_zctrl=zynthian_gui_controller(2, self.octave_ctrl, self)
            self.octave_zctrl.val0 = -5

            if self.halftone_zctrl:
                self.halftone_zctrl.setup_zyncoder()
            else:
                self.halftone_ctrl=zynthian_controller(None, 'semitone transpose', 'semitone transpose', { 'midi_cc':0, 'value_max':25 })
                self.halftone_zctrl=zynthian_gui_controller(0, self.halftone_ctrl, self)
            self.halftone_zctrl.val0 = -12

            if self.zynqtgui.get_current_screen_id() is not None and self.zynqtgui.get_current_screen() == self:

                self.nlow_zctrl.set_value(self.note_low, True)
                self.nlow_zctrl.show()

                self.nhigh_zctrl.set_value(self.note_high, True)
                self.nhigh_zctrl.show()

                self.octave_zctrl.set_value(self.octave_trans + 5, True)
                self.octave_zctrl.show()

                self.halftone_zctrl.set_value(self.halftone_trans + 12, True)
                self.halftone_zctrl.show()
            else:
                self.nlow_zctrl.hide()
                self.nhigh_zctrl.hide()
                self.octave_zctrl.hide()
                self.halftone_zctrl.hide()

    def get_note_low_controller(self):
        if not self.nlow_zctrl:
            self.show()
            self.set_zctrls()
        return self.nlow_zctrl
    note_low_controller = Property(QObject, get_note_low_controller, constant = True)

    def get_note_high_controller(self):
        if not self.nhigh_zctrl:
            self.show()
            self.set_zctrls()
        return self.nhigh_zctrl
    note_high_controller = Property(QObject, get_note_high_controller, constant = True)

    def get_octave_controller(self):
        if not self.octave_zctrl:
            self.show()
            self.set_zctrls()
        return self.octave_zctrl
    octave_controller = Property(QObject, get_octave_controller, constant = True)

    def get_halftone_controller(self):
        if not self.halftone_zctrl:
            self.show()
            self.set_zctrls()
        return self.halftone_zctrl
    get_halftone_controller = Property(QObject, get_halftone_controller, constant = True)

    def show(self):
        super().show()
        self.zynqtgui.screens["control"].unlock_controllers()
        self.set_zctrls()
        #Disable automatic learning for now
        #zyncoder.lib_zyncoder.set_midi_learning_mode(1)


    def hide(self):
        super().hide()
        self.set_zctrls()
        #zyncoder.lib_zyncoder.set_midi_learning_mode(0)

    def zyncoder_read(self, zcnums=None):
        if self.zynqtgui.get_current_screen_id() is not None and self.zynqtgui.get_current_screen() == self:
            self.nlow_zctrl.read_zyncoder()
            if self.note_low!=self.nlow_zctrl.value:
                if self.nlow_zctrl.value>self.note_high:
                    self.nlow_zctrl.set_value(self.note_high-1, True)
                    self.note_low = self.note_high-1
                else:
                    self.note_low = self.nlow_zctrl.value
                    logging.debug("SETTING FILTER NOTE_LOW: {}".format(self.note_low))
                    zyncoder.lib_zyncoder.set_midi_filter_note_low(self.chan, int(self.note_low))
                    self.replot = True

            self.nhigh_zctrl.read_zyncoder()
            if self.note_high!=self.nhigh_zctrl.value:
                if self.nhigh_zctrl.value<self.note_low:
                    self.nhigh_zctrl.set_value(self.note_low+1, True)
                    self.note_high = self.note_low+1
                else:
                    self.note_high = self.nhigh_zctrl.value
                logging.debug("SETTING FILTER NOTE_HIGH: {}".format(self.note_high))
                zyncoder.lib_zyncoder.set_midi_filter_note_high(self.chan, int(self.note_high))
                self.replot = True

            self.octave_zctrl.read_zyncoder()
            if (self.octave_trans+5)!=self.octave_zctrl.value:
                self.octave_trans = self.octave_zctrl.value-5
                logging.debug("SETTING FILTER OCTAVE TRANS.: {}".format(self.octave_trans))
                zyncoder.lib_zyncoder.set_midi_filter_octave_trans(self.chan, int(self.octave_trans))
                self.replot = True

            self.halftone_zctrl.read_zyncoder()
            if (self.halftone_trans+12)!=self.halftone_zctrl.value:
                self.halftone_trans = self.halftone_zctrl.value-12
                logging.debug("SETTING FILTER HALFTONE TRANS.: {}".format(self.halftone_trans))
                zyncoder.lib_zyncoder.set_midi_filter_halftone_trans(self.chan, int(self.halftone_trans))
                self.replot = True

        return [0]


    #def learn_note_range(self, num):
        #if self.learn_toggle==0 or num<=self.note_low:
            #self.nlow_zctrl.set_value(num, True)
            #if self.note_low>self.note_high:
                #self.nhigh_zctrl.set_value(127, True)
            #self.learn_toggle = 1
        #else:
            #self.nhigh_zctrl.set_value(num, True)
            #self.learn_toggle = 0



    def set_select_path(self):
        try:
            self.select_path = ("{} > Note Range & Transpose...".format(self.zynqtgui.screens['layer_options'].layer.get_basepath()))
        except:
            self.select_path = ("Note Range & Transpose...")
        super().set_select_path()


#------------------------------------------------------------------------------
