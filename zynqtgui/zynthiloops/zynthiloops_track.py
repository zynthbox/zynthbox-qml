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


from PySide2.QtCore import Property, QObject, Signal, Slot

from .zynthiloops_clips_model import zynthiloops_clips_model
from .zynthiloops_clip import zynthiloops_clip

class zynthiloops_track(QObject):
    # Possible Values : "audio", "video"
    __type__ = "audio"

    def __init__(self, id: int, parent: QObject = None):
        super(zynthiloops_track, self).__init__(parent)
        self.__id__ = id
        self.__name__ = f"Track {self.__id__}"
        self.__clips_model__ = zynthiloops_clips_model(self)
        # TODO: do from unserialization
        for i in range(0, 4):
            self.__clips_model__.add_clip(zynthiloops_clip(self.__id__, i, self))

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

    @Property(bool, constant=True)
    def nameEditable(self):
        return True

    @Property(int, constant=True)
    def id(self):
        return self.__id__

    @Signal
    def __name_changed__(self):
        pass

    @Property(str, notify=__name_changed__)
    def name(self):
        return self.__name__

    @name.setter
    def set_name(self, name):
        self.__name__ = name
        self.__name_changed__.emit()

    @Property(str, constant=True)
    def type(self):
        return self.__type__

    @Property(QObject, constant=True )
    def clipsModel(self):
        return self.__clips_model__
