#!/usr/bin/python3
# -*- coding: utf-8 -*-
#********************************************************************
# ZYNTHIAN PROJECT: ZynthiLoops C++ Library Wrapper
#
# A Python wrapper for ZynthiLoops library
#
# Copyright (C) 2021 Brian Walton <brian@riban.co.uk>
#
#********************************************************************
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
#********************************************************************

import ctypes
from os.path import dirname, realpath

libzl = None

try:
    libzl = ctypes.cdll.LoadLibrary(dirname(realpath(__file__)) + "/prebuilt/libzl.so")
except Exception as e:
    libzl = None
    print(f"Can't initialise libzl library: {str(e)}")


class libzlClip(object):
    def __init__(self, filepath: bytes):
        libzl.ZynthiLoopsComponent_new.restype = ctypes.c_void_p
        libzl.ZynthiLoopsComponent_new.argtypes = [ctypes.c_char_p]

        libzl.ZynthiLoopsComponent_getDuration.restype = ctypes.c_float
        libzl.ZynthiLoopsComponent_getFileName.restype = ctypes.c_char_p
        libzl.ZynthiLoopsComponent_setStartPosition.argtypes = [ctypes.c_void_p, ctypes.c_float]

        self.obj = libzl.ZynthiLoopsComponent_new(filepath)

    def play(self):
        libzl.ZynthiLoopsComponent_play(self.obj)

    def stop(self):
        return libzl.ZynthiLoopsComponent_stop(self.obj)

    def get_duration(self):
        return libzl.ZynthiLoopsComponent_getDuration(self.obj)

    def get_filename(self):
        return libzl.ZynthiLoopsComponent_getFileName(self.obj)

    def set_start_position(self, startPositionInSeconds: float):
        libzl.ZynthiLoopsComponent_setStartPosition(self.obj, startPositionInSeconds)
