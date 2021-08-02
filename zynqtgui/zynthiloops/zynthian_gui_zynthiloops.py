#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthian PlayGrid: A page to play ntoes with buttons
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
from PySide2.QtCore import Property, QObject, Signal

from .zynthiloops_track import ZynthiLoopsTrack
from .zynthiloops_tracks_model import ZynthiLoopsTracksModel
from .. import zynthian_qt_gui_base


class zynthian_gui_zynthiloops(zynthian_qt_gui_base.ZynGui):
    __track_counter__ = 0

    def __init__(self, parent=None):
        super(zynthian_gui_zynthiloops, self).__init__(parent)

        self.__model__ = ZynthiLoopsTracksModel()

        self.__model__.add_track(ZynthiLoopsTrack(0))
        self.__model__.add_track(ZynthiLoopsTrack(1))
        self.__model__.add_track(ZynthiLoopsTrack(2))

    def show(self):
        pass

    def zyncoder_read(self):
        pass

    def refresh_loading(self):
        pass

    def __get_model__(self):
        return self.__model__

    @Signal
    def __model_changed__(self):
        pass

    model = Property(QObject, __get_model__, notify=__model_changed__)
