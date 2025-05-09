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
from zyncoder import *
from . import zynthian_gui_selector

from PySide2.QtCore import QMetaObject, Qt, QObject, Slot, Signal, Property

#------------------------------------------------------------------------------
# basically a proxy model to zynthian_fixed:channels
#------------------------------------------------------------------------------

class zynthian_gui_layers_for_channel(zynthian_gui_selector):

    def __init__(self, parent = None):
        super(zynthian_gui_layers_for_channel, self).__init__('ChannelLayers', parent)
        self.__total_chains = 5
        self.__volume_controllers = []
        self.zynqtgui.screens['layer'].layer_deleted.connect(self.update_channel_sounds)

    def fill_list(self):
        try:
            self.list_data = []
            self.list_metadata = []
            self.__volume_controllers = []
            song = self.zynqtgui.screens['sketchpad'].song

            if song is not None:
                selected_channel = song.channelsModel.getChannel(self.zynqtgui.sketchpad.selectedTrackId)
                chain = selected_channel.get_chained_sounds()
                empty_channels_needed = 0
                used_empty_channels = []

                for chan in chain:
                    for i, element in enumerate(self.zynqtgui.screens['fixed_layers'].list_data):
                        if chan < 0 and not self.zynqtgui.screens['fixed_layers'].index_is_valid(i) and element[1] not in used_empty_channels:
                            self.list_data.append(element)
                            self.list_metadata.append(self.zynqtgui.screens['fixed_layers'].list_metadata[i])
                            self.__volume_controllers.append(self.zynqtgui.screens['fixed_layers'].volumeControllers[i])
                            used_empty_channels.append(element[1])
                            break
                        elif element[1] == chan:
                            self.list_data.append(element)
                            self.list_metadata.append(self.zynqtgui.screens['fixed_layers'].list_metadata[i])
                            self.__volume_controllers.append(self.zynqtgui.screens['fixed_layers'].volumeControllers[i])
                            break

                #duplicate_chans = []
                #for chan in chain:
                    #if chan < 0 or chan in duplicate_chans: #FIXEME: workaround form duplicate entries in chans
                        #empty_channels_needed += 1
                    #duplicate_chans.append(chan)
                #used_empty_channels = 0
                #for i, element in enumerate(self.zynqtgui.screens['fixed_layers'].list_data):
                    #if element[1] in chain:
                        #self.list_data.append(element)
                        #self.list_metadata.append(self.zynqtgui.screens['fixed_layers'].list_metadata[i])
                        #self.__volume_controllers.append(self.zynqtgui.screens['fixed_layers'].volumeControllers[i])
                    #elif used_empty_channels < empty_channels_needed and len(self.list_data) < self.__total_chains and  not self.zynqtgui.screens['fixed_layers'].index_is_valid(i):
                        #self.list_data.append(element)
                        #self.list_metadata.append(self.zynqtgui.screens['fixed_layers'].list_metadata[i])
                        #self.__volume_controllers.append(self.zynqtgui.screens['fixed_layers'].volumeControllers[i])
                        #used_empty_channels += 1
                self.volumeControllersChanged.emit()
                # self.zynqtgui.screens["sketchpad"].connect_control_objects()
        except Exception as e:
            logging.error(e)
            pass
        super().fill_list()

    def back_action(self):
        return "sketchpad"

    def layer_selection_consistency_check(self):
        if self.zynqtgui.screens['layer'].is_channel_valid(self.current_index):
            return

        for i, element in enumerate(self.list_data):
            if self.zynqtgui.screens['layer'].is_channel_valid(element[1]):
                self.select_action(i)
                return
        self.select_action(0)

    def index_supports_immediate_activation(self, index=None):
        if index is None:
            return False
        chan = self.list_data[index][1]
        if chan < 0:
            return False
        return True

    def sync_index_from_curlayer(self):
        # midi_chan = -1
        # if self.zynqtgui.curlayer:
        #     midi_chan = self.zynqtgui.curlayer.midi_chan
        # else:
        #     midi_chan = zyncoder.lib_zyncoder.get_midi_active_chan()

        # for i, item in enumerate(self.list_data):
        #     logging.debug("sync_index_from_curlayer of layers_for_channel {} {}".format(midi_chan, item[1]))
        #     if midi_chan == item[1]:
        #         self.current_index = i
        #         return
        song = self.zynqtgui.screens['sketchpad'].song
        if song is not None:
            selected_channel = song.channelsModel.getChannel(self.zynqtgui.sketchpad.selectedTrackId)
            if selected_channel.selectedSlot.className == "TracksBar_synthslot":
                self.current_index = selected_channel.selectedSlot.value

    def update_channel_sounds(self):
        self.fill_list()
        if not self.zynqtgui.screens["sketchpad"].song:
            return
        QMetaObject.invokeMethod(self, "do_activate_midich_layer", Qt.QueuedConnection)

    @Slot(None)
    def do_activate_midich_layer(self):
        song = self.zynqtgui.screens["sketchpad"].song
        if song is not None and song.channelsModel is not None:
            channel = song.channelsModel.getChannel(self.zynqtgui.sketchpad.selectedTrackId)
            if channel is not None:
                logging.debug(f"Update Channel Sounds : {channel.connectedSound}")
                if channel.connectedSound >= 0:
                    self.zynqtgui.screens["layer"].activate_midichan_layer(channel.connectedSound)
                else:
                    self.select_action(0)
        else:
            self.select_action(0)

    def select(self, index=None):
        super().select(index)


    def select_action(self, i, t='S'):
        if i < 0 or i >= len(self.list_data):
            return
        midichan = self.list_data[i][1]
        logging.debug(f"### layers for channel select action : {midichan}")
        self.zynqtgui.screens['fixed_layers'].select_action(midichan, t)
        self.select(i)

    ### Property volumeControllers
    def get_volumeControllers(self):
        return self.__volume_controllers

    volumeControllersChanged = Signal()

    volumeControllers = Property("QVariantList", get_volumeControllers, notify=volumeControllersChanged)
    ### END Property volumeControllers

    def set_select_path(self):
        self.select_path_element = self.zynqtgui.screens['fixed_layers'].select_path_element
        self.select_path_element = self.zynqtgui.screens['fixed_layers'].select_path_element
        super().set_select_path()

#------------------------------------------------------------------------------
