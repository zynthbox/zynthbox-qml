#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian GUI Option Selector Class for KNewStuff downloaders
# 
# Copyright (C) 2021 Marco Martin <mart@kde.org>
#
#******************************************************************************
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
#******************************************************************************

import sys
import logging
import os
from pathlib import Path

from PySide2.QtCore import Qt, Property, Signal, Slot, QObject

# Zynthian specific modules
from . import zynthian_qt_gui_base

#------------------------------------------------------------------------------
# Zynthian Listing effects for active layer GUI Class
#------------------------------------------------------------------------------

class zynthian_gui_song_player(zynthian_qt_gui_base.zynqtgui):

    def __init__(self, parent = None):
        super(zynthian_gui_song_player, self).__init__(parent)

#------------------------------------------------------------------------------

