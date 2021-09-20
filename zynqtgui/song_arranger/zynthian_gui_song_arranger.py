#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthian Arranger: A page to arrange songs
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

from PySide2.QtCore import Property, QObject, Signal

from .song_arranger_cell import song_arranger_cell
from .song_arranger_track import song_arranger_track
from .song_arranger_tracks_model import song_arranger_tracks_model
from .. import zynthian_qt_gui_base


class zynthian_gui_song_arranger(zynthian_qt_gui_base.ZynGui):
    def __init__(self, parent=None):
        super(zynthian_gui_song_arranger, self).__init__(parent)
        self.__bars__ = 24
        self.__sketch__ = None
        self.__tracks_model__ = None

        self.generate_tracks_model()

    ### Property bars
    def get_bars(self):
        return self.__bars__
    bars_changed = Signal()
    bars = Property(int, get_bars, notify=bars_changed)
    ### END Property bars

    ### Property tracksModel
    def get_tracksModel(self):
        return self.__tracks_model__
    tracks_model_changed = Signal()
    tracksModel = Property(QObject, get_tracksModel, notify=tracks_model_changed)
    ### END Property tracksModel

    def generate_tracks_model(self):
        logging.error(f"Generating tracks model from Sketch({self.zyngui.zynthiloops.song})")

        self.__sketch__ = self.zyngui.zynthiloops.song
        self.__tracks_model__ = song_arranger_tracks_model(self)

        try:
            self.__sketch__.tracksModel.countChanged.disconnect()
        except Exception as e:
            logging.error(f"Already disconnected : {str(e)}")

        try:
            self.zyngui.zynthiloops.song_changed.disconnect()
        except Exception as e:
            logging.error(f"Already disconnected: {str(e)}")

        self.__sketch__.tracksModel.countChanged.connect(self.generate_tracks_model)
        self.zyngui.zynthiloops.song_changed.connect(self.generate_tracks_model)

        for i in range(self.__sketch__.tracksModel.count):
            track = song_arranger_track(self.__sketch__.tracksModel.getTrack(i), self.__tracks_model__)
            self.__tracks_model__.add_track(track)

            for j in range(self.__bars__):
                cell = song_arranger_cell(j, track)
                track.cellsModel.add_cell(cell)

        self.tracks_model_changed.emit()
