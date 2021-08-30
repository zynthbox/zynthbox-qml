#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthian PlayGrid: A page to play ntoes with buttons
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
import ctypes as ctypes
import math
import sys

from PySide2.QtCore import Property, QObject, QProcess, QTimer, Signal, Slot

sys.path.insert(1, "./libzl")
from .libzl import libzl
from .libzl import zynthiloops_song
from .libzl import zynthiloops_clip

from datetime import  datetime

from .. import zynthian_qt_gui_base


@ctypes.CFUNCTYPE(None)
def cb():
    zynthian_gui_zynthiloops.__instance__.metronome_update()


class zynthian_gui_zynthiloops(zynthian_qt_gui_base.ZynGui):
    __instance__ = None

    def __init__(self, parent=None):
        super(zynthian_gui_zynthiloops, self).__init__(parent)
        zynthian_gui_zynthiloops.__instance__ = self
        self.recorder_process = None
        self.clip_to_record = None
        self.start_clip_recording = False
        self.__current_beat__ = -1
        self.__current_bar__ = -1
        self.metronome_schedule_stop = False
        self.metronome_running_refcount = 0
        self.__sketch_basepath__ = "/zynthian/zynthian-my-data/sketches/"
        self.__song__ = zynthiloops_song.zynthiloops_song(self.__sketch_basepath__, self)
        self.__song__.bpm_changed.connect(self.update_timer_bpm)
        self.__clips_queue__: list[zynthiloops_clip] = []
        self.recorder_process = None

        libzl.registerTimerCallback(cb)
        libzl.registerGraphicTypes()

    def recording_process_started(self):
        logging.error(f"Started recording {self} at {self.clip_to_record}")

    def recording_process_stopped(self, exitCode, exitStatus):
        logging.error(f"Stopped recording {self} : Code({exitCode}), Status({exitStatus})")
        logging.error(f"Recording Process Output : {self.recorder_process.readAll()}")

    def recording_process_errored(self, error):
        logging.error(f"Error recording {self} : Error({error})")

    def show(self):
        pass

    @Signal
    def current_beat_changed(self):
        pass

    @Signal
    def current_bar_changed(self):
        pass

    @Signal
    def metronome_running_changed(self):
        pass

    @Signal
    def song_changed(self):
        pass

    @Property(QObject, notify=song_changed)
    def song(self):
        return self.__song__

    @Slot(None)
    def clearCurrentSketch(self):
        self.__song__.destroy()
        self.__song__ = zynthiloops_song.zynthiloops_song(self.__sketch_basepath__, self)
        self.song_changed.emit()

    def update_timer_bpm(self):
        if self.metronome_running_refcount > 0:
            libzl.startTimer(math.floor((60.0 / self.__song__.__bpm__) * 1000))

    def queue_clip_record(self, clip):
        self.clip_to_record = clip
        self.start_clip_recording = True
        self.start_metronome_request()

    def start_metronome_request(self):
        self.metronome_running_refcount += 1

        logging.error(f"Start Metronome Request : refcount({self.metronome_running_refcount}), metronome_schedule_stop({self.metronome_schedule_stop}")

        if self.metronome_running_refcount == 1:
            if self.metronome_schedule_stop:
                # Metronome is already running and scheduled to stop.
                # Do not start timer again and remove stop schedule
                self.metronome_schedule_stop = False
            else:
                libzl.startTimer(math.floor((60.0 / self.__song__.__bpm__) * 1000))
                self.metronome_running_changed.emit()

    def stop_metronome_request(self):
        self.metronome_running_refcount = max(self.metronome_running_refcount - 1, 0)

        logging.error(f"Stop Metronome Request : refcount({self.metronome_running_refcount}), metronome_schedule_stop({self.metronome_schedule_stop}")

        if self.metronome_running_refcount == 0:
            self.metronome_schedule_stop = True

    def metronome_update(self):
        self.current_beat_changed.emit()
        self.__current_beat__ = (self.__current_beat__ + 1) % 4

        if self.__current_beat__ == 0:
            if self.clip_to_record is not None:
                if self.start_clip_recording:
                    self.recorder_process = QProcess()
                    # self.recorder_process.started.connect(lambda: self.recording_process_started())
                    # self.recorder_process.finished.connect(
                    #     lambda exitCode, exitStatus: self.recording_process_stopped(exitCode, exitStatus))
                    # self.recorder_process.errorOccurred.connect(lambda error: self.recording_process_errored(error))
                    self.recorder_process.start("/usr/local/bin/jack_capture", ["--daemon", self.clip_to_record.recording_path])
                    logging.error(f"Recording clip to {self.clip_to_record.recording_path}")
                    self.start_clip_recording = False
                    self.clip_to_record.isRecording = True
                else:
                    self.recorder_process.terminate()
                    self.clip_to_record.loadRecordedFile()
                    self.clip_to_record.isRecording = False
                    self.clip_to_record = None
                    self.stop_metronome_request()

            if self.metronome_schedule_stop:
                libzl.stopTimer()
                self.metronome_running_changed.emit()

                self.__current_beat__ = -1
                self.__current_bar__ = -1
                self.current_beat_changed.emit()
                self.current_bar_changed.emit()
                self.metronome_schedule_stop = False
            else:
                self.__current_bar__ += 1
                self.current_bar_changed

        #if self.__song__.isPlaying:
            #self.__song__.metronome_update()

    @Property(int, notify=current_beat_changed)
    def currentBeat(self):
        return self.__current_beat__

    @Property(int, notify=current_bar_changed)
    def currentBar(self):
        return self.__current_bar__

    @Property(bool, notify=metronome_running_changed)
    def isMetronomeRunning(self):
        if self.metronome_running_refcount > 0:
            return True
        elif self.metronome_running_refcount == 0 and self.metronome_schedule_stop:
            return True
        else:
            return False


