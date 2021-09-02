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
from . import zynthian_gui_layer
from . import zynthian_gui_selector

#------------------------------------------------------------------------------
# Zynthian Option Selection GUI Class
#------------------------------------------------------------------------------

class zynthian_gui_fixed_layers(zynthian_gui_selector):

    def __init__(self, parent = None):
        super(zynthian_gui_fixed_layers, self).__init__('Layer', parent)

        self.__fixed_layers_count = 5
        self.__extra_layers_count = 5
        self.show()


    def fill_list(self):
        self.list_data=[]

        for i in range(self.__fixed_layers_count): #FIXME
            if i in self.zyngui.screens['layer'].layer_midi_map:
                layer = self.zyngui.screens['layer'].layer_midi_map[i]
                if layer.preset_name is None:
                    self.list_data.append((str(i+1),i,"{} - {}".format(i + 1, layer.engine.name.replace("Jalv/", ""))))
                else:
                    self.list_data.append((str(i+1),i,"{} - {} > {}".format(i + 1, layer.engine.name.replace("Jalv/", ""), layer.preset_name)))
            else:
                self.list_data.append((str(i+1),i, "{} - -".format(i+1)))

        self.list_data.append((None,-1, "")) # Separator

        for i in range(self.__fixed_layers_count, self.__fixed_layers_count + self.__extra_layers_count): #FIXME
            if i in self.zyngui.screens['layer'].layer_midi_map:
                layer = self.zyngui.screens['layer'].layer_midi_map[i]
                if layer.preset_name is None:
                    self.list_data.append((str(i+1),i,"{} - {}".format(i + 1, layer.engine.name.replace("Jalv/", ""))))
                else:
                    self.list_data.append((str(i+1),i,"{} - {} > {}".format(i + 1, layer.engine.name.replace("Jalv/", ""), layer.preset_name)))
            else:
                self.list_data.append((str(i+1),i, "{} - -".format(i+1)))

        super().fill_list()


    def select_action(self, i, t='S'):
        self.index = i
        chan = self.list_data[i][1]

        if chan < 0:
            return

        if chan in self.zyngui.screens['layer'].layer_midi_map:
            self.zyngui.screens['layer'].current_index = self.zyngui.screens['layer'].root_layers.index(self.zyngui.screens['layer'].layer_midi_map[chan])

        self.zyngui.screens['layer'].activate_midichan_layer(chan)

        if t=='B':
            self.zyngui.screens['layer'].layer_options()


    def sync_index_from_curlayer(self):
        if not self.zyngui.curlayer:
            return
        if self.zyngui.curlayer.midi_chan < self.__fixed_layers_count:
            self.current_index = self.zyngui.curlayer.midi_chan
        else:
            self.current_index = self.zyngui.curlayer.midi_chan + 1


    #special_layer_name = Property(str, get_engine_nick, notify = engine_nick_changed)

    def back_action(self):
        return 'main'

    def next_action(self):
        return 'bank'


    def index_supports_immediate_activation(self, index=None):
        return False

    def set_select_path(self):
        self.select_path = "Layers"
        #self.select_path_element = str(zyngui.curlayer.engine.name)
        if self.zyngui.curlayer is None:
            self.select_path_element = "Layers"
        else:
            self.select_path_element = str(self.zyngui.curlayer.midi_chan + 1)
        super().set_select_path()

#------------------------------------------------------------------------------
