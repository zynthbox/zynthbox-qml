#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthian GUI Option Selector Class for setting up details for a channel in external audio mode
#
# Copyright (C) 2023 Dan Leinir Turthra Jensen <admin@leinir.dk>
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
import os
from pathlib import Path

from PySide2.QtCore import Qt, Property, Signal, Slot, QObject

# Zynthian specific modules
from zyngine import zynthian_controller
from . import zynthian_qt_gui_base
from . import zynthian_gui_config
from . import zynthian_gui_controller

#------------------------------------------------------------------------------
# Zynthian Listing effects for active layer GUI Class
#------------------------------------------------------------------------------

class zynthian_gui_channel_external_setup(zynthian_qt_gui_base.ZynGui):

    def __init__(self, parent = None):
        super(zynthian_gui_channel_external_setup, self).__init__(parent)
        self.__zselector = [None, None, None, None]
        self.__zselector_ctrl = [None, None, None, None]
        self.__bigknob_value__ = 0
        self.__knob1_value__ = 0
        self.__knob2_value__ = 0
        self.__knob3_value__ = 0

    def show(self):
        self.set_selector()

    @Slot(None)
    def zyncoder_bigknob(self):
        if self.is_set_selector_running:
            logging.debug(f"Set selector in progress. Not setting value with encoder")
            return

        if self.__bigknob_value__ != self.__zselector[0].value:
            if self.zyngui.altButtonPressed:
                currentValue = self.zyngui.sketchpad.song.bpm
                self.zyngui.set_bpm(currentValue + self.__zselector[0].value - 50)
            else:
                self.__bigknob_value__ = self.__zselector[0].value
                self.bigKnobValueChanged.emit()
            self.set_selector()

    @Slot(None)
    def zyncoder_knob1(self):
        if self.is_set_selector_running:
            logging.debug(f"Set selector in progress. Not setting value with encoder")
            return

        if self.__knob1_value__ != self.__zselector[1].value:
            if self.zyngui.altButtonPressed:
                currentVolume = self.zyngui.get_volume()
                self.zyngui.set_volume(currentVolume + self.__zselector[1].value - 50)
            else:
                self.__knob1_value__ = self.__zselector[1].value
                self.knob1ValueChanged.emit()
            self.set_selector()

    @Slot(None)
    def zyncoder_knob2(self):
        if self.is_set_selector_running:
            logging.debug(f"Set selector in progress. Not setting value with encoder")
            return

        if self.__knob2_value__ != self.__zselector[2].value:
            if self.zyngui.altButtonPressed:
                currentValue = self.zyngui.get_global_fx1_amount()
                self.zyngui.set_global_fx1_amount(currentValue + self.__zselector[2].value - 50)
            else:
                self.__knob2_value__ = self.__zselector[2].value
                self.knob2ValueChanged.emit()
            self.set_selector()

    @Slot(None)
    def zyncoder_knob3(self):
        if self.is_set_selector_running:
            logging.debug(f"Set selector in progress. Not setting value with encoder")
            return

        if self.__knob3_value__ != self.__zselector[3].value:
            if self.zyngui.altButtonPressed:
                currentValue = self.zyngui.get_global_fx2_amount()
                self.zyngui.set_global_fx2_amount(currentValue + self.__zselector[3].value - 50)
            else:
                self.__knob3_value__ = self.__zselector[3].value
                self.knob3ValueChanged.emit()
            self.set_selector()

    def zyncoder_read(self):
        # Big knob is encoder 0
        if self.__zselector[0]:
            self.__zselector[0].read_zyncoder()
            self.zyncoder_bigknob()

        # Small knob 1
        if self.__zselector[1]:
            self.__zselector[1].read_zyncoder()
            self.zyncoder_knob1()

        # Small knob 2
        if self.__zselector[2]:
            self.__zselector[2].read_zyncoder()
            self.zyncoder_knob2()

        # Small knob 3
        if self.__zselector[3]:
            self.__zselector[3].read_zyncoder()
            self.zyncoder_knob3()

        return [0, 1, 2, 3]

    def configure_big_knob(self):
        try:
            if self.__zselector[0] is None:
                self.__zselector_ctrl[0] = zynthian_controller(None, 'channel_external_setup_bigknob', 'channel_external_setup_bigknob', {'midi_cc': 0, 'value': 0})
                self.__zselector[0] = zynthian_gui_controller(zynthian_gui_config.select_ctrl, self.__zselector_ctrl[0], self)
            self.__zselector[0].show()
            self.__zselector_ctrl[0].set_options({'symbol': 'channel_external_setup_bigknob', 'name': 'Channel External Setup Big Knob', 'short_name': 'Bigknob', 'midi_cc': 0, 'value_max': 100, 'value_min': 0, 'value': 50})
            self.__zselector[0].config(self.__zselector_ctrl[0])
            self.__zselector[0].custom_encoder_speed = 0
            if self.__zselector[0] is not None:
                self.__zselector[0].show()
        except:
            if self.__zselector[0] is not None:
                self.__zselector[0].hide()

    def configure_small_knob_1(self):
        if self.__zselector[1] is None:
            self.__zselector_ctrl[1] = zynthian_controller(None, 'channel_external_setup_knob1', 'channel_external_setup_knob1', {'midi_cc': 0, 'value': 0})
            self.__zselector[1] = zynthian_gui_controller(zynthian_gui_config.select_ctrl, self.__zselector_ctrl[1], self)
            self.__zselector[1].index = 0
        if self.zyngui.get_current_screen_id() is not None and self.zyngui.get_current_screen() == self:
            self.__zselector[1].show()
        else:
            if self.__zselector[1]:
                self.__zselector[1].hide()

        self.__zselector_ctrl[1].set_options({'symbol': 'channel_external_setup_knob1', 'name': 'Channel External Setup Knob 1', 'short_name': 'Knob1', 'midi_cc': 0, 'value_max': 100, 'value_min': 0, 'value': 50})
        self.__zselector[1].config(self.__zselector_ctrl[1])
        self.__zselector[1].custom_encoder_speed = 0

    def configure_small_knob_2(self):
        if self.__zselector[2] is None:
            self.__zselector_ctrl[2] = zynthian_controller(None, 'channel_external_setup_knob2', 'channel_external_setup_knob2', {'midi_cc': 0, 'value': 0})
            self.__zselector[2] = zynthian_gui_controller(zynthian_gui_config.select_ctrl, self.__zselector_ctrl[2], self)
            self.__zselector[2].index = 1
        if self.zyngui.get_current_screen_id() is not None and self.zyngui.get_current_screen() == self:
            self.__zselector[2].show()
        else:
            if self.__zselector[2]:
                self.__zselector[2].hide()

        self.__zselector_ctrl[2].set_options({'symbol': 'channel_external_setup_knob2', 'name': 'Channel External Setup Knob 2', 'short_name': 'Knob2', 'midi_cc': 0, 'value_max': 100, 'value_min': 0, 'value': 50})
        self.__zselector[2].config(self.__zselector_ctrl[2])
        self.__zselector[2].custom_encoder_speed = 0

    def configure_small_knob_3(self):
        if self.__zselector[3] is None:
            self.__zselector_ctrl[3] = zynthian_controller(None, 'channel_external_setup_knob3', 'channel_external_setup_knob3', {'midi_cc': 0, 'value': 0})
            self.__zselector[3] = zynthian_gui_controller(zynthian_gui_config.select_ctrl, self.__zselector_ctrl[3], self)
            self.__zselector[3].index = 2
        if self.zyngui.get_current_screen_id() is not None and self.zyngui.get_current_screen() == self:
            self.__zselector[3].show()
        else:
            if self.__zselector[3]:
                self.__zselector[3].hide()

        self.__zselector_ctrl[3].set_options({'symbol': 'channel_external_setup_knob3', 'name': 'Channel External Setup Knob 3', 'short_name': 'Knob3', 'midi_cc': 0, 'value_max': 100, 'value_min': 0, 'value': 50})
        self.__zselector[3].config(self.__zselector_ctrl[3])
        self.__zselector[3].custom_encoder_speed = 0

    @Slot(None)
    def set_selector(self, zs_hiden=False):
        if (self.zyngui.globalPopupOpened or self.zyngui.metronomeButtonPressed) or \
                (self.zyngui.get_current_screen_id() is not None and self.zyngui.get_current_screen() != self):
            if self.__zselector[0] is not None:
                self.__zselector[0].hide()
            if self.__zselector[1] is not None:
                self.__zselector[1].hide()
            if self.__zselector[2] is not None:
                self.__zselector[2].hide()
            if self.__zselector[3] is not None:
                self.__zselector[3].hide()

            return

        self.is_set_selector_running = True

        # Configure Big Knob
        self.configure_big_knob()

        # Configure small knob 1
        self.configure_small_knob_1()

        # Configure small knob 2
        self.configure_small_knob_2()

        # Configure small knob 3
        self.configure_small_knob_3()

        self.is_set_selector_running = False

    @Signal
    def bigKnobValueChanged(self):
        pass
    def get_bigKnobValue(self):
        return self.__bigknob_value__ - 50
    bigKnobValue = Property(int, get_bigKnobValue, notify=bigKnobValueChanged)

    @Signal
    def knob1ValueChanged(self):
        pass
    def get_knob1Value(self):
        return self.__knob1_value__ - 50
    knob1Value = Property(int, get_knob1Value, notify=knob1ValueChanged)

    @Signal
    def knob2ValueChanged(self):
        pass
    def get_knob2Value(self):
        return self.__knob2_value__ - 50
    knob2Value = Property(int, get_knob2Value, notify=knob2ValueChanged)

    @Signal
    def knob3ValueChanged(self):
        pass
    def get_knob3Value(self):
        return self.__knob3_value__ - 50
    knob3Value = Property(int, get_knob3Value, notify=knob3ValueChanged)

#------------------------------------------------------------------------------
