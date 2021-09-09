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
import logging
from os.path import dirname, realpath

from PySide2.QtCore import QProcess

libzl = None

def init():
    global libzl

    try:
        libzl = ctypes.cdll.LoadLibrary(dirname(realpath(__file__)) + "/prebuilt/libzl.so")

        ### Type Definition
        libzl.stopClips.argTypes = [ctypes.c_int, ]

        libzl.SyncTimer_startTimer.argtypes = [ctypes.c_int]

        libzl.SyncTimer_queueClipToStart.argtypes = [ctypes.c_void_p]

        libzl.SyncTimer_queueClipToStop.argtypes = [ctypes.c_void_p]

        # libzl.SyncTimer_addToPart.argtypes = [ctypes.c_int, ctypes.c_void_p]
        #
        # libzl.SyncTimer_playPart.argtypes = [ctypes.c_int]
        #
        # libzl.SyncTimer_stopPart.argtypes = [ctypes.c_int]

        libzl.ClipAudioSource_new.argtypes = [ctypes.c_char_p]
        libzl.ClipAudioSource_new.restype = ctypes.c_void_p

        libzl.ClipAudioSource_play.argtypes = [ctypes.c_void_p, ctypes.c_bool]

        libzl.ClipAudioSource_stop.argtypes = [ctypes.c_void_p]

        libzl.ClipAudioSource_getDuration.argtypes = [ctypes.c_void_p]
        libzl.ClipAudioSource_getDuration.restype = ctypes.c_float

        libzl.ClipAudioSource_setProgressCallback.argtypes = [ctypes.c_void_p, ctypes.py_object, ctypes.CFUNCTYPE(None, ctypes.py_object)]

        libzl.ClipAudioSource_getProgress.argtypes = [ctypes.c_void_p]
        libzl.ClipAudioSource_getProgress.restype = ctypes.c_float

        libzl.ClipAudioSource_getFileName.argtypes = [ctypes.c_void_p]
        libzl.ClipAudioSource_getFileName.restype = ctypes.c_char_p

        libzl.ClipAudioSource_setStartPosition.argtypes = [ctypes.c_void_p, ctypes.c_float]

        libzl.ClipAudioSource_setLength.argtypes = [ctypes.c_void_p, ctypes.c_float]

        libzl.ClipAudioSource_setSpeedRatio.argtypes = [ctypes.c_void_p, ctypes.c_float]

        libzl.ClipAudioSource_setPitch.argtypes = [ctypes.c_void_p, ctypes.c_float]

        libzl.ClipAudioSource_setGain.argtypes = [ctypes.c_void_p, ctypes.c_float]

        libzl.ClipAudioSource_destroy.argtypes = [ctypes.c_void_p]
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


def stopClips(clips: list):
    if len(clips) > 0:
        logging.error(f"{clips[0]}, {clips[0].audioSource}")

        arr = (ctypes.c_void_p * len(clips))()
        arr[:] = [c.audioSource.obj for c in clips]

        if libzl:
            libzl.stopClips(len(clips), arr)


# def add_clip_to_part(partIndex, clip):
#     if libzl:
#         libzl.SyncTimer_addToPart(partIndex, clip)
#
#
# def play_part(partIndex):
#     if libzl:
#         libzl.SyncTimer_playPart(partIndex)
#
#
# def stop_part(partIndex):
#     if libzl:
#         libzl.SyncTimer_stopPart(partIndex)

@ctypes.CFUNCTYPE(None, ctypes.py_object)
def signal_progress(obj):
    obj.progress_changed.emit()

class ClipAudioSource(object):

    def __init__(self, zl_clip, filepath: bytes):
        if libzl:
            self.obj = libzl.ClipAudioSource_new(filepath)

            if zl_clip is not None:
                libzl.ClipAudioSource_setProgressCallback(self.obj, zl_clip, signal_progress)

    def get_progress(self):
        if libzl:
            return libzl.ClipAudioSource_getProgress(self.obj)

    def play(self, loop=True):
        if libzl:
            libzl.ClipAudioSource_play(self.obj, loop)

    def stop(self):
        logging.error(f"Stopping Audio Source : {self.obj}, {libzl}")

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

    def set_gain(self, gain: float):
        if libzl:
            libzl.ClipAudioSource_setGain(self.obj, gain)

    def set_speed_ratio(self, speed_ratio: float):
        if libzl:
            libzl.ClipAudioSource_setSpeedRatio(self.obj, speed_ratio)

    def queueClipToStart(self):
        if libzl:
            libzl.SyncTimer_queueClipToStart(self.obj)

    def queueClipToStop(self):
        if libzl:
            libzl.SyncTimer_queueClipToStop(self.obj)

    def destroy(self):
        if libzl:
            libzl.ClipAudioSource_destroy(self.obj)

    # def start_recording(self):
    #     if self.can_record:
    #         self.recorder_process.startDetached("/usr/local/bin/jack_capture", ["--daemon", self.recording_file_url])
    #
    # def stop_recording(self):
    #     if self.can_record:
    #         self.recorder_process.kill()

