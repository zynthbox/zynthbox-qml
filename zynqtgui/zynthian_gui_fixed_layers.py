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
import json
import sys
import logging
import math

import numpy as np

# Zynthian specific modules
from . import zynthian_gui_layer
from . import zynthian_gui_selector

from zyncoder import *

from PySide2.QtCore import Qt, QObject, QTimer, Slot, Signal, Property

from .zynthian_gui_multi_controller import MultiController


#------------------------------------------------------------------------------
# Zynthian Option Selection GUI Class
#------------------------------------------------------------------------------

class zynthian_gui_fixed_layers(zynthian_gui_selector):

    def __init__(self, parent = None):
        super(zynthian_gui_fixed_layers, self).__init__('Layer', parent)

        self.__layers_count = 15
        self.__start_midi_chan = 0

        # List of LayerVolumeController (one per midi channel)
        self.__volume_controllers: list[MultiController] = []
        for i in range(self.__start_midi_chan, self.__start_midi_chan + self.__layers_count):
            self.__volume_controllers.append(MultiController(self))

        self.__mixer_timer = QTimer()
        self.__mixer_timer.setInterval(250)
        self.__mixer_timer.setSingleShot(True)
        self.__mixer_timer.timeout.connect(self.update_mixers)

        # Load engine config
        try:
            with open("/zynthian/zynthbox-qml/config/engine_config.json", "r") as f:
                self.__engine_config = json.load(f)
        except Exception as e:
            logging.error(f"Error loading engine config from /zynthian/zynthbox-qml/config/engine_config.json : {str(e)}")
            self.__engine_config = {}

        self.show()


    def fill_list(self):
        self.list_data=[]
        self.list_metadata=[]

        for i in range(self.__start_midi_chan, self.__start_midi_chan + self.__layers_count):
            metadata = {}
            if i in self.zynqtgui.screens['layer'].layer_midi_map:
                layer = self.zynqtgui.screens['layer'].layer_midi_map[i]
                if layer.preset_name is None:
                    self.list_data.append((str(i+1),i,"{}".format(layer.engine.name.replace("Jalv/", "").replace("Jucy/", ""))))
                else:
                    self.list_data.append((str(i+1),i,"{} > {}".format(layer.engine.name.replace("Jalv/", "").replace("Jucy/", ""), layer.preset_name)))                    
                metadata["layer"] = layer

                # effects_label = ""
                # first = True
                # for sl in self.zynqtgui.screens['layer'].get_fxchain_layers(layer):
                #     sl0 = None
                #     bullet = ""
                #     if sl.is_parallel_audio_routed(sl0):
                #         bullet = " || "
                #     else:
                #         bullet = " -> "
                #     if not first:
                #         effects_label += bullet + sl.engine.get_path(sl).replace("JV/","")
                #     first = False
                #     sl0 = sl
                # first = True
                # for sl in self.zynqtgui.screens['layer'].get_midichain_layers(layer):
                #     sl0 = None
                #     bullet = ""
                #     if sl.is_parallel_midi_routed(sl0):
                #         bullet = " || "
                #     else:
                #         bullet = " -> "
                #     if not first:
                #         effects_label += bullet + sl.engine.get_path(sl).replace("JV/","") + "(m)"
                #     first = False
                #     sl0 = sl
                # metadata["effects_label"] = effects_label
                metadata["effects_label"] = ""
            else:
                self.list_data.append((str(i+1),i, "-"))
                metadata["effects_label"] = ""
                metadata["layer"] = None

            if -1 < i and i < 15:
                # metadata["midi_cloned"] = self.zynqtgui.screens['layer'].is_midi_cloned(i, i+1)
                # metadata["midi_cloned_to"] = []
                # for j in range(15):
                #     if i != j and self.zynqtgui.screens['layer'].is_midi_cloned(i, j):
                #         metadata["midi_cloned_to"].append(j)
                metadata["midi_cloned"] = False
                metadata["midi_cloned_to"] = []
                metadata["octave_transpose"] = zyncoder.lib_zyncoder.get_midi_filter_octave_trans(i)
                metadata["halftone_transpose"] = zyncoder.lib_zyncoder.get_midi_filter_halftone_trans(i)
                metadata["note_low"] = zyncoder.lib_zyncoder.get_midi_filter_note_low(i)
                metadata["note_high"] = zyncoder.lib_zyncoder.get_midi_filter_note_high(i)
            else:
                metadata["midi_cloned"] = False
                metadata["midi_cloned_to"] = []
                metadata["octave_transpose"] = 0
                metadata["halftone_transpose"] = 0
                metadata["note_low"] = 0
                metadata["note_high"] = 127
            metadata["midi_channel"] = i

            self.list_metadata.append(metadata)


        self.special_layer_name_changed.emit()
        self.current_index_valid_changed.emit()
        self.zynqtgui.screens['layers_for_channel'].fill_list()
        self.__mixer_timer.start()
        super().fill_list()

    def update_mixers(self):
        for i in range(self.__start_midi_chan, self.__start_midi_chan + self.__layers_count):
            if i in self.zynqtgui.screens['layer'].layer_midi_map:
                self.__volume_controllers[i - self.__start_midi_chan].clear_controls()

                layer = self.zynqtgui.screens['layer'].layer_midi_map[i]
                synth_controllers_dict = layer.controllers_dict

                # Check if engine config contains list of custom volume controllers and use them
                # Otherwise check for default volume controllers
                if layer.engine.nickname in self.__engine_config and \
                        "volumeControls" in self.__engine_config[layer.engine.nickname]:
                    volume_controls = self.__engine_config[layer.engine.nickname]["volumeControls"]
                    for ctrl in volume_controls:
                        if ctrl in synth_controllers_dict:
                            self.__volume_controllers[i - self.__start_midi_chan].add_control(synth_controllers_dict[ctrl])
                elif "volume" in synth_controllers_dict:
                    self.__volume_controllers[i - self.__start_midi_chan].add_control(synth_controllers_dict["volume"])
                elif "Volume" in synth_controllers_dict:
                    self.__volume_controllers[i - self.__start_midi_chan].add_control(synth_controllers_dict["Volume"])

        self.volumeControllersChanged.emit()

    def select(self, index=None):
        super().select(index)
        self.active_midi_channel_changed.emit()
        self.set_select_path()


    def select_action(self, i, t='S'):
        if i < 0 or i >= len(self.list_data):
            return

        self.zynqtgui.screens['bank'].set_show_top_sounds(False)

        self.select(i)

        chan = self.list_data[i][1]
        self.current_index_valid_changed.emit()

        logging.error(chan)
        if chan < 0:
            return

        if chan in self.zynqtgui.screens['layer'].layer_midi_map:
            self.zynqtgui.screens['layer'].current_index = self.zynqtgui.screens['layer'].root_layers.index(self.zynqtgui.screens['layer'].layer_midi_map[chan])

        self.zynqtgui.screens['layer'].activate_midichan_layer(chan)

        # Disabling the layer_options page here - it's essentially not usable for our needs any longer (an old style selector page for menu purposes where we use action pickers everywhere else for that)
        # if t=='B' and chan in self.zynqtgui.screens['layer'].layer_midi_map:
            # self.zynqtgui.screens['layer'].layer_options()

        self.fill_list()


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
        if self.zynqtgui.curlayer:
            midi_chan = self.zynqtgui.curlayer.midi_chan
        else:
            midi_chan = zyncoder.lib_zyncoder.get_midi_active_chan()

        if midi_chan < self.__start_midi_chan or midi_chan >= self.__start_midi_chan + self.__layers_count:
            return
        for i, item in enumerate(self.list_data):
            if midi_chan == item[1]:
                self.current_index = i
                return


    @Slot(int, result=int)
    def index_to_midi(self, index):
        if index < 0 or index >= len(self.list_data):
            return -1;
        return self.list_data[index][1]


    @Slot(None)
    def ask_clear_visible_range(self):
        self.zynqtgui.show_confirm("Do you really want to remove all sounds?", self.clear_visible_range)

    def clear_visible_range(self, params=None):
        for chan in range(self.__start_midi_chan, self.__start_midi_chan + self.__layers_count - 1):
            self.zynqtgui.screens['layer'].remove_midichan_layer(chan)
        self.zynqtgui.screens['layer'].reset_channel_status_range(self.__start_midi_chan, self.__start_midi_chan + self.__layers_count - 1)

    @Slot(int, result=bool)
    def index_is_valid(self, index):
        # logging.error("index {} list_data {}".format(index, len(self.list_data)))
        # logging.error("midichan: {}".format(self.list_data[index][1]))
        midi_chan = self.list_data[index][1]

        if midi_chan < 0:
            return False

        return midi_chan in self.zynqtgui.screens['layer'].layer_midi_map

    @Signal
    def current_index_valid_changed(self):
        pass

    def get_current_index_valid(self):
        return self.index_is_valid(self.current_index)

    current_index_valid = Property(bool, get_current_index_valid, notify = current_index_valid_changed)

    @Signal
    def special_layer_name_changed(self):
        pass


    def get_special_layer_name(self):
        layer_name = "T-RACK: "
        found = False
        for chan in range(5, 10):
            if chan in self.zynqtgui.screens['layer'].layer_midi_map:
                if found:
                    layer_name += ", {}".format(self.zynqtgui.screens['layer'].layer_midi_map[chan].preset_name)
                else:
                    layer_name += "{}".format(self.zynqtgui.screens['layer'].layer_midi_map[chan].preset_name)
                    found = True
                #layer_name += self.zynqtgui.screens['layer'].layer_midi_map[chan].preset_name
        if not found:
            layer_name += "None"
        return layer_name
    special_layer_name = Property(str, get_special_layer_name, notify = special_layer_name_changed)

    def back_action(self):
        return 'sketchpad'

    def next_action(self):
        return 'bank'

    active_midi_channel_changed = Signal()
    def get_active_midi_channel(self):
        if self.index >=0 and self.index < len(self.list_data):
            return self.list_data[self.index][1]
        else:
            return -1
    active_midi_channel = Property(int, get_active_midi_channel, notify = active_midi_channel_changed)

    def set_select_path(self):
        self.select_path = "Layers"
        if len(self.list_data) > 0:
            self.select_path_element = str(self.list_data[self.index][1] + 1)
        super().set_select_path()

    ### Property volumeControllers
    def get_volumeControllers(self):
        return self.__volume_controllers

    volumeControllersChanged = Signal()

    volumeControllers = Property("QVariantList", get_volumeControllers, notify=volumeControllersChanged)
    ### END Property volumeControllers

#------------------------------------------------------------------------------
