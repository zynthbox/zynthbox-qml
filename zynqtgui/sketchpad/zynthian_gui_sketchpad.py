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
import shutil
import sys
import json
import numpy as np
import Zynthbox
import jack

from datetime import datetime
from os.path import dirname, realpath
from pathlib import Path
from PySide2.QtCore import QMetaObject, Qt, Property, QObject, QTimer, Signal, Slot
from PySide2.QtGui import QColor
from ..zynthian_gui_multi_controller import MultiController
from . import sketchpad_clip, sketchpad_song
from .. import zynthian_qt_gui_base
from .. import zynthian_gui_controller
from .. import zynthian_gui_config
from zyngine import zynthian_controller


class last_selected_obj_dto(QObject):
    def __init__(self, parent=None):
        super(last_selected_obj_dto, self).__init__(parent)
        self.__className = None
        self.__value = None
        self.__component = None

    ### BEGIN Property className
    def get_className(self):
        return self.__className

    def set_className(self, val):
        if self.__className != val:
            self.__className = val
            self.classNameChanged.emit()

    classNameChanged = Signal()

    className = Property(str, get_className, set_className, notify=classNameChanged)
    ### END Property className

    ### BEGIN Property value
    def get_value(self):
        return self.__value

    def set_value(self, val):
        if self.__value != val:
            self.__value = val
            self.valueChanged.emit()

    valueChanged = Signal()

    value = Property("QVariant", get_value, set_value, notify=valueChanged)
    ### END Property value

    ### BEGIN Property component
    def get_component(self):
        return self.__component

    def set_component(self, val):
        if self.__component != val:
            self.__component = val
            self.componentChanged.emit()

    componentChanged = Signal()

    component = Property(QObject, get_component, set_component, notify=componentChanged)
    ### END Property component


class zynthian_gui_sketchpad(zynthian_qt_gui_base.zynqtgui):
    def __init__(self, parent=None):
        super(zynthian_gui_sketchpad, self).__init__(parent)

        logging.info(f"Initializing Sketchpad")

        self.isZ2V3 = os.environ.get("ZYNTHIAN_WIRING_LAYOUT") == "Z2_V3"
        self.clip_to_record = None
        self.clip_to_record_path = None
        self.clip_to_record_path = None
        self.__current_beat__ = -1
        self.__current_bar__ = -1
        self.metronome_schedule_stop = False
        self.metronome_running_refcount = 0
        self.__sketchpad_basepath__ = Path("/zynthian/zynthian-my-data/sketchpads/my-sketchpads/")
        self.__clips_queue__: list[sketchpad_clip] = []
        self.is_recording = False
        self.recording_count_in_value = 0
        self.jack_client = None
        self.__jack_client_init_timer__ = QTimer()
        self.__jack_client_init_timer__.setInterval(1000)
        self.__jack_client_init_timer__.setSingleShot(True)
        self.__jack_client_init_timer__.timeout.connect(self.init_jack_client)
        self.__last_recording_type__ = ""
        self.__capture_audio_level_left__ = -400
        self.__capture_audio_level_right__ = -400
        self.__song__ = None
        self.__is_init_in_progress__ = True
        self.__long_task_count__ = 0
        self.__big_knob_mode__ = ""
        self.__long_operation__ = False
        self.__record_master_output__ = False
        self.__record_solo = False
        self.__count_in_bars__ = 1
        self.__global_fx_knob_value__ = 50
        self.clips_to_record = []
        self.__display_scene_buttons = False
        self.__recording_source = "internal"
        self.__recording_channel = "*"
        self.__recording_type = "audio"
        self.__last_recording_midi__ = ""
        self.__metronomeVolume = 1.0
        self.__channel_type_synth_color = QColor(255, 0, 0, 200)
        self.__channel_type_sketches_color = QColor(0, 255, 0, 200)
        self.__channel_type_samples_color = QColor(255, 235, 59, 200)
        self.__channel_type_external_color = QColor(142, 36, 170, 200)
        # This variable tells zynthian_qt_gui to load last state snapshot when booting when set to True
        # or load default snapshot when set to False
        self.init_should_load_last_state = False
        self.__last_selected_obj = last_selected_obj_dto(self)

        self.metronome_clip_tick = Zynthbox.ClipAudioSource(dirname(realpath(__file__)) + "/assets/metronome_clip_tick.wav", False, self)
        self.metronome_clip_tick.setVolumeAbsolute(self.__metronomeVolume)
        self.metronome_clip_tick.setLength(1, 120);
        self.metronome_clip_tock = Zynthbox.ClipAudioSource(dirname(realpath(__file__)) + "/assets/metronome_clip_tock.wav", False, self)
        self.metronome_clip_tock.setVolumeAbsolute(self.__metronomeVolume)
        self.metronome_clip_tock.setLength(1, 120);
        Zynthbox.SyncTimer.instance().setMetronomeTicks(self.metronome_clip_tick, self.metronome_clip_tock)
        Zynthbox.SyncTimer.instance().audibleMetronomeChanged.connect(self.metronomeEnabledChanged)

        Path('/zynthian/zynthian-my-data/sketchpads/default-sketchpads').mkdir(exist_ok=True, parents=True)
        Path('/zynthian/zynthian-my-data/sketchpads/my-sketchpads').mkdir(exist_ok=True, parents=True)
        Path('/zynthian/zynthian-my-data/sketchpads/community-sketchpads').mkdir(exist_ok=True, parents=True)
        Path('/zynthian/zynthian-my-data/samples/default-samples').mkdir(exist_ok=True, parents=True)
        Path('/zynthian/zynthian-my-data/samples/my-samples').mkdir(exist_ok=True, parents=True)
        Path('/zynthian/zynthian-my-data/samples/community-samples').mkdir(exist_ok=True, parents=True)
        Path('/zynthian/zynthian-my-data/sample-banks/my-samplebanks').mkdir(exist_ok=True, parents=True)
        Path('/zynthian/zynthian-my-data/sample-banks/community-samplebanks').mkdir(exist_ok=True, parents=True)

    def init_jack_client(self):
        try:
            jack.Client('').get_port_by_name("AudioLevels:SystemPlayback-left_in")
            self.jack_client = jack.Client('AudioLevels')
            logging.info(f"*** AudioLevels Jack client found. Continuing")

            # Connect all jack ports of respective channel after jack client initialization is done.
            for i in range(0, self.__song__.channelsModel.count):
                channel = self.__song__.channelsModel.getChannel(i)
                channel.update_jack_port()
        except:
            logging.info(f"*** AudioLevels Jack client not found. Checking again in 1000ms")
            self.__jack_client_init_timer__.start()

#    def connect_control_objects(self):
#        selected_channel = self.__song__.channelsModel.getChannel(self.zynqtgui.session_dashboard.get_selected_channel())

#        if self.__volume_control_obj == self.zynqtgui.layers_for_channel.volumeControllers[selected_channel.selectedSlotRow]:
#            return
#        if self.__volume_control_obj:
#            self.__volume_control_obj.value_changed.disconnect(self.set_selector)

#        self.__volume_control_obj = self.zynqtgui.layers_for_channel.volumeControllers[selected_channel.selectedSlotRow]

#        if self.__volume_control_obj:
#            self.__volume_control_obj.value_changed.connect(self.set_selector)
#            self.set_selector()

    def init_sketchpad(self, sketchpad, cb=None):
        def _cb():
            Zynthbox.PlayGridManager.instance().metronomeBeat4thChanged.connect(self.metronome_update)

            if cb is not None:
                cb()

            self.zynqtgui.layers_for_channel.fill_list()
            self.zynqtgui.session_dashboard.set_selected_channel(0, True)
            self.__is_init_in_progress__ = False
            logging.info(f"Sketchpad Initialization Complete")

            self.zynqtgui.zynautoconnect(True)

            for i in range(0, self.__song__.channelsModel.count):
                channel = self.__song__.channelsModel.getChannel(i)
                channel.update_jack_port()

        if sketchpad is not None:
            logging.debug(f"### Checking Sketchpad : {sketchpad} : exists({Path(sketchpad).exists()}) ")
        else:
            logging.debug(f"### Checking Sketchpad : sketchpad is none ")

        if sketchpad is not None and Path(sketchpad).exists():
            self.loadSketchpad(sketchpad, True, False, _cb)
            # Existing sketch found. Tell zynthian_qt_gui to load last_state snapshot
            self.init_should_load_last_state = True
        else:
            self.newSketchpad(None, _cb, load_snapshot=False)
            # Existing sketch not found. Tell zynthian_qt_gui to load default snapshot
            self.init_should_load_last_state = False

    def switch_select(self, t):
        pass

    def back_action(self):
        return "sketchpad"

    ### Property countInBars
    def get_countInBars(self):
        return self.__count_in_bars__

    def set_countInBars(self, value):
        self.__count_in_bars__ = value
        self.countInBarsChanged.emit()

    countInBarsChanged = Signal()

    countInBars = Property(int, get_countInBars, set_countInBars, notify=countInBarsChanged)
    ### END Property countInBars

    ### Property recordMasterOutput
    def get_recordMasterOutput(self):
        return self.__record_master_output__

    def set_recordMasterOutput(self, value):
        self.__record_master_output__ = value
        self.recordMasterOutputChanged.emit()

    recordMasterOutputChanged = Signal()

    recordMasterOutput = Property(bool, get_recordMasterOutput, set_recordMasterOutput, notify=recordMasterOutputChanged)
    ### END Property recordMasterOutput

    ### Property recordSolo
    def get_recordSolo(self):
        return self.__record_solo

    def set_recordSolo(self, value):
        self.__record_solo = value
        self.recordSoloChanged.emit()

    recordSoloChanged = Signal()

    recordSolo = Property(bool, get_recordSolo, set_recordSolo, notify=recordSoloChanged)
    ### END Property recordSolo

    ### Property clipToRecord
    def get_clip_to_record(self):
        return self.clip_to_record

    def set_clip_to_record(self, clip):
        if self.clip_to_record != clip:
            self.clip_to_record = clip
            self.clipToRecordChanged.emit()

    clipToRecordChanged = Signal()

    clipToRecord = Property(QObject, get_clip_to_record, set_clip_to_record, notify=clipToRecordChanged)
    ### END Property clipToRecord

    ### Property clipsToRecord
    def get_clips_to_record(self):
        return self.clips_to_record

    def set_clips_to_record(self, clips):
        if clips != self.clips_to_record:
            self.clips_to_record = clips
            self.clipsToRecordChanged.emit()

    clipsToRecordChanged = Signal()

    # This property is used by recording popup to determine which additional clips should also have the recorded clip
    clipsToRecord = Property('QVariantList', get_clips_to_record, set_clips_to_record, notify=clipsToRecordChanged)
    ### END Property clipsToRecord

    ### Property isRecording
    def get_isRecording(self):
        return self.is_recording

    def set_isRecording(self, value):
        if self.is_recording != value:
            self.is_recording = value
            self.isRecordingChanged.emit()

    isRecordingChanged = Signal()

    isRecording = Property(bool, get_isRecording, set_isRecording, notify=isRecordingChanged)
    ### END Property isRecording

    ### Property longOperation
    def longOperationIncrement(self):
        self.__long_operation__ += 1

    def longOperationDecrement(self):
        self.__long_operation__ = max(self.__long_operation__ - 1, 0)
        self.longOperationChanged.emit()

    def get_longOperation(self):
        return self.__long_operation__ > 0

    longOperationChanged = Signal()

    longOperation = Property(bool, get_longOperation, notify=longOperationChanged)
    ### END Property longOperation

    ### Property displaySceneButtons
    def get_displaySceneButtons(self):
        return self.__display_scene_buttons

    def set_displaySceneButtons(self, value):
        if self.__display_scene_buttons != value:
            self.__display_scene_buttons = value
            self.displaySceneButtonsChanged.emit()

    displaySceneButtonsChanged = Signal()

    displaySceneButtons = Property(bool, get_displaySceneButtons, set_displaySceneButtons, notify=displaySceneButtonsChanged)
    ### END Property displaySceneButtons

    ### Property recordingSource
    def get_recordingSource(self):
        return self.__recording_source

    def set_recordingSource(self, source):
        if source != self.__recording_source:
            self.__recording_source = source
            self.recordingSourceChanged.emit()

    recordingSourceChanged = Signal()

    recordingSource = Property(str, get_recordingSource, set_recordingSource, notify=recordingSourceChanged)
    ### END Property recordingSource

    ### Property recordingChannel
    def get_recordingChannel(self):
        return self.__recording_channel

    def set_recordingChannel(self, channel):
        if channel != self.__recording_channel:
            self.__recording_channel = channel
            self.recordingChannelChanged.emit()

    recordingChannelChanged = Signal()

    recordingChannel = Property(str, get_recordingChannel, set_recordingChannel, notify=recordingChannelChanged)
    ### END Property recordingChannel

    ### Property recordingType
    # Recording type can be : "audio" or "midi"
    # "audio" will record both wav and midi (saved as metadata in wav file)
    # "midi" will record only midi and apply it to pattern
    def get_recordingType(self):
        return self.__recording_type

    def set_recordingType(self, type):
        if type != self.__recording_type:
            self.__recording_type = type
            self.recordingTypeChanged.emit()

    recordingTypeChanged = Signal()

    recordingType = Property(str, get_recordingType, set_recordingType, notify=recordingTypeChanged)
    ### END Property recordingType

    ### Property lastRecordingMidi
    def get_lastRecordingMidi(self):
        return self.__last_recording_midi__

    def set_lastRecordingMidi(self, data):
        if data != self.__last_recording_midi__:
            self.__last_recording_midi__ = data
            self.lastRecordingMidiChanged.emit()

    lastRecordingMidiChanged = Signal()

    lastRecordingMidi = Property(str, get_lastRecordingMidi, set_lastRecordingMidi, notify=lastRecordingMidiChanged)
    ### END Property lastRecordingMidi

    ### Property metronomeVolume
    def get_metronomeVolume(self):
        return self.__metronomeVolume

    def set_metronomeVolume(self, volume):
        if self.__metronomeVolume != volume:
            self.__metronomeVolume = volume
            self.metronome_clip_tick.setVolumeAbsolute(self.__metronomeVolume)
            self.metronome_clip_tock.setVolumeAbsolute(self.__metronomeVolume)
            self.metronomeVolumeChanged.emit()

    metronomeVolumeChanged = Signal()

    metronomeVolume = Property(float, get_metronomeVolume, set_metronomeVolume, notify=metronomeVolumeChanged)
    ### END Property metronomeVolume

    ### BEGIN Property channelTypeSynthColor
    def get_channelTypeSynthColor(self):
        return self.__channel_type_synth_color

    channelTypeSynthColor = Property(QColor, get_channelTypeSynthColor, constant=True)
    ### END Property channelTypeSynthColor

    ### BEGIN Property channelTypeSketchesColor
    def get_channelTypeSketchesColor(self):
        return self.__channel_type_sketches_color

    channelTypeSketchesColor = Property(QColor, get_channelTypeSketchesColor, constant=True)
    ### END Property channelTypeSketchesColor

    ### BEGIN Property channelTypeSamplesColor
    def get_channelTypeSamplesColor(self):
        return self.__channel_type_samples_color

    channelTypeSamplesColor = Property(QColor, get_channelTypeSamplesColor, constant=True)
    ### END Property channelTypeSamplesColor

    ### BEGIN Property channelTypeExternalColor
    def get_channelTypeExternalColor(self):
        return self.__channel_type_external_color

    channelTypeExternalColor = Property(QColor, get_channelTypeExternalColor, constant=True)
    ### END Property channelTypeExternalColor

    ### BEGIN Property lastSelectedObj
    def get_lastSelectedObj(self):
        return self.__last_selected_obj

    lastSelectedObj = Property(QObject, get_lastSelectedObj, constant=True)
    ### END Property lastSelectedObj

    @Signal
    def metronomeEnabledChanged(self):
        pass

    def get_metronomeEnabled(self):
        return Zynthbox.SyncTimer.instance().audibleMetronome()

    def set_metronomeEnabled(self, enabled: bool):
        Zynthbox.SyncTimer.instance().setAudibleMetronome(enabled)

    metronomeEnabled = Property(bool, get_metronomeEnabled, set_metronomeEnabled, notify=metronomeEnabledChanged)

    def channel_layers_snapshot(self):
        snapshot = []
        for i in range(5, 10):
            if i in self.zynqtgui.screens['layer'].layer_midi_map:
                layer_to_copy = self.zynqtgui.screens['layer'].layer_midi_map[i]
                snapshot.append(layer_to_copy.get_snapshot())
        return snapshot

    @Slot(int)
    def saveLayersToChannel(self, tid):
        if tid < 0 or tid >= self.__song__.channelsModel.count:
            return
        channel_layers_snapshot = self.channel_layers_snapshot()
        logging.debug(channel_layers_snapshot)
        self.__song__.channelsModel.getChannel(tid).set_layers_snapshot(channel_layers_snapshot)
        self.__song__.schedule_save()

    @Slot(int)
    def restoreLayersFromChannel(self, tid):
        if tid < 0 or tid >= self.__song__.channelsModel.count:
            return
        for i in range(5, 10):
            if i in self.zynqtgui.screens['layer'].layer_midi_map:
                self.zynqtgui.screens['layer'].remove_root_layer(self.zynqtgui.screens['layer'].root_layers.index(self.zynqtgui.screens['layer'].layer_midi_map[i]), True)
        self.zynqtgui.screens['layer'].load_channels_snapshot(self.__song__.channelsModel.getChannel(tid).get_layers_snapshot(), 5, 9)

    @Signal
    def ongoingCountInChanged(self):
        pass

    def get_ongoingCountIn(self):
        return self.recording_count_in_value

    def set_ongoingCountIn(self, value):
        self.recording_count_in_value = value
        self.ongoingCountInChanged.emit()

    ongoingCountIn = Property(int, get_ongoingCountIn, set_ongoingCountIn, notify=ongoingCountInChanged)

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

    def generate_unique_mysketchpad_name(self, name):
        if not (self.__sketchpad_basepath__ / name).exists():
            return name
        else:
            counter = 1

            while (self.__sketchpad_basepath__ / f"{name}-{counter}").exists():
                counter += 1

            return f"{name}-{counter}"

    @Slot(None)
    def newSketchpad(self, base_sketchpad=None, cb=None, load_snapshot=True):
        def task():

            self.zynqtgui.currentTaskMessage = "Stopping playback"

            try:
                self.stopAllPlayback()
                self.zynqtgui.screens["playgrid"].stopMetronomeRequest()
                self.zynqtgui.screens["song_arranger"].stop()
                self.resetMetronome()
            except:
                pass

            if self.__song__ is not None:
                self.__song__.to_be_deleted()

            if (self.__sketchpad_basepath__ / 'temp').exists():
                self.zynqtgui.currentTaskMessage = "Removing existing temp sketchpad"
                shutil.rmtree(self.__sketchpad_basepath__ / 'temp')

            if base_sketchpad is not None:
                logging.info(f"Creating New Sketchpad from community sketchpad : {base_sketchpad}")
                self.zynqtgui.currentTaskMessage = "Copying community sketchpad to my sketchpads"

                base_sketchpad_path = Path(base_sketchpad)

                # Copy community sketchpad to my sketchpads

                new_sketchpad_name = self.generate_unique_mysketchpad_name(base_sketchpad_path.parent.name)
                shutil.copytree(base_sketchpad_path.parent, self.__sketchpad_basepath__ / new_sketchpad_name)

                logging.info(f"Loading new sketchpad from community sketchpad : {str(self.__sketchpad_basepath__ / new_sketchpad_name / base_sketchpad_path.name)}")

                # Load sketchpad snapshot if available or else load default snapshot
                snapshot_path = f"{str(self.__sketchpad_basepath__ / new_sketchpad_name / 'soundsets')}/{base_sketchpad_path.stem.replace('.sketchpad', '')}.zss"
                if Path(snapshot_path).exists():
                    self.zynqtgui.currentTaskMessage = "Loading snapshot"
                    logging.info(f"Loading snapshot : {snapshot_path}")
                    self.zynqtgui.screens["layer"].load_snapshot(snapshot_path)
                elif Path("/zynthian/zynthian-my-data/snapshots/default.zss").exists():
                    logging.info(f"Loading default snapshot")
                    self.zynqtgui.currentTaskMessage = "Loading snapshot"
                    self.zynqtgui.screens["layer"].load_snapshot("/zynthian/zynthian-my-data/snapshots/default.zss")

                self.__song__ = sketchpad_song.sketchpad_song(str(self.__sketchpad_basepath__ / new_sketchpad_name) + "/",
                                                                  base_sketchpad_path.stem.replace(".sketchpad", ""), self)
                self.zynqtgui.screens["session_dashboard"].set_last_selected_sketchpad(
                    str(self.__sketchpad_basepath__ / new_sketchpad_name / base_sketchpad_path.name))
                self.song_changed.emit()
                self.zynqtgui.screens["session_dashboard"].set_selected_channel(0, True)
            else:
                logging.info(f"Creating New Sketchpad")
                self.zynqtgui.currentTaskMessage = "Creating empty sketchpad as temp sketchpad"

                # When zynqtgui is starting, it will load last_state or default snapshot
                # based on the value of self.init_should_load_last_state
                # Do not load snapshot again otherwise it will create multiple processes for same synths
                if load_snapshot:
                    if Path("/zynthian/zynthian-my-data/snapshots/default.zss").exists():
                        logging.info(f"Loading default snapshot")
                        self.zynqtgui.currentTaskMessage = "Loading snapshot"
                        self.zynqtgui.screens["layer"].load_snapshot("/zynthian/zynthian-my-data/snapshots/default.zss")

                self.__song__ = sketchpad_song.sketchpad_song(str(self.__sketchpad_basepath__ / "temp") + "/", "Sketchpad-1", self)
                self.zynqtgui.screens["session_dashboard"].set_last_selected_sketchpad(
                    str(self.__sketchpad_basepath__ / 'temp' / 'Sketchpad-1.sketchpad.json'))

                # Connect all jack ports of respective channel after jack client initialization is done.
                for i in range(0, self.__song__.channelsModel.count):
                    channel = self.__song__.channelsModel.getChannel(i)
                    channel.update_jack_port()

                self.song_changed.emit()
                self.zynqtgui.screens["session_dashboard"].set_selected_channel(0, True)
                self.newSketchpadLoaded.emit()

            # Update volume controls
            self.zynqtgui.fixed_layers.fill_list()

            if cb is not None:
                cb()

            if self.zynqtgui.isBootingComplete:
                self.zynqtgui.currentTaskMessage = "Finalizing"

            self.longOperationDecrement()
            QTimer.singleShot(3000, self.zynqtgui.end_long_task)

        self.zynqtgui.currentTaskMessage = "Creating New Sketchpad"
        self.longOperationIncrement()
        self.zynqtgui.do_long_task(task)

    @Slot(None)
    def saveSketchpad(self):
        def task():
            self.__song__.save(False)
            QTimer.singleShot(3000, self.zynqtgui.end_long_task)

        self.zynqtgui.currentTaskMessage = "Saving sketchpad"
        self.zynqtgui.showCurrentTaskMessage = False
        self.zynqtgui.do_long_task(task)

    @Slot(str)
    def createSketchpad(self, name):
        def task():
            self.stopAllPlayback()
            self.zynqtgui.screens["playgrid"].stopMetronomeRequest()
            self.zynqtgui.screens["song_arranger"].stop()
            self.resetMetronome()

            # Rename temp sketchpad folder to the user defined name
            Path(self.__sketchpad_basepath__ / 'temp').rename(self.__sketchpad_basepath__ / name)

            # Rename temp sketchpad json filename to user defined name
            Path(self.__sketchpad_basepath__ / name / (self.__song__.name + ".sketchpad.json")).rename(self.__sketchpad_basepath__ / name / (name + ".sketchpad.json"))

            obj = {}

            # Read sketchpad json data to dict
            try:
                with open(self.__sketchpad_basepath__ / name / (name + ".sketchpad.json"), "r") as f:
                    obj = json.loads(f.read())
            except Exception as e:
                logging.error(e)

            # Update temp sketchpad name to user defined name and update clip paths to point to new sketchpad dir
            try:
                with open(self.__sketchpad_basepath__ / name / (name + ".sketchpad.json"), "w") as f:
                    obj["name"] = name

                    f.write(json.dumps(obj))
                    f.flush()
                    os.fsync(f.fileno())
            except Exception as e:
                logging.error(e)

            self.__song__ = sketchpad_song.sketchpad_song(str(self.__sketchpad_basepath__ / name) + "/", name, self)
            self.zynqtgui.screens["session_dashboard"].set_last_selected_sketchpad(
                str(self.__sketchpad_basepath__ / name / f'{name}.sketchpad.json'))
            self.__song__.save(False)
            self.song_changed.emit()
            self.longOperationDecrement()
            QTimer.singleShot(3000, self.zynqtgui.end_long_task)

        self.zynqtgui.currentTaskMessage = f"Saving Sketchpad : {name}"
        self.zynqtgui.showCurrentTaskMessage = False
        self.longOperationIncrement()
        self.zynqtgui.do_long_task(task)

    @Slot(str)
    def saveCopy(self, name):
        def task():
            old_folder = self.__song__.sketchpad_folder
            shutil.copytree(old_folder, self.__sketchpad_basepath__ / name)

            QTimer.singleShot(3000, self.zynqtgui.end_long_task)

        self.zynqtgui.currentTaskMessage = "Saving a copy of the sketchpad"
        self.zynqtgui.showCurrentTaskMessage = False
        self.zynqtgui.do_long_task(task)

    @Slot(str, bool)
    def loadSketchpad(self, sketchpad, load_history, load_snapshot=True, cb=None):
        def task():
            logging.info(f"Loading sketchpad : {sketchpad}")

            sketchpad_path = Path(sketchpad)

            self.zynqtgui.currentTaskMessage = "Stopping playback"
            try:
                self.stopAllPlayback()
                self.zynqtgui.screens["playgrid"].stopMetronomeRequest()
                self.zynqtgui.screens["song_arranger"].stop()
                self.resetMetronome()
            except:
                pass

            if sketchpad_path.parent.match("*/zynthian-my-data/sketchpads/community-sketchpads/*"):
                def _cb():
                    # Connect all jack ports of respective channel after jack client initialization is done.
                    for i in range(0, self.__song__.channelsModel.count):
                        channel = self.__song__.channelsModel.getChannel(i)
                        channel.update_jack_port()

                    if cb is not None:
                        cb()

                    if self.zynqtgui.isBootingComplete:
                        self.zynqtgui.currentTaskMessage = "Finalizing"
                    self.longOperationDecrement()
                    QTimer.singleShot(3000, self.zynqtgui.end_long_task)

                self.zynqtgui.currentTaskMessage = "Creating new sketchpad from community sketchpad"
                # newSketchpad will handle loading snapshot based on the value of load_snapshot
                self.newSketchpad(sketchpad, _cb, load_snapshot=load_snapshot)
            else:
                logging.info(f"Loading Sketchpad : {str(sketchpad_path.parent.absolute()) + '/'}, {str(sketchpad_path.stem)}")
                self.zynqtgui.currentTaskMessage = "Loading sketchpad"
                self.__song__ = sketchpad_song.sketchpad_song(str(sketchpad_path.parent.absolute()) + "/", str(sketchpad_path.stem.replace(".sketchpad", "")), self, load_history)
                self.zynqtgui.screens["session_dashboard"].set_last_selected_sketchpad(str(sketchpad_path))

                if load_snapshot:
                    snapshot_path = str(sketchpad_path.parent.absolute()) + '/soundsets/' + str(sketchpad_path.stem.replace('.sketchpad', '')) + '.zss'
                    # Load snapshot
                    if Path(snapshot_path).exists():
                        logging.info(f"Loading snapshot : {snapshot_path}")
                        self.zynqtgui.currentTaskMessage = "Loading snapshot"
                        self.zynqtgui.screens["layer"].load_snapshot(snapshot_path)
                    elif Path("/zynthian/zynthian-my-data/snapshots/default.zss").exists():
                        logging.info(f"Loading default snapshot")
                        self.zynqtgui.currentTaskMessage = "Loading snapshot"
                        self.zynqtgui.screens["layer"].load_snapshot("/zynthian/zynthian-my-data/snapshots/default.zss")

                # Update volume controls
                self.zynqtgui.fixed_layers.fill_list()
                self.song_changed.emit()

                # Connect all jack ports of respective channel after jack client initialization is done.
                for i in range(0, self.__song__.channelsModel.count):
                    channel = self.__song__.channelsModel.getChannel(i)
                    channel.update_jack_port()

                if cb is not None:
                    cb()

                if self.zynqtgui.isBootingComplete:
                    self.zynqtgui.currentTaskMessage = "Finalizing"
                self.longOperationDecrement()
                QTimer.singleShot(3000, self.zynqtgui.end_long_task)

        self.zynqtgui.currentTaskMessage = "Loading Sketchpad"
        self.longOperationIncrement()
        self.zynqtgui.do_long_task(task)

    @Slot(str)
    def loadSketchpadVersion(self, version):
        sketchpad_folder = self.__song__.sketchpad_folder

        self.stopAllPlayback()
        self.zynqtgui.screens["playgrid"].stopMetronomeRequest()
        self.zynqtgui.screens["song_arranger"].stop()
        self.resetMetronome()

        self.__song__ = sketchpad_song.sketchpad_song(sketchpad_folder, version, self)
        self.song_changed.emit()

    @Slot(str, result=bool)
    def sketchpadExists(self, name):
        sketchpad_path = self.__sketchpad_basepath__ / name
        return sketchpad_path.is_dir()

    @Slot(str, result=bool)
    def versionExists(self, name):
        sketchpad_path = Path(self.__song__.sketchpad_folder)
        return (sketchpad_path / (name+'.sketchpad.json')).exists()

    @Slot(None, result=bool)
    def sketchpadIsTemp(self):
        return self.__song__.sketchpad_folder == str(self.__sketchpad_basepath__ / "temp") + "/"

    @Slot(None)
    def stopAllPlayback(self):
        for channel_index in range(self.__song__.channelsModel.count):
            self.__song__.channelsModel.getChannel(channel_index).stopAllClips()

    def queue_clip_record(self, clip):
        # When sketchpad is open, curLayer is not updated when changing channels as it is a considerably heavy task
        # but not necessary to change to selected channel's synth.
        # Hence make sure to update curLayer before doing operations depending upon curLayer
        self.zynqtgui.screens["layers_for_channel"].do_activate_midich_layer()
        layers_snapshot = None

        if self.zynqtgui.curlayer is not None:
            layers_snapshot = self.zynqtgui.screens["layer"].export_multichannel_snapshot(self.zynqtgui.curlayer.midi_chan)

        channel = self.__song__.channelsModel.getChannel(self.zynqtgui.session_dashboard.selectedChannel)
        self.set_clip_to_record(clip)

        if clip.isChannelSample:
            Path(channel.bankDir).mkdir(parents=True, exist_ok=True)
        else:
            (Path(clip.recording_basepath) / 'wav').mkdir(parents=True, exist_ok=True)

        if self.recordingSource == 'internal':
            # If source is internal and there are no layers, show error and return.
            if layers_snapshot is None:
                self.zynqtgui.passiveNotification = "Cannot record channel with no synth"
                return

            try:
                preset_name = layers_snapshot['layers'][0]['preset_name'].replace(' ', '-').replace('/', '-')
            except:
                preset_name = ""
        else:
            preset_name = "external"

        count = 0

        if clip.isChannelSample:
            base_recording_dir = channel.bankDir
        else:
            base_recording_dir = f"{clip.recording_basepath}/wav"

        base_filename = f"{datetime.now().strftime('%Y%m%d-%H%M')}_{preset_name}_{Zynthbox.SyncTimer.instance().getBpm()}-BPM"

        # Check if file exists otherwise append count

        while Path(f"{base_recording_dir}/{base_filename}{'-'+str(count) if count > 0 else ''}.clip.wav").exists():
            count += 1

        self.clip_to_record_path = f"{base_recording_dir}/{base_filename}{'-'+str(count) if count > 0 else ''}.clip.wav"

        self.ongoingCountIn = self.countInBars + 1

        if self.recordingType == "audio":
            if self.recordingSource == 'internal':
                self.__last_recording_type__ = "Internal"

                if self.recordMasterOutput:
                    recording_ports = [("system:playback_1", "system:playback_2")]
                else:
                    recording_ports = channel.channelSynthPorts
            else:
                # TODO : Port external recording to AudioLevels recorder

                if self.recordingChannel == "1":
                    self.__last_recording_type__ = "External (Mono Left)"
                    recording_ports = [["system:capture_1"]]
                elif self.recordingChannel == "2":
                    self.__last_recording_type__ = "External (Mono Right)"
                    recording_ports = [["system:capture_2"]]
                else:
                    self.__last_recording_type__ = "External (Stereo)"
                    recording_ports = [["system:capture_1", "system:capture_2"]]

            logging.debug(f"Queueing clip({self.clip_to_record}) to record with source({self.recordingSource}), ports({recording_ports}), recordingType({self.__last_recording_type__})")

            Zynthbox.AudioLevels.instance().setShouldRecordPorts(True)
            Zynthbox.AudioLevels.instance().setRecordPortsFilenamePrefix(self.clip_to_record_path)
            Zynthbox.AudioLevels.instance().clearRecordPorts()

            for ports in recording_ports:
                for port in zip(ports, (0, 1)):
                    logging.debug(f"Adding record port : {port}")
                    Zynthbox.AudioLevels.instance().addRecordPort(port[0], port[1])

            Zynthbox.AudioLevels.instance().startRecording()

        self.isRecording = True

    @Slot(None)
    def stopRecording(self):
        if self.clip_to_record is not None and self.isRecording:
            self.isRecording = False
            self.stopAudioRecording()
            self.load_recorded_file_to_clip()

            self.set_clip_to_record(None)
            self.clip_to_record_path = None
            self.__last_recording_type__ = ""

            self.clips_to_record.clear()
            self.clipsToRecordChanged.emit()

    @Slot()
    def stopAudioRecording(self):
        if Zynthbox.AudioLevels.instance().isRecording():
            Zynthbox.AudioLevels.instance().stopRecording()
            Zynthbox.AudioLevels.instance().clearRecordPorts()

    @Slot(None)
    def startPlayback(self):
        if not self.is_recording or \
                (self.is_recording and not self.recordSolo):
            self.__song__.scenesModel.playScene(self.__song__.scenesModel.selectedSceneIndex,
                                                self.__song__.scenesModel.selectedTrackIndex)

        self.start_metronome_request()

    def start_metronome_request(self):
        self.metronome_running_refcount += 1

        logging.debug(f"Start Metronome Request : refcount({self.metronome_running_refcount}), metronome_schedule_stop({self.metronome_schedule_stop}")

        if self.metronome_running_refcount == 1:
            if self.metronome_schedule_stop:
                # Metronome is already running and scheduled to stop.
                # Do not start timer again and remove stop schedule
                self.metronome_schedule_stop = False
            else:
                Zynthbox.SyncTimer.instance().start()
                self.metronome_running_changed.emit()

    def stop_metronome_request(self):
        if self.metronome_running_refcount == 1:
            self.metronome_schedule_stop = True

        self.metronome_running_refcount = max(self.metronome_running_refcount - 1, 0)

        logging.debug(f"Stop Metronome Request : refcount({self.metronome_running_refcount}), metronome_schedule_stop({self.metronome_schedule_stop}")

    @Slot(None)
    def resetMetronome(self):
        if self.metronome_running_refcount > 0:
            logging.info(f"Resetting metronome")
            self.metronome_running_refcount = 0
            self.metronome_schedule_stop = True

    def metronome_update(self, beat):
        self.__current_beat__ = beat

        # Immediately stop clips when scheduled to stop
        if self.metronome_schedule_stop:
            logging.debug(f"Stopping timer as it was scheduled to stop.")
            Zynthbox.SyncTimer.instance().stop()

            self.__current_beat__ = -1
            self.__current_bar__ = -1
            self.current_beat_changed.emit()
            self.current_bar_changed.emit()
            self.metronome_schedule_stop = False
            self.metronome_running_changed.emit()
        else:
            if self.__current_beat__ == 0:
                self.__current_bar__ += 1
                if self.ongoingCountIn > 0:
                    self.ongoingCountIn -= 1
                self.current_bar_changed.emit()

            self.current_beat_changed.emit()

    def load_recorded_file_to_clip(self):
        if self.recordingType == "audio":
            logging.info(f"Loading recorded wav to clip({self.clip_to_record})")

            if not Path(self.clip_to_record_path).exists():
                logging.error("### The recording does not exist! This is a big problem and we will have to deal with that.")

            try:
                layer = self.zynqtgui.screens["layer"].export_multichannel_snapshot(self.zynqtgui.curlayer.midi_chan)
                logging.debug(f"### Channel({self.zynqtgui.curlayer.midi_chan}), Layer({json.dumps(layer)})")
            except:
                layer = None

            self.clip_to_record.set_path(self.clip_to_record_path, False)
            if layer is not None:
                self.clip_to_record.write_metadata("ZYNTHBOX_ACTIVELAYER", [json.dumps(layer)])
            self.clip_to_record.write_metadata("ZYNTHBOX_BPM", [str(Zynthbox.SyncTimer.instance().getBpm())])
            self.clip_to_record.write_metadata("ZYNTHBOX_AUDIO_TYPE", [self.__last_recording_type__])
            self.clip_to_record.write_metadata("ZYNTHBOX_MIDI_RECORDING", [self.lastRecordingMidi])


            # Set same recorded clip to other additional clips
            for clip in self.clips_to_record:
                # When recording popup starts recording, it queues recording with one of the clip in clipsToRecord
                # This check avoids setting clip twice and hence doesn't let a crash happen when path is set twice
                if clip != self.clip_to_record:
                    clip.set_path(self.clip_to_record_path, True)
                    if layer is not None:
                        clip.write_metadata("ZYNTHBOX_ACTIVELAYER", [json.dumps(layer)])
                    clip.write_metadata("ZYNTHBOX_BPM", [str(Zynthbox.SyncTimer.instance().getBpm())])
                    clip.write_metadata("ZYNTHBOX_AUDIO_TYPE", [self.__last_recording_type__])
                    clip.write_metadata("ZYNTHBOX_MIDI_RECORDING", [self.lastRecordingMidi])

            if self.clip_to_record.isChannelSample:
                logging.info(f"Recorded clip is a sample")
                channel = self.__song__.channelsModel.getChannel(self.zynqtgui.session_dashboard.selectedChannel)
                channel.samples_changed.emit()
        # self.__song__.save()

    def get_next_free_layer(self):
        logging.debug(self.zynqtgui.screens["layers"].layers)

    def get_sketchpad_folders(self):
        sketchpad_folders = []

        for item in self.__sketchpad_basepath__.glob("./*"):
            if item.is_dir():
                sketchpad_folders.append(item)

        return sketchpad_folders

    @staticmethod
    def get_sketchpad_versions(sketchpad_folder):
        sketchpad_versions = []

        for item in Path(sketchpad_folder).glob("./*.sketchpad.json"):
            sketchpad_versions.append(item)

        return sketchpad_versions

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

    @Slot(QObject)
    def toggleFromClipsToRecord(self, clip):
        if clip in self.clips_to_record:
            self.clips_to_record.remove(clip)
        else:
            self.clips_to_record.append(clip)

        self.clipsToRecordChanged.emit()

    cannotRecordEmptyLayer = Signal()
    newSketchpadLoaded = Signal()
