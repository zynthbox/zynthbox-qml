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

        # Initialise all button with inactive color and not blinking
        for i in range(25):
            self.set_button_color(i, self.led_color_inactive)

    def show(self):
        pass

    def zyncoder_read(self):
        pass

    def refresh_loading(self):
        pass

    def set_button_color(self, button_id, color, blink=False, blinkMode='onOffOnBeat'):
        self.button_color_map[button_id] = {
            'color': color,
            'blink': blink,
            'blinkMode': blinkMode
        }

    def set_button_color_by_channel(self, button_id, blink=False, blinkMode='onOffOnBeat'):
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

    def update_button_colors(self):
        try:
            if self.zyngui.sketchpad.song is not None and (self.channel is None or (
                    self.channel is not None and self.channel.id != self.zyngui.session_dashboard.selectedChannel)):
                logging.debug(f"LED Config : Setting channel to {self.zyngui.session_dashboard.selectedChannel}")
                self.channel = self.zyngui.sketchpad.song.channelsModel.getChannel(self.zyngui.session_dashboard.selectedChannel)
        except Exception as e:
            logging.error(e)

        # Menu
        if self.zyngui.modal_screen is None and self.zyngui.active_screen == "main":
            self.set_button_color(0, self.led_color_active)
        else:
            self.set_button_color(0, self.led_color_inactive)

        # Light up 1-5 buttons as per opened screen / bottomBar
        for i in range(1, 6):
            # If left sidebar is active, blink selected part buttons for sample modes or blink filled clips for loop mode
            # This is global (i.e. for all screens)
            if self.zyngui.leftSidebarActive:
                # Lights up selected slots for channel
                partClip = self.zyngui.sketchpad.song.getClipByPart(self.channel.id,
                                                                    self.zyngui.sketchpad.song.scenesModel.selectedTrackIndex,
                                                                    i - 1)

                if self.channel is not None and partClip.enabled:
                    self.set_button_color_by_channel(i)
                else:
                    self.set_button_color(i, self.led_color_inactive)

                continue

            # Light up 1-5 buttons when respective channel is selected
            # If self.zyngui.channelsModActive is true, light up 1-5 HW button when channels 6-10 is selected
            channelDelta = 5 if self.zyngui.channelsModActive else 0
            if self.zyngui.session_dashboard.selectedChannel - channelDelta == i-1:
                self.set_button_color_by_channel(i)
            else:
                self.set_button_color(i, self.led_color_inactive)

        # 6: * Button
        if not self.zyngui.leftSidebarActive and self.zyngui.channelsModActive:
            self.set_button_color_by_channel(6)
        else:
            self.set_button_color(6, self.led_color_inactive)

        # 7 : Mode Button
        if self.zyngui.leftSidebarActive:
            self.set_button_color_by_channel(7)
        else:
            self.set_button_color(7, self.led_color_inactive)

        # Under screen button 1
        if self.zyngui.current_screen_id == "sketchpad":
            self.set_button_color(8, self.led_color_active)
        else:
            self.set_button_color(8, self.led_color_inactive)

        # Under screen button 2
        if self.zyngui.current_screen_id == "playgrid":
            self.set_button_color(9, self.led_color_active)
        else:
            self.set_button_color(9, self.led_color_inactive)

        # Under screen button 3
        if self.zyngui.current_screen_id == "song_manager":
            self.set_button_color(10, self.led_color_active)
        else:
            self.set_button_color(10, self.led_color_inactive)

        # Under screen button 4
        if self.zyngui.current_screen_id in ["layers_for_channel", "bank", "preset"]:
            self.set_button_color(11, self.led_color_active)
        else:
            self.set_button_color(11, self.led_color_inactive)

        # Under screen button 5
        if self.zyngui.current_screen_id == "control" or self.zyngui.current_screen_id in ["channel_wave_editor", "channel_external_setup"]:
            self.set_button_color(12, self.led_color_active)
        else:
            self.set_button_color(12, self.led_color_inactive)

        # ALT button
        self.set_button_color(13, self.led_color_inactive)

        # Recording Button
        if not self.zyngui.sketchpad.isRecording:
            self.set_button_color(14, self.led_color_inactive)
        else:
            self.set_button_color(14, self.led_color_red)

        # Play button
        if self.zyngui.sketchpad.isMetronomeRunning:
            self.set_button_color(15, self.led_color_active)
        else:
            self.set_button_color(15, self.led_color_inactive)

        # Save button
        if self.zyngui.sketchpad.clickChannelEnabled:
            if self.zyngui.sketchpad.isMetronomeRunning:
                self.set_button_color(16, self.led_color_inactive, True)
            else:
                self.set_button_color(16, self.led_color_inactive)
        else:
            self.set_button_color(16, self.led_color_off)

        # Stop button
        self.set_button_color(17, self.led_color_inactive)

        # Back/No button
        self.set_button_color(18, self.led_color_red)

        # Up button
        self.set_button_color(19, self.led_color_inactive)

        # Select/Yes button
        self.set_button_color(20, self.led_color_green)

        # Left Button
        self.set_button_color(21, self.led_color_inactive)

        # Bottom Button
        self.set_button_color(22, self.led_color_inactive)

        # Right Button
        self.set_button_color(23, self.led_color_inactive)

        # Master Button
        if self.zyngui.globalPopupOpened:
            self.set_button_color(24, self.led_color_active)
        else:
            self.set_button_color(24, self.led_color_inactive)
