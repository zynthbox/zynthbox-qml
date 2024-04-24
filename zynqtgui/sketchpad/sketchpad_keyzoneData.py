#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# A data container for managing keyzone data
#
# Copyright (C) 2024 Dan Leinir Turthra Jensen <admin@leinir.dk>
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

class sketchpad_keyzoneData(QObject):
    def __init__(self, parent: QObject = None):
        super(sketchpad_keyzoneData, self).__init__(parent)
        self.__keyZoneStart__ = 0
        self.__keyZoneEnd__ = 127
        self.__rootNote__ = 60

    def clear(self):
        self.keyZoneStart = 0
        self.keyZoneEnd = 127
        self.rootNote = 60

    def get_keyZoneStart(self):
        return self.__keyZoneStart__
    def set_keyZoneStart(self, value: int = 0):
        if self.__keyZoneStart__ != value:
            self.__keyZoneStart__ = value
            self.keyZoneStartChanged.emit()
    keyZoneStartChanged = Signal()
    keyZoneStart = Property(int, get_keyZoneStart, set_keyZoneStart, notify=keyZoneStartChanged)

    def get_keyZoneEnd(self):
        return self.__keyZoneEnd__
    def set_keyZoneEnd(self, value: int = 0):
        if self.__keyZoneEnd__ != value:
            self.__keyZoneEnd__ = value
            self.keyZoneEndChanged.emit()
    keyZoneEndChanged = Signal()
    keyZoneEnd = Property(int, get_keyZoneEnd, set_keyZoneEnd, notify=keyZoneEndChanged)

    def get_rootNote(self):
        return self.__rootNote__
    def set_rootNote(self, value: int = 0):
        if self.__rootNote__ != value:
            self.__rootNote__ = value
            self.rootNoteChanged.emit()
    rootNoteChanged = Signal()
    rootNote = Property(int, get_rootNote, set_rootNote, notify=rootNoteChanged)

    def serialize(self):
        return {
            "keyZoneStart": self.keyZoneStart,
            "keyZoneEnd": self.keyZoneEnd,
            "rootNote": self.rootNote}

    def deserialize(self, obj):
        try:
            self.clear()
            if "keyZoneStart" in obj:
                self.keyZoneStart = obj["keyZoneStart"]
            if "keyZoneEnd" in obj:
                self.keyZoneEnd = obj["keyZoneEnd"]
            if "rootNote" in obj:
                self.rootNote = obj["rootNote"]
        except Exception as e:
            logging.error(f"Failure during deserialization of keyzone: {e}")
