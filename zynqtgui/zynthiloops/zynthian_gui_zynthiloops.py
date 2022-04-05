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
from subprocess import Popen
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


@ctypes.CFUNCTYPE(None, ctypes.c_float)
def audioLevelCb(dbFS):
    zynthian_gui_zynthiloops.__instance__.set_recording_audio_level(dbFS)


class zynthian_gui_zynthiloops(zynthian_qt_gui_base.ZynGui):
    __instance__ = None

    def __init__(self, parent=None):
        super(zynthian_gui_zynthiloops, self).__init__(parent)
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
        self.jack_client = jack.Client('zynthiloops_client')
        self.recorder_process = None
        self.recorder_process_internal_arguments = ["--daemon", "--port", f"zynthiloops_client:*"]
        self.__last_recording_type__ = ""
        self.__capture_audio_level_left__ = -400
        self.__capture_audio_level_right__ = -400
        self.__recording_audio_level__ = -100
        self.__song__ = None
        self.__zselector = [None, None, None, None]
        self.__zselector_ctrl = [None, None, None, None]
        self.__zselector_track = -1
        self.__knob_touch_update_in_progress__ = False
        self.__selected_clip_col__ = 0
        self.__is_init_in_progress__ = True
        self.__long_task_count__ = 0

        self.__master_audio_level__ = -200
        self.master_audio_level_timer = QTimer()
        self.master_audio_level_timer.setInterval(50)
        self.master_audio_level_timer.timeout.connect(self.master_volume_level_timer_timeout)
        self.zyngui.current_screen_id_changed.connect(self.sync_selector_visibility)

        self.select_preset_timer = QTimer()
        self.select_preset_timer.setInterval(100)
        self.select_preset_timer.setSingleShot(True)
        # self.select_preset_timer.timeout.connect(lambda: self.zyngui.preset.select_action(self.zyngui.preset.current_index))

        self.__volume_control_obj = None

        Path('/zynthian/zynthian-my-data/samples').mkdir(exist_ok=True, parents=True)
        Path('/zynthian/zynthian-my-data/sample-banks/my-samples').mkdir(exist_ok=True, parents=True)
        Path('/zynthian/zynthian-my-data/sample-banks/community-samples').mkdir(exist_ok=True, parents=True)

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
        pass
        # if self.zyngui.get_current_screen_id() != None and self.zyngui.get_current_screen() == self:
        #     if not self.__is_init_in_progress__:
        #         self.set_selector()
        # else:
        #     if self.__zselector[0]:
        #         self.__zselector[0].hide()
        #     if self.__zselector[1]:
        #         self.__zselector[1].hide()
        #     if self.__zselector[2]:
        #         self.__zselector[2].hide()
        #     if self.__zselector[3]:
        #         self.__zselector[3].hide()

    def init_sketch(self, sketch, cb=None):
        def _cb():
            def timer_callback():
                self.zyngui.zynthiloops.set_selector()
                self.__is_init_in_progress__ = False

            libzl.registerTimerCallback(libzlCb)
            libzl.setRecordingAudioLevelCallback(audioLevelCb)

            self.metronomeBeatUpdate4th.connect(self.metronome_update)
            self.zyngui.master_alsa_mixer.volume_changed.connect(lambda: self.master_volume_changed.emit())
            self.update_timer_bpm()
            self.zyngui.screens['layer'].current_index_changed.connect(lambda: self.update_recorder_jack_port())
            self.zyngui.trackWaveEditorBarActiveChanged.connect(self.set_selector)
            self.zyngui.clipWaveEditorBarActiveChanged.connect(self.set_selector)
            self.zyngui.session_dashboard.selected_sound_row_changed.connect(self.set_selector)

            if cb is not None:
                cb()

            # Call set_selector after a few seconds after loading sketch otherwise
            # initial selected track value seems to be overwritten by big knob value
            # no initial load to the maximum value which is 9. Calling set_selector
            # after a timeout seems to mitigate the problem.
            # Although (FIXME) a proper solution is required instead of the timer
            QTimer.singleShot(5000, timer_callback)

        self.master_audio_level_timer.start()

        if sketch is not None:
            logging.error(f"### Checking Sketch {sketch} : exists({Path(sketch).exists()}) ")
        else:
            logging.error(f"### Checking Sketch sketch is none ")

        if sketch is not None and Path(sketch).exists():
            self.loadSketch(sketch, _cb)
        else:
            self.newSketch(None, _cb)

    @Slot(None)
    def zyncoder_set_selected_track(self):
        if self.is_set_selector_running:
            logging.error(f"Set selector in progress. Not setting value with encoder")
            return

        if self.zyngui.session_dashboard.get_selected_track() != round(self.__zselector[0].value/10):
            logging.error(f"Setting track from zyncoder {round(self.__zselector[0].value/10)}")
            self.zyngui.session_dashboard.set_selected_track(round(self.__zselector[0].value/10))
            self.set_selector()

    @Slot(None)
    def zyncoder_set_preset(self):
        if self.is_set_selector_running:
            logging.error(f"Set selector in progress. Not setting value with encoder")
            return

        track = self.__song__.tracksModel.getTrack(self.zyngui.session_dashboard.selectedTrack)
        selected_channel = track.get_chained_sounds()[self.zyngui.session_dashboard.selectedSoundRow]

        if selected_channel in self.zyngui.layer.layer_midi_map:
            layer = self.zyngui.layer.layer_midi_map[selected_channel]

            if track.checkIfLayerExists(selected_channel) and layer.preset_index != round(self.__zselector[0].value/1000):
                logging.error(f"Selecting preset : {round(self.__zselector[0].value/1000)}")
                layer.set_preset(min(round(self.__zselector[0].value/1000), len(layer.preset_list) - 1), True)
                self.zyngui.fixed_layers.fill_list()
                self.presetUpdated.emit()
                # self.select_preset_timer.start()


    @Slot(None)
    def zyncoder_update_layer_volume(self):
        if self.is_set_selector_running:
            logging.error(f"Set selector in progress. Not setting value with encoder")
            return

        selected_track = self.__song__.tracksModel.getTrack(self.zyngui.session_dashboard.get_selected_track())
        try:
            volume_control_obj = self.zyngui.layers_for_track.volume_controls[self.zyngui.session_dashboard.selectedSoundRow]
        except:
            volume_control_obj = None

        if volume_control_obj is not None and \
           selected_track.checkIfLayerExists(selected_track.chainedSounds[self.zyngui.session_dashboard.selectedSoundRow]) and \
           volume_control_obj.value != self.__zselector[1].value / 1000:
            volume_control_obj.value = self.__zselector[1].value / 1000
            logging.error(f"### zyncoder_update_layer_volume {volume_control_obj.value}")
            self.set_selector()

    @Slot(None)
    def zyncoder_update_clip_start_position(self):
        if self.is_set_selector_running:
            logging.error(f"Set selector in progress. Not setting value with encoder")
            return

        selected_track_obj = self.__song__.tracksModel.getTrack(self.zyngui.session_dashboard.get_selected_track())
        selected_clip = None

        if self.zyngui.trackWaveEditorBarActive:
            selected_clip = selected_track_obj.samples[selected_track_obj.selectedSampleRow]
        elif self.zyngui.clipWaveEditorBarActive:
            selected_clip = self.__song__.getClip(selected_track_obj.id, self.selectedClipCol)

        if selected_clip is not None and selected_clip.startPosition != (self.__zselector[1].value / 1000):
            selected_clip.startPosition = self.__zselector[1].value / 1000
            logging.error(f"### zyncoder_update_clip_start_position {selected_clip.startPosition}")
            self.set_selector()

    @Slot(None)
    def zyncoder_update_clip_loop(self):
        if self.is_set_selector_running:
            logging.error(f"Set selector in progress. Not setting value with encoder")
            return

        selected_track_obj = self.__song__.tracksModel.getTrack(self.zyngui.session_dashboard.get_selected_track())
        selected_clip = None

        if self.zyngui.trackWaveEditorBarActive:
            selected_clip = selected_track_obj.samples[selected_track_obj.selectedSampleRow]
        elif self.zyngui.clipWaveEditorBarActive:
            selected_clip = self.__song__.getClip(selected_track_obj.id, self.selectedClipCol)

        if selected_clip is not None and selected_clip.loopDelta != self.__zselector[2].value/1000:
            selected_clip.loopDelta = self.__zselector[2].value/1000
            logging.error(f"### zyncoder_update_clip_loop {selected_clip.loopDelta}")
            self.set_selector()

    @Slot(None)
    def zyncoder_update_clip_length(self):
        if self.is_set_selector_running:
            logging.error(f"Set selector in progress. Not setting value with encoder")
            return

        selected_track_obj = self.__song__.tracksModel.getTrack(self.zyngui.session_dashboard.get_selected_track())
        selected_clip = None

        if self.zyngui.trackWaveEditorBarActive:
            selected_clip = selected_track_obj.samples[selected_track_obj.selectedSampleRow]
        elif self.zyngui.clipWaveEditorBarActive:
            selected_clip = self.__song__.getClip(selected_track_obj.id, self.selectedClipCol)

        if selected_clip is not None and selected_clip.snapLengthToBeat:
            if selected_clip.length != self.__zselector[3].value//100:
                selected_clip.length = self.__zselector[3].value//100
                logging.error(f"### zyncoder_update_clip_length {selected_clip.length}")
                self.set_selector()
        elif selected_clip is not None and not selected_clip.snapLengthToBeat:
            if selected_clip.length != self.__zselector[3].value/100:
                selected_clip.length = self.__zselector[3].value/100
                logging.error(f"### zyncoder_update_clip_length {selected_clip.length}")
                self.set_selector()

    def zyncoder_read(self):
        if self.__knob_touch_update_in_progress__:
            return

        if self.__zselector[0] and self.__song__:
            self.__zselector[0].read_zyncoder()

            if self.zyngui.sound_combinator_active:
                QMetaObject.invokeMethod(self, "zyncoder_set_preset", Qt.QueuedConnection)
            else:
                QMetaObject.invokeMethod(self, "zyncoder_set_selected_track", Qt.QueuedConnection)

        # Update clip startposition/layer volume when required with small knob 1
        if self.__zselector[1] and self.__song__:
            self.__zselector[1].read_zyncoder()
            if self.zyngui.sound_combinator_active:
                QMetaObject.invokeMethod(self, "zyncoder_update_layer_volume", Qt.QueuedConnection)
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
            if self.zyngui.sound_combinator_active:
                # If sound combinator is active, Use Big knob to control preset

                logging.error(f"### set_selector : Configuring big knob, sound combinator is active.")
                track = self.__song__.tracksModel.getTrack(self.zyngui.session_dashboard.selectedTrack)
                selected_channel = track.get_chained_sounds()[self.zyngui.session_dashboard.selectedSoundRow]
                logging.error(f"### selectedTrack : track{self.zyngui.session_dashboard.selectedTrack}({track}), slot({self.zyngui.session_dashboard.selectedSoundRow}), channel({selected_channel})")
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

                try:
                    selected_track = self.zyngui.session_dashboard.get_selected_track() * 10
                except:
                    selected_track = 0

                logging.error(f"### set_selector : Configuring big knob, sound combinator is not active. selected_track({selected_track // 10})")

                if self.__zselector[0] is None:
                    self.__zselector_ctrl[0] = zynthian_controller(None, 'zynthiloops_track', 'zynthiloops_track',
                                                                {'midi_cc': 0, 'value': selected_track})

                    self.__zselector[0] = zynthian_gui_controller(zynthian_gui_config.select_ctrl, self.__zselector_ctrl[0],
                                                                  self)

                self.__zselector[0].show()
                self.__zselector_ctrl[0].set_options(
                    {'symbol': 'zynthiloops_track', 'name': 'Zynthiloops Track', 'short_name': 'Track', 'midi_cc': 0,
                     'value_max': 90, 'value': selected_track})

                self.__zselector[0].config(self.__zselector_ctrl[0])
                self.__zselector[0].custom_encoder_speed = 0

            if self.__zselector[0] is not None:
                self.__zselector[0].show()
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
                ):
            logging.error(
                f"### set_selector : Configuring small knob 1, showing")

            self.__zselector[1].show()
        else:
            logging.error(
                f"### set_selector : Configuring small knob 1, hiding")

            if self.__zselector[1]:
                self.__zselector[1].hide()

        if self.zyngui.sound_combinator_active:
            volume = 0
            min_value = 0
            max_value = 0

            try:
                logging.error(f"layer({selected_track.chainedSounds[self.zyngui.session_dashboard.selectedSoundRow]}), layerExists({selected_track.checkIfLayerExists(selected_track.chainedSounds[self.zyngui.session_dashboard.selectedSoundRow])})")
                if selected_track.checkIfLayerExists(selected_track.chainedSounds[self.zyngui.session_dashboard.selectedSoundRow]):
                    volume_control_obj = self.zyngui.layers_for_track.volume_controls[self.zyngui.session_dashboard.selectedSoundRow]
                    volume = volume_control_obj.value * 1000
                    min_value = volume_control_obj.value_min * 1000
                    max_value = volume_control_obj.value_max * 1000
            except Exception as e:
                logging.error(f"Error configuring knob 1 : {str(e)}")

            logging.error(
                f"### set_selector : Configuring small knob 1, value({volume}), max_value({max_value}), min_value({min_value})")

            self.__zselector_ctrl[1].set_options(
                {'symbol': 'zynthiloops_knob1', 'name': 'Zynthiloops Knob 1',
                 'short_name': 'Knob1',
                 'midi_cc': 0, 'value_max': round(max_value), 'value_min': round(min_value), 'value': round(volume)})

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

            logging.error(f"### set_selector : Configuring small knob 1, value({start_position}), max_value({max_value})")

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
            logging.error(
                f"### set_selector : Configuring small knob 2, showing")

            self.__zselector[2].show()
        else:
            logging.error(
                f"### set_selector : Configuring small knob 2, hiding")
            self.__zselector[2].hide()

        logging.error(
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
            logging.error(
                f"### set_selector : Configuring small knob 3, showing")
            self.__zselector[3].show()
        else:
            logging.error(
                f"### set_selector : Configuring small knob 3, hiding")
            self.__zselector[3].hide()

        logging.error(
            f"### set_selector : Configuring small knob 3, value({value}), max_value({max_value})")

        self.__zselector_ctrl[3].set_options(
            {'symbol': 'zynthiloops_length', 'name': 'Zynthiloops Length',
             'short_name': 'Length',
             'midi_cc': 0, 'value_max': max_value, 'value': value})

        self.__zselector[3].config(self.__zselector_ctrl[3])


    @Slot(None)
    def set_selector(self, zs_hiden=False):
        if self.__song__ is None or (self.zyngui.get_current_screen_id() is not None and self.zyngui.get_current_screen() != self):
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
            logging.error(f"### set_selector : trackWaveEditorBarActive is active.")
            selected_clip = selected_track_obj.samples[selected_track_obj.selectedSampleRow]
        elif self.zyngui.clipWaveEditorBarActive:
            logging.error(f"### set_selector : clipWaveEditorBarActive is active.")
            selected_clip = self.__song__.getClip(selected_track_obj.id, self.selectedClipCol)
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

    ### Property recordingAudioLevel
    def get_recording_audio_level(self):
        return self.__recording_audio_level__
    def set_recording_audio_level(self, db):
        if db < -100:
            db = -100

        if self.__recording_audio_level__ != db:
            self.__recording_audio_level__ = db
            self.recording_audio_level_changed.emit()
    recording_audio_level_changed = Signal()
    recordingAudioLevel = Property(float, get_recording_audio_level, notify=recording_audio_level_changed)
    ### END Property recordingAudioLevel

    @staticmethod
    def peak_dbFS_from_jack_output(port, frames):
        def convertToDBFS(raw):
            if raw <= 0:
                return -400
            fValue = 20 * math.log10(raw)
            if fValue < -400:
                fValue = -400
            return fValue

        buf = np.frombuffer(port.get_buffer())
        raw_peak = 0

        for i in range(0, frames):
            try:
                sample = abs(buf[i])

                if sample > raw_peak:
                    raw_peak = sample
            except:
                pass

        if raw_peak < 0.0:
            raw_peak = 0.0

        return convertToDBFS(raw_peak)

    @Slot(None)
    def monitorCaptureAudioLevels(self):
        client = jack.Client('zynthiloops_monitor')
        port_l = client.inports.register("l")
        port_r = client.inports.register("r")

        @client.set_process_callback
        def process(frames):
            db_left = self.peak_dbFS_from_jack_output(port_l, frames)
            db_right = self.peak_dbFS_from_jack_output(port_r, frames)

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

    ### Property selectedClipCol
    def get_selected_clip_col(self):
        return self.__selected_clip_col__

    def set_selected_clip_col(self, col):
        if self.__selected_clip_col__ != col:
            logging.debug(f"### Selected Clip Col Changed : {col}")
            self.__selected_clip_col__ = col
            self.selectedClipColChanged.emit()

    selectedClipColChanged = Signal()

    selectedClipCol = Property(int, get_selected_clip_col, set_selected_clip_col, notify=selectedClipColChanged)
    ### END Property selectedClipCol

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
        class Worker:
            def run(self, zyngui, jack_client, jack_capture_port_a, jack_capture_port_b, selected_track):
                jack_basenames = []

                for channel in selected_track.chainedSounds:
                    if channel >= 0 and selected_track.checkIfLayerExists(channel):
                        layer = zyngui.screens['layer'].layer_midi_map[channel]

                        for fxlayer in zyngui.screens['layer'].get_fxchain_layers(layer):
                            try:
                                jack_basenames.append(fxlayer.jackname.split(":")[0])
                            except Exception as e:
                                logging.error(f"### update_recorder_jack_port Error : {str(e)}")

                # Disconnect all connected ports first
                try:
                    for port in jack_client.get_all_connections(jack_capture_port_a):
                        try:
                            jack_client.disconnect(port.name, jack_capture_port_a)
                        except Exception as e:
                            logging.error(f"Error disconnecting jack port : {str(e)}")
                    for port in jack_client.get_all_connections(jack_capture_port_b):
                        try:
                            jack_client.disconnect(port.name, jack_capture_port_b)
                        except Exception as e:
                            logging.error(f"Error disconnecting jack port : {str(e)}")
                except Exception as e:
                    logging.error(f"Error while disconnecting ports : {str(e)}")
                ###

                # Connect to selected track's output ports
                for port in jack_client.get_all_connections('system:playback_1'):
                    self.process_jack_port(jack_client, port.name, jack_capture_port_a, jack_basenames)
                for port in jack_client.get_all_connections('system:playback_2'):
                    self.process_jack_port(jack_client, port.name, jack_capture_port_b, jack_basenames)
                ###

            def process_jack_port(self, jack_client, port, target, active_jack_basenames):
                try:
                    for jack_basename in active_jack_basenames:
                        if not (port.startswith("JUCE") or port.startswith(
                                "system")) and port.startswith(jack_basename):
                            logging.error("ACCEPTED {}".format(port))
                            jack_client.connect(port, target)
                        else:
                            logging.error("REJECTED {}".format(port))
                except Exception as e:
                    logging.error(f"Error processing jack port : {port}({str(e)})")

        selected_track = self.song.tracksModel.getTrack(self.zyngui.screens["session_dashboard"].selectedTrack)
        worker = Worker()
        worker_thread = threading.Thread(target=worker.run, args=(self.zyngui, self.jack_client, "zynthiloops_client:capture_port_a", "zynthiloops_client:capture_port_b", selected_track))
        worker_thread.start()

    def recording_process_stopped(self, exitCode, exitStatus):
        logging.error(f"Stopped recording {self} : Code({exitCode}), Status({exitStatus})")

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
                logging.error(f"Creating New Sketch from community sketch : {base_sketch}")

                suggested_name = None
                base_sketch_path = Path(base_sketch)

                # Copy community sketch as temp
                shutil.copytree(base_sketch_path.parent, self.__sketch_basepath__ / 'temp')

                logging.error(f"Loading new sketch from community sketch : {str(self.__sketch_basepath__ / 'temp' / base_sketch_path.name)}")

                self.__song__ = zynthiloops_song.zynthiloops_song(str(self.__sketch_basepath__ / "temp") + "/",
                                                                  base_sketch_path.stem.replace(".sketch", ""), self)
                self.zyngui.screens["session_dashboard"].set_last_selected_sketch(
                    str(self.__sketch_basepath__ / 'temp' / base_sketch_path.name))

                if Path("/zynthian/zynthian-my-data/snapshots/default.zss").exists():
                    logging.error(f"Loading default snapshot")
                    self.zyngui.screens["layer"].load_snapshot("/zynthian/zynthian-my-data/snapshots/default.zss")

                self.__song__.bpm_changed.connect(self.update_timer_bpm)
                self.song_changed.emit()
                self.zyngui.screens["session_dashboard"].set_selected_track(0, True)
            else:
                logging.error(f"Creating New Sketch")

                self.__song__ = zynthiloops_song.zynthiloops_song(str(self.__sketch_basepath__ / "temp") + "/", "Sketch-1", self)
                self.zyngui.screens["session_dashboard"].set_last_selected_sketch(
                    str(self.__sketch_basepath__ / 'temp' / 'Sketch-1.sketch.json'))

                if Path("/zynthian/zynthian-my-data/snapshots/default.zss").exists():
                    logging.error(f"Loading default snapshot")
                    self.zyngui.screens["layer"].load_snapshot("/zynthian/zynthian-my-data/snapshots/default.zss")

                self.__song__.bpm_changed.connect(self.update_timer_bpm)
                self.song_changed.emit()
                self.zyngui.screens["session_dashboard"].set_selected_track(0, True)
                self.newSketchLoaded.emit()

            # Set ALSA Mixer volume to 100% when creating new sketch
            self.zyngui.screens["master_alsa_mixer"].volume = 100

            if cb is not None:
                cb()

            QTimer.singleShot(3000, self.end_long_task)

        self.do_long_task(task)

    @Slot(None)
    def saveSketch(self):
        def task():
            self.__song__.save(False)
            QTimer.singleShot(3000, self.end_long_task)
        self.do_long_task(task)

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
                    obj["suggestedName"] = None

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
            QTimer.singleShot(3000, self.end_long_task)

            # logging.error("### Saving sketch to session")
            # self.zyngui.session_dashboard.set_sketch(self.__song__.sketch_folder)

        self.do_long_task(task)

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

            QTimer.singleShot(3000, self.end_long_task)

        self.do_long_task(task)

    @Slot(str)
    def loadSketch(self, sketch, cb=None):
        def task():
            logging.error(f"Loading sketch : {sketch}")

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

                    # Load snapshot
                    logging.error(
                        f"Loading snapshot : '{str(last_selected_sketch_path.parent / 'soundsets')}/{last_selected_sketch_path.stem.replace('.sketch', '')}.zss'")
                    self.zyngui.screens["layer"].load_snapshot(
                        f"{str(last_selected_sketch_path.parent / 'soundsets')}/{last_selected_sketch_path.stem.replace('.sketch', '')}.zss")

                    QTimer.singleShot(3000, self.end_long_task)

                self.newSketch(sketch, _cb)
            else:
                logging.error(f"Loading Sketch : {str(sketch_path.parent.absolute()) + '/'}, {str(sketch_path.stem)}")
                self.__song__ = zynthiloops_song.zynthiloops_song(str(sketch_path.parent.absolute()) + "/", str(sketch_path.stem.replace(".sketch", "")), self)
                self.zyngui.screens["session_dashboard"].set_last_selected_sketch(str(sketch_path))

                # Load snapshot
                logging.error(
                    f"Loading snapshot : {str(sketch_path.parent.absolute()) + '/soundsets/' + str(sketch_path.stem.replace('.sketch', '')) + '.zss'}")
                self.zyngui.screens["layer"].load_snapshot(
                    str(sketch_path.parent.absolute()) + "/soundsets/" + str(
                        sketch_path.stem.replace(".sketch", "")) + ".zss")

                self.__song__.bpm_changed.connect(self.update_timer_bpm)
                self.song_changed.emit()

                QTimer.singleShot(3000, self.end_long_task)

            if cb is not None:
                cb()

        self.do_long_task(task)

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
            track = self.__song__.tracksModel.getTrack(self.zyngui.session_dashboard.selectedTrack)

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
            logging.error(
                f"Command jack_capture : /usr/local/bin/jack_capture {self.recorder_process_internal_arguments} {self.clip_to_record_path}")

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

            self.set_clip_to_record(clip)
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

        if self.clip_to_record.isTrackSample:
            logging.error(f"Recorded clip is a sample")
            track = self.__song__.tracksModel.getTrack(self.zyngui.session_dashboard.selectedTrack)
            track.samples_changed.emit()

        self.set_clip_to_record(None)
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

    def do_long_task(self, cb):
        logging.error("### Start long task")

        # Emit long task started if no other long task is already running
        if self.__long_task_count__ == 0:
            self.longTaskStarted.emit()

        self.__long_task_count__ += 1

        QTimer.singleShot(2000, cb)

    def end_long_task(self):
        logging.error("### End long task")
        self.__long_task_count__ -= 1

        # Emit long task ended only if all task has ended
        if self.__long_task_count__ == 0:
            self.longTaskEnded.emit()

    metronomeBeatUpdate4th = Signal(int)
    metronomeBeatUpdate8th = Signal(int)
    metronomeBeatUpdate16th = Signal(int)
    metronomeBeatUpdate32th = Signal(int)
    metronomeBeatUpdate64th = Signal(int)
    metronomeBeatUpdate128th = Signal(int)

    cannotRecordEmptyLayer = Signal()
    newSketchLoaded = Signal()
    longTaskStarted = Signal()
    longTaskEnded = Signal()
    presetUpdated = Signal()