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

    def __init__(self, id: int, song: QObject, parent: QObject = None):
        super(zynthiloops_track, self).__init__(parent)
        self.__id__ = id
        self.__name__ = f"T{self.__id__ + 1}"
        self.__song__ = song
        self.__clips_model__ = zynthiloops_clips_model(song, self)

    def serialize(self):
        return {"name": self.name,
            "clips": self.__clips_model__.serialize()}

    def deserialize(self, obj):
        if "name" in obj:
            self.__name__ = obj["name"]
        if "clips" in obj:
            self.__clips_model__.deserialize(obj["clips"])


    def playable(self):
        return False
    playable = Property(bool, playable, constant=True)

    def recordable(self):
        return False
    recordable = Property(bool, recordable, constant=True)

    def clearable(self):
        return True
    clearable = Property(bool, clearable, constant=True)

    def deletable(self):
        return True
    deletable = Property(bool, deletable, constant=True)

    def nameEditable(self):
        return True
    nameEditable = Property(bool, nameEditable, constant=True)

    def id(self):
        return self.__id__
    id = Property(int, id, constant=True)

    @Signal
    def __name_changed__(self):
        pass

    def name(self):
        return self.__name__

    def set_name(self, name):
        self.__name__ = name
        self.__name_changed__.emit()
        self.__song__.schedule_save()

    name = Property(str, name, set_name, notify=__name_changed__)

    def type(self):
        return self.__type__
    type = Property(str, type, constant=True)

    def clipsModel(self):
        return self.__clips_model__
    clipsModel = Property(QObject, clipsModel, constant=True )
