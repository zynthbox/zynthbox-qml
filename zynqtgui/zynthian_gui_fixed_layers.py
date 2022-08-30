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

# Zynthian specific modules
from . import zynthian_gui_layer
from . import zynthian_gui_selector

from zyncoder import *

from PySide2.QtCore import Qt, QObject, QTimer, Slot, Signal, Property

#------------------------------------------------------------------------------
# minimal controller proxy for the mixer: TODO: port all the controllers to this?
#------------------------------------------------------------------------------
class MixerControl(QObject):
    def __init__(self, parent=None):
        super(MixerControl, self).__init__(parent)
        self.__zctrl = None

    def set_zctrl(self, zctrl):
        if self.__zctrl == zctrl:
            return
        self.__zctrl = zctrl
        self.controllable_changed.emit()
        self.refresh()

    @Slot(None)
    def refresh(self):
        self.value_min_changed.emit()
        self.value_max_changed.emit()
        self.name_changed.emit()
        self.value_changed.emit()

    @Signal
    def controllable_changed(self):
        pass

    def get_controllable(self):
        return self.__zctrl is not None

    controllable = Property(bool, get_controllable, notify=controllable_changed)

    @Signal
    def value_changed(self):
        pass
    def get_value(self):
        if self.__zctrl == None:
            return 0
        return self.__zctrl.value
    def set_value(self, value):
        if self.__zctrl == None:
            return
        if self.__zctrl.value == value:
            return

        self.__zctrl.set_value(value, True)
        self.value_changed.emit()
    value = Property(float, get_value, set_value, notify = value_changed)

    @Signal
    def value_min_changed(self):
        pass
    def get_value_min(self):
        if self.__zctrl == None:
            return 0
        return self.__zctrl.value_min
    value_min = Property(float, get_value_min, notify = value_min_changed)

    @Signal
    def value_max_changed(self):
        pass
    def get_value_max(self):
        if self.__zctrl == None:
            return 0
        return self.__zctrl.value_max
    value_max = Property(float, get_value_max, notify = value_max_changed)

    @Signal
    def step_size_changed(self):
        pass
    def get_step_size(self):
        if self.__zctrl == None:
            return 0
        if self.__zctrl.is_integer or self.__zctrl.is_toggle:
            return 1
        else:
            return (self.__zctrl.value_max - self.__zctrl.value_min) / 100.0
    step_size = Property(float, get_step_size, notify = step_size_changed)

    @Signal
    def name_changed(self):
        pass
    def get_name(self):
        if self.__zctrl == None:
            return ""
        return self.__zctrl.name
    name = Property(str, get_name, notify = name_changed)

#------------------------------------------------------------------------------
# Zynthian Option Selection GUI Class
#------------------------------------------------------------------------------

class zynthian_gui_fixed_layers(zynthian_gui_selector):

    def __init__(self, parent = None):
        super(zynthian_gui_fixed_layers, self).__init__('Layer', parent)

        self.__layers_count = 15
        self.__start_midi_chan = 0
        self.__volume_ctrls = []

        self.__mixer_timer = QTimer()
        self.__mixer_timer.setInterval(250)
        self.__mixer_timer.setSingleShot(True)
        self.__mixer_timer.timeout.connect(self.__update_mixers)

        # Load engine config
        try:
            with open("/zynthian/zynthian-ui/config/engine_config.json", "r") as f:
                self.__engine_config__ = json.load(f)
        except Exception as e:
            logging.error(f"Error loading engine config from /zynthian/zynthian-ui/config/engine_config.json : {str(e)}")
            self.__engine_config__ = {}

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
                if len(self.__volume_ctrls) <= i - self.__start_midi_chan:
                    self.__volume_ctrls.append(MixerControl(self))
                else:
                    self.__volume_ctrls[i - self.__start_midi_chan].set_zctrl(None)

            if i < 15:
                metadata["midi_cloned"] = self.zyngui.screens['layer'].is_midi_cloned(i, i+1)
                metadata["midi_cloned_to"] = []
                for j in range(15):
                    if i != j and self.zyngui.screens['layer'].is_midi_cloned(i, j):
                        metadata["midi_cloned_to"].append(j)
            else:
                metadata["midi_cloned"] = False
                metadata["midi_cloned_to"] = []
            metadata["midi_channel"] = i
            metadata["octave_transpose"] = zyncoder.lib_zyncoder.get_midi_filter_octave_trans(i)
            metadata["halftone_transpose"] = zyncoder.lib_zyncoder.get_midi_filter_halftone_trans(i)
            metadata["note_low"] = zyncoder.lib_zyncoder.get_midi_filter_note_low(i)
            metadata["note_high"] = zyncoder.lib_zyncoder.get_midi_filter_note_high(i)

            self.list_metadata.append(metadata)


        self.special_layer_name_changed.emit()
        self.current_index_valid_changed.emit()
        self.zyngui.screens['layers_for_channel'].fill_list()
        self.__mixer_timer.start()
        super().fill_list()

    def __update_mixers(self):
        for i in range(self.__start_midi_chan, self.__start_midi_chan + self.__layers_count):
            if i in self.zyngui.screens['layer'].layer_midi_map:
                layer = self.zyngui.screens['layer'].layer_midi_map[i]
                # Find volume control as per self.__engine_config__
                for name in layer.controllers_dict:
                    # Check if engine has specific mapping of volume controller name
                    # otherwise use global `*` controller mapping name from self.__engine_config__
                    if layer.engine.nickname in self.__engine_config__ and \
                       "volumeControl" in self.__engine_config__[layer.engine.nickname] and \
                       name in self.__engine_config__[layer.engine.nickname]['volumeControl']:
                        # Check if config has engine specific volume controller name
                        logging.debug(f"### VOLUME : Found volume control for engine '{layer.engine.nickname}'")
                        ctrl = layer.controllers_dict[name]
                    elif "default" in self.__engine_config__ and \
                         "volumeControl" in self.__engine_config__['default'] and \
                         name in self.__engine_config__['default']['volumeControl']:
                        # Check if config has global volume controller name
                        logging.debug(f"### VOLUME : Volume control for engine '{layer.engine.nickname}' not found. Using default config")
                        ctrl = layer.controllers_dict[name]
                    elif name in ['volume', 'Volume']:
                        logging.debug(f"### VOLUME : Default config not found. Using fallback config for '{layer.engine.nickname}'")
                        # Fallback when config does not have global volume controller name
                        ctrl = layer.controllers_dict[name]
                    else:
                        logging.debug(f"### VOLUME : Volume Control for engine '{layer.engine.nickname}' not found. Skipping")

                if len(self.__volume_ctrls) <= i - self.__start_midi_chan:
                    gctrl = MixerControl(self)
                    gctrl.set_zctrl(ctrl)
                    self.__volume_ctrls.append(gctrl)
                else:
                    self.__volume_ctrls[i - self.__start_midi_chan].set_zctrl(ctrl)
        self.volume_controls_changed.emit()

    def select(self, index=None):
        super().select(index)
        self.active_midi_channel_changed.emit()
        self.set_select_path()


    def select_action(self, i, t='S'):
        if i < 0 or i >= len(self.list_data):
            return

        self.zyngui.screens['bank'].set_show_top_sounds(False)

        self.select(i)

        chan = self.list_data[i][1]
        self.current_index_valid_changed.emit()

        logging.error(chan)
        if chan < 0:
            return

        if chan in self.zyngui.screens['layer'].layer_midi_map:
            self.zyngui.screens['layer'].current_index = self.zyngui.screens['layer'].root_layers.index(self.zyngui.screens['layer'].layer_midi_map[chan])

        self.zyngui.screens['layer'].activate_midichan_layer(chan)

        if t=='B' and chan in self.zyngui.screens['layer'].layer_midi_map:
            self.zyngui.screens['layer'].layer_options()

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
        if self.zyngui.curlayer:
            midi_chan = self.zyngui.curlayer.midi_chan
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
        self.zyngui.show_confirm("Do you really want to remove all sounds?", self.clear_visible_range)

    def clear_visible_range(self, params=None):
        for chan in range(self.__start_midi_chan, self.__start_midi_chan + self.__layers_count - 1):
            self.zyngui.screens['layer'].remove_midichan_layer(chan)
        self.zyngui.screens['layer'].reset_channel_status_range(self.__start_midi_chan, self.__start_midi_chan + self.__layers_count - 1)

    @Slot(int, result=bool)
    def index_is_valid(self, index):
        # logging.error("index {} list_data {}".format(index, len(self.list_data)))
        # logging.error("midichan: {}".format(self.list_data[index][1]))
        midi_chan = self.list_data[index][1]

        if midi_chan < 0:
            return False

        return midi_chan in self.zyngui.screens['layer'].layer_midi_map

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

    active_midi_channel_changed = Signal()
    def get_active_midi_channel(self):
        if self.index >=0 and self.index < len(self.list_data):
            return self.list_data[self.index][1]
        else:
            return -1
    active_midi_channel = Property(int, get_active_midi_channel, notify = active_midi_channel_changed)

    def get_volume_controls(self):
        return self.__volume_ctrls
    @Signal
    def volume_controls_changed(self):
        pass
    volume_controls = Property('QVariantList', get_volume_controls, notify = volume_controls_changed)

    def set_select_path(self):
        self.select_path = "Layers"
        self.select_path_element = str(self.list_data[self.index][1] + 1)
        super().set_select_path()

#------------------------------------------------------------------------------
