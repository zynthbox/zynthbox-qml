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
from datetime import datetime
from os.path import dirname, realpath
from pathlib import Path
import json

import numpy as np
from PySide2.QtCore import QMetaObject, Qt, Property, QObject, QTimer, Signal, Slot

from .libzl.libzl import ClipAudioSource

sys.path.insert(1, "./libzl")
from .libzl import libzl
from . import sketchpad_clip, sketchpad_song

from .. import zynthian_qt_gui_base
from .. import zynthian_gui_controller
from .. import zynthian_gui_config
from zyngine import zynthian_controller
import jack


@ctypes.CFUNCTYPE(None, ctypes.c_int)
def libzlCb(beat):
    if beat % 32 == 0:
        zynthian_gui_sketchpad.__instance__.metronomeBeatUpdate4th.emit(beat / 32)

    if beat % 16 == 0:
        zynthian_gui_sketchpad.__instance__.metronomeBeatUpdate8th.emit(beat / 16)

    if beat % 8 == 0:
        zynthian_gui_sketchpad.__instance__.metronomeBeatUpdate16th.emit(beat / 8)

    if beat % 4 == 0:
        zynthian_gui_sketchpad.__instance__.metronomeBeatUpdate32th.emit(beat / 4)

    if beat % 2 == 0:
        zynthian_gui_sketchpad.__instance__.metronomeBeatUpdate64th.emit(beat / 2)

    zynthian_gui_sketchpad.__instance__.metronomeBeatUpdate128th.emit(beat)


class zynthian_gui_sketchpad(zynthian_qt_gui_base.ZynGui):
    __instance__ = None

    def __init__(self, parent=None):
        super(zynthian_gui_sketchpad, self).__init__(parent)

        logging.info(f"Initializing Sketchpad")

        zynthian_gui_sketchpad.__instance__ = self
        libzl.registerGraphicTypes()

        self.isZ2V3 = os.environ.get("ZYNTHIAN_WIRING_LAYOUT") == "Z2_V3"
        self.is_set_selector_running = False
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
        self.click_channel_click = ClipAudioSource(None, (dirname(realpath(__file__)) + "/assets/click_channel_click.wav").encode('utf-8'))
        self.click_channel_clack = ClipAudioSource(None, (dirname(realpath(__file__)) + "/assets/click_channel_clack.wav").encode('utf-8'))
        self.click_channel_enabled = False
        self.jack_client = None
        self.__jack_client_init_timer__ = QTimer()
        self.__jack_client_init_timer__.setInterval(1000)
        self.__jack_client_init_timer__.setSingleShot(True)
        self.__jack_client_init_timer__.timeout.connect(self.init_jack_client)
        self.__last_recording_type__ = ""
        self.__capture_audio_level_left__ = -400
        self.__capture_audio_level_right__ = -400
        self.__song__ = None
        self.__zselector = [None, None, None, None]
        self.__zselector_ctrl = [None, None, None, None]
        self.__zselector_channel = -1
        self.__selected_clip_col__ = 0
        self.__is_init_in_progress__ = True
        self.__long_task_count__ = 0
        self.__big_knob_mode__ = ""
        self.__long_operation__ = False
        self.__record_master_output__ = False
        self.__record_solo = False
        self.__count_in_bars__ = 0
        self.__global_fx_knob_value__ = 50
        self.clips_to_record = []
        self.__display_scene_buttons = False
        self.__recording_source = "internal"
        self.__recording_channel = "*"
        self.__recording_type = "audio"
        self.__last_recording_midi__ = ""

        self.big_knob_channel_multiplier = 1 if self.isZ2V3 else 10

        self.__master_audio_level__ = -200
        self.master_audio_level_timer = QTimer()
        self.master_audio_level_timer.setInterval(50)
        self.master_audio_level_timer.timeout.connect(self.master_volume_level_timer_timeout)
        self.zyngui.current_screen_id_changed.connect(self.sync_selector_visibility, Qt.QueuedConnection)

        self.set_selector_timer = QTimer()
        self.set_selector_timer.setSingleShot(True)
        self.set_selector_timer.setInterval(10)
        self.set_selector_timer.timeout.connect(self.set_selector)

        self.update_timer_bpm_timer = QTimer()
        self.update_timer_bpm_timer.setInterval(100)
        self.update_timer_bpm_timer.setSingleShot(True)
        self.update_timer_bpm_timer.timeout.connect(self.update_timer_bpm)

        self.__volume_control_obj = None

        Path('/zynthian/zynthian-my-data/samples/my-samples').mkdir(exist_ok=True, parents=True)
        Path('/zynthian/zynthian-my-data/samples/community-samples').mkdir(exist_ok=True, parents=True)
        Path('/zynthian/zynthian-my-data/sample-banks/my-samplebanks').mkdir(exist_ok=True, parents=True)
        Path('/zynthian/zynthian-my-data/sample-banks/community-samplebanks').mkdir(exist_ok=True, parents=True)

    def init_jack_client(self):
        try:
            jack.Client('').get_port_by_name("AudioLevels-SystemPlayback:left_in")
            self.jack_client = jack.Client('AudioLevels-SystemPlayback')
            logging.info(f"*** AudioLevels-SystemPlayback Jack client found. Continuing")

            # Connect all jack ports of respective channel after jack client initialization is done.
            for i in range(0, self.__song__.channelsModel.count):
                channel = self.__song__.channelsModel.getChannel(i)
                channel.update_jack_port()
        except:
            logging.info(f"*** AudioLevels-SystemPlayback Jack client not found. Checking again in 1000ms")
            self.__jack_client_init_timer__.start()

    def connect_control_objects(self):
        selected_channel = self.__song__.channelsModel.getChannel(self.zyngui.session_dashboard.get_selected_channel())

        if self.__volume_control_obj == self.zyngui.layers_for_channel.get_volume_controls()[selected_channel.selectedSlotRow]:
            return
        if self.__volume_control_obj:
            self.__volume_control_obj.value_changed.disconnect(self.set_selector)

        self.__volume_control_obj = self.zyngui.layers_for_channel.get_volume_controls()[selected_channel.selectedSlotRow]

        if self.__volume_control_obj:
            self.__volume_control_obj.value_changed.connect(self.set_selector)
            self.set_selector()

    def sync_selector_visibility(self):
        self.set_selector()

    def init_sketchpad(self, sketchpad, cb=None):
        def _cb():
            libzl.registerTimerCallback(libzlCb)

            self.metronomeBeatUpdate4th.connect(self.metronome_update)
            self.metronomeBeatUpdate8th.connect(self.zyngui.increment_blink_count)
            self.zyngui.master_alsa_mixer.volume_changed.connect(lambda: self.master_volume_changed.emit())
            self.update_timer_bpm()

            if cb is not None:
                cb()

            self.zyngui.layers_for_channel.fill_list()
            self.zyngui.sketchpad.set_selector()
            self.zyngui.session_dashboard.set_selected_channel(0, True)
            self.__is_init_in_progress__ = False
            logging.info(f"Sketchpad Initialization Complete")

            self.zyngui.zynautoconnect(True)

            for i in range(0, self.__song__.channelsModel.count):
                channel = self.__song__.channelsModel.getChannel(i)
                channel.update_jack_port()

        self.master_audio_level_timer.start()

        if sketchpad is not None:
            logging.debug(f"### Checking Sketchpad : {sketchpad} : exists({Path(sketchpad).exists()}) ")
        else:
            logging.debug(f"### Checking Sketchpad : sketchpad is none ")

        if sketchpad is not None and Path(sketchpad).exists():
            self.loadSketchpad(sketchpad, True, False, _cb)
        else:
            self.newSketchpad(None, _cb)

    @Slot(None)
    def zyncoder_set_selected_segment(self):
        if self.__big_knob_mode__ == "segment" and self.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex != round(self.__zselector[0].value/self.big_knob_channel_multiplier):
            logging.debug(f"Setting segment from zyncoder {round(self.__zselector[0].value/self.big_knob_channel_multiplier)}")
            self.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex = round(self.__zselector[0].value/self.big_knob_channel_multiplier)
            self.set_selector()

    @Slot(None)
    def zyncoder_set_selected_channel(self):
        if self.__big_knob_mode__ == "channel" and self.zyngui.session_dashboard.get_selected_channel() != round(self.__zselector[0].value/self.big_knob_channel_multiplier):
            logging.debug(f"Setting channel from zyncoder {round(self.__zselector[0].value/self.big_knob_channel_multiplier)}")
            self.zyngui.session_dashboard.set_selected_channel(round(self.__zselector[0].value/self.big_knob_channel_multiplier))
            self.set_selector()

    @Slot(None)
    def zyncoder_set_preset(self):
        channel = self.__song__.channelsModel.getChannel(self.zyngui.session_dashboard.selectedChannel)
        selected_channel = channel.get_chained_sounds()[channel.selectedSlotRow]

        if self.__big_knob_mode__ == "preset" and selected_channel in self.zyngui.layer.layer_midi_map:
            layer = self.zyngui.layer.layer_midi_map[selected_channel]
            preset_index = min(round(self.__zselector[0].value / 1000), len(layer.preset_list) - 1)
            self.set_preset_actual(preset_index)

    def set_preset_actual(self, preset_index):
        channel = self.__song__.channelsModel.getChannel(self.zyngui.session_dashboard.selectedChannel)
        selected_channel = channel.get_chained_sounds()[channel.selectedSlotRow]
        preset_index = int(preset_index)
        try:
            preset_name = channel.getLayerNameByMidiChannel(selected_channel).split('>')[1]
        except:
            preset_name = ""

        if self.__big_knob_mode__ == "preset" and selected_channel in self.zyngui.layer.layer_midi_map:
            layer = self.zyngui.layer.layer_midi_map[selected_channel]

            if channel.checkIfLayerExists(selected_channel) and layer.preset_index != preset_index:
                logging.debug(f"Selecting preset : {preset_index}")
                layer.set_preset(preset_index, True)
                channel.chainedSoundsInfoChanged.emit()
                self.set_selector()
                self.zyngui.fixed_layers.fill_list()
                self.zyngui.osd.updateOsd(
                    parameterName="selected_preset",
                    description=f"Preset({preset_index+1}/{len(self.zyngui.layer.layer_midi_map[selected_channel].preset_list)})",
                    start=0,
                    stop=len(self.zyngui.layer.layer_midi_map[selected_channel].preset_list) - 1,
                    step=1,
                    defaultValue=None,
                    currentValue=preset_index,
                    setValueFunction=self.set_preset_actual,
                    startLabel="1",
                    stopLabel=f"{len(self.zyngui.layer.layer_midi_map[selected_channel].preset_list)}",
                    valueLabel=preset_name,
                    showValueLabel=True,
                    visualZero=None,
                    showResetToDefault=False,
                    showVisualZero=False
                )

    @Slot(None)
    def zyncoder_update_layer_volume(self):
        self.set_layer_volume_actual(self.__zselector[1].value / 1000)

    def set_layer_volume_actual(self, volume):
        selected_channel = self.__song__.channelsModel.getChannel(self.zyngui.session_dashboard.get_selected_channel())
        try:
            synth_name = selected_channel.getLayerNameByMidiChannel(selected_channel.selectedSlotRow).split('>')[0]
        except:
            synth_name = ""

        try:
            if ((self.zyngui.slotsBarChannelActive and selected_channel.channelAudioType == "synth") or self.zyngui.slotsBarSynthsActive) and \
                        selected_channel.checkIfLayerExists(selected_channel.chainedSounds[selected_channel.selectedSlotRow]):
                volume_control_obj = self.zyngui.layers_for_channel.volume_controls[selected_channel.selectedSlotRow]
            elif self.zyngui.sound_combinator_active and \
                    selected_channel.checkIfLayerExists(selected_channel.chainedSounds[selected_channel.selectedSlotRow]):
                volume_control_obj = self.zyngui.layers_for_channel.volume_controls[selected_channel.selectedSlotRow]
            else:
                volume_control_obj = None
        except:
            volume_control_obj = None

        if volume_control_obj is not None and \
           volume_control_obj.value != volume:
            volume_control_obj.value = volume
            logging.debug(f"### zyncoder_update_layer_volume {volume_control_obj.value}")
            self.set_selector()

            self.zyngui.osd.updateOsd(
                parameterName="layer_volume",
                description=f"{synth_name} Volume",
                start=volume_control_obj.value_min,
                stop=volume_control_obj.value_max,
                step=volume_control_obj.step_size,
                defaultValue=None,
                currentValue=volume_control_obj.value,
                setValueFunction=self.set_layer_volume_actual,
                showValueLabel=True,
                showResetToDefault=False,
                showVisualZero=False
            )

    @Slot(None)
    def zyncoder_update_channel_volume(self):
        volume = np.interp(self.__zselector[1].value, (0, 60), (-40, 20))
        self.set_channel_volume_actual(volume)

    def set_channel_volume_actual(self, volume):
        selected_channel = self.__song__.channelsModel.getChannel(self.zyngui.session_dashboard.get_selected_channel())

        if selected_channel.volume != volume:
            # zselector doesnt support negetive mimimum value. Need to interoporale zyncoder value from range(0 to 60) to actual range(-40 to 20)
            selected_channel.volume = volume
            logging.debug(f"### zyncoder_update_channel_volume {selected_channel.volume}")
            self.set_selector()
            self.zyngui.osd.updateOsd(
                parameterName="channel_volume",
                description=f"{selected_channel.name} Volume",
                start=-40,
                stop=20,
                step=1,
                defaultValue=0,
                currentValue=selected_channel.volume,
                setValueFunction=self.set_channel_volume_actual,
                showValueLabel=True
            )

    @Slot(None)
    def zyncoder_update_clip_start_position(self):
        selected_channel_obj = self.__song__.channelsModel.getChannel(self.zyngui.session_dashboard.get_selected_channel())
        selected_clip = None

        if self.zyngui.channelWaveEditorBarActive:
            selected_clip = selected_channel_obj.samples[selected_channel_obj.selectedSlotRow]
        elif self.zyngui.clipWaveEditorBarActive:
            selected_clip = self.__song__.getClip(selected_channel_obj.id, self.song.scenesModel.selectedTrackIndex)

        if selected_clip is not None and selected_clip.startPosition != (self.__zselector[1].value / 1000):
            selected_clip.startPosition = self.__zselector[1].value / 1000
            logging.debug(f"### zyncoder_update_clip_start_position {selected_clip.startPosition}")
            self.set_selector()

    @Slot(None)
    def zyncoder_update_clip_loop(self):
        selected_channel_obj = self.__song__.channelsModel.getChannel(self.zyngui.session_dashboard.get_selected_channel())
        selected_clip = None

        if self.zyngui.channelWaveEditorBarActive:
            selected_clip = selected_channel_obj.samples[selected_channel_obj.selectedSlotRow]
        elif self.zyngui.clipWaveEditorBarActive:
            selected_clip = self.__song__.getClip(selected_channel_obj.id, self.song.scenesModel.selectedTrackIndex)

        if selected_clip is not None and selected_clip.loopDelta != self.__zselector[2].value/1000:
            selected_clip.loopDelta = self.__zselector[2].value/1000
            logging.debug(f"### zyncoder_update_clip_loop {selected_clip.loopDelta}")
            self.set_selector()

    def update_channel_pan_actual(self, pan):
        selected_channel_obj = self.__song__.channelsModel.getChannel(self.zyngui.session_dashboard.get_selected_channel())

        # Do not set pan value if change is less than step size of 0.1
        if selected_channel_obj is not None and selected_channel_obj.pan != pan:
            logging.debug(f"### zyncoder_update_channel_pan from {selected_channel_obj.pan} to {pan}")
            selected_channel_obj.pan = pan
            self.set_selector()
            self.zyngui.osd.updateOsd("channel_pan", f"Channel {selected_channel_obj.id + 1}: Pan", 1, -1, 0.1, 0, selected_channel_obj.pan, self.set_selected_channel_pan, startLabel="L", stopLabel="R", showValueLabel=False, visualZero=0)

    def set_selected_channel_pan(self, pan):
        self.update_channel_pan_actual(min(max(-1, round(pan, 2)), 1))

    @Slot(None)
    def zyncoder_update_channel_pan(self):
        pan = round(np.interp(self.__zselector[2].value, (0, 1000), (-1.0, 1.0)), 2)
        self.update_channel_pan_actual(-1 * pan)

    @Slot(None)
    def zyncoder_update_clip_length(self):
        selected_channel_obj = self.__song__.channelsModel.getChannel(self.zyngui.session_dashboard.get_selected_channel())
        selected_clip = None

        if self.zyngui.channelWaveEditorBarActive:
            selected_clip = selected_channel_obj.samples[selected_channel_obj.selectedSlotRow]
        elif self.zyngui.clipWaveEditorBarActive:
            selected_clip = self.__song__.getClip(selected_channel_obj.id, self.song.scenesModel.selectedTrackIndex)

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
        if self.zyngui.knobTouchUpdateInProgress:
            return
        if self.is_set_selector_running:
            # Set selector in progress. Not setting value with encoder
            return

        if self.__zselector[0] and self.__song__:
            self.__zselector[0].read_zyncoder()

            if self.__big_knob_mode__ == "preset":
                QMetaObject.invokeMethod(self, "zyncoder_set_preset", Qt.QueuedConnection)
            elif self.__big_knob_mode__ == "segment":
                QMetaObject.invokeMethod(self, "zyncoder_set_selected_segment", Qt.QueuedConnection)
            elif self.__big_knob_mode__ == "channel":
                QMetaObject.invokeMethod(self, "zyncoder_set_selected_channel", Qt.QueuedConnection)

        # Update clip startposition/layer volume when required with small knob 1
        if self.__zselector[1] and self.__song__:
            self.__zselector[1].read_zyncoder()
            if self.zyngui.sound_combinator_active or self.zyngui.slotsBarChannelActive or self.zyngui.slotsBarSynthsActive:
                QMetaObject.invokeMethod(self, "zyncoder_update_layer_volume", Qt.QueuedConnection)
            elif self.zyngui.slotsBarMixerActive:
                QMetaObject.invokeMethod(self, "zyncoder_update_channel_volume", Qt.QueuedConnection)
            else:
                QMetaObject.invokeMethod(self, "zyncoder_update_clip_start_position", Qt.QueuedConnection)

        # Update clip length when required with small knob 2
        if self.__zselector[2] and self.__song__:
            self.__zselector[2].read_zyncoder()
            if self.zyngui.slotsBarMixerActive:
                QMetaObject.invokeMethod(self, "zyncoder_update_channel_pan", Qt.QueuedConnection)
            else:
                QMetaObject.invokeMethod(self, "zyncoder_update_clip_loop", Qt.QueuedConnection)

        # Update clip length when required with small knob 3
        if self.__zselector[3] and self.__song__:
            self.__zselector[3].read_zyncoder()

            if self.zyngui.channelWaveEditorBarActive or self.zyngui.clipWaveEditorBarActive:
                QMetaObject.invokeMethod(self, "zyncoder_update_clip_length", Qt.QueuedConnection)

        return [0, 1, 2, 3]

    @Slot(None)
    def configure_big_knob(self):
        try:
            if self.__zselector[0] is not None:
                self.__zselector[0].show()

            if self.zyngui.sound_combinator_active:
                # If sound combinator is active, Use Big knob to control preset

                self.__big_knob_mode__ = "preset"

                logging.debug(f"### set_selector : Configuring big knob, sound combinator is active.")
                channel = self.__song__.channelsModel.getChannel(self.zyngui.session_dashboard.selectedChannel)
                selected_channel = channel.get_chained_sounds()[channel.selectedSlotRow]
                logging.debug(f"### selectedChannel : channel{self.zyngui.session_dashboard.selectedChannel}({channel}), slot({channel.selectedSlotRow}), channel({selected_channel})")
                preset_index = 0
                max_value = 0

                try:
                    preset_index = self.zyngui.layer.layer_midi_map[selected_channel].preset_index * 1000
                    max_value = (len(self.zyngui.layer.layer_midi_map[selected_channel].preset_list) - 1) * 1000
                except:
                    pass

                if self.__zselector[0] is None:
                    self.__zselector_ctrl[0] = zynthian_controller(None, 'sketchpad_preset', 'sketchpad_preset',
                                                                {'midi_cc': 0, 'value': preset_index})

                    self.__zselector[0] = zynthian_gui_controller(zynthian_gui_config.select_ctrl,
                                                                  self.__zselector_ctrl[0], self)
                    self.__zselector[0].show()

                self.__zselector_ctrl[0].set_options(
                    {'symbol': 'sketchpad_preset', 'name': 'Sketchpad Preset', 'short_name': 'Preset', 'midi_cc': 0,
                     'value_max': max_value, 'value_min': 0, 'value': preset_index})

                self.__zselector[0].config(self.__zselector_ctrl[0])
                self.__zselector[0].custom_encoder_speed = 0
            elif self.song.sketchesModel.songMode:
                # If sound combinator is not active and in song mode, Use Big knob to control selected segment

                self.__big_knob_mode__ = "segment"

                try:
                    selected_segment = self.song.sketchesModel.selectedSketch.segmentsModel.selectedSegmentIndex * self.big_knob_channel_multiplier
                except:
                    selected_segment = 0

                logging.debug(
                    f"### set_selector : Configuring big knob, sound combinator is not active and song mode is active. selected_segment({selected_segment // self.big_knob_channel_multiplier})")

                if self.__zselector[0] is None:
                    self.__zselector_ctrl[0] = zynthian_controller(None, 'sketchpad_segment', 'sketchpad_segment',
                                                                   {'midi_cc': 0, 'value': selected_segment,
                                                                    'step': 1})

                    self.__zselector[0] = zynthian_gui_controller(zynthian_gui_config.select_ctrl,
                                                                  self.__zselector_ctrl[0],
                                                                  self)
                    self.__zselector[0].show()

                self.__zselector_ctrl[0].set_options(
                    {'symbol': 'sketchpad_segment', 'name': 'sketchpad_segment', 'short_name': 'sketchpad_segment', 'midi_cc': 0,
                     'value_min': 0, 'value_max': (self.song.sketchesModel.selectedSketch.segmentsModel.count - 1) * self.big_knob_channel_multiplier, 'value': selected_segment, 'step': 1})

                self.__zselector[0].config(self.__zselector_ctrl[0])

                if not self.isZ2V3:
                    self.__zselector[0].custom_encoder_speed = 0
            else:
                # If sound combinator is not active and not song mode, Use Big knob to control selected channel

                self.__big_knob_mode__ = "channel"

                try:
                    selected_channel = self.zyngui.session_dashboard.get_selected_channel() * self.big_knob_channel_multiplier
                except:
                    selected_channel = 0

                logging.debug(f"### set_selector : Configuring big knob, sound combinator is not active and song mode is not active. selected_channel({selected_channel // self.big_knob_channel_multiplier})")

                if self.__zselector[0] is None:
                    self.__zselector_ctrl[0] = zynthian_controller(None, 'sketchpad_channel', 'sketchpad_channel',
                                                                {'midi_cc': 0, 'value': selected_channel, 'step': 1})

                    self.__zselector[0] = zynthian_gui_controller(zynthian_gui_config.select_ctrl, self.__zselector_ctrl[0],
                                                                  self)
                    self.__zselector[0].show()

                self.__zselector_ctrl[0].set_options(
                    {'symbol': 'sketchpad_channel', 'name': 'sketchpad_channel', 'short_name': 'sketchpad_channel', 'midi_cc': 0,
                     'value_min': 0, 'value_max': 9*self.big_knob_channel_multiplier, 'value': selected_channel, 'step': 1})

                self.__zselector[0].config(self.__zselector_ctrl[0])

                if not self.isZ2V3:
                    self.__zselector[0].custom_encoder_speed = 0
        except:
            if self.__zselector[0] is not None:
                self.__zselector[0].hide()

    def configure_small_knob_1(self, selected_channel, selected_clip):
        if self.__zselector[1] is None:
            self.__zselector_ctrl[1] = zynthian_controller(None, 'sketchpad_knob1',
                                                            'sketchpad_knob1',
                                                            {'midi_cc': 0, 'value': 0})

            self.__zselector[1] = zynthian_gui_controller(zynthian_gui_config.select_ctrl, self.__zselector_ctrl[1],
                                                            self)
            self.__zselector[1].index = 0
        if self.zyngui.get_current_screen_id() is not None and \
                self.zyngui.get_current_screen() == self and \
                (
                    (self.zyngui.channelWaveEditorBarActive or self.zyngui.clipWaveEditorBarActive) and
                    selected_clip is not None and
                    selected_clip.path is not None and
                    len(selected_clip.path) > 0
                ) or (
                    self.zyngui.sound_combinator_active and
                    selected_channel is not None and
                    selected_channel.checkIfLayerExists(selected_channel.chainedSounds[selected_channel.selectedSlotRow])
                ) or (
                    ((self.zyngui.slotsBarChannelActive and selected_channel.channelAudioType == "synth") or self.zyngui.slotsBarSynthsActive) and
                    selected_channel is not None and
                    selected_channel.checkIfLayerExists(selected_channel.chainedSounds[selected_channel.selectedSlotRow])
                ) or (
                    self.zyngui.slotsBarMixerActive and
                    selected_channel is not None
                ):
            logging.debug(
                f"### set_selector : Configuring small knob 1, showing")

            self.__zselector[1].show()
        else:
            logging.debug(
                f"### set_selector : Configuring small knob 1, hiding")

            if self.__zselector[1]:
                self.__zselector[1].hide()

        if self.zyngui.sound_combinator_active or self.zyngui.slotsBarChannelActive or self.zyngui.slotsBarSynthsActive:
            volume = 0
            min_value = 0
            max_value = 0

            try:
                # logging.error(f"layer({selected_channel.chainedSounds[selected_channel.selectedSlotRow]}), layerExists({selected_channel.checkIfLayerExists(selected_channel.chainedSounds[selected_channel.selectedSlotRow])})")

                if self.zyngui.sound_combinator_active and \
                        selected_channel.checkIfLayerExists(
                            selected_channel.chainedSounds[selected_channel.selectedSlotRow]):
                    volume_control_obj = self.zyngui.layers_for_channel.volume_controls[selected_channel.selectedSlotRow]
                    volume = volume_control_obj.value * 1000
                    min_value = volume_control_obj.value_min * 1000
                    max_value = volume_control_obj.value_max * 1000
                elif ((self.zyngui.slotsBarChannelActive and selected_channel.channelAudioType == "synth") or self.zyngui.slotsBarSynthsActive) and \
                        selected_channel.checkIfLayerExists(selected_channel.chainedSounds[selected_channel.selectedSlotRow]):
                    volume_control_obj = self.zyngui.layers_for_channel.volume_controls[selected_channel.selectedSlotRow]
                    volume = volume_control_obj.value * 1000
                    min_value = volume_control_obj.value_min * 1000
                    max_value = volume_control_obj.value_max * 1000
            except Exception as e:
                logging.error(f"Error configuring knob 1 : {str(e)}")

            logging.debug(
                f"### set_selector : Configuring small knob 1, value({volume}), max_value({max_value}), min_value({min_value})")

            self.__zselector_ctrl[1].set_options(
                {'symbol': 'sketchpad_knob1', 'name': 'Sketchpad Knob 1',
                 'short_name': 'Knob1',
                 'midi_cc': 0, 'value_max': round(max_value), 'value_min': round(min_value), 'value': round(volume)})

            self.__zselector[1].config(self.__zselector_ctrl[1])
            self.__zselector[1].custom_encoder_speed = 0
        elif self.zyngui.slotsBarMixerActive:
            # zselector doesnt negetive minimum value. need to interpolate actual range (-40 to 20) to range (0 to 60)
            volume = np.interp(selected_channel.volume, (-40, 20), (0, 60))

            if self.__zselector[1] is None:
                self.__zselector_ctrl[1] = zynthian_controller(None, 'sketchpad_knob1',
                                                               'sketchpad_knob1',
                                                               {'midi_cc': 0, 'value': volume})

                self.__zselector[1] = zynthian_gui_controller(zynthian_gui_config.select_ctrl, self.__zselector_ctrl[1],
                                                              self)
                self.__zselector[1].index = 0

            logging.debug(f"### set_selector : Configuring small knob 1, value({volume})")


            self.__zselector_ctrl[1].set_options(
                {'symbol': 'sketchpad_knob1', 'name': 'Sketchpad Knob 1', 'short_name': 'Knob1',
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
                self.__zselector_ctrl[1] = zynthian_controller(None, 'sketchpad_knob1',
                                                               'sketchpad_knob1',
                                                               {'midi_cc': 0, 'value': start_position})

                self.__zselector[1] = zynthian_gui_controller(zynthian_gui_config.select_ctrl, self.__zselector_ctrl[1],
                                                              self)
                self.__zselector[1].index = 0

            logging.debug(f"### set_selector : Configuring small knob 1, value({start_position}), max_value({max_value})")

            self.__zselector_ctrl[1].set_options(
                {'symbol': 'sketchpad_knob1', 'name': 'Sketchpad Knob 1', 'short_name': 'Knob1',
                 'midi_cc': 0, 'value_max': max_value, 'value': start_position})

            self.__zselector[1].config(self.__zselector_ctrl[1])
            self.__zselector[1].custom_encoder_speed = 0


    def configure_small_knob_2(self, selected_channel, selected_clip):
        if self.__zselector[2] is None:
            self.__zselector_ctrl[2] = zynthian_controller(None, 'sketchpad_knob2',
                                                           'sketchpad_knob2',
                                                           {'midi_cc': 0, 'value': 0})

            self.__zselector[2] = zynthian_gui_controller(zynthian_gui_config.select_ctrl, self.__zselector_ctrl[2], self)
            self.__zselector[2].index = 1

        if (self.zyngui.get_current_screen_id() is not None and \
                self.zyngui.get_current_screen() == self and \
                (self.zyngui.channelWaveEditorBarActive or self.zyngui.clipWaveEditorBarActive) and \
                selected_clip is not None and \
                selected_clip.path is not None and \
                len(selected_clip.path) > 0) or (
            selected_channel is not None and \
                self.zyngui.slotsBarMixerActive
        ):
            logging.debug(
                f"### set_selector : Configuring small knob 2, showing")

            self.__zselector[2].show()
        else:
            logging.debug(
                f"### set_selector : Configuring small knob 2, hiding")
            self.__zselector[2].hide()

        if self.zyngui.slotsBarMixerActive:
            pan_interped = 0

            try:
                if selected_channel is not None:
                    pan_interped = np.interp(-1 * selected_channel.pan, (-1.0, 1.0), (0, 1000))
            except Exception as e:
                logging.error(f"Error configuring knob 2 : {str(e)}")

            logging.debug(
                f"### set_selector : Configuring small knob 2, value({pan_interped})")

            self.__zselector_ctrl[2].set_options(
                {'symbol': 'sketchpad_knob2', 'name': 'sketchpad_knob2',
                 'short_name': 'sketchpad_knob2', 'midi_cc': 0, 'value_max': 1001, 'value': pan_interped})

            self.__zselector[2].config(self.__zselector_ctrl[2])
            self.__zselector[2].custom_encoder_speed = 0
        else:
            loop = 0
            max_value = 0

            try:
                if selected_clip is not None and selected_clip.path is not None and len(selected_clip.path) > 0:
                    loop = int(selected_clip.loopDelta * 1000)
                    max_value = int(selected_clip.secPerBeat * selected_clip.length * 1000)
            except Exception as e:
                logging.error(f"Error configuring knob 2 : {str(e)}")

            logging.debug(
                f"### set_selector : Configuring small knob 2, value({loop}), max_value({max_value})")

            self.__zselector_ctrl[2].set_options(
                {'symbol': 'sketchpad_knob2', 'name': 'sketchpad_knob2',
                 'short_name': 'sketchpad_knob2', 'midi_cc': 0, 'value_max': max_value, 'value': loop})

            self.__zselector[2].config(self.__zselector_ctrl[2])
            self.__zselector[2].custom_encoder_speed = 0


    def configure_small_knob_3(self, selected_channel, selected_clip):
        value = 0
        min_value = 0
        max_value = 0

        try:
            if self.zyngui.get_current_screen_id() is not None and \
                    self.zyngui.get_current_screen() == self and \
                    (self.zyngui.channelWaveEditorBarActive or self.zyngui.clipWaveEditorBarActive) and \
                    selected_clip is not None and \
                    selected_clip.path is not None and \
                    len(selected_clip.path) > 0:
                value = selected_clip.length * 100
                max_value = 64 * 100
                min_value = 0
        except Exception as e:
            logging.error(f"Error configuring knob 3 : {str(e)}")

        if self.__zselector[3] is None:
            self.__zselector_ctrl[3] = zynthian_controller(None, 'sketchpad_knob3',
                                                           'sketchpad_knob3',
                                                           {'midi_cc': 0, 'value': value})

            self.__zselector[3] = zynthian_gui_controller(zynthian_gui_config.select_ctrl, self.__zselector_ctrl[3],
                                                          self)
            self.__zselector[3].index = 2

        if self.zyngui.get_current_screen_id() is not None and \
                self.zyngui.get_current_screen() == self and \
                (self.zyngui.channelWaveEditorBarActive or self.zyngui.clipWaveEditorBarActive) and \
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
            {'symbol': 'sketchpad_knob3', 'name': 'Sketchpad Knob3',
             'short_name': 'Knob3',
             'midi_cc': 0, 'value_max': max_value, 'value_min': min_value, 'value': value})

        self.__zselector[3].config(self.__zselector_ctrl[3])

    def set_selector_throttled(self):
        self.set_selector_timer.start()

    def set_set_selector_active(self):
        self.is_set_selector_running = True

    @Slot(None)
    def set_selector(self, big_knob=True, small_knob1=True, small_knob2=True, small_knob3=True,):
        # Hide selectors and return if dependent variables is None or a long operation is in progress
        if self.__song__ is None or \
                (self.zyngui.globalPopupOpened or self.zyngui.metronomeButtonPressed) or \
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
        selected_channel_obj = self.__song__.channelsModel.getChannel(self.zyngui.session_dashboard.get_selected_channel())

        if self.zyngui.channelWaveEditorBarActive:
            logging.debug(f"### set_selector : channelWaveEditorBarActive is active.")
            selected_clip = selected_channel_obj.samples[selected_channel_obj.selectedSlotRow]
        elif self.zyngui.clipWaveEditorBarActive:
            logging.debug(f"### set_selector : clipWaveEditorBarActive is active.")
            selected_clip = self.__song__.getClip(selected_channel_obj.id, self.song.scenesModel.selectedTrackIndex)
        ###

        # Configure Big Knob
        if big_knob:
            self.configure_big_knob()

        # Configure small knob 1
        if small_knob1:
            self.configure_small_knob_1(selected_channel_obj, selected_clip)

        # Configure small knob 2
        if small_knob2:
            self.configure_small_knob_2(selected_channel_obj, selected_clip)

        # Configure small knob 3
        if small_knob3:
            self.configure_small_knob_3(selected_channel_obj, selected_clip)

        self.is_set_selector_running = False

    def switch_select(self, t):
        pass

    def back_action(self):
        return "sketchpad"

    @Slot(None)
    def startMonitorMasterAudioLevels(self):
        self.master_audio_level_timer.start()

    @Slot(None)
    def stopMonitorMasterAudioLevels(self):
        self.master_audio_level_timer.stop()

    def master_volume_level_timer_timeout(self):
        try:
            added_db = 0
            for i in range(0, self.__song__.channelsModel.count):
                channel = self.__song__.channelsModel.getChannel(i)
                added_db += pow(10, channel.get_audioLevel()/10)

            self.set_master_audio_level(10*math.log10(added_db))
        except:
            self.set_master_audio_level(0)

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

    @Signal
    def master_volume_changed(self):
        pass

    def get_master_volume(self):
        return self.zyngui.master_alsa_mixer.volume

    @Signal
    def click_channel_enabled_changed(self):
        pass

    def get_clickChannelEnabled(self):
        return self.click_channel_enabled

    def set_clickChannelEnabled(self, enabled: bool):
        self.click_channel_enabled = enabled

        self.click_channel_click.stopOnChannel(-2)
        self.click_channel_clack.stopOnChannel(-2)
        self.click_channel_click.set_length(4, self.__song__.bpm)
        self.click_channel_clack.set_length(1, self.__song__.bpm)
        # If the metronome is running, queue the click channels up to start (otherwise don't - for now at least)
        if enabled and self.metronome_running_refcount > 0:
            self.click_channel_click.queueClipToStartOnChannel(-2)
            self.click_channel_clack.queueClipToStartOnChannel(-2)

        self.click_channel_enabled_changed.emit()

    clickChannelEnabled = Property(bool, get_clickChannelEnabled, set_clickChannelEnabled, notify=click_channel_enabled_changed)

    def channel_layers_snapshot(self):
        snapshot = []
        for i in range(5, 10):
            if i in self.zyngui.screens['layer'].layer_midi_map:
                layer_to_copy = self.zyngui.screens['layer'].layer_midi_map[i]
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
            if i in self.zyngui.screens['layer'].layer_midi_map:
                self.zyngui.screens['layer'].remove_root_layer(self.zyngui.screens['layer'].root_layers.index(self.zyngui.screens['layer'].layer_midi_map[i]), True)
        self.zyngui.screens['layer'].load_channels_snapshot(self.__song__.channelsModel.getChannel(tid).get_layers_snapshot(), 5, 9)

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
    def newSketchpad(self, base_sketchpad=None, cb=None):
        def task():
            try:
                self.__song__.bpm_changed.disconnect()
            except Exception as e:
                logging.error(f"Already disconnected : {str(e)}")

            self.zyngui.currentTaskMessage = "Stopping playback"

            try:
                self.stopAllPlayback()
                self.zyngui.screens["playgrid"].stopMetronomeRequest()
                self.zyngui.screens["song_arranger"].stop()
                self.resetMetronome()
            except:
                pass

            if self.__song__ is not None:
                self.__song__.to_be_deleted()

            if (self.__sketchpad_basepath__ / 'temp').exists():
                self.zyngui.currentTaskMessage = "Removing existing temp sketchpad"
                shutil.rmtree(self.__sketchpad_basepath__ / 'temp')

            if base_sketchpad is not None:
                logging.info(f"Creating New Sketchpad from community sketchpad : {base_sketchpad}")
                self.zyngui.currentTaskMessage = "Copying community sketchpad to my sketchpads"

                base_sketchpad_path = Path(base_sketchpad)

                # Copy community sketchpad to my sketchpads

                new_sketchpad_name = self.generate_unique_mysketchpad_name(base_sketchpad_path.parent.name)
                shutil.copytree(base_sketchpad_path.parent, self.__sketchpad_basepath__ / new_sketchpad_name)

                logging.info(f"Loading new sketchpad from community sketchpad : {str(self.__sketchpad_basepath__ / new_sketchpad_name / base_sketchpad_path.name)}")

                self.__song__ = sketchpad_song.sketchpad_song(str(self.__sketchpad_basepath__ / new_sketchpad_name) + "/",
                                                                  base_sketchpad_path.stem.replace(".sketchpad", ""), self)
                self.zyngui.screens["session_dashboard"].set_last_selected_sketchpad(
                    str(self.__sketchpad_basepath__ / new_sketchpad_name / base_sketchpad_path.name))

                # In case a base sketchpad is supplied, handle loading snapshot from the source

                self.__song__.bpm_changed.connect(self.update_timer_bpm_timer.start)
                self.song_changed.emit()
                self.zyngui.screens["session_dashboard"].set_selected_channel(0, True)
            else:
                logging.info(f"Creating New Sketchpad")
                self.zyngui.currentTaskMessage = "Creating empty sketchpad as temp sketchpad"

                self.__song__ = sketchpad_song.sketchpad_song(str(self.__sketchpad_basepath__ / "temp") + "/", "Sketchpad-1", self)
                self.zyngui.screens["session_dashboard"].set_last_selected_sketchpad(
                    str(self.__sketchpad_basepath__ / 'temp' / 'Sketchpad-1.sketchpad.json'))

                if Path("/zynthian/zynthian-my-data/snapshots/default.zss").exists():
                    logging.info(f"Loading default snapshot")
                    self.zyngui.currentTaskMessage = "Loading snapshot"
                    self.zyngui.screens["layer"].load_snapshot("/zynthian/zynthian-my-data/snapshots/default.zss")

                # Connect all jack ports of respective channel after jack client initialization is done.
                for i in range(0, self.__song__.channelsModel.count):
                    channel = self.__song__.channelsModel.getChannel(i)
                    channel.update_jack_port()

                self.__song__.bpm_changed.connect(self.update_timer_bpm)
                self.song_changed.emit()
                self.zyngui.screens["session_dashboard"].set_selected_channel(0, True)
                self.newSketchpadLoaded.emit()

            # Set ALSA Mixer volume to 100% when creating new sketchpad
            self.zyngui.screens["master_alsa_mixer"].volume = 100

            # Update volume controls
            self.zyngui.fixed_layers.fill_list()
            self.set_selector()

            if cb is not None:
                cb()

            self.zyngui.currentTaskMessage = "Finalizing"

            self.longOperationDecrement()
            QTimer.singleShot(3000, self.zyngui.end_long_task)

        self.zyngui.currentTaskMessage = "Creating New Sketchpad"
        self.longOperationIncrement()
        self.zyngui.do_long_task(task)

    @Slot(None)
    def saveSketchpad(self):
        def task():
            self.__song__.save(False)
            QTimer.singleShot(3000, self.zyngui.end_long_task)

        self.zyngui.currentTaskMessage = "Saving sketchpad"
        self.zyngui.showCurrentTaskMessage = False
        self.zyngui.do_long_task(task)

    @Slot(str)
    def createSketchpad(self, name):
        def task():
            self.stopAllPlayback()
            self.zyngui.screens["playgrid"].stopMetronomeRequest()
            self.zyngui.screens["song_arranger"].stop()
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
            self.zyngui.screens["session_dashboard"].set_last_selected_sketchpad(
                str(self.__sketchpad_basepath__ / name / f'{name}.sketchpad.json'))
            self.__song__.save(False)

            self.__song__.bpm_changed.connect(self.update_timer_bpm)

            self.song_changed.emit()
            self.longOperationDecrement()
            QTimer.singleShot(3000, self.zyngui.end_long_task)

        self.zyngui.currentTaskMessage = f"Saving Sketchpad : {name}"
        self.zyngui.showCurrentTaskMessage = False
        self.longOperationIncrement()
        self.zyngui.do_long_task(task)

    @Slot(str)
    def saveCopy(self, name):
        def task():
            old_folder = self.__song__.sketchpad_folder
            shutil.copytree(old_folder, self.__sketchpad_basepath__ / name)

            QTimer.singleShot(3000, self.zyngui.end_long_task)

        self.zyngui.currentTaskMessage = "Saving a copy of the sketchpad"
        self.zyngui.showCurrentTaskMessage = False
        self.zyngui.do_long_task(task)

    @Slot(str, bool)
    def loadSketchpad(self, sketchpad, load_history, load_snapshot=True, cb=None):
        def task():
            logging.info(f"Loading sketchpad : {sketchpad}")

            try:
                self.__song__.bpm_changed.disconnect()
            except Exception as e:
                logging.error(f"Already disconnected : {str(e)}")

            sketchpad_path = Path(sketchpad)

            self.zyngui.currentTaskMessage = "Stopping playback"
            try:
                self.stopAllPlayback()
                self.zyngui.screens["playgrid"].stopMetronomeRequest()
                self.zyngui.screens["song_arranger"].stop()
                self.resetMetronome()
            except:
                pass

            if sketchpad_path.parent.match("*/zynthian-my-data/sketchpads/community-sketchpads/*"):
                def _cb():
                    last_selected_sketchpad_path = Path(self.zyngui.screens['session_dashboard'].get_last_selected_sketchpad())

                    if load_snapshot:
                        # Load snapshot
                        snapshot_path = f"{str(last_selected_sketchpad_path.parent / 'soundsets')}/{last_selected_sketchpad_path.stem.replace('.sketchpad', '')}.zss"
                        if Path(snapshot_path).exists():
                            self.zyngui.currentTaskMessage = "Loading snapshot"
                            logging.info(f"Loading snapshot : {snapshot_path}")
                            self.zyngui.screens["layer"].load_snapshot(snapshot_path)
                        elif Path("/zynthian/zynthian-my-data/snapshots/default.zss").exists():
                            logging.info(f"Loading default snapshot")
                            self.zyngui.currentTaskMessage = "Loading snapshot"
                            self.zyngui.screens["layer"].load_snapshot("/zynthian/zynthian-my-data/snapshots/default.zss")

                    # Connect all jack ports of respective channel after jack client initialization is done.
                    for i in range(0, self.__song__.channelsModel.count):
                        channel = self.__song__.channelsModel.getChannel(i)
                        channel.update_jack_port()

                    if cb is not None:
                        cb()

                    self.zyngui.currentTaskMessage = "Finalizing"
                    self.longOperationDecrement()
                    QTimer.singleShot(3000, self.zyngui.end_long_task)

                self.zyngui.currentTaskMessage = "Creating new sketchpad from community sketchpad"
                self.newSketchpad(sketchpad, _cb)
            else:
                logging.info(f"Loading Sketchpad : {str(sketchpad_path.parent.absolute()) + '/'}, {str(sketchpad_path.stem)}")
                self.zyngui.currentTaskMessage = "Loading sketchpad"
                self.__song__ = sketchpad_song.sketchpad_song(str(sketchpad_path.parent.absolute()) + "/", str(sketchpad_path.stem.replace(".sketchpad", "")), self, load_history)
                self.zyngui.screens["session_dashboard"].set_last_selected_sketchpad(str(sketchpad_path))

                if load_snapshot:
                    snapshot_path = str(sketchpad_path.parent.absolute()) + '/soundsets/' + str(sketchpad_path.stem.replace('.sketchpad', '')) + '.zss'
                    # Load snapshot
                    if Path(snapshot_path).exists():
                        logging.info(f"Loading snapshot : {snapshot_path}")
                        self.zyngui.currentTaskMessage = "Loading snapshot"
                        self.zyngui.screens["layer"].load_snapshot(snapshot_path)
                    elif Path("/zynthian/zynthian-my-data/snapshots/default.zss").exists():
                        logging.info(f"Loading default snapshot")
                        self.zyngui.currentTaskMessage = "Loading snapshot"
                        self.zyngui.screens["layer"].load_snapshot("/zynthian/zynthian-my-data/snapshots/default.zss")

                self.__song__.bpm_changed.connect(self.update_timer_bpm)
                self.song_changed.emit()

                # Connect all jack ports of respective channel after jack client initialization is done.
                for i in range(0, self.__song__.channelsModel.count):
                    channel = self.__song__.channelsModel.getChannel(i)
                    channel.update_jack_port()

                if cb is not None:
                    cb()

                self.zyngui.currentTaskMessage = "Finalizing"
                self.longOperationDecrement()
                QTimer.singleShot(3000, self.zyngui.end_long_task)

        self.zyngui.currentTaskMessage = "Loading Sketchpad"
        self.longOperationIncrement()
        self.zyngui.do_long_task(task)

    @Slot(str)
    def loadSketchpadVersion(self, version):
        sketchpad_folder = self.__song__.sketchpad_folder

        try:
            self.__song__.bpm_changed.disconnect()
        except Exception as e:
            logging.error(f"Already disconnected : {str(e)}")

        self.stopAllPlayback()
        self.zyngui.screens["playgrid"].stopMetronomeRequest()
        self.zyngui.screens["song_arranger"].stop()
        self.resetMetronome()

        self.__song__ = sketchpad_song.sketchpad_song(sketchpad_folder, version, self)
        self.__song__.bpm_changed.connect(self.update_timer_bpm)
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
        # The click channel wants to not have any effects added at all, so use the magic channel -2, which is our uneffected global channel
        self.click_channel_click.stopOnChannel(-2)
        self.click_channel_clack.stopOnChannel(-2)

        for channel_index in range(self.__song__.channelsModel.count):
            self.__song__.channelsModel.getChannel(channel_index).stopAllClips()

    def update_timer_bpm(self):
        self.click_channel_click.set_length(4, self.__song__.bpm)
        self.click_channel_clack.set_length(1, self.__song__.bpm)

        libzl.setBpm(self.__song__.bpm)
        if self.metronome_running_refcount > 0:
            self.set_clickChannelEnabled(self.click_channel_enabled)

    def queue_clip_record(self, clip):
        # When sketchpad is open, curLayer is not updated when changing channels as it is a considerably heavy task
        # but not necessary to change to selected channel's synth.
        # Hence make sure to update curLayer before doing operations depending upon curLayer
        self.zyngui.screens["layers_for_channel"].do_activate_midich_layer()
        layers_snapshot = None

        if self.zyngui.curlayer is not None:
            layers_snapshot = self.zyngui.screens["layer"].export_multichannel_snapshot(self.zyngui.curlayer.midi_chan)

        channel = self.__song__.channelsModel.getChannel(self.zyngui.session_dashboard.selectedChannel)
        self.set_clip_to_record(clip)

        if clip.isChannelSample:
            Path(channel.bankDir).mkdir(parents=True, exist_ok=True)
        else:
            (Path(clip.recording_basepath) / 'wav').mkdir(parents=True, exist_ok=True)

        if self.recordingSource == 'internal':
            # If source is internal and there are no layers, show error and return.
            if layers_snapshot is None:
                self.zyngui.passiveNotification = "Cannot record channel with no synth"
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

        base_filename = f"{datetime.now().strftime('%Y%m%d-%H%M')}_{preset_name}_{self.__song__.bpm}-BPM"

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

            libzl.AudioLevels_setShouldRecordPorts(True)
            libzl.AudioLevels_setRecordPortsFilenamePrefix(self.clip_to_record_path)
            libzl.AudioLevels_clearRecordPorts()

            for ports in recording_ports:
                for port in zip(ports, (0, 1)):
                    logging.debug(f"Adding record port : {port}")
                    libzl.AudioLevels_addRecordPort(port[0], port[1])

            libzl.AudioLevels_startRecording()

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
        if libzl.AudioLevels_isRecording():
            libzl.AudioLevels_stopRecording()
            libzl.AudioLevels_clearRecordPorts()

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
                if self.click_channel_enabled:
                    # The click channel wants to not have any effects added at all, so play it on the magic channel -2, which is our uneffected global channel
                    self.click_channel_click.queueClipToStartOnChannel(-2)
                    self.click_channel_clack.queueClipToStartOnChannel(-2)

                libzl.startTimer(self.__song__.bpm)

                # Stop blink timer when metronome starts as blink will be handled by metronome update callback
                # to have more accurate representation of bpm
                self.zyngui.wsleds_blink_timer.stop()

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
            libzl.stopTimer()

            # Start blink timer when metronome stops to keep blinking in sync with bpm
            self.zyngui.wsleds_blink_timer.start()

            self.click_channel_click.stopOnChannel(-2)
            self.click_channel_clack.stopOnChannel(-2)
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
                layer = self.zyngui.screens["layer"].export_multichannel_snapshot(self.zyngui.curlayer.midi_chan)
                logging.debug(f"### Channel({self.zyngui.curlayer.midi_chan}), Layer({json.dumps(layer)})")
            except:
                layer = None

            self.clip_to_record.set_path(self.clip_to_record_path, False)
            if layer is not None:
                self.clip_to_record.write_metadata("ZYNTHBOX_ACTIVELAYER", [json.dumps(layer)])
            self.clip_to_record.write_metadata("ZYNTHBOX_BPM", [str(self.__song__.bpm)])
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
                    clip.write_metadata("ZYNTHBOX_BPM", [str(self.__song__.bpm)])
                    clip.write_metadata("ZYNTHBOX_AUDIO_TYPE", [self.__last_recording_type__])
                    clip.write_metadata("ZYNTHBOX_MIDI_RECORDING", [self.lastRecordingMidi])

            if self.clip_to_record.isChannelSample:
                logging.info(f"Recorded clip is a sample")
                channel = self.__song__.channelsModel.getChannel(self.zyngui.session_dashboard.selectedChannel)
                channel.samples_changed.emit()
        # self.__song__.save()

    def get_next_free_layer(self):
        logging.debug(self.zyngui.screens["layers"].layers)

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

    metronomeBeatUpdate4th = Signal(int)
    metronomeBeatUpdate8th = Signal(int)
    metronomeBeatUpdate16th = Signal(int)
    metronomeBeatUpdate32th = Signal(int)
    metronomeBeatUpdate64th = Signal(int)
    metronomeBeatUpdate128th = Signal(int)

    cannotRecordEmptyLayer = Signal()
    newSketchpadLoaded = Signal()
