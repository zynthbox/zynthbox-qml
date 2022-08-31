#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# A model to for storing channels in Sketchpad page
#
# Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
#
# ******************************************************************************
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
# ******************************************************************************

from PySide2.QtCore import Property, QObject, Signal, Slot

from zynqtgui.song_arranger.song_arranger_cells_model import song_arranger_cells_model


class song_arranger_channel(QObject):
    def __init__(self, zl_channel, parent=None):
        super(song_arranger_channel, self).__init__(parent)
        self.__cells_model__ = song_arranger_cells_model(self)
        self.__zl_channel__ = zl_channel
        self.__selected_clip__ = None

    ### Property cellsModel
    def get_cellsModel(self):
        return self.__cells_model__
    cellsModel = Property(QObject, get_cellsModel, constant=True)
    ### END Property cellsModel

    ### Property zlChannel
    def get_zlChannel(self):
        return self.__zl_channel__
    zlChannel = Property(QObject, get_zlChannel, constant=True)
    ### END Property zlChannel

    ### Property name
    def get_name(self):
        return self.__zl_channel__.name
    name = Property(str, get_name, constant=True)
    ### END Property name

    ### Property selectedClip
    @Signal
    def selected_clip_changed(self):
        pass
    def get_selected_clip(self):
        return self.__selected_clip__
    def set_selected_clip(self, clip):
        self.__selected_clip__ = clip
        self.selected_clip_changed.emit()
    selectedClip = Property(QObject, get_selected_clip, set_selected_clip, notify=selected_clip_changed)
    ### END Property selectedClip
