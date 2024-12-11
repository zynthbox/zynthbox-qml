#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Main Class and Program for Zynthian GUI
#
# Copyright (C) 2015-2016 Fernando Moyano <jofemodo@zynthian.org>
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
import os
import re
import sys
import copy

import alsaaudio
import liblo
import queue
import signal
import math

# import psutil
# import alsaseq
import logging
import threading

import numpy as np
import rpi_ws281x
import time
from datetime import datetime
from threading import Thread, Lock, Event
from subprocess import Popen, check_output
from ctypes import c_float, c_double, CDLL
import xml.etree.ElementTree as ET

# Qt modules
from PySide2.QtCore import (
    QProcess, Qt,
    QObject,
    QMetaObject,
    SIGNAL, Slot,
    Signal,
    Property,
    QTimer,
    QEventLoop,
    QSettings
)
from PySide2.QtGui import QGuiApplication, QPalette, QColor, QIcon, QWindow, QCursor, QPixmap

# from PySide2.QtWidgets import QApplication
from PySide2.QtQml import QQmlApplicationEngine, QQmlDebuggingEnabler, qmlRegisterType
from soundfile import SoundFile

from pynput.keyboard import Key, Controller

from timeit import default_timer as timer
from datetime import timedelta

from zynqtgui.zynthian_gui_bluetooth_config import zynthian_gui_bluetooth_config
from zynqtgui.zynthian_gui_song_manager import zynthian_gui_song_manager
from zynqtgui.sound_categories.zynthian_gui_sound_categories import zynthian_gui_sound_categories
from zynqtgui.utils import file_properties_helper
from zynqtgui.utils.zynthbox_plugins_helper import zynthbox_plugins_helper
from zynqtgui.zynthian_gui_audio_settings import zynthian_gui_audio_settings
from zynqtgui.zynthian_gui_led_config import zynthian_gui_led_config
from zynqtgui.zynthian_gui_wifi_settings import zynthian_gui_wifi_settings
from zynqtgui.zynthian_gui_midicontroller_settings import zynthian_gui_midicontroller_settings
from zynqtgui.zynthian_gui_multi_controller import MultiController

sys.path.insert(1, "/zynthian/zynthbox-qml/")
sys.path.insert(1, "./zynqtgui")

# Zynthian specific modules
import zynconf
import zynautoconnect
from zyncoder import *
from zyncoder.zyncoder import lib_zyncoder_init
from zyngine import zynthian_controller, zynthian_zcmidi, zynthian_layer
from zyngine import zynthian_midi_filter

# from zyngine import zynthian_engine_transport
from zynqtgui import zynthian_gui_config, zynthian_gui_controller
from zynqtgui.zynthian_gui_selector import zynthian_gui_selector
from zynqtgui.zynthian_gui_info import zynthian_gui_info
from zynqtgui.zynthian_gui_about import zynthian_gui_about
from zynqtgui.zynthian_gui_option import zynthian_gui_option
from zynqtgui.zynthian_gui_admin import zynthian_gui_admin
from zynqtgui.zynthian_gui_snapshot import zynthian_gui_snapshot
from zynqtgui.zynthian_gui_layer import zynthian_gui_layer
from zynqtgui.zynthian_gui_fixed_layers import zynthian_gui_fixed_layers
from zynqtgui.zynthian_gui_effects_for_channel import zynthian_gui_effects_for_channel
from zynqtgui.zynthian_gui_layers_for_channel import zynthian_gui_layers_for_channel
from zynqtgui.zynthian_gui_layer_options import zynthian_gui_layer_options
from zynqtgui.zynthian_gui_layer_effects import zynthian_gui_layer_effects
from zynqtgui.zynthian_gui_layer_effects import zynthian_gui_layer_effects
from zynqtgui.zynthian_gui_effect_types import zynthian_gui_effect_types
from zynqtgui.zynthian_gui_layer_effect_chooser import (
    zynthian_gui_layer_effect_chooser,
)
from zynqtgui.zynthian_gui_engine import zynthian_gui_engine
from zynqtgui.zynthian_gui_midi_chan import zynthian_gui_midi_chan
from zynqtgui.zynthian_gui_midi_cc import zynthian_gui_midi_cc

from zynqtgui.zynthian_gui_midi_key_range import zynthian_gui_midi_key_range
from zynqtgui.zynthian_gui_audio_out import zynthian_gui_audio_out
# from zynqtgui.zynthian_gui_midi_out import zynthian_gui_midi_out
from zynqtgui.zynthian_gui_audio_in import zynthian_gui_audio_in
from zynqtgui.zynthian_gui_bank import zynthian_gui_bank
from zynqtgui.zynthian_gui_preset import zynthian_gui_preset
from zynqtgui.zynthian_gui_control import zynthian_gui_control
from zynqtgui.zynthian_gui_channel import zynthian_gui_channel
from zynqtgui.zynthian_gui_channel_external_setup import zynthian_gui_channel_external_setup
from zynqtgui.zynthian_gui_channel_wave_editor import zynthian_gui_channel_wave_editor

# from zynqtgui.zynthian_gui_control_xy import zynthian_gui_control_xy
# from zynqtgui.zynthian_gui_midi_profile import zynthian_gui_midi_profile
# from zynqtgui.zynthian_gui_zs3_learn import zynthian_gui_zs3_learn
# from zynqtgui.zynthian_gui_zs3_options import zynthian_gui_zs3_options
from zynqtgui.zynthian_gui_confirm import zynthian_gui_confirm

# from zynqtgui.zynthian_gui_keyboard import zynthian_gui_keyboard
from zynqtgui.zynthian_gui_keybinding import zynthian_gui_keybinding
from zynqtgui.zynthian_gui_main import zynthian_gui_main
from zynqtgui.zynthian_gui_audio_recorder import zynthian_gui_audio_recorder
from zynqtgui.zynthian_gui_test_touchpoints import (
    zynthian_gui_test_touchpoints,
)
from zynqtgui.zynthian_gui_playgrid import zynthian_gui_playgrid
from zynqtgui.sketchpad.zynthian_gui_sketchpad import (
    zynthian_gui_sketchpad,
)

# if "autoeq" in zynthian_gui_config.experimental_features:
# from zynqtgui.zynthian_gui_autoeq import zynthian_gui_autoeq
# from zynqtgui.zynthian_gui_touchscreen_calibration import zynthian_gui_touchscreen_calibration

# from zynqtgui.zynthian_gui_control_osc_browser import zynthian_gui_osc_browser

from zynqtgui.zynthian_gui_theme_chooser import zynthian_gui_theme_chooser
from zynqtgui.zynthian_gui_newstuff import zynthian_gui_newstuff
from zynqtgui.zynthian_gui_synth_behaviour import zynthian_gui_synth_behaviour
from zynqtgui.zynthian_gui_snapshots_menu import zynthian_gui_snapshots_menu
from zynqtgui.zynthian_gui_network import zynthian_gui_network
from zynqtgui.zynthian_gui_hardware import zynthian_gui_hardware
from zynqtgui.zynthian_gui_test_knobs import zynthian_gui_test_knobs
from zynqtgui.zynthian_osd import zynthian_osd

import Zynthbox

from pathlib import Path

import faulthandler
faulthandler.enable()

import Xlib.display, Xlib.Xatom, Xlib.X

# -------------------------------------------------------------------------------
# QObject to bridge status data to QML (ie audio levels, cpu levels etc
# -------------------------------------------------------------------------------
class zynthian_gui_status_data(QObject):
    def __init__(self, parent=None):
        super(zynthian_gui_status_data, self).__init__(parent)
        self.status_info = {}
        self.status_info["cpu_load"] = 0
        self.status_info["peakA"] = 0
        self.status_info["peakB"] = 0
        self.status_info["peakSignalA"] = 0
        self.status_info["peakSignalB"] = 0
        self.status_info["holdA"] = 0
        self.status_info["holdB"] = 0
        self.status_info["holdSignalA"] = 0
        self.status_info["holdSignalB"] = 0
        self.status_info["xrun"] = False
        self.status_info["undervoltage"] = False
        self.status_info["overtemp"] = False
        self.status_info["audio_recorder"] = False

        self.dpm_rangedB = 30  # Lowest meter reading in -dBFS
        self.dpm_highdB = 10  # Start of yellow zone in -dBFS
        self.dpm_overdB = 3  # Start of red zone in -dBFS
        self.dpm_high = 1 - self.dpm_highdB / self.dpm_rangedB
        self.dpm_over = 1 - self.dpm_overdB / self.dpm_rangedB

    def set_status(self, status):
        audio_recorder_has_changed = False
        if "audio_recorder" in status and "audio_recorder" in self.status_info and self.status_info["audio_recorder"] is not status["audio_recorder"]:
            audio_recorder_has_changed = True
        elif "audio_recorder" in status and "audio_recorder" not in self.status_info:
            audio_recorder_has_changed = True
        elif "audio_recorder" not in status and "audio_recorder" in self.status_info:
            audio_recorder_has_changed = True
        undervoltage_has_changed = False
        if "undervoltage" in status and "undervoltage" in self.status_info and self.status_info["undervoltage"] is not status["undervoltage"]:
            undervoltage_has_changed = True
        xrun_has_changed = False
        if "xrun" in status and "xrun" in self.status_info and self.status_info["xrun"] is not status["xrun"]:
            xrun_has_changed = True
        overtemp_has_changed = False
        if "overtemp" in status and "overtemp" in self.status_info and self.status_info["overtemp"] is not status["overtemp"]:
            overtemp_has_changed = True

        self.status_info = status
        # Update a couple of extra bits we need
        #self.status_info["peakSignalA"] = min(max(0, 1 + status["peakA"] / self.dpm_rangedB), 1)
        #self.status_info["peakSignalB"] = min(max(0, 1 + status["peakB"] / self.dpm_rangedB), 1)
        #self.status_info["holdSignalA"] = min(max(0, 1 + status["holdA"] / self.dpm_rangedB), 1)
        #self.status_info["holdSignalB"] = min(max(0, 1 + status["holdB"] / self.dpm_rangedB), 1)

        self.status_changed.emit()
        if audio_recorder_has_changed is True:
            self.audio_recorder_changed.emit()
        if undervoltage_has_changed is True:
            self.undervoltage_changed.emit()
        if xrun_has_changed is True:
            self.xrun_changed.emit()
        if overtemp_has_changed is True:
            self.overtemp_changed.emit()

    def get_cpu_load(self):
        return self.status_info["cpu_load"]

    def get_peakA(self):
        return self.status_info["peakA"]

    def get_peakB(self):
        return self.status_info["peakB"]

    def get_peakSignalA(self):
        return self.status_info["peakSignalA"]

    def get_peakSignalB(self):
        return self.status_info["peakSignalB"]

    def get_holdA(self):
        return self.status_info["holdA"]

    def get_holdB(self):
        return self.status_info["holdB"]

    def get_holdSignalA(self):
        return self.status_info["holdSignalA"]

    def get_holdSignalB(self):
        return self.status_info["holdSignalB"]

    xrun_changed = Signal()
    def get_xrun(self):
        return self.status_info["xrun"]

    undervoltage_changed = Signal()
    def get_undervoltage(self):
        if "undervoltage" in self.status_info:
            return self.status_info["undervoltage"]
        else:
            return False

    overtemp_changed = Signal()
    def get_overtemp(self):
        if "overtemp" in self.status_info:
            return self.status_info["overtemp"]
        else:
            return False

    audio_recorder_changed = Signal()
    def get_audio_recorder(self):
        if "audio_recorder" in self.status_info:
            return self.status_info["audio_recorder"]
        else:
            return None

    def get_rangedB(self):
        return self.dpm_rangedB

    def get_highdB(self):
        return self.dpm_highdB

    def get_overdB(self):
        return self.dpm_overdB

    def get_high(self):
        return self.dpm_high

    def get_over(self):
        return self.dpm_over

    status_changed = Signal()

    cpu_load = Property(float, get_cpu_load, notify=status_changed)
    peakA = Property(float, get_peakA, notify=status_changed)
    peakB = Property(float, get_peakB, notify=status_changed)
    peakSignalA = Property(float, get_peakSignalA, notify=status_changed)
    peakSignalB = Property(float, get_peakSignalB, notify=status_changed)
    holdA = Property(float, get_holdA, notify=status_changed)
    holdB = Property(float, get_holdB, notify=status_changed)
    holdSignalA = Property(float, get_holdSignalA, notify=status_changed)
    holdSignalB = Property(float, get_holdSignalB, notify=status_changed)
    xrun = Property(bool, get_xrun, notify=xrun_changed)
    undervoltage = Property(bool, get_undervoltage, notify=undervoltage_changed)
    overtemp = Property(bool, get_overtemp, notify=overtemp_changed)
    audio_recorder = Property(str, get_audio_recorder, notify=audio_recorder_changed)

    rangedB = Property(float, get_rangedB, constant=True)
    highdB = Property(float, get_highdB, constant=True)
    overdB = Property(float, get_overdB, constant=True)
    high = Property(float, get_high, constant=True)
    over = Property(float, get_over, constant=True)


# -------------------------------------------------------------------------------
# Zynthian Main GUI Class
# -------------------------------------------------------------------------------

recent_task_messages = queue.SimpleQueue()
class zynthian_gui(QObject):

    screens_sequence = (
        "sketchpad",
        "layers_for_channel",
        "bank",
        "preset",
        "control",
        "layer_effects",
        "layer_midi_effects",
    )
    non_modal_screens = (
        "sketchpad",
        "main",
        "layer",
        "fixed_layers",
        "effects_for_channel",
        "layers_for_channel",
        "main_layers_view",
        "bank",
        "preset",
        "control",
        "layer_effects",
        "effect_types",
        "layer_effect_chooser",
        "layer_midi_effects",
        "midi_effect_types",
        "layer_midi_effect_chooser",
    )

    note2cuia = {
        "0": "POWER_OFF",
        "1": "REBOOT",
        "2": "RESTART_UI",
        "3": "RELOAD_MIDI_CONFIG",
        "4": "RELOAD_KEY_BINDING",
        "5": "LAST_STATE_ACTION",
        "10": "ALL_NOTES_OFF",
        "11": "ALL_SOUNDS_OFF",
        "12": "ALL_OFF",
        "23": "TOGGLE_AUDIO_RECORD",
        "24": "START_AUDIO_RECORD",
        "25": "STOP_AUDIO_RECORD",
        "26": "TOGGLE_AUDIO_PLAY",
        "27": "START_AUDIO_PLAY",
        "28": "STOP_AUDIO_PLAY",
        "35": "TOGGLE_MIDI_RECORD",
        "36": "START_MIDI_RECORD",
        "37": "STOP_MIDI_RECORD",
        "38": "TOGGLE_MIDI_PLAY",
        "39": "START_MIDI_PLAY",
        "40": "STOP_MIDI_PLAY",
        "51": "SELECT_ITEM",
        "52": "SELECT_UP",
        "53": "SELECT_DOWN",
        "56": "LAYER_UP",
        "57": "LAYER_DOWN",
        "58": "SNAPSHOT_UP",
        "59": "SNAPSHOT_DOWN",
        "64": "SWITCH_BACK_SHORT",
        "63": "SWITCH_BACK_BOLD",
        # "62": "SWITCH_BACK_LONG",
        "65": "SWITCH_SELECT_SHORT",
        "66": "SWITCH_SELECT_BOLD",
        # "67": "SWITCH_SELECT_LONG",
        "60": "SWITCH_LAYER_SHORT",
        "61": "SWITCH_LAYER_BOLD",
        # "68": "SWITCH_LAYER_LONG",
        "71": "SWITCH_SNAPSHOT_SHORT",
        "72": "SWITCH_SNAPSHOT_BOLD",
        # "73": "SWITCH_SNAPSHOT_LONG",
        "80": "SCREEN_ADMIN",
        "81": "SCREEN_LAYER",
        "82": "SCREEN_BANK",
        "83": "SCREEN_PRESET",
        "84": "SCREEN_CONTROL",
        "90": "MODAL_SNAPSHOT_LOAD",
        "91": "MODAL_SNAPSHOT_SAVE",
        "92": "MODAL_AUDIO_RECORDER",
        "93": "MODAL_MIDI_RECORDER",
        "94": "MODAL_ALSA_MIXER",
        "95": "SCREEN_PLAYGRID",
        "96": "NAVIGATE_RIGHT",
        "101": "LAYER_1",
        "102": "LAYER_2",
        "103": "LAYER_3",
        "104": "LAYER_4",
        "105": "LAYER_5",
        "106": "LAYER_6",
        "107": "INCREASE",
        "108": "DECREASE",
        "109": "TOGGLE_KEYBOARD",
    }

    def __init__(self, parent=None):
        super(zynthian_gui, self).__init__(parent)

        self.exit_flag = False
        self.bootsplash_thread = Thread(target=self.bootsplash_worker, args=())
        self.bootsplash_thread.daemon = True # thread will exit with the program
        self.bootsplash_thread.start()

        self.bpmBeforePressingMetronome = 0
        self.volumeBeforePressingMetronome = 0
        self.metronomeVolumeBeforePressingMetronome = 0
        self.delayBeforePressingMetronome = 0
        self.reverbBeforePressingMetronome = 0
        self.__ignoreNextMenuButtonPress = False
        self.__ignoreNextModeButtonPress = False
        self.__ignoreNextRecordButtonPress = False
        self.__ignoreNextMetronomeButtonPress = False
        self.__ignoreNextPlayButtonPress = False
        self.__ignoreNextStopButtonPress = False
        self.__ignoreNextGlobalButtonPress = False
        self.__ignoreNextSelectButtonPress = False
        self.__ignoreNextBackButtonPress = False
        self.__current_task_message = ""
        self.__show_current_task_message = True
        self.currentTaskMessage = f"Starting Zynthbox"
        self.__master_volume = self.get_initialMasterVolume()

        self.zynmidi = None
        self.screens = {}
        self.__home_screen = "sketchpad" #TODO: make this configurable, put same in static screens_sequence
        self.active_screen = None
        self.modal_screen = None
        self.modal_screen_back = None
        self.screen_back = None
        self.__forced_screen_back = None
        self.__knob_touch_update_in_progress__ = False

        # global_fx_engines is a list of a set of 2 elements.
        # 1st element of the set is the engine instance
        # 2nd element of the set is the zynthian controller to control fx
        self.global_fx_engines = []

        self.__channelToRecord = None
        self.__channelRecordingRow = None
        self.__clipToRecord = None
        self.__forceSongMode__ = False
        self.__menu_button_pressed__ = False
        self.__switch_channels_button_pressed__ = False
        self.__mode_button_pressed__ = False
        self.__alt_button_pressed__ = False
        self.__global_button_pressed__ = False
        self.__startRecord_button_pressed__ = False
        self.__play_button_pressed__ = False
        self.__metronome_button_pressed__ = False
        self.__stop_button_pressed__ = False
        self.__back_button_pressed__ = False
        self.__up_button_pressed__ = False
        self.__select_button_pressed__ = False
        self.__left_button_pressed__ = False
        self.__down_button_pressed__ = False
        self.__right_button_pressed__ = False
        self.__knob0touched__ = False
        self.__knob1touched__ = False
        self.__knob2touched__ = False
        self.__knob3touched__ = False
        self.knob0touched_changed.connect(self.anyKnobTouched_changed, Qt.QueuedConnection)
        self.knob1touched_changed.connect(self.anyKnobTouched_changed, Qt.QueuedConnection)
        self.knob2touched_changed.connect(self.anyKnobTouched_changed, Qt.QueuedConnection)
        self.knob3touched_changed.connect(self.anyKnobTouched_changed, Qt.QueuedConnection)
        self.__global_popup_opened__ = False
        self.__passive_notification = ""
        self.__splash_stopped = False
        self.__start_playback_on_metronome_release = False

        self.__show_mini_play_grid__ = False
        self.miniPlayGridToggle.connect(self.toggleMiniPlayGrid)

        # When true, 1-5 buttons selects channel 6-10
        self.tracks_mod_active = False

        self.song_bar_active = False
        self.slots_bar_clips_active = False
        self.sound_combinator_active = False
        self.channel_wave_editor_bar_active = False
        self.channel_samples_bar_active = False
        self.clip_wave_editor_bar_active = False
        self.slots_bar_channel_active = False
        self.slots_bar_mixer_active = False
        self.slots_bar_synths_active = False
        self.slots_bar_samples_active = False
        self.slots_bar_fx_active = False
        self.recording_popup_active = False
        self.left_sidebar_active = False

        self.opened_dialog = None
        self.dialogStack = []
        self.left_sidebar = None

        self.__bottombar_control_obj = None
        self.__bottombar_control_type = "bottombar-controltype-none"

        # This makes zynswitch_short execute in the main thread, zynswitch_short_triggered will be emitted from a different thread
        self.zynswitch_short_triggered.connect(self.zynswitch_short, Qt.QueuedConnection)
        self.zynswitch_long_triggered.connect(self.zynswitch_long, Qt.QueuedConnection)
        self.zynswitch_bold_triggered.connect(self.zynswitch_bold, Qt.QueuedConnection)
        self.fakeKeyboard = Controller()

        self.modal_timer = QTimer(self)
        self.modal_timer.setInterval(3000)
        self.modal_timer.setSingleShot(False)
        self.modal_timer.timeout.connect(self.close_modal)
        self.__booting_complete__ = False
        self.__shutting_down = False
        self.rainbow_led_counter = 0

        # If * button is pressed, it toggles itself on/off for 5000ms before returning to previous state.
        # Use this timer to toggle state after 5000ms
        self.tracksModTimer = QTimer(self)
        self.tracksModTimer.setInterval(3000)
        self.tracksModTimer.setSingleShot(True)
        self.tracksModTimer.timeout.connect(self.tracksModTimerHandler)

        self.info_timer = QTimer(self)
        self.info_timer.setInterval(3000)
        self.info_timer.setSingleShot(False)
        self.info_timer.timeout.connect(self.hide_info)
        # HACK: in order to start the timer from the proper thread
        self.current_modal_screen_id_changed.connect(self.info_timer.start, Qt.QueuedConnection)
        self.current_qml_page_prop = None

        self.curlayer = None
        self._curlayer = None

        self.dtsw = []
        self.polling = False
        self.polling_timer = QTimer(self)
        self.polling_timer.setInterval(200)
        self.polling_timer.setSingleShot(False)
        self.polling_timer.timeout.connect(self.polling_timer_expired)

        self.loading = 0
        self.loading_thread = None
        self.zyncoder_thread = None
        self.zynread_wait_flag = False
        self.zynswitch_defered_event = None
        self.exit_flag = False
        self.exit_code = 0

        self.cpu_status_info_undervoltage = Event()
        self.cpu_status_info_overtemp = Event()
        self.cpu_status_thread = Thread(target=self.cpu_status_refresh, args=(self.cpu_status_info_undervoltage, self.cpu_status_info_overtemp))
        self.cpu_status_thread.daemon = True # thread will exit with the program
        self.cpu_status_thread.start()

        self.midi_filter_script = None
        self.midi_learn_mode = False
        self.midi_learn_zctrl = None
        self.__notes_on = []

        self.status_info = {}
        self.status_object = zynthian_gui_status_data(self)
        self.status_counter = 0

        self.__long_task_count__ = 0

        self.zynautoconnect_audio_flag = False
        self.zynautoconnect_midi_flag = False

        # Global zselectors
        self.__zselectors = [None, None, None, None]
        self.__zselector_controllers = [None, None, None, None]
        self.__knob_delta_factors = [500, 500, 500, 1]
        self.__knob_values_max = [20000, 20000, 20000, 20000]
        self.__knob_values_default = [10000, 10000, 10000, 10000]
        self.__knob_values = [10000, 10000, 10000, 10000]

        # Create Global FX Settings
        self.global_settings = QSettings()
        self.global_settings.beginGroup("GlobalFX")
        if self.global_settings.value("delay_engine_name", None) is None:
            self.global_settings.setValue("delay_engine_name", "JV/Gxdigital_delay_st")
        if self.global_settings.value("delay_level_controller_name", None) is None:
            self.global_settings.setValue("delay_level_controller_name", "LEVEL")
        if self.global_settings.value("reverb_engine_name", None) is None:
            self.global_settings.setValue("reverb_engine_name", "JV/TAP Reverberator")
        if self.global_settings.value("reverb_level_controller_name", None) is None:
            self.global_settings.setValue("reverb_level_controller_name", "wetlevel")
        self.global_settings.endGroup()

        self.knobDeltaChanged.connect(self.knobDeltaCuiaEmitter, Qt.QueuedConnection)

        # This variable will decide if zyncoder_read should be called or not depending on whether
        # global set_selector is in progress or not
        self.is_global_set_selector_running = False

        # Create Lock object to avoid concurrence problems
        self.lock = Lock()
        self.osc_server = None

        # Load keyboard binding map
        zynthian_gui_keybinding.getInstance(self).load()

        # Get Jackd Options
        self.jackd_options = zynconf.get_jackd_options()

        ### SCREEN SHOW QUEUE
        '''
        This list will be used as a queue to call `show` method of the screen objects in the list
        '''
        self.show_screens_queue = []

        '''
        self.show_screens_queue_timer will process once screen at a time from self.show_screens_queue and call the respective show method
        If there are more screens left in the queue, the timer will restart itself otherwise not
        This will make sure to not call show methods of the screens together and hence blocking event processing (causes stutter in UI)
        '''
        self.show_screens_queue_timer = QTimer()
        self.show_screens_queue_timer.setSingleShot(True)
        self.show_screens_queue_timer.setInterval(10)
        self.show_screens_queue_timer.timeout.connect(self.show_screens_queue_timer_timeout, Qt.QueuedConnection)
        ### END SCREEN SHOW QUEUE

        self.__fake_keys_pressed = set()
        self.__old_bk_value = 0 # FIXME: hack
        self.__bk_fake_key = None
        self.__bk_last_turn_time = None

        # Initialize Controllers (Rotary & Switches) & MIDI-router
        try:
            global lib_zyncoder
            # Init Zyncoder Library
            lib_zyncoder_init()
            lib_zyncoder = zyncoder.get_lib_zyncoder()
            self.zynmidi = zynthian_zcmidi()
            # Init Switches
            self.zynswitches_init()
            self.zynswitches_midi_setup()
        except Exception as e:
            logging.error(
                "ERROR initializing Controllers & MIDI-router: %s" % e
            )

        # Initialise Zynthbox plugin (which requires things found in zyncoder, specifically the zynthian midi router)
        Zynthbox.Plugin.instance().initialize()
        # Hook up message passing
        Zynthbox.MidiRouter.instance().midiMessage.connect(self.handleMidiMessage)
        Zynthbox.MidiRouter.instance().cuiaEvent.connect(self.handleMidiRouterCuiaEvent)
        self.current_screen_id_changed.connect(self.handleCurrentScreenIDChanged)

    @Slot(int, int, int, int, int, int, bool)
    def handleMidiMessage(self, port, size, byte1, byte2, byte3, sketchpadTrack, fromInternal):
        # logging.error(f"Port {port} event size {size} on track {sketchpadTrack} from internal: {fromInternal} - {byte1} {byte2} {byte3}")
        if port == Zynthbox.MidiRouter.ListenerPort.HardwareInPassthroughPort:
            if 0xAF < byte1 and byte1 < 0xC0:
                chan = (byte1 & 0xf)
                # If MIDI learn pending ...
                if self.midi_learn_zctrl:
                    self.midi_learn_zctrl.cb_midi_learn(chan, byte2)
                # Try layer's zctrls
                else:
                    self.screens["layer"].midi_control_change(chan, byte2, byte3)
                    # TODO Our hook for external track midi routing would be here (set up on sketchpad.channel, send through sketchpad, which routes to current song, and then to all channels, who can handle the logic of what to do)
                    # Also where we can hook in the k0 through k3 knobs and clickiness and such for learning...

    @Slot()
    def handleCurrentScreenIDChanged(self):
        theScreenID = self.current_screen_id
        if theScreenID == "layer":
            Zynthbox.MidiRouter.instance().cuiaEventFeedback("SCREEN_LAYER", -1, Zynthbox.ZynthboxBasics.Track.AnyTrack, Zynthbox.ZynthboxBasics.Slot.AnySlot, 0)
        elif theScreenID == "layer_effects":
            Zynthbox.MidiRouter.instance().cuiaEventFeedback("SCREEN_LAYER_FX", -1, Zynthbox.ZynthboxBasics.Track.AnyTrack, Zynthbox.ZynthboxBasics.Slot.AnySlot, 0)
        elif theScreenID == "main":
            Zynthbox.MidiRouter.instance().cuiaEventFeedback("SCREEN_MAIN_MENU", -1, Zynthbox.ZynthboxBasics.Track.AnyTrack, Zynthbox.ZynthboxBasics.Slot.AnySlot, 0)
        # elif theScreenID == "":
            # Zynthbox.MidiRouter.instance().cuiaEventFeedback("SCREEN_EDIT_CONTEXTUAL", -1, Zynthbox.ZynthboxBasics.Track.AnyTrack, Zynthbox.ZynthboxBasics.Slot.AnySlot, 0)
        elif theScreenID == "admin":
            Zynthbox.MidiRouter.instance().cuiaEventFeedback("SCREEN_ADMIN", -1, Zynthbox.ZynthboxBasics.Track.AnyTrack, Zynthbox.ZynthboxBasics.Slot.AnySlot, 0)
        elif theScreenID == "bank":
            Zynthbox.MidiRouter.instance().cuiaEventFeedback("SCREEN_BANK", -1, Zynthbox.ZynthboxBasics.Track.AnyTrack, Zynthbox.ZynthboxBasics.Slot.AnySlot, 0)
        elif theScreenID == "preset":
            Zynthbox.MidiRouter.instance().cuiaEventFeedback("SCREEN_PRESET", -1, Zynthbox.ZynthboxBasics.Track.AnyTrack, Zynthbox.ZynthboxBasics.Slot.AnySlot, 0)
        elif theScreenID == "control":
            Zynthbox.MidiRouter.instance().cuiaEventFeedback("SCREEN_CONTROL", -1, Zynthbox.ZynthboxBasics.Track.AnyTrack, Zynthbox.ZynthboxBasics.Slot.AnySlot, 0)
        elif theScreenID == "sketchpad":
            Zynthbox.MidiRouter.instance().cuiaEventFeedback("SCREEN_SKETCHPAD", -1, Zynthbox.ZynthboxBasics.Track.AnyTrack, Zynthbox.ZynthboxBasics.Slot.AnySlot, 0)
        elif theScreenID == "song_manager":
            Zynthbox.MidiRouter.instance().cuiaEventFeedback("SCREEN_SONG_MANAGER", -1, Zynthbox.ZynthboxBasics.Track.AnyTrack, Zynthbox.ZynthboxBasics.Slot.AnySlot, 0)
        elif theScreenID == "playgrid":
            Zynthbox.MidiRouter.instance().cuiaEventFeedback("SCREEN_PLAYGRID", -1, Zynthbox.ZynthboxBasics.Track.AnyTrack, Zynthbox.ZynthboxBasics.Slot.AnySlot, 0)
        elif theScreenID == "alsa_mixer":
            Zynthbox.MidiRouter.instance().cuiaEventFeedback("SCREEN_ALSA_MIXER", -1, Zynthbox.ZynthboxBasics.Track.AnyTrack, Zynthbox.ZynthboxBasics.Slot.AnySlot, 0)

    @Slot()
    def tracksModTimerHandler(self):
        # If * button is pressed, it toggles itself on/off for 5000ms before returning
        # to state where it shows current channel.

        # Set tracksModActive to true when channel 5-10 is active
        self.tracksModActive = self.sketchpad.selectedTrackId >= 5

    ### SHOW SCREEN QUEUE
    '''
    Add a screen to queue for processing and start timer
    Always enqueue show screen with this method to make sure timer is started when a screen is queued
    '''
    def add_screen_to_show_queue(self, screen, select_first_action=False, fill_list=False, show_screen=True, set_select_path=False):
        screen_to_show = (screen, select_first_action, fill_list, show_screen, set_select_path)

        if screen_to_show not in self.show_screens_queue:
            logging.debug(f"Screen {screen} not in list. Appending")
            self.show_screens_queue.append(screen_to_show)
        else:
            logging.debug(f"Screen {screen} already added to list. Not appending")

        self.show_screens_queue_timer.start()

    def clear_show_screen_queue(self):
        self.show_screens_queue_timer.stop()
        self.show_screens_queue.clear()

    '''
    Show screen queue timer timeout when invoked will process the screens from the queue and will call processEvents
    after showing every screen to process any queued qt events. This will cause the UI to keep updating and not cause
     any visible stutter in UI.      
    '''
    def show_screens_queue_timer_timeout(self):
        # Try calling show method of the screen and select first action if told to do so
        try:
            for screen, select_first_action, fill_list, show_screen, set_select_path in self.show_screens_queue:
                if fill_list:
                    screen.fill_list()
                    QGuiApplication.instance().processEvents()

                if show_screen:
                    logging.debug(f"Showing screen : {screen}")
                    screen.show()
                    QGuiApplication.instance().processEvents()

                if set_select_path:
                    logging.debug(f"Setting select path for screen : {screen}")
                    screen.set_select_path()
                    QGuiApplication.instance().processEvents()

                if select_first_action:
                    logging.debug(f"Selection first action for screen : {screen}")
                    screen.select_action(0)
                    QGuiApplication.instance().processEvents()
        except Exception as e: logging.exception(f"Error processing screen : {e}")
    ### END SHOW SCREEN QUEUE

    ### Global controller and selector
    @Slot(int, int)
    def knobDeltaCuiaEmitter(self, knob_index, delta):
        """
        Emit CUIA Actions when knob delta changes
        """
        for _ in range(abs(delta)):
            if delta > 0:
                self.callable_ui_action(f"KNOB{knob_index}_UP")
            else:
                self.callable_ui_action(f"KNOB{knob_index}_DOWN")

    @Slot(None)
    def set_selector(self):
        if not self.isBootingComplete:
            return

        for knob_index in [0, 1, 2, 3]:
            try:
                if self.__zselectors[knob_index] is None:
                    self.__zselector_controllers[knob_index] = zynthian_controller(None, f'delta_knob{knob_index}', f'delta_knob{knob_index}', {'name': f'Knob{knob_index} Delta', 'short_name': f'Knob{knob_index} Delta', 'midi_cc': 0, 'value_max': self.__knob_values_max[knob_index], 'value_min': 0, 'value': self.__knob_values_default[knob_index]})
                    self.__zselectors[knob_index] = zynthian_gui_controller(knob_index, self.__zselector_controllers[knob_index], self)
                    self.__zselectors[knob_index].config(self.__zselector_controllers[knob_index])
                    self.__zselectors[knob_index].set_value(self.__knob_values_default[knob_index], True)
                    self.__zselectors[knob_index].step = 1
                    self.__zselectors[knob_index].mult = 1

                self.__zselectors[knob_index].show()
                self.__zselector_controllers[knob_index].set_options({"value": self.__knob_values_default[knob_index]})
                self.__zselectors[knob_index].config(self.__zselector_controllers[knob_index])
            except:
                if self.__zselectors[knob_index] is not None:
                    self.__zselectors[knob_index].hide()

    knobDeltaChanged = Signal(int, int, arguments=["knobIndex", "delta"])
    ### END Global controller and selector

    # ---------------------------------------------------------------------------
    # WS281X LEDs
    # ---------------------------------------------------------------------------

    # LED management properties

    def get_song_bar_active(self):
        return self.song_bar_active

    def set_song_bar_active(self, isActive):
        if self.song_bar_active != isActive:
            self.song_bar_active = isActive
            self.songBarActiveChanged.emit()

    songBarActiveChanged = Signal()

    songBarActive = Property(bool, get_song_bar_active, set_song_bar_active, notify=songBarActiveChanged)

    def get_sound_combinator_active(self):
        return self.sound_combinator_active

    def set_sound_combinator_active(self, isActive):
        if self.sound_combinator_active != isActive:
            self.sound_combinator_active = isActive
            self.soundCombinatorActiveChanged.emit()

    soundCombinatorActiveChanged = Signal()

    soundCombinatorActive = Property(bool, get_sound_combinator_active, set_sound_combinator_active,
                                     notify=soundCombinatorActiveChanged)

    def get_channel_wave_editor_bar_active(self):
        return self.channel_wave_editor_bar_active

    def set_channel_wave_editor_bar_active(self, isActive):
        if self.channel_wave_editor_bar_active != isActive:
            self.channel_wave_editor_bar_active = isActive
            self.channelWaveEditorBarActiveChanged.emit()

    channelWaveEditorBarActiveChanged = Signal()

    channelWaveEditorBarActive = Property(bool, get_channel_wave_editor_bar_active, set_channel_wave_editor_bar_active,
                                     notify=channelWaveEditorBarActiveChanged)

    def get_channel_samples_bar_active(self):
        return self.channel_samples_bar_active

    def set_channel_samples_bar_active(self, isActive):
        if self.channel_samples_bar_active != isActive:
            self.channel_samples_bar_active = isActive
            self.channelSamplesBarActiveChanged.emit()

    channelSamplesBarActiveChanged = Signal()

    channelSamplesBarActive = Property(bool, get_channel_samples_bar_active, set_channel_samples_bar_active,
                                     notify=channelSamplesBarActiveChanged)

    def get_clip_wave_editor_bar_active(self):
        return self.clip_wave_editor_bar_active

    def set_clip_wave_editor_bar_active(self, isActive):
        if self.clip_wave_editor_bar_active != isActive:
            self.clip_wave_editor_bar_active = isActive
            self.clipWaveEditorBarActiveChanged.emit()

    clipWaveEditorBarActiveChanged = Signal()

    clipWaveEditorBarActive = Property(bool, get_clip_wave_editor_bar_active, set_clip_wave_editor_bar_active,
                                       notify=clipWaveEditorBarActiveChanged)

    def get_slots_bar_channel_active(self):
        return self.slots_bar_channel_active

    def set_slots_bar_channel_active(self, isActive):
        if self.slots_bar_channel_active != isActive:
            self.slots_bar_channel_active = isActive
            self.slotsBarChannelActiveChanged.emit()

    slotsBarChannelActiveChanged = Signal()

    slotsBarChannelActive = Property(bool, get_slots_bar_channel_active, set_slots_bar_channel_active,
                                   notify=slotsBarChannelActiveChanged)

    def get_slots_bar_mixer_active(self):
        return self.slots_bar_mixer_active

    def set_slots_bar_mixer_active(self, isActive):
        if self.slots_bar_mixer_active != isActive:
            self.slots_bar_mixer_active = isActive
            self.slotsBarMixerActiveChanged.emit()

    slotsBarMixerActiveChanged = Signal()

    slotsBarMixerActive = Property(bool, get_slots_bar_mixer_active, set_slots_bar_mixer_active,
                                   notify=slotsBarMixerActiveChanged)

    def get_slots_bar_clips_active(self):
        return self.slots_bar_clips_active

    def set_slots_bar_clips_active(self, isActive):
        if self.slots_bar_clips_active != isActive:
            self.slots_bar_clips_active = isActive
            self.slotsBarClipsActiveChanged.emit()

    slotsBarClipsActiveChanged = Signal()

    slotsBarClipsActive = Property(bool, get_slots_bar_clips_active, set_slots_bar_clips_active, notify=slotsBarClipsActiveChanged)

    def get_slots_bar_synths_active(self):
        return self.slots_bar_synths_active

    def set_slots_bar_synths_active(self, isActive):
        if self.slots_bar_synths_active != isActive:
            self.slots_bar_synths_active = isActive
            self.slotsBarSynthsActiveChanged.emit()

    slotsBarSynthsActiveChanged = Signal()

    slotsBarSynthsActive = Property(bool, get_slots_bar_synths_active, set_slots_bar_synths_active,
                                    notify=slotsBarSynthsActiveChanged)

    def get_slots_bar_samples_active(self):
        return self.slots_bar_samples_active

    def set_slots_bar_samples_active(self, isActive):
        if self.slots_bar_samples_active != isActive:
            self.slots_bar_samples_active = isActive
            self.slotsBarSamplesActiveChanged.emit()

    slotsBarSamplesActiveChanged = Signal()

    slotsBarSamplesActive = Property(bool, get_slots_bar_samples_active, set_slots_bar_samples_active,
                                     notify=slotsBarSamplesActiveChanged)

    def get_slots_bar_fx_active(self):
        return self.slots_bar_fx_active

    def set_slots_bar_fx_active(self, isActive):
        if self.slots_bar_fx_active != isActive:
            self.slots_bar_fx_active = isActive
            self.slotsBarFxActiveChanged.emit()

    slotsBarFxActiveChanged = Signal()

    slotsBarFxActive = Property(bool, get_slots_bar_fx_active, set_slots_bar_fx_active,
                                notify=slotsBarFxActiveChanged)
    ###

    def get_recording_popup_active(self):
        return self.recording_popup_active

    def set_recording_popup_active(self, isActive):
        if self.recording_popup_active != isActive:
            self.recording_popup_active = isActive
            self.recordingPopupActiveChanged.emit()

    recordingPopupActiveChanged = Signal()

    recordingPopupActive = Property(bool, get_recording_popup_active, set_recording_popup_active, notify=recordingPopupActiveChanged)

    def get_left_sidebar_active(self):
        return self.left_sidebar_active

    def set_left_sidebar_active(self, isActive):
        if self.left_sidebar_active != isActive:
            self.left_sidebar_active = isActive

            if isActive:
                # If leftSidebar is opened and stop tracksModTimer and call timer handler immediately
                QMetaObject.invokeMethod(self.tracksModTimer, "stop", Qt.QueuedConnection)
                QMetaObject.invokeMethod(self, "tracksModTimerHandler", Qt.QueuedConnection)

            self.leftSidebarActiveChanged.emit()

    leftSidebarActiveChanged = Signal()

    leftSidebarActive = Property(bool, get_left_sidebar_active, set_left_sidebar_active, notify=leftSidebarActiveChanged)

    # ---------------------------------------------------------------------------
    # MIDI Router Init & Config
    # ---------------------------------------------------------------------------

    def init_midi(self):
        try:
            global lib_zyncoder
            # Set Global Tuning
            self.fine_tuning_freq = zynthian_gui_config.midi_fine_tuning
            lib_zyncoder.set_midi_filter_tuning_freq(
                c_double(self.fine_tuning_freq)
            )
            # Set MIDI Master Channel
            lib_zyncoder.set_midi_master_chan(
                zynthian_gui_config.master_midi_channel
            )
            # Set MIDI CC automode
            lib_zyncoder.set_midi_ctrl_automode(
                zynthian_gui_config.midi_cc_automode
            )
            # Setup MIDI filter rules
            if self.midi_filter_script:
                self.midi_filter_script.clean()
            self.midi_filter_script = zynthian_midi_filter.MidiFilterScript(
                zynthian_gui_config.midi_filter_rules
            )

        except Exception as e:
            logging.error("ERROR initializing MIDI : %s" % e)

    def init_midi_services(self):
        # Start/Stop MIDI aux. services
        self.screens["admin"].default_rtpmidi()
        self.screens["admin"].default_qmidinet()
        self.screens["admin"].default_touchosc()
        self.screens["admin"].default_aubionotes()

    def reload_midi_config(self):
        zynconf.load_config()
        midi_profile_fpath = zynconf.get_midi_config_fpath()
        if midi_profile_fpath:
            zynconf.load_config(True, midi_profile_fpath)
            zynthian_gui_config.set_midi_config()
            self.init_midi()
            self.init_midi_services()
            self.zynautoconnect()
            Zynthbox.Plugin.instance().reloadZynthianConfiguration()

    """
    Initialize Global FX Engines
    This method, when called, will create all the fx engines that and store them in the list self.global_fx_engines
    Zynautoconnect will use this list of engines and connect samplersynth to these engines
    """
    def init_global_fx(self):
        self.global_settings.beginGroup("GlobalFX")
        delay_engine_name = self.global_settings.value("delay_engine_name")
        delay_level_controller_name = self.global_settings.value("delay_level_controller_name")
        reverb_engine_name = self.global_settings.value("reverb_engine_name")
        reverb_level_controller_name = self.global_settings.value("reverb_level_controller_name")
        self.global_settings.endGroup()

        logging.debug("Initializing global FX engines")
        self.currentTaskMessage = "Initializing Global FX Engines : Delay"
        delay_engine = self.engine.start_engine(delay_engine_name, False)
        delay_layer = zynthian_layer(delay_engine, -1, self)
        delay_controller = MultiController(self)
        delay_controller.add_control(delay_layer.controllers_dict[delay_level_controller_name])

        self.currentTaskMessage = "Initializing Global FX Engines : Reverb"
        reverb_engine = self.engine.start_engine(reverb_engine_name, False)
        reverb_layer = zynthian_layer(reverb_engine, -1, self)
        reverb_controller = MultiController(self)
        reverb_controller.add_control(reverb_layer.controllers_dict[reverb_level_controller_name])

        # global_fx_engines is a list of lists of 3 elements.
        # 1st element of the list is the engine instance
        # 2nd element of the list is the zynthian controller to control fx
        # 3rd element of the list is the layer
        self.global_fx_engines = [
            [delay_engine, delay_controller, delay_layer],
            [reverb_engine, reverb_controller, reverb_layer]
        ]

        self.global_fx_engines[0][1].value = 100
        self.global_fx_engines[1][1].value = 100

    @Slot(int, result=None)
    def selectGlobalFXPreset(self, fxSlot):
        if -1 < fxSlot and fxSlot < len(self.global_fx_engines):
            self.set_curlayer(self.global_fx_engines[fxSlot][2])
            self.show_screen("effect_preset")

    @Slot(int, result=None)
    def editGlobalFX(self, fxSlot):
        if -1 < fxSlot and fxSlot < len(self.global_fx_engines):
            self.set_curlayer(self.global_fx_engines[fxSlot][2])
            self.show_screen("control")

    # ---------------------------------------------------------------------------
    # OSC Management
    # ---------------------------------------------------------------------------

    def osc_init(self, port=1370, proto=liblo.UDP):
        try:
            self.osc_server = liblo.Server(port, proto)
            self.osc_server_port = self.osc_server.get_port()
            self.osc_server_url = liblo.Address(
                "localhost", self.osc_server_port, proto
            ).get_url()
            logging.info(
                "ZYNTHIAN-UI OSC server running in port {}".format(
                    self.osc_server_port
                )
            )
            self.osc_server.add_method(None, None, self.osc_cb_all)
            # self.osc_server.start()
        # except liblo.AddressError as err:
        except Exception as err:
            logging.error(
                "ZYNTHIAN-UI OSC Server can't be started: {}".format(err)
            )

    def osc_end(self):
        if self.osc_server:
            try:
                # self.osc_server.stop()
                logging.info("ZYNTHIAN-UI OSC server stopped")
            except Exception as err:
                logging.error("Can't stop ZYNTHIAN-UI OSC server => %s" % err)

    def osc_receive(self):
        if not hasattr(self, "osc_server"):
            return
        while self.osc_server.recv(0):
            pass

    # @liblo.make_method("RELOAD_MIDI_CONFIG", None)
    # @liblo.make_method(None, None)
    def osc_cb_all(self, path, args, types, src):
        logging.info("OSC MESSAGE '%s' from '%s'" % (path, src.url))

        parts = path.split("/", 2)
        if parts[0] == "" and parts[1].upper() == "CUIA":
            # Execute action
            self.callable_ui_action(parts[2].upper(), args)
            # Run autoconnect if needed
            self.zynautoconnect_do()
        else:
            logging.warning("Not supported OSC call '{}'".format(path))

        # for a, t in zip(args, types):
        #     logging.debug("argument of type '%s': %s" % (t, a))

    # ---------------------------------------------------------------------------
    # GUI Core Management
    # ---------------------------------------------------------------------------

    def start(self):
        # Initialize jack Transport
        # self.zyntransport = zynthian_engine_transport()

        # Create Core UI Screens
        self.currentTaskMessage = "Creating Core Control Objects"

        self.screens["info"] = zynthian_gui_info(self)
        self.screens["about"] = zynthian_gui_about(self)
        self.screens["confirm"] = zynthian_gui_confirm(self)
        # self.screens['keyboard'] = zynthian_gui_keyboard(self)
        self.screens["option"] = zynthian_gui_option(self)
        self.screens["engine"] = zynthian_gui_engine(self)
        self.screens["layer"] = zynthian_gui_layer(self)
        self.screens["layer_options"] = zynthian_gui_layer_options(self)
        self.screens["layer_effects"] = zynthian_gui_layer_effects(self)
        self.screens["layer_midi_effects"] = zynthian_gui_layer_effects(self)
        self.screens["layer_midi_effects"].midi_mode = True
        self.screens["effect_types"] = zynthian_gui_effect_types(self)
        self.screens["midi_effect_types"] = zynthian_gui_effect_types(self)
        self.screens["midi_effect_types"].midi_mode = True
        self.screens["layer_effect_chooser"] = zynthian_gui_layer_effect_chooser(self)
        self.screens["layer_midi_effect_chooser"] = zynthian_gui_layer_effect_chooser(self)
        self.screens["layer_midi_effect_chooser"].midi_mode = True
        self.screens["snapshot"] = zynthian_gui_snapshot(self)
        self.screens["midi_chan"] = zynthian_gui_midi_chan(self)
        self.screens["midi_cc"] = zynthian_gui_midi_cc(self)
        self.screens['midi_key_range'] = zynthian_gui_midi_key_range(self)
        self.screens['audio_out'] = zynthian_gui_audio_out(self)
        # self.screens['midi_out'] = zynthian_gui_midi_out(self)
        self.screens['audio_in'] = zynthian_gui_audio_in(self)
        self.screens["bank"] = zynthian_gui_bank(self)
        self.screens["preset"] = zynthian_gui_preset(self)

        # effect_preset is the same instance as preset screen
        # This is done to be able to differentiate if the preset page is open from SynthSetupPage or FXSetupPage
        # Since the same data is displayed in both the pages we need to be able to differentiate it so that PageManager can know which container page to open
        self.screens["effect_preset"] = self.screens["preset"]

        self.screens["control"] = zynthian_gui_control(self)
        self.screens["control_downloader"] = zynthian_gui_newstuff(self)
        self.screens["fx_control_downloader"] = self.screens["control_downloader"]
        self.screens["channel"] = zynthian_gui_channel(self)
        self.screens["channel_external_setup"] = zynthian_gui_channel_external_setup(self)
        self.screens["channel_wave_editor"] = zynthian_gui_channel_wave_editor(self)
        # self.screens['control_xy'] = zynthian_gui_control_xy(self)
        # self.screens['midi_profile'] = zynthian_gui_midi_profile(self)
        # self.screens['zs3_learn'] = zynthian_gui_zs3_learn(self)
        # self.screens['zs3_options'] = zynthian_gui_zs3_options(self)
        self.screens["main"] = zynthian_gui_main(self)
        self.screens["module_downloader"] = zynthian_gui_newstuff(self)
        self.screens["admin"] = zynthian_gui_admin(self)
        self.screens["audio_settings"] = zynthian_gui_audio_settings(self)
        self.screens["wifi_settings"] = zynthian_gui_wifi_settings(self)
        self.screens["midicontroller_settings"] = zynthian_gui_midicontroller_settings(self)
        self.screens["synth_behaviour"] = zynthian_gui_synth_behaviour(self)
        self.screens["snapshots_menu"] = zynthian_gui_snapshots_menu(self)
        self.screens["sound_categories"] = zynthian_gui_sound_categories(self)

        self.screens["network"] = zynthian_gui_network(self)
        self.screens["network_info"] = self.screens["network"]
        self.screens["hardware"] = zynthian_gui_hardware(self)
        self.screens["test_knobs"] = zynthian_gui_test_knobs(self)
        # self.screens['touchscreen_calibration'] = zynthian_gui_touchscreen_calibration(self)

        # Init GlobalFX
        self.init_global_fx()

        # Create UI Apps Screens
        self.currentTaskMessage = "Loading Application Page Backends"

        self.screens['alsa_mixer'] = self.screens['control']
        self.screens["audio_recorder"] = zynthian_gui_audio_recorder(self)
        self.screens["test_touchpoints"] = zynthian_gui_test_touchpoints(self)
        self.screens["sketchpad"] = zynthian_gui_sketchpad(self)

        ###
        # Fixed layers depends on sketchpad screen and hence needs to be initialized
        # after those 2 pages
        ###
        self.screens["layers_for_channel"] = zynthian_gui_layers_for_channel(self)
        self.screens["fixed_layers"] = zynthian_gui_fixed_layers(self)
        self.screens["main_layers_view"] = zynthian_gui_fixed_layers(self)

        self.screens["effects_for_channel"] = zynthian_gui_effects_for_channel(self)

        # if "autoeq" in zynthian_gui_config.experimental_features:
        # self.screens['autoeq'] = zynthian_gui_autoeq(self)
        # self.screens['stepseq'] = zynthian_gui_stepsequencer(self)
        self.screens["theme_chooser"] = zynthian_gui_theme_chooser(self)
        self.screens["theme_downloader"] = zynthian_gui_newstuff(self)
        self.screens["sketch_downloader"] = zynthian_gui_newstuff(self)
        self.screens["sound_downloader"] = zynthian_gui_newstuff(self)
        self.screens["soundfont_downloader"] = zynthian_gui_newstuff(self)
        self.screens["soundset_downloader"] = zynthian_gui_newstuff(self)
        self.screens["sequence_downloader"] = zynthian_gui_newstuff(self)
        self.screens["sketchpad_downloader"] = zynthian_gui_newstuff(self)

        self.screens["playgrid"] = zynthian_gui_playgrid(self)
        self.screens["playgrid_downloader"] = zynthian_gui_newstuff(self)
        self.screens["miniplaygrid"] = zynthian_gui_playgrid(self)
        self.screens["song_manager"] = zynthian_gui_song_manager(self)
        self.screens["led_config"] = zynthian_gui_led_config(self)
        self.screens["bluetooth_config"] = zynthian_gui_bluetooth_config(self)

        # Instantiate Plugin helper
        self.__zynthbox_plugins_helper = zynthbox_plugins_helper(self)

        # Add the OSD handler
        self.__osd = zynthian_osd(self)

        # Init Auto-connector
        zynautoconnect.start()

        # Initialize OSC
        self.osc_init()

        # Initialize midi config
        self.init_midi()

        # Start polling threads
        self.start_polling()
        self.start_loading_thread()
        self.start_zyncoder_thread()

        # Run autoconnect if needed
        self.zynautoconnect_do()

        # Initialize MPE Zones
        # self.init_mpe_zones(0, 2)

        # Reset tracks LED state on selectedTrackId change
        self.sketchpad.selected_track_id_changed.connect(self.tracksModTimerHandler)

    def stop(self):
        logging.info("STOPPING ZYNTHIAN-UI ...")
        self.stop_polling()
        self.osc_end()
        zynautoconnect.stop()
        self.screens["layer"].reset()
        # Turn off leds
        Popen(("python3", "zynqtgui/zynthian_gui_led_config.py", "off"))
        # self.zyntransport.stop()

    def hide_screens(self, exclude=None):
        if not exclude:
            exclude = self.active_screen

        exclude_obj = self.screens[exclude]

    @Slot(str)
    def show_screen(self, screen=None):
        if screen is None:
            if self.active_screen:
                screen = self.active_screen
            else:
                screen = self.__home_screen
        elif screen == "layer" or screen == "main_layers_view" or screen == "fixed_layers":  #HACK replace completely layer with layers_for_channel
            screen = "layers_for_channel"

        if (
            screen == "layer"
            or screen == "fixed_layers"
            or screen == "main_layers_view"
            or screen ==  "layers_for_channel"
            or screen == "bank"
            or screen == "preset"
            or screen == "control"
        ):
            self.restore_curlayer()

        self.lock.acquire()
        self.hide_screens(exclude=screen)
        self.screens[screen].show()
        screen_scanged = self.active_screen != screen
        modal_screen_scanged = self.modal_screen != None
        self.active_screen = screen
        if screen == "main": # Main is now transient
            if self.modal_screen != "confirm":
                self.modal_screen_back = self.modal_screen
        else:
            self.modal_screen_back = None
            self.screen_back = self.active_screen
        self.modal_screen = None
        self.lock.release()
        if screen_scanged or modal_screen_scanged:
            self.current_screen_id_changed.emit()
        if modal_screen_scanged:
            self.current_modal_screen_id_changed.emit()

    def show_active_screen(self):
        self.show_screen()

    @Slot(str)
    def show_modal(self, screen, mode=None):
        if screen == "alsa_mixer":
            if (
                self.modal_screen != screen
                and self.screens["layer"].amixer_layer
            ):
                self._curlayer = self.curlayer
                self.screens["layer"].amixer_layer.refresh_controllers()
                self.set_curlayer(self.screens["layer"].amixer_layer)
            else:
                return

        elif screen == "snapshot":
            if mode is None:
                mode = "LOAD"
            self.screens["snapshot"].set_action(mode)

        self.lock.acquire()
        if self.modal_screen != screen and self.modal_screen not in (
            "info",
            "confirm",
        ):
            self.modal_screen_back = self.modal_screen

        self.screen_back = None
        self.modal_screen = screen
        logging.debug("AAAAA{}".format(screen))
        logging.debug(self.screens[screen])
        if screen != "confirm":
            self.screens[screen].show()

        self.hide_screens(exclude=screen)
        self.lock.release()

        self.current_modal_screen_id_changed.emit()
        self.current_screen_id_changed.emit()

    def close_modal(self):
        self.cancel_modal_timer()
        if self.modal_screen_back:
            self.show_modal(self.modal_screen_back)
            self.modal_screen_back = None
        else:
            self.show_screen()
        self.current_modal_screen_id_changed.emit()

    def close_modal_timer(self, tms=3000):
        self.cancel_modal_timer()
        self.modal_timer.setInterval(tms)
        self.modal_timer.start()

    def cancel_modal_timer(self):
        self.modal_timer.stop()

    def toggle_modal(self, screen, mode=None):
        if self.modal_screen != screen:
            self.show_modal(screen, mode)
        else:
            self.close_modal()

    def refresh_screen(self):
        screen = self.active_screen
        if screen == "preset" and len(self.curlayer.preset_list) <= 1:
            screen = "control"
        self.show_screen(screen)

    def get_current_screen(self):
        try:
            if self.modal_screen:
                return self.screens[self.modal_screen]
            else:
                return self.screens[self.active_screen]
        except:
            # This should never happen but if happens it is better to return None instead of crashing
            return None

    def show_confirm(self, text, callback=None, cb_params=None):
        if self.modal_screen != "confirm":
            self.modal_screen_back = self.modal_screen
        self.modal_screen = "confirm"
        self.screens["confirm"].show(text, callback, cb_params)
        self.hide_screens(exclude="confirm")
        self.current_modal_screen_id_changed.emit()

    def show_keyboard(self, callback, text="", max_chars=None):
        self.modal_screen_back = self.modal_screen
        self.modal_screen = "keyboard"
        self.screens["keyboard"].show(callback, text, max_chars)
        self.hide_screens(exclude="keyboard")
        self.current_modal_screen_id_changed.emit()

    def show_info(self, text, tms=None):
        if self.modal_screen != "confirm":
            self.modal_screen_back = self.modal_screen
        self.modal_screen = "info"
        self.screens["info"].show(text)
        self.hide_screens(exclude="info")
        self.current_modal_screen_id_changed.emit()
        logging.debug(tms)
        if tms:
            self.hide_info_timer()

    def add_info(self, text, tags=None):
        self.screens["info"].add(text, tags)

    def hide_info(self):
        if self.modal_screen == "info":
            self.close_modal()

    def hide_info_timer(self, tms=3000):
        if self.modal_screen == "info":
            self.cancel_info_timer()
            self.info_timer.setInterval(tms)
            self.info_timer.start()

    def cancel_info_timer(self):
        self.info_timer.stop()

    def calibrate_touchscreen(self):
        self.show_modal("touchscreen_calibration")

    def load_snapshot(self):
        self.show_modal("snapshot", "LOAD")

    def save_snapshot(self):
        self.show_modal("snapshot", "SAVE")

    def layer_control(self, layer=None):
        modal = False
        if layer is not None:
            if layer in self.screens["layer"].root_layers:
                self._curlayer = None
            else:
                modal = True
                self._curlayer = self.curlayer

            self.set_curlayer(layer)

        if self.curlayer:
            # If there is a preset selection for the active layer ...
            if (
                zynthian_gui_config.automatically_show_control_page
                and self.curlayer.get_preset_name()
            ):
                self.show_screen("control")
            else:
                if self.curlayer.get_preset_name():
                    if self.isBootingComplete:
                        self.add_screen_to_show_queue(self.screens["control"])
                    else:
                        self.screens["control"].show()

                if self.screens["layer"].auto_next_screen:
                    if modal:
                        self.show_modal("bank")
                    else:
                        self.show_screen("bank")
                elif self.modal_screen == None and self.active_screen == None:
                    if modal:
                        self.show_modal("layer")
                    else:
                        self.show_screen("layer")
                else:
                    if self.isBootingComplete:
                        self.add_screen_to_show_queue(self.screens["layer"])
                    else:
                        self.screens["layer"].show()

                # If there is only one bank, jump to preset selection
                if len(self.curlayer.bank_list) <= 1:
                    self.screens["bank"].select_action(0)

                if self.isBootingComplete:
                    self.add_screen_to_show_queue(self.screens["layer_effects"], True)
                    self.add_screen_to_show_queue(self.screens["layer_midi_effects"], True)
                else:
                    self.screens["layer_effects"].show()
                    self.screens["layer_effects"].select_action(0)
                    self.screens["layer_midi_effects"].show()
                    self.screens["layer_midi_effects"].select_action(0)

    def show_control(self):
        self.restore_curlayer()
        self.layer_control()

    def enter_midi_learn_mode(self):
        self.midi_learn_mode = True
        self.setMidiLearnZctrl(None)
        lib_zyncoder.set_midi_learning_mode(1)
        self.screens["control"].refresh_midi_bind()
        self.screens["control"].set_select_path()
        # self.show_modal('zs3_learn')

    def exit_midi_learn_mode(self):
        self.midi_learn_mode = False
        self.setMidiLearnZctrl(None)
        lib_zyncoder.set_midi_learning_mode(0)
        self.screens["control"].refresh_midi_bind()
        self.screens["control"].set_select_path()
        self.show_active_screen()

    def show_control_xy(self, xctrl, yctrl):
        self.modal_screen = "control_xy"
        self.screens["control_xy"].set_controllers(xctrl, yctrl)
        self.screens["control_xy"].show()
        self.hide_screens(exclude="control_xy")
        self.active_screen = "control"
        self.screens["control"].set_mode_control()
        logging.debug(
            "SHOW CONTROL-XY => %s, %s" % (xctrl.symbol, yctrl.symbol)
        )
        self.current_modal_screen_id_changed.emit()

    def set_curlayer(self, layer, save=False, queue=True):
        if layer is not None:
            if save:
                self._curlayer = self.curlayer
            self.curlayer = layer
            self.set_active_channel()
            try:
                self.screens["layer"].select(self.screens["layer"].root_layers.index(layer))
            except:
                pass
        else:
            self.curlayer = None
        self.screens["fixed_layers"].sync_index_from_curlayer()
        self.screens["layers_for_channel"].sync_index_from_curlayer()
        if queue:
            self.add_screen_to_show_queue(self.screens["bank"], False, True)
            self.add_screen_to_show_queue(self.screens["preset"], False, True)
            self.add_screen_to_show_queue(self.screens["control"], False, True)
            if self.curlayer is not None and self.curlayer.engine.type == "Audio Effect":
                self.add_screen_to_show_queue(self.screens["effects_for_channel"], False, True)
        else:
            self.curlayer.refresh_controllers()
            self.screens["bank"].fill_list()
            self.screens["preset"].fill_list()
            self.screens["control"].fill_list()
            self.screens["bank"].show()
            self.screens["preset"].show()
            self.screens["control"].show()
            if self.curlayer is not None and self.curlayer.engine.type == "Audio Effect":
                self.screens["effects_for_channel"].fill_list()
                self.screens["effects_for_channel"].show()
        self.control.selectedColumn = 0
        if self.curlayer:
            self.screens["midi_key_range"].config(self.curlayer.midi_chan)
            midi_chan = self.curlayer.midi_chan
            if midi_chan < self.screens['main_layers_view'].get_start_midi_chan() or midi_chan >= self.screens['main_layers_view'].get_start_midi_chan() + self.screens['main_layers_view'].get_layers_count():
                self.screens['main_layers_view'].set_start_midi_chan(math.floor(midi_chan / 5) * 5)
        self.active_midi_channel_changed.emit()
        self.screens["main_layers_view"].sync_index_from_curlayer()
        self.curlayerEngineNameChanged.emit()
        self.curlayerPresetNameChanged.emit()
        self.curlayerIsFXChanged.emit()

    def restore_curlayer(self):
        if self._curlayer:
            self.set_curlayer(self._curlayer)
            self._curlayer = None

    # If "MIDI Single Active Channel" mode is enabled, set MIDI Active Channel to layer's one
    def set_active_channel(self):
        curlayer_chan = None
        active_chan = -1

        if self.curlayer:
            # Don't change nothing for MIXER
            if self.curlayer.engine.nickname == "MX":
                return
            curlayer_chan = self.curlayer.get_midi_chan()
            if (
                curlayer_chan is not None
                and zynthian_gui_config.midi_single_active_channel
            ):
                active_chan = curlayer_chan
                cur_active_chan = lib_zyncoder.get_midi_active_chan()
                if cur_active_chan == active_chan:
                    return
                else:
                    # logging.debug("ACTIVE CHAN: {} => {}".format(cur_active_chan, active_chan))
                    # if cur_active_chan>=0:
                    #     self.all_notes_off_chan(cur_active_chan)
                    pass

        lib_zyncoder.set_midi_active_chan(active_chan)
        self.zynswitches_midi_setup(curlayer_chan)
        self.active_midi_channel_changed.emit()

    def get_curlayer_wait(self):
        # Try until layer is ready
        for j in range(100):
            if self.curlayer:
                return self.curlayer
            else:
                time.sleep(0.1)

    def is_single_active_channel(self):
        return zynthian_gui_config.midi_single_active_channel

    def is_external_app_active(self):
        return hasattr(zynthian_gui_config, 'top') and zynthian_gui_config.top.isActive() == False

    # -------------------------------------------------------------------
    # Callable UI Actions
    # -------------------------------------------------------------------

    @Slot(str,int,int,int,int)
    def handleMidiRouterCuiaEvent(self, cuia, originId, track, slot, value):
        # logging.error(f"midi router cuia event: {cuia}, origin ID: {originId}, track: {track} aka {int(track)}, slot: {slot} aka {int(slot)}, value: {value}")
        if int(track) < 0:
            track = self.sketchpad.selectedTrackId
        if int(slot) < 0:
            slot = 0 # FIXME This needs to also sniff the currently selected clip/sound/fx slot when valid
            # theTrack.selectedFxSlotRow - the property holding that information...
        self.callable_ui_action(cuia, [value], originId, int(track), int(slot))

    # This exists to allow us to call just a cuia (without parameters) from QML, as we can't easily overload slots
    @Slot(str)
    def callable_ui_action_simple(self, cuia):
        self.callable_ui_action(cuia)

    @Slot(str, 'QVariantList', int, int, int)
    def callable_ui_action(self, cuia, params=[-1], originId=-1, track=-1, slot=-1):
        # logging.error(f"CUIA : {cuia} {params} {originId} {track} {slot}")

        # BEGIN fallback logic for legacy cuias
        # NOTE If any of these are hit, we will return early from this function
        rewriteLegacyAs = ""
        if cuia == "SELECT":
            rewriteLegacyAs = "SELECT_ITEM"
        if cuia == "ZL_PLAY":
            rewriteLegacyAs = "SWITCH_PLAY"
        elif cuia == "ZL_STOP":
            rewriteLegacyAs = "SWITCH_STOP"
        elif cuia == "START_RECORD":
            rewriteLegacyAs = "SWITCH_RECORD"
        elif cuia == "KEYBOARD":
            rewriteLegacyAs = "TOGGLE_KEYBOARD"
        elif cuia == "MODAL_STEPSEQ":
            rewriteLegacyAs = "SCREEN_PLAYGRID"
        elif cuia == "SWITCH_LAYER_LONG":
            rewriteLegacyAs = "SWITCH_LAYER_BOLD"
        elif cuia == "SWITCH_BACK_LONG":
            rewriteLegacyAs = "SWITCH_BACK_BOLD"
        elif cuia == "SWITCH_SNAPSHOT_LONG":
            rewriteLegacyAs = "SWITCH_SNAPSHOT_BOLD"
        elif cuia == "SWITCH_SELECT_LONG":
            rewriteLegacyAs = "SWITCH_SELECT_BOLD"
        elif cuia.startswith("CHANNEL_"):
            # Catch all five numerical entries, and the two next/previous ones
            rewriteLegacyAs = cuia.replace("CHANNEL_", "TRACK_")
        elif cuia == "SCREEN_AUDIO_SETTINGS" or cuia == "MODAL_ALSA_MIXER":
            rewriteLegacyAs = "SWITCH_GLOBAL_RELEASED"
        elif cuia in ["START_MIDI_RECORD", "STOP_MIDI_RECORD", "TOGGLE_MIDI_RECORD", "START_MIDI_PLAY", "STOP_MIDI_PLAY", "TOGGLE_MIDI_PLAY", "MODAL_MIDI_RECORDER",
                      "START_AUDIO_RECORD", "STOP_AUDIO_RECORD", "TOGGLE_AUDIO_RECORD", "START_AUDIO_PLAY", "STOP_AUDIO_PLAY", "TOGGLE_AUDIO_PLAY", "MODAL_AUDIO_RECORDER",
                      "BACK_UP", "BACK_DOWN",
                      "MODE_SWITCH_SHORT", "MODE_SWITCH_BOLD", "MODE_SWITCH_LONG",
                      "SWITCH_TRACKS_MOD_SHORT", "SWITCH_TRACKS_MOD_BOLD", "SWITCH_TRACKS_MOD_LONG", "SWITCH_CHANNELS_MOD_SHORT", "SWITCH_CHANNELS_MOD_BOLD", "SWITCH_CHANNELS_MOD_LONG"]:
            # These commands are simply ignored (they have no function, so while they may still show up, we have no use for them)
            # They became not required when we switched our recorder logic from a split modal page to a globally available popup
            return
        if len(rewriteLegacyAs) > 0:
            self.callable_ui_action(rewriteLegacyAs, params, originId, track, slot)
            return
        # END fallback logic for legacy cuias

        # BEGIN Button ignore logic
        # NOTE If any of these are hit, we will return early from this function
        if (cuia == "SWITCH_BACK_SHORT" or cuia == "SWITCH_BACK_BOLD") and self.ignoreNextBackButtonPress == True:
            self.ignoreNextBackButtonPress = False
            return
        elif cuia == "SWITCH_MODE_RELEASED" and self.ignoreNextModeButtonPress == True:
            self.modeButtonPressed = False # Ensure we have marked the button as released
            self.ignoreNextModeButtonPress = False
            return
        elif cuia == "SWITCH_MENU_RELEASED" and self.ignoreNextMenuButtonPress == True:
            self.menuButtonPressed = False # Ensure we have marked the button as released
            self.ignoreNextMenuButtonPress = False
            return
        elif cuia == "SWITCH_PLAY" and self.ignoreNextPlayButtonPress == True:
            self.ignoreNextPlayButtonPress = False
            return
        elif cuia == "SWITCH_STOP" and self.ignoreNextStopButtonPress == True:
            self.ignoreNextStopButtonPress = False
            return
        elif cuia == "SWITCH_RECORD" and self.ignoreNextRecordButtonPress == True:
            self.ignoreNextRecordButtonPress = False
            return
        elif (cuia == "SWITCH_METRONOME_SHORT" or cuia == "SWITCH_METRONOME_BOLD") and self.ignoreNextMetronomeButtonPress == True:
            self.ignoreNextMetronomeButtonPress = False
            return
        elif cuia == "SWITCH_GLOBAL_RELEASED" and self.ignoreNextGlobalButtonPress == True:
            self.globalButtonPressed = False # Ensure we have marked the button as released
            self.ignoreNextGlobalButtonPress = False
            return
        elif (cuia == "SWITCH_SELECT_SHORT" or cuia == "SWITCH_SELECT_BOLD") and self.ignoreNextSelectButtonPress == True:
            self.ignoreNextSelectButtonPress = False
            return
        # END Button ignore logic

        # BEGIN Button-press abort modifiers logic
        # NOTE If any of these are hit, we will return early from this function
        # If we press the back button when any of the modifier-capable
        # buttons are held down, abort that button's release actions
        if cuia == "SWITCH_BACK_SHORT" or cuia == "SWITCH_BACK_BOLD":
            changedAnything = False
            if self.globalButtonPressed == True and self.ignoreNextGlobalButtonPress == False:
                self.ignoreNextGlobalButtonPress = True
                changedAnything = True
            if self.modeButtonPressed == True and self.ignoreNextModeButtonPress == False:
                self.ignoreNextModeButtonPress = True
                changedAnything = True
            if self.menuButtonPressed == True and self.ignoreNextMenuButtonPress == False:
                self.ignoreNextMenuButtonPress = True
                changedAnything = True
            if self.playButtonPressed == True and self.ignoreNextPlayButtonPress == False:
                self.ignoreNextPlayButtonPress = True
                changedAnything = True
            if self.stopButtonPressed == True and self.ignoreNextStopButtonPress == False:
                self.ignoreNextStopButtonPress = True
                changedAnything = True
            if self.startRecordButtonPressed == True and self.ignoreNextRecordButtonPress == False:
                self.ignoreNextRecordButtonPress = True
                changedAnything = True
            if self.metronomeButtonPressed == True and self.ignoreNextMetronomeButtonPress == False:
                self.ignoreNextMetronomeButtonPress = True
                changedAnything = True
            if self.selectButtonPressed == True and self.ignoreNextSelectButtonPress == False:
                self.ignoreNextSelectButtonPress = True
                changedAnything = True
            if changedAnything == True:
                return
        # END Button-press abort modifiers logic

        trackDelta = 5 if self.tracksModActive else 0

        # This will happen if fed an empty parameter list (such as from osc)
        if len(params) == 0:
            params = [-1]

        # Before anything else, try and ask the main window whether there's anything to be done
        try:
            cuia_callback = zynthian_gui_config.top.property("cuiaCallback")
            if cuia_callback is not None and cuia_callback.isCallable():
                _result = cuia_callback.call([cuia, originId, track, slot, params[0]])
                if _result is not None and _result.toBool():
                    Zynthbox.MidiRouter.instance().cuiaEventFeedback(cuia, originId, Zynthbox.ZynthboxBasics.Track(track), Zynthbox.ZynthboxBasics.Slot(slot), params[0])
                    return
        except Exception as e:
            logging.error("Attempted to run callbacks on the main window, which apparently failed badly, with the error: {}".format(e))

        # Check if there are any open dialogs. Forward cuia events to cuiaCallback of opened dialog
        if self.opened_dialog is not None:
            try:
                cuia_callback = self.opened_dialog.property("cuiaCallback")
                visible = self.opened_dialog.property("visible")

                if cuia_callback is not None and cuia_callback.isCallable() and visible:
                    _result = cuia_callback.call([cuia, originId, track, slot, params[0]])

                    if _result is not None and _result.toBool():
                        # If cuiaCallback returned true, then CUIA event has been handled by qml. Return
                        Zynthbox.MidiRouter.instance().cuiaEventFeedback(cuia, originId, Zynthbox.ZynthboxBasics.Track(track), Zynthbox.ZynthboxBasics.Slot(slot), params[0])
                        return

                if visible:
                    # If control reaches here it means either cuiaCallback property was not found or returned false
                    # In either of the case, try to close the dialog if CUIA event is SWITCH_BACK
                    try:
                        if cuia.startswith("SWITCH_BACK"):
                            logging.debug(f"SWITCH_BACK pressed. Dialog does not have a cuiaCallback property. Try closing.")
                            QMetaObject.invokeMethod(self.opened_dialog, "close", Qt.QueuedConnection)
                            Zynthbox.MidiRouter.instance().cuiaEventFeedback(cuia, originId, Zynthbox.ZynthboxBasics.Track(track), Zynthbox.ZynthboxBasics.Slot(slot), params[0])
                            return
                    except Exception as e:
                        logging.debug(f"Attempted to close openedDialog, got error: {e}")
                        pass
            except Exception as e:
                logging.error("Attempted to use cuiaCallback on openeedDialog, got error: {}".format(e))

        if cuia != "SCREEN_MAIN_MENU" and self.current_qml_page != None:
            try:
                js_value = self.current_qml_page_prop.property("cuiaCallback")
                if js_value is not None and js_value.isCallable():
                    _result = js_value.call([cuia, originId, track, slot, params[0]])
                    if _result is not None and _result.toBool():
                        Zynthbox.MidiRouter.instance().cuiaEventFeedback(cuia, originId, Zynthbox.ZynthboxBasics.Track(track), Zynthbox.ZynthboxBasics.Slot(slot), params[0])
                        return
            except Exception as e:
                logging.error("Attempted to use cuiaCallback, got error: {}".format(e))

        sendCuiaEventFeedback = True
        if cuia == "POWER_OFF":
            self.screens["admin"].power_off_confirmed()

        elif cuia == "REBOOT":
            self.screens["admin"].reboot_confirmed()

        elif cuia == "RESTART_UI":
            self.screens["admin"].restart_gui()

        elif cuia == "RELOAD_MIDI_CONFIG":
            self.reload_midi_config()

        elif cuia == "RELOAD_KEY_BINDING":
            zynthian_gui_keybinding.getInstance(self).load()

        elif cuia == "LAST_STATE_ACTION":
            self.screens["admin"].last_state_action()

        elif cuia == "ALL_NOTES_OFF":
            self.all_notes_off()

        elif cuia == "ALL_SOUNDS_OFF" or cuia == "ALL_OFF":
            self.all_notes_off()
            self.all_sounds_off()

        elif cuia == "SELECT_ITEM":
            try:
                self.get_current_screen().select(params[0])
            except:
                pass

        elif cuia == "SELECT_UP":
            try:
                self.get_current_screen().select_up()
            except:
                pass

        elif cuia == "SELECT_DOWN":
            try:
                self.get_current_screen().select_down()
            except:
                pass

        elif cuia == "LAYER_UP":
            try:
                self.screens["layer"].layer_up()
            except:
                pass

        elif cuia == "LAYER_DOWN":
            try:
                self.screens["layer"].layer_down()
            except:
                pass

        elif cuia == "SNAPSHOT_UP":
            try:
                self.get_current_screen().snapshot_up()
            except:
                pass

        elif cuia == "SNAPSHOT_DOWN":
            try:
                self.get_current_screen().snapshot_down()
            except:
                pass

        elif cuia == "SCENE_UP":
            try:
                self.screens["sketchpad"].song.scenesModel.selectedSketchpadSongIndex = max(0, self.screens["sketchpad"].song.scenesModel.selectedSketchpadSongIndex - 1)
            except:
                pass

        elif cuia == "SCENE_DOWN":
            try:
                self.screens["sketchpad"].song.scenesModel.selectedSketchpadSongIndex = min(self.screens["sketchpad"].song.scenesModel.count - 1, self.screens["sketchpad"].song.scenesModel.selectedSketchpadSongIndex + 1)
            except:
                pass

        elif cuia == "SWITCH_LAYER_SHORT":
            self.zynswitch_short(0)

        elif cuia == "SWITCH_LAYER_BOLD":
            self.zynswitch_bold(0)

        elif cuia == "SWITCH_BACK_SHORT":
            self.zynswitch_short(1)

        elif cuia == "SWITCH_BACK_BOLD":
            self.zynswitch_bold(1)

        elif cuia == "SWITCH_SNAPSHOT_SHORT":
            self.zynswitch_short(2)

        elif cuia == "SWITCH_SNAPSHOT_BOLD":
            self.zynswitch_bold(2)

        elif cuia == "SWITCH_SELECT_SHORT":
            self.zynswitch_short(3)

        elif cuia == "SWITCH_SELECT_BOLD":
            self.zynswitch_bold(3)

        elif cuia == "SCREEN_MAIN_MENU":
            if self.get_current_screen_id() == "main":
                if self.modal_screen_back:
                    self.show_modal(self.modal_screen_back)
                elif self.screen_back:
                    self.show_screen(self.screen_back)
            else:
                self.show_screen("main")

        # elif cuia == "SCREEN_EDIT_CONTEXTUAL":
            # Do not handle this here. Instead handle it from qml main
            # Open control page if selected slot has synth from SynthSetupPage
            # Open respective edit page as per selected slot from any other page
            # pass

        # elif cuia == "SCREEN_ADMIN":
            # Do not handle 5th under screen button globally.
            # This button has specific behaviour for ZL page. Not sure about other pages
            # self.show_modal("admin")
            # pass

        elif cuia == "SCREEN_LAYER":
            selected_track = self.sketchpad.song.channelsModel.getChannel(self.sketchpad.selectedTrackId)
            if self.sketchpad.lastSelectedObj.className == "MixedChannelsViewBar_fxslot" and selected_track.chainedFx[self.sketchpad.lastSelectedObj.value] != None:
                zynqtgui.forced_screen_back = "sketchpad"
                zynqtgui.current_screen_id = "effect_preset"
                zynqtgui.layer.page_after_layer_creation = "sketchpad"
            elif self.sketchpad.lastSelectedObj.className == "MixedChannelsViewBar_slot" and selected_track.checkIfLayerExists(selected_track.chainedSounds[self.sketchpad.lastSelectedObj.value]):
                self.show_screen("preset")
            else:
                self.showMessageDialog.emit("Selected slot is empty. Cannot open preset page for empty slot", 2000)
            sendCuiaEventFeedback = False

        elif cuia == "SCREEN_LAYER_FX":
            self.show_screen("layer_effects")
            sendCuiaEventFeedback = False

        elif cuia == "SCREEN_BANK":
            self.show_screen("bank")
            sendCuiaEventFeedback = False

        elif cuia == "SCREEN_PRESET":
            self.show_screen("preset")
            sendCuiaEventFeedback = False

        elif cuia == "SCREEN_CONTROL":
            self.show_screen("control")
            sendCuiaEventFeedback = False

        elif cuia == "SCREEN_SKETCHPAD":
            if self.current_screen_id == "sketchpad":
                if self.altButtonPressed:
                    self.toggleSketchpadMixer()
            else:
                if self.altButtonPressed:
                    self.showSketchpadMixer()
                else:
                    self.show_modal("sketchpad")
            sendCuiaEventFeedback = False

        elif cuia == "SCREEN_SONG_MANAGER":
            self.show_modal("song_manager")
            sendCuiaEventFeedback = False

        elif cuia == "SCREEN_PLAYGRID":
            self.show_modal("playgrid")
            sendCuiaEventFeedback = False

        elif cuia == "SCREEN_ALSA_MIXER":
            self.toggle_modal("alsa_mixer")

        elif cuia == "MODAL_SNAPSHOT_LOAD":
            self.toggle_modal("snapshot", "LOAD")

        elif cuia == "MODAL_SNAPSHOT_SAVE":
            self.toggle_modal("snapshot", "SAVE")

        elif cuia == "SWITCH_GLOBAL_DOWN":
            self.globalButtonPressed = True
        elif cuia == "SWITCH_GLOBAL_RELEASED":
            self.globalButtonPressed = False

        elif cuia == "TRACK_1":
            if self.sketchpad.selectedTrackId == 0 + trackDelta and not self.leftSidebarActive:
                self.openLeftSidebar.emit()
            else:
                self.sketchpad.selectedTrackId = 0 + trackDelta
        elif cuia == "TRACK_2":
            if self.sketchpad.selectedTrackId == 1 + trackDelta and not self.leftSidebarActive:
                self.openLeftSidebar.emit()
            else:
                self.sketchpad.selectedTrackId = 1 + trackDelta
        elif cuia == "TRACK_3":
            if self.sketchpad.selectedTrackId == 2 + trackDelta and not self.leftSidebarActive:
                self.openLeftSidebar.emit()
            else:
                self.sketchpad.selectedTrackId = 2 + trackDelta
        elif cuia == "TRACK_4":
            if self.sketchpad.selectedTrackId == 3 + trackDelta and not self.leftSidebarActive:
                self.openLeftSidebar.emit()
            else:
                self.sketchpad.selectedTrackId = 3 + trackDelta
        elif cuia == "TRACK_5":
            if self.sketchpad.selectedTrackId == 4 + trackDelta and not self.leftSidebarActive:
                self.openLeftSidebar.emit()
            else:
                self.sketchpad.selectedTrackId = 4 + trackDelta
        elif cuia == "TRACK_PREVIOUS":
            self.sketchpad.selectedTrackId = max(0, min(self.sketchpad.selectedTrackId - 1, Zynthbox.Plugin.instance().sketchpadTrackCount() - 1))
        elif cuia == "TRACK_NEXT":
            self.sketchpad.selectedTrackId = max(0, min(self.sketchpad.selectedTrackId + 1, Zynthbox.Plugin.instance().sketchpadTrackCount() - 1))

        elif cuia == "SWITCH_TRACKS_MOD_DOWN":
            self.switchChannelsButtonPressed = True
        elif cuia == "SWITCH_TRACKS_MOD_RELEASED":
            self.switchChannelsButtonPressed = False

        elif cuia == "TOGGLE_KEYBOARD":
            # logging.info("TOGGLE_KEYBOARD")
            self.toggleMiniPlayGrid()
        elif cuia == "SHOW_KEYBOARD":
            self.showMiniPlayGrid = True
        elif cuia == "HIDE_KEYBOARD":
            self.showMiniPlayGrid = False

        elif cuia == "SWITCH_ALT_DOWN":
            self.altButtonPressed = True
        elif cuia == "SWITCH_ALT_RELEASED":
            self.altButtonPressed = False

        elif cuia == "SWITCH_PLAY":
            zl = self.screens["sketchpad"]

            if self.metronomeButtonPressed:
                self.__start_playback_on_metronome_release = True
            else:
                # Toggle play/stop with play CUIA action
                if zl.isMetronomeRunning:
                    self.run_stop_metronome_and_playback.emit()
                else:
                    self.run_start_metronome_and_playback.emit()
        elif cuia == "SWITCH_STOP":
            if Zynthbox.SyncTimer.instance().timerRunning():
                self.run_stop_metronome_and_playback.emit()
            else:
                self.callable_ui_action("ALL_NOTES_OFF")

        elif cuia == "SWITCH_RECORD":
            zl = self.screens["sketchpad"]
            if self.recording_popup_active or self.metronomeButtonPressed:
                if zl.isRecording:
                    # Some Clip is currently being recorded
                    logging.info("Some Clip is currently being recorded. Stopping record")
                    self.run_stop_metronome_and_playback.emit()
                    self.__channelToRecord = None
                    self.__channelRecordingRow = None
                    self.__clipToRecord = None
                else:
                    # No clips are currently being recorded
                    logging.info("CUIA Start Recording")
                    # Ensure that if we have been asked to start recording without opening the dialog (that is, by
                    # holding down the metronome button and then pressing record, for instant recording), we still
                    # end up actually recording into what's expected
                    if self.__channelToRecord is None:
                        self.__channelToRecord = zl.song.channelsModel.getChannel(self.sketchpad.selectedTrackId)
                    if self.__channelRecordingRow is None:
                        self.__channelRecordingRow = self.__channelToRecord.selectedSlotRow
                    if self.__clipToRecord is None:
                        self.__clipToRecord = self.__channelToRecord.getClipToRecord()

                    # If sample[0] is empty, set sample[0] to recorded file along with selectedTrackId's clip
                    if self.__channelToRecord.samples[self.__channelRecordingRow].path is not None and len(self.__channelToRecord.samples[self.__channelRecordingRow].path) > 0:
                        zl.clipsToRecord = [self.__clipToRecord]
                    else:
                        zl.clipsToRecord = [self.__clipToRecord, self.__channelToRecord.samples[self.__channelRecordingRow]]

                    logging.info(f"Recording Clip : {self.__clipToRecord}")
                    if self.__clipToRecord.queueRecording():
                        self.run_start_metronome_and_playback.emit()
                    else:
                        logging.error("Error while trying to queue clip to record")
            else:
                if zl.isRecording == False:
                    self.__channelToRecord = zl.song.channelsModel.getChannel(self.sketchpad.selectedTrackId)
                    self.__channelRecordingRow = self.__channelToRecord.selectedSlotRow
                    self.__clipToRecord = self.__channelToRecord.getClipToRecord()
                self.displayRecordingPopup.emit()

        elif cuia == "STOP_RECORD":
            self.run_stop_metronome_and_playback.emit()

        elif cuia == "SWITCH_MODE_DOWN":
            self.modeButtonPressed = True
        elif cuia == "SWITCH_MODE_RELEASED":
            if self.leftSidebarActive:
                self.closeLeftSidebar.emit()
            else:
                self.openLeftSidebar.emit()

        # elif cuia == "SWITCH_METRONOME_SHORT" or cuia == "SWITCH_METRONOME_BOLD":
        #     self.screens["sketchpad"].metronomeEnabled = not self.screens["sketchpad"].metronomeEnabled
        elif cuia == "SWITCH_PRESSED":
            pass
        elif cuia == "SWITCH_RELEASED":
            pass
        elif cuia == "ACTIVATE_TRACK":
            self.sketchpad.selectedTrackId = max(0, min(track, Zynthbox.Plugin.instance().sketchpadTrackCount() - 1))
            sendCuiaEventFeedback = False
        elif cuia == "ACTIVATE_TRACK_RELATIVE":
            trackDivisor = 128.0 / float(Zynthbox.Plugin.instance().sketchpadTrackCount())
            self.sketchpad.selectedTrackId = max(0, min((params[0] / trackDivisor), Zynthbox.Plugin.instance().sketchpadTrackCount() - 1))
            sendCuiaEventFeedback = False
        elif cuia == "TOGGLE_TRACK_MUTED":
            theTrack = self.sketchpad.song.channelsModel.getChannel(track)
            theTrack.muted = not theTrack.muted
        elif cuia == "SET_TRACK_MUTED":
            theTrack = self.sketchpad.song.channelsModel.getChannel(track)
            theTrack.muted = True if params[0] > 0 else False
            sendCuiaEventFeedback = False
        elif cuia == "TOGGLE_TRACK_SOLOED":
            if self.sketchpad.song.playChannelSolo == track:
                self.sketchpad.song.playChannelSolo = -1
            else:
                self.sketchpad.song.playChannelSolo = track
        elif cuia == "SET_TRACK_SOLOED":
            if params[0] == 0 and self.sketchpad.song.playChannelSolo == track:
                self.sketchpad.song.playChannelSolo = -1
            elif params[0] > 0:
                self.sketchpad.song.playChannelSolo = track
            sendCuiaEventFeedback = False
        elif cuia == "SET_TRACK_VOLUME":
            theTrack = self.sketchpad.song.channelsModel.getChannel(track)
            theTrack.gainHandler.setGainAbsolute(np.interp(param[0], (0, 127), (0, 1)))
            sendCuiaEventFeedback = False
        elif cuia == "SET_CLIP_CURRENT":
            shouldEmitClipOnly = True
            if -1 < track and track < Zynthbox.Plugin.instance().sketchpadTrackCount():
                self.sketchpad.set_selected_track_id(max(0, min(track, Zynthbox.Plugin.instance().sketchpadTrackCount() - 1)), shouldEmitCurrentTrackClipCUIAFeedback=False)
                shouldEmitClipOnly = False
            theTrack = self.sketchpad.song.channelsModel.getChannel(track)
            theTrack.theTrack.set_selected_clip(max(0, min(slot, Zynthbox.Plugin.instance().sketchpadSlotCount() - 1)), shouldEmitCurrentClipCUIAFeedback=shouldEmitClipOnly)
            if shouldEmitClipOnly == False:
                self.sketchpad.emitCurrentTrackClipCUIAFeedback()
            sendCuiaEventFeedback = False
        elif cuia == "SET_CLIP_CURRENT_RELATIVE":
            shouldEmitClipOnly = True
            if -1 < track and track < Zynthbox.Plugin.instance().sketchpadTrackCount():
                self.sketchpad.set_selected_track_id(max(0, min(track, Zynthbox.Plugin.instance().sketchpadTrackCount() - 1)), shouldEmitCurrentTrackClipCUIAFeedback=False)
                shouldEmitClipOnly = False
            slotDivisor = 128.0 / float(Zynthbox.Plugin.instance().sketchpadSlotCount())
            theTrack = self.sketchpad.song.channelsModel.getChannel(track)
            theTrack.set_selected_clip(max(0, min((params[0] / slotDivisor), Zynthbox.Plugin.instance().sketchpadSlotCount() - 1)), shouldEmitCurrentClipCUIAFeedback=shouldEmitClipOnly)
            if shouldEmitClipOnly == False:
                self.sketchpad.emitCurrentTrackClipCUIAFeedback()
            sendCuiaEventFeedback = False
        elif cuia == "SET_TRACK_PAN":
            theTrack = self.sketchpad.song.channelsModel.getChannel(track)
            theTrack.pan = np.interp(param[0], (0, 127), (-1, 1))
            sendCuiaEventFeedback = False
        elif cuia == "SET_TRACK_SEND1_AMOUNT":
            theTrack = self.sketchpad.song.channelsModel.getChannel(track)
            theTrack.wetFx1Amount = np.interp(param[0], (0, 127), (0, 1))
            sendCuiaEventFeedback = False
        elif cuia == "SET_TRACK_SEND2_AMOUNT":
            theTrack = self.sketchpad.song.channelsModel.getChannel(track)
            theTrack.wetFx2Amount = np.interp(param[0], (0, 127), (0, 1))
            sendCuiaEventFeedback = False
        elif cuia == "SET_CLIP_ACTIVE_STATE":
            theTrack = self.sketchpad.song.channelsModel.getChannel(track)
            theClip = theTrack.getClipsModelById(slot).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
            theClip.enabled = True if params[0] > 1 else False
            sendCuiaEventFeedback = False
        elif cuia == "TOGGLE_CLIP":
            theTrack = self.sketchpad.song.channelsModel.getChannel(track)
            theClip = theTrack.getClipsModelById(slot).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
            theClip.enabled = not theClip.enabled
        elif cuia == "SET_SLOT_GAIN":
            theTrack = self.sketchpad.song.channelsModel.getChannel(track)
            if theTrack.audioTypeKey() == "synth":
                synthIndex = theTrack.chainedSounds[slot]
                if synthIndex > -1:
                    theTrack.set_passthroughValue("synthPassthrough", slot, "dryAmount", np.interp(params[0], (0, 127), (0, 1)))
            elif theTrack.audioTypeKey() == "sample":
                sample = theTrack.samples[slot]
                if sample.audioSource:
                    sample.audioSource.setGainAbsolute(np.interp(params[0], (0, 127), (0, 1)))
            elif theTrack.audioTypeKey() == "sketch":
                theClip = theTrack.getClipsModelById(slot).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
                if theClip.audioSource:
                    theClip.audioSource.setGainAbsolute(np.interp(params[0], (0, 127), (0, 1)))
            elif theTrack.audioTypeKey() == "external":
                # TODO Should we be sending something out for external tracks? Is there anything reasonable for this? probably control 7 (channel volume)? (cc 0x07 for MSB and 0x27 for LSB)
                pass
            sendCuiaEventFeedback = False
        elif cuia == "SET_SLOT_PAN":
            theTrack = self.sketchpad.song.channelsModel.getChannel(track)
            if theTrack.audioTypeKey() == "synth":
                synthIndex = theTrack.chainedSounds[slot]
                if synthIndex > -1:
                    theTrack.set_passthroughValue("synthPassthrough", slot, "panAmount", np.interp(params[0], (0, 127), (-1, 1)))
            elif theTrack.audioTypeKey() == "sample":
                sample = theTrack.samples[slot]
                if sample.audioSource:
                    sample.audioSource.setPan(np.interp(params[0], (0, 127), (-1, 1)))
            elif theTrack.audioTypeKey() == "sketch":
                theClip = theTrack.getClipsModelById(slot).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
                if theClip.audioSource:
                    theClip.audioSource.setPanAbsolute(np.interp(params[0], (0, 127), (-1, 1)))
            elif theTrack.audioTypeKey() == "external":
                # TODO Should we be sending something out for external tracks? Is there anything reasonable for this? probably control 7 (channel volume)? (cc 0x07 for MSB and 0x27 for LSB)
                pass
            sendCuiaEventFeedback = False
        elif cuia == "SET_SLOT_FILTER_CUTOFF":
            theTrack = self.sketchpad.song.channelsModel.getChannel(track)
            if theTrack.trackType == "synth":
                # TODO We need to capture these controllers' changes elsewhere, so we can feed them back however and whenever they change...
                controller = root.selectedChannel.get_filterCutoffControllers()[slot]
                if controller != None and controller.controlsCount > 0:
                    controller.value = np.interp(params[0], (0, 127), (controller.value_min, controller.value_max))
            elif theTrack.trackType == "sample-trig":
                pass
            elif theTrack.trackType == "sample-loop":
                pass
            else:
                # TODO Probably offer some way to set what CC this changes externally?
                pass
        elif cuia == "SET_SLOT_FILTER_RESONANCE":
            theTrack = self.sketchpad.song.channelsModel.getChannel(track)
            if theTrack.trackType == "synth":
                # TODO We need to capture these controllers' changes elsewhere, so we can feed them back however and whenever they change...
                controller = root.selectedChannel.get_filterResonanceControllers()[slot]
                if controller != None and controller.controlsCount > 0:
                    controller.value = np.interp(params[0], (0, 127), (controller.value_min, controller.value_max))
            elif theTrack.trackType == "sample-trig":
                pass
            elif theTrack.trackType == "sample-loop":
                pass
            else:
                # TODO Probably offer some way to set what CC this changes externally?
                pass
        elif cuia == "SET_FX_AMOUNT":
            theTrack = self.sketchpad.song.channelsModel.getChannel(track)
            if theTrack.chainedFx[slot]:
                theTrack.set_passthroughValue("fxPassthrough", slot, "dryWetMixAmount", np.interp(params[0], (0, 127), (0, 2)))
            sendCuiaEventFeedback = False
        elif cuia == "SET_TRACK_AND_CLIP_CURRRENT_RELATIVE":
            trackSlotDivisor = 128.0 / float(Zynthbox.Plugin.instance().sketchpadSlotCount() * Zynthbox.Plugin.instance().sketchpadTrackCount())
            cumulativeSlot = params[0] / trackSlotDivisor
            theTrackIndex = floor(cumulativeSlot / Zynthbox.Plugin.instance().sketchpadSlotCount())
            theSlotIndex = cumulativeSlot - (theTrackIndex * Zynthbox.Plugin.instance().sketchpadSlotCount())
            self.sketchpad.set_selected_track_id( max(0, min(theTrackIndex, Zynthbox.Plugin.instance().sketchpadTrackCount() - 1)), shouldEmitCurrentTrackClipCUIAFeedback=False)
            theTrack = self.sketchpad.song.channelsModel.getChannel(track)
            theTrack.set_selected_clip(max(0, min(theSlotIndex, Zynthbox.Plugin.instance().sketchpadSlotCount() - 1)), shouldEmitCurrentClipCUIAFeedback=False)
            self.sketchpad.emitCurrentTrackClipCUIAFeedback()
            sendCuiaEventFeedback = False

        # Finally, report back to MidiRouter that we've handled the action
        if sendCuiaEventFeedback == True:
            Zynthbox.MidiRouter.instance().cuiaEventFeedback(cuia, originId, Zynthbox.ZynthboxBasics.Track(track), Zynthbox.ZynthboxBasics.Slot(slot), params[0])

    def custom_switch_ui_action(self, i, t):
        try:
            if t in zynthian_gui_config.custom_switch_ui_actions[i]:
                # logging.info("Executing CUIA action: {}".format(zynthian_gui_config.custom_switch_ui_actions[i]))
                self.callable_ui_action(
                    zynthian_gui_config.custom_switch_ui_actions[i][t]
                )
        except Exception as e:
            logging.error(f"Error occurred while attempting to call a cuia action: {e}")

    # -------------------------------------------------------------------
    # Switches
    # -------------------------------------------------------------------

    # Init GPIO Switches
    def zynswitches_init(self):
        if not lib_zyncore: return
        logging.info("INIT {} ZYNSWITCHES ...".format(zynthian_gui_config.num_zynswitches))
        ts=datetime.now()
        self.dtsw = [ts] * (zynthian_gui_config.num_zynswitches + 4)

    def zynswitches_midi_setup(self, curlayer_chan=None):
        # logging.info("MIDI SWITCHES SETUP...")

        # Configure Custom Switches
        for i in range(0, zynthian_gui_config.n_custom_switches):
            swi = 4 + i
            event = zynthian_gui_config.custom_switch_midi_events[i]
            if event is not None:
                if event["chan"] is not None:
                    midi_chan = event["chan"]
                else:
                    midi_chan = curlayer_chan

                if midi_chan is not None:
                    lib_zyncoder.setup_zynswitch_midi(
                        swi, event["type"], midi_chan, event["num"]
                    )
                    logging.info(
                        "MIDI ZYNSWITCH {}: {} CH#{}, {}".format(
                            swi, event["type"], midi_chan, event["num"]
                        )
                    )
                else:
                    lib_zyncoder.setup_zynswitch_midi(swi, 0, 0, 0)
                    logging.info("MIDI ZYNSWITCH {}: DISABLED!".format(swi))

        # Configure Zynaptik Analog Inputs (CV-IN)
        for i, event in enumerate(zynthian_gui_config.zynaptik_ad_midi_events):
            if event is not None:
                if event["chan"] is not None:
                    midi_chan = event["chan"]
                else:
                    midi_chan = curlayer_chan

                if midi_chan is not None:
                    lib_zyncoder.setup_zynaptik_cvin(
                        i, event["type"], midi_chan, event["num"]
                    )
                    logging.info(
                        "ZYNAPTIK CV-IN {}: {} CH#{}, {}".format(
                            i, event["type"], midi_chan, event["num"]
                        )
                    )
                else:
                    lib_zyncoder.disable_zynaptik_cvin(i)
                    logging.info("ZYNAPTIK CV-IN {}: DISABLED!".format(i))

        # Configure Zyntof Inputs (Distance Sensor)
        for i, event in enumerate(zynthian_gui_config.zyntof_midi_events):
            if event is not None:
                if event["chan"] is not None:
                    midi_chan = event["chan"]
                else:
                    midi_chan = curlayer_chan

                if midi_chan is not None:
                    lib_zyncoder.setup_zyntof(
                        i, event["type"], midi_chan, event["num"]
                    )
                    logging.info(
                        "ZYNTOF {}: {} CH#{}, {}".format(
                            i, event["type"], midi_chan, event["num"]
                        )
                    )
                else:
                    lib_zyncoder.disable_zyntof(i)
                    logging.info("ZYNTOF {}: DISABLED!".format(i))

    def zynswitches(self):
        if not lib_zyncoder: return
        last_zynswitch_index = lib_zyncoder.get_last_zynswitch_index()
        i = 0

        while i<=last_zynswitch_index:
            dtus = lib_zyncoder.get_zynswitch(i, zynthian_gui_config.zynswitch_long_us)

            if self.is_external_app_active():
                if dtus == 0:
                    if self.fake_key_event_for_zynswitch(i, True):
                        return
                elif dtus > 0:
                    if self.fake_key_event_for_zynswitch(i, False):
                        return
            elif dtus == 0:
                # logging.error("key press: {} {}".format(i, dtus))

                if 5 <= i <= 9:
                    # If * button is pressed, it toggles itself on/off for 5000ms before returning to previous state.
                    # When 1-5 hw button is pressed during that 5000ms, * button state is retained and hence stop timer.
                    QMetaObject.invokeMethod(self.tracksModTimer, "stop", Qt.QueuedConnection)

                # Handle button press event
                if i == 4:
                    self.menuButtonPressed = True
                elif i == 10:
                    self.switchChannelsButtonPressed = True
                elif i == 11:
                    self.modeButtonPressed = True
                elif i == 17:
                    self.altButtonPressed = True
                elif i == 18:
                    self.startRecordButtonPressed = True
                elif i == 19:
                    self.playButtonPressed = True
                elif i == 20:
                    self.metronomeButtonPressed = True
                elif i == 21:
                    self.stopButtonPressed = True
                elif i == 22:
                    self.backButtonPressed = True
                elif i == 23:
                    self.upButtonPressed = True
                elif i == 24:
                    self.selectButtonPressed = True
                elif i == 25:
                    self.leftButtonPressed = True
                elif i == 26:
                    self.downButtonPressed = True
                elif i == 27:
                    self.rightButtonPressed = True
                elif i == 28:
                    self.globalButtonPressed = True
                elif i == 31: # KNOB_0
                    self.knob0Touched = True
                elif i == 30: # KNOB_1
                    self.knob1Touched = True
                elif i == 32: # KNOB_2
                    self.knob2Touched = True
                elif i == 33: # KNOB_3 (big knob)
                    self.knob3Touched = True

                if self.fake_key_event_for_zynswitch(i, True):
                    return
            elif dtus > 0:
                # logging.error("key release: {} {}".format(i, dtus))

                # Handle button release event
                if i == 4:
                    self.menuButtonPressed = False
                elif i == 10:
                    self.switchChannelsButtonPressed = False
                elif i == 11:
                    self.modeButtonPressed = False
                elif i == 17:
                    self.altButtonPressed = False
                elif i == 18:
                    self.startRecordButtonPressed = False
                elif i == 19:
                    self.playButtonPressed = False
                elif i == 20:
                    if self.__start_playback_on_metronome_release:
                        self.__start_playback_on_metronome_release = False
                        Zynthbox.SyncTimer.instance().startWithCountin()
                    self.metronomeButtonPressed = False
                elif i == 21:
                    self.stopButtonPressed = False
                elif i == 22:
                    self.backButtonPressed = False
                elif i == 23:
                    self.upButtonPressed = False
                elif i == 24:
                    self.selectButtonPressed = False
                elif i == 25:
                    self.leftButtonPressed = False
                elif i == 26:
                    self.downButtonPressed = False
                elif i == 27:
                    self.rightButtonPressed = False
                elif i == 28:
                    self.globalButtonPressed = False
                elif i == 31: # KNOB_0
                    self.knob0Touched = False
                elif i == 30: # KNOB_1
                    self.knob1Touched = False
                elif i == 32: # KNOB_2
                    self.knob2Touched = False
                elif i == 33: # KNOB_3 (big knob)
                    self.knob3Touched = False

                if self.fake_key_event_for_zynswitch(i, False):
                    return


            if not self.is_external_app_active():
                # Do not handle idle state
                if dtus <= 0:
                    pass
                else:
                    if dtus>zynthian_gui_config.zynswitch_long_us:
                        self.zynswitch_long_triggered.emit(i)
                    elif dtus>zynthian_gui_config.zynswitch_bold_us:
                        # Double switches must be bold!!! => by now ...
                        if not self.zynswitch_double(i):
                            self.zynswitch_bold_triggered.emit(i)
                    elif dtus>0:
                        #print("Switch "+str(i)+" dtus="+str(dtus))
                        self.zynswitch_short_triggered.emit(i)
            i += 1;

        self.fake_key_event_for_zynpot(3, Key.left, Key.right)

    zynswitch_short_triggered = Signal(int)
    zynswitch_long_triggered = Signal(int)
    zynswitch_bold_triggered = Signal(int)

    def fake_key_event_for_zynpot(self, npot, key_left, key_right):
        bk_value = zyncoder.lib_zyncoder.get_value_zynpot(npot)
        delta = 0
        if self.__bk_last_turn_time != None and self.__bk_last_turn_time > 0:
            delta = time.time() * 1000 - self.__bk_last_turn_time
        if self.is_external_app_active() and self.__old_bk_value != bk_value:
            fake_key = None
            if self.__old_bk_value > bk_value:
                fake_key = key_left
            else:
                fake_key = key_right
            if fake_key != self.__bk_fake_key and self.__bk_fake_key != None:
                self.fakeKeyboard.release(self.__bk_fake_key)
                self.__bk_fake_key = None
            elif self.__bk_fake_key != None:
                self.fakeKeyboard.press(fake_key)
            self.__bk_fake_key = fake_key
            if bk_value == 0 or bk_value >= 40:
                zyncoder.lib_zyncoder.set_value_zynpot(npot, 20, 1)
                self.__old_bk_value = bk_value = 20
            self.__bk_last_turn_time = time.time() * 1000
        elif delta > 50 and self.__bk_fake_key != None:
            self.fakeKeyboard.release(self.__bk_fake_key)
            self.__bk_fake_key = None
            self.__bk_last_turn_time = None
        elif self.is_external_app_active() and bk_value == 0 and self.__old_bk_value == 0:
            zyncoder.lib_zyncoder.set_value_zynpot(npot, 20, 1)
            self.__old_bk_value = bk_value = 20

        self.__old_bk_value = bk_value;


    def fake_key_event_for_zynswitch(self, i : int, press : bool):
        fake_key = None

        # ALT
        if hasattr(zynthian_gui_config, 'top') and zynthian_gui_config.top.isActive() == False and i == 17:
            fake_key = Key.space

        # NAV CLUSTER
        if i == 23:
            fake_key = Key.up
        elif i == 26:
            fake_key = Key.down
        elif i == 25:
            fake_key = Key.left
        elif i == 27:
            fake_key = Key.right
        elif i == 24:
            fake_key = Key.enter
        elif i == 22:
            fake_key = Key.esc
        # Channel buttons
        elif i == 5:
            fake_key = "1"
        elif i == 6:
            fake_key = "2"
        elif i == 7:
            fake_key = "3"
        elif i == 8:
            fake_key = "4"
        elif i == 9:
            fake_key = "5"

        # Disable emitting key 6 as it will act as modifier
        # elif i == 10:
        #     fake_key = "6"
        #F1 .. F5
        elif i == 12:
            fake_key = Key.f1
        elif i == 13:
            fake_key = Key.f2
        elif i == 14:
            fake_key = Key.f3
        elif i == 15:
            fake_key = Key.f4
        elif i == 16:
            fake_key = Key.f5

        if fake_key == None:
            return False

        if press:
            if not fake_key in self.__fake_keys_pressed:
                # Do not emulate Ctrl key with tracksModActive
                # if self.tracksModActive:
                #     self.fakeKeyboard.press(Key.ctrl)

                self.__fake_keys_pressed.add(fake_key)
                self.fakeKeyboard.press(fake_key)
        else:
            if fake_key in self.__fake_keys_pressed:
                # Do not emulate Ctrl key with tracksModActive
                # if self.tracksModActive:
                #     self.fakeKeyboard.release(Key.ctrl)

                self.__fake_keys_pressed.discard(fake_key)
                self.fakeKeyboard.release(fake_key)

        return True


    def zynswitch_long(self, i):
        # logging.info("Looooooooong Switch " + str(i))
        # Disabling ald loong presses for the moment
        return
        #self.start_loading()

        # Standard 4 ZynSwitches
        if i == 0:
            pass

        elif i == 1:
            # self.callable_ui_action("ALL_OFF")
            self.show_modal("admin")

        elif i == 2:
            self.show_modal("alsa_mixer")

        elif i == 3:
            self.screens["admin"].power_off()

        # Custom ZynSwitches
        elif i >= 4:
            self.custom_switch_ui_action(i - 4, "L")

        #self.stop_loading()

    def zynswitch_bold(self, i):
        # logging.info("Bold Switch " + str(i))
        #self.start_loading()

        if self.modal_screen in ["stepseq", "keyboard"]:
            self.stop_loading()
            if self.screens[self.modal_screen].switch(i, "B"):
                return

        # Standard 4 ZynSwitches
        if i == 0:
            if (
                self.active_screen == "layer"
                and self.modal_screen != "stepseq"
            ):
                self.show_modal("stepseq")
            else:
                if self.active_screen == "preset":
                    self.screens["preset"].restore_preset()
                self.show_screen("layer")

        elif i == 1:
            if self.modal_screen:
                logging.debug("CLOSE MODAL => " + self.modal_screen)
                self.show_screen(self.__home_screen)

            elif self.active_screen == "preset":
                self.screens["preset"].restore_preset()
                self.show_screen("control")

            elif (
                self.active_screen in [self.__home_screen, "admin"]
                and len(self.screens["layer"].layers) > 0
            ):
                self.show_control()

            else:
                self.show_screen(self.__home_screen)

        elif i == 2:
            self.load_snapshot()

        elif i == 3:
            if self.modal_screen:
                self.screens[self.modal_screen].switch_select("B")
            else:
                self.screens[self.active_screen].switch_select("B")

        # Custom ZynSwitches
        elif i >= 4:
            self.custom_switch_ui_action(i - 4, "B")

        #self.stop_loading()

    def zynswitch_short(self, i):
        # logging.info("Short Switch " + str(i))
        if self.modal_screen in ["stepseq"]:
            if self.screens[self.modal_screen].switch(i, "S"):
                return

        #if i != 1:  # HACK to not show loading screen when just going back
            #self.start_loading()

        # Standard 4 ZynSwitches
        if i == 0:
            if (
                self.active_screen == "control"
                or self.modal_screen == "alsa_mixer"
            ):
                if self.screens["layer"].get_num_root_layers() > 1:
                    logging.info("Next layer")
                    self.screens["layer"].next(True)
                else:
                    self.show_screen("layer")

            elif self.active_screen == "layer":
                if self.modal_screen is not None:
                    self.show_screen("layer")
                elif self.screens["layer"].get_num_root_layers() > 1:
                    logging.info("Next layer")
                    self.screens["layer"].next(False)

            else:
                if self.active_screen == "preset":
                    self.screens["preset"].restore_preset()
                self.show_screen("layer")

        elif i == 1:
            screen_back = None
            if  self.__forced_screen_back != None and self.__forced_screen_back != "":
                if self.__forced_screen_back in self.non_modal_screens:
                    self.show_screen(self.__forced_screen_back)
                else:
                    self.show_modal(self.__forced_screen_back)
                self.__forced_screen_back = None
                return
            # If modal screen ...
            if self.modal_screen:
                logging.debug("CLOSE MODAL => " + self.modal_screen)

                # Try to call modal back_action method:
                try:
                    screen_back = self.screens[self.modal_screen].back_action()
                    logging.debug("SCREEN BACK => " + screen_back)
                except:
                    pass

                # Back to home screen or modal
                if screen_back is None:
                    if self.modal_screen_back:
                        screen_back = self.modal_screen_back
                    elif self.active_screen == "main": #HACK
                        screen_back = self.__home_screen
                    else:
                        screen_back = self.active_screen #self.__home_screen #FIXME: it was self.active_screen should be somewhat configurable

            else:
                try:
                    screen_back = self.screens[
                        self.active_screen
                    ].back_action()
                except:
                    pass

                # Back to screen-1 by default ...
                if screen_back is None:
                    j = self.screens_sequence.index(self.active_screen) - 1
                    if j < 0:
                        if (
                            len(self.screens["layer"].layers) > 0
                            and self.curlayer
                        ):
                            j = len(self.screens_sequence) - 1
                        else:
                            j = 0
                    screen_back = self.screens_sequence[j]

            # TODO: this code is disabled to have a more predictable back navigation, is a good choice? how to make it depend only from qml part?
            # If there is only one preset, go back to bank selection
            #if screen_back == "preset" and len(self.curlayer.preset_list) <= 1:
                #screen_back = "bank"

            ## If there is only one bank, go back to layer selection
            #if screen_back == "bank" and len(self.curlayer.bank_list) <= 1:
                #screen_back = "layer"

            if screen_back:
                logging.debug("BACK TO SCREEN => {}".format(screen_back))
                if screen_back in self.non_modal_screens:
                    self.show_screen(screen_back)
                else:
                    self.show_modal(screen_back)
                    self.modal_screen_back = None

        elif i == 2:
            if self.modal_screen == "snapshot":
                self.screens["snapshot"].next()
            elif (
                self.active_screen == "control"
                or self.modal_screen == "alsa_mixer"
            ) and self.screens["control"].mode == "control":
                if self.midi_learn_mode or self.midi_learn_zctrl:
                    if self.modal_screen == "zs3_learn":
                        self.show_screen("control")
                    elif zynthian_gui_config.midi_prog_change_zs3:
                        self.show_modal("zs3_learn")
                else:
                    self.enter_midi_learn_mode()

            elif len(self.screens["layer"].layers) > 0:
                self.enter_midi_learn_mode()
                self.show_modal("zs3_learn")

            else:
                self.load_snapshot()

        elif i == 3:
            if self.modal_screen:
                self.screens[self.modal_screen].switch_select("S")
            else:
                self.screens[self.active_screen].switch_select("S")

        # Custom ZynSwitches
        elif i >= 4:
            self.custom_switch_ui_action(i - 4, "S")

        #self.stop_loading()

    def zynswitch_push(self,i):
        logging.info('Push Switch '+str(i))
        self.start_loading()

        # Standard 4 ZynSwitches
        if i>=0 and i<=3:
            pass

        # Custom ZynSwitches
        elif i>=4:
            self.custom_switch_ui_action(i-4, "P")

        self.stop_loading()

    def zynswitch_double(self, i):
        if not i in self.dtsw: return
        self.dtsw[i] = datetime.now()
        for j in range(4):
            if j == i:
                continue
            if abs((self.dtsw[i] - self.dtsw[j]).total_seconds()) < 0.3:
                self.start_loading()
                dswstr = str(i) + "+" + str(j)
                logging.info("Double Switch " + dswstr)
                # self.show_control_xy(i,j)
                self.show_screen("control")
                self.screens["control"].set_xyselect_mode(i, j)
                self.stop_loading()
                return True

    def zynswitch_X(self, i):
        logging.info("X Switch %d" % i)
        if (
            self.active_screen == "control"
            and self.screens["control"].mode == "control"
        ):
            self.screens["control"].midi_learn(i)

    def zynswitch_Y(self, i):
        logging.info("Y Switch %d" % i)
        if (
            self.active_screen == "control"
            and self.screens["control"].mode == "control"
        ):
            self.screens["control"].midi_unlearn(i)

    # ------------------------------------------------------------------
    # Switch Defered Event
    # ------------------------------------------------------------------

    def zynswitch_defered(self, t, i):
        self.zynswitch_defered_event = (t, i)

    def zynswitch_defered_exec(self):
        if self.zynswitch_defered_event is not None:
            # Copy event and clean variable
            event = copy.deepcopy(self.zynswitch_defered_event)
            self.zynswitch_defered_event = None
            # Process event
            if event[0] == "S":
                self.zynswitch_short(event[1])
            elif event[0] == "B":
                self.zynswitch_bold(event[1])
            elif event[0] == "L":
                self.zynswitch_long(event[1])
            elif event[0] == "X":
                self.zynswitch_X(event[1])
            elif event[0] == "Y":
                self.zynswitch_Y(event[1])

    # ------------------------------------------------------------------
    # Threads
    # ------------------------------------------------------------------

    def start_zyncoder_thread(self):
        if lib_zyncoder:
            self.zyncoder_thread = Thread(
                target=self.zyncoder_thread_task, args=()
            )
            self.zyncoder_thread.daemon = True  # thread dies with the program
            self.zyncoder_thread.start()

    def zyncoder_thread_task(self):
        while not self.exit_flag:
            # Do not read zyncoder values when booting is in progress
            if self.isBootingComplete and not self.zynread_wait_flag: # FIXME: poor man's mutex? actually works only with this one FIXME: REVERT
                self.zyncoder_read()
                self.zynmidi_read()
                self.osc_receive()
                self.plot_zctrls()
                time.sleep(0.04)
            else:
                time.sleep(0.3)
            # if self.zynread_wait_flag:
            # time.sleep(0.3)
            # self.zynread_wait_flag=False

    def zyncoder_read(self):
        try:
            # Read Zyncoders
            self.lock.acquire()

            # Calculate delta and emit
            for knob_index in [0, 1, 2, 3]:
                try:
                    if self.__zselectors[knob_index]:
                        self.__zselectors[knob_index].read_zyncoder()

                        value_change = self.__zselectors[knob_index].value - self.__knob_values[knob_index]
                        # Use floor/ceil as per knob change direction to produce similar effect for both increasing and decreasing values with knobs
                        if value_change > 0:
                            delta = math.floor(value_change / self.__knob_delta_factors[knob_index])
                        else:
                            delta = math.ceil(value_change / self.__knob_delta_factors[knob_index])

                        if delta != 0:
                            self.knobDeltaChanged.emit(knob_index, delta)
                            # If knob value is close to extreme points then do reset immediately. Otherwise defer resetting until required
                            if self.__zselectors[knob_index].value - self.__knob_delta_factors[knob_index] < 0 or \
                                    self.__zselectors[knob_index].value + self.__knob_delta_factors[knob_index] > self.__knob_values_max[knob_index]:
                                self.__zselectors[knob_index].set_value(self.__knob_values_default[knob_index], True)
                                self.__knob_values[knob_index] = self.__knob_values_default[knob_index]
                            else:
                                self.__knob_values[knob_index] = self.__zselectors[knob_index].value
                except Exception as e:
                    logging.exception(f"Error reading zyncoder value : {str(e)}")

            self.lock.release()

            # Zynswitches
            self.zynswitch_defered_exec()
            self.zynswitches()

        except Exception as err:
            self.reset_loading()
            logging.exception(err)

        # Run autoconnect if needed
        self.zynautoconnect_do()

    def zynmidi_read(self):
        try:
            while lib_zyncoder:
                ev = lib_zyncoder.read_zynmidi()
                if ev == 0:
                    break

                evtype = (ev & 0xF00000) >> 20
                chan = (ev & 0x0F0000) >> 16

                if evtype == 0xF and chan == 0x8:
                    self.status_info["midi_clock"] = True
                else:
                    self.status_info["midi"] = True

                # logging.info("MIDI_UI MESSAGE: {}".format(hex(ev)))
                # logging.info("MIDI_UI MESSAGE DETAILS: {}, {}".format(chan,evtype))

                # System Messages
                if zynthian_gui_config.midi_sys_enabled and evtype == 0xF:
                    # Song Position Pointer...
                    if chan == 0x1:
                        timecode = (ev & 0xFF) >> 8
                    elif chan == 0x2:
                        pos = ev & 0xFFFF
                    # Song Select...
                    elif chan == 0x3:
                        song_number = (ev & 0xFF) >> 8
                    # Timeclock
                    elif chan == 0x8:
                        pass
                    # MIDI tick
                    elif chan == 0x9:
                        pass
                    # Start
                    elif chan == 0xA:
                        pass
                    # Continue
                    elif chan == 0xB:
                        pass
                    # Stop
                    elif chan == 0xC:
                        pass
                    # Active Sensing
                    elif chan == 0xE:
                        pass
                    # Reset
                    elif chan == 0xF:
                        pass

                # Master MIDI Channel ...
                elif chan == zynthian_gui_config.master_midi_channel:
                    logging.info("MASTER MIDI MESSAGE: %s" % hex(ev))
                    self.start_loading()
                    # Webconf configured messages for Snapshot Control ...
                    if ev == zynthian_gui_config.master_midi_program_change_up:
                        logging.debug("PROGRAM CHANGE UP!")
                        self.screens["snapshot"].midi_program_change_up()
                    elif (
                        ev
                        == zynthian_gui_config.master_midi_program_change_down
                    ):
                        logging.debug("PROGRAM CHANGE DOWN!")
                        self.screens["snapshot"].midi_program_change_down()
                    elif ev == zynthian_gui_config.master_midi_bank_change_up:
                        logging.debug("BANK CHANGE UP!")
                        self.screens["snapshot"].midi_bank_change_up()
                    elif (
                        ev == zynthian_gui_config.master_midi_bank_change_down
                    ):
                        logging.debug("BANK CHANGE DOWN!")
                        self.screens["snapshot"].midi_bank_change_down()
                    # Program Change => Snapshot Load
                    elif evtype == 0xC:
                        pgm = (ev & 0x7F00) >> 8
                        logging.debug("PROGRAM CHANGE %d" % pgm)
                        self.screens["snapshot"].midi_program_change(pgm)
                    # Control Change ...
                    elif evtype == 0xB:
                        ccnum = (ev & 0x7F00) >> 8
                        if (
                            ccnum
                            == zynthian_gui_config.master_midi_bank_change_ccnum
                        ):
                            bnk = ev & 0x7F
                            logging.debug("BANK CHANGE %d" % bnk)
                            self.screens["snapshot"].midi_bank_change(bnk)
                        elif ccnum == 120:
                            self.all_sounds_off()
                        elif ccnum == 123:
                            self.all_notes_off()
                    # Note-on => CUIA
                    elif evtype == 0x9:
                        note = str((ev & 0x7F00) >> 8)
                        vel = ev & 0x007F
                        if vel != 0 and note in self.note2cuia:
                            self.callable_ui_action(
                                self.note2cuia[note], [vel]
                            )

                    # Run autoconnect (if needed) and stop logo animation
                    self.zynautoconnect_do()
                    self.stop_loading()

                # Program Change ...
                elif evtype == 0xC:
                    pgm = (ev & 0x7F00) >> 8
                    logging.info(
                        "MIDI PROGRAM CHANGE: CH{} => {}".format(chan, pgm)
                    )

                    # SubSnapShot (ZS3) MIDI learn ...
                    if (
                        self.midi_learn_mode
                        and self.modal_screen == "zs3_learn"
                    ):
                        if self.screens["layer"].save_midi_chan_zs3(chan, pgm):
                            logging.info(
                                "ZS3 Saved: CH{} => {}".format(chan, pgm)
                            )
                            self.exit_midi_learn_mode()

                    # Set Preset or ZS3 (sub-snapshot), depending of config option
                    else:
                        if zynthian_gui_config.midi_prog_change_zs3:
                            self.screens["layer"].set_midi_chan_zs3(chan, pgm)
                        else:
                            self.screens["layer"].set_midi_chan_preset(
                                chan, pgm
                            )

                        # if not self.modal_screen and self.curlayer and chan==self.curlayer.get_midi_chan():
                        #     self.show_screen('control')


                # Note-Off ...
                elif evtype == 0x8:
                    self.screens["midi_chan"].midi_chan_activity(chan)
                    note = (ev & 0x7F00) >> 8
                    self.__notes_on = list(filter(lambda a: a != note, self.__notes_on))
                    self.last_note_changed.emit()

                # Note-On ...
                elif evtype == 0x9:
                    self.screens["midi_chan"].midi_chan_activity(chan)
                    # Preload preset (note-on)
                    if (
                        self.curlayer
                        and zynthian_gui_config.preset_preload_noteon
                        and self.active_screen == "preset"
                        and chan == self.curlayer.get_midi_chan()
                    ):
                        self.start_loading()
                        self.screens["preset"].preselect_action()
                        self.stop_loading()

                    note = (ev & 0x7F00) >> 8
                    if not note in self.__notes_on:
                        self.__notes_on.append(note)
                        self.last_note_changed.emit()
                    # Note Range Learn
                    if self.modal_screen == "midi_key_range":
                        self.screens["midi_key_range"].learn_note_range(note)

                # Control Change ...
                elif evtype == 0xB:
                    self.screens["midi_chan"].midi_chan_activity(chan)
                    ccnum = (ev & 0x7F00) >> 8
                    ccval = ev & 0x007F
                    # logging.debug("MIDI CONTROL CHANGE: CH{}, CC{} => {}".format(chan,ccnum,ccval))
                    # If MIDI learn pending ...
                    if self.midi_learn_zctrl:
                        self.midi_learn_zctrl.cb_midi_learn(chan, ccnum)
                    # Try layer's zctrls
                    else:
                        self.screens["layer"].midi_control_change(
                            chan, ccnum, ccval
                        )

        except Exception as err:
            self.reset_loading()
            logging.exception(err)

    def plot_zctrls(self):
        try:
            if self.modal_screen:
                self.screens[self.modal_screen].plot_zctrls()
            else:
                self.screens[self.active_screen].plot_zctrls()
        except AttributeError:
            pass
        except Exception as e:
            logging.error(e)

    def cpu_status_refresh(self, cpu_status_info_undervoltage, cpu_status_info_overtemp):
        watchdog_process = Popen(["python3", "cpu_watchdog.py"])
        watchdog_fifo = None
        while not self.exit_flag:
            # Do not refresh when booting is in progress
            if self.isBootingComplete and zynthian_gui_config.show_cpu_status:
                try:
                    if watchdog_fifo is None:
                        watchdog_fifo = open("/tmp/cpu_watchdog", "r")

                    data = ""
                    while True:
                        data = self.__boot_log_file.readline()[:-1].strip()
                        if len(data) == 0:
                            break
                        else:
                            if data.startswith("overtemp"):
                                splitData = data.split(" ")
                                if splitData[1] == "True":
                                    cpu_status_info_overtemp.set()
                                else:
                                    cpu_status_info_overtemp.clear()
                            if data.startswith("undervoltage"):
                                splitData = data.split(" ")
                                if splitData[1] == "True":
                                    cpu_status_info_undervoltage.set()
                                else:
                                    cpu_status_info_undervoltage.clear()

                except Exception as e:
                    logging.error(e)
            time.sleep(0.3)
        if watchdog_fifo is not None:
            watchdog_fifo.close()
        if watchdog_process is not None:
            watchdog_process.kill()

    def bootsplash_worker(self):
        bootsplash_fifo = None
        if not Path("/tmp/bootlog.fifo").exists():
            os.mkfifo("/tmp/bootlog.fifo")
        while not self.exit_flag:
            try:
                if bootsplash_fifo is None:
                    bootsplash_fifo = os.open("/tmp/bootlog.fifo", os.O_WRONLY)

                bootsplashEntry = recent_task_messages.get()
                if len(bootsplashEntry) > 0:
                    os.write(bootsplash_fifo, f"{bootsplashEntry}\n".encode())
            except Exception as e:
                logging.error(e)

    def start_loading_thread(self):
        self.loading_thread = Thread(target=self.loading_refresh, args=())
        self.loading_thread.daemon = True  # thread dies with the program
        self.loading_thread.start()

    @Slot(None)
    def start_loading(self):
        self.loading = self.loading + 1
        if self.loading < 1:
            self.loading = 1
        self.currentTaskMessage = "Please wait"
        recent_task_messages.put("command:show")
        self.is_loading_changed.emit()
        QGuiApplication.instance().processEvents()
        # logging.debug("START LOADING %d" % self.loading)

    @Slot(None)
    def stop_loading(self):
        self.loading = self.loading - 1
        if self.loading < 0:
            self.loading = 0

        if self.loading == 0:
            if self.__long_task_count__ == 0:
                recent_task_messages.put("command:hide")
            self.is_loading_changed.emit()
            QGuiApplication.instance().processEvents()
        # logging.debug("STOP LOADING %d" % self.loading)

    def reset_loading(self):
        if self.__long_task_count__ == 0:
            recent_task_messages.put("command:hide")
        self.loading = 0
        self.is_loading_changed.emit()
        QGuiApplication.instance().processEvents()

    def get_is_loading(self):
        return self.loading > 0

    def get_grainerator_enabled(self):
        return "grainerator" in zynthian_gui_config.experimental_features

    # FIXME: is this necessary?
    def loading_refresh(self):
        while not self.exit_flag:
            # Do not refresh when booting is in progress
            if self.isBootingComplete:
                try:
                    if self.modal_screen:
                        self.screens[self.modal_screen].refresh_loading()
                    else:
                        self.screens[self.active_screen].refresh_loading()
                except Exception as err:
                    logging.error("zynthian_gui.loading_refresh() => %s" % err)
            time.sleep(0.1)

    def wait_threads_end(self, n=20):
        logging.debug("Awaiting threads to end ...")

        while (
            self.loading_thread.is_alive()
            or self.zyncoder_thread.is_alive()
            or zynautoconnect.is_running()
        ) and n > 0:
            time.sleep(0.1)
            n -= 1

        if n <= 0:
            logging.info(
                "Reached maximum count while awaiting threads to end!"
            )
            return False
        else:
            logging.debug(
                "Remaining {} active threads...".format(
                    threading.active_count()
                )
            )
            time.sleep(0.5)
            return True

    def exit(self, code=0):
        self.exit_flag = True
        self.exit_code = code

    @Slot(str, result=bool)
    def file_exists(self, file_path):
        return os.path.isfile(file_path)

    # ------------------------------------------------------------------
    # Polling
    # ------------------------------------------------------------------

    def start_polling(self):
        self.polling = True
        self.polling_timer.start()
        self.zyngine_refresh()
        self.refresh_status()

    def stop_polling(self):
        self.polling = False
        self.polling_timer.stop()

    def polling_timer_expired(self):
        self.zyngine_refresh()
        self.refresh_status()
        # logging.error("refreshed status")

    # FIXME: is this actually used?
    def after(self, msec, func):
        QTimer.singleShot(msec, func)

    def zyngine_refresh(self):
        try:
            # Capture exit event and finish
            if self.exit_flag:
                self.isShuttingDown = True
                self.stop()
                self.wait_threads_end()
                logging.info("EXITING ZYNTHIAN-UI ...")

                if self.exit_code == 100:
                    Popen(("systemctl", "poweroff"))
                elif self.exit_code == 101:
                    Popen(("reboot"))
                elif self.exit_code == 102:
                    Popen(("systemctl", "restart", "jack2", "zynthbox-qml", "mod-ttymidi"))
                else:
                    Popen(("systemctl", "restart", "jack2", "zynthbox-qml", "mod-ttymidi"))
            # Refresh Current Layer
            elif self.curlayer and not self.loading:
                self.curlayer.refresh()

        except Exception as e:
            self.reset_loading()
            logging.exception(e)

        # Poll
        # if self.polling:
        # QTimer.singleShot(160, self.zyngine_refresh)

    def refresh_status(self):
        if self.exit_flag:
            return

        try:
            if zynthian_gui_config.show_cpu_status:
                # Get CPU Load
                # self.status_info['cpu_load'] = max(psutil.cpu_percent(None, True))
                self.status_info[
                    "cpu_load"
                ] = zynautoconnect.get_jackd_cpu_load()

            # Get Status Flags (once each 5 refreshes)
            if self.status_counter > 5:
                self.status_counter = 0

                if self.cpu_status_info_undervoltage.is_set():
                    self.status_info["undervoltage"] = True
                else:
                    self.status_info["undervoltage"] = False
                if self.cpu_status_info_overtemp.is_set():
                    self.status_info["overtemp"] = True
                else:
                    self.status_info["overtemp"] = False

                try:
                    # Get Recorder Status
                    self.status_info["audio_recorder"] = self.screens[
                        "audio_recorder"
                    ].get_status()

                except Exception as e:
                    logging.error(e)

            else:
                self.status_counter += 1

            # Refresh On-Screen Status
            try:
                self.status_object.set_status(self.status_info)

                if self.modal_screen:
                    self.screens[self.modal_screen].refresh_status(
                        self.status_info
                    )
                elif self.active_screen:
                    self.screens[self.active_screen].refresh_status(
                        self.status_info
                    )
            except AttributeError:
                pass

            # Clean some status_info
            self.status_info["xrun"] = False
            self.status_info["midi"] = False
            self.status_info["midi_clock"] = False

            # if self.polling:
            # QTimer.singleShot(200, self.refresh_status)

        except Exception as e:
            logging.exception(e)

        # Poll
        # if self.polling:
        # QTimer.singleShot(200, self.refresh_status)

    @Slot(str)
    def process_keybinding_shortcut(self, keyseq):
        action = zynthian_gui_keybinding.getInstance().get_key_action(keyseq)

        if action != None:
            zynqtgui.callable_ui_action(action)

    @Slot("void")
    def go_back(self):
        # switch 1 means going back TODO: instead of magic numbers their functions should be moved in slots?
        self.zynswitch_short(1)

    # ------------------------------------------------------------------
    # Engine OSC callbacks => No concurrency!!
    # ------------------------------------------------------------------

    def cb_osc_bank_view(self, path, args):
        pass

    def cb_osc_ctrl(self, path, args):
        # print ("OSC CTRL: " + path + " => "+str(args[0]))
        if path in self.screens["control"].zgui_controllers_map.keys():
            self.screens["control"].zgui_controllers_map[path].set_init_value(
                args[0]
            )

    # ------------------------------------------------------------------
    # All Notes/Sounds Off => PANIC!
    # ------------------------------------------------------------------

    def all_sounds_off(self):
        logging.info("All Sounds Off!")
        Zynthbox.SyncTimer.instance().sendAllSoundsOffEverywhereImmediately()

    def all_notes_off(self):
        logging.info("All Notes Off!")
        Zynthbox.SyncTimer.instance().sendAllNotesOffEverywhereImmediately()

    def raw_all_notes_off(self):
        logging.info("Raw All Notes Off!")
        Zynthbox.SyncTimer.instance().sendAllNotesOffEverywhereImmediately()

    def all_sounds_off_chan(self, track):
        logging.info("All Sounds Off for track {}!".format(track))
        Zynthbox.SyncTimer.instance().sendAllSoundsOffImmediately(track)

    def all_notes_off_chan(self, track):
        logging.info("All Notes Off for track {}!".format(track))
        Zynthbox.SyncTimer.instance().sendAllNotesOffImmediately(track)

    def raw_all_notes_off_chan(self, track):
        logging.info("Raw All Notes Off for track {}!".format(track))
        Zynthbox.SyncTimer.instance().sendAllNotesOffImmediately(track)

    # ------------------------------------------------------------------
    # MPE initialization
    # ------------------------------------------------------------------

    def init_mpe_zones(self, lower_n_chans, upper_n_chans):
        pass
        # Configure Lower Zone
        # if (
        #     not isinstance(lower_n_chans, int)
        #     or lower_n_chans < 0
        #     or lower_n_chans > 0xF
        # ):
        #     logging.error(
        #         "Can't initialize MPE Lower Zone. Incorrect num of channels ({})".format(
        #             lower_n_chans
        #         )
        #     )
        # else:
        #     lib_zyncoder.ctrlfb_send_ccontrol_change(0x0, 0x79, 0x0)
        #     lib_zyncoder.ctrlfb_send_ccontrol_change(0x0, 0x64, 0x6)
        #     lib_zyncoder.ctrlfb_send_ccontrol_change(0x0, 0x65, 0x0)
        #     lib_zyncoder.ctrlfb_send_ccontrol_change(0x0, 0x06, lower_n_chans)
        # 
        # # Configure Upper Zone
        # if (
        #     not isinstance(upper_n_chans, int)
        #     or upper_n_chans < 0
        #     or upper_n_chans > 0xF
        # ):
        #     logging.error(
        #         "Can't initialize MPE Upper Zone. Incorrect num of channels ({})".format(
        #             upper_n_chans
        #         )
        #     )
        # else:
        #     lib_zyncoder.ctrlfb_send_ccontrol_change(0xF, 0x79, 0x0)
        #     lib_zyncoder.ctrlfb_send_ccontrol_change(0xF, 0x64, 0x6)
        #     lib_zyncoder.ctrlfb_send_ccontrol_change(0xF, 0x65, 0x0)
        #     lib_zyncoder.ctrlfb_send_ccontrol_change(0xF, 0x06, upper_n_chans)

    # ------------------------------------------------------------------
    # MIDI learning
    # ------------------------------------------------------------------

    @Slot(QObject)
    def init_midi_learn(self, zctrl):
        self.setMidiLearnZctrl(zctrl)
        lib_zyncoder.set_midi_learning_mode(1)
        self.screens["control"].refresh_midi_bind()
        self.screens["control"].set_select_path()

    @Slot(None)
    def end_midi_learn(self):
        self.setMidiLearnZctrl(None)
        lib_zyncoder.set_midi_learning_mode(0)
        self.screens["control"].refresh_midi_bind()
        self.screens["control"].set_select_path()

    def refresh_midi_learn(self):
        self.screens["control"].refresh_midi_bind()
        self.screens["control"].set_select_path()

    def getMidiLearnZctrl(self):
        return self.midi_learn_zctrl
    def setMidiLearnZctrl(self, zctrl):
        if self.midi_learn_zctrl != zctrl:
            self.midi_learn_zctrl = zctrl
            self.midiLearnZctrlChanged.emit()
    midiLearnZctrlChanged = Signal()
    midiLearnZctrl = Property(QObject,getMidiLearnZctrl, notify=midiLearnZctrlChanged)

    # ------------------------------------------------------------------
    # Autoconnect
    # ------------------------------------------------------------------

    @Slot()
    def zynautoconnect(self, force=False):
        if force:
            zynautoconnect.midi_autoconnect(True)
            zynautoconnect.audio_autoconnect(True)
        else:
            self.zynautoconnect_midi_flag = True
            self.zynautoconnect_audio_flag = True

    def zynautoconnect_midi(self, force=False):
        if force:
            zynautoconnect.midi_autoconnect(True)
        else:
            self.zynautoconnect_midi_flag = True

    def zynautoconnect_audio(self, force=False):
        if force:
            zynautoconnect.audio_autoconnect(True)
        else:
            self.zynautoconnect_audio_flag = True

    def zynautoconnect_do(self):
        if self.zynautoconnect_midi_flag:
            self.zynautoconnect_midi_flag = False
            zynautoconnect.midi_autoconnect(True)

        if self.zynautoconnect_audio_flag:
            self.zynautoconnect_audio_flag = False
            zynautoconnect.audio_autoconnect(True)

    def zynautoconnect_acquire_lock(self):
        # Get Mutex Lock
        zynautoconnect.acquire_lock()

    def zynautoconnect_release_lock(self):
        # Release Mutex Lock
        zynautoconnect.release_lock()

    # ------------------------------------------------------------------
    # Jackd Info
    # ------------------------------------------------------------------

    def get_jackd_samplerate(self):
        return zynautoconnect.get_jackd_samplerate()

    def get_jackd_blocksize(self):
        return zynautoconnect.get_jackd_blocksize()

    # ------------------------------------------------------------------
    # Zynthian Config Info
    # ------------------------------------------------------------------

    def get_zynthian_config(self, varname):
        return eval("zynthian_gui_config.{}".format(varname))

    def allow_headphones(self):
        return self.screens["layer"].amixer_layer.engine.allow_headphones()

    # ------------------------------------------------------------------
    # QML bindings
    # ------------------------------------------------------------------

    @Slot(QWindow)
    def register_panel(self, panel):
        display = Xlib.display.Display()
        window = display.create_resource_object("window", panel.winId())
        window.change_property(
            display.intern_atom("_NET_WM_STRUT"),
            display.intern_atom("CARDINAL"),
            32, [0, 0, 0, panel.height()])

        _ATOM = display.intern_atom("ATOM")
        _TYPE = display.intern_atom("_NET_WM_WINDOW_TYPE")
        _DOCK = display.intern_atom("_NET_WM_WINDOW_TYPE_DOCK")
        window.change_property(_TYPE, _ATOM, 32, [_DOCK])

        logging.debug(panel)
        logging.debug(panel.winId())
        logging.debug(window)
        display.sync()

    @Slot(None)
    def close_current_window(self):
        if zynthian_gui_config.app.focusWindow():
            return
        display = Xlib.display.Display()
        root = display.screen().root
        wid = root.get_full_property(display.intern_atom('_NET_ACTIVE_WINDOW'), Xlib.X.AnyPropertyType).value[0]

        logging.debug(wid)
        window = display.create_resource_object("window", wid)

        _NET_CLOSE_WINDOW = display.intern_atom("_NET_CLOSE_WINDOW")

        close_message = Xlib.protocol.event.ClientMessage(window=window, client_type=_NET_CLOSE_WINDOW, data=(32,[0,0,0,0,0]))
        mask = (Xlib.X.SubstructureRedirectMask | Xlib.X.SubstructureNotifyMask)

        root.send_event(close_message, event_mask=mask)
        display.flush()

    def get_active_midi_channel(self):
        if self.curlayer == None:
            return lib_zyncoder.get_midi_active_chan()
        else:
            return self.curlayer.midi_chan

    def get_current_screen_id(self):
        if self.modal_screen:
            return self.modal_screen
        else:
            return self.active_screen

    def get_current_modal_screen_id(self):
        return self.modal_screen

    def get_status_information(self):
        return self.status_object

    def get_keybinding(self):
        return zynthian_gui_keybinding.getInstance(self)

    def set_current_qml_page(self, page):
        if self.current_qml_page_prop is page:
            return
        self.current_qml_page_prop = page
        self.current_qml_page_changed.emit()

    def get_current_qml_page(self):
        return self.current_qml_page_prop

    def get_home_screen(self):
        return self.__home_screen

    def set_home_screen(self, screen: str):
        if self.__home_screen == screen:
            return
        self.__home_screen = screen
        self.home_screen_changed.emit()

    def get_last_note(self):
        if not self.__notes_on:
            return ""
        note_names = ("C","C#","D","D#","E","F","F#","G","G#","A","A#","B")
        num = self.__notes_on[len(self.__notes_on) - 1]
        scale = int(num / 12) - 1
        num = int(num % 12)
        return "{}{}".format(note_names[num], scale)

    @Slot(None)
    def stop_splash(self):
        logging.debug("---p Starting stop_splash procedure")
        self.zynautoconnect()
        self.audio_settings.setAllControllersToMaxValue()
        # Display main window as soon as possible so it doesn't take time to load after splash stops
        self.displayMainWindow.emit()
        self.isBootingComplete = True
        recent_task_messages.put("command:play-extro")        
        # Display sketchpad page and run set_selector at last before hiding splash to ensure knobs work fine
        self.show_modal("sketchpad")
        self.set_selector()        
        # Explicitly run update_jack_port after booting is complete as any requests made while booting is ignored
        for i in range(0, self.sketchpad.song.channelsModel.count):
            channel = self.sketchpad.song.channelsModel.getChannel(i)
            # Allow jack ports connection to complete before showing UI so do not update jack ports in a thread
            channel.update_jack_port(run_in_thread=False)
            # Cache back/preset of all selected synths of all channel
            channel.cache_bank_preset_lists()
        # Stop rainbow and initialize LED config and connect to required signals to be able to update LEDs on value change instead
        rainbow_led_process.terminate()
        self.led_config.init()
        boot_end = timer()
        logging.debug("---p Completing stop_splash procedure")
        logging.info(f"### BOOTUP TIME : {timedelta(seconds=boot_end - boot_start)}")

    # ---------------------------------------------------------------------------
    # Screens getters
    def get_info(self):
        return self.screens["info"]

    def get_confirm(self):
        return self.screens["confirm"]

    def get_option(self):
        return self.screens["option"]

    def get_main(self):
        return self.screens["main"]

    def about(self):
        return self.screens["about"]

    def get_engine(self):
        return self.screens["engine"]

    def get_layer(self):
        return self.screens["layer"]

    def get_fixed_layers(self):
        return self.screens["fixed_layers"]

    def get_effects_for_channel(self):
        return self.screens["effects_for_channel"]

    def get_layers_for_channel(self):
        return self.screens["layers_for_channel"]

    def get_main_layers_view(self):
        return self.screens["main_layers_view"]

    def get_layer_options(self):
        return self.screens["layer_options"]

    def get_layer_effects(self):
        return self.screens["layer_effects"]

    def get_layer_midi_effects(self):
        return self.screens["layer_midi_effects"]

    def get_effect_types(self):
        return self.screens["effect_types"]

    def get_midi_effect_types(self):
        return self.screens["midi_effect_types"]

    def get_layer_effect_chooser(self):
        return self.screens["layer_effect_chooser"]

    def get_layer_midi_effect_chooser(self):
        return self.screens["layer_midi_effect_chooser"]

    def get_module_downloader(self):
        return self.screens["module_downloader"]

    def get_control_downloader(self):
        return self.screens["control_downloader"]

    def get_fx_control_downloader(self):
        return self.screens["fx_control_downloader"]

    def get_admin(self):
        return self.screens["admin"]

    def get_snapshot(self):
        return self.screens["snapshot"]

    def get_midi_chan(self):
        return self.screens["midi_chan"]

    def get_midi_key_range(self):
        return self.screens["midi_key_range"]

    def get_bank(self):
        return self.screens["bank"]

    def get_preset(self):
        return self.screens["preset"]

    def get_effect_preset(self):
        return self.screens["effect_preset"]

    def get_control(self):
        return self.screens["control"]

    def get_channel(self):
        return self.screens["channel"]

    def get_channel_external_setup(self):
        return self.screens["channel_external_setup"]

    def get_channel_wave_editor(self):
        return self.screens["channel_wave_editor"]

    def audio_out(self):
        return self.screens["audio_out"]

    def audio_in(self):
        return self.screens["audio_in"]

    def get_audio_recorder(self):
        return self.screens["audio_recorder"]

    def get_play_grid(self):
        return self.screens["play_grid"]

    def get_playgrid_downloader(self):
        return self.screens["playgrid_downloader"]

    def get_theme_chooser(self):
        return self.screens["theme_chooser"]

    def get_theme_downloader(self):
        return self.screens["theme_downloader"]

    def get_sketch_downloader(self):
        return self.screens["sketch_downloader"]

    def get_sound_downloader(self):
        return self.screens["sound_downloader"]

    def get_soundfont_downloader(self):
        return self.screens["soundfont_downloader"]

    def get_soundset_downloader(self):
        return self.screens["soundset_downloader"]

    def get_sequence_downloader(self):
        return self.screens["sequence_downloader"]

    def get_sketchpad_downloader(self):
        return self.screens["sketchpad_downloader"]

    def test_touchpoints(self):
        return self.screens["test_touchpoints"]

    def playgrid(self):
        return self.screens["playgrid"]

    def miniplaygrid(self):
        return self.screens["miniplaygrid"]

    def sketchpad(self):
        if "sketchpad" in self.screens:
            return self.screens["sketchpad"]
        return None

    def audio_settings(self):
        return self.screens["audio_settings"]

    def wifi_settings(self):
        return self.screens["wifi_settings"]

    def midicontroller_settings(self):
        return self.screens["midicontroller_settings"]

    def test_knobs(self):
        return self.screens["test_knobs"]

    def synth_behaviour(self):
        return self.screens["synth_behaviour"]

    def snapshots_menu(self):
        return self.screens["snapshots_menu"]

    def network(self):
        return self.screens["network"]

    def hardware(self):
        return self.screens["hardware"]

    def song_manager(self):
        return self.screens["song_manager"]

    def sound_categories(self):
        return self.screens["sound_categories"]

    def led_config(self):
        return self.screens["led_config"]

    def bluetooth_config(self):
        return self.screens["bluetooth_config"]

    def osd(self):
        return self.__osd

    def zynthbox_plugins_helper(self):
        return self.__zynthbox_plugins_helper

    ### Alternative long task handling than show_loading
    def do_long_task(self, cb, message=None):
        logging.debug("### Start long task")
        # Emit long task started if no other long task is already running
        if message is not None:
            self.currentTaskMessage = message
        if self.__long_task_count__ == 0:
            self.longTaskStarted.emit()
        self.__long_task_count__ += 1
        self.doingLongTaskChanged.emit()
        if self.__long_task_count__ > 0:
            recent_task_messages.put("command:show")

        QTimer.singleShot(300, cb)

    def end_long_task(self):
        logging.debug("### End long task")
        self.__long_task_count__ -= 1
        self.doingLongTaskChanged.emit()
        # Emit long task ended only if all task has ended
        if self.__long_task_count__ == 0:
            self.currentTaskMessage = ""
            self.longTaskEnded.emit()
            if self.loading == 0:
                recent_task_messages.put("command:hide")

    longTaskStarted = Signal()
    longTaskEnded = Signal()
    ### END Alternative long task handling

    ### BEGIN Property forceSongMode
    def get_forceSongMode(self):
        return self.__forceSongMode__
    def set_forceSongMode(self, newValue):
        if self.__forceSongMode__ != newValue:
            self.__forceSongMode__ = newValue
            self.forceSongModeChanged.emit()
    forceSongModeChanged = Signal()
    forceSongMode = Property(bool, get_forceSongMode, set_forceSongMode, notify=forceSongModeChanged)
    ### END Property forceSongMode

    ### BEGIN Property menuButtonPressed
    def get_menu_button_pressed(self):
        return self.__menu_button_pressed__

    def set_menu_button_pressed(self, pressed):
        if self.__menu_button_pressed__ != pressed:
            logging.debug(f"Menu Button pressed : {pressed}")
            self.__menu_button_pressed__ = pressed
            if pressed:
                Zynthbox.MidiRouter.instance().enqueueCuiaCommand("SWITCH_MENU_DOWN")
                Zynthbox.MidiRouter.instance().enqueueCuiaCommand("SCREEN_MAIN_MENU")
            else:
                Zynthbox.MidiRouter.instance().enqueueCuiaCommand("SWITCH_MENU_RELEASED")
            self.menu_button_pressed_changed.emit()

    menu_button_pressed_changed = Signal()

    menuButtonPressed = Property(bool, get_menu_button_pressed, set_menu_button_pressed, notify=menu_button_pressed_changed)
    ### END Property menuButtonPressed

    ### BEGIN Property ignoreNextMenuButtonPress
    def get_ignoreNextMenuButtonPress(self):
        return self.__ignoreNextMenuButtonPress

    def set_ignoreNextMenuButtonPress(self, val):
        if self.__ignoreNextMenuButtonPress != val:
            self.__ignoreNextMenuButtonPress = val
            self.ignoreNextMenuButtonPressChanged.emit()

    ignoreNextMenuButtonPressChanged = Signal()

    ignoreNextMenuButtonPress = Property(bool, get_ignoreNextMenuButtonPress, set_ignoreNextMenuButtonPress, notify=ignoreNextMenuButtonPressChanged)
    ### END Property ignoreNextMenuButtonPress

    ### BEGIN Property switchChannelsButtonPressed
    def get_switch_channels_button_pressed(self):
        return self.__switch_channels_button_pressed__

    def set_switch_channels_button_pressed(self, pressed):
        if self.__switch_channels_button_pressed__ != pressed:
            logging.error(f"Switch Channels Button pressed : {pressed}")
            self.__switch_channels_button_pressed__ = pressed
            if pressed:
                Zynthbox.MidiRouter.instance().enqueueCuiaCommand("SWITCH_TRACKS_MOD_DOWN")
                self.tracksModActive = not self.tracksModActive
            else:
                Zynthbox.MidiRouter.instance().enqueueCuiaCommand("SWITCH_TRACKS_MOD_RELEASED")
                # If * button is pressed, it toggles itself on/off for 5000ms before returning to previous state.
                # Since * button is pressed, start timer
                QMetaObject.invokeMethod(self.tracksModTimer, "start", Qt.QueuedConnection)
            logging.debug(f'self.tracksModActive({self.tracksModActive})')
            self.switch_channels_button_pressed_changed.emit()

    switch_channels_button_pressed_changed = Signal()

    switchChannelsButtonPressed = Property(bool, get_switch_channels_button_pressed, set_switch_channels_button_pressed, notify=switch_channels_button_pressed_changed)
    ### END Property switchChannelsButtonPressed

    ### BEGIN Property modeButtonPressed
    def get_mode_button_pressed(self):
        return self.__mode_button_pressed__

    def set_mode_button_pressed(self, pressed):
        if self.__mode_button_pressed__ != pressed:
            logging.debug(f"Mode Button pressed : {pressed}")
            self.__mode_button_pressed__ = pressed
            if pressed:
                Zynthbox.MidiRouter.instance().enqueueCuiaCommand("SWITCH_MODE_DOWN")
            else:
                Zynthbox.MidiRouter.instance().enqueueCuiaCommand("SWITCH_MODE_RELEASED")
            self.mode_button_pressed_changed.emit()

    mode_button_pressed_changed = Signal()

    modeButtonPressed = Property(bool, get_mode_button_pressed, set_mode_button_pressed, notify=mode_button_pressed_changed)
    ### END Property modeButtonPressed

    ### BEGIN Property ignoreNextModeButtonPress
    def get_ignoreNextModeButtonPress(self):
        return self.__ignoreNextModeButtonPress

    def set_ignoreNextModeButtonPress(self, val):
        if self.__ignoreNextModeButtonPress != val:
            self.__ignoreNextModeButtonPress = val
            self.ignoreNextModeButtonPressChanged.emit()

    ignoreNextModeButtonPressChanged = Signal()

    ignoreNextModeButtonPress = Property(bool, get_ignoreNextModeButtonPress, set_ignoreNextModeButtonPress, notify=ignoreNextModeButtonPressChanged)
    ### END Property ignoreNextModeButtonPress

    ### BEGIN Property altButtonPressed
    def get_alt_button_pressed(self):
        return self.__alt_button_pressed__

    def set_alt_button_pressed(self, pressed):
        if self.__alt_button_pressed__ != pressed:
            logging.debug(f"alt Button pressed : {pressed}")
            self.__alt_button_pressed__ = pressed
            if pressed:
                Zynthbox.MidiRouter.instance().enqueueCuiaCommand("SWITCH_ALT_DOWN")
            else:
                Zynthbox.MidiRouter.instance().enqueueCuiaCommand("SWITCH_ALT_RELEASED")
            self.alt_button_pressed_changed.emit()

    alt_button_pressed_changed = Signal()

    altButtonPressed = Property(bool, get_alt_button_pressed, set_alt_button_pressed, notify=alt_button_pressed_changed)
    ### END Property altButtonPressed

    ### BEGIN Property globalButtonPressed
    def get_global_button_pressed(self):
        return self.__global_button_pressed__

    def set_global_button_pressed(self, pressed):
        if self.__global_button_pressed__ != pressed:
            logging.debug(f"Global Button pressed : {pressed}")
            self.__global_button_pressed__ = pressed
            if pressed:
                Zynthbox.MidiRouter.instance().enqueueCuiaCommand("SWITCH_GLOBAL_DOWN")
                self.globalPopupOpened = not self.globalPopupOpened
            else:
                Zynthbox.MidiRouter.instance().enqueueCuiaCommand("SWITCH_GLOBAL_RELEASED")
            self.global_button_pressed_changed.emit()

    global_button_pressed_changed = Signal()

    globalButtonPressed = Property(bool, get_global_button_pressed, set_global_button_pressed, notify=global_button_pressed_changed)
    ### END Property globalButtonPressed

    ### BEGIN Property ignoreNextGlobalButtonPress
    def get_ignoreNextGlobalButtonPress(self):
        return self.__ignoreNextGlobalButtonPress

    def set_ignoreNextGlobalButtonPress(self, val):
        if self.__ignoreNextGlobalButtonPress != val:
            self.__ignoreNextGlobalButtonPress = val
            self.ignoreNextGlobalButtonPressChanged.emit()

    ignoreNextGlobalButtonPressChanged = Signal()

    ignoreNextGlobalButtonPress = Property(bool, get_ignoreNextGlobalButtonPress, set_ignoreNextGlobalButtonPress, notify=ignoreNextGlobalButtonPressChanged)
    ### END Property ignoreNextGlobalButtonPress

    ### Property startRecordButtonPressed
    def get_startRecord_button_pressed(self):
        return self.__startRecord_button_pressed__

    def set_startRecord_button_pressed(self, pressed):
        if self.__startRecord_button_pressed__ != pressed:
            logging.debug(f"startRecord Button pressed : {pressed}")
            self.__startRecord_button_pressed__ = pressed
            self.startRecord_button_pressed_changed.emit()

    startRecord_button_pressed_changed = Signal()

    startRecordButtonPressed = Property(bool, get_startRecord_button_pressed, set_startRecord_button_pressed, notify=startRecord_button_pressed_changed)
    ### END Property startRecordButtonPressed

    ### BEGIN Property ignoreNextRecordButtonPress
    def get_ignoreNextRecordButtonPress(self):
        return self.__ignoreNextRecordButtonPress

    def set_ignoreNextRecordButtonPress(self, val):
        if self.__ignoreNextRecordButtonPress != val:
            self.__ignoreNextRecordButtonPress = val
            self.ignoreNextRecordButtonPressChanged.emit()

    ignoreNextRecordButtonPressChanged = Signal()

    ignoreNextRecordButtonPress = Property(bool, get_ignoreNextRecordButtonPress, set_ignoreNextRecordButtonPress, notify=ignoreNextRecordButtonPressChanged)
    ### END Property ignoreNextRecordButtonPress

    ### Property playButtonPressed
    def get_play_button_pressed(self):
        return self.__play_button_pressed__

    def set_play_button_pressed(self, pressed):
        if self.__play_button_pressed__ != pressed:
            logging.debug(f"play Button pressed : {pressed}")
            self.__play_button_pressed__ = pressed
            self.play_button_pressed_changed.emit()

    play_button_pressed_changed = Signal()

    playButtonPressed = Property(bool, get_play_button_pressed, set_play_button_pressed, notify=play_button_pressed_changed)
    ### END Property playButtonPressed

    ### BEGIN Property ignoreNextPlayButtonPress
    def get_ignoreNextPlayButtonPress(self):
        return self.__ignoreNextPlayButtonPress

    def set_ignoreNextPlayButtonPress(self, val):
        if self.__ignoreNextPlayButtonPress != val:
            self.__ignoreNextPlayButtonPress = val
            self.ignoreNextPlayButtonPressChanged.emit()

    ignoreNextPlayButtonPressChanged = Signal()

    ignoreNextPlayButtonPress = Property(bool, get_ignoreNextPlayButtonPress, set_ignoreNextPlayButtonPress, notify=ignoreNextPlayButtonPressChanged)
    ### END Property ignoreNextPlayButtonPress

    ### BEGIN Property metronomeButtonPressed
    def get_metronome_button_pressed(self):
        return self.__metronome_button_pressed__

    def set_metronome_button_pressed(self, pressed):
        if self.__metronome_button_pressed__ != pressed:
            logging.debug(f"metronome Button pressed : {pressed}")
            self.__metronome_button_pressed__ = pressed
            self.metronome_button_pressed_changed.emit()

    metronome_button_pressed_changed = Signal()

    metronomeButtonPressed = Property(bool, get_metronome_button_pressed, set_metronome_button_pressed, notify=metronome_button_pressed_changed)
    ### END Property metronomeButtonPressed

    ### BEGIN Property ignoreNextMetronomeButtonPress
    def get_ignoreNextMetronomeButtonPress(self):
        return self.__ignoreNextMetronomeButtonPress

    def set_ignoreNextMetronomeButtonPress(self, val):
        if self.__ignoreNextMetronomeButtonPress != val:
            self.__ignoreNextMetronomeButtonPress = val
            self.ignoreNextMetronomeButtonPressChanged.emit()

    ignoreNextMetronomeButtonPressChanged = Signal()

    ignoreNextMetronomeButtonPress = Property(bool, get_ignoreNextMetronomeButtonPress, set_ignoreNextMetronomeButtonPress, notify=ignoreNextMetronomeButtonPressChanged)
    ### END Property ignoreNextMetronomeButtonPress

    ### Property stopButtonPressed
    def get_stop_button_pressed(self):
        return self.__stop_button_pressed__

    def set_stop_button_pressed(self, pressed):
        if self.__stop_button_pressed__ != pressed:
            logging.debug(f"stop Button pressed : {pressed}")
            self.__stop_button_pressed__ = pressed
            self.stop_button_pressed_changed.emit()

    stop_button_pressed_changed = Signal()

    stopButtonPressed = Property(bool, get_stop_button_pressed, set_stop_button_pressed, notify=stop_button_pressed_changed)
    ### END Property stopButtonPressed

    ### BEGIN Property ignoreNextStopButtonPress
    def get_ignoreNextStopButtonPress(self):
        return self.__ignoreNextStopButtonPress

    def set_ignoreNextStopButtonPress(self, val):
        if self.__ignoreNextStopButtonPress != val:
            self.__ignoreNextStopButtonPress = val
            self.ignoreNextStopButtonPressChanged.emit()

    ignoreNextStopButtonPressChanged = Signal()

    ignoreNextStopButtonPress = Property(bool, get_ignoreNextStopButtonPress, set_ignoreNextStopButtonPress, notify=ignoreNextStopButtonPressChanged)
    ### END Property ignoreNextStopButtonPress

    ### Property backButtonPressed
    def get_back_button_pressed(self):
        return self.__back_button_pressed__

    def set_back_button_pressed(self, pressed):
        if self.__back_button_pressed__ != pressed:
            logging.debug(f"back Button pressed : {pressed}")
            self.__back_button_pressed__ = pressed
            self.back_button_pressed_changed.emit()

    back_button_pressed_changed = Signal()

    backButtonPressed = Property(bool, get_back_button_pressed, set_back_button_pressed, notify=back_button_pressed_changed)
    ### END Property backButtonPressed

    ### BEGIN Property ignoreNextBackButtonPress
    def get_ignoreNextBackButtonPress(self):
        return self.__ignoreNextBackButtonPress

    def set_ignoreNextBackButtonPress(self, val):
        if self.__ignoreNextBackButtonPress != val:
            self.__ignoreNextBackButtonPress = val
            self.ignoreNextBackButtonPressChanged.emit()

    ignoreNextBackButtonPressChanged = Signal()

    ignoreNextBackButtonPress = Property(bool, get_ignoreNextBackButtonPress, set_ignoreNextBackButtonPress, notify=ignoreNextBackButtonPressChanged)
    ### END Property ignoreNextBackButtonPress

    ### Property upButtonPressed
    def get_up_button_pressed(self):
        return self.__up_button_pressed__

    def set_up_button_pressed(self, pressed):
        if self.__up_button_pressed__ != pressed:
            logging.debug(f"up Button pressed : {pressed}")
            self.__up_button_pressed__ = pressed
            self.up_button_pressed_changed.emit()

    up_button_pressed_changed = Signal()

    upButtonPressed = Property(bool, get_up_button_pressed, set_up_button_pressed, notify=up_button_pressed_changed)
    ### END Property upButtonPressed

    ### Property selectButtonPressed
    def get_select_button_pressed(self):
        return self.__select_button_pressed__

    def set_select_button_pressed(self, pressed):
        if self.__select_button_pressed__ != pressed:
            logging.debug(f"select Button pressed : {pressed}")
            self.__select_button_pressed__ = pressed
            self.select_button_pressed_changed.emit()

    select_button_pressed_changed = Signal()

    selectButtonPressed = Property(bool, get_select_button_pressed, set_select_button_pressed, notify=select_button_pressed_changed)
    ### END Property selectButtonPressed

    ### BEGIN Property ignoreNextSelectButtonPress
    def get_ignoreNextSelectButtonPress(self):
        return self.__ignoreNextSelectButtonPress

    def set_ignoreNextSelectButtonPress(self, val):
        if self.__ignoreNextSelectButtonPress != val:
            self.__ignoreNextSelectButtonPress = val
            self.ignoreNextSelectButtonPressChanged.emit()

    ignoreNextSelectButtonPressChanged = Signal()

    ignoreNextSelectButtonPress = Property(bool, get_ignoreNextSelectButtonPress, set_ignoreNextSelectButtonPress, notify=ignoreNextSelectButtonPressChanged)
    ### END Property ignoreNextSelectButtonPress

    ### Property leftButtonPressed
    def get_left_button_pressed(self):
        return self.__left_button_pressed__

    def set_left_button_pressed(self, pressed):
        if self.__left_button_pressed__ != pressed:
            logging.debug(f"left Button pressed : {pressed}")
            self.__left_button_pressed__ = pressed
            self.left_button_pressed_changed.emit()

    left_button_pressed_changed = Signal()

    leftButtonPressed = Property(bool, get_left_button_pressed, set_left_button_pressed, notify=left_button_pressed_changed)
    ### END Property leftButtonPressed

    ### Property downButtonPressed
    def get_down_button_pressed(self):
        return self.__down_button_pressed__

    def set_down_button_pressed(self, pressed):
        if self.__down_button_pressed__ != pressed:
            logging.debug(f"down Button pressed : {pressed}")
            self.__down_button_pressed__ = pressed
            self.down_button_pressed_changed.emit()

    down_button_pressed_changed = Signal()

    downButtonPressed = Property(bool, get_down_button_pressed, set_down_button_pressed, notify=down_button_pressed_changed)
    ### END Property downButtonPressed

    ### Property rightButtonPressed
    def get_right_button_pressed(self):
        return self.__right_button_pressed__

    def set_right_button_pressed(self, pressed):
        if self.__right_button_pressed__ != pressed:
            logging.debug(f"right Button pressed : {pressed}")
            self.__right_button_pressed__ = pressed
            self.right_button_pressed_changed.emit()

    right_button_pressed_changed = Signal()

    rightButtonPressed = Property(bool, get_right_button_pressed, set_right_button_pressed, notify=right_button_pressed_changed)
    ### END Property rightButtonPressed

    ### Property anyKnobTouched
    def get_anyKnobTouched(self):
        return self.__knob0touched__ or self.__knob1touched__ or self.__knob2touched__ or self.__knob3touched__

    anyKnobTouched_changed = Signal()

    anyKnobTouched = Property(bool, get_anyKnobTouched, notify=anyKnobTouched_changed)
    ### END Property anyKnobTouched

    ### Property knob0Touched
    def get_knob0touched(self):
        return self.__knob0touched__

    def set_knob0touched(self, touched):
        if self.__knob0touched__ != touched:
            self.__knob0touched__ = touched
            if touched:
                Zynthbox.MidiRouter.instance().enqueueCuiaCommand("KNOB0_TOUCHED")
            else:
                Zynthbox.MidiRouter.instance().enqueueCuiaCommand("KNOB0_RELEASED")
            self.knob0touched_changed.emit()

    knob0touched_changed = Signal()

    knob0Touched = Property(bool, get_knob0touched, set_knob0touched, notify=knob0touched_changed)
    ### END Property knob0Touched

    ### Property knob1Touched
    def get_knob1touched(self):
        return self.__knob1touched__

    def set_knob1touched(self, touched):
        if self.__knob1touched__ != touched:
            self.__knob1touched__ = touched
            if touched:
                Zynthbox.MidiRouter.instance().enqueueCuiaCommand("KNOB1_TOUCHED")
            else:
                Zynthbox.MidiRouter.instance().enqueueCuiaCommand("KNOB1_RELEASED")
            self.knob1touched_changed.emit()

    knob1touched_changed = Signal()

    knob1Touched = Property(bool, get_knob1touched, set_knob1touched, notify=knob1touched_changed)
    ### END Property knob1Touched

    ### Property knob2Touched
    def get_knob2touched(self):
        return self.__knob2touched__

    def set_knob2touched(self, touched):
        if self.__knob2touched__ != touched:
            self.__knob2touched__ = touched
            if touched:
                Zynthbox.MidiRouter.instance().enqueueCuiaCommand("KNOB2_TOUCHED")
            else:
                Zynthbox.MidiRouter.instance().enqueueCuiaCommand("KNOB2_RELEASED")
            self.knob2touched_changed.emit()

    knob2touched_changed = Signal()

    knob2Touched = Property(bool, get_knob2touched, set_knob2touched, notify=knob2touched_changed)
    ### END Property knob2Touched

    ### Property knob3Touched
    def get_knob3touched(self):
        return self.__knob3touched__

    def set_knob3touched(self, touched):
        if self.__knob3touched__ != touched:
            self.__knob3touched__ = touched
            if touched:
                Zynthbox.MidiRouter.instance().enqueueCuiaCommand("KNOB3_TOUCHED")
            else:
                Zynthbox.MidiRouter.instance().enqueueCuiaCommand("KNOB3_RELEASED")
            self.knob3touched_changed.emit()

    knob3touched_changed = Signal()

    knob3Touched = Property(bool, get_knob3touched, set_knob3touched, notify=knob3touched_changed)
    ### END Property knob3Touched

    ### Property openedDialog
    def get_openedDialog(self):
        return self.opened_dialog

    def set_openedDialog(self, dialog):
        if dialog != self.opened_dialog:
            self.opened_dialog = dialog
            self.openedDialogChanged.emit()

    openedDialogChanged = Signal()

    openedDialog = Property(QObject, get_openedDialog, set_openedDialog, notify=openedDialogChanged)

    @Slot(QObject)
    def pushDialog(self, dialog):
        self.dialogStack.append(dialog)
        self.set_openedDialog(dialog)
        pass

    @Slot(QObject)
    def popDialog(self, dialog):
        if dialog in self.dialogStack:
            updateOpened = False
            if self.dialogStack[-1] is dialog:
                updateOpened = True
            else:
                logging.warning(f"The dialog ({dialog.objectName()}) we just tried to pop from the list is not at the top of the stack. We still removed it, but there is likely something wrong if this happens.")
            self.dialogStack.remove(dialog)
            if len(self.dialogStack) > 0:
                self.set_openedDialog(self.dialogStack[-1])
            else:
                self.set_openedDialog(None)
        else:
            logging.warning("The dialog we attempted to pop from the list is not in the list of opened dialogs. Something's out of wack.")

    ### End Property openedDialog

    ### Property leftSidebar
    def get_leftSidebar(self):
        return self.left_sidebar

    def set_leftSidebar(self, sidebar):
        if sidebar != self.left_sidebar:
            self.left_sidebar = sidebar
            self.leftSidebarChanged.emit()

    leftSidebarChanged = Signal()

    leftSidebar = Property(QObject, get_leftSidebar, set_leftSidebar, notify=leftSidebarChanged)

    ### End Property leftSidebar

    ### Property isBootingComplete
    def get_isBootingComplete(self):
        return self.__booting_complete__

    def set_isBootingComplete(self, value):
        if self.__booting_complete__ != value:
            self.__booting_complete__ = value
            self.isBootingCompleteChanged.emit()

            if self.__booting_complete__:
                self.currentTaskMessage = ""

    isBootingCompleteChanged = Signal()

    isBootingComplete = Property(bool, get_isBootingComplete, set_isBootingComplete, notify=isBootingCompleteChanged)
    ### END Property isBootingComplete

    ### Property isShuttingDown
    def get_isShuttingDown(self):
        return self.__shutting_down

    def set_isShuttingDown(self, value):
        if self.__shutting_down != value:
            self.__shutting_down = value
            self.isShuttingDownChanged.emit()

    isShuttingDownChanged = Signal()

    isShuttingDown = Property(bool, get_isShuttingDown, set_isShuttingDown, notify=isShuttingDownChanged)
    ### END Property isShuttingDown

    ### Property globalPopupOpened
    def get_globalPopupOpened(self):
        return self.__global_popup_opened__

    def set_globalPopupOpened(self, opened):
        if self.__global_popup_opened__ != opened:
            self.__global_popup_opened__ = opened
            self.globalPopupOpenedChanged.emit()
            self.handleCurrentScreenIDChanged() # Technically a bit odd, but logically this is what's happening

    globalPopupOpenedChanged = Signal()

    globalPopupOpened = Property(bool, get_globalPopupOpened, set_globalPopupOpened, notify=globalPopupOpenedChanged)
    ### END Property globalPopupOpened

    ### Property delayController
    def get_delayController(self):
        return self.global_fx_engines[0][1]

    delayController = Property(QObject, get_delayController, constant=True)
    ### END Property delayController

    ### Property reverbController
    def get_reverbController(self):
        return self.global_fx_engines[1][1]

    reverbController = Property(QObject, get_reverbController, constant=True)
    ### END Property reverbController

    ### Property currentTaskMessage
    def get_currentTaskMessage(self):
        return self.__current_task_message

    def set_currentTaskMessage(self, value):
        if value != self.__current_task_message:
            self.__current_task_message = value
            recent_task_messages.put(value)
            self.currentTaskMessageChanged.emit()
            QGuiApplication.instance().processEvents()

    currentTaskMessageChanged = Signal()

    currentTaskMessage = Property(str, get_currentTaskMessage, set_currentTaskMessage, notify=currentTaskMessageChanged)
    ### END Property currentTaskMessage

    ### Property passiveNotification
    def get_passiveNotification(self):
        return self.__passive_notification

    def set_passiveNotification(self, msg):
        self.__passive_notification = msg

        # Show notification if message is not empty
        if msg != "":
            self.passiveNotificationChanged.emit()

    passiveNotificationChanged = Signal()

    passiveNotification = Property(str, get_passiveNotification, set_passiveNotification, notify=passiveNotificationChanged)
    ### END Property passiveNotification

    ### Property tracksModActive
    def get_tracksModActive(self):
        return self.tracks_mod_active

    def set_tracksModActive(self, val):
        if self.tracks_mod_active != val:
            self.tracks_mod_active = val
            self.tracksModActiveChanged.emit()

    tracksModActiveChanged = Signal()

    tracksModActive = Property(bool, get_tracksModActive, set_tracksModActive, notify=tracksModActiveChanged)
    ### END Property tracksModActive

    ### Property bottomBarControlObj
    ### This property will store the object that is being controlled by bottomBar
    def get_bottomBarControlObj(self):
        return self.__bottombar_control_obj

    def set_bottomBarControlObj(self, val):
        if self.__bottombar_control_obj != val:
            self.__bottombar_control_obj = val
            self.bottomBarControlObjChanged.emit()

    bottomBarControlObjChanged = Signal()

    bottomBarControlObj = Property(QObject, get_bottomBarControlObj, set_bottomBarControlObj, notify=bottomBarControlObjChanged)
    ### END Property bottomBarControlObj

    ### Property bottomBarControlType
    ### This property will store the type of object that is being controlled by bottombar
    ### Allowed values : "bottombar-controltype-song", "bottombar-controltype-clip", "bottombar-controltype-channel", "bottombar-controltype-clips", "bottombar-controltype-pattern", "bottombar-controltype-none"
    def get_bottomBarControlType(self):
        return self.__bottombar_control_type

    def set_bottomBarControlType(self, val):
        if self.__bottombar_control_type != val:
            self.__bottombar_control_type = val
            self.bottomBarControlTypeChanged.emit()

    bottomBarControlTypeChanged = Signal()

    bottomBarControlType = Property(str, get_bottomBarControlType, set_bottomBarControlType, notify=bottomBarControlTypeChanged)
    ### END Property bottomBarControlType

    ### BEGIN Mixer display control
    @Slot(None)
    def showSketchpadMixer(self):
        if self.current_screen_id != "sketchpad":
            self.show_modal("sketchpad")
        self.showMixer.emit()

    @Slot(None)
    def hideSketchpadMixer(self):
        self.hideMixer.emit()

    @Slot(None)
    def toggleSketchpadMixer(self):
        if self.current_screen_id != "sketchpad":
            self.showSketchpadMixer()
        else:
            self.toggleMixer.emit()

    showMixer = Signal()
    hideMixer = Signal()
    toggleMixer = Signal()
    ### END Mixer display control

    ### Property isExternalAppActive
    def get_isExternalAppActive(self):
        return hasattr(zynthian_gui_config, 'top') and zynthian_gui_config.top.isActive() == False

    isExternalAppActiveChanged = Signal()

    isExternalAppActive = Property(bool, get_isExternalAppActive, notify=isExternalAppActiveChanged)
    ### END Property isExternalAppActive

    ### Property masterVolume
    def get_masterVolume(self):
        return self.__master_volume

    def set_masterVolume(self, value):
        if self.__master_volume != value:
            self.__master_volume = value
            # JackPassthroughClient expects dryAmount to be ranging from 0-1
            Zynthbox.Plugin.instance().globalPlaybackClient().setDryAmount(np.interp(value, (0, 100), (0, 1)))
            self.masterVolumeChanged.emit()

    masterVolumeChanged = Signal()

    masterVolume = Property(int, get_masterVolume, set_masterVolume, notify=masterVolumeChanged)
    ### END Property masterVolume

    ### Property initialMasterVolume
    def get_initialMasterVolume(self):
        return 25

    initialMasterVolume = Property(int, get_initialMasterVolume, constant=True)
    ### END Property initialMasterVolume

    ### Property curlayerEngineName
    def get_curlayerEngineName(self):
        try:
            return self.curlayer.engine.name.replace("Jalv/", "")
        except:
            return ""

    curlayerEngineNameChanged = Signal()

    curlayerEngineName = Property(str, get_curlayerEngineName, notify=curlayerEngineNameChanged)
    ### END Property curlayerEngineName

    ### Property curlayerPresetName
    def get_curlayerPresetName(self):
        try:
            return self.curlayer.preset_name
        except:
            return ""

    curlayerPresetNameChanged = Signal()

    curlayerPresetName = Property(str, get_curlayerPresetName, notify=curlayerPresetNameChanged)
    ### END Property curlayerPresetName

    ### Property curlayerIsFX
    def get_curlayerIsFX(self):
        try:
            return self.curlayer.engine.type == "Audio Effect"
        except:
            return False

    curlayerIsFXChanged = Signal()

    curlayerIsFX = Property(bool, get_curlayerIsFX, notify=curlayerIsFXChanged)
    ### END Property curlayerIsFX

    ### BEGIN Property doingLongTask
    def get_doingLongTask(self):
        return self.__long_task_count__ > 0

    doingLongTaskChanged = Signal()

    doingLongTask = Property(bool, get_doingLongTask, notify=doingLongTaskChanged)
    ### END Property doingLongTask

    ### BEGIN Property showMiniPlayGrid
    @Slot(None)
    def toggleMiniPlayGrid(self):
        self.showMiniPlayGrid = not self.showMiniPlayGrid

    def get_showMiniPlayGrid(self):
        return self.__show_mini_play_grid__
    def set_showMiniPlayGrid(self, showMiniPlayGrid):
        if self.__show_mini_play_grid__ != showMiniPlayGrid:
            self.__show_mini_play_grid__ = showMiniPlayGrid
            self.showMiniPlayGridChanged.emit()
    showMiniPlayGridChanged = Signal()
    showMiniPlayGrid = Property(bool, get_showMiniPlayGrid, set_showMiniPlayGrid, notify=showMiniPlayGridChanged)
    ### END Property showMiniPlayGrid

    current_screen_id_changed = Signal()
    current_modal_screen_id_changed = Signal()
    is_loading_changed = Signal()
    status_info_changed = Signal()
    current_qml_page_changed = Signal()
    miniPlayGridToggle = Signal()
    home_screen_changed = Signal()
    active_midi_channel_changed = Signal()
    last_note_changed = Signal()
    forced_screen_back_changed = Signal()
    run_start_metronome_and_playback = Signal()
    run_stop_metronome_and_playback = Signal()
    displayMainWindow = Signal()
    displayRecordingPopup = Signal()
    openLeftSidebar = Signal()
    closeLeftSidebar = Signal()
    # Arg 1 : Message to display
    # Arg 2 : If non zero, then hide dialog after timeout seconds otherwise show until closed
    showMessageDialog = Signal(str, int)

    about = Property(QObject, about, constant=True)
    audio_out = Property(QObject, audio_out, constant=True)
    audio_in = Property(QObject, audio_in, constant=True)
    test_touchpoints = Property(QObject, test_touchpoints, constant=True)
    playgrid = Property(QObject, playgrid, constant=True)
    miniplaygrid = Property(QObject, miniplaygrid, constant=True)
    sketchpad = Property(QObject, sketchpad, constant=True)
    audio_settings = Property(QObject, audio_settings, constant=True)
    wifi_settings = Property(QObject, wifi_settings, constant=True)
    midicontroller_settings = Property(QObject, midicontroller_settings, constant=True)
    test_knobs = Property(QObject, test_knobs, constant=True)
    synth_behaviour = Property(QObject, synth_behaviour, constant=True)
    snapshots_menu = Property(QObject, snapshots_menu, constant=True)
    network = Property(QObject, network, constant=True)
    hardware = Property(QObject, hardware, constant=True)
    song_manager = Property(QObject, song_manager, constant=True)
    sound_categories = Property(QObject, sound_categories, constant=True)
    led_config = Property(QObject, led_config, constant=True)
    bluetooth_config = Property(QObject, bluetooth_config, constant=True)
    osd = Property(QObject, osd, constant=True)
    zynthbox_plugins_helper = Property(QObject, zynthbox_plugins_helper, constant=True)

    current_screen_id = Property(
        str,
        get_current_screen_id,
        show_screen,
        notify=current_screen_id_changed,
    )
    current_modal_screen_id = Property(
        str,
        get_current_modal_screen_id,
        show_modal,
        notify=current_modal_screen_id_changed,
    )

    last_note = Property(
        str,
        get_last_note,
        notify=last_note_changed
    )

    graineratorEnabled = Property(bool, get_grainerator_enabled, constant=True)
    is_loading = Property(bool, get_is_loading, notify=is_loading_changed)
    home_screen = Property(str, get_home_screen, set_home_screen, notify=home_screen_changed)
    active_midi_channel = Property(int, get_active_midi_channel, notify = active_midi_channel_changed)

    def get_forced_screen_back(self):
        return self.__forced_screen_back
    def set_forced_screen_back(self, screen):
        if self.__forced_screen_back == screen:
            return
        self.__forced_screen_back = screen
        self.forced_screen_back_changed.emit()
    forced_screen_back = Property(str, get_forced_screen_back, set_forced_screen_back, notify=forced_screen_back_changed)

    status_information = Property(
        QObject, get_status_information, constant=True
    )

    keybinding = Property(QObject, get_keybinding, constant=True)

    current_qml_page = Property(
        QObject,
        get_current_qml_page,
        set_current_qml_page,
        notify=current_qml_page_changed,
    )

    info = Property(QObject, get_info, constant=True)
    confirm = Property(QObject, get_confirm, constant=True)
    option = Property(QObject, get_option, constant=True)
    main = Property(QObject, get_main, constant=True)
    engine = Property(QObject, get_engine, constant=True)
    layer = Property(QObject, get_layer, constant=True)
    fixed_layers = Property(QObject, get_fixed_layers, constant=True)
    effects_for_channel = Property(QObject, get_effects_for_channel, constant=True)
    layers_for_channel = Property(QObject, get_layers_for_channel, constant=True)
    main_layers_view = Property(QObject, get_main_layers_view, constant=True)
    layer_options = Property(QObject, get_layer_options, constant=True)
    layer_effects = Property(QObject, get_layer_effects, constant=True)
    layer_midi_effects = Property(QObject, get_layer_midi_effects, constant=True)
    effect_types = Property(QObject, get_effect_types, constant=True)
    midi_effect_types = Property(QObject, get_midi_effect_types, constant=True)
    layer_effect_chooser = Property(
        QObject, get_layer_effect_chooser, constant=True
    )
    layer_midi_effect_chooser = Property(
        QObject, get_layer_midi_effect_chooser, constant=True
    )
    module_downloader = Property(QObject, get_module_downloader, constant=True)
    control_downloader = Property(QObject, get_control_downloader, constant=True)
    fx_control_downloader = Property(QObject, get_fx_control_downloader, constant=True)
    admin = Property(QObject, get_admin, constant=True)
    snapshot = Property(QObject, get_snapshot, constant=True)
    midi_chan = Property(QObject, get_midi_chan, constant=True)
    midi_key_range = Property(QObject, get_midi_key_range, constant=True)
    bank = Property(QObject, get_bank, constant=True)
    preset = Property(QObject, get_preset, constant=True)
    effect_preset = Property(QObject, get_effect_preset, constant=True)
    control = Property(QObject, get_control, constant=True)
    channel = Property(QObject, get_channel, constant=True)
    channel_external_setup = Property(QObject, get_channel_external_setup, constant=True)
    channel_wave_editor = Property(QObject, get_channel_wave_editor, constant=True)
    audio_recorder = Property(QObject, get_audio_recorder, constant=True)
    playgrid_downloader = Property(QObject, get_playgrid_downloader, constant=True)
    theme_chooser = Property(QObject, get_theme_chooser, constant=True)
    theme_downloader = Property(QObject, get_theme_downloader, constant=True)
    sketch_downloader = Property(QObject, get_sketch_downloader, constant=True)
    sound_downloader = Property(QObject, get_sound_downloader, constant=True)
    soundfont_downloader = Property(QObject, get_soundfont_downloader, constant=True)
    soundset_downloader = Property(QObject, get_soundset_downloader, constant=True)
    sequence_downloader = Property(QObject, get_sequence_downloader, constant=True)
    sketchpad_downloader = Property(QObject, get_sketchpad_downloader, constant=True)

# ------------------------------------------------------------------------------
# Reparent Top Window using GTK XEmbed protocol features
# ------------------------------------------------------------------------------


# def flushflush():
# for i in range(1000):
# print("FLUSHFLUSHFLUSHFLUSHFLUSHFLUSHFLUSH")
# zynthian_gui_config.top.after(200, flushflush)


# if zynthian_gui_config.wiring_layout=="EMULATOR":
# top_xid=zynthian_gui_config.top.winfo_id()
# print("Zynthian GUI XID: "+str(top_xid))
# if len(sys.argv)>1:
# parent_xid=int(sys.argv[1])
# print("Parent XID: "+str(parent_xid))
# zynthian_gui_config.top.geometry('-10000-10000')
# zynthian_gui_config.top.overrideredirect(True)
# zynthian_gui_config.top.wm_withdraw()
# flushflush()
# zynthian_gui_config.top.after(1000, zynthian_gui_config.top.wm_deiconify)


# ------------------------------------------------------------------------------
# Catch SIGTERM
# ------------------------------------------------------------------------------


def exit_handler(signo, stack_frame):
    logging.info("Catch Exit Signal ({}) ...".format(signo))
    if signo == signal.SIGHUP:
        exit_code = 0
    elif signo == signal.SIGINT:
        exit_code = 100
    elif signo == signal.SIGQUIT:
        exit_code = 102
    elif signo == signal.SIGTERM:
        exit_code = 101

    zynqtgui.exit(exit_code)


signal.signal(signal.SIGHUP, exit_handler)
signal.signal(signal.SIGINT, exit_handler)
signal.signal(signal.SIGQUIT, exit_handler)
signal.signal(signal.SIGTERM, exit_handler)


def delete_window():
    exit_code = 101
    zynqtgui.exit(exit_code)


# Function to handle computer keyboard key press
#     event: Key event
# def cb_keybinding(event):
# logging.debug("Key press {} {}".format(event.keycode, event.keysym))
# zynthian_gui_config.top.focus_set() # Must remove focus from listbox to avoid interference with physical keyboard

# if not zynthian_gui_keybinding.getInstance().isEnabled():
# logging.debug("Key binding is disabled - ignoring key press")
# return

## Ignore TAB key (for now) to avoid confusing widget focus change
# if event.keysym == "Tab":
# return

## Space is not recognised as keysym so need to convert keycode
# if event.keycode == 65:
# keysym = "Space"
# else:
# keysym = event.keysym

# action = zynthian_gui_keybinding.getInstance().get_key_action(keysym, event.state)
# if action != None:
# zynqtgui.callable_ui_action(action)


# zynthian_gui_config.top.bind("<Key>", cb_keybinding)

# zynthian_gui_config.top.protocol("WM_DELETE_WINDOW", delete_window)

# ------------------------------------------------------------------------------
# TKinter Main Loop
# ------------------------------------------------------------------------------

# import cProfile
# cProfile.run('zynthian_gui_config.top.mainloop()')

# zynthian_gui_config.top.mainloop()

# logging.info("Exit with code {} ...\n\n".format(zynqtgui.exit_code))
# exit(zynqtgui.exit_code)


# ------------------------------------------------------------------------------
# GUI & Synth Engine initialization
# ------------------------------------------------------------------------------

if __name__ == "__main__":
    boot_start = timer()

    # Start rainbow led process
    rainbow_led_process = Popen(("python3", "zynqtgui/zynthian_gui_led_config.py", "rainbow"))

    # Enable qml debugger if ZYNTHBOX_DEBUG env variable is set
    if os.environ.get("ZYNTHBOX_DEBUG"):
        debug = QQmlDebuggingEnabler()

    ### Tracktion config file `/root/.config/libzynthbox/Settings.xml` sometimes reconfigures and sets
    ### the value <VALUE name="audiosettings_JACK"><AUDIODEVICE outEnabled="0" inEnabled="0" monoChansOut="0" stereoChansIn="0"/></VALUE>
    ### which causes no audio output from libzynthbox. To circumvent this isssue, always remove the following
    ### three tags from the xml : <VALUE name="audiosettings_JACK">, <VALUE name="defaultWaveDevice_JACK">
    ### and <VALUE name="defaultWaveInDevice_JACK"
    ### Remove these above 3 tags from xml before initializing libzynthbox
    ### FIXME : Find the root cause of the issue instead of this workaround
    try:
        if Path("/root/.config/libzynthbox/Settings.xml").exists():
            logging.debug(f"libzynthbox settings file found. Removing elements")
            tree = ET.parse('/root/.config/libzynthbox/Settings.xml')
            root = tree.getroot()

            e1 = root.find(".//VALUE[@name='audiosettings_JACK']")
            e2 = root.find(".//VALUE[@name='defaultWaveDevice_JACK']")
            e3 = root.find(".//VALUE[@name='defaultWaveInDevice_JACK']")
            if e1 is not None:
                logging.debug(f"Removing element audiosettings_JACK")
                root.remove(e1)
            if e2 is not None:
                logging.debug(f"Removing element defaultWaveDevice_JACK")
                root.remove(e2)
            if e3 is not None:
                logging.debug(f"Removing element defaultWaveInDevice_JACK")
                root.remove(e3)

            tree.write("/root/.config/libzynthbox/Settings.xml")
    except Exception as e:
        logging.error(f"Error updating libzynthbox Settings.xml : {str(e)}")

    ###

    QGuiApplication.setOrganizationName("zynthbox")
    QGuiApplication.setApplicationName("zynthbox-qml")

    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()

    if zynthian_gui_config.force_enable_cursor == False:
        nullCursor = QPixmap(16, 16);
        nullCursor.fill(Qt.transparent);
        app.setOverrideCursor(QCursor(nullCursor));

    logging.info("REGISTERING QML TYPES")
    qmlRegisterType(file_properties_helper, "Helpers", 1, 0, "FilePropertiesHelper")
    Zynthbox.Plugin.instance().registerTypes(engine, "io.zynthbox.components")

    logging.info("STARTING ZYNTHIAN-UI ...")
    zynthian_gui_config.zynqtgui = zynqtgui = zynthian_gui()
    logging.debug("---p Starting zynqtgui")
    zynqtgui.start()
    logging.debug("---p zynqtgui complete")
    zynqtgui.sketchpad.init() # Call init after zynqtgui initialization is complete
    QIcon.setThemeName("breeze")    
    palette = app.palette()
    bgColor = QColor(zynthian_gui_config.color_bg)
    txColor = QColor(zynthian_gui_config.color_tx)
    palette.setColor(QPalette.Window, bgColor)
    palette.setColor(QPalette.WindowText, txColor)
    ratio = 0.2
    btnColor = QColor(
        bgColor.red() * (1 - ratio) + txColor.red() * ratio,
        bgColor.green() * (1 - ratio) + txColor.green() * ratio,
        bgColor.blue() * (1 - ratio) + txColor.blue() * ratio,
        255,
    )
    palette.setColor(QPalette.Button, btnColor)
    palette.setColor(QPalette.ButtonText, QColor(zynthian_gui_config.color_tx))
    palette.setColor(QPalette.Highlight, QColor(zynthian_gui_config.color_on))
    palette.setColor(QPalette.Base, QColor(zynthian_gui_config.color_panel_bd))
    palette.setColor(QPalette.Text, QColor(zynthian_gui_config.color_tx))
    palette.setColor(QPalette.HighlightedText, zynthian_gui_config.color_tx)
    app.setPalette(palette)
    zynqtgui.screens["theme_chooser"].apply_font()
    zynqtgui.show_screen(zynqtgui.home_screen)
    zynqtgui.screens["preset"].disable_show_fav_presets()
    engine.addImportPath(os.fspath(Path(__file__).resolve().parent / "qml-ui"))
    engine.rootContext().setContextProperty("zynqtgui", zynqtgui)

    def load_qml():
        if zynqtgui.sketchpad.sketchpadLoadingInProgress:
            # logging.debug("Sketchpad Loading is still in progress. Delay loading qml")
            QTimer.singleShot(100, load_qml)
        else:
            logging.debug("---p Starting loading qml")
            zynqtgui.currentTaskMessage = "Loading Core UI"
            engine.load(os.fspath(Path(__file__).resolve().parent / "qml-ui/main.qml"))
            logging.debug("---p After loading qml engine")
            if not engine.rootObjects() or not app.topLevelWindows():
                sys.exit(-1)

            # assuming there is one and only one window for now
            zynthian_gui_config.top = app.topLevelWindows()[0]
            zynthian_gui_config.app = app

            # Notify isExternalActive changed when top window active value changes
            zynthian_gui_config.top.activeChanged.connect(lambda: zynqtgui.isExternalAppActiveChanged.emit())

    # Delay loading qml to let zynqtgui complete it's init sequence
    # Without the delay, UI sometimes doest start when `systemctl restart zynthian` is ran
    QTimer.singleShot(1000, load_qml)

    sys.exit(app.exec_())

# ------------------------------------------------------------------------------
