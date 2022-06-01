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
import threading
import uuid
from datetime import datetime
from os.path import dirname, realpath
from pathlib import Path
from subprocess import Popen, PIPE
from time import sleep
import json

import numpy as np
from PySide2.QtCore import QMetaObject, Qt, Property, QObject, QProcess, QTimer, Signal, Slot

from .libzl.libzl import ClipAudioSource

sys.path.insert(1, "./libzl")
from .libzl import libzl
from .libzl import zynthiloops_song
from .libzl import zynthiloops_clip

from .. import zynthian_qt_gui_base
from .. import zynthian_gui_controller
from .. import zynthian_gui_config
from zyngine import zynthian_controller
import jack


@ctypes.CFUNCTYPE(None, ctypes.c_int)
def libzlCb(beat):
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

        logging.info(f"Initializing Zynthiloops")

        zynthian_gui_zynthiloops.__instance__ = self
        libzl.registerGraphicTypes()
        self.is_set_selector_running = False
        self.recorder_process = None
        self.clip_to_record = None
        self.clip_to_record_path = None
        self.clip_to_record_path = None
        self.__current_beat__ = -1
        self.__current_bar__ = -1
        self.metronome_schedule_stop = False
        self.metronome_running_refcount = 0
        self.__sketch_basepath__ = Path("/zynthian/zynthian-my-data/sketches/my-sketches/")
        self.__clips_queue__: list[zynthiloops_clip] = []
        self.is_recording_complete = False
        self.recording_count_in_value = 0
        self.recording_complete.connect(lambda: self.load_recorded_file_to_clip())
        self.click_track_click = ClipAudioSource(None, (dirname(realpath(__file__)) + "/assets/click_track_click.wav").encode('utf-8'))
        self.click_track_clack = ClipAudioSource(None, (dirname(realpath(__file__)) + "/assets/click_track_clack.wav").encode('utf-8'))
        self.click_track_enabled = False
        self.jack_client = None
        self.__jack_client_init_timer__ = QTimer()
        self.__jack_client_init_timer__.setInterval(1000)
        self.__jack_client_init_timer__.setSingleShot(True)
        self.__jack_client_init_timer__.timeout.connect(self.init_jack_client)
        self.recorder_process = None
        self.recorder_process_internal_arguments = ["--disable-console", "--no-stdin"]
        self.__last_recording_type__ = ""
        self.__capture_audio_level_left__ = -400
        self.__capture_audio_level_right__ = -400
        self.__song__ = None
        self.__zselector = [None, None, None, None]
        self.__zselector_ctrl = [None, None, None, None]
        self.__zselector_track = -1
        self.__knob_touch_update_in_progress__ = False
        self.__selected_clip_col__ = 0
        self.__is_init_in_progress__ = True
        self.__long_task_count__ = 0
        self.__big_knob_mode__ = ""
        self.__long_operation__ = False

        self.__master_audio_level__ = -200
        self.master_audio_level_timer = QTimer()
        self.master_audio_level_timer.setInterval(50)
        self.master_audio_level_timer.timeout.connect(self.master_volume_level_timer_timeout)
        self.zyngui.current_screen_id_changed.connect(self.sync_selector_visibility)

        self.__volume_control_obj = None

        Path('/zynthian/zynthian-my-data/samples').mkdir(exist_ok=True, parents=True)
        Path('/zynthian/zynthian-my-data/sample-banks/my-samplebanks').mkdir(exist_ok=True, parents=True)
        Path('/zynthian/zynthian-my-data/sample-banks/community-samplebanks').mkdir(exist_ok=True, parents=True)

    def init_jack_client(self):
        try:
            jack.Client('').get_port_by_name("zynthiloops_audio_levels_client:playback_port_a")
            self.jack_client = jack.Client('zynthiloops_audio_levels_client')
            logging.info(f"*** zynthiloops_audio_levels_client Jack client found. Continuing")

            # Connect all jack ports of respective track after jack client initialization is done.
            for i in range(0, self.__song__.tracksModel.count):
                track = self.__song__.tracksModel.getTrack(i)
                track.update_jack_port()
        except:
            logging.info(f"*** zynthiloops_audio_levels_client Jack client not found. Checking again in 1000ms")
            self.__jack_client_init_timer__.start()

    def connect_control_objects(self):
        if self.__volume_control_obj == self.zyngui.layers_for_track.get_volume_controls()[self.zyngui.session_dashboard.selectedSoundRow]:
            return
        if self.__volume_control_obj:
            self.__volume_control_obj.value_changed.disconnect(self.set_selector)

        self.__volume_control_obj = self.zyngui.layers_for_track.get_volume_controls()[self.zyngui.session_dashboard.selectedSoundRow]

        if self.__volume_control_obj:
            self.__volume_control_obj.value_changed.connect(self.set_selector)
            self.set_selector()

    def sync_selector_visibility(self):
        self.set_selector()

    def init_sketch(self, sketch, cb=None):
        def _cb():
            libzl.registerTimerCallback(libzlCb)

            self.metronomeBeatUpdate4th.connect(self.metronome_update)
            self.zyngui.master_alsa_mixer.volume_changed.connect(lambda: self.master_volume_changed.emit())
            self.update_timer_bpm()
            self.zyngui.trackWaveEditorBarActiveChanged.connect(self.set_selector)
            self.zyngui.clipWaveEditorBarActiveChanged.connect(self.set_selector)
            self.zyngui.session_dashboard.selected_sound_row_changed.connect(self.set_selector)

            if cb is not None:
                cb()

            self.zyngui.zynthiloops.set_selector()
            self.zyngui.session_dashboard.set_selected_track(0, True)
            self.__is_init_in_progress__ = False
            logging.info(f"Zynthiloops Initialization Complete")

        self.master_audio_level_timer.start()

        if sketch is not None:
            logging.debug(f"### Checking Sketch : {sketch} : exists({Path(sketch).exists()}) ")
        else:
            logging.debug(f"### Checking Sketch : sketch is none ")

        if sketch is not None and Path(sketch).exists():
            self.loadSketch(sketch, True, False, _cb)
        else:
            self.newSketch(None, _cb)

    @Slot(None)
    def zyncoder_set_selected_track(self):
        if self.is_set_selector_running:
            logging.info(f"Set selector in progress. Not setting value with encoder")
            return

        if self.__big_knob_mode__ == "track" and self.zyngui.session_dashboard.get_selected_track() != round(self.__zselector[0].value/10):
            logging.debug(f"Setting track from zyncoder {round(self.__zselector[0].value/10)}")
            self.zyngui.session_dashboard.set_selected_track(round(self.__zselector[0].value/10))
            self.set_selector()

    @Slot(None)
    def zyncoder_set_preset(self):
        if self.is_set_selector_running:
            logging.info(f"Set selector in progress. Not setting value with encoder")
            return

        track = self.__song__.tracksModel.getTrack(self.zyngui.session_dashboard.selectedTrack)
        selected_channel = track.get_chained_sounds()[self.zyngui.session_dashboard.selectedSoundRow]

        if self.__big_knob_mode__ == "preset" and selected_channel in self.zyngui.layer.layer_midi_map:
            layer = self.zyngui.layer.layer_midi_map[selected_channel]
            preset_index = min(round(self.__zselector[0].value/1000), len(layer.preset_list) - 1)

            if track.checkIfLayerExists(selected_channel) and layer.preset_index != preset_index:
                logging.debug(f"Selecting preset : {preset_index}")
                layer.set_preset(preset_index, True)
                track.chainedSoundsInfoChanged.emit()
                self.zyngui.fixed_layers.fill_list()

    @Slot(None)
    def zyncoder_update_layer_volume(self):
        if self.is_set_selector_running:
            logging.info(f"Set selector in progress. Not setting value with encoder")
            return

        selected_track = self.__song__.tracksModel.getTrack(self.zyngui.session_dashboard.get_selected_track())

        try:
            if ((self.zyngui.slotsBarTrackActive and selected_track.trackAudioType == "synth") or self.zyngui.slotsBarSynthsActive) and \
                        selected_track.checkIfLayerExists(selected_track.chainedSounds[selected_track.selectedSlotRow]):
                volume_control_obj = self.zyngui.layers_for_track.volume_controls[selected_track.selectedSlotRow]
            elif self.zyngui.sound_combinator_active and \
                    selected_track.checkIfLayerExists(selected_track.chainedSounds[self.zyngui.session_dashboard.selectedSoundRow]):
                volume_control_obj = self.zyngui.layers_for_track.volume_controls[
                    self.zyngui.session_dashboard.selectedSoundRow]
            else:
                volume_control_obj = None
        except:
            volume_control_obj = None

        if volume_control_obj is not None and \
           volume_control_obj.value != self.__zselector[1].value / 1000:
            volume_control_obj.value = self.__zselector[1].value / 1000
            logging.debug(f"### zyncoder_update_layer_volume {volume_control_obj.value}")
            self.set_selector()

    @Slot(None)
    def zyncoder_update_track_volume(self):
        if self.is_set_selector_running:
            logging.info(f"Set selector in progress. Not setting value with encoder")
            return

        selected_track = self.__song__.tracksModel.getTrack(self.zyngui.session_dashboard.get_selected_track())
        volume = np.interp(self.__zselector[1].value, (0, 60), (-40, 20))

        if selected_track.volume != volume:
            # zselector doesnt support negetive mimimum value. Need to interoporale zyncoder value from range(0 to 60) to actual range(-40 to 20)
            selected_track.volume = volume
            logging.debug(f"### zyncoder_update_track_volume {selected_track.volume}")
            self.set_selector()

    @Slot(None)
    def zyncoder_update_clip_start_position(self):
        if self.is_set_selector_running:
            logging.info(f"Set selector in progress. Not setting value with encoder")
            return

        selected_track_obj = self.__song__.tracksModel.getTrack(self.zyngui.session_dashboard.get_selected_track())
        selected_clip = None

        if self.zyngui.trackWaveEditorBarActive:
            selected_clip = selected_track_obj.samples[selected_track_obj.selectedSampleRow]
        elif self.zyngui.clipWaveEditorBarActive:
            selected_clip = self.__song__.getClip(selected_track_obj.id, self.song.scenesModel.selectedMixIndex)

        if selected_clip is not None and selected_clip.startPosition != (self.__zselector[1].value / 1000):
            selected_clip.startPosition = self.__zselector[1].value / 1000
            logging.debug(f"### zyncoder_update_clip_start_position {selected_clip.startPosition}")
            self.set_selector()

    @Slot(None)
    def zyncoder_update_clip_loop(self):
        if self.is_set_selector_running:
            logging.info(f"Set selector in progress. Not setting value with encoder")
            return

        selected_track_obj = self.__song__.tracksModel.getTrack(self.zyngui.session_dashboard.get_selected_track())
        selected_clip = None

        if self.zyngui.trackWaveEditorBarActive:
            selected_clip = selected_track_obj.samples[selected_track_obj.selectedSampleRow]
        elif self.zyngui.clipWaveEditorBarActive:
            selected_clip = self.__song__.getClip(selected_track_obj.id, self.song.scenesModel.selectedMixIndex)

        if selected_clip is not None and selected_clip.loopDelta != self.__zselector[2].value/1000:
            selected_clip.loopDelta = self.__zselector[2].value/1000
            logging.debug(f"### zyncoder_update_clip_loop {selected_clip.loopDelta}")
            self.set_selector()

    @Slot(None)
    def zyncoder_update_clip_length(self):
        if self.is_set_selector_running:
            logging.info(f"Set selector in progress. Not setting value with encoder")
            return

        selected_track_obj = self.__song__.tracksModel.getTrack(self.zyngui.session_dashboard.get_selected_track())
        selected_clip = None

        if self.zyngui.trackWaveEditorBarActive:
            selected_clip = selected_track_obj.samples[selected_track_obj.selectedSampleRow]
        elif self.zyngui.clipWaveEditorBarActive:
            selected_clip = self.__song__.getClip(selected_track_obj.id, self.song.scenesModel.selectedMixIndex)

        if selected_clip is not None and selected_clip.snapLengthToBeat:
            if selected_clip.length != self.__zselector[3].value//100:
                selected_clip.length = self.__zselector[3].value//100
                logging.debug(f"### zyncoder_update_clip_length {selected_clip.length}")
                self.set_selector()
        elif selected_clip is not None and not selected_clip.snapLengthToBeat:
            if selected_clip.length != self.__zselector[3].value/100:
                selected_clip.length = self.__zselector[3].value/100
                logging.debug(f"### zyncoder_update_clip_length {selected_clip.length}")
                self.set_selector()

    def zyncoder_read(self):
        if self.__knob_touch_update_in_progress__:
            return

        if self.__zselector[0] and self.__song__:
            self.__zselector[0].read_zyncoder()

            if self.__big_knob_mode__ == "preset":
                QMetaObject.invokeMethod(self, "zyncoder_set_preset", Qt.QueuedConnection)
            elif self.__big_knob_mode__ == "track":
                QMetaObject.invokeMethod(self, "zyncoder_set_selected_track", Qt.QueuedConnection)

        # Update clip startposition/layer volume when required with small knob 1
        if self.__zselector[1] and self.__song__:
            self.__zselector[1].read_zyncoder()
            if self.zyngui.sound_combinator_active or self.zyngui.slotsBarTrackActive or self.zyngui.slotsBarSynthsActive:
                QMetaObject.invokeMethod(self, "zyncoder_update_layer_volume", Qt.QueuedConnection)
            elif self.zyngui.slotsBarMixerActive:
                QMetaObject.invokeMethod(self, "zyncoder_update_track_volume", Qt.QueuedConnection)
            else:
                QMetaObject.invokeMethod(self, "zyncoder_update_clip_start_position", Qt.QueuedConnection)

        # Update clip length when required with small knob 2
        if self.__zselector[2] and self.__song__:
            self.__zselector[2].read_zyncoder()
            QMetaObject.invokeMethod(self, "zyncoder_update_clip_loop", Qt.QueuedConnection)

        # Update clip length when required with small knob 3
        if self.__zselector[3] and self.__song__:
            self.__zselector[3].read_zyncoder()
            QMetaObject.invokeMethod(self, "zyncoder_update_clip_length", Qt.QueuedConnection)

        return [0, 1, 2, 3]

    def configure_big_knob(self):
        try:
            if self.__zselector[0] is not None:
                self.__zselector[0].show()

            if self.zyngui.sound_combinator_active:
                # If sound combinator is active, Use Big knob to control preset

                self.__big_knob_mode__ = "preset"

                logging.debug(f"### set_selector : Configuring big knob, sound combinator is active.")
                track = self.__song__.tracksModel.getTrack(self.zyngui.session_dashboard.selectedTrack)
                selected_channel = track.get_chained_sounds()[self.zyngui.session_dashboard.selectedSoundRow]
                logging.debug(f"### selectedTrack : track{self.zyngui.session_dashboard.selectedTrack}({track}), slot({self.zyngui.session_dashboard.selectedSoundRow}), channel({selected_channel})")
                preset_index = 0
                max_value = 0

                try:
                    preset_index = self.zyngui.layer.layer_midi_map[selected_channel].preset_index * 1000
                    max_value = (len(self.zyngui.layer.layer_midi_map[selected_channel].preset_list) - 1) * 1000
                except:
                    pass

                if self.__zselector[0] is None:
                    self.__zselector_ctrl[0] = zynthian_controller(None, 'zynthiloops_preset', 'zynthiloops_preset',
                                                                {'midi_cc': 0, 'value': preset_index})

                    self.__zselector[0] = zynthian_gui_controller(zynthian_gui_config.select_ctrl,
                                                                  self.__zselector_ctrl[0], self)
                    self.__zselector[0].show()

                self.__zselector_ctrl[0].set_options(
                    {'symbol': 'zynthiloops_preset', 'name': 'Zynthiloops Preset', 'short_name': 'Preset', 'midi_cc': 0,
                     'value_max': max_value,
                     'value': preset_index})

                self.__zselector[0].config(self.__zselector_ctrl[0])
                self.__zselector[0].custom_encoder_speed = 0
            else:
                # If sound combinator is not active, Use Big knob to control selected track

                self.__big_knob_mode__ = "track"

                try:
                    selected_track = self.zyngui.session_dashboard.get_selected_track() * 10
                except:
                    selected_track = 0

                logging.debug(f"### set_selector : Configuring big knob, sound combinator is not active. selected_track({selected_track // 10})")

                if self.__zselector[0] is None:
                    self.__zselector_ctrl[0] = zynthian_controller(None, 'zynthiloops_track', 'zynthiloops_track',
                                                                {'midi_cc': 0, 'value': selected_track})

                    self.__zselector[0] = zynthian_gui_controller(zynthian_gui_config.select_ctrl, self.__zselector_ctrl[0],
                                                                  self)
                    self.__zselector[0].show()

                self.__zselector_ctrl[0].set_options(
                    {'symbol': 'zynthiloops_track', 'name': 'zynthiloops_track', 'short_name': 'zynthiloops_track', 'midi_cc': 0,
                     'value_max': 90, 'value': selected_track})

                self.__zselector[0].config(self.__zselector_ctrl[0])
                self.__zselector[0].custom_encoder_speed = 0
        except:
            if self.__zselector[0] is not None:
                self.__zselector[0].hide()

    def configure_small_knob_1(self, selected_track, selected_clip):
        if self.__zselector[1] is None:
            self.__zselector_ctrl[1] = zynthian_controller(None, 'zynthiloops_knob1',
                                                            'zynthiloops_knob1',
                                                            {'midi_cc': 0, 'value': 0})

            self.__zselector[1] = zynthian_gui_controller(zynthian_gui_config.select_ctrl, self.__zselector_ctrl[1],
                                                            self)
            self.__zselector[1].index = 0
        if self.zyngui.get_current_screen_id() is not None and \
                self.zyngui.get_current_screen() == self and \
                (
                    (self.zyngui.trackWaveEditorBarActive or self.zyngui.clipWaveEditorBarActive) and
                    selected_clip is not None and
                    selected_clip.path is not None and
                    len(selected_clip.path) > 0
                ) or (
                    self.zyngui.sound_combinator_active and
                    selected_track is not None and
                    selected_track.checkIfLayerExists(self.zyngui.session_dashboard.selectedSoundRow)
                ) or (
                    ((self.zyngui.slotsBarTrackActive and selected_track.trackAudioType == "synth") or self.zyngui.slotsBarSynthsActive) and
                    selected_track is not None and
                    selected_track.checkIfLayerExists(selected_track.chainedSounds[selected_track.selectedSlotRow])
                ) or (
                    self.zyngui.slotsBarMixerActive and
                    selected_track is not None
                ):
            logging.debug(
                f"### set_selector : Configuring small knob 1, showing")

            self.__zselector[1].show()
        else:
            logging.debug(
                f"### set_selector : Configuring small knob 1, hiding")

            if self.__zselector[1]:
                self.__zselector[1].hide()

        if self.zyngui.sound_combinator_active or self.zyngui.slotsBarTrackActive or self.zyngui.slotsBarSynthsActive:
            volume = 0
            min_value = 0
            max_value = 0

            try:
                # logging.error(f"layer({selected_track.chainedSounds[self.zyngui.session_dashboard.selectedSoundRow]}), layerExists({selected_track.checkIfLayerExists(selected_track.chainedSounds[self.zyngui.session_dashboard.selectedSoundRow])})")

                if self.zyngui.sound_combinator_active and \
                        selected_track.checkIfLayerExists(
                            selected_track.chainedSounds[self.zyngui.session_dashboard.selectedSoundRow]):
                    volume_control_obj = self.zyngui.layers_for_track.volume_controls[
                        self.zyngui.session_dashboard.selectedSoundRow]
                    volume = volume_control_obj.value * 1000
                    min_value = volume_control_obj.value_min * 1000
                    max_value = volume_control_obj.value_max * 1000
                elif ((self.zyngui.slotsBarTrackActive and selected_track.trackAudioType == "synth") or self.zyngui.slotsBarSynthsActive) and \
                        selected_track.checkIfLayerExists(selected_track.chainedSounds[selected_track.selectedSlotRow]):
                    volume_control_obj = self.zyngui.layers_for_track.volume_controls[selected_track.selectedSlotRow]
                    volume = volume_control_obj.value * 1000
                    min_value = volume_control_obj.value_min * 1000
                    max_value = volume_control_obj.value_max * 1000
            except Exception as e:
                logging.error(f"Error configuring knob 1 : {str(e)}")

            logging.debug(
                f"### set_selector : Configuring small knob 1, value({volume}), max_value({max_value}), min_value({min_value})")

            self.__zselector_ctrl[1].set_options(
                {'symbol': 'zynthiloops_knob1', 'name': 'Zynthiloops Knob 1',
                 'short_name': 'Knob1',
                 'midi_cc': 0, 'value_max': round(max_value), 'value_min': round(min_value), 'value': round(volume)})

            self.__zselector[1].config(self.__zselector_ctrl[1])
            self.__zselector[1].custom_encoder_speed = 0
        elif self.zyngui.slotsBarMixerActive:
            # zselector doesnt negetive minimum value. need to interpolate actual range (-40 to 20) to range (0 to 60)
            volume = np.interp(selected_track.volume, (-40, 20), (0, 60))

            if self.__zselector[1] is None:
                self.__zselector_ctrl[1] = zynthian_controller(None, 'zynthiloops_knob1',
                                                               'zynthiloops_knob1',
                                                               {'midi_cc': 0, 'value': volume})

                self.__zselector[1] = zynthian_gui_controller(zynthian_gui_config.select_ctrl, self.__zselector_ctrl[1],
                                                              self)
                self.__zselector[1].index = 0

            logging.debug(f"### set_selector : Configuring small knob 1, value({volume})")


            self.__zselector_ctrl[1].set_options(
                {'symbol': 'zynthiloops_knob1', 'name': 'Zynthiloops Knob 1', 'short_name': 'Knob1',
                 'midi_cc': 0, 'value_max': 60, 'value': volume})

            self.__zselector[1].config(self.__zselector_ctrl[1])
            self.__zselector[1].custom_encoder_speed = 0
        else:
            start_position = 0
            max_value = 0

            try:
                if selected_clip is not None and selected_clip.path is not None and len(selected_clip.path) > 0:
                    start_position = int(selected_clip.startPosition * 1000)
                    max_value = int(selected_clip.duration * 1000)
            except Exception as e:
                logging.error(f"Error configuring knob 1 : {str(e)}")

            if self.__zselector[1] is None:
                self.__zselector_ctrl[1] = zynthian_controller(None, 'zynthiloops_knob1',
                                                               'zynthiloops_knob1',
                                                               {'midi_cc': 0, 'value': start_position})

                self.__zselector[1] = zynthian_gui_controller(zynthian_gui_config.select_ctrl, self.__zselector_ctrl[1],
                                                              self)
                self.__zselector[1].index = 0

            logging.debug(f"### set_selector : Configuring small knob 1, value({start_position}), max_value({max_value})")

            self.__zselector_ctrl[1].set_options(
                {'symbol': 'zynthiloops_knob1', 'name': 'Zynthiloops Knob 1', 'short_name': 'Knob1',
                 'midi_cc': 0, 'value_max': max_value, 'value': start_position})

            self.__zselector[1].config(self.__zselector_ctrl[1])
            self.__zselector[1].custom_encoder_speed = 0


    def configure_small_knob_2(self, selected_track, selected_clip):
        loop = 0
        max_value = 0

        try:
            if selected_clip is not None and selected_clip.path is not None and len(selected_clip.path) > 0:
                loop = int(selected_clip.loopDelta * 1000)
                max_value = int(selected_clip.secPerBeat * selected_clip.length * 1000)
        except Exception as e:
            logging.error(f"Error configuring knob 2 : {str(e)}")

        if self.__zselector[2] is None:
            self.__zselector_ctrl[2] = zynthian_controller(None, 'zynthiloops_loop',
                                                           'zynthiloops_loop',
                                                           {'midi_cc': 0, 'value': loop})

            self.__zselector[2] = zynthian_gui_controller(zynthian_gui_config.select_ctrl, self.__zselector_ctrl[2],
                                                          self)
            self.__zselector[2].index = 1

        if self.zyngui.get_current_screen_id() is not None and \
                self.zyngui.get_current_screen() == self and \
                (self.zyngui.trackWaveEditorBarActive or self.zyngui.clipWaveEditorBarActive) and \
                selected_clip is not None and \
                selected_clip.path is not None and \
                len(selected_clip.path) > 0:
            logging.debug(
                f"### set_selector : Configuring small knob 2, showing")

            self.__zselector[2].show()
        else:
            logging.debug(
                f"### set_selector : Configuring small knob 2, hiding")
            self.__zselector[2].hide()

        logging.debug(
            f"### set_selector : Configuring small knob 2, value({loop}), max_value({max_value})")

        self.__zselector_ctrl[2].set_options(
            {'symbol': 'zynthiloops_loop', 'name': 'Zynthiloops Loop',
             'short_name': 'Loop',
             'midi_cc': 0, 'value_max': max_value, 'value': loop})

        self.__zselector[2].config(self.__zselector_ctrl[2])
        self.__zselector[2].custom_encoder_speed = 0


    def configure_small_knob_3(self, selected_track, selected_clip):
        value = 0
        max_value = 64 * 100

        try:
            if selected_clip is not None and selected_clip.path is not None and len(selected_clip.path) > 0:
                value = selected_clip.length * 100
        except Exception as e:
            logging.error(f"Error configuring knob 3 : {str(e)}")

        if self.__zselector[3] is None:
            self.__zselector_ctrl[3] = zynthian_controller(None, 'zynthiloops_length',
                                                           'zynthiloops_length',
                                                           {'midi_cc': 0, 'value': value})

            self.__zselector[3] = zynthian_gui_controller(zynthian_gui_config.select_ctrl, self.__zselector_ctrl[3],
                                                          self)
            self.__zselector[3].index = 2

        if self.zyngui.get_current_screen_id() is not None and \
                self.zyngui.get_current_screen() == self and \
                (self.zyngui.trackWaveEditorBarActive or self.zyngui.clipWaveEditorBarActive) and \
                selected_clip is not None and \
                selected_clip.path is not None and \
                len(selected_clip.path) > 0:
            logging.debug(
                f"### set_selector : Configuring small knob 3, showing")
            self.__zselector[3].show()
        else:
            logging.debug(
                f"### set_selector : Configuring small knob 3, hiding")
            self.__zselector[3].hide()

        logging.debug(
            f"### set_selector : Configuring small knob 3, value({value}), max_value({max_value})")

        self.__zselector_ctrl[3].set_options(
            {'symbol': 'zynthiloops_length', 'name': 'Zynthiloops Length',
             'short_name': 'Length',
             'midi_cc': 0, 'value_max': max_value, 'value': value})

        self.__zselector[3].config(self.__zselector_ctrl[3])


    @Slot(None)
    def set_selector(self, zs_hiden=False):
        # Hide selectors and return if dependent variables is None or a long operation is in progress
        if self.__song__ is None or \
                (self.zyngui.get_current_screen_id() is not None and self.zyngui.get_current_screen() != self) or \
                self.longOperation:
            if self.__zselector[0] is not None:
                self.__zselector[0].hide()
            if self.__zselector[1] is not None:
                self.__zselector[1].hide()
            if self.__zselector[2] is not None:
                self.__zselector[2].hide()
            if self.__zselector[3] is not None:
                self.__zselector[3].hide()

            return

        self.is_set_selector_running = True

        ### Common vars for small knobs
        selected_clip = None
        selected_track_obj = self.__song__.tracksModel.getTrack(self.zyngui.session_dashboard.get_selected_track())

        if self.zyngui.trackWaveEditorBarActive:
            logging.debug(f"### set_selector : trackWaveEditorBarActive is active.")
            selected_clip = selected_track_obj.samples[selected_track_obj.selectedSampleRow]
        elif self.zyngui.clipWaveEditorBarActive:
            logging.debug(f"### set_selector : clipWaveEditorBarActive is active.")
            selected_clip = self.__song__.getClip(selected_track_obj.id, self.song.scenesModel.selectedMixIndex)
        ###

        # Configure Big Knob
        self.configure_big_knob()

        # Configure small knob 1
        self.configure_small_knob_1(selected_track_obj, selected_clip)

        # Configure small knob 2
        self.configure_small_knob_2(selected_track_obj, selected_clip)

        # Configure small knob 3
        self.configure_small_knob_3(selected_track_obj, selected_clip)

        self.is_set_selector_running = False

    def switch_select(self, t):
        pass

    def back_action(self):
        return "zynthiloops"

    @Slot(None)
    def startMonitorMasterAudioLevels(self):
        self.master_audio_level_timer.start()

    @Slot(None)
    def stopMonitorMasterAudioLevels(self):
        self.master_audio_level_timer.stop()

    def master_volume_level_timer_timeout(self):
        try:
            added_db = 0
            for i in range(0, self.__song__.tracksModel.count):
                track = self.__song__.tracksModel.getTrack(i)
                added_db += pow(10, track.get_audioLevel()/10)

            self.set_master_audio_level(10*math.log10(added_db))
        except:
            self.set_master_audio_level(0)

    ### Property masterAudioLevel
    def get_master_audio_level(self):
        return self.__master_audio_level__
    def set_master_audio_level(self, level):
        self.__master_audio_level__ = level
        self.master_audio_level_changed.emit()
    master_audio_level_changed = Signal()
    masterAudioLevel = Property(float, get_master_audio_level, notify=master_audio_level_changed)
    ### END Property masterAudioLevelLeft

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

    ### Property knobTouchUpdateInProgress
    def get_knob_touch_update_in_progress(self):
        return self.__knob_touch_update_in_progress__

    def set_knob_touch_update_in_progress(self, value):
        if self.__knob_touch_update_in_progress__ != value:
            self.__knob_touch_update_in_progress__ = value
            self.knob_touch_update_in_progress_changed.emit()

    knob_touch_update_in_progress_changed = Signal()

    knobTouchUpdateInProgress = Property(bool, get_knob_touch_update_in_progress, set_knob_touch_update_in_progress,
                                         notify=knob_touch_update_in_progress_changed)
    ### END Property knobTouchUpdateInProgress

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
        logging.debug(track_layers_snapshot)
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

    def recording_process_stopped(self, exitCode, exitStatus):
        logging.info(f"Stopped recording {self} : Code({exitCode}), Status({exitStatus})")

    def show(self):
        self.set_selector()

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
    def newSketch(self, base_sketch=None, cb=None):
        def task():
            try:
                self.__song__.bpm_changed.disconnect()
            except Exception as e:
                logging.error(f"Already disconnected : {str(e)}")

            try:
                self.stopAllPlayback()
                self.zyngui.screens["playgrid"].stopMetronomeRequest()
                self.zyngui.screens["song_arranger"].stop()
                self.resetMetronome()
            except:
                pass

            if self.__song__ is not None:
                self.__song__.to_be_deleted()

            if (self.__sketch_basepath__ / 'temp').exists():
                shutil.rmtree(self.__sketch_basepath__ / 'temp')

            if base_sketch is not None:
                logging.info(f"Creating New Sketch from community sketch : {base_sketch}")

                base_sketch_path = Path(base_sketch)

                # Copy community sketch as temp
                shutil.copytree(base_sketch_path.parent, self.__sketch_basepath__ / 'temp')

                logging.info(f"Loading new sketch from community sketch : {str(self.__sketch_basepath__ / 'temp' / base_sketch_path.name)}")

                self.__song__ = zynthiloops_song.zynthiloops_song(str(self.__sketch_basepath__ / "temp") + "/",
                                                                  base_sketch_path.stem.replace(".sketch", ""), self)
                self.zyngui.screens["session_dashboard"].set_last_selected_sketch(
                    str(self.__sketch_basepath__ / 'temp' / base_sketch_path.name))

                if Path("/zynthian/zynthian-my-data/snapshots/default.zss").exists():
                    logging.info(f"Loading default snapshot")
                    self.zyngui.screens["layer"].load_snapshot("/zynthian/zynthian-my-data/snapshots/default.zss")

                self.__song__.bpm_changed.connect(self.update_timer_bpm)
                self.song_changed.emit()
                self.zyngui.screens["session_dashboard"].set_selected_track(0, True)
            else:
                logging.info(f"Creating New Sketch")

                self.__song__ = zynthiloops_song.zynthiloops_song(str(self.__sketch_basepath__ / "temp") + "/", "Sketch-1", self)
                self.zyngui.screens["session_dashboard"].set_last_selected_sketch(
                    str(self.__sketch_basepath__ / 'temp' / 'Sketch-1.sketch.json'))

                if Path("/zynthian/zynthian-my-data/snapshots/default.zss").exists():
                    logging.info(f"Loading default snapshot")
                    self.zyngui.screens["layer"].load_snapshot("/zynthian/zynthian-my-data/snapshots/default.zss")

                self.__song__.bpm_changed.connect(self.update_timer_bpm)
                self.song_changed.emit()
                self.zyngui.screens["session_dashboard"].set_selected_track(0, True)
                self.newSketchLoaded.emit()

            # Set ALSA Mixer volume to 100% when creating new sketch
            self.zyngui.screens["master_alsa_mixer"].volume = 100

            # Update volume controls
            self.zyngui.fixed_layers.fill_list()
            self.set_selector()

            if cb is not None:
                cb()

            self.longOperationDecrement()
            QTimer.singleShot(3000, self.zyngui.end_long_task)

        self.longOperationIncrement()
        self.zyngui.do_long_task(task)

    @Slot(None)
    def saveSketch(self):
        def task():
            self.__song__.save(False)
            QTimer.singleShot(3000, self.zyngui.end_long_task)
        self.zyngui.do_long_task(task)

    @Slot(str)
    def createSketch(self, name):
        def task():
            self.stopAllPlayback()
            self.zyngui.screens["playgrid"].stopMetronomeRequest()
            self.zyngui.screens["song_arranger"].stop()
            self.resetMetronome()

            # Rename temp sketch folder to the user defined name
            Path(self.__sketch_basepath__ / 'temp').rename(self.__sketch_basepath__ / name)

            # Rename temp sketch json filename to user defined name
            Path(self.__sketch_basepath__ / name / (self.__song__.name + ".sketch.json")).rename(self.__sketch_basepath__ / name / (name + ".sketch.json"))

            obj = {}

            # Read sketch json data to dict
            try:
                with open(self.__sketch_basepath__ / name / (name + ".sketch.json"), "r") as f:
                    obj = json.loads(f.read())
            except Exception as e:
                logging.error(e)

            # Update temp sketch name to user defined name and update clip paths to point to new sketch dir
            try:
                with open(self.__sketch_basepath__ / name / (name + ".sketch.json"), "w") as f:
                    obj["name"] = name

                    # for i, track in enumerate(obj["tracks"]):
                    #     for j, clip in enumerate(track["clips"]):
                    #         if clip['path'] is not None:
                    #             path = clip['path'].replace("/zynthian/zynthian-my-data/sketches/my-sketches/temp/", str(self.__sketch_basepath__ / name) + "/")
                    #             logging.error(f"Clip Path : {clip['path']}")
                    #             obj["tracks"][i]["clips"][j]["path"] = path

                    f.write(json.dumps(obj))
                    f.flush()
                    os.fsync(f.fileno())
            except Exception as e:
                logging.error(e)

            self.__song__ = zynthiloops_song.zynthiloops_song(str(self.__sketch_basepath__ / name) + "/", name, self)
            self.zyngui.screens["session_dashboard"].set_last_selected_sketch(
                str(self.__sketch_basepath__ / name / f'{name}.sketch.json'))
            self.__song__.save(False)

            self.__song__.bpm_changed.connect(self.update_timer_bpm)

            self.song_changed.emit()
            self.longOperationDecrement()
            QTimer.singleShot(3000, self.zyngui.end_long_task)

            # logging.error("### Saving sketch to session")
            # self.zyngui.session_dashboard.set_sketch(self.__song__.sketch_folder)

        self.longOperationIncrement()
        self.zyngui.do_long_task(task)

    @Slot(str)
    def saveCopy(self, name):
        def task():
            old_folder = self.__song__.sketch_folder
            shutil.copytree(old_folder, self.__sketch_basepath__ / name)

            # for json_path in (self.__sketch_basepath__ / name).glob("**/*.sketch.json"):
            #     try:
            #         with open(json_path, "r+") as f:
            #             obj = json.load(f)
            #             f.seek(0)
            #
            #             for i, track in enumerate(obj["tracks"]):
            #                 for j, clip in enumerate(track["clips"]):
            #                     if clip['path'] is not None:
            #                         path = clip['path'].replace(old_folder, str(self.__sketch_basepath__ / name) + "/")
            #                         logging.error(f"Clip Path : {clip['path']}")
            #                         obj["tracks"][i]["clips"][j]["path"] = path
            #
            #             json.dump(obj, f)
            #             f.truncate()
            #             f.flush()
            #             os.fsync(f.fileno())
            #     except Exception as e:
            #         logging.error(e)

            QTimer.singleShot(3000, self.zyngui.end_long_task)

        self.zyngui.do_long_task(task)

    @Slot(str, bool)
    def loadSketch(self, sketch, load_history, load_snapshot=True, cb=None):
        def task():
            logging.info(f"Loading sketch : {sketch}")

            try:
                self.__song__.bpm_changed.disconnect()
            except Exception as e:
                logging.error(f"Already disconnected : {str(e)}")

            sketch_path = Path(sketch)

            try:
                self.stopAllPlayback()
                self.zyngui.screens["playgrid"].stopMetronomeRequest()
                self.zyngui.screens["song_arranger"].stop()
                self.resetMetronome()
            except:
                pass

            if sketch_path.parent.match("*/zynthian-my-data/sketches/community-sketches/*"):
                def _cb():
                    last_selected_sketch_path = Path(self.zyngui.screens['session_dashboard'].get_last_selected_sketch())

                    if load_snapshot:
                        # Load snapshot
                        logging.info(
                            f"Loading snapshot : '{str(last_selected_sketch_path.parent / 'soundsets')}/{last_selected_sketch_path.stem.replace('.sketch', '')}.zss'")
                        self.zyngui.screens["layer"].load_snapshot(
                            f"{str(last_selected_sketch_path.parent / 'soundsets')}/{last_selected_sketch_path.stem.replace('.sketch', '')}.zss")

                    self.longOperationDecrement()
                    QTimer.singleShot(3000, self.zyngui.end_long_task)

                self.newSketch(sketch, _cb)
            else:
                logging.info(f"Loading Sketch : {str(sketch_path.parent.absolute()) + '/'}, {str(sketch_path.stem)}")
                self.__song__ = zynthiloops_song.zynthiloops_song(str(sketch_path.parent.absolute()) + "/", str(sketch_path.stem.replace(".sketch", "")), self, load_history)
                self.zyngui.screens["session_dashboard"].set_last_selected_sketch(str(sketch_path))

                if load_snapshot:
                    snapshot_path = str(sketch_path.parent.absolute()) + '/soundsets/' + str(sketch_path.stem.replace('.sketch', '')) + '.zss'
                    # Load snapshot
                    logging.info(f"Loading snapshot : {snapshot_path}")
                    self.zyngui.screens["layer"].load_snapshot(snapshot_path)

                self.__song__.bpm_changed.connect(self.update_timer_bpm)
                self.song_changed.emit()

                self.longOperationDecrement()
                QTimer.singleShot(3000, self.zyngui.end_long_task)

            if cb is not None:
                cb()

        self.longOperationIncrement()
        self.zyngui.do_long_task(task)

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
        return (sketch_path / (name+'.sketch.json')).exists()

    @Slot(None, result=bool)
    def sketchIsTemp(self):
        return self.__song__.sketch_folder == str(self.__sketch_basepath__ / "temp") + "/"

    @Slot(None)
    def stopAllPlayback(self):
        self.click_track_click.queueClipToStop()
        self.click_track_clack.queueClipToStop()

        for track_index in range(self.__song__.tracksModel.count):
            self.__song__.tracksModel.getTrack(track_index).stopAllClips()

    def update_timer_bpm(self):
        self.click_track_click.set_length(4, self.__song__.bpm)
        self.click_track_clack.set_length(1, self.__song__.bpm)

        if self.metronome_running_refcount > 0:
            self.set_clickTrackEnabled(self.click_track_enabled)

            libzl.startTimer(self.__song__.__bpm__)

    def queue_clip_record(self, clip, source, channel):
        if self.zyngui.curlayer is not None:
            layers_snapshot = self.zyngui.screens["layer"].export_multichannel_snapshot(self.zyngui.curlayer.midi_chan)
            track = self.__song__.tracksModel.getTrack(self.zyngui.session_dashboard.selectedTrack)
            self.set_clip_to_record(clip)

            if clip.isTrackSample:
                Path(track.bankDir).mkdir(parents=True, exist_ok=True)
            else:
                (Path(clip.recording_basepath) / 'wav').mkdir(parents=True, exist_ok=True)

            if source == 'internal':
                try:
                    preset_name = layers_snapshot['layers'][0]['preset_name'].replace(' ', '-').replace('/', '-')
                except:
                    preset_name = ""
            else:
                preset_name = "external"

            count = 0

            if clip.isTrackSample:
                base_recording_dir = track.bankDir
            else:
                base_recording_dir = f"{clip.recording_basepath}/wav"

            base_filename = f"{datetime.now().strftime('%Y%m%d-%H%M')}_{preset_name}_{self.__song__.bpm}-BPM"

            # Check if file exists otherwise append count

            while Path(f"{base_recording_dir}/{base_filename}{'-'+str(count) if count > 0 else ''}.clip.wav").exists():
                count += 1

            self.clip_to_record_path = f"{base_recording_dir}/{base_filename}{'-'+str(count) if count > 0 else ''}.clip.wav"

            #self.countInValue = countInBars * 4
            logging.debug(
                f"Command jack_capture : /usr/local/bin/jack_capture {self.recorder_process_internal_arguments} \
                --port zynthiloops_audio_levels_client:T{track.id + 1}A \
                --port zynthiloops_audio_levels_client:T{track.id + 1}B \
                {self.clip_to_record_path}")

            if source == 'internal':
                self.__last_recording_type__ = "Internal"
                self.recorder_process = Popen(("/usr/local/bin/jack_capture", *self.recorder_process_internal_arguments,
                                               "--port", f"zynthiloops_audio_levels_client:T{track.id + 1}A", "--port",
                                               f"zynthiloops_audio_levels_client:T{track.id + 1}B",
                                               self.clip_to_record_path), stdout=PIPE, stderr=PIPE)
            else:
                if channel == "1":
                    self.__last_recording_type__ = "External (Mono Left)"
                elif channel == "2":
                    self.__last_recording_type__ = "External (Mono Right)"
                else:
                    self.__last_recording_type__ = "External (Stereo)"
                self.recorder_process = Popen(("/usr/local/bin/jack_capture", "--disable-console", "--no-stdin", "--port", f"system:capture_{channel}", self.clip_to_record_path),stdout=PIPE,stderr=PIPE)

            logging.info("Process opened, let's wait for output...")
            # Let's make sure that we have at least a bit of output before continuing (so we know the process has actually started)
            self.recorder_process.stderr.read(13) # This should be the string ">>> Recording", but also anything will do really
            logging.info("Output get! Continue.")

            self.clip_to_record.isRecording = True
        else:
            logging.error("Empty layer selected. Cannot record.")
            self.cannotRecordEmptyLayer.emit()

    @Slot(None)
    def stopRecording(self):
        if self.clip_to_record is not None and self.clip_to_record.isRecording:
            self.clip_to_record.isRecording = False

        if self.recorder_process is not None:
            self.recorder_process.terminate()
            logging.info("Asked recorder to stop doing the thing");
            self.recording_complete.emit()

    @Slot(None)
    def startPlayback(self):
        self.__song__.scenesModel.playScene(self.__song__.scenesModel.selectedSceneIndex, self.__song__.scenesModel.selectedMixIndex)
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
                if self.click_track_enabled:
                    self.click_track_click.queueClipToStart()
                    self.click_track_clack.queueClipToStart()

                libzl.startTimer(self.__song__.__bpm__)
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
        logging.info("Loading recorded clip - but first, wait for the recorder to exit")
        self.recorder_process.wait()
        logging.info("Recorder exited, now we should have a file")
        if not Path(self.clip_to_record_path).exists():
            logging.error("### The recording does not exist! This is a big problem and we will have to deal with that.")

        layer = self.zyngui.screens["layer"].export_multichannel_snapshot(self.zyngui.curlayer.midi_chan)
        logging.debug(f"### Channel({self.zyngui.curlayer.midi_chan}), Layer({json.dumps(layer)})")

        self.clip_to_record.path = self.clip_to_record_path
        self.clip_to_record.write_metadata("ZYNTHBOX_ACTIVELAYER", [json.dumps(layer)])
        self.clip_to_record.write_metadata("ZYNTHBOX_BPM", [str(self.__song__.bpm)])
        self.clip_to_record.write_metadata("ZYNTHBOX_AUDIO_TYPE", [self.__last_recording_type__])

        if self.clip_to_record.isTrackSample:
            logging.info(f"Recorded clip is a sample")
            track = self.__song__.tracksModel.getTrack(self.zyngui.session_dashboard.selectedTrack)
            track.samples_changed.emit()

        self.set_clip_to_record(None)
        self.clip_to_record_path = None
        self.recorder_process = None
        self.__last_recording_type__ = ""
        # self.__song__.save()

    def get_next_free_layer(self):
        logging.debug(self.zyngui.screens["layers"].layers)

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
    newSketchLoaded = Signal()
