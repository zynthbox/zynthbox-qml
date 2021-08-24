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

        ### Type Definition
        libzl.SyncTimer_startTimer.argtypes = [ctypes.c_int]

        libzl.SyncTimer_addClip.argtypes = [ctypes.c_void_p]

        libzl.SyncTimer_removeClip.argtypes = [ctypes.c_void_p]

        libzl.ClipAudioSource_new.argtypes = [ctypes.c_char_p]
        libzl.ClipAudioSource_new.restype = ctypes.c_void_p

        libzl.ClipAudioSource_play.argtypes = [ctypes.c_void_p, ctypes.c_bool]

        libzl.ClipAudioSource_stop.argtypes = [ctypes.c_void_p]

        libzl.ClipAudioSource_getDuration.argtypes = [ctypes.c_void_p]
        libzl.ClipAudioSource_getDuration.restype = ctypes.c_float

        libzl.ClipAudioSource_getFileName.argtypes = [ctypes.c_void_p]
        libzl.ClipAudioSource_getFileName.restype = ctypes.c_char_p

        libzl.ClipAudioSource_setStartPosition.argtypes = [ctypes.c_void_p, ctypes.c_float]

        libzl.ClipAudioSource_setLength.argtypes = [ctypes.c_void_p, ctypes.c_float]

        libzl.ClipAudioSource_setSpeedRatio.argtypes = [ctypes.c_void_p, ctypes.c_float]

        libzl.ClipAudioSource_setPitch.argtypes = [ctypes.c_void_p, ctypes.c_float]
        ### END Type Definition

        # Start juce event loop
        libzl.initJuce()
    except Exception as e:
        libzl = None
        print(f"Can't initialise libzl library: {str(e)}")


def registerTimerCallback(callback):
    if libzl:
        libzl.SyncTimer_registerTimerCallback(callback)

def registerGraphicTypes():
    if libzl:
        libzl.registerGraphicTypes()

def startTimer(interval: int):
    if libzl:
        libzl.SyncTimer_startTimer(interval)


def stopTimer():
    if libzl:
        libzl.SyncTimer_stopTimer()


class ClipAudioSource(object):
    def __init__(self, filepath: bytes):
        if libzl:
            self.obj = libzl.ClipAudioSource_new(filepath)

    def play(self, should_loop=True):
        if libzl:
            libzl.ClipAudioSource_play(self.obj, should_loop)

    def stop(self):
        if libzl:
            libzl.ClipAudioSource_stop(self.obj)

    def get_duration(self):
        if libzl:
            return libzl.ClipAudioSource_getDuration(self.obj)

    def get_filename(self):
        if libzl:
            return libzl.ClipAudioSource_getFileName(self.obj)

    def set_start_position(self, start_position_in_seconds: float):
        if libzl:
            libzl.ClipAudioSource_setStartPosition(self.obj, start_position_in_seconds)

    def set_length(self, length_in_seconds: float):
        if libzl:
            libzl.ClipAudioSource_setLength(self.obj, length_in_seconds)

    def set_pitch(self, pitch: float):
        if libzl:
            libzl.ClipAudioSource_setPitch(self.obj, pitch)

    def set_speed_ratio(self, speed_ratio: float):
        if libzl:
            libzl.ClipAudioSource_setSpeedRatio(self.obj, speed_ratio)

    def addClipToTimer(self):
        if libzl:
            libzl.SyncTimer_addClip(self.obj)

    def removeClipFromTimer(self):
        if libzl:
            libzl.SyncTimer_removeClip(self.obj)
