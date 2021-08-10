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


def init():
    global libzl
    try:
        libzl = ctypes.cdll.LoadLibrary(dirname(realpath(__file__)) + "/prebuilt/libzl.so")
        libzl.init()
    except Exception as e:
        libzl = None
        print(f"Can't initialise zynseq library: {str(e)}")


def playWav():
    if libzl:
        libzl.playWav()


def stopWav():
    if libzl:
        libzl.stopWav()
