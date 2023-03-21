#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthian LED Configuration : A page to configure LED colors
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

from PySide2.QtCore import Property, QTimer, Signal, Slot

import logging

import rpi_ws281x

from . import zynthian_qt_gui_base


class zynthian_gui_led_config(zynthian_qt_gui_base.ZynGui):
    """
    A Helper class that sets correct led color per button as per current state

    To set a led color to a button :
    self.button_color_map[0] = {
        'color': <One of the self.led_color_*>,
        'blink': <True or False> # Setting to True will make the led blink as per the blinkMode
        'blinkMode': <'toggleOnBeat'(default) or 'onOffOnBeat'> # toggleOnBeat will toggle on/off state on every beat
                                                                # onOffOnBeat will blink the button color on=off on every beat
    }

    Button id map :
    0 : Menu
    1 : 1
    2 : 2
    3 : 3
    4 : 4
    5 : 5
    6 : 6
    7 : FX
    8 : Under Screen Button 1
    9 : Under Screen Button 2
    10 : Under Screen Button 3
    11 : Under Screen Button 4
    12 : Under Screen Button 5
    13 : ALT
    14 : RECORD
    15 : PLAY
    16 : SAVE
    17 : STOP
    18 : BACK/NO
    19 : UP
    20 : SELECT/YES
    21 : LEFT
    22 : BOTTOM
    23 : RIGHT
    24 : MASTER
    """
    def __init__(self, parent=None):
        super(zynthian_gui_led_config, self).__init__(parent)

        self.led_color_off = rpi_ws281x.Color(0, 0, 0)
        self.led_color_blue = rpi_ws281x.Color(0, 50, 200)
        self.led_color_green = rpi_ws281x.Color(0, 255, 0)
        self.led_color_red = rpi_ws281x.Color(247, 124, 124)
        self.led_color_yellow = rpi_ws281x.Color(255, 235, 59)
        self.led_color_purple = rpi_ws281x.Color(142, 36, 170)

        self.led_color_inactive = self.led_color_blue
        self.led_color_active = self.led_color_green

        self.led_color_channel_synth = self.led_color_red
        self.led_color_channel_loop = self.led_color_green
        self.led_color_channel_sample = self.led_color_yellow
        self.led_color_channel_external = self.led_color_purple

        self.button_color_map = {}
        self.channel = None

        self.button_menu = 0
        self.button_1 = 1
        self.button_2 = 2
        self.button_3 = 3
        self.button_4 = 4
        self.button_5 = 5
        self.button_star = 6
        self.button_mode = 7
        self.button_under_screen_1 = 8
        self.button_under_screen_2 = 9
        self.button_under_screen_3 = 10
        self.button_under_screen_4 = 11
        self.button_under_screen_5 = 12
        self.button_alt = 13
        self.button_record = 14
        self.button_play = 15
        self.button_metronome = 16
        self.button_stop = 17
        self.button_back = 18
        self.button_up = 19
        self.button_select = 20
        self.button_left = 21
        self.button_down = 22
        self.button_right = 23
        self.button_global = 24

        # Initialise all button with inactive color and not blinking
        for i in range(25):
            self.set_button_color(i, self.led_color_inactive)

    def show(self):
        pass

    def zyncoder_read(self):
        pass

    def refresh_loading(self):
        pass

    def set_button_color(self, button_id, color, setChannelColor=False, blink=False, blinkMode='onOffOnBeat'):
        if setChannelColor:
            if self.channel.channelAudioType == "synth":
                self.button_color_map[button_id] = {
                    'color': self.led_color_channel_synth,
                    'blink': blink,
                    'blinkMode': blinkMode
                }
            elif self.channel.channelAudioType in ["sample-trig", "sample-slice"]:
                self.button_color_map[button_id] = {
                    'color': self.led_color_channel_sample,
                    'blink': blink,
                    'blinkMode': blinkMode
                }
            elif self.channel.channelAudioType == "sample-loop":
                self.button_color_map[button_id] = {
                    'color': self.led_color_channel_loop,
                    'blink': blink,
                    'blinkMode': blinkMode
                }
            elif self.channel.channelAudioType == "external":
                self.button_color_map[button_id] = {
                    'color': self.led_color_channel_external,
                    'blink': blink,
                    'blinkMode': blinkMode
                }
        else:
            assert color is not None, "color cannot be None when setChannelColor is False"

            self.button_color_map[button_id] = {
                'color': color,
                'blink': blink,
                'blinkMode': blinkMode
            }

    def update_button_colors(self):
        try:
            if self.zyngui.sketchpad.song is not None and (self.channel is None or (
                    self.channel is not None and self.channel.id != self.zyngui.session_dashboard.selectedChannel)):
                logging.debug(f"LED Config : Setting channel to {self.zyngui.session_dashboard.selectedChannel}")
                self.channel = self.zyngui.sketchpad.song.channelsModel.getChannel(self.zyngui.session_dashboard.selectedChannel)
        except Exception as e:
            logging.error(e)

        if self.channel is None:
            # Do not continue if channel is not yet instantiated
            return

        menu_page_active = self.zyngui.modal_screen is None and self.zyngui.active_screen == "main"
        sketchpad_page_active = self.zyngui.current_screen_id == "sketchpad"
        playgrid_page_active = self.zyngui.current_screen_id == "playgrid"
        song_manager_page_active = self.zyngui.current_screen_id == "song_manager"
        library_page_active = self.zyngui.current_screen_id in ["layers_for_channel", "bank", "preset"]
        edit_page_active = self.zyngui.current_screen_id == "control" or self.zyngui.current_screen_id in ["channel_wave_editor", "channel_external_setup"]

        for index, button in enumerate([self.button_1, self.button_2, self.button_3, self.button_4, self.button_5]):
            # If left sidebar is active, blink selected part buttons for sample modes or blink filled clips for loop mode
            # This is global (i.e. for all screens)
            if self.zyngui.leftSidebarActive:
                # Lights up selected slots for channel
                partClip = self.zyngui.sketchpad.song.getClipByPart(self.channel.id, self.zyngui.sketchpad.song.scenesModel.selectedTrackIndex, index)
                self.set_button_color(button, self.led_color_inactive, setChannelColor=partClip.enabled)
            else:
                # Light up 1-5 buttons when respective channel is selected
                # If self.zyngui.channelsModActive is true, light up 1-5 HW button when channels 6-10 is selected
                channelDelta = 5 if self.zyngui.channelsModActive else 0
                selectedChannelIndex = self.zyngui.session_dashboard.selectedChannel - channelDelta
                self.set_button_color(button, self.led_color_inactive, setChannelColor=selectedChannelIndex == index)

        self.set_button_color(self.button_menu, self.led_color_active if menu_page_active else self.led_color_inactive)
        self.set_button_color(self.button_star, self.led_color_inactive, setChannelColor=not self.zyngui.leftSidebarActive and self.zyngui.channelsModActive)
        self.set_button_color(self.button_mode, self.led_color_inactive, setChannelColor=self.zyngui.leftSidebarActive)
        self.set_button_color(self.button_under_screen_1, self.led_color_active if sketchpad_page_active else self.led_color_inactive)
        self.set_button_color(self.button_under_screen_2, self.led_color_active if playgrid_page_active else self.led_color_inactive)
        self.set_button_color(self.button_under_screen_3, self.led_color_active if song_manager_page_active else self.led_color_inactive)
        self.set_button_color(self.button_under_screen_4, self.led_color_active if library_page_active else self.led_color_inactive)
        self.set_button_color(self.button_under_screen_5, self.led_color_active if edit_page_active else self.led_color_inactive)
        self.set_button_color(self.button_alt, self.led_color_inactive)
        self.set_button_color(self.button_record, self.led_color_red if self.zyngui.sketchpad.isRecording else self.led_color_inactive)
        self.set_button_color(self.button_play, self.led_color_active if self.zyngui.sketchpad.isMetronomeRunning else self.led_color_inactive)
        self.set_button_color(self.button_metronome, self.led_color_inactive if self.zyngui.sketchpad.clickChannelEnabled else self.led_color_off, blink=self.zyngui.sketchpad.isMetronomeRunning)
        self.set_button_color(self.button_stop, self.led_color_inactive)
        self.set_button_color(self.button_back, self.led_color_red)
        self.set_button_color(self.button_up, self.led_color_inactive)
        self.set_button_color(self.button_select, self.led_color_green)
        self.set_button_color(self.button_left, self.led_color_inactive)
        self.set_button_color(self.button_down, self.led_color_inactive)
        self.set_button_color(self.button_right, self.led_color_inactive)
        self.set_button_color(self.button_global, self.led_color_active if self.zyngui.globalPopupOpened else self.led_color_inactive)
