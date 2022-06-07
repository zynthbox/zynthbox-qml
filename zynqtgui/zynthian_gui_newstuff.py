#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian GUI Option Selector Class for KNewStuff downloaders
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
import os
from pathlib import Path

from PySide2.QtCore import Qt, Property, Signal, Slot, QObject

# Zynthian specific modules
from . import zynthian_gui_selector

#------------------------------------------------------------------------------
# Zynthian Listing effects for active layer GUI Class
#------------------------------------------------------------------------------

class zynthian_gui_newstuff(zynthian_gui_selector):

    def __init__(self, parent = None):
        super(zynthian_gui_newstuff, self).__init__('Download', parent)

        self.audiofx_layer = None
        self.audiofx_layers = None
        self.newstuff_model_changed.connect(self.fill_list)
        self.newstuff_model_data = None

        self.current_index_changed.connect(self.set_selector)

    def fill_list(self):
        self.list_data=[]
        if self.newstuff_model_data:
            if self.newstuff_model_data.rowCount() > 0:
                for index in range(self.newstuff_model_data.rowCount()):
                    entry_name = self.newstuff_model_data.data(self.newstuff_model_data.index(index, 0))
                    # 285 is StatusRole in NewStuff's model
                    entry_status = 0 #int(self.newstuff_model_data.data(self.newstuff_model_data.index(index, 0), 285))
                    # element 0 is action_id
                    # element 1 is entry_index
                    # element 2 is the display role
                    self.list_data.append((entry_status,index,entry_name))

        super().fill_list()

    def update_list(self):
        self.fill_list()
        self.set_selector()

    def select_action(self, i, t='S'):
        if i < 0 or i >= len(self.list_data):
            return

        self.select(i)

    def set_select_path(self):
        self.select_path = "Download"
        super().set_select_path()

    def get_newstuff_model(self):
        return self.newstuff_model_data

    def background_model_deleted(self):
        self.newstuff_model_data = None
        self.newstuff_model_changed.emit()

    def set_newstuff_model(self,new_model):
        self.newstuff_model_data = new_model
        self.newstuff_model_data.rowsInserted.connect(self.update_list)
        self.newstuff_model_data.rowsRemoved.connect(self.update_list)
        self.newstuff_model_data.dataChanged.connect(self.update_list)
        self.newstuff_model_data.modelReset.connect(self.update_list)
        self.newstuff_model_data.destroyed.connect(self.background_model_deleted)
        self.newstuff_model_changed.emit()

    newstuff_model_changed = Signal()

    newstuff_model = Property(QObject, get_newstuff_model, set_newstuff_model, notify = newstuff_model_changed)

#------------------------------------------------------------------------------
