#!/usr/bin/python3
# -*- coding: utf-8 -*-
#********************************************************************
# ZYNTHIAN PROJECT: Sketchpad C++ Library Wrapper
#
# A Python wrapper for Sketchpad library
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

            libzl.SyncTimer_setBpm.argtypes = [ctypes.c_uint]

            libzl.SyncTimer_queueClipToStart.argtypes = [ctypes.c_void_p]

            libzl.SyncTimer_queueClipToStartOnChannel.argtypes = [ctypes.c_void_p, ctypes.c_int]

            libzl.SyncTimer_queueClipToStop.argtypes = [ctypes.c_void_p]

            libzl.SyncTimer_queueClipToStopOnChannel.argtypes = [ctypes.c_void_p, ctypes.c_int]

            # libzl.SyncTimer_addToPart.argtypes = [ctypes.c_int, ctypes.c_void_p]
            #
            # libzl.SyncTimer_playPart.argtypes = [ctypes.c_int]
            #
            # libzl.SyncTimer_stopPart.argtypes = [ctypes.c_int]

            libzl.ClipAudioSource_new.argtypes = [ctypes.c_char_p, ctypes.c_bool]
            libzl.ClipAudioSource_new.restype = ctypes.c_void_p

            libzl.ClipAudioSource_play.argtypes = [ctypes.c_void_p, ctypes.c_bool]

            libzl.ClipAudioSource_stop.argtypes = [ctypes.c_void_p]

            libzl.ClipAudioSource_playOnChannel.argtypes = [ctypes.c_void_p, ctypes.c_bool, ctypes.c_int]

            libzl.ClipAudioSource_stopOnChannel.argtypes = [ctypes.c_void_p, ctypes.c_int]

            libzl.ClipAudioSource_getDuration.argtypes = [ctypes.c_void_p]
            libzl.ClipAudioSource_getDuration.restype = ctypes.c_float

            libzl.ClipAudioSource_setProgressCallback.argtypes = [ctypes.c_void_p, AudioLevelChangedCallback]

            libzl.ClipAudioSource_getFileName.argtypes = [ctypes.c_void_p]
            libzl.ClipAudioSource_getFileName.restype = ctypes.c_char_p

            libzl.ClipAudioSource_setStartPosition.argtypes = [ctypes.c_void_p, ctypes.c_float]

            libzl.ClipAudioSource_setLength.argtypes = [ctypes.c_void_p, ctypes.c_float, ctypes.c_int]

            libzl.ClipAudioSource_setPan.argtypes = [ctypes.c_void_p, ctypes.c_float]

            libzl.ClipAudioSource_setSpeedRatio.argtypes = [ctypes.c_void_p, ctypes.c_float]

            libzl.ClipAudioSource_setPitch.argtypes = [ctypes.c_void_p, ctypes.c_float]

            libzl.ClipAudioSource_setGain.argtypes = [ctypes.c_void_p, ctypes.c_float]

            libzl.ClipAudioSource_setVolume.argtypes = [ctypes.c_void_p, ctypes.c_float]

            libzl.ClipAudioSource_setAudioLevelChangedCallback.argtypes = [ctypes.c_void_p, AudioLevelChangedCallback]

            libzl.ClipAudioSource_id.argtypes = [ctypes.c_void_p]
            libzl.ClipAudioSource_id.restypes = ctypes.c_int

            libzl.ClipAudioSource_setSlices.argtypes = [ctypes.c_void_p, ctypes.c_int]

            libzl.ClipAudioSource_keyZoneStart.argtypes = [ctypes.c_void_p]
            libzl.ClipAudioSource_keyZoneStart.restypes = ctypes.c_int
            libzl.ClipAudioSource_setKeyZoneStart.argtypes = [ctypes.c_void_p, ctypes.c_int]

            libzl.ClipAudioSource_keyZoneEnd.argtypes = [ctypes.c_void_p]
            libzl.ClipAudioSource_keyZoneEndrestypes = ctypes.c_int
            libzl.ClipAudioSource_setKeyZoneEnd.argtypes = [ctypes.c_void_p, ctypes.c_int]

            libzl.ClipAudioSource_rootNote.argtypes = [ctypes.c_void_p]
            libzl.ClipAudioSource_rootNote.restypes = ctypes.c_int
            libzl.ClipAudioSource_setRootNote.argtypes = [ctypes.c_void_p, ctypes.c_int]

            libzl.ClipAudioSource_destroy.argtypes = [ctypes.c_void_p]

            libzl.AudioLevels_setRecordGlobalPlayback.argtypes = [ctypes.c_bool]
            libzl.AudioLevels_setGlobalPlaybackFilenamePrefix.argtypes = [ctypes.c_char_p]

            libzl.AudioLevels_setRecordPortsFilenamePrefix.argtypes = [ctypes.c_char_p]
            libzl.AudioLevels_addRecordPort.argtypes = [ctypes.c_char_p, ctypes.c_int]
            libzl.AudioLevels_removeRecordPort.argtypes = [ctypes.c_char_p, ctypes.c_int]
            libzl.AudioLevels_setShouldRecordPorts.argtypes = [ctypes.c_bool]

            libzl.AudioLevels_isRecording.restypes = ctypes.c_bool
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

def reloadZynthianConfiguration():
    if libzl:
        libzl.reloadZynthianConfiguration()

def registerTimerCallback(callback):
    if libzl:
        libzl.SyncTimer_registerTimerCallback(callback)


def registerGraphicTypes():
    if libzl:
        libzl.registerGraphicTypes()


def startTimer(interval: int):
    if libzl:
        libzl.SyncTimer_startTimer(interval)


def setBpm(bpm: int):
    if libzl:
        libzl.SyncTimer_setBpm(bpm)

def stopTimer():
    if libzl:
        libzl.SyncTimer_stopTimer()


def stopClips(clips: list):
    if len(clips) > 0:
        logging.debug(f"{clips[0]}, {clips[0].audioSource}")

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


def AudioLevels_setRecordGlobalPlayback(shouldRecord):
    if libzl:
        libzl.AudioLevels_setRecordGlobalPlayback(shouldRecord)


def AudioLevels_setGlobalPlaybackFilenamePrefix(fileNamePrefix: str):
    if libzl:
        libzl.AudioLevels_setGlobalPlaybackFilenamePrefix(fileNamePrefix.encode())


def AudioLevels_startRecording():
    if libzl:
        libzl.AudioLevels_startRecording()


def AudioLevels_stopRecording():
    if libzl:
        libzl.AudioLevels_stopRecording()


def AudioLevels_isRecording() -> bool:
    if libzl:
        return libzl.AudioLevels_isRecording()


def AudioLevels_setRecordPortsFilenamePrefix(fileNamePrefix: str):
    if libzl:
        libzl.AudioLevels_setRecordPortsFilenamePrefix(fileNamePrefix.encode())


def AudioLevels_addRecordPort(portName: str, channel: int):
    if libzl:
        libzl.AudioLevels_addRecordPort(portName.encode(), channel)


def AudioLevels_removeRecordPort(portName: str, channel: int):
    if libzl:
        libzl.AudioLevels_removeRecordPort(portName.encode(), channel)


def AudioLevels_setShouldRecordPorts(shouldRecord):
    if libzl:
        libzl.AudioLevels_setShouldRecordPorts(shouldRecord)


def AudioLevels_clearRecordPorts():
    if libzl:
        libzl.AudioLevels_clearRecordPorts()


class ClipAudioSource(QObject):
    audioLevelChanged = Signal(float)
    progressChanged = Signal(float)

    def __init__(self, zl_clip, filepath: bytes, muted=False):
        super(ClipAudioSource, self).__init__()

        if libzl:
            self.obj = libzl.ClipAudioSource_new(filepath, muted)

            logging.debug(f"@@@ libzl CLIP OBJ : {self.obj}")

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
        logging.debug(f"Stopping Audio Source : {self.obj}, {libzl}")

        if libzl:
            libzl.ClipAudioSource_stop(self.obj)

    def playOnChannel(self, loop=True, midiChannel=-2):
        if libzl:
            libzl.ClipAudioSource_playOnChannel(self.obj, loop, midiChannel)

    def stopOnChannel(self, midiChannel=-2):
        logging.debug(f"Stopping Audio Source : {self.obj}, {libzl}")

        if libzl:
            libzl.ClipAudioSource_stopOnChannel(self.obj, midiChannel)

    def get_id(self):
        if libzl:
            return libzl.ClipAudioSource_id(self.obj)

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

    def set_pan(self, pan: float):
        if libzl:
            libzl.ClipAudioSource_setPan(self.obj, pan)

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

    def queueClipToStartOnChannel(self, midiChannel):
        if libzl:
            libzl.SyncTimer_queueClipToStartOnChannel(self.obj, midiChannel)

    def queueClipToStop(self):
        if libzl:
            libzl.SyncTimer_queueClipToStop(self.obj)

    def queueClipToStopOnChannel(self, midiChannel):
        if libzl:
            libzl.SyncTimer_queueClipToStopOnChannel(self.obj, midiChannel)

    def setSlices(self, slices : int):
        if libzl:
            libzl.ClipAudioSource_setSlices(self.obj, slices)

    def keyZoneStart(self):
        if libzl:
            return libzl.ClipAudioSource_keyZoneStart(self.obj)

    def setKeyZoneStart(self, keyZoneStart):
        if libzl:
            libzl.ClipAudioSource_setKeyZoneStart(self.obj, keyZoneStart)

    def keyZoneEnd(self):
        if libzl:
            return libzl.ClipAudioSource_keyZoneEnd(self.obj)

    def setKeyZoneEnd(self, keyZoneEnd):
        if libzl:
            libzl.ClipAudioSource_setKeyZoneEnd(self.obj, keyZoneEnd)

    def rootNote(self):
        if libzl:
            return libzl.ClipAudioSource_rootNote(self.obj)

    def setRootNote(self, rootNote):
        if libzl:
            libzl.ClipAudioSource_setRootNote(self.obj, rootNote)

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
