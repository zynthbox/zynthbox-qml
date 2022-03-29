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

from PySide2.QtCore import Property, QObject, Signal


class sounds_model_sound_dto(QObject):
    def __init__(self, parent, name, type, category="0"):
        super().__init__(parent)

        self.__name__ = name
        self.__type__ = type
        self.__category__ = category

    ### Property name
    def get_name(self):
        return self.__name__

    def set_name(self, name):
        if self.__name__ != name:
            self.__name__ = name
            self.name_changed.emit()

    name_changed = Signal()

    name = Property(str, get_name, set_name, notify=name_changed)
    ### END Property name

    ### Property type
    def get_type(self):
        return self.__type__

    def set_type(self, type):
        if self.__type__ != type:
            self.__type__ = type
            self.type_changed.emit()

    type_changed = Signal()

    type = Property(str, get_type, set_type, notify=type_changed)
    ### END Property type

    ### Property category
    def get_category(self):
        return self.__category__

    def set_category(self, category):
        if self.__category__ != category:
            self.__category__ = category
            self.category_changed.emit()

    category_changed = Signal()

    category = Property(str, get_category, set_category, notify=category_changed)
    ### END Property category