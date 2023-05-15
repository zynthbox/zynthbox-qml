#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian Qt GUI Base Class: Base qtobject all gui logic uses
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


# Zynthian specific modules
from . import zynthian_gui_config

# Qt modules
from PySide2.QtCore import QObject


class zynqtgui(QObject):
    def __init__(self, parent=None):
        super(zynqtgui, self).__init__(parent)
        self.zynqtgui = zynthian_gui_config.zynqtgui
        self.select_path = ""
        self.shown = True

    def show(self):
        pass

    def refresh_loading(self):
        pass

    def set_select_path(self):
        pass

    def refresh_status(self, status={}):
        pass

#------------------------------------------------------------------------------
