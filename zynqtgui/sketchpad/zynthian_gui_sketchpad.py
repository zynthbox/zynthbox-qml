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
import re

from datetime import datetime
from os.path import dirname, realpath
from pathlib import Path
from PySide2.QtCore import QMetaObject, Qt, Property, QObject, QTimer, Signal, Slot
from PySide2.QtGui import QColor, QGuiApplication
from .sketchpad_channel import last_selected_obj_dto
from ..zynthian_gui_multi_controller import MultiController
from . import sketchpad_clip, sketchpad_song
from .. import zynthian_qt_gui_base
from .. import zynthian_gui_controller
from .. import zynthian_gui_config
from zyngine import zynthian_controller

class zynthian_gui_sketchpad(zynthian_qt_gui_base.zynqtgui):
    def __init__(self, parent=None):
        super(zynthian_gui_sketchpad, self).__init__(parent)

        logging.info(f"Initializing Sketchpad")

        self.clip_to_record = None
        self.clip_to_record_path = None
        self.__current_beat__ = -1
        self.__current_bar__ = -1
        self.metronome_schedule_stop = False
        self.__sketchpad_basepath__ = Path("/zynthian/zynthian-my-data/sketchpads/my-sketchpads/")
        self.__clips_queue__: list[sketchpad_clip] = []
        self.is_recording = False
        self.recording_count_in_value = 0
        self.jack_client = None
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
        self.__display_scene_buttons = False
        self.__recording_source = "internal-track"
        self.__recording_channel = "*"
        self.__recording_type = "audio"
        self.__last_recording_midi__ = ""
        self.__channel_type_synth_color = QColor(255, 0, 0, 200)
        self.__channel_type_sketches_color = QColor(0, 255, 0, 200)
        self.__channel_type_samples_color = QColor(255, 235, 59, 200)
        self.__channel_type_external_color = QColor(142, 36, 170, 200)
        # This variable tells zynthian_qt_gui to load last state snapshot when booting when set to True
        # or load default snapshot when set to False
        self.init_should_load_last_state = False
        self.__last_selected_obj = last_selected_obj_dto(self)
        self.__copy_source_obj = last_selected_obj_dto(self)
        self.__copy_source_obj.reset()
        # When starting up, init process will load a sketchpad and hence set it to True by default
        # This will later be set to False once init process loads the sketchpad
        self.__sketchpad_loading_in_progress = True
        self.__selected_track_id = 0
        self.__stopRecordingRetrier__ = QTimer(self)
        self.__stopRecordingRetrier__.setInterval(50)
        self.__stopRecordingRetrier__.setSingleShot(True)
        self.__stopRecordingRetrier__.timeout.connect(self.stopRecording)
        self.__fixed_layers_fill_list_timer = None
        self.__update_channel_sounds_timer = None

        self.metronome_clip_tick = Zynthbox.ClipAudioSource(dirname(realpath(__file__)) + "/assets/metronome_clip_tick.wav", -1, 0, False, False, self)
        self.metronome_clip_tock = Zynthbox.ClipAudioSource(dirname(realpath(__file__)) + "/assets/metronome_clip_tock.wav", -1, 0, False, False, self)
        # The gain we expose is the slider position, so fetch our default of that out of the newly created thing just to make it simple (the default level being no adjustment)
        self.__metronomeVolume = self.metronome_clip_tick.rootSlice().gainHandler().gainAbsolute()
        Zynthbox.SyncTimer.instance().setMetronomeTicks(self.metronome_clip_tick, self.metronome_clip_tock)
        Zynthbox.SyncTimer.instance().audibleMetronomeChanged.connect(self.metronomeEnabledChanged)
        Zynthbox.SyncTimer.instance().timerRunningChanged.connect(self.metronome_running_changed)

        Path('/zynthian/zynthian-my-data/sketchpads/default-sketchpads').mkdir(exist_ok=True, parents=True)
        Path('/zynthian/zynthian-my-data/sketchpads/my-sketchpads').mkdir(exist_ok=True, parents=True)
        Path('/zynthian/zynthian-my-data/sketchpads/community-sketchpads').mkdir(exist_ok=True, parents=True)
        Path('/zynthian/zynthian-my-data/samples/default-samples').mkdir(exist_ok=True, parents=True)
        Path('/zynthian/zynthian-my-data/samples/my-samples').mkdir(exist_ok=True, parents=True)
        Path('/zynthian/zynthian-my-data/samples/community-samples').mkdir(exist_ok=True, parents=True)
        Path('/zynthian/zynthian-my-data/sketches/default-sketches').mkdir(exist_ok=True, parents=True)
        Path('/zynthian/zynthian-my-data/sketches/my-sketches').mkdir(exist_ok=True, parents=True)
        Path('/zynthian/zynthian-my-data/sketches/community-sketches').mkdir(exist_ok=True, parents=True)
        Path('/zynthian/zynthian-my-data/device-settings/my-device-settings').mkdir(exist_ok=True, parents=True)
        Path('/zynthian/zynthian-my-data/device-settings/community-device-settings').mkdir(exist_ok=True, parents=True)
        Path('/zynthian/zynthian-my-data/sounds/my-sounds').mkdir(exist_ok=True, parents=True)
        Path('/zynthian/zynthian-my-data/sounds/community-sounds').mkdir(exist_ok=True, parents=True)
#        Path('/zynthian/zynthian-my-data/sample-banks/my-samplebanks').mkdir(exist_ok=True, parents=True)
#        Path('/zynthian/zynthian-my-data/sample-banks/community-samplebanks').mkdir(exist_ok=True, parents=True)

        self.song_changed.connect(lambda: self.lastSelectedObj.reset())

    def init(self):
        def _cb():
            Zynthbox.PlayGridManager.instance().metronomeBeat4thChanged.connect(self.metronome_update)
            self.selectedTrackId = 0
            self.__is_init_in_progress__ = False
            logging.info("Sketchpad Initialization Complete")

            self.zynqtgui.zynautoconnect(True)

            for i in range(0, self.__song__.channelsModel.count):
                channel = self.__song__.channelsModel.getChannel(i)
                channel.update_jack_port()

        lastSelectedSketchpad = self.zynqtgui.global_settings.value("Sketchpad/lastSelectedSketchpad", None)
        self.zynqtgui.layer.layer_created.connect(self.emit_chained_sounds_changed, Qt.QueuedConnection)
        self.zynqtgui.layer_effects.fx_layers_changed.connect(self.emit_chained_sounds_changed, Qt.QueuedConnection)
        if lastSelectedSketchpad is not None and Path(lastSelectedSketchpad).exists():
            # Existing sketch found. Load last_state snapshot after loading sketchpad
            self.loadSketchpad(lastSelectedSketchpad, load_autosave=True, load_snapshot=False, cb=_cb, load_last_state_snapshot=True)
        else:
            # Existing sketch not found. Load default snapshot after loading sketchpad
            self.newSketchpad(base_sketchpad=None, cb=_cb, load_snapshot=False, load_last_state_snapshot=True)

        storedMetronomeEnabled = self.zynqtgui.global_settings.value("Sketchpad/metronomeEnabled", None)
        if storedMetronomeEnabled is not None:
            self.set_metronomeEnabled(True if storedMetronomeEnabled == "true" else False)
        storedMetronomeVolume = self.zynqtgui.global_settings.value("Sketchpad/metronomeVolume", None)
        if storedMetronomeVolume is not None:
            # First set one of the clips volume
            self.metronome_clip_tick.rootSlice().gainHandler().setGain(float(storedMetronomeVolume))
            # Then set the internal volume to what that volume is from 0 to 1
            self.set_metronomeVolume(self.metronome_clip_tick.rootSlice().gainHandler().gainAbsolute())

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

    ### BEGIN Property copySourceObj
    def get_copySourceObj(self):
        return self.__copy_source_obj

    copySourceObj = Property(QObject, get_copySourceObj, constant=True)
    ### END Property lastSelectedObj

    ### BEGIN Property sketchpadLoadingInProgress
    def get_sketchpadLoadingInProgress(self):
        return self.__sketchpad_loading_in_progress

    def set_sketchpadLoadingInProgress(self, value):
        if self.__sketchpad_loading_in_progress != value:
            self.__sketchpad_loading_in_progress = value
            self.sketchpadLoadingInProgressChanged.emit()

    sketchpadLoadingInProgressChanged = Signal()

    sketchpadLoadingInProgress = Property(QObject, get_sketchpadLoadingInProgress, set_sketchpadLoadingInProgress, notify=sketchpadLoadingInProgressChanged)
    ### END Property sketchpadLoadingInProgress

    ### BEGIN Property selectedTrackId
    def get_selected_track_id(self):
        return self.__selected_track_id
    def set_selected_track_id(self, track_id, force_set=False, shouldEmitCurrentTrackClipCUIAFeedback=True):
        if self.__selected_track_id != int(track_id) or force_set is True:
            logging.debug(f"### Setting selected track : channel({int(track_id)})")
            self.__selected_track_id = max(0, min(int(track_id), Zynthbox.Plugin.instance().sketchpadTrackCount() - 1))
            self.selected_track_id_changed.emit()
            if self.__fixed_layers_fill_list_timer is None:
                self.__fixed_layers_fill_list_timer = QTimer(self)
                self.__fixed_layers_fill_list_timer.setInterval(100)
                self.__fixed_layers_fill_list_timer.setSingleShot(True)
                self.__fixed_layers_fill_list_timer.timeout.connect(self.zynqtgui.fixed_layers.fill_list, Qt.QueuedConnection)
            if self.__update_channel_sounds_timer is None:
                self.__update_channel_sounds_timer = QTimer(self)
                self.__update_channel_sounds_timer.setInterval(500)
                self.__update_channel_sounds_timer.setSingleShot(True)
                self.__update_channel_sounds_timer.timeout.connect(self.zynqtgui.layers_for_channel.update_channel_sounds, Qt.QueuedConnection)
            self.__fixed_layers_fill_list_timer.start()
            self.__update_channel_sounds_timer.start()
            Zynthbox.MidiRouter.instance().cuiaEventFeedback("ACTIVATE_TRACK", -1, Zynthbox.ZynthboxBasics.Track(self.__selected_track_id), Zynthbox.ZynthboxBasics.Slot.AnySlot, 0)
            if shouldEmitCurrentTrackClipCUIAFeedback:
                self.emitCurrentTrackClipCUIAFeedback()
    selected_track_id_changed = Signal()
    selectedTrackId = Property(int, get_selected_track_id, set_selected_track_id, notify=selected_track_id_changed)
    ### END Property selectedTrackId

    @Slot(None)
    def emitCurrentTrackClipCUIAFeedback(self):
        trackDivisor = 128.0 / float(Zynthbox.Plugin.instance().sketchpadTrackCount())
        Zynthbox.MidiRouter.instance().cuiaEventFeedback("ACTIVATE_TRACK_RELATIVE", -1, Zynthbox.ZynthboxBasics.Track.AnyTrack, Zynthbox.ZynthboxBasics.Slot.AnySlot, (trackDivisor * self.__selected_track_id))
        Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_TRACK_SOLOED", -1, Zynthbox.ZynthboxBasics.Track.CurrentTrack, Zynthbox.ZynthboxBasics.Slot.AnySlot, 1 if self.__song__.playChannelSolo == self.__selected_track_id else 0)
        theTrack = self.__song__.channelsModel.getChannel(self.__selected_track_id)
        Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_TRACK_MUTED", -1, Zynthbox.ZynthboxBasics.Track.CurrentTrack, Zynthbox.ZynthboxBasics.Slot.AnySlot, 1 if theTrack.muted else 0)
        Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_TRACK_VOLUME", -1, Zynthbox.ZynthboxBasics.Track.CurrentTrack, Zynthbox.ZynthboxBasics.Slot.AnySlot, np.interp(theTrack.gainHandler.gainAbsolute(), (0, 1), (0, 127)))
        Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_CLIP_CURRENT", -1, Zynthbox.ZynthboxBasics.Track.CurrentTrack, Zynthbox.ZynthboxBasics.Slot(theTrack.selectedClip), 0)
        Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_CLIP_CURRENT_RELATIVE", -1, Zynthbox.ZynthboxBasics.Track.CurrentTrack, Zynthbox.ZynthboxBasics.Slot.AnySlot, np.interp(theTrack.selectedClip, (0, Zynthbox.Plugin.instance().sketchpadSlotCount() - 1), (0, 127)))
        Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_TRACK_PAN", -1, Zynthbox.ZynthboxBasics.Track.CurrentTrack, Zynthbox.ZynthboxBasics.Slot.AnySlot, np.interp(theTrack.pan, (0, 1), (0, 127)))
        Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_TRACK_SEND1_AMOUNT", -1, Zynthbox.ZynthboxBasics.Track.CurrentTrack, Zynthbox.ZynthboxBasics.Slot.AnySlot, np.interp(theTrack.wetFx1Amount, (0, 1), (0, 127)))
        Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_TRACK_SEND2_AMOUNT", -1, Zynthbox.ZynthboxBasics.Track.CurrentTrack, Zynthbox.ZynthboxBasics.Slot.AnySlot, np.interp(theTrack.wetFx2Amount, (0, 1), (0, 127)))
        theTrack.emitCurrentClipCUIAFeedback()

    @Slot(None)
    def emit_chained_sounds_changed(self):
        selected_channel = self.song.channelsModel.getChannel(self.selectedTrackId)
        if selected_channel is not None:
            selected_channel.set_chained_sounds(selected_channel.get_chained_sounds())
            selected_channel.update_jack_port()
        self.song.channelsModel.connected_sounds_count_changed.emit()

    ### BEGIN Property metronomeEnabled
    @Signal
    def metronomeEnabledChanged(self):
        pass

    def get_metronomeEnabled(self):
        return Zynthbox.SyncTimer.instance().audibleMetronome()

    def set_metronomeEnabled(self, enabled: bool):
        Zynthbox.SyncTimer.instance().setAudibleMetronome(enabled)
        if self.zynqtgui.isBootingComplete:
            self.zynqtgui.global_settings.setValue("Sketchpad/metronomeEnabled", enabled)

    metronomeEnabled = Property(bool, get_metronomeEnabled, set_metronomeEnabled, notify=metronomeEnabledChanged)
    ### END Property metronomeEnabled

    ### BEGIN Property metronomeVolume
    def get_metronomeVolume(self):
        return self.__metronomeVolume

    def set_metronomeVolume(self, volume):
        if self.__metronomeVolume != volume:
            self.__metronomeVolume = volume
            self.metronome_clip_tick.rootSlice().gainHandler().setGainAbsolute(self.__metronomeVolume)
            self.metronome_clip_tock.rootSlice().gainHandler().setGainAbsolute(self.__metronomeVolume)
            self.metronomeVolumeChanged.emit()
            if self.zynqtgui.isBootingComplete:
                self.zynqtgui.global_settings.setValue("Sketchpad/metronomeVolume", self.metronome_clip_tick.rootSlice().gainHandler().gain())

    metronomeVolumeChanged = Signal()

    metronomeVolume = Property(float, get_metronomeVolume, set_metronomeVolume, notify=metronomeVolumeChanged)
    ### END Property metronomeVolume

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

    # Fallback for loading sequences from old sketchpads. This will try to check if there are any sequences from old sketchpad structure where the sequences were saved globally across all versions.
    # If old global sequences are found and new sequences directory do not exist, it will copy the global sequences to all the versions.
    # TODO : Remove after a considerable amount of time or when we are sure that all the old sketchpads got updated. Or maybe before a stable release
    def checkOldSequencesAndApplyFallback(self, sketchpad_path):
        sketchpad_path = Path(sketchpad_path)
        if (sketchpad_path.parent / "sequences" / "global").exists():
            for version in sketchpad_path.parent.glob("*.sketchpad.json"):
                version = version.name.replace(".sketchpad.json", "")
                if not (sketchpad_path.parent / "sequences" / version).exists():
                    logging.debug(f"Found version {version} that does not have sequences although there is a global sequences dir. Applying fallback.")
                    shutil.copytree(sketchpad_path.parent / "sequences" / "global", sketchpad_path.parent / "sequences" / version / "global")
            # Save the global patterns to autosave version explicitly
            shutil.copytree(sketchpad_path.parent / "sequences" / "global", sketchpad_path.parent / "sequences" / "autosave" / "global")
            # Remove the old sequences structure after applying fallback
            shutil.rmtree(sketchpad_path.parent / "sequences" / "global")

    @Slot(str)
    def newSketchpadFromFolder(self, sketchpadFolder):
        justTheFiles = [f for f in os.listdir(sketchpadFolder) if os.path.isfile(os.path.join(sketchpadFolder, f))]
        for aFile in justTheFiles:
            if aFile.endswith(".sketchpad.json"):
                self.newSketchpad(os.path.join(sketchpadFolder, aFile))
                break

    @Slot(None)
    def newSketchpad(self, base_sketchpad=None, cb=None, load_snapshot=True, force=False, load_last_state_snapshot=False):
        def task():
            self.zynqtgui.currentTaskMessage = "Stopping playback"

            try:
                self.stopAllPlayback()
                self.zynqtgui.screens["playgrid"].stopMetronomeRequest()
            except:
                pass

            old_song = self.__song__
            # Mark old song to be deleted to not perform any operations on it
            if old_song is not None:
                old_song.to_be_deleted()

            if (self.__sketchpad_basepath__ / 'temp').exists():
                self.zynqtgui.currentTaskMessage = "Removing existing temp sketchpad"
                shutil.rmtree(self.__sketchpad_basepath__ / 'temp')

            # Reset the keyzoning state when creating a new sketch (essentially to be on the safe side, it should otherwise be reset whenever we load/create synths)
            for synthSlot in range(0, 16):
                Zynthbox.MidiRouter.instance().setZynthianSynthKeyzones(synthSlot, 0, 127, 60)
            if base_sketchpad is not None:
                logging.info(f"Creating New Sketchpad from community sketchpad : {base_sketchpad}")
                self.zynqtgui.currentTaskMessage = "Copying community sketchpad to my sketchpads"
                base_sketchpad_path = Path(base_sketchpad)
                # Copy community sketchpad to my sketchpads
                new_sketchpad_name = self.generate_unique_mysketchpad_name(base_sketchpad_path.parent.name)
                shutil.copytree(base_sketchpad_path.parent, self.__sketchpad_basepath__ / new_sketchpad_name)
                # TODO : Remove after a considerable amount of time or when we are sure that all the old sketchpads got updated. Or maybe before a stable release
                self.checkOldSequencesAndApplyFallback(self.__sketchpad_basepath__ / new_sketchpad_name / base_sketchpad_path.name)
                logging.info(f"Loading new sketchpad from community sketchpad : {str(self.__sketchpad_basepath__ / new_sketchpad_name / base_sketchpad_path.name)}")
                self.__song__ = sketchpad_song.sketchpad_song(str(self.__sketchpad_basepath__ / new_sketchpad_name) + "/", base_sketchpad_path.stem.replace(".sketchpad", ""), self, load_autosave=False)
                self.zynqtgui.global_settings.setValue("Sketchpad/lastSelectedSketchpad", str(self.__sketchpad_basepath__ / new_sketchpad_name / base_sketchpad_path.name))
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
                self.song_changed.emit()
                self.selectedTrackId = 0
            else:
                logging.info("Creating New Sketchpad")
                # Reset global fx to 100%
                self.zynqtgui.global_fx_engines[0][1].value = self.zynqtgui.global_fx_engines[0][1].value_max
                self.zynqtgui.global_fx_engines[1][1].value = self.zynqtgui.global_fx_engines[1][1].value_max
                self.zynqtgui.currentTaskMessage = "Creating empty sketchpad as temp sketchpad"
                self.__song__ = sketchpad_song.sketchpad_song(str(self.__sketchpad_basepath__ / "temp") + "/", "Sketchpad-1", self, load_autosave=False)
                # When zynqtgui is starting, it will load last_state or default snapshot
                # based on the value of self.init_should_load_last_state
                # Do not load snapshot again otherwise it will create multiple processes for same synths
                if load_snapshot:
                    if Path("/zynthian/zynthian-my-data/snapshots/default.zss").exists():
                        logging.info(f"Loading default snapshot")
                        self.zynqtgui.currentTaskMessage = "Loading snapshot"
                        self.zynqtgui.screens["layer"].load_snapshot("/zynthian/zynthian-my-data/snapshots/default.zss")
                if load_last_state_snapshot:
                    if not self.zynqtgui.screens["snapshot"].load_default_snapshot():
                        # Show error if loading default snapshot fails
                        logging.error("Error loading default snapshot")
                self.zynqtgui.global_settings.setValue("Sketchpad/lastSelectedSketchpad", str(self.__sketchpad_basepath__ / 'temp' / 'Sketchpad-1.sketchpad.json'))
                # Connect all jack ports of respective channel after jack client initialization is done.
                for i in range(0, self.__song__.channelsModel.count):
                    channel = self.__song__.channelsModel.getChannel(i)
                    channel.update_jack_port()
                self.song_changed.emit()
                self.selectedTrackId = 0
                self.newSketchpadLoaded.emit()

            # Delete old song object after creating a new song instance
            if old_song is not None:
                old_song.deleteLater()

            # Update volume controls
            self.zynqtgui.fixed_layers.fill_list()
            # Reset last selected item
            self.lastSelectedObj.reset()

            if cb is not None:
                cb()

            self.sketchpadLoadingInProgress = False
            self.zynqtgui.zynautoconnect()
            if self.zynqtgui.isBootingComplete:
                self.zynqtgui.currentTaskMessage = "Finalizing"
            # Schedule a save sketchpad file is available after creating a new sketchpad
            self.song.schedule_save()
            self.longOperationDecrement()
            QTimer.singleShot(1000, self.zynqtgui.end_long_task)

        def confirmNewSketchpad(params=None):
            self.longOperationIncrement()
            self.sketchpadLoadingInProgress = True
            self.zynqtgui.do_long_task(task, "Creating New Sketchpad")

        if not force and self.zynqtgui.isBootingComplete and self.song.hasUnsavedChanges:
            self.zynqtgui.show_confirm("You have unsaved changes. Do you really want to continue?", confirmNewSketchpad)
        else:
            confirmNewSketchpad()

    @Slot(None)
    def saveSketchpad(self, cb=None):
        def task():
            self.__song__.save(autosave=False)
            if cb is not None:
                cb()
            QTimer.singleShot(1000, self.zynqtgui.end_long_task)

        self.zynqtgui.do_long_task(task, "Saving sketchpad")

    @Slot(str)
    def createSketchpad(self, name):
        def task():
            obj = {}
            self.stopAllPlayback()
            self.zynqtgui.screens["playgrid"].stopMetronomeRequest()            

            # Mark old song to be deleted to not perform any operations on it
            old_song = self.__song__
            if old_song is not None:
                old_song.to_be_deleted()

            # Rename temp sketchpad folder to the user defined name
            Path(self.__sketchpad_basepath__ / 'temp').rename(self.__sketchpad_basepath__ / name)
            # Rename temp sketchpad json filename to user defined name
            Path(self.__sketchpad_basepath__ / name / (self.__song__.name + ".sketchpad.json")).rename(self.__sketchpad_basepath__ / name / (name + ".sketchpad.json"))

            # Save a sequence for this version to the user defined name
            sequenceModel = Zynthbox.PlayGridManager.instance().getSequenceModel(self.__song__.scenesModel.selectedSequenceName)
            sequenceModel.exportTo(f"{self.__sketchpad_basepath__ / name}/sequences/{name}/{sequenceModel.objectName().lower().replace(' ', '-')}/metadata.sequence.json")

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

            self.__song__ = sketchpad_song.sketchpad_song(str(self.__sketchpad_basepath__ / name) + "/", name, self, load_autosave=False, clear_passthroughs=False)

            # FX layers gets added to channel fx slots during snapshot loading
            # Since snapshot is not loaded when creating a sketchpad from temp, add FX layers to channels explicitly here
            for layer in self.zynqtgui.layer.layers:
                if layer.engine.type == "Audio Effect":
                    self.song.channelsModel.getChannel(layer.track_index).setFxToChain(layer, layer.slot_index)

            self.zynqtgui.global_settings.setValue("Sketchpad/lastSelectedSketchpad", str(self.__sketchpad_basepath__ / name / f'{name}.sketchpad.json'))
            self.__song__.save(False)
            self.selectedTrackId = 0
            self.song_changed.emit()

            # Delete old song object after creating a new song instance
            if old_song is not None:
                old_song.deleteLater()

            self.longOperationDecrement()
            QTimer.singleShot(1000, self.zynqtgui.end_long_task)

        self.longOperationIncrement()
        self.zynqtgui.do_long_task(task, f"Saving Sketchpad : {name}")

    @Slot(str)
    def saveCopy(self, name, cb=None):
        def task():
            old_folder = self.__song__.sketchpad_folder
            shutil.copytree(old_folder, self.__sketchpad_basepath__ / name)
            if cb is not None:
                cb()
            QTimer.singleShot(1000, self.zynqtgui.end_long_task)

        self.zynqtgui.do_long_task(task, "Saving a copy of the sketchpad to {name}")

    @Slot(str, bool)
    def loadSketchpad(self, sketchpad, load_autosave, load_snapshot=True, cb=None, load_last_state_snapshot=False):
        def task():
            logging.info(f"Loading sketchpad : {sketchpad}")

            sketchpad_path = Path(sketchpad)

            # self.zynqtgui.currentTaskMessage = "Stopping playback"
            try:
                self.zynqtgui.run_stop_metronome_and_playback.emit()
            except:
                pass

            # Prepare a regex to check if a sketchpad json is from community-sketchpads
            community_sketchpads_regex = re.compile(".*/zynthian-my-data/sketchpads/community-sketchpads/.*")
            # If the regex matches a string, it returns a re.Match object otherwise returns None
            # We do not need the matched string but instead we just need to check if the string matched.
            # If string matched the regex, it means the sketchpad is from community and hence ask to create a new sketchpad using the community one as a base
            if community_sketchpads_regex.match(sketchpad) is not None:
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
                self.newSketchpad(sketchpad, _cb, load_snapshot=load_snapshot, force=True)
            else:
                logging.info(f"Loading Sketchpad : {str(sketchpad_path.parent.absolute()) + '/'}, {str(sketchpad_path.stem)}")
                self.zynqtgui.currentTaskMessage = f"Loading Sketchpad:<br />{str(sketchpad_path.parent.name)}"
                self.sketchpadLoadingInProgress = True

                # Mark old song to be deleted to not perform any operations on it
                old_song = self.__song__
                if old_song is not None:
                    old_song.to_be_deleted()

                # TODO : Remove after a considerable amount of time or when we are sure that all the old sketchpads got updated. Or maybe before a stable release
                self.checkOldSequencesAndApplyFallback(sketchpad_path)
                self.__song__ = sketchpad_song.sketchpad_song(str(sketchpad_path.parent.absolute()) + "/", str(sketchpad_path.stem.replace(".sketchpad", "")), self, load_autosave)
                self.zynqtgui.global_settings.setValue("Sketchpad/lastSelectedSketchpad", str(sketchpad_path))

                if load_snapshot:
                    snapshot_path = str(sketchpad_path.parent.absolute()) + '/soundsets/' + str(sketchpad_path.stem.replace('.sketchpad', '')) + '.zss'
                    # Load snapshot
                    if Path(snapshot_path).exists():
                        logging.info(f"Loading snapshot : {snapshot_path}")
                        self.zynqtgui.currentTaskMessage = "Loading Sketchpad : Restoring Snapshot"
                        self.zynqtgui.screens["layer"].load_snapshot(snapshot_path)
                    elif Path("/zynthian/zynthian-my-data/snapshots/default.zss").exists():
                        logging.info(f"Loading default snapshot")
                        self.zynqtgui.currentTaskMessage = "Loading Sketchpad : Loading Default Snapshot"
                        self.zynqtgui.screens["layer"].load_snapshot("/zynthian/zynthian-my-data/snapshots/default.zss")
                if load_last_state_snapshot:
                    if not self.zynqtgui.screens["snapshot"].load_last_state_snapshot():
                        # Try loading default snapshot if loading last_state snapshot fails
                        if not self.zynqtgui.screens["snapshot"].load_default_snapshot():
                            # Show error if loading default snapshot fails
                            logging.error("Error loading default snapshot")

                # Update volume controls
                self.zynqtgui.fixed_layers.fill_list()
                self.selectedTrackId = 0
                self.song_changed.emit()

                # Delete old song object after creating a new song instance
                if old_song is not None:
                    old_song.deleteLater()

                # Reset last selected item
                self.lastSelectedObj.reset()

                # Connect all jack ports of respective channel after jack client initialization is done.
                for i in range(0, self.__song__.channelsModel.count):
                    channel = self.__song__.channelsModel.getChannel(i)
                    channel.update_jack_port()

                if cb is not None:
                    cb()

                self.sketchpadLoadingInProgress = False
                self.zynqtgui.zynautoconnect()

                if self.zynqtgui.isBootingComplete:
                    self.zynqtgui.currentTaskMessage = "Finalizing"
                self.longOperationDecrement()
                QTimer.singleShot(1000, self.zynqtgui.end_long_task)

        def confirmLoadSketchpad(params=None):
            self.longOperationIncrement()
            self.zynqtgui.do_long_task(task, "Loading Sketchpad")

        if self.zynqtgui.isBootingComplete and self.song.hasUnsavedChanges:
            self.zynqtgui.show_confirm("You have unsaved changes. Do you really want to continue?", confirmLoadSketchpad)
        else:
            confirmLoadSketchpad()

    @Slot(str)
    def createNamedEmptySketchpad(self, name):
        """
        A helper method to create a named empty sketchpad for use with webconf via OSC
        """
        sketchpad_name = name.replace(".sketchpad.json", "")
        song = sketchpad_song.sketchpad_song(str(self.__sketchpad_basepath__ / sketchpad_name), sketchpad_name, self, load_autosave=False)
        song.save(autosave=False, save_empty=True)
        song.to_be_deleted()
        song.deleteLater()

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
        if self.__song__ is not None and self.__song__.channelsModel is not None and self.__song__.scenesModel is not None:
            for trackIndex in range(0, Zynthbox.Plugin.instance().sketchpadTrackCount()):
                channel = self.__song__.channelsModel.getChannel(trackIndex)
                if channel is not None:
                    for clipId in range(0, Zynthbox.Plugin.instance().sketchpadSlotCount()):
                        clipsModel = channel.getClipsModelById(clipId)
                        if clipsModel is not None:
                            clip = clipsModel.getClip(self.__song__.scenesModel.selectedSketchpadSongIndex)
                            if clip is not None:
                                clip.stop()

    @Slot(QObject,result=str)
    def get_channel_recording_filename(self, channel):
        generated_path = ""
        preset_name = "no-preset"
        if channel.trackType == "synth":
            layers_snapshot = json.loads(channel.getChannelSoundSnapshot())
            try:
                preset_name = layers_snapshot['layers'][0]['preset_name'].replace(' ', '-').replace('/', '-')
            except:
                preset_name = "no-layer"
        elif channel.trackType == "sample-trig":
            preset_name = "samples"
        count = 0
        base_recording_dir = f"{self.__song__.sketchpad_folder}wav"
        base_filename = f"{Zynthbox.Plugin.instance().currentTimestamp()}_{preset_name}_{Zynthbox.SyncTimer.instance().getBpm()}-BPM"
        # Check if file exists otherwise append count
        while Path(f"{base_recording_dir}/{base_filename}{'-'+str(count) if count > 0 else ''}.sketch.wav").exists():
            count += 1
        generated_path = f"{base_recording_dir}/{base_filename}{'-'+str(count) if count > 0 else ''}.sketch.wav"
        return generated_path

    def queue_clip_record(self, clip, do_countin = True):
        """
        This method will return True if the clip was successfully queued and False when there was any error while queueing
        """

        # When sketchpad is open, curLayer is not updated when changing channels as it is a considerably heavy task
        # but not necessary to change to selected channel's synth.
        # Hence make sure to update curLayer before doing operations depending upon curLayer
        self.zynqtgui.screens["layers_for_channel"].do_activate_midich_layer()
        channel = self.__song__.channelsModel.getChannel(self.zynqtgui.sketchpad.selectedTrackId)
        layers_snapshot = self.zynqtgui.layer.generate_snapshot(channel)

        if clip.isChannelSample:
            Path(clip.clipChannel.bankDir).mkdir(parents=True, exist_ok=True)
        else:
            (Path(clip.recording_basepath) / 'wav').mkdir(parents=True, exist_ok=True)

        if self.recordingSource.startswith('internal'):
            # If source is internal and there are no layers, show error and return.
            if channel.occupiedSlotsCount == 0 and channel.occupiedSampleSlotsCount == 0:
                self.zynqtgui.showMessageDialog.emit("The source track has no sound. Cannot start recording", 3000)
                return False

            try:
                # FIXME This gets weird if there is only samples, or if there is more than one synth engine
                preset_name = layers_snapshot['layers'][0]['preset_name'].replace(' ', '-').replace('/', '-')
            except:
                preset_name = ""
        else:
            preset_name = "external"

        if clip.isChannelSample:
            base_recording_dir = clip.clipChannel.bankDir
        else:
            base_recording_dir = f"{clip.recording_basepath}/wav"

        base_filename = f"{Zynthbox.Plugin.instance().currentTimestamp()}_{preset_name}_{Zynthbox.SyncTimer.instance().getBpm()}-BPM"

        # Check if file exists otherwise append count
        count = 0
        while Path(f"{base_recording_dir}/{base_filename}{'-'+str(count) if count > 0 else ''}.sketch.wav").exists():
            count += 1

        self.clip_to_record_path = f"{base_recording_dir}/{base_filename}{'-'+str(count) if count > 0 else ''}.sketch.wav"

        if self.recordingType == "audio":
            if self.recordingSource.startswith('internal'):
                self.__last_recording_type__ = "Internal"

                if self.recordingSource == "internal-master":
                    recording_ports = {
                        0: ["GlobalPlayback:dryOutLeft"],
                        1: ["GlobalPlayback:dryOutRight"]
                    }
                elif  self.recordingSource == "internal-track":
                    recording_ports = channel.channelSoundRecordingPorts
                else:
                    self.zynqtgui.showMessageDialog.emit("Invalid recording source", 3000)
                    # As we're bailing, clear this for side effect reduction
                    self.clip_to_record_path = ""
                    return False
            else:
                # TODO : Port external recording to AudioLevels recorder

                if self.recordingChannel == "1":
                    self.__last_recording_type__ = "External (Mono Left)"
                    recording_ports = {
                        0: ["system:capture_1"]
                    }
                elif self.recordingChannel == "2":
                    self.__last_recording_type__ = "External (Mono Right)"
                    recording_ports = {
                        0: ["system:capture_2"]
                    }
                else:
                    self.__last_recording_type__ = "External (Stereo)"
                    recording_ports = {
                        0: ["system:capture_1"],
                        1: ["system:capture_2"]
                    }

            logging.debug(f"Queueing clip({clip}) to record with source({self.recordingSource}), ports({recording_ports}), recordingType({self.__last_recording_type__})")

            Zynthbox.AudioLevels.instance().setShouldRecordPorts(True)
            Zynthbox.AudioLevels.instance().setRecordPortsFilenamePrefix(self.clip_to_record_path)
            Zynthbox.AudioLevels.instance().clearRecordPorts()

            for channel in recording_ports:
                for port in recording_ports[channel]:
                    logging.debug(f"Adding record port : port({port}), channel({channel})")
                    Zynthbox.AudioLevels.instance().addRecordPort(port, channel)

        # These are done at the end, to ensure that if we bail out early, we don't leave some kind of nasty state behind
        self.set_clip_to_record(clip)
        if do_countin:
            self.ongoingCountIn = self.countInBars + 1

        self.isRecording = True
        return True

    @Slot(None)
    def stopRecording(self):
        if self.clip_to_record is not None and self.isRecording:
            if Zynthbox.AudioLevels.instance().isRecording() == False and Zynthbox.MidiRecorder.instance().isRecording() == False:
                def task():
                    Zynthbox.AudioLevels.instance().clearRecordPorts()
                    self.set_lastRecordingMidi(Zynthbox.MidiRecorder.instance().base64TrackMidi(Zynthbox.PlayGridManager.instance().currentSketchpadTrack()))
                    self.load_recorded_file_to_clip()
                    self.set_lastRecordingMidi("")

                    # If recording stopped with the recording popup is closed, change track types to match the newly created recording
                    if self.zynqtgui.recordingPopupActive == False:
                        currentTrack = self.__song__.channelsModel.getChannel(self.zynqtgui.sketchpad.selectedTrackId)
                        if self.clip_to_record.isChannelSample:
                            # When recording a sample, set the track type to synth
                            currentTrack.trackType = "synth"
                        else:
                            # When recording a sketch (any other case), set track type to Sketch explicitly
                            currentChannel.trackType = "sample-loop"

                    self.set_clip_to_record(None)
                    self.clip_to_record_path = None
                    self.__last_recording_type__ = ""

                    self.isRecording = False
                    self.longOperationDecrement()
                    QTimer.singleShot(300, self.zynqtgui.end_long_task)

                self.longOperationIncrement()
                self.zynqtgui.do_long_task(task, "Processing recording")
            else:
                logging.debug("Recording not yet stopped. Retrying in a bit.")
                self.__stopRecordingRetrier__.start()

    # Called by SyncTimer to ensure the current scene gets started as expected
    # To actually start playback, call start_metronome_request, or manually call SyncTimer::scheduleStartPlayback
    @Slot(None)
    def startPlayback(self):
        if not self.is_recording or \
                (self.is_recording and not self.recordSolo):
            self.__song__.scenesModel.playScene(self.__song__.scenesModel.selectedSceneIndex,
                                                self.__song__.scenesModel.selectedSketchpadSongIndex)

    def start_metronome_request(self):
        logging.debug(f"Start Metronome Request : while timer is running:{self.isMetronomeRunning}")
        if self.isMetronomeRunning == False:
            Zynthbox.SyncTimer.instance().scheduleStartPlayback(0)

    def stop_metronome_request(self):
        logging.debug(f"Stop Metronome Request : while timer is running:{self.isMetronomeRunning}")
        if self.isMetronomeRunning == True:
            Zynthbox.SyncTimer.instance().scheduleStopPlayback(0)

    def metronome_update(self, beat):
        self.__current_bar__ = math.floor(Zynthbox.SyncTimer.instance().cumulativeBeat() / (Zynthbox.SyncTimer.instance().getMultiplier() * 4))
        self.__current_beat__ = beat
        self.current_bar_changed.emit()
        self.current_beat_changed.emit()
        if self.ongoingCountIn > 0:
            self.ongoingCountIn -= 1

    def load_recorded_file_to_clip(self):
        if self.recordingType == "audio":
            logging.info(f"Loading recorded wav ({self.clip_to_record_path}) to clip({self.clip_to_record}) {self.clip_to_record.channel.id} {self.clip_to_record.id}")
            if not Path(self.clip_to_record_path).exists():
                logging.error("### The recording does not exist! This is a big problem and we will have to deal with that.")
            else:
                # Since this is a new clip, it does not matter if we are loading autosave metadata or not, as it does not have any metadata yet
                # Also, we do not want to copy the clip, as it will have been recorded into an appropriate location inside the sketchpad
                self.zynqtgui.currentTaskMessage = "Loading recording to clip"
                self.clip_to_record.set_path(self.clip_to_record_path, should_copy=False)
                self.clip_to_record.enabled = True
                ### Save clip metadata
                # When processing a sample, do not write sound metadata. It does not need to have sound metadata
                # When processing a skit, do write sound metadata. Sound metadata is not saved unless explicitly asked for. It is a potentially heavy task as it needs to write a lot of data
                ###
                self.clip_to_record.metadata.write(writeSoundMetadata=not self.clip_to_record.is_channel_sample)
                if self.clip_to_record.isChannelSample:
                    # logging.info("Recorded clip is a sample")
                    self.clip_to_record.channel.samples_changed.emit()

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
        return Zynthbox.SyncTimer.instance().timerRunning()

    cannotRecordEmptyLayer = Signal()
    newSketchpadLoaded = Signal()
