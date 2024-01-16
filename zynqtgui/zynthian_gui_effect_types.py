#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian GUI Option Selector Class
# 
# Copyright (C) 2021 Marco Martin <mart@kde.org>
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
from . import zynthian_gui_engine

#------------------------------------------------------------------------------
# Zynthian Option Selection GUI Class
#------------------------------------------------------------------------------

class zynthian_gui_effect_types(zynthian_gui_engine):

    def __init__(self, parent = None):
        super(zynthian_gui_effect_types, self).__init__(parent)

        self.selector_caption = "FX Type"
        self.midi_mode = False
        self.effects_screen = "layer_effects"
        self.effect_chooser_screen = "layer_effect_chooser"

        #if self.zynqtgui.curlayer:
            #self.set_fxchain_mode(self.zynqtgui.curlayer.midi_chan)
        self.only_categories = True


    def show(self):
        if self.midi_mode:
            self.effects_screen = "layer_midi_effects"
            self.effect_chooser_screen = "layer_midi_effect_chooser"
        else:
            self.effects_screen = "layer_effects"
            self.effect_chooser_screen = "layer_effect_chooser"
        if self.zynqtgui.curlayer:
            if self.midi_mode:
                self.set_midichain_mode(self.zynqtgui.curlayer.midi_chan)
            else:
                self.set_fxchain_mode(self.zynqtgui.curlayer.midi_chan)
            self.reset_index = False
        super().show()

        try:
            if self.zynqtgui.screens[self.effects_screen].fx_layer != None and self.zynqtgui.get_current_screen_id() != 'effect_types':
                cat = self.engine_info[self.zynqtgui.screens[self.effects_screen].fx_layer.engine.get_path(self.zynqtgui.screens[self.effects_screen].fx_layer)][3]
                for i, item in enumerate(self.list_data):
                    if item[2] == cat:
                        self.activate_index(i)
                        return
            if self.zynqtgui.screens[self.effect_chooser_screen].single_category == "    ":
                self.zynqtgui.screens[self.effect_chooser_screen].single_category == self.list_data[0][0]
        except Exception as e:
            pass #logging.exception(e)
        self.zynqtgui.screens[self.effect_chooser_screen].show()


    def select_action(self, i, t='S'):
        if i is not None and self.list_data[i][0]:
            self.zynqtgui.screens[self.effect_chooser_screen].single_category = self.list_data[i][0]
            self.zynqtgui.screens[self.effect_chooser_screen].show()
            #If first column is not pointing to a layer, preselect slot 0 of effect_chooser_screen
        self.set_select_path()


    def back_action(self):
        return "sketchpad"

    def next_action(self):
        return self.effect_chooser_screen


    def index_supports_immediate_activation(self, index=None):
        return True


    def set_select_path(self):
        self.select_path = ''
        self.select_path_element = ''

        try:
            if self.zynqtgui.screens[self.effects_screen].fx_layer != None and self.zynqtgui.curlayer != None:
                self.select_path_element = self.engine_info[self.zynqtgui.screens[self.effects_screen].fx_layer.engine.get_path(self.zynqtgui.screens[self.effects_screen].fx_layer)][3]
                self.select_path = self.zynqtgui.curlayer.get_basepath() + " Audio-FX > " + str(self.select_path_element)
        except Exception as e:
            pass #logging.exception(e)
        self.selector_path_changed.emit()
        self.selector_path_element_changed.emit()

#------------------------------------------------------------------------------
