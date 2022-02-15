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
import signal
import math

# import psutil
# import alsaseq
import logging
import threading
import rpi_ws281x
import time
from datetime import datetime
from threading import Thread, Lock
from subprocess import check_output
from ctypes import c_float, c_double, CDLL

# Qt modules
from PySide2.QtCore import (
    Qt,
    QObject,
    QMetaObject,
    Slot,
    Signal,
    Property,
    QTimer,
    QEventLoop,
)
from PySide2.QtGui import QGuiApplication, QPalette, QColor, QIcon, QWindow, QCursor, QPixmap

# from PySide2.QtWidgets import QApplication
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType
from soundfile import SoundFile

from pynput.keyboard import Key, Controller

from zynqtgui.sketch_copier import zynthian_gui_sketch_copier
from zynqtgui.song_arranger import zynthian_gui_song_arranger
from zynqtgui.utils import file_properties_helper
from zynqtgui.zynthian_gui_audio_settings import zynthian_gui_audio_settings
from zynqtgui.zynthiloops.libzl import libzl

sys.path.insert(1, "/zynthian/zynthian-ui/")
sys.path.insert(1, "./zynqtgui")

# Zynthian specific modules
import zynconf
import zynautoconnect
from zynlibs.jackpeak import lib_jackpeak_init
from zyncoder import *
from zyncoder.zyncoder import lib_zyncoder_init
from zyngine import zynthian_zcmidi
from zyngine import zynthian_midi_filter

# from zyngine import zynthian_engine_transport
from zynqtgui import zynthian_gui_config
from zynqtgui.zynthian_gui_selector import zynthian_gui_selector
from zynqtgui.zynthian_gui_info import zynthian_gui_info
from zynqtgui.zynthian_gui_about import zynthian_gui_about
from zynqtgui.zynthian_gui_option import zynthian_gui_option
from zynqtgui.zynthian_gui_admin import zynthian_gui_admin
from zynqtgui.zynthian_gui_snapshot import zynthian_gui_snapshot
from zynqtgui.zynthian_gui_layer import zynthian_gui_layer
from zynqtgui.zynthian_gui_fixed_layers import zynthian_gui_fixed_layers
from zynqtgui.zynthian_gui_layers_for_track import zynthian_gui_layers_for_track
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
from zynqtgui.zynthian_gui_track import zynthian_gui_track

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
from zynqtgui.zynthiloops.zynthian_gui_zynthiloops import (
    zynthian_gui_zynthiloops,
)

# if "autoeq" in zynthian_gui_config.experimental_features:
# from zynqtgui.zynthian_gui_autoeq import zynthian_gui_autoeq
# if "zynseq" in zynthian_gui_config.experimental_features:
# from zynqtgui.zynthian_gui_stepsequencer import zynthian_gui_stepsequencer
# from zynqtgui.zynthian_gui_touchscreen_calibration import zynthian_gui_touchscreen_calibration

# from zynqtgui.zynthian_gui_control_osc_browser import zynthian_gui_osc_browser

from zynqtgui.zynthian_gui_theme_chooser import zynthian_gui_theme_chooser
from zynqtgui.zynthian_gui_newstuff import zynthian_gui_newstuff

from zynqtgui.zynthian_gui_synth_behaviour import zynthian_gui_synth_behaviour
from zynqtgui.zynthian_gui_snapshots_menu import zynthian_gui_snapshots_menu
from zynqtgui.zynthian_gui_network import zynthian_gui_network
from zynqtgui.zynthian_gui_hardware import zynthian_gui_hardware

from zynqtgui.session_dashboard.zynthian_gui_session_dashboard import zynthian_gui_session_dashboard
from zynqtgui.zynthian_gui_master_alsa_mixer import zynthian_gui_master_alsa_mixer

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
        self.status_info["holdA"] = 0
        self.status_info["holdB"] = 0
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
        self.status_info = status
        self.status_changed.emit()

    def get_cpu_load(self):
        return self.status_info["cpu_load"]

    def get_peakA(self):
        return self.status_info["peakA"]

    def get_peakB(self):
        return self.status_info["peakB"]

    def get_holdA(self):
        return self.status_info["holdA"]

    def get_holdB(self):
        return self.status_info["holdB"]

    def get_xrun(self):
        return self.status_info["xrun"]

    def get_undervoltage(self):
        if "undervoltage" in self.status_info:
            return self.status_info["undervoltage"]
        else:
            return False

    def get_overtemp(self):
        if "overtemp" in self.status_info:
            return self.status_info["overtemp"]
        else:
            return False

    def get_audio_recorder(self):
        if "audio_recorder" in self.status_info:
            return self.status_info["audio_recorder"]
        else:
            return None

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
    holdA = Property(float, get_holdA, notify=status_changed)
    holdB = Property(float, get_holdB, notify=status_changed)
    xrun = Property(bool, get_xrun, notify=status_changed)
    undervoltage = Property(bool, get_undervoltage, notify=status_changed)
    overtemp = Property(bool, get_overtemp, notify=status_changed)
    audio_recorder = Property(str, get_audio_recorder, notify=status_changed)
    midi_recorder = Property(str, get_midi_recorder, notify=status_changed)

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
        "zynthiloops",
        "layers_for_track",
        "bank",
        "preset",
        "control",
        "layer_effects",
        "layer_midi_effects",
    )
    non_modal_screens = (
        #"session_dashboard",  #FIXME or main? make this more configurable?
        "zynthiloops",
        "main",
        "layer",
        "fixed_layers",
        "layers_for_track",
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
        self.zynmidi = None
        self.screens = {}
        self.__home_screen = "zynthiloops" #TODO: make this configurable, put same in static screens_sequence
        self.active_screen = None
        self.modal_screen = None
        self.modal_screen_back = None
        self.screen_back = None
        self.__forced_screen_back = None

        # This makes zynswitch_short execute in the main thread, zynswitch_short_triggered will be emitted from a different thread
        self.zynswitch_short_triggered.connect(self.zynswitch_short, Qt.QueuedConnection)
        self.zynswitch_long_triggered.connect(self.zynswitch_long, Qt.QueuedConnection)
        self.zynswitch_bold_triggered.connect(self.zynswitch_bold, Qt.QueuedConnection)
        self.fakeKeyboard = Controller()

        self.modal_timer = QTimer(self)
        self.modal_timer.setInterval(3000)
        self.modal_timer.setSingleShot(False)
        self.modal_timer.timeout.connect(self.close_modal)

        self.init_wsleds()

        self.info_timer = QTimer(self)
        self.info_timer.setInterval(3000)
        self.info_timer.setSingleShot(False)
        self.info_timer.timeout.connect(self.hide_info)
        # HACK: in order to start the timer from the proper thread
        self.current_modal_screen_id_changed.connect(self.info_timer.start)
        self.current_qml_page_prop = None

        #FIXME HACK: this spams is_loading_changed on the proper thread until the ui gets it, can it be done properly?
        self.deferred_loading_timer = QTimer(self)
        self.deferred_loading_timer.setInterval(0)
        self.deferred_loading_timer.setSingleShot(False)
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

        self.midi_filter_script = None
        self.midi_learn_mode = False
        self.midi_learn_zctrl = None
        self.__notes_on = []

        self.status_info = {}
        self.status_object = zynthian_gui_status_data(self)
        self.status_counter = 0

        self.zynautoconnect_audio_flag = False
        self.zynautoconnect_midi_flag = False

        # Create Lock object to avoid concurrence problems
        self.lock = Lock()
        self.osc_server = None

        # Load keyboard binding map
        zynthian_gui_keybinding.getInstance(self).load()

        # Get Jackd Options
        self.jackd_options = zynconf.get_jackd_options()

        self.__fake_keys_pressed = set()
        # When true 1-6 switch sounds instead of tracks
        self.__layer_track_mode_switch = False

        # Initialize peakmeter audio monitor if needed
        if not zynthian_gui_config.show_cpu_status:
            try:
                global lib_jackpeak
                lib_jackpeak = lib_jackpeak_init()
                lib_jackpeak.setDecay(c_float(0.2))
                lib_jackpeak.setHoldCount(10)
            except Exception as e:
                logging.error("ERROR initializing jackpeak: %s" % e)

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

        if "zynseq" in zynthian_gui_config.experimental_features:
            self.libseq = CDLL(
                "/zynthian/zynthian-ui/zynlibs/zynseq/build/libzynseq.so"
            )
            self.libseq.init(True)


    # ---------------------------------------------------------------------------
    # WS281X LEDs
    # ---------------------------------------------------------------------------

    def init_wsleds(self):
        if zynthian_gui_config.wiring_layout=="Z2_V1":
            # LEDS with PWM1 (pin 13, channel 1)
            pin = 13
            chan = 1
        elif zynthian_gui_config.wiring_layout=="Z2_V2":
            # LEDS with SPI0 (pin 10, channel 0)
            pin = 10
            chan = 0
        else:
            self.wsleds = None
            return 0

        self.wsleds_num = 25
        self.wsleds=rpi_ws281x.PixelStrip(self.wsleds_num, pin, dma=10, channel=chan, strip_type=rpi_ws281x.ws.WS2811_STRIP_GRB)
        self.wsleds.begin()

        self.wscolor_off = rpi_ws281x.Color(0,0,0)
        self.wscolor_light = rpi_ws281x.Color(0,50,200)
        self.wscolor_active = rpi_ws281x.Color(0,255,0)
        self.wscolor_admin = rpi_ws281x.Color(120,0,0)
        self.wscolor_red = rpi_ws281x.Color(120,0,0)
        self.wscolor_green = rpi_ws281x.Color(0,255,0)

        # Light all LEDs
        for i in range(0,25):
            self.wsleds.setPixelColor(i,self.wscolor_light)
        self.wsleds.show()

        self.wsleds_blink_count = 0

        return self.wsleds_num


    def end_wsleds(self):
        # Light-off all LEDs
        for i in range(0,25):
            self.wsleds.setPixelColor(i,self.wscolor_off)
        self.wsleds.show()


    def wsled_blink(self, i, color):
        if self.wsleds_blink:
            self.wsleds.setPixelColor(i, color)
        else:
            self.wsleds.setPixelColor(i, self.wscolor_light)


    def update_wsleds(self):
        if self.wsleds_blink_count % 6 > 2:
            self.wsleds_blink = True
        else:
            self.wsleds_blink = False

        try:
            # Menu
            if self.modal_screen==None and self.active_screen=="main":
                self.wsleds.setPixelColor(0,self.wscolor_active)
            else:
                self.wsleds.setPixelColor(0,self.wscolor_light)

            # To blink aled
            #self.wsled_blink(0,self.wscolor_active)
            # Active Track
            for i in range(6):
                self.wsleds.setPixelColor(1+i,self.wscolor_light)
            i = None
            if self.__layer_track_mode_switch:
                i = self.screens['layers_for_track'].index
            else:
                i = self.screens['session_dashboard'].selectedTrack
            if i is not None and i<6:
                self.wsleds.setPixelColor(1+i,self.wscolor_active)

            if self.__layer_track_mode_switch:
                self.wsleds.setPixelColor(7,self.wscolor_active)
            else:
                self.wsleds.setPixelColor(7,self.wscolor_light)

            # Stepseq screen:
            if self.modal_screen=="zynthiloops":
                self.wsleds.setPixelColor(8,self.wscolor_active)
            else:
                self.wsleds.setPixelColor(8,self.wscolor_light)

            # Audio Recorder screen:
            if self.modal_screen=="playgrid":
                self.wsleds.setPixelColor(9,self.wscolor_active)
            else:
                self.wsleds.setPixelColor(9,self.wscolor_light)

            # MIDI Recorder screen:
            if self.modal_screen==None and (self.active_screen=="layers_for_track" or self.active_screen=="bank" or self.active_screen=="preset"):
                self.wsleds.setPixelColor(10,self.wscolor_active)
            else:
                self.wsleds.setPixelColor(10,self.wscolor_light)

            # Snapshot screen:
            if self.modal_screen=="song_arranger":
                self.wsleds.setPixelColor(11,self.wscolor_active)
            else:
                self.wsleds.setPixelColor(11,self.wscolor_light)

            # Presets screen:
            if self.modal_screen=="admin":
                self.wsleds.setPixelColor(12,self.wscolor_active)
            else:
                self.wsleds.setPixelColor(12,self.wscolor_light)

            # Light ALT button
            self.wsleds.setPixelColor(13,self.wscolor_light)

            if self.screens["zynthiloops"].clipToRecord is None:
                self.wsleds.setPixelColor(14,self.wscolor_light)
            else:
                self.wsleds.setPixelColor(14,self.wscolor_red)

            if self.screens["zynthiloops"].isMetronomeRunning:
                self.wsleds.setPixelColor(15,self.wscolor_active)
            else:
                self.wsleds.setPixelColor(15,self.wscolor_light)

            ## REC/PLAY Audio buttons:
            #if self.status_info['audio_recorder']:
                #if "REC" in self.status_info['audio_recorder']:
                    #self.wsleds.setPixelColor(14,self.wscolor_red)
                #else:
                    #self.wsleds.setPixelColor(14,self.wscolor_light)

                #if "PLAY" in self.status_info['audio_recorder']:
                    #self.wsleds.setPixelColor(15,self.wscolor_active)
                #else:
                    #self.wsleds.setPixelColor(15,self.wscolor_light)
            #else:
                #self.wsleds.setPixelColor(14,self.wscolor_light)
                #self.wsleds.setPixelColor(15,self.wscolor_light)

            ## REC/PLAY MIDI buttons:
            #if self.status_info['midi_recorder']:
                #if "REC" in self.status_info['midi_recorder']:
                    #self.wsleds.setPixelColor(16,self.wscolor_red)
                #else:
                    #self.wsleds.setPixelColor(16,self.wscolor_light)

                #if "PLAY" in self.status_info['midi_recorder']:
                    #self.wsleds.setPixelColor(17,self.wscolor_active)
                #else:
                    #self.wsleds.setPixelColor(17,self.wscolor_light)
            #else:
                #self.wsleds.setPixelColor(16,self.wscolor_light)
                #self.wsleds.setPixelColor(17,self.wscolor_light)

            # Back/No button
            self.wsleds.setPixelColor(18,self.wscolor_red)

            # Up button
            self.wsleds.setPixelColor(19,self.wscolor_light)

            # Select/Yes button
            self.wsleds.setPixelColor(20,self.wscolor_green)

            # Left, Bottom, Right button
            for i in range(3):
                self.wsleds.setPixelColor(21+i,self.wscolor_light)

            # Audio Mixer/Levels screen
            if self.modal_screen=="audio_settings":
                self.wsleds.setPixelColor(24,self.wscolor_active)
            else:
                self.wsleds.setPixelColor(24,self.wscolor_light)

            # Refresh LEDs
            self.wsleds.show()

        except Exception as e:
            logging.error(e)

        self.wsleds_blink_count += 1


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
        self.screens["track"] = zynthian_gui_track(self)
        # self.screens['control_xy'] = zynthian_gui_control_xy(self)
        # self.screens['midi_profile'] = zynthian_gui_midi_profile(self)
        # self.screens['zs3_learn'] = zynthian_gui_zs3_learn(self)
        # self.screens['zs3_options'] = zynthian_gui_zs3_options(self)
        self.screens["main"] = zynthian_gui_main(self)
        self.screens["module_downloader"] = zynthian_gui_newstuff(self)
        self.screens["admin"] = zynthian_gui_admin(self)
        self.screens["audio_settings"] = zynthian_gui_audio_settings(self)
        self.screens["synth_behaviour"] = zynthian_gui_synth_behaviour(self)
        self.screens["snapshots_menu"] = zynthian_gui_snapshots_menu(self)

        self.screens["network"] = zynthian_gui_network(self)
        self.screens["network_info"] = self.screens["network"]
        self.screens["hardware"] = zynthian_gui_hardware(self)

        # self.screens['touchscreen_calibration'] = zynthian_gui_touchscreen_calibration(self)
        # Create UI Apps Screens
        self.screens['alsa_mixer'] = self.screens['control']
        self.screens["audio_recorder"] = zynthian_gui_audio_recorder(self)
        self.screens["midi_recorder"] = zynthian_gui_midi_recorder(self)
        self.screens["test_touchpoints"] = zynthian_gui_test_touchpoints(self)

        ###
        # ZynthiLoops depends on master_alsa_mixer screen for master volume related functionalities
        # and hence needs to be initialized before ZL page has been initialized
        ###
        self.screens["master_alsa_mixer"] = zynthian_gui_master_alsa_mixer(self)

        self.screens["zynthiloops"] = zynthian_gui_zynthiloops(self)

        ###
        # Session Dashboard depends on ZL to load sketches and hence needs to be initialized after ZL page
        ###
        self.screens["session_dashboard"] = zynthian_gui_session_dashboard(self)

        ###
        # Fixed layers depends on zynthiloops and session_dashboard screens and hence needs to be initialized
        # after those 2 pages
        ###
        self.screens["layers_for_track"] = zynthian_gui_layers_for_track(self)
        self.screens["fixed_layers"] = zynthian_gui_fixed_layers(self)
        self.screens["main_layers_view"] = zynthian_gui_fixed_layers(self)

        # if "autoeq" in zynthian_gui_config.experimental_features:
        # self.screens['autoeq'] = zynthian_gui_autoeq(self)
        # if "zynseq" in zynthian_gui_config.experimental_features:
        # self.screens['stepseq'] = zynthian_gui_stepsequencer(self)
        self.screens["theme_chooser"] = zynthian_gui_theme_chooser(self)
        self.screens["theme_downloader"] = zynthian_gui_newstuff(self)
        self.screens["sound_downloader"] = zynthian_gui_newstuff(self)
        self.screens["soundfont_downloader"] = zynthian_gui_newstuff(self)
        self.screens["soundset_downloader"] = zynthian_gui_newstuff(self)
        self.screens["sequence_downloader"] = zynthian_gui_newstuff(self)
        self.screens["sketch_downloader"] = zynthian_gui_newstuff(self)

        ###
        # Playgrid depends on zynthiloops screen for metronome related functionalities
        # and hence needs to be initialized after ZL page has been initialized
        # TODO Make the metronome independant of ZL and more generic
        ###
        self.screens["playgrid"] = zynthian_gui_playgrid(self)
        self.screens["playgrid_downloader"] = zynthian_gui_newstuff(self)
        self.screens["miniplaygrid"] = zynthian_gui_playgrid(self)

        self.screens["song_arranger"] = zynthian_gui_song_arranger(self)
        self.screens["sketch_copier"] = zynthian_gui_sketch_copier(self)

        # Init Auto-connector
        zynautoconnect.start()

        # Initialize OSC
        self.osc_init()

        # Initial snapshot...
        snapshot_loaded = False
        # Try to load "last_state" snapshot ...
        if zynthian_gui_config.restore_last_state:
            snapshot_loaded = self.screens[
                "snapshot"
            ].load_last_state_snapshot()
        # Try to load "default" snapshot ...
        if not snapshot_loaded:
            snapshot_loaded = self.screens["snapshot"].load_default_snapshot()
        # Set empty state
        if not snapshot_loaded:
            # Init MIDI Subsystem => MIDI Profile
            self.init_midi()
            self.init_midi_services()
            self.zynautoconnect()
            # Show initial screen
            self.show_screen(self.__home_screen)

        # Start polling threads
        self.start_polling()
        self.start_loading_thread()
        self.start_status_thread()
        self.start_zyncoder_thread()

        # Run autoconnect if needed
        self.zynautoconnect_do()

        # Initialize MPE Zones
        # self.init_mpe_zones(0, 2)

    def stop(self):
        logging.info("STOPPING ZYNTHIAN-UI ...")
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
        elif screen is "layer" or screen is "main_layers_view" or screen is "fixed_layers":  #HACK replace completely layer with layers_for_track
            screen = "layers_for_track"

        if (
            screen == "layer"
            or screen == "fixed_layers"
            or screen == "main_layers_view"
            or screen ==  "layers_for_track"
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
        logging.error("AAAAA{}".format(screen))
        logging.error(self.screens[screen])
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
        logging.error(tms)
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
                    self.screens["layer"].show()
                # If there is only one bank, jump to preset selection
                if len(self.curlayer.bank_list) <= 1:
                    self.screens["bank"].select_action(0)
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
        self.screens["layers_for_track"].sync_index_from_curlayer()
        self.screens["bank"].fill_list()
        self.screens["bank"].show()
        self.screens["preset"].fill_list()
        self.screens["preset"].show()
        self.screens["control"].fill_list()
        self.screens["control"].show()
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

    # -------------------------------------------------------------------
    # Callable UI Actions
    # -------------------------------------------------------------------

    @Slot(str)
    def callable_ui_action(self, cuia, params=None):
        logging.debug("CUIA '{}' => {}".format(cuia, params))

        if cuia != "SCREEN_MAIN" and self.current_qml_page != None:
            js_value = self.current_qml_page_prop.property("cuiaCallback")
            if js_value != None and js_value.isCallable():
                if js_value.call([cuia]).toBool():
                    return

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
                self.screens["zynthiloops"].song.scenesModel.selectedSceneIndex = max(0, self.screens["zynthiloops"].song.scenesModel.selectedSceneIndex - 1)
            except:
                pass

        elif cuia == "SCENE_DOWN":
            try:
                self.screens["zynthiloops"].song.scenesModel.selectedSceneIndex = min(self.screens["zynthiloops"].song.scenesModel.count - 1, self.screens["zynthiloops"].song.scenesModel.selectedSceneIndex + 1)
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

        elif cuia == "SCREEN_ADMIN":
            self.show_modal("admin")

        elif cuia == "SCREEN_LAYER":
            self.show_screen("layers_for_track")

        elif cuia == "SCREEN_LAYER_FX":
            self.show_screen("layer_effects")

        elif cuia == "SCREEN_BANK":
            self.show_screen("bank")

        elif cuia == "SCREEN_PRESET":
            self.show_screen("preset")

        elif cuia == "SCREEN_CONTROL":
            self.show_screen("control")

        elif cuia == "SCREEN_ZYNTHILOOPS":
            self.show_modal("zynthiloops")

        elif cuia == "SCREEN_ARRANGER":
            self.show_modal("song_arranger")

        elif cuia == "SCREEN_PLAYGRID":
            self.show_modal("playgrid")

        elif cuia == "SCREEN_AUDIO_SETTINGS":
            self.toggle_modal("audio_settings")

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

        elif cuia == "TRACK_1":
            if self.__layer_track_mode_switch:
                self.screens['layers_for_track'].select_action(0)
            else:
                self.screens["session_dashboard"].selectedTrack = 0
        elif cuia == "TRACK_2":
            if self.__layer_track_mode_switch:
                self.screens['layers_for_track'].select_action(1)
            else:
                self.screens["session_dashboard"].selectedTrack = 1
        elif cuia == "TRACK_3":
            if self.__layer_track_mode_switch:
                self.screens['layers_for_track'].select_action(2)
            else:
                self.screens["session_dashboard"].selectedTrack = 2
        elif cuia == "TRACK_4":
            if self.__layer_track_mode_switch:
                self.screens['layers_for_track'].select_action(3)
            else:
                self.screens["session_dashboard"].selectedTrack = 3
        elif cuia == "TRACK_5":
            if self.__layer_track_mode_switch:
                self.screens['layers_for_track'].select_action(4)
            else:
                self.screens["session_dashboard"].selectedTrack = 4
        elif cuia == "TRACK_6":
            if self.__layer_track_mode_switch:
                self.screens['layers_for_track'].select_action(5)
            else:
                self.screens["session_dashboard"].selectedTrack = 5
        elif cuia == "TRACK_7":
            self.screens["session_dashboard"].selectedTrack = 6
        elif cuia == "TRACK_8":
            self.screens["session_dashboard"].selectedTrack = 7
        elif cuia == "TRACK_9":
            self.screens["session_dashboard"].selectedTrack = 8
        elif cuia == "TRACK_10":
            self.screens["session_dashboard"].selectedTrack = 9
        elif cuia == "TRACK_11":
            self.screens["session_dashboard"].selectedTrack = 10
        elif cuia == "TRACK_12":
            self.screens["session_dashboard"].selectedTrack = 11

        elif cuia == "TRACK_PREVIOUS":
            if self.screens["session_dashboard"].selectedTrack > 0:
                self.screens["session_dashboard"].selectedTrack -= 1
        elif cuia == "TRACK_NEXT":
            if self.screens["session_dashboard"].selectedTrack < 11:
                self.screens["session_dashboard"].selectedTrack += 1

        elif cuia == "KEYBOARD":
            logging.error("KEYBOARD")
            self.miniPlayGridToggle.emit()

        elif cuia == "ZL_PLAY":
            self.run_start_metronome_and_playback.emit()

        elif cuia == "ZL_STOP":
            zl = self.screens["zynthiloops"]
            if zl.clipToRecord is not None:
                # A Clip is currently being recorded
                clip = zl.clipToRecord
                logging.error("CUIA Stop Recording")
                logging.error(f"Recording Clip : {clip}")
                clip.stopRecording()
                zl.song.scenesModel.addClipToCurrentScene(clip)
            self.run_stop_metronome_and_playback.emit()

        elif cuia == "START_RECORD":
            zl = self.screens["zynthiloops"]
            if zl.clipToRecord is None:
                # No clips are currently being recorded
                logging.error("CUIA Start Recording")
                clip = zl.song.getClip(self.session_dashboard.selectedTrack, zl.selectedClipCol)
                logging.error(f"Recording Clip : {clip}")
                clip.queueRecording("internal", "*")
                self.run_start_metronome_and_playback.emit()
            else:
                # Some Clip is currently being recorded
                logging.error("Cannot start recording until the current recording is stopped")
                clip = zl.clipToRecord
                clip.stopRecording()
                zl.song.scenesModel.addClipToCurrentScene(clip)

        elif cuia == "STOP_RECORD":
            zl = self.screens["zynthiloops"]
            if zl.clipToRecord is not None:
                # A Clip is currently being recorded
                clip = zl.clipToRecord
                logging.error("CUIA Stop Recording")
                logging.error(f"Recording Clip : {clip}")
                clip.stopRecording()
                zl.song.scenesModel.addClipToCurrentScene(clip)
            else:
                # No Clip is currently being recorded
                logging.error("No clip is being recorded")

        elif cuia == "MODE_SWITCH_SHORT" or cuia == "MODE_SWITCH_BOLD" or cuia == "MODE_SWITCH_LONG":
            # Switch between track and sound mode
            self.__layer_track_mode_switch = not self.__layer_track_mode_switch

    def custom_switch_ui_action(self, i, t):
        try:
            if t in zynthian_gui_config.custom_switch_ui_actions[i]:
                logging.error("Executing CUIA action: {}".format(zynthian_gui_config.custom_switch_ui_actions[i]))
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
            if dtus == 0:
                logging.error("key press: {} {}".format(i, dtus))
                if self.fake_key_event_for_zynswitch(i, True):
                    return
            elif dtus > 0:
                logging.error("key release: {} {}".format(i, dtus))
                if self.fake_key_event_for_zynswitch(i, False):
                    return

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

    zynswitch_short_triggered = Signal(int)
    zynswitch_long_triggered = Signal(int)
    zynswitch_bold_triggered = Signal(int)

    def fake_key_event_for_zynswitch(self, i : int, press : bool):
        fake_key = None

        # ALT
        if i == 17:
            fake_key = Key.ctrl
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
        # Track buttons
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
        elif i == 10:
            fake_key = "6"
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
                self.__fake_keys_pressed.add(fake_key)
                self.fakeKeyboard.press(fake_key)
        else:
            if fake_key in self.__fake_keys_pressed:
                self.__fake_keys_pressed.discard(fake_key)
                self.fakeKeyboard.release(fake_key)
        return True


    def zynswitch_long(self, i):
        logging.info("Looooooooong Switch " + str(i))
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
            if (
                not self.zynread_wait_flag
            ):  # FIXME: poor man's mutex? actually works only with this one FIXME: REVERT
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
        if not self.loading:  # TODO Es necesario???
            try:
                # TODO: figure out the multithreading error

                # Read Zyncoders
                self.lock.acquire()
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
        self.deferred_loading_timer.start()
        QGuiApplication.instance().processEvents(QEventLoop.AllEvents, 1000)
        self.is_loading_changed.emit()
        # logging.debug("START LOADING %d" % self.loading)

    @Slot(None)
    def stop_loading(self):
        self.loading = self.loading - 1
        if self.loading < 0:
            self.loading = 0

        if self.loading == 0:
            self.deferred_loading_timer.stop()
            self.is_loading_changed.emit()
        # logging.debug("STOP LOADING %d" % self.loading)

    def reset_loading(self):
        self.is_loading_changed.emit()
        self.deferred_loading_timer.stop()
        self.loading = 0

    def get_is_loading(self):
        return self.loading > 0

    # FIXME: is this necessary?
    def loading_refresh(self):
        while not self.exit_flag:
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
            logging.error(
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

    #------------------------------------------------------------------
    # Status Refresh Thread
    #------------------------------------------------------------------

    def start_status_thread(self):
        self.status_thread=Thread(target=self.status_thread_task, args=())
        self.status_thread.daemon = True # thread dies with the program
        self.status_thread.start()


    def status_thread_task(self):
        while not self.exit_flag:
            #self.refresh_status()
            if self.wsleds:
                self.update_wsleds()
            time.sleep(0.2)
        self.end_wsleds()

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
                zynthian_gui_config.app.exit(self.exit_code)
                return
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
            else:
                # Get audio peak level
                self.status_info["peakA"] = lib_jackpeak.getPeak(0)
                self.status_info["peakB"] = lib_jackpeak.getPeak(1)
                self.status_info["holdA"] = lib_jackpeak.getHold(0)
                self.status_info["holdB"] = lib_jackpeak.getHold(1)

            # Get Status Flags (once each 5 refreshes)
            if self.status_counter > 5:
                self.status_counter = 0

                self.status_info["undervoltage"] = False
                self.status_info["overtemp"] = False
                try:
                    # Get ARM flags
                    res = check_output(("vcgencmd", "get_throttled")).decode(
                        "utf-8", "ignore"
                    )
                    thr = int(res[12:], 16)
                    if thr & 0x1:
                        self.status_info["undervoltage"] = True
                    elif thr & (0x4 | 0x2):
                        self.status_info["overtemp"] = True

                except Exception as e:
                    logging.error(e)

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
            zyngui.callable_ui_action(action)

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

        logging.error(panel)
        logging.error(panel.winId())
        logging.error(window)
        display.sync()

    @Slot(None)
    def close_current_window(self):
        if zynthian_gui_config.app.focusWindow():
            return
        display = Xlib.display.Display()
        root = display.screen().root
        wid = root.get_full_property(display.intern_atom('_NET_ACTIVE_WINDOW'), Xlib.X.AnyPropertyType).value[0]

        logging.error(wid)
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
        with open("/tmp/mplayer-splash-control", "w") as f:
            f.write("quit\n")
            f.close()

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

    @Property(QObject, constant=True)
    def about(self):
        return self.screens["about"]

    def get_engine(self):
        return self.screens["engine"]

    def get_layer(self):
        return self.screens["layer"]

    def get_fixed_layers(self):
        return self.screens["fixed_layers"]

    def get_layers_for_track(self):
        return self.screens["layers_for_track"]

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

    def get_track(self):
        return self.screens["track"]

    @Property(QObject, constant=True)
    def audio_out(self):
        return self.screens["audio_out"]

    @Property(QObject, constant=True)
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

    def get_sound_downloader(self):
        return self.screens["sound_downloader"]

    def get_soundfont_downloader(self):
        return self.screens["soundfont_downloader"]

    def get_soundset_downloader(self):
        return self.screens["soundset_downloader"]

    def get_sequence_downloader(self):
        return self.screens["sequence_downloader"]

    def get_sketch_downloader(self):
        return self.screens["sketch_downloader"]

    @Property(QObject, constant=True)
    def test_touchpoints(self):
        return self.screens["test_touchpoints"]

    @Property(QObject, constant=True)
    def playgrid(self):
        return self.screens["playgrid"]

    @Property(QObject, constant=True)
    def miniplaygrid(self):
        return self.screens["miniplaygrid"]

    @Property(QObject, constant=True)
    def zynthiloops(self):
        return self.screens["zynthiloops"]

    @Property(QObject, constant=True)
    def audio_settings(self):
        return self.screens["audio_settings"]

    @Property(QObject, constant=True)
    def synth_behaviour(self):
        return self.screens["synth_behaviour"]

    @Property(QObject, constant=True)
    def snapshots_menu(self):
        return self.screens["snapshots_menu"]

    @Property(QObject, constant=True)
    def network(self):
        return self.screens["network"]

    @Property(QObject, constant=True)
    def hardware(self):
        return self.screens["hardware"]

    @Property(QObject, constant=True)
    def master_alsa_mixer(self):
        return self.screens["master_alsa_mixer"]

    @Property(QObject, constant=True)
    def session_dashboard(self):
        return self.screens["session_dashboard"]

    @Property(QObject, constant=True)
    def song_arranger(self):
        return self.screens["song_arranger"]

    @Property(QObject, constant=True)
    def sketch_copier(self):
        return self.screens["sketch_copier"]

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
    layers_for_track = Property(QObject, get_layers_for_track, constant=True)
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
    track = Property(QObject, get_track, constant=True)
    audio_recorder = Property(QObject, get_audio_recorder, constant=True)
    midi_recorder = Property(QObject, get_midi_recorder, constant=True)
    playgrid_downloader = Property(QObject, get_playgrid_downloader, constant=True)
    theme_chooser = Property(QObject, get_theme_chooser, constant=True)
    theme_downloader = Property(QObject, get_theme_downloader, constant=True)
    sound_downloader = Property(QObject, get_sound_downloader, constant=True)
    soundfont_downloader = Property(QObject, get_soundfont_downloader, constant=True)
    soundset_downloader = Property(QObject, get_soundset_downloader, constant=True)
    sequence_downloader = Property(QObject, get_sequence_downloader, constant=True)
    sketch_downloader = Property(QObject, get_sketch_downloader, constant=True)


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

    zyngui.exit(exit_code)


signal.signal(signal.SIGHUP, exit_handler)
signal.signal(signal.SIGINT, exit_handler)
signal.signal(signal.SIGQUIT, exit_handler)
signal.signal(signal.SIGTERM, exit_handler)


def delete_window():
    exit_code = 101
    zyngui.exit(exit_code)


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
# zyngui.callable_ui_action(action)


# zynthian_gui_config.top.bind("<Key>", cb_keybinding)

# zynthian_gui_config.top.protocol("WM_DELETE_WINDOW", delete_window)

# ------------------------------------------------------------------------------
# TKinter Main Loop
# ------------------------------------------------------------------------------

# import cProfile
# cProfile.run('zynthian_gui_config.top.mainloop()')

# zynthian_gui_config.top.mainloop()

# logging.info("Exit with code {} ...\n\n".format(zyngui.exit_code))
# exit(zyngui.exit_code)


# ------------------------------------------------------------------------------
# GUI & Synth Engine initialization
# ------------------------------------------------------------------------------

if __name__ == "__main__":
    libzl.init()
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()

    nullCursor = QPixmap(16, 16);
    nullCursor.fill(Qt.transparent);
    app.setOverrideCursor(QCursor(nullCursor));

    logging.info("REGISTERING QML TYPES")
    qmlRegisterType(file_properties_helper, "Helpers", 1, 0, "FilePropertiesHelper")

    logging.info("STARTING ZYNTHIAN-UI ...")
    zynthian_gui_config.zyngui = zyngui = zynthian_gui()
    zyngui.start()

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

    zyngui.screens["theme_chooser"].apply_font()
    # font = app.font()
    # font.setPointSize(12)
    # font.setFamily("Roboto")
    # app.setFont(font)

    zyngui.show_screen(zyngui.home_screen)
    zyngui.screens["preset"].disable_show_fav_presets()

    engine.addImportPath(os.fspath(Path(__file__).resolve().parent / "qml-ui"))
    engine.rootContext().setContextProperty("zynthian", zyngui)

    def load_qml():
        engine.load(os.fspath(Path(__file__).resolve().parent / "qml-ui/main.qml"))

        if not engine.rootObjects() or not app.topLevelWindows():
            sys.exit(-1)

        # assuming there is one and only one window for now
        zynthian_gui_config.top = app.topLevelWindows()[0]
        zynthian_gui_config.app = app

    # Delay loading qml to let zyngui complete it's init sequence
    # Without the delay, UI sometimes doest start when `systemctl restart zynthian` is ran
    QTimer.singleShot(1000, load_qml)

    sys.exit(app.exec_())

# ------------------------------------------------------------------------------
