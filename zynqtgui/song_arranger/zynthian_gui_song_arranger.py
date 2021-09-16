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
from PySide2.QtCore import Property, QObject, Signal

from .. import zynthian_qt_gui_base


class zynthian_gui_song_arranger(zynthian_qt_gui_base.ZynGui):
    def __init__(self, parent=None):
        super(zynthian_gui_song_arranger, self).__init__(parent)
        self.__bars__ = 240
        self.__sketch__ = self.zyngui.zynthiloops.song

    ### Property bars
    def get_bars(self):
        return self.__bars__
    bars_changed = Signal()
    bars = Property(int, get_bars, notify=bars_changed)
    ### END Property bars

    ### Property sketch
    def get_sketch(self):
        return self.__sketch__
    sketch = Property(QObject, get_sketch, constant=True)
    ### END Property sketch