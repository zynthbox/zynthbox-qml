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
import sys
import copy
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

from zynqtgui.sketchpad_copier import zynthian_gui_sketchpad_copier
from zynqtgui.song_arranger import zynthian_gui_song_arranger
from zynqtgui.zynthian_gui_bluetooth_config import zynthian_gui_bluetooth_config
from zynqtgui.zynthian_gui_song_player import zynthian_gui_song_player
from zynqtgui.zynthian_gui_song_manager import zynthian_gui_song_manager
from zynqtgui.sound_categories.zynthian_gui_sound_categories import zynthian_gui_sound_categories
from zynqtgui.utils import file_properties_helper
from zynqtgui.zynthian_gui_audio_settings import zynthian_gui_audio_settings
from zynqtgui.zynthian_gui_led_config import zynthian_gui_led_config
from zynqtgui.zynthian_gui_wifi_settings import zynthian_gui_wifi_settings

sys.path.insert(1, "/zynthian/zynthian-ui/")
sys.path.insert(1, "./zynqtgui")

# Zynthian specific modules
import zynconf
import zynautoconnect
#from zynlibs.jackpeak import lib_jackpeak_init
from zyncoder import *
from zyncoder.zyncoder import lib_zyncoder_init
from zyngine import zynthian_controller, zynthian_zcmidi
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
from zynqtgui.zynthian_gui_midi_recorder import zynthian_gui_midi_recorder
from zynqtgui.zynthian_gui_test_touchpoints import (
    zynthian_gui_test_touchpoints,
)
from zynqtgui.zynthian_gui_playgrid import zynthian_gui_playgrid
from zynqtgui.sketchpad.zynthian_gui_sketchpad import (
    zynthian_gui_sketchpad,
)

# if "autoeq" in zynthian_gui_config.experimental_features:
# from zynqtgui.zynthian_gui_autoeq import zynthian_gui_autoeq
# if "zynseq" in zynthian_gui_config.experimental_features:
# from zynqtgui.zynthian_gui_stepsequencer import zynthian_gui_stepsequencer
# from zynqtgui.zynthian_gui_touchscreen_calibration import zynthian_gui_touchscreen_calibration

# from zynqtgui.zynthian_gui_control_osc_browser import zynthian_gui_osc_browser

from zynqtgui.zynthian_gui_theme_chooser import zynthian_gui_theme_chooser
from zynqtgui.zynthian_gui_newstuff import zynthian_gui_newstuff

from zynqtgui.zynthian_gui_guioptions import zynthian_gui_guioptions

from zynqtgui.zynthian_gui_synth_behaviour import zynthian_gui_synth_behaviour
from zynqtgui.zynthian_gui_snapshots_menu import zynthian_gui_snapshots_menu
from zynqtgui.zynthian_gui_network import zynthian_gui_network
from zynqtgui.zynthian_gui_hardware import zynthian_gui_hardware
from zynqtgui.zynthian_gui_test_knobs import zynthian_gui_test_knobs

from zynqtgui.session_dashboard.zynthian_gui_session_dashboard import zynthian_gui_session_dashboard
from zynqtgui.zynthian_gui_master_alsa_mixer import zynthian_gui_master_alsa_mixer

from zynqtgui.zynthian_osd import zynthian_osd

from zynqtgui.sketchpad.libzl import libzl

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
        self.status_info["midi_recorder"] = False

        self.dpm_rangedB = 30  # Lowest meter reading in -dBFS
        self.dpm_highdB = 10  # Start of yellow zone in -dBFS
        self.dpm_overdB = 3  # Start of red zone in -dBFS
        self.dpm_high = 1 - self.dpm_highdB / self.dpm_rangedB
        self.dpm_over = 1 - self.dpm_overdB / self.dpm_rangedB

    def set_status(self, status):
        midi_recorder_has_changed = False
        if "midi_recorder" in status and "midi_recorder" in self.status_info and self.status_info["midi_recorder"] is not status["midi_recorder"]:
            midi_recorder_has_changed = True
        elif "midi_recorder" in status and "midi_recorder" not in self.status_info:
            midi_recorder_has_changed = True
        elif "midi_recorder" not in status and "midi_recorder" in self.status_info:
            midi_recorder_has_changed = True
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
        if midi_recorder_has_changed is True:
            self.midi_recorder_changed.emit()
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

    midi_recorder_changed = Signal()
    def get_midi_recorder(self):
        if "midi_recorder" in self.status_info:
            return self.status_info["midi_recorder"]
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
    midi_recorder = Property(str, get_midi_recorder, notify=midi_recorder_changed)

    rangedB = Property(float, get_rangedB, constant=True)
    highdB = Property(float, get_highdB, constant=True)
    overdB = Property(float, get_overdB, constant=True)
    high = Property(float, get_high, constant=True)
    over = Property(float, get_over, constant=True)


# -------------------------------------------------------------------------------
# Zynthian Main GUI Class
# -------------------------------------------------------------------------------


class zynthian_gui(QObject):

    screens_sequence = (
        #"session_dashboard",  #FIXME or main? make this more configurable?
        "sketchpad",
        "layers_for_channel",
        "bank",
        "preset",
        "control",
        "layer_effects",
        "layer_midi_effects",
    )
    non_modal_screens = (
        #"session_dashboard",  #FIXME or main? make this more configurable?
        "sketchpad",
        "main",
        "layer",
        "fixed_layers",
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
        "51": "SELECT",
        "52": "SELECT_UP",
        "53": "SELECT_DOWN",
        "54": "BACK_UP",
        "55": "BACK_DOWN",
        "56": "LAYER_UP",
        "57": "LAYER_DOWN",
        "58": "SNAPSHOT_UP",
        "59": "SNAPSHOT_DOWN",
        "64": "SWITCH_BACK_SHORT",
        "63": "SWITCH_BACK_BOLD",
        "62": "SWITCH_BACK_LONG",
        "65": "SWITCH_SELECT_SHORT",
        "66": "SWITCH_SELECT_BOLD",
        "67": "SWITCH_SELECT_LONG",
        "60": "SWITCH_LAYER_SHORT",
        "61": "SWITCH_LAYER_BOLD",
        "68": "SWITCH_LAYER_LONG",
        "71": "SWITCH_SNAPSHOT_SHORT",
        "72": "SWITCH_SNAPSHOT_BOLD",
        "73": "SWITCH_SNAPSHOT_LONG",
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
        "95": "MODAL_STEPSEQ",
        "96": "NAVIGATE_RIGHT",
        "101": "LAYER_1",
        "102": "LAYER_2",
        "103": "LAYER_3",
        "104": "LAYER_4",
        "105": "LAYER_5",
        "106": "LAYER_6",
        "107": "INCREASE",
        "108": "DECREASE",
        "109": "KEYBOARD",
    }

    def __init__(self, parent=None):
        super(zynthian_gui, self).__init__(parent)

        self.bpmBeforePressingMetronome = 0
        self.volumeBeforePressingMetronome = 0
        self.delayBeforePressingMetronome = 0
        self.reverbBeforePressingMetronome = 0
        self.__current_task_message = ""
        self.__recent_task_messages = queue.Queue()
        self.__show_current_task_message = True
        self.currentTaskMessageChanged.connect(self.save_currentTaskMessage, Qt.QueuedConnection)
        self.currentTaskMessage = f"Starting Zynthbox QML"

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

        self.__switch_channels_button_pressed__ = False
        self.__alt_button_pressed__ = False
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
        self.__global_popup_opened__ = False
        self.__passive_notification = ""
        self.__splash_stopped = False

        # When true, 1-5 buttons selects channel 6-10
        self.channels_mod_active = False

        self.song_bar_active = False
        self.slots_bar_part_active = False
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
        self.rainbow_led_counter = 0

        # If * button is pressed, it toggles itself on/off for 5000ms before returning to previous state.
        # Use this timer to toggle state after 5000ms
        self.channelsModTimer = QTimer(self)
        self.channelsModTimer.setInterval(3000)
        self.channelsModTimer.setSingleShot(True)
        self.channelsModTimer.timeout.connect(self.channelsModTimerHandler)

        speed_settings = QSettings("/home/pi/config/gui_optionsrc", QSettings.IniFormat)
        if speed_settings.status() != QSettings.NoError:
            self.__encoder_list_speed_multiplier = 4
        else:
            speed_settings.beginGroup("Encoder0")
            self.__encoder_list_speed_multiplier = None
            try:
                self.__encoder_list_speed_multiplier = int(speed_settings.value("speed"));
            except:
                pass
            if self.__encoder_list_speed_multiplier is None:
                self.__encoder_list_speed_multiplier = 4

        self.info_timer = QTimer(self)
        self.info_timer.setInterval(3000)
        self.info_timer.setSingleShot(False)
        self.info_timer.timeout.connect(self.hide_info)
        # HACK: in order to start the timer from the proper thread
        self.current_modal_screen_id_changed.connect(self.info_timer.start, Qt.QueuedConnection)
        self.current_qml_page_prop = None

        #FIXME HACK: this spams is_loading_changed on the proper thread until the ui gets it, can it be done properly?
        self.deferred_loading_timer = QTimer(self)
        self.deferred_loading_timer.setInterval(0)
        self.deferred_loading_timer.setSingleShot(False)
        self.deferred_loading_timer_start.connect(self.deferred_loading_timer.start)
        self.deferred_loading_timer_stop.connect(self.deferred_loading_timer.stop)
        self.deferred_loading_timer.timeout.connect(self.is_loading_changed)

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
        self.__zselector = [None, None, None, None]
        self.__zselector_ctrl = [None, None, None, None]
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

        # Initialize peakmeter audio monitor if needed
        #if not zynthian_gui_config.show_cpu_status:
            #try:
                #global lib_jackpeak
                #lib_jackpeak = lib_jackpeak_init()
                #lib_jackpeak.setDecay(c_float(0.2))
                #lib_jackpeak.setHoldCount(10)
            #except Exception as e:
                #logging.error("ERROR initializing jackpeak: %s" % e)

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

        #if "zynseq" in zynthian_gui_config.experimental_features:
            #self.libseq = CDLL(
                #"/zynthian/zynthian-ui/zynlibs/zynseq/build/libzynseq.so"
            #)
            #self.libseq.init(True)

        # Initialise libzl (which requires things found in zyncoder, specifically the zynthian midi router)
        libzl.init()

    @Slot()
    def channelsModTimerHandler(self):
        # If * button is pressed, it toggles itself on/off for 5000ms before returning
        # to state where it shows current channel.

        # Set channelsModActive to true when channel 5-10 is active
        self.channelsModActive = self.session_dashboard.selectedChannel >= 5

    @Slot(None)
    def save_currentTaskMessage(self):
        while self.__recent_task_messages.empty() is False:
            theMessage = self.__recent_task_messages.get()
            if ((hasattr(self, "__booting_complete__") and not self.__booting_complete__) or not hasattr(self, "__booting_complete__")) and bootlog_fifo is not None and len(theMessage) > 0:
                os.write(bootlog_fifo, f"{theMessage}\n".encode())
            self.__recent_task_messages.task_done()

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
        except: pass
    ### END SHOW SCREEN QUEUE

    ### Global controller and selector
    @Slot(None)
    def zyncoder_set_bpm(self):
        if self.globalPopupOpened or self.metronomeButtonPressed:
            self.set_bpm_actual(np.clip(self.__zselector[0].value, 50, 200))

    @Slot(None)
    def set_bpm(self, bpm):
        self.set_bpm_actual(bpm, False)

    def set_bpm_actual(self, bpm, takeControlOfSelector = True):
        """
            Set song bpm when global popup is active
        """

        # FIXME : Sometimes when this method is called, the value of zselector is 0
        #         which is causing division by zero error.

        song = self.sketchpad.song
        bpm = int(bpm)
        if song is not None and song.bpm != bpm:
            song.bpm = bpm
            # Show bpm osd when global popup is not open
            # Since when global popup is open, bpm change can be visualized with dial value change
            if not self.globalPopupOpened:
                self.osd.updateOsd(
                    parameterName="song_bpm",
                    description=f"Song BPM",
                    start=50,
                    stop=200,
                    step=1,
                    defaultValue=120,
                    currentValue=song.bpm,
                    setValueFunction=self.set_bpm_actual,
                    showValueLabel=True,
                )

            if takeControlOfSelector is True:
                self.set_selector()

    def get_volume(self):
        value = 0
        if self.master_alsa_mixer is not None:
            value = self.master_alsa_mixer.volume
        return value

    def set_volume(self, value):
        self.set_volume_actual(value, False)

    @Slot(None)
    def zyncoder_set_volume(self):
        if self.globalPopupOpened or self.metronomeButtonPressed:
            self.set_volume_actual(self.__zselector[1].value)

    def set_volume_actual(self, volume, takeControlOfSelector = True):
        """
        Set volume when global popup is active
        """

        volume = int(volume)
        if self.master_alsa_mixer is not None and \
                self.master_alsa_mixer.volume != volume:
            self.master_alsa_mixer.set_volume(volume, takeControlOfSelector)

            if not self.globalPopupOpened:
                self.osd.updateOsd(
                    parameterName="master_volume",
                    description=f"Master Volume",
                    start=0,
                    stop=100,
                    step=1,
                    defaultValue=self.master_alsa_mixer.initialVolume,
                    currentValue=volume,
                    setValueFunction=self.set_volume_actual,
                    showValueLabel=True,
                    showResetToDefault=True,
                    showVisualZero=True
                )

            if takeControlOfSelector is True:
                self.set_selector()

    def get_global_fx1_amount(self):
        value = 0
        if self.global_fx_engines[0] is not None:
            controller = self.global_fx_engines[0][1]
            if controller is not None:
                value = np.interp(controller.value, [controller.value_min, controller.value_max], [0, 100])
        return value

    def set_global_fx1_amount(self, value):
        self.set_delay_actual(value, False)

    @Slot(None)
    def zyncoder_set_delay(self):
        if self.globalPopupOpened or self.metronomeButtonPressed:
            self.set_delay_actual(self.__zselector[2].value)

    def set_delay_actual(self, delay_percent, takeControlOfSelector = True):
        """
        Set global fx delay when global popup is active
        """

        if self.global_fx_engines[0] is not None:
            controller = self.global_fx_engines[0][1]
            delay_percent = int(delay_percent)
            delay = np.interp(delay_percent, [0, 100], [controller.value_min, controller.value_max])

            if controller is not None and \
                    controller.value != delay:
                controller.set_value(delay, True)

                self.osd.updateOsd(
                    parameterName="global_delay",
                    description=f"Global Delay FX",
                    start=0,
                    stop=100,
                    step=1,
                    defaultValue=10,
                    currentValue=delay_percent,
                    setValueFunction=self.set_delay_actual,
                    showValueLabel=True,
                    showResetToDefault=True,
                    showVisualZero=True
                )

                if takeControlOfSelector is True:
                    self.set_selector()

    def get_global_fx2_amount(self):
        value = 0
        if self.global_fx_engines[1] is not None:
            controller = self.global_fx_engines[1][1]
            if controller is not None:
                value = np.interp(controller.value, [controller.value_min, controller.value_max], [0, 100])
        return value

    def set_global_fx2_amount(self, value):
        self.set_reverb_actual(value, False)

    @Slot(None)
    def zyncoder_set_reverb(self):
        if self.globalPopupOpened or self.metronomeButtonPressed:
            self.set_reverb_actual(self.__zselector[3].value)

    def set_reverb_actual(self, reverb_percent, takeControlOfSelector = True):
        """
        Set global fx reverb when global popup is active
        """

        if self.global_fx_engines[1] is not None:
            controller = self.global_fx_engines[1][1]
            reverb_percent = int(reverb_percent)
            reverb = np.interp(reverb_percent, [0, 100], [controller.value_min, controller.value_max])

            if controller is not None and \
                    controller.value != reverb:
                controller.set_value(reverb, True)

                self.osd.updateOsd(
                    parameterName="global_reverb",
                    description=f"Global Reverb FX",
                    start=0,
                    stop=100,
                    step=1,
                    defaultValue=10,
                    currentValue=reverb_percent,
                    setValueFunction=self.set_reverb_actual,
                    showValueLabel=True,
                    showResetToDefault=True,
                    showVisualZero=True
                )

                if takeControlOfSelector is True:
                    self.set_selector()

    @Slot(None)
    def zyncoder_set_current_index(self):
        """
        Set current index when there is an open file dialog
        """

        if self.openedDialog is not None and self.openedDialog.property("listCurrentIndex") is not None:
            if self.openedDialog.property("listCurrentIndex") != self.__zselector[0].value:
                self.openedDialog.setProperty("listCurrentIndex", self.__zselector[0].value)
                logging.debug(f"Setting listCurrentIndex of openedDialog({self.openedDialog}) to {self.__zselector[0].value}")
                self.set_selector()


    @Slot(None)
    def zyncoder_set_channel_volume(self):
        if self.altButtonPressed:
            self.set_channel_volume_actual(self.__zselector[1].value)

    def set_channel_volume_actual(self, volume, takeControlOfSelector=True):
        """
        Set channel volume when altButton is pressed
        """

        selected_channel = self.sketchpad.song.channelsModel.getChannel(self.session_dashboard.selectedChannel)
        value = round(np.interp(round(volume), (0, 100), (-40, 20)))

        if selected_channel.volume != value:
            selected_channel.volume = value

            if takeControlOfSelector is True:
                self.set_selector()

            self.osd.updateOsd(
                parameterName="channel_volume",
                description=f"Channel Volume",
                start=0,
                stop=100,
                step=1,
                defaultValue=None,
                currentValue=volume,
                setValueFunction=self.set_channel_volume_actual,
                showValueLabel=True,
                showResetToDefault=False,
                showVisualZero=False,
            )

    @Slot(None)
    def zyncoder_set_channel_delay_send_amount(self):
        if self.altButtonPressed:
            self.zyncoder_set_channel_delay_send_amount_actual(self.__zselector[2].value)

    def zyncoder_set_channel_delay_send_amount_actual(self, delay, takeControlOfSelector=True):
        """
        Set channel delay send amount when altButton is pressed
        """
        
        value = round(np.interp(round(delay), (0, 100), (0, 1)), 1)

        if round(libzl.getWetFx1Amount(self.session_dashboard.selectedChannel), 1) != value:
            libzl.setWetFx1Amount(self.session_dashboard.selectedChannel, value)

            if takeControlOfSelector is True:
                self.set_selector()

            self.osd.updateOsd(
                parameterName="channel_delay_send",
                description=f"Delay FX Send amount for Channel {self.session_dashboard.selectedChannel + 1}",
                start=0,
                stop=100,
                step=1,
                defaultValue=100,
                currentValue=round(delay),
                setValueFunction=self.zyncoder_set_channel_delay_send_amount_actual,
                showValueLabel=True,
                showResetToDefault=True,
                showVisualZero=True
            )

    @Slot(None)
    def zyncoder_set_channel_reverb_send_amount(self):
        if self.altButtonPressed:
            self.zyncoder_set_channel_reverb_send_amount_actual(self.__zselector[3].value)

    def zyncoder_set_channel_reverb_send_amount_actual(self, reverb, takeControlOfSelector=True):
        """
        Set channel reverb send amount when altButton is pressed
        """

        value = round(np.interp(round(reverb), (0, 100), (0, 1)), 1)

        if round(libzl.getWetFx2Amount(self.session_dashboard.selectedChannel), 1) != value:
            libzl.setWetFx2Amount(self.session_dashboard.selectedChannel, value)

            if takeControlOfSelector is True:
                self.set_selector()

            self.osd.updateOsd(
                parameterName="channel_reverb_send",
                description=f"Reverb FX Send amount for Channel {self.session_dashboard.selectedChannel + 1}",
                start=0,
                stop=100,
                step=1,
                defaultValue=100,
                currentValue=round(reverb),
                setValueFunction=self.zyncoder_set_channel_reverb_send_amount_actual,
                showValueLabel=True,
                showResetToDefault=True,
                showVisualZero=True
            )

    def configure_big_knob(self):
        # Configure Big Knob to set BPM
        try:
            if self.__zselector[0] is not None:
                self.__zselector[0].show()

            logging.debug(f"### set_selector : Configuring big knob to set bpm")

            value = 0
            min_value = 0
            max_value = 0

            # If openedDialog has listCurrentIndex and listCount property control currentIndex of that dialog with BK
            if self.openedDialog is not None and self.openedDialog.property("listCurrentIndex") is not None and self.openedDialog.property("listCount") is not None:
                value = self.openedDialog.property("listCurrentIndex")
                min_value = 0
                max_value = self.openedDialog.property("listCount")

                if self.__zselector[0] is None:
                    self.__zselector_ctrl[0] = zynthian_controller(None, 'global_big_knob', 'global_big_knob',
                                                                   {'midi_cc': 0, 'value': value,
                                                                    'step': 1})

                    self.__zselector[0] = zynthian_gui_controller(3, self.__zselector_ctrl[0], self)
                    self.__zselector[0].show()

                self.__zselector_ctrl[0].set_options(
                    {'symbol': 'global_big_knob', 'name': 'global_big_knob', 'short_name': 'global_big_knob',
                     'midi_cc': 0,
                     'value_max': max_value, 'value': value, 'value_min': min_value, 'step': 1})

                self.__zselector[0].config(self.__zselector_ctrl[0])
            else:
                song = self.sketchpad.song
                if song is not None:
                    value = song.bpm
                    min_value = 50
                    max_value = 200 + 1

                if self.__zselector[0] is None:
                    self.__zselector_ctrl[0] = zynthian_controller(None, 'global_big_knob', 'global_big_knob',
                                                                   {'midi_cc': 0, 'value': value,
                                                                    'step': 1})

                    self.__zselector[0] = zynthian_gui_controller(3, self.__zselector_ctrl[0], self)
                    self.__zselector[0].show()

                self.__zselector_ctrl[0].set_options(
                    {'symbol': 'global_big_knob', 'name': 'global_big_knob', 'short_name': 'global_big_knob',
                     'midi_cc': 0,
                     'value_max': max_value, 'value': value, 'value_min': min_value, 'step': 1})

                self.__zselector[0].config(self.__zselector_ctrl[0])
        except:
            if self.__zselector[0] is not None:
                self.__zselector[0].hide()

    def configure_small_knob1(self):
        # Configure Small Knob 1 to set volume
        try:
            if self.__zselector[1] is not None:
                self.__zselector[1].show()

            if self.altButtonPressed:
                logging.debug(f"### set_selector : Configuring small knob 1 to set channel volume")
                selected_channel = self.sketchpad.song.channelsModel.getChannel(self.session_dashboard.selectedChannel)

                if self.__zselector[1] is None:
                    self.__zselector_ctrl[1] = zynthian_controller(None, 'global_small_knob_1', 'global_small_knob_1', {'midi_cc': 0})
                    self.__zselector[1] = zynthian_gui_controller(0, self.__zselector_ctrl[1], self)
                    self.__zselector[1].show()

                value = round(np.interp(selected_channel.volume, (-40, 20), (0, 100)))
                self.__zselector_ctrl[1].set_options({'value_max': 101, 'value': value, 'value_min': 0, 'step': 1})
                self.__zselector[1].config(self.__zselector_ctrl[1])
            else:
                logging.debug(f"### set_selector : Configuring small knob 1 to set volume")

                value = 0
                min_value = 0
                max_value = 0

                if self.master_alsa_mixer is not None:
                    value = self.master_alsa_mixer.volume
                    min_value = 0
                    max_value = 100 + 1

                if self.__zselector[1] is None:
                    self.__zselector_ctrl[1] = zynthian_controller(None, 'global_small_knob_1', 'global_small_knob_1',
                                                                   {'midi_cc': 0, 'value': value,
                                                                    'step': 1})

                    self.__zselector[1] = zynthian_gui_controller(0, self.__zselector_ctrl[1], self)
                    self.__zselector[1].show()

                self.__zselector_ctrl[1].set_options(
                    {'symbol': 'global_small_knob_1', 'name': 'global_small_knob_1', 'short_name': 'global_small_knob_1',
                     'midi_cc': 0,
                     'value_max': max_value, 'value': value, 'value_min': min_value, 'step': 1})

                self.__zselector[1].config(self.__zselector_ctrl[1])
        except:
            if self.__zselector[1] is not None:
                self.__zselector[1].hide()

    def configure_small_knob2(self):
        # Configure Small Knob 2 to set delay
        try:
            if self.__zselector[2] is not None:
                self.__zselector[2].show()

            if self.altButtonPressed:
                logging.debug(f"### set_selector : Configuring small knob 2 to set channel delay send amount")

                if self.__zselector[2] is None:
                    self.__zselector_ctrl[2] = zynthian_controller(None, 'global_small_knob_2', 'global_small_knob_2', {'midi_cc': 0})
                    self.__zselector[2] = zynthian_gui_controller(1, self.__zselector_ctrl[2], self)
                    self.__zselector[2].show()

                value = round(np.interp(libzl.getWetFx1Amount(self.session_dashboard.selectedChannel), (0, 1), (0, 100)))
                self.__zselector_ctrl[2].set_options({'value_max': 101, 'value': value, 'value_min': 0, 'step': 1})
                self.__zselector[2].config(self.__zselector_ctrl[2])
            else:
                logging.debug(f"### set_selector : Configuring small knob 2 to set delay")

                value = 0
                min_value = 0
                max_value = 0

                if self.global_fx_engines[0] is not None:
                    controller = self.global_fx_engines[0][1]
                    value = np.interp(controller.value, [controller.value_min, controller.value_max], [0, 100])
                    min_value = 0
                    max_value = 100 + 1

                if self.__zselector[2] is None:
                    self.__zselector_ctrl[2] = zynthian_controller(None, 'global_small_knob_2', 'global_small_knob_2',
                                                                   {'midi_cc': 0, 'value': value,
                                                                    'step': 1})

                    self.__zselector[2] = zynthian_gui_controller(1, self.__zselector_ctrl[2], self)
                    self.__zselector[2].show()

                self.__zselector_ctrl[2].set_options(
                    {'symbol': 'global_small_knob_2', 'name': 'global_small_knob_2', 'short_name': 'global_small_knob_2',
                     'midi_cc': 0,
                     'value_max': max_value, 'value': value, 'value_min': min_value, 'step': 1})

                self.__zselector[2].config(self.__zselector_ctrl[2])
                self.delayKnobValueChanged.emit()
        except:
            if self.__zselector[2] is not None:
                self.__zselector[2].hide()

    def configure_small_knob3(self):
        # Configure Small Knob 3 to set reverb
        try:
            if self.__zselector[3] is not None:
                self.__zselector[3].show()

            if self.altButtonPressed:
                logging.debug(f"### set_selector : Configuring small knob 3 to set channel reverb send amount")

                if self.__zselector[3] is None:
                    self.__zselector_ctrl[3] = zynthian_controller(None, 'global_small_knob_3', 'global_small_knob_3', {'midi_cc': 0})
                    self.__zselector[3] = zynthian_gui_controller(2, self.__zselector_ctrl[3], self)
                    self.__zselector[3].show()

                value = round(np.interp(libzl.getWetFx2Amount(self.session_dashboard.selectedChannel), (0, 1), (0, 100)))
                self.__zselector_ctrl[3].set_options({'value_max': 101, 'value': value, 'value_min': 0, 'step': 1})
                self.__zselector[3].config(self.__zselector_ctrl[3])
            else:
                logging.debug(f"### set_selector : Configuring small knob 3 to set reverb")

                value = 0
                min_value = 0
                max_value = 0

                if self.global_fx_engines[1] is not None:
                    controller = self.global_fx_engines[1][1]
                    value = np.interp(controller.value, [controller.value_min, controller.value_max], [0, 100])
                    min_value = 0
                    max_value = 100 + 1

                if self.__zselector[3] is None:
                    self.__zselector_ctrl[3] = zynthian_controller(None, 'global_small_knob_3', 'global_small_knob_3',
                                                                   {'midi_cc': 0, 'value': value,
                                                                    'step': 1})

                    self.__zselector[3] = zynthian_gui_controller(2, self.__zselector_ctrl[3], self)
                    self.__zselector[3].show()

                self.__zselector_ctrl[3].set_options(
                    {'symbol': 'global_small_knob_3', 'name': 'global_small_knob_3', 'short_name': 'global_small_knob_3',
                     'midi_cc': 0,
                     'value_max': max_value, 'value': value, 'value_min': min_value, 'step': 1})

                self.__zselector[3].config(self.__zselector_ctrl[3])
                self.reverbKnobValueChanged.emit()
        except:
            if self.__zselector[3] is not None:
                self.__zselector[3].hide()

    def set_selector(self):
        if self.globalPopupOpened or self.metronomeButtonPressed or self.altButtonPressed:
            self.configure_big_knob()
            self.configure_small_knob1()
            self.configure_small_knob2()
            self.configure_small_knob3()
        elif self.openedDialog is not None and self.openedDialog.property("listCurrentIndex") is not None:
            # If openedDialog has listCurrentIndex and listCount property controll currentIndex of that dialog with BK.
            # Hence configure big knob
            self.configure_big_knob()

            if self.__zselector[1] is not None:
                self.__zselector[1].hide()
            if self.__zselector[2] is not None:
                self.__zselector[2].hide()
            if self.__zselector[3] is not None:
                self.__zselector[3].hide()
        else:
            if self.__zselector[0] is not None:
                self.__zselector[0].hide()
            if self.__zselector[1] is not None:
                self.__zselector[1].hide()
            if self.__zselector[2] is not None:
                self.__zselector[2].hide()
            if self.__zselector[3] is not None:
                self.__zselector[3].hide()
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
            self.screens["sketchpad"].set_selector()
            self.songBarActiveChanged.emit()

    songBarActiveChanged = Signal()

    songBarActive = Property(bool, get_song_bar_active, set_song_bar_active, notify=songBarActiveChanged)

    def get_sound_combinator_active(self):
        return self.sound_combinator_active

    def set_sound_combinator_active(self, isActive):
        if self.sound_combinator_active != isActive:
            self.sound_combinator_active = isActive
            self.screens["sketchpad"].set_selector()
            self.soundCombinatorActiveChanged.emit()

    soundCombinatorActiveChanged = Signal()

    soundCombinatorActive = Property(bool, get_sound_combinator_active, set_sound_combinator_active,
                                     notify=soundCombinatorActiveChanged)

    def get_channel_wave_editor_bar_active(self):
        return self.channel_wave_editor_bar_active

    def set_channel_wave_editor_bar_active(self, isActive):
        if self.channel_wave_editor_bar_active != isActive:
            self.channel_wave_editor_bar_active = isActive
            self.screens["sketchpad"].set_selector()
            self.channelWaveEditorBarActiveChanged.emit()

    channelWaveEditorBarActiveChanged = Signal()

    channelWaveEditorBarActive = Property(bool, get_channel_wave_editor_bar_active, set_channel_wave_editor_bar_active,
                                     notify=channelWaveEditorBarActiveChanged)

    def get_channel_samples_bar_active(self):
        return self.channel_samples_bar_active

    def set_channel_samples_bar_active(self, isActive):
        if self.channel_samples_bar_active != isActive:
            self.channel_samples_bar_active = isActive
            self.screens["sketchpad"].set_selector()
            self.channelSamplesBarActiveChanged.emit()

    channelSamplesBarActiveChanged = Signal()

    channelSamplesBarActive = Property(bool, get_channel_samples_bar_active, set_channel_samples_bar_active,
                                     notify=channelSamplesBarActiveChanged)

    def get_clip_wave_editor_bar_active(self):
        return self.clip_wave_editor_bar_active

    def set_clip_wave_editor_bar_active(self, isActive):
        if self.clip_wave_editor_bar_active != isActive:
            self.clip_wave_editor_bar_active = isActive
            self.screens["sketchpad"].set_selector()
            self.clipWaveEditorBarActiveChanged.emit()

    clipWaveEditorBarActiveChanged = Signal()

    clipWaveEditorBarActive = Property(bool, get_clip_wave_editor_bar_active, set_clip_wave_editor_bar_active,
                                       notify=clipWaveEditorBarActiveChanged)

    def get_slots_bar_channel_active(self):
        return self.slots_bar_channel_active

    def set_slots_bar_channel_active(self, isActive):
        if self.slots_bar_channel_active != isActive:
            self.slots_bar_channel_active = isActive
            self.screens["sketchpad"].set_selector()
            self.slotsBarChannelActiveChanged.emit()

    slotsBarChannelActiveChanged = Signal()

    slotsBarChannelActive = Property(bool, get_slots_bar_channel_active, set_slots_bar_channel_active,
                                   notify=slotsBarChannelActiveChanged)

    def get_slots_bar_mixer_active(self):
        return self.slots_bar_mixer_active

    def set_slots_bar_mixer_active(self, isActive):
        if self.slots_bar_mixer_active != isActive:
            self.slots_bar_mixer_active = isActive
            self.screens["sketchpad"].set_selector()
            self.slotsBarMixerActiveChanged.emit()

    slotsBarMixerActiveChanged = Signal()

    slotsBarMixerActive = Property(bool, get_slots_bar_mixer_active, set_slots_bar_mixer_active,
                                   notify=slotsBarMixerActiveChanged)

    def get_slots_bar_part_active(self):
        return self.slots_bar_part_active

    def set_slots_bar_part_active(self, isActive):
        if self.slots_bar_part_active != isActive:
            self.slots_bar_part_active = isActive
            self.screens["sketchpad"].set_selector()
            self.slotsBarPartActiveChanged.emit()

    slotsBarPartActiveChanged = Signal()

    slotsBarPartActive = Property(bool, get_slots_bar_part_active, set_slots_bar_part_active, notify=slotsBarPartActiveChanged)

    def get_slots_bar_synths_active(self):
        return self.slots_bar_synths_active

    def set_slots_bar_synths_active(self, isActive):
        if self.slots_bar_synths_active != isActive:
            self.slots_bar_synths_active = isActive
            self.screens["sketchpad"].set_selector()
            self.slotsBarSynthsActiveChanged.emit()

    slotsBarSynthsActiveChanged = Signal()

    slotsBarSynthsActive = Property(bool, get_slots_bar_synths_active, set_slots_bar_synths_active,
                                    notify=slotsBarSynthsActiveChanged)

    def get_slots_bar_samples_active(self):
        return self.slots_bar_samples_active

    def set_slots_bar_samples_active(self, isActive):
        if self.slots_bar_samples_active != isActive:
            self.slots_bar_samples_active = isActive
            self.screens["sketchpad"].set_selector()
            self.slotsBarSamplesActiveChanged.emit()

    slotsBarSamplesActiveChanged = Signal()

    slotsBarSamplesActive = Property(bool, get_slots_bar_samples_active, set_slots_bar_samples_active,
                                     notify=slotsBarSamplesActiveChanged)

    def get_slots_bar_fx_active(self):
        return self.slots_bar_fx_active

    def set_slots_bar_fx_active(self, isActive):
        if self.slots_bar_fx_active != isActive:
            self.slots_bar_fx_active = isActive
            self.screens["sketchpad"].set_selector()
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
                # If leftSidebar is opened and stop channelsModTimer and call timer handler immediately
                QMetaObject.invokeMethod(self.channelsModTimer, "stop", Qt.QueuedConnection)
                QMetaObject.invokeMethod(self, "channelsModTimerHandler", Qt.QueuedConnection)

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
            libzl.reloadZynthianConfiguration()

    """
    Initialize Global FX Engines
    This method, when called, will create all the fx engines that and store them in the list self.global_fx_engines
    Zynautoconnect will use this list of engines and connect samplersynth to these engines
    """
    def init_global_fx(self):
        logging.debug(f"Initializing global FX engines")
        self.currentTaskMessage = "Initializing Global FX Engines"

        delay_engine = self.engine.start_engine("JV/Gxdigital_delay_st")
        reverb_engine = self.engine.start_engine("JV/Roomy")

        # global_fx_engines is a list of a set of 2 elements.
        # 1st element of the set is the engine instance
        # 2nd element of the set is the zynthian controller to control fx
        self.global_fx_engines = [
            (delay_engine, delay_engine.get_lv2_controllers_dict()["LEVEL"]),
            (reverb_engine, reverb_engine.get_lv2_controllers_dict()["dry_wet"])
        ]

        self.global_fx_engines[0][1].set_value(
            np.interp(10, [0, 100], [self.global_fx_engines[0][1].value_min, self.global_fx_engines[0][1].value_max]),
            True)

        self.global_fx_engines[1][1].set_value(
            np.interp(10, [0, 100], [self.global_fx_engines[1][1].value_min, self.global_fx_engines[1][1].value_max]),
            True)

        self.delayKnobValueChanged.emit()
        self.reverbKnobValueChanged.emit()

        self.zynautoconnect(True)

        if self.sketchpad.song is not None:
            for i in range(0, self.sketchpad.song.channelsModel.count):
                channel = self.sketchpad.song.channelsModel.getChannel(i)
                channel.update_jack_port()

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
        self.currentTaskMessage = "Creating screen objects"

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
        self.screens["guioptions"] = zynthian_gui_guioptions(self)
        self.screens["audio_settings"] = zynthian_gui_audio_settings(self)
        self.screens["wifi_settings"] = zynthian_gui_wifi_settings(self)
        self.screens["synth_behaviour"] = zynthian_gui_synth_behaviour(self)
        self.screens["snapshots_menu"] = zynthian_gui_snapshots_menu(self)
        self.screens["sound_categories"] = zynthian_gui_sound_categories(self)

        self.screens["network"] = zynthian_gui_network(self)
        self.screens["network_info"] = self.screens["network"]
        self.screens["hardware"] = zynthian_gui_hardware(self)
        self.screens["test_knobs"] = zynthian_gui_test_knobs(self)

        # self.screens['touchscreen_calibration'] = zynthian_gui_touchscreen_calibration(self)
        # Create UI Apps Screens
        self.screens['alsa_mixer'] = self.screens['control']
        self.screens["audio_recorder"] = zynthian_gui_audio_recorder(self)
        self.screens["midi_recorder"] = zynthian_gui_midi_recorder(self)
        self.screens["test_touchpoints"] = zynthian_gui_test_touchpoints(self)

        ###
        # Sketchpad depends on master_alsa_mixer screen for master volume related functionalities
        # and hence needs to be initialized before ZL page has been initialized
        ###
        self.screens["master_alsa_mixer"] = zynthian_gui_master_alsa_mixer(self)

        self.screens["sketchpad"] = zynthian_gui_sketchpad(self)

        ###
        # Session Dashboard depends on ZL to load sketchpads and hence needs to be initialized after ZL page
        ###
        self.screens["session_dashboard"] = zynthian_gui_session_dashboard(self)
        ###
        # Fixed layers depends on sketchpad and session_dashboard screens and hence needs to be initialized
        # after those 2 pages
        ###
        self.screens["layers_for_channel"] = zynthian_gui_layers_for_channel(self)
        self.screens["fixed_layers"] = zynthian_gui_fixed_layers(self)
        self.screens["main_layers_view"] = zynthian_gui_fixed_layers(self)

        # if "autoeq" in zynthian_gui_config.experimental_features:
        # self.screens['autoeq'] = zynthian_gui_autoeq(self)
        # if "zynseq" in zynthian_gui_config.experimental_features:
        # self.screens['stepseq'] = zynthian_gui_stepsequencer(self)
        self.screens["theme_chooser"] = zynthian_gui_theme_chooser(self)
        self.screens["theme_downloader"] = zynthian_gui_newstuff(self)
        self.screens["sample_downloader"] = zynthian_gui_newstuff(self)
        self.screens["sound_downloader"] = zynthian_gui_newstuff(self)
        self.screens["soundfont_downloader"] = zynthian_gui_newstuff(self)
        self.screens["soundset_downloader"] = zynthian_gui_newstuff(self)
        self.screens["sequence_downloader"] = zynthian_gui_newstuff(self)
        self.screens["sketchpad_downloader"] = zynthian_gui_newstuff(self)

        ###
        # Playgrid depends on sketchpad screen for metronome related functionalities
        # and hence needs to be initialized after ZL page has been initialized
        # TODO Make the metronome independant of ZL and more generic
        ###
        self.screens["playgrid"] = zynthian_gui_playgrid(self)
        self.screens["playgrid_downloader"] = zynthian_gui_newstuff(self)
        self.screens["miniplaygrid"] = zynthian_gui_playgrid(self)

        self.screens["song_arranger"] = zynthian_gui_song_arranger(self)
        self.screens["song_player"] = zynthian_gui_song_player(self)
        self.screens["song_manager"] = zynthian_gui_song_manager(self)
        self.screens["sketchpad_copier"] = zynthian_gui_sketchpad_copier(self)

        self.screens["led_config"] = zynthian_gui_led_config(self)

        self.screens["bluetooth_config"] = zynthian_gui_bluetooth_config(self)

        # Add the OSD handler
        self.__osd = zynthian_osd(self)

        # Init Auto-connector
        zynautoconnect.start()

        # Initialize OSC
        self.osc_init()

        ###
        # Initial snapshot loading needs to be done here before starting the threads in below this block
        # Not loading the snapshots here causes a crash. It is not yet known where and why the crash happens.
        # When booting, snapshot loading occurs here based on what sketchpad is loaded.
        # For other cases sketchpad handles loading correct snapshot
        #
        # If sketchpad is loading an existing sketch, load last state snapshot to let eh euser keep working on synths
        # between restarts
        # Otherwise load a default snapshot as a new sketch wil be created
        ###
        if self.screens["sketchpad"].init_should_load_last_state:
            if not self.screens["snapshot"].load_last_state_snapshot():
                # Try loading default snapshot if loading last_state snapshot fails
                if not self.screens["snapshot"].load_default_snapshot():
                    # Show error if loading default snapshot fails
                    logging.error("Error loading default snapshot")
        else:
            if not self.screens["snapshot"].load_default_snapshot():
                # Show error if loading default snapshot fails
                logging.error("Error loading default snapshot")

        # Start polling threads
        self.start_polling()
        self.start_loading_thread()
        self.start_zyncoder_thread()

        # Run autoconnect if needed
        self.zynautoconnect_do()

        # Initialize MPE Zones
        # self.init_mpe_zones(0, 2)

        # Init GlobalFX
        self.init_global_fx()

        # Reset channels LED state on selectedChannel change
        self.session_dashboard.selected_channel_changed.connect(self.channelsModTimerHandler)

    def stop(self):
        logging.info("STOPPING ZYNTHIAN-UI ...")

        # Turn off leds
        Popen(("python3", "zynqtgui/zynthian_gui_led_config.py", "off"))

        self.stop_polling()
        self.osc_end()
        zynautoconnect.stop()
        self.screens["layer"].reset()
        self.screens[
            "midi_recorder"
        ].stop_playing()  # Need to stop timing thread
        # self.zyntransport.stop()

    def hide_screens(self, exclude=None):
        if not exclude:
            exclude = self.active_screen

        exclude_obj = self.screens[exclude]

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

        # Update curlayer when page changes if not updated when changing layers
        if not self.session_dashboard.curlayer_updated_on_channel_change:
            self.layers_for_channel.do_activate_midich_layer()
            self.session_dashboard.curlayer_updated_on_channel_change = True

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

        # Update curlayer when page changes if not updated when changing layers
        if not self.session_dashboard.curlayer_updated_on_channel_change:
            self.layers_for_channel.do_activate_midich_layer()
            self.session_dashboard.curlayer_updated_on_channel_change = True

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
        if self.modal_screen:
            return self.screens[self.modal_screen]
        else:
            return self.screens[self.active_screen]

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
        self.midi_learn_zctrl = None
        lib_zyncoder.set_midi_learning_mode(1)
        self.screens["control"].refresh_midi_bind()
        self.screens["control"].set_select_path()
        # self.show_modal('zs3_learn')

    def exit_midi_learn_mode(self):
        self.midi_learn_mode = False
        self.midi_learn_zctrl = None
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

    def set_curlayer(self, layer, save=False):
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
        self.add_screen_to_show_queue(self.screens["bank"], False, True)
        self.add_screen_to_show_queue(self.screens["preset"], False, True)
        self.add_screen_to_show_queue(self.screens["control"], False, True)
        if self.curlayer:
            self.screens["midi_key_range"].config(self.curlayer.midi_chan)
            midi_chan = self.curlayer.midi_chan
            if midi_chan < self.screens['main_layers_view'].get_start_midi_chan() or midi_chan >= self.screens['main_layers_view'].get_start_midi_chan() + self.screens['main_layers_view'].get_layers_count():
                self.screens['main_layers_view'].set_start_midi_chan(math.floor(midi_chan / 5) * 5)
        self.active_midi_channel_changed.emit()
        self.screens["main_layers_view"].sync_index_from_curlayer()
        self.screens["snapshot"].schedule_save_last_state_snapshot()


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
                    logging.debug(
                        "ACTIVE CHAN: {} => {}".format(
                            cur_active_chan, active_chan
                        )
                    )
                    # if cur_active_chan>=0:
                    #     self.all_notes_off_chan(cur_active_chan)

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

    @Slot(str)
    def callable_ui_action(self, cuia, params=None):
        logging.debug("CUIA '{}' => {}".format(cuia, params))

        channelDelta = 5 if self.channelsModActive else 0

        # Before anything else, try and ask the main window whether there's anything to be done
        try:
            cuia_callback = zynthian_gui_config.top.property("cuiaCallback")
            if cuia_callback is not None and cuia_callback.isCallable():
                _result = cuia_callback.call([cuia])
                if _result is not None and _result.toBool():
                        return
        except Exception as e:
            logging.error("Attempted to run callbacks on the main window, which apparently failed badly, with the error: {}".format(e))
            pass

        # Check if there are any open dialogs. Forward cuia events to cuiaCallback of opened dialog
        if self.opened_dialog is not None:
            try:
                cuia_callback = self.opened_dialog.property("cuiaCallback")
                visible = self.opened_dialog.property("visible")

                if cuia_callback is not None and cuia_callback.isCallable() and visible:
                    _result = cuia_callback.call([cuia])

                    if _result is not None and _result.toBool():
                        # If cuiaCallback returned true, then CUIA event has been handled by qml. Return
                        return

                if visible:
                    # If control reaches here it means either cuiaCallback property was not found or returned false
                    # In either of the case, try to close the dialog if CUIA event is SWITCH_BACK
                    try:
                        if cuia.startswith("SWITCH_BACK"):
                            logging.debug(f"SWITCH_BACK pressed. Dialog does not have a cuiaCallback property. Try closing.")
                            QMetaObject.invokeMethod(self.opened_dialog, "close", Qt.QueuedConnection)
                            return
                    except Exception as e:
                        logging.debug(f"Attempted to close openedDialog, got error: {e}")
                        pass
            except Exception as e:
                logging.error("Attempted to use cuiaCallback on openeedDialog, got error: {}".format(e))
                pass

        if cuia != "SCREEN_MAIN" and self.current_qml_page != None:
            try:
                js_value = self.current_qml_page_prop.property("cuiaCallback")
                if js_value is not None and js_value.isCallable():
                    _result = js_value.call([cuia])
                    if _result is not None and _result.toBool():
                        return
            except Exception as e:
                logging.error("Attempted to use cuiaCallback, got error: {}".format(e))
                pass

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
            time.sleep(0.1)
            self.raw_all_notes_off()

        elif cuia == "ALL_SOUNDS_OFF" or cuia == "ALL_OFF":
            self.all_notes_off()
            self.all_sounds_off()
            time.sleep(0.1)
            self.raw_all_notes_off()

        elif cuia == "START_AUDIO_RECORD":
            self.screens["audio_recorder"].start_recording()

        elif cuia == "STOP_AUDIO_RECORD":
            self.screens["audio_recorder"].stop_recording()

        elif cuia == "TOGGLE_AUDIO_RECORD":
            self.screens["audio_recorder"].toggle_recording()

        elif cuia == "START_AUDIO_PLAY":
            self.screens["audio_recorder"].start_playing()

        elif cuia == "STOP_AUDIO_PLAY":
            self.screens["audio_recorder"].stop_playing()

        elif cuia == "TOGGLE_AUDIO_PLAY":
            self.screens["audio_recorder"].toggle_playing()

        elif cuia == "START_MIDI_RECORD":
            self.screens["midi_recorder"].start_recording()

        elif cuia == "STOP_MIDI_RECORD":
            self.screens["midi_recorder"].stop_recording()

        elif cuia == "TOGGLE_MIDI_RECORD":
            self.screens["midi_recorder"].toggle_recording()

        elif cuia == "START_MIDI_PLAY":
            self.screens["midi_recorder"].start_playing()

        elif cuia == "STOP_MIDI_PLAY":
            self.screens["midi_recorder"].stop_playing()

        elif cuia == "TOGGLE_MIDI_PLAY":
            self.screens["midi_recorder"].toggle_playing()

        elif cuia == "SELECT":
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

        elif cuia == "BACK_UP":
            try:
                self.get_current_screen().back_up()
            except:
                pass

        elif cuia == "BACK_DOWN":
            try:
                self.get_current_screen().back_down()
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
                self.screens["sketchpad"].song.scenesModel.selectedTrackIndex = max(0, self.screens["sketchpad"].song.scenesModel.selectedTrackIndex - 1)
            except:
                pass

        elif cuia == "SCENE_DOWN":
            try:
                self.screens["sketchpad"].song.scenesModel.selectedTrackIndex = min(self.screens["sketchpad"].song.scenesModel.count - 1, self.screens["sketchpad"].song.scenesModel.selectedTrackIndex + 1)
            except:
                pass

        elif cuia == "SWITCH_LAYER_SHORT":
            self.zynswitch_short(0)

        elif cuia == "SWITCH_LAYER_BOLD":
            self.zynswitch_bold(0)

        elif cuia == "SWITCH_LAYER_LONG":
            self.zynswitch_long(0)

        elif cuia == "SWITCH_BACK_SHORT":
            self.zynswitch_short(1)

        elif cuia == "SWITCH_BACK_BOLD":
            self.zynswitch_bold(1)

        elif cuia == "SWITCH_BACK_LONG":
            self.zynswitch_long(1)

        elif cuia == "SWITCH_SNAPSHOT_SHORT":
            self.zynswitch_short(2)

        elif cuia == "SWITCH_SNAPSHOT_BOLD":
            self.zynswitch_bold(2)

        elif cuia == "SWITCH_SNAPSHOT_LONG":
            self.zynswitch_long(2)

        elif cuia == "SWITCH_SELECT_SHORT":
            self.zynswitch_short(3)

        elif cuia == "SWITCH_SELECT_BOLD":
            self.zynswitch_bold(3)

        elif cuia == "SWITCH_SELECT_LONG":
            self.zynswitch_long(3)

        elif cuia == "SCREEN_MAIN":
            if self.get_current_screen_id() == "main":
                if self.modal_screen_back:
                    self.show_modal(self.modal_screen_back)
                elif self.screen_back:
                    self.show_screen(self.screen_back)
            else:
                self.show_screen("main")

        elif cuia == "SCREEN_EDIT_CONTEXTUAL":
            if self.sketchpad.song is not None:
                channel = self.sketchpad.song.channelsModel.getChannel(self.session_dashboard.selectedChannel)
                if channel.channelAudioType == "synth": # The channel is set to send stuff to the zynthian engines
                    self.show_screen("control")
                    self.forced_screen_back = "sketchpad"
                elif channel.channelAudioType == "external": # The channel is set to spit midi events out through the midi_out port
                    self.show_modal("channel_external_setup")
                    self.forced_screen_back = "sketchpad"
                else: # The rest are different kinds of samples for SamplerSynth playback, so we'll show the wave editor for those
                    self.show_modal("channel_wave_editor")
                    self.forced_screen_back = "sketchpad"

        # elif cuia == "SCREEN_ADMIN":
            # Do not handle 5th under screen button globally.
            # This button has specific behaviour for ZL page. Not sure about other pages
            # self.show_modal("admin")
            # pass

        elif cuia == "SCREEN_LAYER":
            # self.show_screen("layers_for_channel")
            self.show_screen("preset")

        elif cuia == "SCREEN_LAYER_FX":
            self.show_screen("layer_effects")

        elif cuia == "SCREEN_BANK":
            self.show_screen("bank")

        elif cuia == "SCREEN_PRESET":
            self.show_screen("preset")

        elif cuia == "SCREEN_CONTROL":
            self.show_screen("control")

        elif cuia == "SCREEN_SKETCHPAD":
            self.show_screen("sketchpad")

        elif cuia == "SCREEN_ARRANGER":
            self.show_modal("song_arranger")

        elif cuia == "SCREEN_SONG_PLAYER":
            self.show_modal("song_player")

        elif cuia == "SCREEN_SONG_MANAGER":
            self.show_modal("song_manager")

        elif cuia == "SCREEN_PLAYGRID":
            self.show_modal("playgrid")

        elif cuia == "SCREEN_AUDIO_SETTINGS":
            # Toggle global top right popup instead of opening audio settings page
            # self.toggle_modal("audio_settings")
            self.globalPopupOpened = not self.globalPopupOpened

        elif cuia == "MODAL_SNAPSHOT_LOAD":
            self.toggle_modal("snapshot", "LOAD")

        elif cuia == "MODAL_SNAPSHOT_SAVE":
            self.toggle_modal("snapshot", "SAVE")

        elif cuia == "MODAL_AUDIO_RECORDER":
            self.toggle_modal("audio_recorder")

        elif cuia == "MODAL_MIDI_RECORDER":
            self.toggle_modal("midi_recorder")

        elif cuia == "MODAL_ALSA_MIXER":
            self.toggle_modal("alsa_mixer")

        elif (
            cuia == "MODAL_STEPSEQ"
            and "zynseq" in zynthian_gui_config.experimental_features
        ):
            self.toggle_modal("stepseq")

        elif cuia == "CHANNEL_1":
            self.screens["session_dashboard"].selectedChannel = 0 + channelDelta
        elif cuia == "CHANNEL_2":
            self.screens["session_dashboard"].selectedChannel = 1 + channelDelta
        elif cuia == "CHANNEL_3":
            self.screens["session_dashboard"].selectedChannel = 2 + channelDelta
        elif cuia == "CHANNEL_4":
            self.screens["session_dashboard"].selectedChannel = 3 + channelDelta
        elif cuia == "CHANNEL_5":
            self.screens["session_dashboard"].selectedChannel = 4 + channelDelta
        # elif cuia == "CHANNEL_6":
        #     self.screens["session_dashboard"].selectedChannel = 5
        # elif cuia == "CHANNEL_7":
        #     self.screens["session_dashboard"].selectedChannel = 6
        # elif cuia == "CHANNEL_8":
        #     self.screens["session_dashboard"].selectedChannel = 7
        # elif cuia == "CHANNEL_9":
        #     self.screens["session_dashboard"].selectedChannel = 8
        # elif cuia == "CHANNEL_10":
        #     self.screens["session_dashboard"].selectedChannel = 9
        # elif cuia == "CHANNEL_11":
        #     self.screens["session_dashboard"].selectedChannel = 10
        # elif cuia == "CHANNEL_12":
        #     self.screens["session_dashboard"].selectedChannel = 11

        elif cuia == "CHANNEL_PREVIOUS":
            if self.screens["session_dashboard"].selectedChannel > 0:
                self.screens["session_dashboard"].selectedChannel -= 1
        elif cuia == "CHANNEL_NEXT":
            if self.screens["session_dashboard"].selectedChannel < 11:
                self.screens["session_dashboard"].selectedChannel += 1

        elif cuia == "KEYBOARD":
            logging.info("KEYBOARD")
            self.miniPlayGridToggle.emit()

        elif cuia == "ZL_PLAY":
            zl = self.screens["sketchpad"]

            # Toggle play/stop with play CUIA action
            if not zl.isMetronomeRunning:
                self.run_start_metronome_and_playback.emit()
            else:
                self.run_stop_metronome_and_playback.emit()
        elif cuia == "ZL_STOP":
            self.run_stop_metronome_and_playback.emit()

        elif cuia == "START_RECORD":
            if self.recording_popup_active or self.metronomeButtonPressed:
                zl = self.screens["sketchpad"]
                if not zl.isRecording:
                    # No clips are currently being recorded
                    logging.info("CUIA Start Recording")
                    channel = zl.song.channelsModel.getChannel(self.session_dashboard.selectedChannel)
                    clip = channel.getClipToRecord()

                    # If sample[0] is empty, set sample[0] to recorded file along with selectedChannel's clip
                    if channel.samples[channel.selectedSlotRow].path is not None and len(channel.samples[channel.selectedSlotRow].path) > 0:
                        zl.clipsToRecord = [clip]
                    else:
                        zl.clipsToRecord = [clip, channel.samples[channel.selectedSlotRow]]

                    logging.info(f"Recording Clip : {clip}")
                    clip.queueRecording()
                    self.run_start_metronome_and_playback.emit()
                else:
                    # Some Clip is currently being recorded
                    logging.info("Some Clip is currently being recorded. Stopping record")
                    self.run_stop_metronome_and_playback.emit()
            else:
                self.displayRecordingPopup.emit()

        elif cuia == "STOP_RECORD":
            self.run_stop_metronome_and_playback.emit()

        elif cuia == "MODE_SWITCH_SHORT" or cuia == "MODE_SWITCH_BOLD" or cuia == "MODE_SWITCH_LONG":
            if self.leftSidebarActive:
                self.closeLeftSidebar.emit()
            else:
                self.openLeftSidebar.emit()

        elif cuia == "SWITCH_CHANNELS_MOD_SHORT" or cuia == "SWITCH_CHANNELS_MOD_BOLD" or cuia == "SWITCH_CHANNELS_MOD_LONG":
            self.channelsModActive = not self.channelsModActive
            # If * button is pressed, it toggles itself on/off for 5000ms before returning to previous state.
            # Since * button is pressed, start timer
            QMetaObject.invokeMethod(self.channelsModTimer, "start", Qt.QueuedConnection)
            logging.debug(f'self.channelsModActive({self.channelsModActive})')

        # elif cuia == "SWITCH_METRONOME_SHORT" or cuia == "SWITCH_METRONOME_BOLD":
        #     self.screens["sketchpad"].clickChannelEnabled = not self.screens["sketchpad"].clickChannelEnabled

    def custom_switch_ui_action(self, i, t):
        try:
            if t in zynthian_gui_config.custom_switch_ui_actions[i]:
                logging.info("Executing CUIA action: {}".format(zynthian_gui_config.custom_switch_ui_actions[i]))
                self.callable_ui_action(
                    zynthian_gui_config.custom_switch_ui_actions[i][t]
                )
        except Exception as e:
            logging.warning(e)

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
        logging.info("MIDI SWITCHES SETUP...")

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
                    QMetaObject.invokeMethod(self.channelsModTimer, "stop", Qt.QueuedConnection)

                # Handle button press event
                if i == 10:
                    self.switchChannelsButtonPressed = True
                elif i == 17:
                    self.altButtonPressed = True
                elif i == 18:
                    self.startRecordButtonPressed = True
                elif i == 19:
                    self.playButtonPressed = True
                elif i == 20:
                    self.bpmBeforePressingMetronome = self.sketchpad.song.bpm
                    self.volumeBeforePressingMetronome = self.master_alsa_mixer.volume
                    self.delayBeforePressingMetronome = self.global_fx_engines[0][1].value
                    self.reverbBeforePressingMetronome = self.global_fx_engines[1][1].value
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

                if self.fake_key_event_for_zynswitch(i, True):
                    return
            elif dtus > 0:
                # logging.error("key release: {} {}".format(i, dtus))

                # Handle button release event
                if i == 10:
                    self.switchChannelsButtonPressed = False
                elif i == 17:
                    self.altButtonPressed = False
                elif i == 18:
                    self.startRecordButtonPressed = False
                elif i == 19:
                    self.playButtonPressed = False
                elif i == 20:
                    # Toggle metronome only if metronome+BK is not used to change bpm or volume or delay or reverb
                    bpmAfterPressingMetronome = self.sketchpad.song.bpm
                    volumeAfterPressingMetronome = self.master_alsa_mixer.volume
                    delayAfterPressingMetronome = self.global_fx_engines[0][1].value
                    reverbAfterPressingMetronome = self.global_fx_engines[1][1].value
                    if bpmAfterPressingMetronome == self.bpmBeforePressingMetronome and \
                            volumeAfterPressingMetronome == self.volumeBeforePressingMetronome and \
                            delayAfterPressingMetronome == self.delayBeforePressingMetronome and \
                            reverbAfterPressingMetronome == self.reverbBeforePressingMetronome:
                        # BPM/Volume/Delay/Reverb did not change. Toggle metronome state
                        self.screens["sketchpad"].clickChannelEnabled = not self.screens["sketchpad"].clickChannelEnabled
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

                if self.fake_key_event_for_zynswitch(i, False):
                    return

            if not self.is_external_app_active():
                if dtus < 0:
                    pass
                elif dtus>zynthian_gui_config.zynswitch_long_us:
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
                # Do not emulate Ctrl key with channelsModActive
                # if self.channelsModActive:
                #     self.fakeKeyboard.press(Key.ctrl)

                self.__fake_keys_pressed.add(fake_key)
                self.fakeKeyboard.press(fake_key)
        else:
            if fake_key in self.__fake_keys_pressed:
                # Do not emulate Ctrl key with channelsModActive
                # if self.channelsModActive:
                #     self.fakeKeyboard.release(Key.ctrl)

                self.__fake_keys_pressed.discard(fake_key)
                self.fakeKeyboard.release(fake_key)

        return True


    def zynswitch_long(self, i):
        logging.info("Looooooooong Switch " + str(i))
        # Disabling ald loong presses for the moment
        return
        #self.start_loading()

        # Standard 4 ZynSwitches
        if i == 0 and "zynseq" in zynthian_gui_config.experimental_features:
            self.toggle_modal("stepseq")

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
        logging.info("Bold Switch " + str(i))
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
        logging.info("Short Switch " + str(i))
        print("Short Switch Triggered" + str(i))
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

            elif self.active_screen != "session_dashboard": # Session dashboard is always at the end of the back chain
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

            elif self.modal_screen == "audio_recorder":
                self.show_modal("midi_recorder")

            elif self.modal_screen == "midi_recorder":
                self.show_modal("audio_recorder")

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
        if self.knobTouchUpdateInProgress:
            return

        if not self.loading:  # TODO Es necesario???
            try:
                # TODO: figure out the multithreading error

                # Read Zyncoders
                self.lock.acquire()

                if self.is_global_set_selector_running:
                    # If Global set_selector is in progress, do not call zyncoder_read methods
                    # This will make sure none of the gui updates while set_selector is in progress
                    logging.debug(f"Set selector in progress. Not setting value with encoder")
                else:
                    if self.globalPopupOpened or self.metronomeButtonPressed or self.altButtonPressed:
                        # When global popup is open, set song bpm with big knob
                        if self.__zselector[0] and self.sketchpad.song is not None:
                            self.__zselector[0].read_zyncoder()
                            if self.altButtonPressed:
                                pass
                            else:
                                QMetaObject.invokeMethod(self, "zyncoder_set_bpm", Qt.QueuedConnection)

                        # When global popup is open, set volume with small knob 1
                        if self.__zselector[1] and self.master_alsa_mixer is not None:
                            self.__zselector[1].read_zyncoder()
                            if self.altButtonPressed:
                                QMetaObject.invokeMethod(self, "zyncoder_set_channel_volume", Qt.QueuedConnection)
                            else:
                                QMetaObject.invokeMethod(self, "zyncoder_set_volume", Qt.QueuedConnection)

                        # When global popup is open, set delay with small knob 2
                        if self.__zselector[2] and self.global_fx_engines[0] is not None:
                            self.__zselector[2].read_zyncoder()
                            if self.altButtonPressed:
                                QMetaObject.invokeMethod(self, "zyncoder_set_channel_delay_send_amount", Qt.QueuedConnection)
                            else:
                                QMetaObject.invokeMethod(self, "zyncoder_set_delay", Qt.QueuedConnection)

                        # When global popup is open, set reverb with small knob 3
                        if self.__zselector[3] and self.global_fx_engines[1] is not None:
                            self.__zselector[3].read_zyncoder()
                            if self.altButtonPressed:
                                QMetaObject.invokeMethod(self, "zyncoder_set_channel_reverb_send_amount", Qt.QueuedConnection)
                            else:
                                QMetaObject.invokeMethod(self, "zyncoder_set_reverb", Qt.QueuedConnection)
                    else:
                        if self.openedDialog is not None and self.openedDialog.property("listCurrentIndex") is not None:
                            # If openedDialog has listCurrentIndex and listCount property control currentIndex of that dialog with BK.
                            if self.__zselector[0]:
                                self.__zselector[0].read_zyncoder()
                                QMetaObject.invokeMethod(self, "zyncoder_set_current_index", Qt.QueuedConnection)
                        else:
                            # When global popop is not open, call zyncoder_read of active screen/modal
                            if self.modal_screen:
                                free_zyncoders = self.screens[
                                    self.modal_screen
                                ].zyncoder_read()
                            else:
                                free_zyncoders = self.screens[
                                    self.active_screen
                                ].zyncoder_read()

                            if free_zyncoders:
                                self.screens["control"].zyncoder_read(free_zyncoders)

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

    def start_loading_thread(self):
        self.loading_thread = Thread(target=self.loading_refresh, args=())
        self.loading_thread.daemon = True  # thread dies with the program
        self.loading_thread.start()

    @Slot(None)
    def start_loading(self):
        self.loading = self.loading + 1
        if self.loading < 1:
            self.loading = 1
        self.is_loading_changed.emit()
        # FIXME Apparently needs bot hthe timer *and* processEvents for qml to actually receive the signal before the sync loading is done
        self.deferred_loading_timer_start.emit()
        QGuiApplication.instance().processEvents(QEventLoop.AllEvents, 1000)
        self.is_loading_changed.emit()
        # logging.debug("START LOADING %d" % self.loading)

    @Slot(None)
    def stop_loading(self):
        self.loading = self.loading - 1
        if self.loading < 0:
            self.loading = 0

        if self.loading == 0:
            self.deferred_loading_timer_stop.emit()
            self.is_loading_changed.emit()
        # logging.debug("STOP LOADING %d" % self.loading)

    def reset_loading(self):
        self.is_loading_changed.emit()
        self.deferred_loading_timer_stop.emit()
        self.loading = 0

    def get_is_loading(self):
        return self.loading > 0

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
                    self.show_screen("session_dashboard")
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
                self.stop()
                self.wait_threads_end()
                logging.info("EXITING ZYNTHIAN-UI ...")

                if self.exit_code == 100:
                    Popen(("systemctl", "poweroff"))
                elif self.exit_code == 101:
                    Popen(("reboot"))
                elif self.exit_code == 102:
                    Popen(("systemctl", "restart", "jack2", "zynthian", "mod-ttymidi"))
                else:
                    Popen(("systemctl", "restart", "jack2", "zynthian", "mod-ttymidi"))
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
            #else:
                ## Get audio peak level
                #self.status_info["peakA"] = lib_jackpeak.getPeak(0)
                #self.status_info["peakB"] = lib_jackpeak.getPeak(1)
                #self.status_info["holdA"] = lib_jackpeak.getHold(0)
                #self.status_info["holdB"] = lib_jackpeak.getHold(1)

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
                    self.status_info["midi_recorder"] = self.screens[
                        "midi_recorder"
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
        for chan in range(16):
            lib_zyncoder.ui_send_ccontrol_change(chan, 120, 0)

    def all_notes_off(self):
        logging.info("All Notes Off!")
        for chan in range(16):
            lib_zyncoder.ui_send_ccontrol_change(chan, 123, 0)

    def raw_all_notes_off(self):
        logging.info("Raw All Notes Off!")
        lib_zyncoder.ui_send_all_notes_off()

    def all_sounds_off_chan(self, chan):
        logging.info("All Sounds Off for channel {}!".format(chan))
        lib_zyncoder.ui_send_ccontrol_change(chan, 120, 0)

    def all_notes_off_chan(self, chan):
        logging.info("All Notes Off for channel {}!".format(chan))
        lib_zyncoder.ui_send_ccontrol_change(chan, 123, 0)

    def raw_all_notes_off_chan(self, chan):
        logging.info("Raw All Notes Off for channel {}!".format(chan))
        lib_zyncoder.ui_send_all_notes_off_chan(chan)

    # ------------------------------------------------------------------
    # MPE initialization
    # ------------------------------------------------------------------

    def init_mpe_zones(self, lower_n_chans, upper_n_chans):
        # Configure Lower Zone
        if (
            not isinstance(lower_n_chans, int)
            or lower_n_chans < 0
            or lower_n_chans > 0xF
        ):
            logging.error(
                "Can't initialize MPE Lower Zone. Incorrect num of channels ({})".format(
                    lower_n_chans
                )
            )
        else:
            lib_zyncoder.ctrlfb_send_ccontrol_change(0x0, 0x79, 0x0)
            lib_zyncoder.ctrlfb_send_ccontrol_change(0x0, 0x64, 0x6)
            lib_zyncoder.ctrlfb_send_ccontrol_change(0x0, 0x65, 0x0)
            lib_zyncoder.ctrlfb_send_ccontrol_change(0x0, 0x06, lower_n_chans)

        # Configure Upper Zone
        if (
            not isinstance(upper_n_chans, int)
            or upper_n_chans < 0
            or upper_n_chans > 0xF
        ):
            logging.error(
                "Can't initialize MPE Upper Zone. Incorrect num of channels ({})".format(
                    upper_n_chans
                )
            )
        else:
            lib_zyncoder.ctrlfb_send_ccontrol_change(0xF, 0x79, 0x0)
            lib_zyncoder.ctrlfb_send_ccontrol_change(0xF, 0x64, 0x6)
            lib_zyncoder.ctrlfb_send_ccontrol_change(0xF, 0x65, 0x0)
            lib_zyncoder.ctrlfb_send_ccontrol_change(0xF, 0x06, upper_n_chans)

    # ------------------------------------------------------------------
    # MIDI learning
    # ------------------------------------------------------------------

    def init_midi_learn(self, zctrl):
        self.midi_learn_zctrl = zctrl
        lib_zyncoder.set_midi_learning_mode(1)
        self.screens["control"].refresh_midi_bind()
        self.screens["control"].set_select_path()

    def end_midi_learn(self):
        self.midi_learn_zctrl = None
        lib_zyncoder.set_midi_learning_mode(0)
        self.screens["control"].refresh_midi_bind()
        self.screens["control"].set_select_path()

    def refresh_midi_learn(self):
        self.screens["control"].refresh_midi_bind()
        self.screens["control"].set_select_path()

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
        # Display main window as soon as possible so it doesn't take time to load after splash stops
        self.displayMainWindow.emit()
        self.isBootingComplete = True

        

        # Display sketchpad page and run set_selector at last before hiding splash
        # to ensure knobs work fine
        self.show_modal("sketchpad")
        self.sketchpad.set_selector()

        # Explicitly run update_jack_port after booting is complete
        # as any requests made while booting is ignored
        # zynqtgui.zynautoconnect will run after channel ports are updated
        for i in range(0, self.sketchpad.song.channelsModel.count):
            channel = self.sketchpad.song.channelsModel.getChannel(i)
            # Allow jack ports connection to complete before showing UI
            # so do not update jack ports in a thread
            channel.update_jack_port(run_in_thread=False)

        extro_path = Path('/usr/share/zynthbox-bootsplash/zynthbox-bootsplash-extro.mp4')

        process = Popen(("mplayer", '-noborder', '-ontop', '-geometry', '50%:50%', str(extro_path)))

        with open("/tmp/mplayer-splash-control", "w") as f:
            f.write("quit\n")
            f.close()

        if process is not None:
            process.wait()

        # Setting splashStopped to True will remove the overlay over main wwindow so nothing is displayed below splash until splash process exits
        self.splashStopped = True

        # Stop rainbow and initialize LED config and connect to required signals
        # to be able to update LEDs on value change instead
        rainbow_led_process.terminate()
        self.led_config.init()

        boot_end = timer()

        logging.info(f"### BOOTUP TIME : {timedelta(seconds=boot_end - boot_start)}")

    def get_encoder_list_speed_multiplier(self):
        return self.__encoder_list_speed_multiplier

    def set_encoder_list_speed_multiplier(self, val):
        if self.__encoder_list_speed_multiplier == val:
            return
        self.__encoder_list_speed_multiplier = val
        speed_settings = QSettings("/home/pi/config/gui_optionsrc", QSettings.IniFormat)
        speed_settings.beginGroup("Encoder0")
        speed_settings.setValue("speed", self.__encoder_list_speed_multiplier);
        speed_settings.endGroup()

        self.encoder_list_speed_multiplier_changed.emit()

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

    def get_midi_recorder(self):
        return self.screens["midi_recorder"]

    def get_play_grid(self):
        return self.screens["play_grid"]

    def get_playgrid_downloader(self):
        return self.screens["playgrid_downloader"]

    def get_theme_chooser(self):
        return self.screens["theme_chooser"]

    def get_theme_downloader(self):
        return self.screens["theme_downloader"]

    def get_sample_downloader(self):
        return self.screens["sample_downloader"]

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

    def get_guioptions(self):
        return self.screens["guioptions"]

    def test_touchpoints(self):
        return self.screens["test_touchpoints"]

    def playgrid(self):
        return self.screens["playgrid"]

    def miniplaygrid(self):
        return self.screens["miniplaygrid"]

    def sketchpad(self):
        return self.screens["sketchpad"]

    def audio_settings(self):
        return self.screens["audio_settings"]

    def wifi_settings(self):
        return self.screens["wifi_settings"]

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

    def master_alsa_mixer(self):
        return self.screens["master_alsa_mixer"]

    def session_dashboard(self):
        return self.screens["session_dashboard"]

    def song_arranger(self):
        return self.screens["song_arranger"]

    def song_player(self):
        return self.screens["song_player"]

    def song_manager(self):
        return self.screens["song_manager"]

    def sketchpad_copier(self):
        return self.screens["sketchpad_copier"]

    def sound_categories(self):
        return self.screens["sound_categories"]

    def led_config(self):
        return self.screens["led_config"]

    def bluetooth_config(self):
        return self.screens["bluetooth_config"]

    def osd(self):
        return self.__osd
    
    ### Alternative long task handling than show_loading
    def do_long_task(self, cb):
        logging.debug("### Start long task")

        # Emit long task started if no other long task is already running
        if self.__long_task_count__ == 0:
            self.longTaskStarted.emit()

        self.__long_task_count__ += 1

        QTimer.singleShot(2000, cb)

    def end_long_task(self):
        logging.debug("### End long task")
        self.__long_task_count__ -= 1

        # Emit long task ended only if all task has ended
        if self.__long_task_count__ == 0:
            self.showCurrentTaskMessage = True
            self.currentTaskMessage = ""
            self.longTaskEnded.emit()
            self.run_set_selectors()

    longTaskStarted = Signal()
    longTaskEnded = Signal()
    ### END Alternative long task handling

    ### Property switchChannelsButtonPressed
    def get_switch_channels_button_pressed(self):
        return self.__switch_channels_button_pressed__

    def set_switch_channels_button_pressed(self, pressed):
        if self.__switch_channels_button_pressed__ != pressed:
            logging.debug(f"Switch Channels Button pressed : {pressed}")
            self.__switch_channels_button_pressed__ = pressed
            self.switch_channels_button_pressed_changed.emit()

    switch_channels_button_pressed_changed = Signal()

    switchChannelsButtonPressed = Property(bool, get_switch_channels_button_pressed, set_switch_channels_button_pressed, notify=switch_channels_button_pressed_changed)
    ### END Property switchChannelsButtonPressed

    ### Property altButtonPressed
    def get_alt_button_pressed(self):
        return self.__alt_button_pressed__

    def set_alt_button_pressed(self, pressed):
        if self.__alt_button_pressed__ != pressed:
            logging.debug(f"alt Button pressed : {pressed}")
            self.__alt_button_pressed__ = pressed
            self.alt_button_pressed_changed.emit()
            self.run_set_selectors()

    alt_button_pressed_changed = Signal()

    altButtonPressed = Property(bool, get_alt_button_pressed, set_alt_button_pressed, notify=alt_button_pressed_changed)
    ### END Property altButtonPressed

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

    ### Property metronomeButtonPressed
    def get_metronome_button_pressed(self):
        return self.__metronome_button_pressed__

    def set_metronome_button_pressed(self, pressed):
        if self.__metronome_button_pressed__ != pressed:
            logging.debug(f"metronome Button pressed : {pressed}")
            self.__metronome_button_pressed__ = pressed
            self.metronome_button_pressed_changed.emit()
            self.run_set_selectors()

    metronome_button_pressed_changed = Signal()

    metronomeButtonPressed = Property(bool, get_metronome_button_pressed, set_metronome_button_pressed, notify=metronome_button_pressed_changed)
    ### END Property metronomeButtonPressed

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

    ### Property openedDialog
    def get_openedDialog(self):
        return self.opened_dialog

    def set_openedDialog(self, dialog):
        if dialog != self.opened_dialog:
            logging.debug(f"Setting opened dialog : {dialog}")

            try:
                self.opened_dialog.disconnect(self)
            except: pass

            self.opened_dialog = dialog
            self.openedDialogChanged.emit()

            try:
                dialog.connect(dialog, SIGNAL("listCountChanged()"), self.set_selector, Qt.DirectConnection)
                dialog.connect(dialog, SIGNAL("listCurrentIndexChanged()"), self.set_selector, Qt.DirectConnection)
            except: pass

            self.set_selector()

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
                logging.warning("The dialog we just tried to pop from the list is not at the top of the stack. We still removed it, but there is likely something wrong if this happens.")
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
        global bootlog_fifo

        if self.__booting_complete__ != value:
            self.__booting_complete__ = value
            self.isBootingCompleteChanged.emit()

            if self.__booting_complete__:
                if bootlog_fifo is not None:
                    os.write(bootlog_fifo, f"exit\n".encode())
                    os.close(bootlog_fifo)
                    bootlog_fifo = None

                    Path("/tmp/bootlog.fifo").unlink()

                self.currentTaskMessage = ""

    isBootingCompleteChanged = Signal()

    isBootingComplete = Property(bool, get_isBootingComplete, set_isBootingComplete, notify=isBootingCompleteChanged)
    ### END Property isBootingComplete

    ### Property globalPopupOpened
    def get_globalPopupOpened(self):
        return self.__global_popup_opened__

    def set_globalPopupOpened(self, opened):
        if self.__global_popup_opened__ != opened:
            self.__global_popup_opened__ = opened

            # Set is_global_set_selector_running to True, which will disable any gui updates with knobs
            # while set_selector is in progress
            self.is_global_set_selector_running = True

            # Queue call to running set_selector of all pages to make sure opening global popus is fast
            QMetaObject.invokeMethod(self, "run_set_selectors", Qt.QueuedConnection)

            # Emit globalPopupOpenedChanged immediately and not wait for set_selector calls to complete
            # to make sure global popup is opened instantly
            self.globalPopupOpenedChanged.emit()

    @Slot(None)
    def run_set_selectors(self):
        """
        Run set_selector for all pages when global popop opens/closes
        """

        if self.isBootingComplete:
            self.set_selector()

            # Since set_selector of a page is called when show() method is called so run set selector of current page
            # along with global set_selector to update knob settings as it is already being shown
            if hasattr(self.get_current_screen(), "set_selector"):
                self.get_current_screen().set_selector()

            self.is_global_set_selector_running = False

    globalPopupOpenedChanged = Signal()

    globalPopupOpened = Property(bool, get_globalPopupOpened, set_globalPopupOpened, notify=globalPopupOpenedChanged)
    ### END Property globalPopupOpened

    ### Property delayKnobValue
    def get_delayKnobValue(self):
        controller = self.global_fx_engines[0][1]
        if controller is not None:
            return np.interp(controller.value, [controller.value_min, controller.value_max], [0, 100])
        else:
            return 0

    def set_delayKnobValue(self, percentage):
        controller = self.global_fx_engines[0][1]
        if controller is not None:
            value = np.interp(percentage, [0, 100], [controller.value_min, controller.value_max])
            self.global_fx_engines[0][1].set_value(value, True)
            self.run_set_selectors()

    delayKnobValueChanged = Signal()

    delayKnobValue = Property(int, get_delayKnobValue, set_delayKnobValue, notify=delayKnobValueChanged)
    ### END Property delayKnobValue

    ### Property reverbKnobValue
    def get_reverbKnobValue(self):
        controller = self.global_fx_engines[1][1]
        if controller is not None:
            return np.interp(controller.value, [controller.value_min, controller.value_max], [0, 100])
        else:
            return 0

    def set_reverbKnobValue(self, percentage):
        controller = self.global_fx_engines[1][1]
        if controller is not None:
            value = np.interp(percentage, [0, 100], [controller.value_min, controller.value_max])
            self.global_fx_engines[1][1].set_value(value, True)
            self.run_set_selectors()

    reverbKnobValueChanged = Signal()

    reverbKnobValue = Property(int, get_reverbKnobValue, set_reverbKnobValue, notify=reverbKnobValueChanged)
    ### END Property reverbKnobValue

    ### Property currentTaskMessage
    def get_currentTaskMessage(self):
        return self.__current_task_message

    def set_currentTaskMessage(self, value):
        if value != self.__current_task_message and self.showCurrentTaskMessage:
            self.__current_task_message = value
            self.__recent_task_messages.put(value)
            self.currentTaskMessageChanged.emit()
            QGuiApplication.instance().processEvents()

    currentTaskMessageChanged = Signal()

    currentTaskMessage = Property(str, get_currentTaskMessage, set_currentTaskMessage, notify=currentTaskMessageChanged)
    ### END Property currentTaskMessage

    ### Property showCurrentTaskMessage
    def get_showCurrentTaskMessage(self):
        return self.__show_current_task_message

    def set_showCurrentTaskMessage(self, value):
        if value != self.__show_current_task_message:
            self.__show_current_task_message = value
            self.showCurrentTaskMessageChanged.emit()

    showCurrentTaskMessageChanged = Signal()

    showCurrentTaskMessage = Property(bool, get_showCurrentTaskMessage, set_showCurrentTaskMessage, notify=showCurrentTaskMessageChanged)
    ### END Property showCurrentTaskMessage

    ### Property knobTouchUpdateInProgress
    def get_knob_touch_update_in_progress(self):
        return self.__knob_touch_update_in_progress__

    def set_knob_touch_update_in_progress(self, value):
        if self.__knob_touch_update_in_progress__ != value:
            self.set_selector()
            self.__knob_touch_update_in_progress__ = value
            self.knob_touch_update_in_progress_changed.emit()

    knob_touch_update_in_progress_changed = Signal()

    knobTouchUpdateInProgress = Property(bool, get_knob_touch_update_in_progress, set_knob_touch_update_in_progress,
                                         notify=knob_touch_update_in_progress_changed)
    ### END Property knobTouchUpdateInProgress

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
    
    ### Property splashStopped
    # This property will make sure to display an overlay over the main window until splash is stopped
    def get_splashStopped(self):
        return self.__splash_stopped
            
    def set_splashStopped(self, val):
        self.__splash_stopped = val
        self.splashStoppedChanged.emit()
    
    splashStoppedChanged = Signal()
        
    splashStopped = Property(bool, get_splashStopped, set_splashStopped, notify=splashStoppedChanged)
    ### END Property splashStopped

    ### Property channelsModActive
    def get_channelsModActive(self):
        return self.channels_mod_active

    def set_channelsModActive(self, val):
        if self.channels_mod_active != val:
            self.channels_mod_active = val
            self.channelsModActiveChanged.emit()

    channelsModActiveChanged = Signal()

    channelsModActive = Property(bool, get_channelsModActive, set_channelsModActive, notify=channelsModActiveChanged)
    ### END Property channelsModActive

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
    ### Allowed values : "bottombar-controltype-song", "bottombar-controltype-clip", "bottombar-controltype-channel", "bottombar-controltype-part", "bottombar-controltype-pattern", "bottombar-controltype-none"
    def get_bottomBarControlType(self):
        return self.__bottombar_control_type

    def set_bottomBarControlType(self, val):
        if self.__bottombar_control_type != val:
            self.__bottombar_control_type = val
            self.bottomBarControlTypeChanged.emit()

    bottomBarControlTypeChanged = Signal()

    bottomBarControlType = Property(str, get_bottomBarControlType, set_bottomBarControlType, notify=bottomBarControlTypeChanged)
    ### END Property bottomBarControlType

    ### Property isExternalAppActive
    def get_isExternalAppActive(self):
        return hasattr(zynthian_gui_config, 'top') and zynthian_gui_config.top.isActive() == False

    isExternalAppActiveChanged = Signal()

    isExternalAppActive = Property(bool, get_isExternalAppActive, notify=isExternalAppActiveChanged)
    ### END Property isExternalAppActive

    current_screen_id_changed = Signal()
    current_modal_screen_id_changed = Signal()
    deferred_loading_timer_start = Signal()
    deferred_loading_timer_stop = Signal()
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
    encoder_list_speed_multiplier_changed = Signal()
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
    test_knobs = Property(QObject, test_knobs, constant=True)
    synth_behaviour = Property(QObject, synth_behaviour, constant=True)
    snapshots_menu = Property(QObject, snapshots_menu, constant=True)
    network = Property(QObject, network, constant=True)
    hardware = Property(QObject, hardware, constant=True)
    master_alsa_mixer = Property(QObject, master_alsa_mixer, constant=True)
    session_dashboard = Property(QObject, session_dashboard, constant=True)
    song_arranger = Property(QObject, song_arranger, constant=True)
    song_player = Property(QObject, song_player, constant=True)
    song_manager = Property(QObject, song_manager, constant=True)
    sketchpad_copier = Property(QObject, sketchpad_copier, constant=True)
    sound_categories = Property(QObject, sound_categories, constant=True)
    led_config = Property(QObject, led_config, constant=True)
    bluetooth_config = Property(QObject, bluetooth_config, constant=True)
    osd = Property(QObject, osd, constant=True)

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

    is_loading = Property(bool, get_is_loading, notify=is_loading_changed)

    home_screen = Property(str, get_home_screen, set_home_screen, notify=home_screen_changed)

    active_midi_channel = Property(int, get_active_midi_channel, notify = active_midi_channel_changed)

    encoder_list_speed_multiplier = Property(int, get_encoder_list_speed_multiplier, set_encoder_list_speed_multiplier, notify = encoder_list_speed_multiplier_changed)

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
    control = Property(QObject, get_control, constant=True)
    channel = Property(QObject, get_channel, constant=True)
    channel_external_setup = Property(QObject, get_channel_external_setup, constant=True)
    channel_wave_editor = Property(QObject, get_channel_wave_editor, constant=True)
    audio_recorder = Property(QObject, get_audio_recorder, constant=True)
    midi_recorder = Property(QObject, get_midi_recorder, constant=True)
    playgrid_downloader = Property(QObject, get_playgrid_downloader, constant=True)
    theme_chooser = Property(QObject, get_theme_chooser, constant=True)
    theme_downloader = Property(QObject, get_theme_downloader, constant=True)
    sample_downloader = Property(QObject, get_sample_downloader, constant=True)
    sound_downloader = Property(QObject, get_sound_downloader, constant=True)
    soundfont_downloader = Property(QObject, get_soundfont_downloader, constant=True)
    soundset_downloader = Property(QObject, get_soundset_downloader, constant=True)
    sequence_downloader = Property(QObject, get_sequence_downloader, constant=True)
    sketchpad_downloader = Property(QObject, get_sketchpad_downloader, constant=True)
    guioptions = Property(QObject, get_guioptions, constant=True)

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

def open_bootlog_fifo():
    global bootlog_fifo

    bootlog_fifo = os.open("/tmp/bootlog.fifo", os.O_WRONLY)

if __name__ == "__main__":
    boot_start = timer()
    bootlog_fifo = None

    if not Path("/tmp/bootlog.fifo").exists():
        os.mkfifo("/tmp/bootlog.fifo")

    threading.Thread(target=open_bootlog_fifo).start()

    # Start rainbow led process
    rainbow_led_process = Popen(("python3", "zynqtgui/zynthian_gui_led_config.py", "rainbow"))

    # Enable qml debugger if ZYNTHBOX_DEBUG env variable is set
    if os.environ.get("ZYNTHBOX_DEBUG"):
        debug = QQmlDebuggingEnabler()

    ### Tracktion config file `/root/.config/libzl/Settings.xml` sometimes reconfigures and sets
    ### the value <VALUE name="audiosettings_JACK"><AUDIODEVICE outEnabled="0" inEnabled="0" monoChansOut="0" stereoChansIn="0"/></VALUE>
    ### which causes no audio output from libzl. To circumvent this isssue, always remove the following
    ### three tags from the xml : <VALUE name="audiosettings_JACK">, <VALUE name="defaultWaveDevice_JACK">
    ### and <VALUE name="defaultWaveInDevice_JACK"
    ### Remove these above 3 tags from xml before initializing libzl
    ### FIXME : Find the root cause of the issue instead of this workaround
    try:
        if Path("/root/.config/libzl/Settings.xml").exists():
            logging.debug(f"libzl settings file found. Removing elements")
            tree = ET.parse('/root/.config/libzl/Settings.xml')
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

            tree.write("/root/.config/libzl/Settings.xml")
    except Exception as e:
        logging.error(f"Error updating libzl Settings.xml : {str(e)}")

    ###

    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()

    if zynthian_gui_config.force_enable_cursor == False:
        nullCursor = QPixmap(16, 16);
        nullCursor.fill(Qt.transparent);
        app.setOverrideCursor(QCursor(nullCursor));

    logging.info("REGISTERING QML TYPES")
    qmlRegisterType(file_properties_helper, "Helpers", 1, 0, "FilePropertiesHelper")

    logging.info("STARTING ZYNTHIAN-UI ...")
    zynthian_gui_config.zynqtgui = zynqtgui = zynthian_gui()
    zynqtgui.start()

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
    # font = app.font()
    # font.setPointSize(12)
    # font.setFamily("Roboto")
    # app.setFont(font)

    zynqtgui.show_screen(zynqtgui.home_screen)
    zynqtgui.screens["preset"].disable_show_fav_presets()

    engine.addImportPath(os.fspath(Path(__file__).resolve().parent / "qml-ui"))
    engine.rootContext().setContextProperty("zynqtgui", zynqtgui)

    def load_qml():
        zynqtgui.currentTaskMessage = f"Loading pages"
        engine.load(os.fspath(Path(__file__).resolve().parent / "qml-ui/main.qml"))

        if not engine.rootObjects() or not app.topLevelWindows():
            sys.exit(-1)

        # assuming there is one and only one window for now
        zynthian_gui_config.top = app.topLevelWindows()[0]
        zynthian_gui_config.app = app

        # Norify isExternalActive changed when top window active value changes
        zynthian_gui_config.top.activeChanged.connect(lambda: zynqtgui.isExternalAppActiveChanged.emit())

    # Delay loading qml to let zynqtgui complete it's init sequence
    # Without the delay, UI sometimes doest start when `systemctl restart zynthian` is ran
    QTimer.singleShot(1000, load_qml)

    sys.exit(app.exec_())

# ------------------------------------------------------------------------------
