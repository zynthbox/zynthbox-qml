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
import logging
import ctypes as ctypes

from PySide2.QtCore import Property, QObject

from . import libzl
from .zynthiloops_song import zynthiloops_song
from .. import zynthian_qt_gui_base


@ctypes.CFUNCTYPE(None)
def timer_callback():
    logging.error(f"Timer triggered")


class zynthian_gui_zynthiloops(zynthian_qt_gui_base.ZynGui):
    def __init__(self, parent=None):
        super(zynthian_gui_zynthiloops, self).__init__(parent)
        self.__song__ = zynthiloops_song(self)
        libzl.registerTimerCallback(timer_callback)
        libzl.startTimer(2000)

    def show(self):
        pass

    @Property(QObject, constant=True)
    def song(self):
        return self.__song__

