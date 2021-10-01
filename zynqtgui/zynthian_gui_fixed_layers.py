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
import math

# Zynthian specific modules
from . import zynthian_gui_layer
from . import zynthian_gui_selector

from zyncoder import *

from PySide2.QtCore import Qt, QObject, Slot, Signal, Property

#------------------------------------------------------------------------------
# Zynthian Option Selection GUI Class
#------------------------------------------------------------------------------

class zynthian_gui_fixed_layers(zynthian_gui_selector):

    def __init__(self, parent = None):
        super(zynthian_gui_fixed_layers, self).__init__('Layer', parent)

        self.__layers_count = 5
        self.__start_midi_chan = 0
        self.show()


    def fill_list(self):
        self.list_data=[]
        self.list_metadata=[]

        for i in range(self.__start_midi_chan, self.__start_midi_chan + self.__layers_count):
            metadata = {}
            if i in self.zyngui.screens['layer'].layer_midi_map:
                layer = self.zyngui.screens['layer'].layer_midi_map[i]
                if layer.preset_name is None:
                    self.list_data.append((str(i+1),i,"{}".format(layer.engine.name.replace("Jalv/", ""))))
                else:
                    self.list_data.append((str(i+1),i,"{} > {}".format(layer.engine.name.replace("Jalv/", ""), layer.preset_name)))
                effects_label = ""
                first = True
                for sl in self.zyngui.screens['layer'].get_fxchain_layers(layer):
                    sl0 = None
                    bullet = ""
                    if sl.is_parallel_audio_routed(sl0):
                        bullet = " || "
                    else:
                        bullet = " -> "
                    if not first:
                        effects_label += bullet + sl.engine.get_path(sl).replace("JV/","")
                    first = False
                    sl0 = sl
                first = True
                for sl in self.zyngui.screens['layer'].get_midichain_layers(layer):
                    sl0 = None
                    bullet = ""
                    if sl.is_parallel_midi_routed(sl0):
                        bullet = " || "
                    else:
                        bullet = " -> "
                    if not first:
                        effects_label += bullet + sl.engine.get_path(sl).replace("JV/","") + "(m)"
                    first = False
                    sl0 = sl
                metadata["effects_label"] = effects_label

            else:
                self.list_data.append((str(i+1),i, "-"))
                metadata["effects_label"] = ""

            if i < 15:
                metadata["midi_cloned"] = self.zyngui.screens['layer'].is_midi_cloned(i, i+1)
            else:
                metadata["midi_cloned"] = False
            metadata["midi_channel"] = i
            metadata["octave_transpose"] = zyncoder.lib_zyncoder.get_midi_filter_octave_trans(i)
            metadata["halftone_transpose"] = zyncoder.lib_zyncoder.get_midi_filter_halftone_trans(i)
            metadata["note_low"] = zyncoder.lib_zyncoder.get_midi_filter_note_low(i)
            metadata["note_high"] = zyncoder.lib_zyncoder.get_midi_filter_note_high(i)
            self.list_metadata.append(metadata)

        self.special_layer_name_changed.emit()
        self.current_index_valid_changed.emit()
        super().fill_list()


    def select(self, index=None):
        super().select(index)
        self.set_select_path()


    def select_action(self, i, t='S'):
        if i < 0 or i >= len(self.list_data):
            return

        self.zyngui.screens['bank'].set_show_top_sounds(False)

        self.select(i)

        chan = self.list_data[i][1]
        self.current_index_valid_changed.emit()

        if chan < 0:
            return

        if chan in self.zyngui.screens['layer'].layer_midi_map:
            self.zyngui.screens['layer'].current_index = self.zyngui.screens['layer'].root_layers.index(self.zyngui.screens['layer'].layer_midi_map[chan])

        self.zyngui.screens['layer'].activate_midichan_layer(chan)

        if t=='B':
            self.zyngui.screens['layer'].layer_options()


    @Signal
    def start_midi_chan_changed(self):
        pass

    def set_start_midi_chan(self, chan):
        if self.__start_midi_chan == chan:
            return
        self.__start_midi_chan = chan
        self.fill_list()
        self.start_midi_chan_changed.emit()

    def get_start_midi_chan(self):
        return self.__start_midi_chan

    start_midi_chan = Property(int, get_start_midi_chan, set_start_midi_chan, notify = start_midi_chan_changed)

    @Signal
    def layers_count_changed(self):
        pass

    def set_layers_count(self, count):
        if self.__layers_count == count:
            return
        self.__layers_count = count
        self.fill_list()
        self.layers_count_changed.emit()

    def get_layers_count(self):
        return self.__layers_count

    layers_count = Property(int, get_layers_count, set_layers_count, notify = layers_count_changed)


    def index_supports_immediate_activation(self, index=None):
        if index is None:
            return False
        chan = self.list_data[index][1]
        if chan < 0:
            return False
        return True


    def sync_index_from_curlayer(self):
        midi_chan = -1
        if self.zyngui.curlayer:
            midi_chan = self.zyngui.curlayer.midi_chan
        else:
            midi_chan = zyncoder.lib_zyncoder.get_midi_active_chan()

        if midi_chan < self.__start_midi_chan or midi_chan >= self.__start_midi_chan + self.__layers_count:
            self.set_start_midi_chan(math.floor(midi_chan / 5) * 5)
        for i, item in enumerate(self.list_data):
            if midi_chan == item[1]:
                self.current_index = i
                return


    @Slot(int, result=int)
    def index_to_midi(self, index):
        if index < 0 or index >= len(self.list_data):
            return -1;
        return self.list_data[index][1]

    @Signal
    def current_index_valid_changed(self):
        pass

    def get_current_index_valid(self):
        logging.error("index {} list_data {}".format(self.index, len(self.list_data)))
        logging.error("midichan: {}".format(self.list_data[self.index][1]))
        midi_chan = self.list_data[self.index][1]

        if midi_chan < 0:
            return False

        return midi_chan in self.zyngui.screens['layer'].layer_midi_map

    current_index_valid = Property(bool, get_current_index_valid, notify = current_index_valid_changed)

    @Signal
    def special_layer_name_changed(self):
        pass


    def get_special_layer_name(self):
        layer_name = "T-RACK: "
        found = False
        for chan in range(5, 10):
            if chan in self.zyngui.screens['layer'].layer_midi_map:
                if found:
                    layer_name += ", {}".format(self.zyngui.screens['layer'].layer_midi_map[chan].preset_name)
                else:
                    layer_name += "{}".format(self.zyngui.screens['layer'].layer_midi_map[chan].preset_name)
                    found = True
                #layer_name += self.zyngui.screens['layer'].layer_midi_map[chan].preset_name
        if not found:
            layer_name += "None"
        return layer_name
    special_layer_name = Property(str, get_special_layer_name, notify = special_layer_name_changed)

    def back_action(self):
        return 'session_dashboard'

    def next_action(self):
        return 'bank'


    def set_select_path(self):
        self.select_path = "Layers"
        self.select_path_element = str(self.list_data[self.index][1] + 1)
        super().set_select_path()

#------------------------------------------------------------------------------
