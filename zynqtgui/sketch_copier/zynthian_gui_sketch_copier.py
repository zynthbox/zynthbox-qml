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
        self.__track_copy_cache__ = None
        self.__track_copy_source__ = None
        self.__add_sketch_path__ = ""

    ### Property isCopyInProgress
    def get_is_copy_in_progress(self):
        return self.__track_copy_cache__ is not None
    is_copy_in_progress_changed = Signal()
    isCopyInProgress = Property(bool, get_is_copy_in_progress, notify=is_copy_in_progress_changed)
    ### END Property isCopyInProgress

    ### Property addSketchPath
    def get_add_sketch_path(self):
        return self.__add_sketch_path__
    def set_add_sketch_path(self, path):
        self.__add_sketch_path__ = path
        self.add_sketch_path_changed.emit()
    add_sketch_path_changed = Signal()
    addSketchPath = Property(str, get_add_sketch_path, set_add_sketch_path, notify=add_sketch_path_changed)
    ### END Property addSketchPath

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

        logging.info(f"Copied track : {self.__track_copy_cache__}")

    @Slot(None)
    def cancelCopyTrack(self):
        self.__track_copy_cache__ = None
        self.__track_copy_source__ = None
        self.is_copy_in_progress_changed.emit()
        self.track_copy_source_changed.emit()

        logging.info(f"Track Copy Cancelled")

    @Slot(QObject)
    def pasteTrack(self, sketch):
        logging.info(f"Pasting track to sketch : {sketch.name}")

        pasted_track = zynthiloops_track(sketch.tracksModel.count, sketch, self)
        sketch.tracksModel.add_track(pasted_track)
        pasted_track.deserialize(self.__track_copy_cache__)
        self.__track_copy_cache__ = None
        self.__track_copy_source__ = None
        self.is_copy_in_progress_changed.emit()
        self.track_copy_source_changed.emit()

    @Slot(int)
    def setSketchSlot(self, slot):
        self.zyngui.session_dashboard.setSketchSlot(slot, self.__add_sketch_path__)
        self.__add_sketch_path__ = ""
        self.add_sketch_path_changed.emit()
