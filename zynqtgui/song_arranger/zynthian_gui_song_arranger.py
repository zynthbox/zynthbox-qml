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
from .song_arranger_channel import song_arranger_channel
from .song_arranger_channels_model import song_arranger_channels_model
from .. import zynthian_qt_gui_base
from ..sketchpad import zynthian_gui_sketchpad
from zynqtgui.sketchpad.sketchpad_clip import sketchpad_clip
from zynqtgui.sketchpad.sketchpad_song import sketchpad_song
from zynqtgui.sketchpad.sketchpad_channel import sketchpad_channel


class zynthian_gui_song_arranger(zynthian_qt_gui_base.ZynGui):
    def __init__(self, parent=None):
        super(zynthian_gui_song_arranger, self).__init__(parent)
        self.__bars__ = 24
        self.__sketch__ = None
        self.__channels_model__ = song_arranger_channels_model(self)
        self.__metronome_manager__: zynthian_gui_sketchpad = self.zyngui.sketchpad
        self.__is_playing__ = False
        self.__start_from_bar__ = 0
        self.__playing_bar__ = -1

        self.__metronome_manager__.current_bar_changed.connect(self.current_bar_changed_handler)
        self.zyngui.sketchpad.song_changed.connect(self.generate_channels_model)

    ### Property bars
    def get_bars(self):
        return self.__bars__
    bars_changed = Signal()
    bars = Property(int, get_bars, notify=bars_changed)
    ### END Property bars

    ### Property channelsModel
    def get_channelsModel(self):
        return self.__channels_model__
    channels_model_changed = Signal()
    channelsModel = Property(QObject, get_channelsModel, notify=channels_model_changed)
    ### END Property channelsModel

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

    def generate_channels_model(self):
        logging.info(f"Generating channels model from Sketch({self.zyngui.sketchpad.song})")

        self.__sketch__:sketchpad_song = self.zyngui.sketchpad.song
        self.__channels_model__.clear()

        try:
            self.__sketch__.channelsModel.countChanged.disconnect()
        except Exception as e:
            logging.error(f"Already disconnected : {str(e)}")

        # try:
        #     self.zyngui.sketchpad.song_changed.disconnect()
        # except Exception as e:
        #     logging.error(f"Already disconnected: {str(e)}")

        self.__sketch__.channelsModel.countChanged.connect(self.generate_channels_model)

        for i in range(self.__sketch__.channelsModel.count):
            zl_channel: sketchpad_channel = self.__sketch__.channelsModel.getChannel(i)
            channel = song_arranger_channel(zl_channel, self.__channels_model__)
            self.__channels_model__.add_channel(channel)

            for j in range(self.__bars__):
                cell = song_arranger_cell(j, self.__metronome_manager__, channel, self)
                channel.cellsModel.add_cell(cell)

            for j in range(2):
                zl_clip: sketchpad_clip = self.__sketch__.getClip(zl_channel.id, j)

                if zl_clip is not None:
                    for pos in zl_clip.arrangerBarPositions:
                        cell = channel.cellsModel.getCell(pos)
                        logging.info(f"Restoring arranger clip({zl_clip}) to {pos} for {cell}")
                        cell.zlClip = zl_clip

        self.channels_model_changed.emit()
