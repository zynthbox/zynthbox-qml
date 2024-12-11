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

from PySide2.QtCore import QTimer
# Zynthian specific modules
from . import zynthian_gui_engine

#------------------------------------------------------------------------------
# Zynthian Option Selection GUI Class
#------------------------------------------------------------------------------

class zynthian_gui_layer_effect_chooser(zynthian_gui_engine):

    def __init__(self, parent = None):
        super(zynthian_gui_layer_effect_chooser, self).__init__(parent)

        self.selector_caption = "FX"
        self.layer_chain_parallel = False
        self.midi_mode = False
        self.effects_screen = "layer_effects"
        self.effects_types_screen = "effect_types"

        self.single_category = "    " # Hack to get an empty list
        if self.zynqtgui.curlayer:
            self.set_fxchain_mode(self.zynqtgui.curlayer.midi_chan)


    def show(self):
        if self.midi_mode:
            self.effects_screen = "layer_midi_effects"
            self.effects_types_screen = "midi_effect_types"
        else:
            self.effects_screen = "layer_effects"
            self.effects_types_screen = "effect_types"

        if self.zynqtgui.curlayer:
            if self.midi_mode:
                self.set_midichain_mode(self.zynqtgui.curlayer.midi_chan)
            else:
                self.set_fxchain_mode(self.zynqtgui.curlayer.midi_chan)
            self.reset_index = False

        super().show()

        if self.zynqtgui.screens[self.effects_screen].fx_layer != None:
            for i, item in enumerate(self.list_data):
                try:
                    if item[0] == self.zynqtgui.screens[self.effects_screen].fx_layer.engine.get_path(self.zynqtgui.screens[self.effects_screen].fx_layer):
                        self.select(i)
                        return
                except Exception as e:
                    pass #logging.exception(e)

                self.select(0)
        else:
            self.select(0)

    def replaceFxConfirmed(self, i):
        def task():
            try:
                self.zynqtgui.screens['layer'].layer_chain_parallel = self.layer_chain_parallel
                self.zynqtgui.screens['layer'].add_layer_engine(engine, None, False)
                self.zynqtgui.screens["fixed_layers"].fill_list()
                self.zynqtgui.screens['snapshot'].save_last_state_snapshot()
            except Exception as e:
                logging.exception(e)
            self.zynqtgui.currentTaskMessage = ""
            QTimer.singleShot(2000, self.zynqtgui.end_long_task)
        engine = self.list_data[i][0]
        self.zynqtgui.do_long_task(task, f"Adding FX {engine}")

    def select_action(self, i, t='S'):
        if i is not None and i >= 0 and i < len(self.list_data) and self.list_data[i][0]:
            if self.zynqtgui.curlayer is None:
                self.replaceFxConfirmed(i)
            else:
                self.zynqtgui.show_confirm(f"This will replace the effect {self.zynqtgui.curlayer.engine.name} with {self.list_data[i][0]}. Are you sure?", self.replaceFxConfirmed, i)

    def back_action(self):
        return "sketchpad"


    def set_select_path(self):
        self.select_path = ''
        try:
            if self.zynqtgui.screens[self.effects_screen].fx_layer != None:
                self.select_path = self.engine_info[self.zynqtgui.screens[self.effects_screen].fx_layer.engine.get_path(self.zynqtgui.screens[self.effects_screen].fx_layer)][0]
        except Exception as e:
            pass #logging.exception(e)
        self.selector_path_changed.emit()
        self.selector_path_element_changed.emit()

#------------------------------------------------------------------------------
