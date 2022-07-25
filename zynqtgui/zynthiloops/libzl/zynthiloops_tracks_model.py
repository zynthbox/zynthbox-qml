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
import logging

import numpy as np
from PySide2.QtCore import QAbstractListModel, QModelIndex, QObject, Qt, Property, Signal, Slot
from .zynthiloops_track import zynthiloops_track

class zynthiloops_tracks_model(QAbstractListModel):
    IdRole = Qt.UserRole + 1
    NameRole = Qt.UserRole + 2
    TrackRole = Qt.UserRole + 3

    def __init__(self, parent: QObject):
        super(zynthiloops_tracks_model, self).__init__(parent)
        self.__song__ = parent
        self.__tracks__: [zynthiloops_track] = []

    def serialize(self):
        data = []
        for t in self.__tracks__:
            data.append(t.serialize())
        return data

    def deserialize(self, arr):
        if not isinstance(arr, list):
            raise Exception("Invalid json format for tracks")
        self.beginResetModel()
        self.__tracks__.clear()
        for i, t in enumerate(arr):
            track = zynthiloops_track(i, self.__song__, self)
            self.add_track(track)
            track.deserialize(t)
        self.endResetModel()

    def data(self, index, role=None):
        # logging.info(index.row(), self.__tracks__[index.row()])

        if not index.isValid():
            return None

        if index.row() >= len(self.__tracks__):
            return None

        if role == self.IdRole:
            return self.__tracks__[index.row()].id
        elif role == self.NameRole or role == Qt.DisplayRole:
            return self.__tracks__[index.row()].name
        elif role == self.TrackRole:
            return self.__tracks__[index.row()]
        else:
            return None

    def roleNames(self):
        role_names = {
            Qt.DisplayRole: b'display',
            self.IdRole: b"id",
            self.NameRole: b"name",
            self.TrackRole: b"track"
        }

        return role_names

    def rowCount(self, index):
        return len(self.__tracks__)

    def add_track(self, track: zynthiloops_track):
        length = len(self.__tracks__)

        self.beginInsertRows(QModelIndex(), length, length)
        self.__tracks__.append(track)
        self.endInsertRows()
        self.countChanged.emit()

    @Slot(int, result=QObject)
    def getTrack(self, row : int):
        if row < 0 or row >= len(self.__tracks__):
            return None
        return self.__tracks__[row]


    @Signal
    def countChanged(self):
        pass


    def count(self):
        return len(self.__tracks__)
    count = Property(int, count, notify=countChanged)

    def delete_track(self, track):
        for index, r_track in enumerate(self.__tracks__):
            if r_track is track:
                self.beginRemoveRows(QModelIndex(), index, index)
                del self.__tracks__[index]
                self.endRemoveRows()
                self.countChanged.emit()

                break

        for index, r_track in enumerate(self.__tracks__):
            r_track.set_id(index)
            clipsModel = r_track.clipsModel

            for clip_index in range(0, clipsModel.count):
                clip = clipsModel.getClip(clip_index)
                clip.set_row_index(index)

        self.__song__.schedule_save()

    @Slot(int, result=bool)
    def checkIfPatternAlreadyConnected(self, patternIndex):
        already_connected = False

        for i in range(0, self.count):
            track = self.getTrack(i)

            if track.connectedPattern == patternIndex:
                already_connected = True
                break

        logging.debug(f"Pattern {patternIndex} already connected: {already_connected}")

        return already_connected

    ### Property connectedSoundsCount
    def get_connected_sounds_count(self):
        zyngui = self.__song__.get_metronome_manager().zyngui
        assigned_layers = []

        tracks_model = zyngui.screens["zynthiloops"].song.tracksModel

        for i in range(0, tracks_model.count):
            track = tracks_model.getTrack(i)
            assigned_layers.extend([x for x in track.chainedSounds if x >= 0 and track.checkIfLayerExists(x)])

        values = np.unique(assigned_layers)

        logging.debug(f"### Connected Sounds Count : length({len(values)}) -> {values}")

        return len(values)
    connected_sounds_count_changed = Signal()
    connectedSoundsCount = Property(int, get_connected_sounds_count, notify=connected_sounds_count_changed)
    ### END Property connectedSoundsCount

    ### Property connectedPatternsCount
    def get_connected_patterns_count(self):
        connected_patterns = []
        for index, track in enumerate(self.__tracks__):
            if track.connectedPattern >= 0:
                connected_patterns.append(track.connectedPattern)
        values = np.unique(connected_patterns)
        return len(values)
    connected_patterns_count_changed = Signal()
    connectedPatternsCount = Property(int, get_connected_patterns_count, notify=connected_patterns_count_changed)
    ### END Property connectedPatternsCount
