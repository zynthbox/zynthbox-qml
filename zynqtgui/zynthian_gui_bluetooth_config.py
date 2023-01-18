#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthian Bluetooth Configuration : A page to configure Bluetooth connection
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
from subprocess import Popen

from PySide2.QtCore import QTimer, Slot

from . import zynthian_qt_gui_base


class zynthian_gui_bluetooth_config(zynthian_qt_gui_base.ZynGui):
    def __init__(self, parent=None):
        super(zynthian_gui_bluetooth_config, self).__init__(parent)
        self.zita_j2a_process = None

    def show(self):
        pass

    def zyncoder_read(self):
        pass

    def refresh_loading(self):
        pass

    @Slot()
    def connectBluetoothPorts(self):
        @Slot()
        def post_startup_task():
            # If zita-j2a bridge is running do run autoconnect to connect to bluetooth ports
            if self.zita_j2a_process is not None and self.zita_j2a_process.poll() is None:
                logging.info("Successfully started zita-j2a bridge. Bluetooth device should play audio now")
                self.zyngui.zynautoconnect()
            else:
                logging.error("Failed to start zita-j2a bridge. Check if bluetooth device is connected")

        if self.zita_j2a_process is not None:
            self.zita_j2a_process.terminate()

        self.zita_j2a_process = Popen(("zita-j2a", "-j", "bluealsa", "-d", "bluealsa", "-p", "1024", "-n", "3", "-c", "2", "-L"))

        QTimer.singleShot(3000, post_startup_task)
