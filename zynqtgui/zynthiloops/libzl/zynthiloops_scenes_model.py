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
    NameRole = SceneRole + 1

    def __init__(self, parent=None):
        super().__init__(parent)
        self.__scenes__ = {
            0: {"clips": []},
            1: {"clips": []},
            2: {"clips": []},
            3: {"clips": []},
            4: {"clips": []},
            5: {"clips": []},
            6: {"clips": []},
            7: {"clips": []},
            8: {"clips": []},
            9: {"clips": []},
            10: {"clips": []},
            11: {"clips": []},
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
        elif role == Qt.DisplayRole or role == self.NameRole:
            return chr(index.row() + 65)
        else:
            return None

    def roleNames(self):
        role_names = {
            Qt.DisplayRole: b'display',
            self.SceneRole: b"scene",
            self.NameRole: b"name",
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
