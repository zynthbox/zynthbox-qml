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

from PySide2.QtCore import Qt, QObject, Slot, Signal, Property

#------------------------------------------------------------------------------
# basically a proxy model to zynthian_fixed:tracks
#------------------------------------------------------------------------------

class zynthian_gui_layers_for_track(zynthian_gui_selector):

    def __init__(self, parent = None):
        super(zynthian_gui_layers_for_track, self).__init__('TrackLayers', parent)
        self.__total_chains = 5
        self.__volume_ctrls = []
        self.zyngui.screens['session_dashboard'].selected_track_changed.connect(self.fill_list)

    def fill_list(self):
        self.list_data = []
        self.list_metadata = []
        self.__volume_ctrls = []
        try:
            selected_track = self.zyngui.screens['zynthiloops'].song.tracksModel.getTrack(self.zyngui.screens['session_dashboard'].selectedTrack)
            chain = selected_track.get_chained_sounds()
            empty_channels_needed = 0
            duplicate_chans = []
            for chan in chain:
                if chan < 0 or chan in duplicate_chans: #FIXEME: workaround form duplicate entries in chans
                    empty_channels_needed += 1
                duplicate_chans.append(chan)
            used_empty_channels = 0
            for i, element in enumerate(self.zyngui.screens['fixed_layers'].list_data):
                if element[1] in chain:
                    self.list_data.append(element)
                    self.list_metadata.append(self.zyngui.screens['fixed_layers'].list_metadata[i])
                    self.__volume_ctrls.append(self.zyngui.screens['fixed_layers'].get_volume_controls()[i])
                elif used_empty_channels < empty_channels_needed and len(self.list_data) < self.__total_chains and  not self.zyngui.screens['fixed_layers'].index_is_valid(i):
                    self.list_data.append(element)
                    self.list_metadata.append(self.zyngui.screens['fixed_layers'].list_metadata[i])
                    self.__volume_ctrls.append(self.zyngui.screens['fixed_layers'].get_volume_controls()[i])
                    used_empty_channels += 1
            self.volume_controls_changed.emit()
        except Exception as e:
            logging.error(e)
            pass
        super().fill_list()


    def sync_index_from_curlayer(self):
        midi_chan = -1
        if self.zyngui.curlayer:
            midi_chan = self.zyngui.curlayer.midi_chan
        else:
            midi_chan = zyncoder.lib_zyncoder.get_midi_active_chan()

        for i, item in enumerate(self.list_data):
            if midi_chan == item[1]:
                self.current_index = i
                return

    def select_action(self, i, t='S'):
        if i < 0 or i >= len(self.list_data):
            return
        midichan = self.list_data[i][1]
        self.zyngui.screens['fixed_layers'].select_action(midichan, t)

    def get_volume_controls(self):
        return self.__volume_ctrls
    @Signal
    def volume_controls_changed(self):
        pass
    volume_controls = Property('QVariantList', get_volume_controls, notify = volume_controls_changed)

    def set_select_path(self):
        self.select_path_element = self.zyngui.screens['fixed_layers'].select_path_element
        self.select_path_element = self.zyngui.screens['fixed_layers'].select_path_element
        super().set_select_path()

#------------------------------------------------------------------------------
