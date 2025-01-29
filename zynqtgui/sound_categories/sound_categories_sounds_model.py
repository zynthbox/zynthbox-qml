#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# A model to store sounds by categories
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
from enum import IntEnum, auto

from PySide2.QtCore import QAbstractListModel, QModelIndex, Qt, Property, Signal, Slot, QObject

from zynqtgui.sound_categories.zynthbox_sound import zynthbox_sound


class sound_categories_sounds_model(QAbstractListModel):
    class Roles(IntEnum):
        SoundRole = Qt.UserRole + 1
        SoundTypeRole = auto()
        CategoryRole = auto()

    def __init__(self, parent=None):
        super().__init__(parent)

        # List of zynthbox_sound instances
        self.sounds = []

    ### Property count
    def count(self):
        return len(self.sounds)
    countChanged = Signal()
    count = Property(int, count, notify=countChanged)
    ### END Property count

    def data(self, index, role=None):
        if not index.isValid():
            return None

        if index.row() > len(self.sounds):
            return None

        if role == Qt.DisplayRole:
            return self.sounds[index.row()].name
        elif role == self.Roles.SoundTypeRole:
            return self.sounds[index.row()].type
        elif role == self.Roles.CategoryRole:
            return self.sounds[index.row()].category
        elif role == self.Roles.SoundRole:
            return self.sounds[index.row()]
        else:
            return None

    def roleNames(self):
        role_names = {
            Qt.DisplayRole: b'display',
            self.Roles.SoundRole: b"sound",
            self.Roles.SoundTypeRole: b"soundType",
            self.Roles.CategoryRole: b"category",
        }

        return role_names

    def rowCount(self, index):
        return len(self.sounds)

    def add_sound(self, sound: zynthbox_sound):
        if sound.name.startswith("."):
            return

        length = len(self.sounds)

        self.beginInsertRows(QModelIndex(), length, length)
        self.sounds.append(sound)
        self.endInsertRows()
        self.countChanged.emit()

    def clear(self):
        self.beginResetModel()
        self.sounds = []
        self.endResetModel()

    def emit_category_updated(self, sound):
        # TODO
        sound_index = self.sounds.index(sound)
        self.dataChanged.emit(self.index(sound_index, 0), self.index(sound_index, 0), [self.Roles.CategoryRole])
