#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian GUI Info Class
# 
# Copyright (C) 2021 Marco MArtin <mart@kde.org>
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

from datetime import datetime

# Zynthian specific modules
from . import zynthian_gui_selector

# Qt modules
from PySide2.QtCore import Qt, QObject, Slot, Signal, Property


#------------------------------------------------------------------------------
# Zynthian Session Dashboard GUI Class
#------------------------------------------------------------------------------

class zynthian_gui_session_dashboard(zynthian_gui_selector):

    def __init__(self, parent=None):
        super(zynthian_gui_session_dashboard, self).__init__('Session', parent)
        self.__sessionStartTime = datetime.now()

        self.show()

    def fill_list(self):
        self.list_data = []
        self.list_metadata = []
        super().fill_list()

    def select_action(self, i, t='S'):
        self.index = i


    @Slot(None, result=float)
    def get_session_time(self):
        logging.error((datetime.now() - self.__sessionStartTime).total_seconds())
        return (datetime.now() - self.__sessionStartTime).total_seconds()

    def set_select_path(self):
        self.select_path = "Session"
        self.select_path_element = "Session"
        super().set_select_path()

#-------------------------------------------------------------------------------
