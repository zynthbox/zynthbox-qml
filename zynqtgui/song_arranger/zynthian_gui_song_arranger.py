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

from PySide2.QtCore import Property, QObject, Signal, Slot

from .song_arranger_cell import song_arranger_cell
from .song_arranger_track import song_arranger_track
from .song_arranger_tracks_model import song_arranger_tracks_model
from .. import zynthian_qt_gui_base
from ..zynthiloops import zynthian_gui_zynthiloops
from ..zynthiloops.libzl.zynthiloops_clip import zynthiloops_clip
from ..zynthiloops.libzl.zynthiloops_song import zynthiloops_song
from ..zynthiloops.libzl.zynthiloops_track import zynthiloops_track


class zynthian_gui_song_arranger(zynthian_qt_gui_base.ZynGui):
    def __init__(self, parent=None):
        super(zynthian_gui_song_arranger, self).__init__(parent)
        self.__bars__ = 24
        self.__sketch__ = None
        self.__tracks_model__ = song_arranger_tracks_model(self)
        self.__metronome_manager__: zynthian_gui_zynthiloops = self.zyngui.zynthiloops
        self.__is_playing__ = False
        self.__start_from_bar__ = 0
        self.__playing_bar__ = -1

        self.__metronome_manager__.current_bar_changed.connect(self.current_bar_changed_handler)
        self.zyngui.zynthiloops.song_changed.connect(self.generate_tracks_model)

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

    ### Property isPlaying
    def get_is_playing(self):
        return self.__is_playing__
    is_playing_changed = Signal()
    isPlaying = Property(int, get_is_playing, notify=is_playing_changed)
    ### END Property isPlaying

    ### Property startFromBar
    def get_start_from_bar(self):
        return self.__start_from_bar__
    def set_start_from_bar(self, start):
        self.__start_from_bar__ = start
        self.start_from_bar_changed.emit()
    start_from_bar_changed = Signal()
    startFromBar = Property(int, get_start_from_bar, set_start_from_bar, notify=start_from_bar_changed)
    ### END Property startFromBar

    ### Property playingBar
    def get_playing_bar(self):
        return self.__playing_bar__
    playing_bar_changed = Signal()
    playingBar = Property(int, get_playing_bar, notify=playing_bar_changed)
    ### END Property playingBar

    @Slot(None)
    def start(self):
        self.__metronome_manager__.start_metronome_request()
        self.__is_playing__ = True
        self.is_playing_changed.emit()

    @Slot(None)
    def stop(self):
        self.__metronome_manager__.stop_metronome_request()
        self.__is_playing__ = False
        self.is_playing_changed.emit()

    def current_bar_changed_handler(self):
        self.__playing_bar__ = self.__metronome_manager__.currentBar + self.__start_from_bar__
        self.playing_bar_changed.emit()

    def generate_tracks_model(self):
        logging.info(f"Generating tracks model from Sketch({self.zyngui.zynthiloops.song})")

        self.__sketch__:zynthiloops_song = self.zyngui.zynthiloops.song
        self.__tracks_model__.clear()

        try:
            self.__sketch__.tracksModel.countChanged.disconnect()
        except Exception as e:
            logging.error(f"Already disconnected : {str(e)}")

        # try:
        #     self.zyngui.zynthiloops.song_changed.disconnect()
        # except Exception as e:
        #     logging.error(f"Already disconnected: {str(e)}")

        self.__sketch__.tracksModel.countChanged.connect(self.generate_tracks_model)

        for i in range(self.__sketch__.tracksModel.count):
            zl_track: zynthiloops_track = self.__sketch__.tracksModel.getTrack(i)
            track = song_arranger_track(zl_track, self.__tracks_model__)
            self.__tracks_model__.add_track(track)

            for j in range(self.__bars__):
                cell = song_arranger_cell(j, self.__metronome_manager__, track, self)
                track.cellsModel.add_cell(cell)

            for j in range(2):
                zl_clip: zynthiloops_clip = self.__sketch__.getClip(zl_track.id, j)

                if zl_clip is not None:
                    for pos in zl_clip.arrangerBarPositions:
                        cell = track.cellsModel.getCell(pos)
                        logging.info(f"Restoring arranger clip({zl_clip}) to {pos} for {cell}")
                        cell.zlClip = zl_clip

        self.tracks_model_changed.emit()
