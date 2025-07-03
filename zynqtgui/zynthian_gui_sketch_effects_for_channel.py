#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian GUI Sketch FX selector class
# 
# Copyright (C) 2025 Anupam Basak <anupam.basak27@gmail.com>
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

class zynthian_gui_sketch_effects_for_channel(zynthian_gui_selector):
    """
    A Selector class to display Sketch FX List on FXSetupPage
    """
    def __init__(self, parent = None):
        super(zynthian_gui_sketch_effects_for_channel, self).__init__('Sketch FX', parent)

    @Slot()
    def fill_list(self):
        self.list_data = []
        try:
            selected_track = self.zynqtgui.sketchpad.song.channelsModel.getChannel(self.zynqtgui.sketchpad.selectedTrackId)
            for index in range(5):
                self.list_data.append((str(index+1), index, f"{index+1} - {selected_track.chainedSketchFxNames[index]}", selected_track.chainedSketchFx[index]))
            self.select(selected_track.selectedSlot.value)
        except:
            # fill_list might fail when sketchpad is yet to be loaded. Do nothing as it will fill list again when curlayer changes
            pass
        super().fill_list()

    def select(self, index=None):
        super().select(index)
        self.set_select_path()

    def select_action(self, i, t='S'):
        if i < 0 or i >= len(self.list_data):
            return
        selected_track = self.zynqtgui.sketchpad.song.channelsModel.getChannel(self.zynqtgui.sketchpad.selectedTrackId)
        # Doing this here will result in the popup showing immediate when an entry is activated (which isn't the intent)
        # The value will still be updated, but from the ui *after* the item has been activated
        # selected_track.selectedSlot.value = i
        selected_track.setCurlayerByType("sketch-fx")
        self.select(i)
        self.fill_list()

    def index_supports_immediate_activation(self, index=None):
        return True

    def back_action(self):
        return 'sketchpad'

    def next_action(self):
        return 'sketch_effect_preset'

    def set_select_path(self):
        self.select_path = "Sketch FX"
        if len(self.list_data) > 0:
            self.select_path_element = str(self.list_data[self.index][1] + 1)
        super().set_select_path()

#------------------------------------------------------------------------------
