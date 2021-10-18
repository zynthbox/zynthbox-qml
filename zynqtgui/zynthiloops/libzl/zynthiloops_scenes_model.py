#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# A model to store scenes of a song in ZynthiLoops
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
import logging
from PySide2.QtCore import QAbstractListModel, QModelIndex, Qt, Property, Signal, Slot, QObject


class zynthiloops_scenes_model(QAbstractListModel):
    SceneRole = Qt.UserRole + 1

    def __init__(self, parent=None):
        super().__init__(parent)
        self.__selected_scene_index__ = 0
        self.__scenes__ = {
            0: {"name": "A", "clips": []},
            1: {"name": "B", "clips": []},
            2: {"name": "C", "clips": []},
            3: {"name": "D", "clips": []},
            4: {"name": "E", "clips": []},
            5: {"name": "F", "clips": []},
            6: {"name": "G", "clips": []},
            7: {"name": "H", "clips": []},
            8: {"name": "I", "clips": []},
            9: {"name": "J", "clips": []},
            10: {"name": "K", "clips": []},
            11: {"name": "L", "clips": []},
        }

    def serialize(self):
        pass

    def deserialize(self, arr):
        pass

    def data(self, index, role=None):
        if not index.isValid():
            return None

        if index.row() > len(self.__scenes__):
            return None

        if role == self.SceneRole:
            return self.__scenes__[index.row()]
        else:
            return None

    def roleNames(self):
        role_names = {
            Qt.DisplayRole: b'display',
            self.SceneRole: b"scene",
        }

        return role_names

    def rowCount(self, index):
        return len(self.__scenes__)

    ### Property count
    def count(self):
        return len(self.__scenes__)
    countChanged = Signal()
    count = Property(int, count, notify=countChanged)
    ### END Property count

    ### Property selectedSceneIndex
    def get_selected_scene_index(self):
        return self.__selected_scene_index__
    def set_selected_scene_index(self, index):
        self.__selected_scene_index__ = index
        self.selected_scene_index_changed.emit()
    selected_scene_index_changed = Signal()
    selectedSceneIndex = Property(int, get_selected_scene_index, set_selected_scene_index, notify=selected_scene_index_changed)
    ### END Property selectedSceneIndex

    @Slot(int, result='QVariantMap')
    def getScene(self, index):
        return self.__scenes__[index]