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
import re
import sys
from datetime import datetime
from os.path import dirname, realpath
from pathlib import Path
from time import sleep
import json

from PySide2.QtCore import Property, QObject, QProcess, QTimer, Signal, Slot

from .libzl.libzl import ClipAudioSource

sys.path.insert(1, "./libzl")
from .libzl import libzl
from .libzl import zynthiloops_song
from .libzl import zynthiloops_clip

from .. import zynthian_qt_gui_base

import jack


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
        self.clip_to_record_path = None
        self.clip_to_record_path = None
        self.start_clip_recording = False
        self.__current_beat__ = -1
        self.__current_bar__ = -1
        self.metronome_schedule_stop = False
        self.metronome_running_refcount = 0
        self.__sketch_basepath__ = "/zynthian/zynthian-my-data/sketches/"
        self.__song__ = zynthiloops_song.zynthiloops_song(self.__sketch_basepath__, self)
        self.__song__.bpm_changed.connect(self.update_timer_bpm)
        self.__clips_queue__: list[zynthiloops_clip] = []
        self.is_recording_complete = False
        self.recording_count_in_value = 0
        self.recording_complete.connect(lambda: self.load_recorded_file_to_clip())
        self.click_track_click = ClipAudioSource(None, (dirname(realpath(__file__)) + "/assets/click_track_click.wav").encode('utf-8'))
        self.click_track_clack = ClipAudioSource(None, (dirname(realpath(__file__)) + "/assets/click_track_clack.wav").encode('utf-8'))
        self.click_track_enabled = False
        self.jack_client = jack.Client('zynthiloops_client')
        self.jack_capture_port = self.jack_client.inports.register(f"capture_port")
        self.recorder_process = None
        self.recorder_process_arguments = ["--port", self.jack_capture_port.name]

        libzl.registerTimerCallback(cb)
        libzl.registerGraphicTypes()

        # self.update_recorder_jack_port()
        self.zyngui.screens['layer'].current_index_changed.connect(lambda: self.update_recorder_jack_port())

        self.update_timer_bpm()

    @Signal
    def click_track_enabled_changed(self):
        pass

    def get_clickTrackEnabled(self):
        return self.click_track_enabled

    def set_clickTrackEnabled(self, enabled: bool):
        self.click_track_enabled = enabled

        if enabled:
            self.click_track_click.set_length((60.0 / self.__song__.__bpm__) * 4)
            self.click_track_clack.set_length((60.0 / self.__song__.__bpm__))

            self.click_track_click.queueClipToStart()
            self.click_track_clack.queueClipToStart()
        else:
            self.click_track_click.queueClipToStop()
            self.click_track_clack.queueClipToStop()

        self.click_track_enabled_changed.emit()

    clickTrackEnabled = Property(bool, get_clickTrackEnabled, set_clickTrackEnabled, notify=click_track_enabled_changed)

    def track_layers_snapshot(self):
        snapshot = []
        for i in range(5, 10):
            if i in self.zyngui.screens['layer'].layer_midi_map:
                layer_to_copy = self.zyngui.screens['layer'].layer_midi_map[i]
                snapshot.append(layer_to_copy.get_snapshot())
        return snapshot

    @Slot(int)
    def saveLayersToTrack(self, tid):
        if tid < 0 or tid >= self.__song__.tracksModel.count:
            return
        track_layers_snapshot = self.track_layers_snapshot()
        logging.error(track_layers_snapshot)
        self.__song__.tracksModel.getTrack(tid).set_layers_snapshot(track_layers_snapshot)
        self.__song__.schedule_save()

    @Slot(int)
    def restoreLayersFromTrack(self, tid):
        if tid < 0 or tid >= self.__song__.tracksModel.count:
            return
        for i in range(5, 10):
            if i in self.zyngui.screens['layer'].layer_midi_map:
                self.zyngui.screens['layer'].remove_root_layer(self.zyngui.screens['layer'].root_layers.index(self.zyngui.screens['layer'].layer_midi_map[i]), True)
        self.zyngui.screens['layer'].load_channels_snapshot(self.__song__.tracksModel.getTrack(tid).get_layers_snapshot(), 5, 9)
        self.zyngui.screens['layer'].ensure_special_layers_midi_cloned()


    # @Signal
    # def count_in_value_changed(self):
    #     pass
    #
    # def get_countInValue(self):
    #     return self.recording_count_in_value
    #
    # def set_countInValue(self, value):
    #     self.recording_count_in_value = value
    #     self.count_in_value_changed.emit()
    #
    # countInValue = Property(int, get_countInValue, set_countInValue, notify=count_in_value_changed)

    def update_recorder_jack_port(self):
        self.jack_client.deactivate()
        self.jack_client.activate()

        for port in self.jack_client.get_ports(is_audio=True, is_output=True):
            if not (port.name.startswith("JUCE") or port.name.startswith("system")):#port.name.startswith(jack_basename):
                logging.error("ACCEPTED {}".format(port.name))
                # self.recorder_process_arguments.append("--port")
                # self.recorder_process_arguments.append(port.name)
                try:
                    self.jack_client.connect(port.name, self.jack_capture_port.name)
                except:
                    logging.error(f"Error connecting to jack port : {port.name}")
            else:
                logging.error("REJECTED {}".format(port.name))

        # logging.error(f"##### Recorder Process Arguments : {self.recorder_process_arguments}")

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

    @Signal
    def recording_complete(self):
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
            self.set_clickTrackEnabled(self.click_track_enabled)

            libzl.startTimer(math.floor((60.0 / self.__song__.__bpm__) * 1000))

    def queue_clip_record(self, clip):
        self.update_recorder_jack_port()
        self.clip_to_record = clip
        self.clip_to_record_path = "/zynthian/zynthian-my-data/capture/"+self.clip_to_record.name+"_"+datetime.now().strftime("%Y-%m-%d_%H-%M-%S")+".wav"
        #self.countInValue = countInBars * 4

        self.recorder_process = QProcess()
        self.recorder_process.setProgram("/usr/local/bin/jack_capture")
        self.recorder_process.setArguments([*self.recorder_process_arguments, self.clip_to_record_path])
        # self.recorder_process.started.connect(lambda: self.recording_process_started())
        # self.recorder_process.finished.connect(
        #     lambda exitCode, exitStatus: self.recording_process_stopped(exitCode, exitStatus))
        # self.recorder_process.errorOccurred.connect(lambda error: self.recording_process_errored(error))
        logging.error(
            f"Command jack_capture : /usr/local/bin/jack_capture {self.recorder_process_arguments} {self.clip_to_record_path}")

        self.is_recording_complete = False
        self.start_clip_recording = True
        self.clip_to_record.isRecording = True
        self.start_metronome_request()

    def stop_recording(self):
        self.recorder_process.terminate()
        self.clip_to_record.isRecording = False
        self.is_recording_complete = True
        self.stop_metronome_request()
        self.recording_complete.emit()

    def start_metronome_request(self):
        self.metronome_running_refcount += 1

        logging.error(f"Start Metronome Request : refcount({self.metronome_running_refcount}), metronome_schedule_stop({self.metronome_schedule_stop}")

        if self.metronome_running_refcount == 1:
            if self.metronome_schedule_stop:
                # Metronome is already running and scheduled to stop.
                # Do not start timer again and remove stop schedule
                self.metronome_schedule_stop = False
            else:
                if self.click_track_enabled:
                    self.click_track_click.queueClipToStart()
                    self.click_track_clack.queueClipToStart()

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

        # if self.countInValue > 0:
        #     self.countInValue -= 1

        if self.__current_beat__ == 0:
            if self.clip_to_record is not None and self.is_recording_complete is False: # and self.countInValue <= 0:
                if self.start_clip_recording:
                    self.recorder_process.start()
                    self.start_clip_recording = False

            if self.metronome_schedule_stop:
                libzl.stopTimer()
                self.metronome_running_changed.emit()

                self.click_track_click.stop()
                self.click_track_clack.stop()
                self.__current_beat__ = -1
                self.__current_bar__ = -1
                self.current_beat_changed.emit()
                self.current_bar_changed.emit()
                self.metronome_schedule_stop = False
            else:
                self.__current_bar__ += 1
                self.current_bar_changed

        #if self.__song__.isPlaying:
            #self.__song__.metronome_update

    def load_recorded_file_to_clip(self):
        while not Path(self.clip_to_record_path).exists():
            sleep(0.1)

        layer_index = self.zyngui.screens['layer'].get_layer_selected()
        selected_layer = self.zyngui.screens['layer'].root_layers[layer_index].get_snapshot()

        logging.error(f"Selected Layer Snapshot : {json.dumps(selected_layer)}")

        self.clip_to_record.path = self.clip_to_record_path
        self.clip_to_record.write_metadata("ZYNTHBOX_LAYERS", [json.dumps(self.track_layers_snapshot())])
        self.clip_to_record.write_metadata("ZYNTHBOX_ACTIVELAYER", [json.dumps(selected_layer)])
        self.clip_to_record = None
        self.clip_to_record_path = None
        self.recorder_process = None
        self.__song__.save()

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


