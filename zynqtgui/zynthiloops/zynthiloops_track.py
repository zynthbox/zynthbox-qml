#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# A model to for storing tracks in ZynthiLoops page
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


from PySide2.QtCore import Property, QObject


class ZynthiLoopsTrack(QObject):
    def __init__(self, id: int, parent: QObject = None):
        super(ZynthiLoopsTrack, self).__init__(parent)
        self.__id__ = id

    @Property(int, constant=True)
    def id(self):
        return self.__id__

    @Property(str, constant=True)
    def name(self):
        return f"Track #{self.__id__}"
