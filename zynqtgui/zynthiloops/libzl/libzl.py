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

from PySide2.QtCore import Property, QObject, QProcess, Signal
from PySide2.QtQml import QQmlEngine

libzl = None
AudioLevelChangedCallback = ctypes.CFUNCTYPE(None, ctypes.c_float)
ProgressChangedCallback = ctypes.CFUNCTYPE(None, ctypes.c_float)

def init():
    global libzl

    try:
        libzl = ctypes.cdll.LoadLibrary("libzl.so")
    except Exception as e:
        print(f"Could not load the libzl shared library (at a guess, the libzl package has not been installed): {str(e)}")

    if not libzl is None:
        try:
            ### Type Definition
            libzl.stopClips.argTypes = [ctypes.c_int]

            libzl.dBFromVolume.argtypes = [ctypes.c_float]
            libzl.dBFromVolume.restype = ctypes.c_float

            libzl.SyncTimer_instance.restype = ctypes.c_void_p

            libzl.SyncTimer_startTimer.argtypes = [ctypes.c_int]

            libzl.SyncTimer_queueClipToStart.argtypes = [ctypes.c_void_p]

            libzl.SyncTimer_queueClipToStop.argtypes = [ctypes.c_void_p]

            # libzl.SyncTimer_addToPart.argtypes = [ctypes.c_int, ctypes.c_void_p]
            #
            # libzl.SyncTimer_playPart.argtypes = [ctypes.c_int]
            #
            # libzl.SyncTimer_stopPart.argtypes = [ctypes.c_int]

            libzl.ClipAudioSource_new.argtypes = [ctypes.c_char_p, ctypes.c_bool]
            libzl.ClipAudioSource_new.restype = ctypes.c_void_p

            libzl.ClipAudioSource_play.argtypes = [ctypes.c_void_p, ctypes.c_bool]

            libzl.ClipAudioSource_stop.argtypes = [ctypes.c_void_p]

            libzl.ClipAudioSource_getDuration.argtypes = [ctypes.c_void_p]
            libzl.ClipAudioSource_getDuration.restype = ctypes.c_float

            libzl.ClipAudioSource_setProgressCallback.argtypes = [ctypes.c_void_p, AudioLevelChangedCallback]

            libzl.ClipAudioSource_getFileName.argtypes = [ctypes.c_void_p]
            libzl.ClipAudioSource_getFileName.restype = ctypes.c_char_p

            libzl.ClipAudioSource_setStartPosition.argtypes = [ctypes.c_void_p, ctypes.c_float]

            libzl.ClipAudioSource_setLength.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int]

            libzl.ClipAudioSource_setSpeedRatio.argtypes = [ctypes.c_void_p, ctypes.c_float]

            libzl.ClipAudioSource_setPitch.argtypes = [ctypes.c_void_p, ctypes.c_float]

            libzl.ClipAudioSource_setGain.argtypes = [ctypes.c_void_p, ctypes.c_float]

            libzl.ClipAudioSource_setVolume.argtypes = [ctypes.c_void_p, ctypes.c_float]

            libzl.ClipAudioSource_setAudioLevelChangedCallback.argtypes = [ctypes.c_void_p, AudioLevelChangedCallback]

            libzl.ClipAudioSource_destroy.argtypes = [ctypes.c_void_p]
            ### END Type Definition

            # Start juce event loop
            libzl.initJuce()
        except Exception as e:
            libzl = None
            print(f"Failed to initialise libzl library: {str(e)}")


@ctypes.CFUNCTYPE(ctypes.c_void_p)
def getSyncTimerInstance():
    if libzl:
        return libzl.SyncTimer_instance()


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


def dbFromVolume(vol: float):
    if libzl:
        return libzl.dBFromVolume(vol)


def setRecordingAudioLevelCallback(cb):
    if libzl:
        libzl.setRecordingAudioLevelCallback(cb)


class ClipAudioSource(QObject):
    audioLevelChanged = Signal(float)
    progressChanged = Signal(float)

    def __init__(self, zl_clip, filepath: bytes, muted=False):
        super(ClipAudioSource, self).__init__()

        if libzl:
            self.obj = libzl.ClipAudioSource_new(filepath, muted)

            logging.error(f"@@@ libzl CLIP OBJ : {self.obj}")

            if zl_clip is not None:
                self.audio_level_changed_callback = AudioLevelChangedCallback(self.audio_level_changed_callback)
                self.progress_changed_callback = ProgressChangedCallback(self.progress_changed_callback)

                libzl.ClipAudioSource_setProgressCallback(self.obj, self.progress_changed_callback)
                libzl.ClipAudioSource_setAudioLevelChangedCallback(self.obj, self.audio_level_changed_callback)

    def audio_level_changed_callback(self, level_db):
        self.audioLevelChanged.emit(level_db)

    def progress_changed_callback(self, progress):
        self.progressChanged.emit(progress)

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

    def set_length(self, length: int, bpm: int):
        if libzl:
            libzl.ClipAudioSource_setLength(self.obj, length, bpm)

    def set_pitch(self, pitch: float):
        if libzl:
            libzl.ClipAudioSource_setPitch(self.obj, pitch)

    def set_gain(self, gain: float):
        if libzl:
            libzl.ClipAudioSource_setGain(self.obj, gain)

    def set_volume(self, volume: float):
        if libzl:
            libzl.ClipAudioSource_setVolume(self.obj, volume)

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

    def get_cpp_obj(self):
        return self.obj

    # def start_recording(self):
    #     if self.can_record:
    #         self.recorder_process.startDetached("/usr/local/bin/jack_capture", ["--daemon", self.recording_file_url])
    #
    # def stop_recording(self):
    #     if self.can_record:
    #         self.recorder_process.kill()
