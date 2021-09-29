#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthian Arranger: A page to copy tracks between sketches in a session
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
from pathlib import Path

from PySide2.QtCore import Property, QObject, Signal, Slot

from .. import zynthian_qt_gui_base
from ..zynthiloops.libzl.zynthiloops_song import zynthiloops_song
from ..zynthiloops.libzl.zynthiloops_track import zynthiloops_track


class zynthian_gui_sketch_copier(zynthian_qt_gui_base.ZynGui):
    def __init__(self, parent=None):
        super(zynthian_gui_sketch_copier, self).__init__(parent)
        self.__sketches__ = {
            "1": None,
            "2": None,
            "3": None,
            "4": None,
            "5": None,
            "6": None,
            "7": None,
            "8": None,
            "9": None,
            "10": None,
            "11": None,
        }
        self.__track_copy_cache__ = None
        self.__track_copy_source__ = None

    ### Property sketches
    def get_sketches(self):
        return self.__sketches__
    sketches_changed = Signal()
    sketches = Property('QVariantMap', get_sketches, notify=sketches_changed)
    ### END Property sketches

    ### Property isCopyInProgress
    def get_is_copy_in_progress(self):
        return self.__track_copy_cache__ is not None
    is_copy_in_progress_changed = Signal()
    isCopyInProgress = Property(bool, get_is_copy_in_progress, notify=is_copy_in_progress_changed)
    ### END Property isCopyInProgress

    ### Property trackCopySource
    def get_track_copy_source(self):
        return self.__track_copy_source__
    track_copy_source_changed = Signal()
    trackCopySource = Property(QObject, get_track_copy_source, notify=track_copy_source_changed)
    ### END Property trackCopySource

    @Slot(QObject)
    def copyTrack(self, track):
        self.__track_copy_cache__ = track.serialize()
        self.__track_copy_source__ = track
        self.is_copy_in_progress_changed.emit()
        self.track_copy_source_changed.emit()

        logging.error(f"Copied track : {self.__track_copy_cache__}")

    @Slot(None)
    def cancelCopyTrack(self):
        self.__track_copy_cache__ = None
        self.__track_copy_source__ = None
        self.is_copy_in_progress_changed.emit()
        self.track_copy_source_changed.emit()

        logging.error(f"Track Copy Cancelled")

    @Slot(QObject)
    def pasteTrack(self, sketch):
        logging.error(f"Pasting track to sketch : {sketch.name}")

        pasted_track = zynthiloops_track(sketch.tracksModel.count, sketch, self)
        sketch.tracksModel.add_track(pasted_track)
        pasted_track.deserialize(self.__track_copy_cache__)
        self.__track_copy_cache__ = None
        self.__track_copy_source__ = None
        self.is_copy_in_progress_changed.emit()
        self.track_copy_source_changed.emit()
