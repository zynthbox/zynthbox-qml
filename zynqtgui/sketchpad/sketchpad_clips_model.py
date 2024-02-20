#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# A model to store parts of a song in Sketchpad
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

from .sketchpad_clip import sketchpad_clip


class sketchpad_clips_model(QAbstractListModel):
    ClipIndexRole = Qt.UserRole + 1
    NameRole = ClipIndexRole + 1
    ClipRole = ClipIndexRole + 2
    __clips__: [sketchpad_clip] = []

    def __init__(self, song, parentChannel=None, partIndex=-1):
        super().__init__(parentChannel)
        self.__channel__ = parentChannel
        self.__song__ = song
        self.__clips__ = []
        self.__samples__ = []
        self.__partIndex__ = partIndex
        partNames = ['a', 'b', 'c', 'd', 'e']
        self.__partName__ = "(?)" if (partIndex == -1) else partNames[partIndex]
        if self.__channel__ is not None:
            self.__channel__.keyZoneModeChanged.connect(self.updateSamplesFromChannel)
            self.__channel__.channel_audio_type_changed.connect(self.updateSamplesFromChannel)

    def serialize(self):
        data = []
        for c in self.__clips__:
            data.append(c.serialize())
        return data

    def deserialize(self, arr, part_index):
        if not isinstance(arr, list):
            for i in range(2):
                clip = sketchpad_clip(self.__channel__.id, i, part_index, self.__song__, self)
                self.add_clip(clip)
            raise Exception("Invalid json format for clips")

        if len(arr) == 0:
            for i in range(2):
                clip = sketchpad_clip(self.__channel__.id, i, part_index, self.__song__, self)
                self.add_clip(clip)
            return
        for i, c in enumerate(arr):
            clip = sketchpad_clip(self.__channel__.id, i, part_index, self.__song__, self)
            clip.deserialize(c)
            self.add_clip(clip)
            #self.__song__.add_clip_to_part(clip, i)

    def data(self, index, role=None):
        if not index.isValid():
            return None

        if index.row() > len(self.__clips__):
            return None

        if role == self.ClipIndexRole:
            return self.__clips__[index.row()].clipIndex
        elif role == self.NameRole or role == Qt.DisplayRole :
            return self.__clips__[index.row()].name
        elif role == self.ClipRole:
            return self.__clips__[index.row()]
        else:
            return None

    def roleNames(self):
        role_names = {
            Qt.DisplayRole: b'display',
            self.ClipIndexRole: b"clipIndex",
            self.NameRole: b"name",
            self.ClipRole: b"clip"
        }

        return role_names

    def rowCount(self, index):
        return len(self.__clips__)

    def add_clip(self, clip: sketchpad_clip):
        length = len(self.__clips__)

        self.beginInsertRows(QModelIndex(), length, length)
        self.__clips__.append(clip)
        self.endInsertRows()
        self.countChanged.emit()
        if self.__channel__ is not None and self.__partIndex__ > -1:
            # The clips in a parts model contains the scene-related information for the channel/clip
            clip.enabled_changed.connect(self.__channel__.onClipEnabledChanged, Qt.QueuedConnection)

    @Slot(int, result=QObject)
    def getClip(self, row : int):
        if row < 0 or row >= len(self.__clips__):
            return None
        return self.__clips__[row]

    @Slot(QObject, result=int)
    def getClipIndex(self, clip):
        if clip in self.__clips__:
            return self.__clips__.index(clip)
        return -1

    @Signal
    def countChanged(self):
        pass


    def count(self):
        return len(self.__clips__)
    count = Property(int, count, notify=countChanged)

    ### BEGIN Property partName
    def get_partName(self):
        return self.__partName__
    def set_partName(self, partName):
        if self.__partName__ != partName:
            self.__partName__ = partName;
            self.partName_changed.emit()
    @Signal
    def partName_changed(self):
        pass
    partName = Property(str, get_partName, set_partName, notify=partName_changed)
    ### END Property partName

    ### BEGIN Property samples
    def get_samples(self):
        return self.__samples__
    def set_samples(self, samples):
        if self.__samples__ != samples:
            self.__samples__ = samples;
            self.samples_changed.emit()
    @Signal
    def samples_changed(self):
        pass
    @Slot(int)
    def addSample(self, sample):
        if not sample in self.__samples__:
            self.__samples__.append(sample)
            self.samples_changed.emit()
    @Slot(int)
    def removeSample(self, sample):
        if sample in self.__samples__:
            self.__samples__.remove(sample)
            self.samples_changed.emit()
    @Slot(None)
    def clearSamples(self):
        self.__samples__.clear()
        self.samples_changed.emit()
    @Slot(None)
    def updateSamplesFromChannel(self):
        if self.__channel__ is not None:
            if self.__channel__.channelAudioType == "sample-trig" and self.__channel__.keyZoneMode == "all-full":
                self.__samples__ = [self.__partIndex__] # A little odd seeming perhaps, but the indices line up (five parts, five samples, we want the sample for trig/full to match the part)
            else:
                self.__samples__ = [0, 1, 2, 3, 4]
            self.samples_changed.emit()
    samples = Property('QVariantList', get_samples, set_samples, notify=samples_changed)
    ### END Property samples
