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


from PySide2.QtCore import Property, QObject, Slot


class zynthiloops_track(QObject):
    # Possible Values : "audio", "video"
    __type__ = "audio"
    __clips__ = []

    def __init__(self, id: int, parent: QObject = None):
        super(zynthiloops_track, self).__init__(parent)
        self.__id__ = id

    @Property(bool, constant=True)
    def playable(self):
        return False

    @Property(bool, constant=True)
    def recordable(self):
        return False

    @Property(bool, constant=True)
    def clearable(self):
        return True

    @Property(bool, constant=True)
    def deletable(self):
        return True

    @Property(int, constant=True)
    def id(self):
        return self.__id__

    @Property(str, constant=True)
    def name(self):
        return f"Track {self.__id__}"

    @Property(str, constant=True)
    def type(self):
        return self.__type__

    @Slot(QObject, int)
    def addClip(self, clip: QObject, index: int):
        self.__clips__.insert(index, clip)
