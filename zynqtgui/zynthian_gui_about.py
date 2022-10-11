#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian GUI MIDI key-range config class
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
import apt
from ctypes import c_ubyte, c_byte

# Zynthian specific modules
from zyncoder import *
from . import zynthian_gui_config
from . import zynthian_qt_gui_base
from . import zynthian_gui_controller

from subprocess import run, check_output, Popen, PIPE, STDOUT

from PySide2.QtCore import Qt, QObject, Slot, Signal, Property

#------------------------------------------------------------------------------
# Some About data
#------------------------------------------------------------------------------

class zynthian_gui_about(zynthian_qt_gui_base.ZynGui):
    def __init__(self, parent=None):
        super(zynthian_gui_about, self).__init__(parent)
        self.cache = None

    def get_version_from_apt(self, package):
        try:
            if self.cache is None:
                self.cache = apt.cache.Cache()
                self.cache.open()
            return self.cache[package].installed.version
        except Exception as e:
            logging.error(f"Error getting version from apt : {e}")
            return ""

    def get_zynthbox_version(self):
        return self.get_version_from_apt("zynthbox-qml")
    zynthbox_version = Property(str, get_zynthbox_version, constant = True)

    def get_qt_version(self):
        return self.get_version_from_apt("libqt5core5a")
    qt_version = Property(str, get_qt_version, constant = True)

    def get_libzl_version(self):
        return self.get_version_from_apt("libzl")
    libzl_version = Property(str, get_libzl_version, constant = True)

    def get_kirigami_version(self):
        return self.get_version_from_apt("qml-module-org-kde-kirigami2")
    kirigami_version = Property(str, get_kirigami_version, constant = True)

    def get_zynthiancomponents_version(self):
        return self.get_version_from_apt("zynthian-quick-components")
    zynthiancomponents_version = Property(str, get_zynthiancomponents_version, constant = True)

    def set_select_path(self):
        self.select_path = "About"
        super().set_select_path()

    def get_kernel_version(self):
        try:
            cmd = "uname -sr"
            proc = Popen(
                cmd,
                shell=True,
                stdout=PIPE,
                stderr=STDOUT,
                universal_newlines=True,
            )

            for line in proc.stdout:
                if len(line) > 0:
                    return line[:-1]
        except Exception as e:
            logging.error(e)
    kernel_version = Property(str, get_kernel_version, constant = True)


    def get_distribution(self):
        try:
            cmd = "lsb_release -d"
            proc = Popen(
                cmd,
                shell=True,
                stdout=PIPE,
                stderr=STDOUT,
                universal_newlines=True,
            )

            for line in proc.stdout:
                if line.startswith("Description:"):
                    return line[len("Description:"):-1].lstrip()
        except Exception as e:
            logging.error(e)
    distribution_version = Property(str, get_distribution, constant = True)

#------------------------------------------------------------------------------
