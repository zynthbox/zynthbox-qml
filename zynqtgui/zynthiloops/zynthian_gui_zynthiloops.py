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
import os.path
import re
import shutil
import sys
import uuid
from datetime import datetime
from os.path import dirname, realpath
from pathlib import Path
from subprocess import Popen
from time import sleep
import json

import numpy as np
from PySide2.QtCore import Property, QObject, QProcess, QTimer, Signal, Slot

from .libzl.libzl import ClipAudioSource

sys.path.insert(1, "./libzl")
from .libzl import libzl
from .libzl import zynthiloops_song
from .libzl import zynthiloops_clip

from .. import zynthian_qt_gui_base

import jack


@ctypes.CFUNCTYPE(None, ctypes.c_int)
def cb(beat):
    if beat % 32 == 0:
        zynthian_gui_zynthiloops.__instance__.metronomeBeatUpdate4th.emit(beat / 32)

    if beat % 16 == 0:
        zynthian_gui_zynthiloops.__instance__.metronomeBeatUpdate8th.emit(beat / 16)

    if beat % 8 == 0:
        zynthian_gui_zynthiloops.__instance__.metronomeBeatUpdate16th.emit(beat / 8)

    if beat % 4 == 0:
        zynthian_gui_zynthiloops.__instance__.metronomeBeatUpdate32th.emit(beat / 4)

    if beat % 2 == 0:
        zynthian_gui_zynthiloops.__instance__.metronomeBeatUpdate64th.emit(beat / 2)

    zynthian_gui_zynthiloops.__instance__.metronomeBeatUpdate128th.emit(beat)


class zynthian_gui_zynthiloops(zynthian_qt_gui_base.ZynGui):
    __instance__ = None

    def __init__(self, parent=None):
        super(zynthian_gui_zynthiloops, self).__init__(parent)
        zynthian_gui_zynthiloops.__instance__ = self
        self.recorder_process = None
        self.clip_to_record = None
        self.clip_to_record_path = None
        self.clip_to_record_path = None
        self.__current_beat__ = -1
        self.__current_bar__ = -1
        self.metronome_schedule_stop = False
        self.metronome_running_refcount = 0
        self.__sketch_basepath__ = Path("/zynthian/zynthian-my-data/sketches/")
        self.__clips_queue__: list[zynthiloops_clip] = []
        self.is_recording_complete = False
        self.recording_count_in_value = 0
        self.recording_complete.connect(lambda: self.load_recorded_file_to_clip())
        self.click_track_click = ClipAudioSource(None, (dirname(realpath(__file__)) + "/assets/click_track_click.wav").encode('utf-8'))
        self.click_track_clack = ClipAudioSource(None, (dirname(realpath(__file__)) + "/assets/click_track_clack.wav").encode('utf-8'))
        self.click_track_enabled = False
        self.jack_client = jack.Client('zynthiloops_client')
        self.jack_capture_port_a = self.jack_client.inports.register(f"capture_port_a")
        self.jack_capture_port_b = self.jack_client.inports.register(f"capture_port_b")
        self.recorder_process = None
        self.recorder_process_internal_arguments = ["--daemon", "--port", f"{self.jack_client.name}:*"]
        self.__last_recording_type__ = ""
        self.__capture_audio_level_left__ = -200
        self.__capture_audio_level_right__ = -200

        self.__master_audio_level__ = -200
        self.master_audio_level_timer = QTimer()
        self.master_audio_level_timer.setInterval(50)
        self.master_audio_level_timer.timeout.connect(self.master_volume_level_timer_timeout)

        self.__song__ = zynthiloops_song.zynthiloops_song(str(self.__sketch_basepath__ / "temp") + "/", "Sketch-1", self)
        self.__song__.bpm_changed.connect(self.update_timer_bpm)

        libzl.registerTimerCallback(cb)
        libzl.registerGraphicTypes()

        self.metronomeBeatUpdate4th.connect(self.metronome_update)

        self.zyngui.master_alsa_mixer.volume_changed.connect(lambda: self.master_volume_changed.emit())

        self.update_timer_bpm()

    @Slot(None)
    def monitorCaptureAudioLevels(self):
        client = jack.Client('zynthiloops_monitor')
        port_l = client.inports.register("l")
        port_r = client.inports.register("r")

        def convertToDBFS(raw):
            if raw <= 0:
                return -200
            fValue = 20 * math.log10(raw)
            if fValue < -200:
                fValue = -200
            return fValue

        @client.set_process_callback
        def process(frames):
            buf_l = np.frombuffer(port_l.get_buffer())
            buf_r = np.frombuffer(port_r.get_buffer())
            raw_peak_l = 0
            raw_peak_r = 0

            for i in range(0, frames):
                try:
                    sample_l = abs(buf_l[i])
                    sample_r = abs(buf_r[i])

                    if sample_l > raw_peak_l:
                        raw_peak_l = sample_l
                    if sample_r > raw_peak_r:
                        raw_peak_r = sample_r
                except:
                    pass

            if raw_peak_l < 0.0:
                raw_peak_l = 0.0
            if raw_peak_r < 0.0:
                raw_peak_r = 0.0

            db_left = convertToDBFS(raw_peak_l)
            db_right = convertToDBFS(raw_peak_r)

            if self.__capture_audio_level_left__ != db_left:
                self.__capture_audio_level_left__ = db_left
                self.capture_audio_level_left_changed.emit()
            if self.__capture_audio_level_right__ != db_right:
                self.__capture_audio_level_right__ = db_right
                self.capture_audio_level_right_changed.emit()

        client.activate()

        client.connect("system:capture_1", port_l.name)
        client.connect("system:capture_2", port_r.name)

    def back_action(self):
        return "zynthiloops"

    ### Property captureAudioLevelLeft
    def get_capture_audio_level_left(self):
        return self.__capture_audio_level_left__
    capture_audio_level_left_changed = Signal()
    captureAudioLevelLeft = Property(float, get_capture_audio_level_left, notify=capture_audio_level_left_changed)
    ### END Property captureAudioLevelLeft

    ### Property captureAudioLevelRight
    def get_capture_audio_level_right(self):
        return self.__capture_audio_level_right__
    capture_audio_level_right_changed = Signal()
    captureAudioLevelRight = Property(float, get_capture_audio_level_right, notify=capture_audio_level_right_changed)
    ### END Property captureAudioLevelRight

    @Slot(None)
    def startMonitorMasterAudioLevels(self):
        self.master_audio_level_timer.start()

    @Slot(None)
    def stopMonitorMasterAudioLevels(self):
        self.master_audio_level_timer.stop()

    def master_volume_level_timer_timeout(self):
        added_db = 0
        for i in range(0, self.__song__.tracksModel.count):
            track = self.__song__.tracksModel.getTrack(i)
            added_db += pow(10, track.get_audioLevel()/10)

        self.set_master_audio_level(10*math.log10(added_db))

    ### Property masterAudioLevel
    def get_master_audio_level(self):
        return self.__master_audio_level__
    def set_master_audio_level(self, level):
        self.__master_audio_level__ = level
        self.master_audio_level_changed.emit()
    master_audio_level_changed = Signal()
    masterAudioLevel = Property(float, get_master_audio_level, notify=master_audio_level_changed)
    ### END Property masterAudioLevelLeft

    @Signal
    def master_volume_changed(self):
        pass

    def get_master_volume(self):
        return self.zyngui.master_alsa_mixer.volume

    @Signal
    def click_track_enabled_changed(self):
        pass

    def get_clickTrackEnabled(self):
        return self.click_track_enabled

    def set_clickTrackEnabled(self, enabled: bool):
        self.click_track_enabled = enabled

        if enabled:
            self.click_track_click.set_length(4, self.__song__.bpm)
            self.click_track_clack.set_length(1, self.__song__.bpm)

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

        jack_basenames = []
        selected_track = self.song.tracksModel.getTrack(self.zyngui.screens["session_dashboard"].selectedTrack)

        logging.error(f"### update_recorder_jack_port chainedSounds : {selected_track.chainedSounds}")

        for channel in selected_track.chainedSounds:
            if channel >= 0 and selected_track.checkIfLayerExists(channel):
                layer = self.zyngui.screens['layer'].layer_midi_map[channel]

                logging.error(f"### FX Chain Layers : {self.zyngui.screens['layer'].get_fxchain_layers(layer)}")

                for fxlayer in self.zyngui.screens['layer'].get_fxchain_layers(layer):
                    logging.error(f"FX Layer : {fxlayer}, {fxlayer.jackname}")
                    try:
                        jack_basenames.append(fxlayer.jackname.split(":")[0])
                    except Exception as e:
                        logging.error(f"### update_recorder_jack_port Error : {str(e)}")

        for port in self.jack_client.get_all_connections('system:playback_1'):
            self.process_jack_port(port, self.jack_capture_port_a, jack_basenames)

        for port in self.jack_client.get_all_connections('system:playback_2'):
            self.process_jack_port(port, self.jack_capture_port_b, jack_basenames)

    def process_jack_port(self, port, target, active_jack_basenames):
        try:
            for jack_basename in active_jack_basenames:
                if not (port.name.startswith("JUCE") or port.name.startswith("system")) and port.name.startswith(jack_basename):
                    logging.error("ACCEPTED {}".format(port.name))
                    self.jack_client.connect(port.name, target.name)
                else:
                    logging.error("REJECTED {}".format(port.name))
        except Exception as e:
            logging.error(f"Error processing jack port : {port}({str(e)})")

    def recording_process_stopped(self, exitCode, exitStatus):
        logging.error(f"Stopped recording {self} : Code({exitCode}), Status({exitStatus})")

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
    def newSketch(self):
        try:
            self.__song__.bpm_changed.disconnect()
        except Exception as e:
            logging.error(f"Already disconnected : {str(e)}")

        if (self.__sketch_basepath__ / 'temp').exists():
            shutil.rmtree(self.__sketch_basepath__ / 'temp')

        try:
            self.stopAllPlayback()
            self.zyngui.screens["playgrid"].stopMetronomeRequest()
            self.zyngui.screens["song_arranger"].stop()
            self.resetMetronome()
        except:
            pass

        self.__song__ = zynthiloops_song.zynthiloops_song(str(self.__sketch_basepath__ / "temp") + "/", "Sketch-1", self)
        self.__song__.bpm_changed.connect(self.update_timer_bpm)
        self.song_changed.emit()
        self.zyngui.screens["session_dashboard"].set_selected_track(0, True)

    @Slot(None)
    def saveSketch(self):
        self.__song__.save(False)

    @Slot(str)
    def createSketch(self, name):
        self.stopAllPlayback()
        self.zyngui.screens["playgrid"].stopMetronomeRequest()
        self.zyngui.screens["song_arranger"].stop()
        self.resetMetronome()

        # Rename temp sketch folder to the user defined name
        Path(self.__sketch_basepath__ / 'temp').rename(self.__sketch_basepath__ / name)

        # Rename temp sketch json filename to user defined name
        Path(self.__sketch_basepath__ / name / (self.__song__.name + ".json")).rename(self.__sketch_basepath__ / name / (name + ".json"))

        obj = {}

        # Read sketch json data to dict
        try:
            with open(self.__sketch_basepath__ / name / (name + ".json"), "r") as f:
                obj = json.loads(f.read())
        except Exception as e:
            logging.error(e)

        # Update temp sketch name to user defined name and update clip paths to point to new sketch dir
        try:
            with open(self.__sketch_basepath__ / name / (name + ".json"), "w") as f:
                obj["name"] = name

                for i, track in enumerate(obj["tracks"]):
                    for j, clip in enumerate(track["clips"]):
                        if clip['path'] is not None:
                            path = clip['path'].replace("/zynthian/zynthian-my-data/sketches/temp/", str(self.__sketch_basepath__ / name) + "/")
                            logging.error(f"Clip Path : {clip['path']}")
                            obj["tracks"][i]["clips"][j]["path"] = path

                f.write(json.dumps(obj))
                f.flush()
                os.fsync(f.fileno())
        except Exception as e:
            logging.error(e)

        self.__song__ = zynthiloops_song.zynthiloops_song(str(self.__sketch_basepath__ / name) + "/", name, self)
        self.__song__.bpm_changed.connect(self.update_timer_bpm)
        self.song_changed.emit()

        logging.error("### Saving sketch to session")
        self.zyngui.session_dashboard.set_sketch(self.__song__.sketch_folder)

    @Slot(str)
    def saveCopy(self, name):
        old_folder = self.__song__.sketch_folder
        shutil.copytree(old_folder, self.__sketch_basepath__ / name)

        for json_path in (self.__sketch_basepath__ / name).glob("**/*.json"):
            try:
                with open(json_path, "r+") as f:
                    obj = json.load(f)
                    f.seek(0)

                    for i, track in enumerate(obj["tracks"]):
                        for j, clip in enumerate(track["clips"]):
                            if clip['path'] is not None:
                                path = clip['path'].replace(old_folder, str(self.__sketch_basepath__ / name) + "/")
                                logging.error(f"Clip Path : {clip['path']}")
                                obj["tracks"][i]["clips"][j]["path"] = path

                    json.dump(obj, f)
                    f.truncate()
                    f.flush()
                    os.fsync(f.fileno())
            except Exception as e:
                logging.error(e)

    @Slot(str)
    def loadSketch(self, sketch):
        logging.error(f"Loading sketch : {sketch}")

        try:
            self.__song__.bpm_changed.disconnect()
        except Exception as e:
            logging.error(f"Already disconnected : {str(e)}")

        sketch_path = Path(sketch)

        self.stopAllPlayback()
        self.zyngui.screens["playgrid"].stopMetronomeRequest()
        self.zyngui.screens["song_arranger"].stop()
        self.resetMetronome()

        logging.error(f"Loading Sketch : {str(sketch_path.parent.absolute()) + '/'}, {str(sketch_path.stem)}")
        self.__song__ = zynthiloops_song.zynthiloops_song(str(sketch_path.parent.absolute()) + "/", str(sketch_path.stem), self)

        self.__song__.bpm_changed.connect(self.update_timer_bpm)
        self.song_changed.emit()

    @Slot(str)
    def loadSketchVersion(self, version):
        sketch_folder = self.__song__.sketch_folder

        try:
            self.__song__.bpm_changed.disconnect()
        except Exception as e:
            logging.error(f"Already disconnected : {str(e)}")

        self.stopAllPlayback()
        self.zyngui.screens["playgrid"].stopMetronomeRequest()
        self.zyngui.screens["song_arranger"].stop()
        self.resetMetronome()

        self.__song__ = zynthiloops_song.zynthiloops_song(sketch_folder, version, self)
        self.__song__.bpm_changed.connect(self.update_timer_bpm)
        self.song_changed.emit()

    @Slot(str, result=bool)
    def sketchExists(self, name):
        sketch_path = self.__sketch_basepath__ / name
        return sketch_path.is_dir()

    @Slot(str, result=bool)
    def versionExists(self, name):
        sketch_path = Path(self.__song__.sketch_folder)
        return (sketch_path / (name+'.json')).exists()

    @Slot(None, result=bool)
    def sketchIsTemp(self):
        return self.__song__.sketch_folder == str(self.__sketch_basepath__ / "temp") + "/"

    @Slot(None)
    def stopAllPlayback(self):
        for i in range(self.__song__.partsModel.count):
            self.__song__.partsModel.getPart(i).stop()
            for j in range(self.__song__.tracksModel.count):
                self.__song__.getClip(j, i).stop()

    def update_timer_bpm(self):
        self.click_track_click.set_length(4, self.__song__.bpm)
        self.click_track_clack.set_length(1, self.__song__.bpm)

        if self.metronome_running_refcount > 0:
            self.set_clickTrackEnabled(self.click_track_enabled)

            libzl.startTimer(self.__song__.__bpm__)

    def queue_clip_record(self, clip, source, channel):
        if self.zyngui.curlayer is not None:
            layers_snapshot = self.zyngui.screens["layer"].export_multichannel_snapshot(self.zyngui.curlayer.midi_chan)
            self.update_recorder_jack_port()
            self.clip_to_record = clip
            (Path(self.clip_to_record.recording_basepath) / 'wav').mkdir(parents=True, exist_ok=True)

            if source == 'internal':
                try:
                    preset_name = layers_snapshot['layers'][0]['preset_name'].replace(' ', '-').replace('/', '-')
                except:
                    preset_name = ""
            else:
                preset_name = "external"

            count=0
            base_recording_dir = f"{self.clip_to_record.recording_basepath}/wav"
            base_filename = f"{datetime.now().strftime('%Y%m%d-%H%M')}_{preset_name}_{self.__song__.bpm}-BPM"

            # Check if file exists otherwise append count
            while Path(f"{base_recording_dir}/{base_filename}{'-'+str(count) if count > 0 else ''}.clip.wav").exists():
                count += 1

            self.clip_to_record_path = f"{base_recording_dir}/{base_filename}{'-'+str(count) if count > 0 else ''}.clip.wav"

            #self.countInValue = countInBars * 4
            logging.error(
                f"Command jack_capture : /usr/local/bin/jack_capture {self.recorder_process_internal_arguments} {self.clip_to_record_path}")

            self.clip_to_record.isRecording = True
            
            if source == 'internal':
                self.__last_recording_type__ = "Internal"
                self.recorder_process = Popen(("/usr/local/bin/jack_capture", *self.recorder_process_internal_arguments, self.clip_to_record_path))
            else:
                if channel == "1":
                    self.__last_recording_type__ = "External (Mono Left)"
                elif channel == "2":
                    self.__last_recording_type__ = "External (Mono Right)"
                else:
                    self.__last_recording_type__ = "External (Stereo)"
                self.recorder_process = Popen(("/usr/local/bin/jack_capture", "--daemon", "--port", f"system:capture_{channel}", self.clip_to_record_path))
        else:
            logging.error("Empty layer selected. Cannot record.")
            self.cannotRecordEmptyLayer.emit()

    @Slot(None)
    def stopRecording(self):
        if self.clip_to_record is not None and self.clip_to_record.isRecording:
            self.clip_to_record.isRecording = False

        if self.recorder_process is not None:
            self.recorder_process.terminate()
            self.recording_complete.emit()

    @Slot(None)
    def startPlayback(self):
        self.__song__.scenesModel.playScene(self.__song__.scenesModel.selectedSceneIndex)
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
                if self.click_track_enabled:
                    self.click_track_click.queueClipToStart()
                    self.click_track_clack.queueClipToStart()

                libzl.startTimer(self.__song__.__bpm__)
                self.metronome_running_changed.emit()

    def stop_metronome_request(self):
        if self.metronome_running_refcount == 1:
            self.metronome_schedule_stop = True

        self.metronome_running_refcount = max(self.metronome_running_refcount - 1, 0)

        logging.error(f"Stop Metronome Request : refcount({self.metronome_running_refcount}), metronome_schedule_stop({self.metronome_schedule_stop}")

    @Slot(None)
    def resetMetronome(self):
        if self.metronome_running_refcount > 0:
            logging.error(f"Resetting metronome")
            self.metronome_running_refcount = 0
            self.metronome_schedule_stop = True

    def metronome_update(self, beat):
        self.__current_beat__ = beat

        # if self.countInValue > 0:
        #     self.countInValue -= 1

        # Immediately stop clips when scheduled to stop
        if self.metronome_schedule_stop:
            libzl.stopTimer()

            self.click_track_click.stop()
            self.click_track_clack.stop()
            self.__current_beat__ = -1
            self.__current_bar__ = -1
            self.current_beat_changed.emit()
            self.current_bar_changed.emit()
            self.metronome_schedule_stop = False
            self.metronome_running_changed.emit()

        if self.__current_beat__ == 0:
            self.__current_bar__ += 1
            self.current_bar_changed.emit()

        self.current_beat_changed.emit()

    def load_recorded_file_to_clip(self):
        while not Path(self.clip_to_record_path).exists():
            sleep(0.1)

        layer = self.zyngui.screens["layer"].export_multichannel_snapshot(self.zyngui.curlayer.midi_chan)
        logging.error(f"### Channel({self.zyngui.curlayer.midi_chan}), Layer({json.dumps(layer)})")

        self.clip_to_record.path = self.clip_to_record_path
        self.clip_to_record.write_metadata("ZYNTHBOX_ACTIVELAYER", [json.dumps(layer)])
        self.clip_to_record.write_metadata("ZYNTHBOX_BPM", [str(self.__song__.bpm)])
        self.clip_to_record.write_metadata("ZYNTHBOX_AUDIO_TYPE", [self.__last_recording_type__])
        self.clip_to_record = None
        self.clip_to_record_path = None
        self.recorder_process = None
        self.__last_recording_type__ = ""
        # self.__song__.save()

    def get_next_free_layer(self):
        logging.error(self.zyngui.screens["layers"].layers)

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

    metronomeBeatUpdate4th = Signal(int)
    metronomeBeatUpdate8th = Signal(int)
    metronomeBeatUpdate16th = Signal(int)
    metronomeBeatUpdate32th = Signal(int)
    metronomeBeatUpdate64th = Signal(int)
    metronomeBeatUpdate128th = Signal(int)

    cannotRecordEmptyLayer = Signal()
