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

import logging
import os
import rpi_ws281x
import sys
import time
import Zynthbox

from PySide2.QtCore import Property, QTimer, Signal, Slot
from PySide2.QtGui import QColor


darkening_factor=800

color_red = QColor.fromRgb(255, 0, 0).darker(darkening_factor)
color_green = QColor.fromRgb(0, 255, 0).darker(darkening_factor)
color_blue = QColor.fromRgb(0, 50, 200).darker(darkening_factor)

led_color_off = rpi_ws281x.Color(0, 0, 0)
led_color_red = rpi_ws281x.Color(color_red.red(), color_red.green(), color_red.blue())
led_color_green = rpi_ws281x.Color(color_green.red(), color_green.green(), color_green.blue())
led_color_blue = rpi_ws281x.Color(color_blue.red(), color_blue.green(), color_blue.blue())

led_color_inactive = led_color_blue
led_color_active = led_color_green

wsleds: rpi_ws281x.PixelStrip = None


def init_wsleds():
    global wsleds

    wiring_layout = os.environ.get('ZYNTHIAN_WIRING_LAYOUT', "DUMMIES")

    if wsleds is None:
        if wiring_layout=="Z2_V1":
            # LEDS with PWM1 (pin 13, channel 1)
            pin = 13
            chan = 1
        elif wiring_layout in ("Z2_V2", "Z2_V3"):
            # LEDS with SPI0 (pin 10, channel 0)
            pin = 10
            chan = 0
        else:
            return 0

        wsleds = rpi_ws281x.PixelStrip(25, pin, dma=10, channel=chan, strip_type=rpi_ws281x.ws.WS2811_STRIP_GRB)
        wsleds.begin()


########################################################################################################################
# Standalone script to set led colors
########################################################################################################################

if __name__ == "__main__":
    def print_help():
        print("ERROR : Invalid argument")
        print()
        print("Usage :")
        print(f"  {sys.argv[0]} <command>")
        print("  Commands :")
        print("    - rainbow : Display rainbow colors infinitely")
        print("    - on      : Set colors of all buttons to blue")
        print("    - off     : Set colors of all buttons to off")

    if len(sys.argv) <= 1:
        print_help()
        sys.exit(0)

    init_wsleds()

    if sys.argv[1] == "rainbow":
        # Display rainbow colors
        rainbow_led_counter = 0
        while True:
            for i in range(25):
                color = QColor.fromHsl((rainbow_led_counter + i * 10) % 359, 242, 127, 127).darker(darkening_factor)
                wsleds.setPixelColor(i, rpi_ws281x.Color(color.red(), color.green(), color.blue()))
            wsleds.show()
            rainbow_led_counter += 3
            rainbow_led_counter = rainbow_led_counter % 359
            time.sleep(0.05)
    elif sys.argv[1] == "on":
        # Turn on all leds with blue color
        for i in range(25):
            wsleds.setPixelColor(i, led_color_inactive)
        wsleds.show()
        sys.exit(0)
    elif sys.argv[1] == "off":
        # Turn off all leds
        for i in range(25):
            wsleds.setPixelColor(i, led_color_off)
        wsleds.show()
        sys.exit(0)
    else:
        print_help()
        sys.exit(1)


########################################################################################################################
# END Standalone script to set led colors
########################################################################################################################


from . import zynthian_qt_gui_base


class zynthian_gui_led_config(zynthian_qt_gui_base.zynqtgui):
    """
    A Helper class that sets correct led color per button as per current state

    To set a led color to a button :
    self.button_color_map[0] = {
        'color': <One of the led_color_*>,
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

        from . import zynthian_gui_config
        zynqtgui = zynthian_gui_config.zynqtgui

        channelTypeSynthColorDarkened = zynqtgui.sketchpad.channelTypeSynthColor.darker(darkening_factor)
        channelTypeSketchesColorDarkened = zynqtgui.sketchpad.channelTypeSketchesColor.darker(darkening_factor)
        channelTypeSamplesColorDarkened = zynqtgui.sketchpad.channelTypeSamplesColor.darker(darkening_factor)
        channelTypeExternalColorDarkened = zynqtgui.sketchpad.channelTypeExternalColor.darker(darkening_factor)

        self.led_color_channel_synth = rpi_ws281x.Color(channelTypeSynthColorDarkened.red(), channelTypeSynthColorDarkened.green(), channelTypeSynthColorDarkened.blue())
        self.led_color_channel_loop = rpi_ws281x.Color(channelTypeSketchesColorDarkened.red(), channelTypeSketchesColorDarkened.green(), channelTypeSketchesColorDarkened.blue())
        self.led_color_channel_sample = rpi_ws281x.Color(channelTypeSamplesColorDarkened.red(), channelTypeSamplesColorDarkened.green(), channelTypeSamplesColorDarkened.blue())
        self.led_color_channel_external = rpi_ws281x.Color(channelTypeExternalColorDarkened.red(), channelTypeExternalColorDarkened.green(), channelTypeExternalColorDarkened.blue())

        self.channel = None
        self.button_config = {}
        self.update_botton_colors_timer = QTimer()
        self.update_botton_colors_timer.setInterval(0)
        self.update_botton_colors_timer.setSingleShot(True)
        self.update_botton_colors_timer.timeout.connect(self.update_button_colors_actual)

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

        Zynthbox.PlayGridManager.instance().metronomeBeat128thChanged.connect(self.metronomeBeatUpdate128thHandler)

    @Slot()
    def metronomeBeatUpdate128thHandler(self, beat):
        if self.zynqtgui.sketchpad.isMetronomeRunning:
            if beat % 32 == 0:
                self.blinkOff()
            elif (beat - 8) % 32 == 0:
                self.blinkOn()
        else:
            self.blinkOn()

    @Slot()
    def blinkOff(self):
        for button_id, config in self.button_config.items():
            if config["blink"] is True:
                wsleds.setPixelColor(button_id, config['blinkColor'])

        wsleds.show()

    @Slot()
    def blinkOn(self):
        for button_id, config in self.button_config.items():
            if config["blink"] is True:
                wsleds.setPixelColor(button_id, config["color"])

        wsleds.show()

    def show(self):
        pass

    def zyncoder_read(self):
        pass

    def refresh_loading(self):
        pass

    def set_button_color(self, buttonId, color, setChannelColor=False, blink=False):
        buttonColor = None

        if setChannelColor:
            if self.channel.trackType == "synth":
                buttonColor = self.led_color_channel_synth
            elif self.channel.trackType in ["sample-trig", "sample-slice"]:
                buttonColor = self.led_color_channel_sample
            elif self.channel.trackType == "sample-loop":
                buttonColor = self.led_color_channel_loop
            elif self.channel.trackType == "external":
                buttonColor = self.led_color_channel_external
        else:
            assert color is not None, "color cannot be None when setChannelColor is False"

            buttonColor = color

        self.button_config[buttonId] = {
            'color': buttonColor,
            'blink': blink,
            'blinkColor': led_color_off
        }

        wsleds.setPixelColor(buttonId, buttonColor)

    def init(self):
        init_wsleds()

        # Initialise all button with inactive color and not blinking
        for i in range(25):
            self.set_button_color(i, led_color_inactive)

        wsleds.show()
        self.connect_dependent_property_signals()

    @Slot()
    def connect_dependent_property_signals(self):
        logging.debug("### Connecting dependant property signals")

        # Reset channel as it would change when song changes
        if self.zynqtgui.sketchpad.song is not None:
            self.channel = self.zynqtgui.sketchpad.song.channelsModel.getChannel(self.zynqtgui.sketchpad.selectedTrackId)

        # Connect to required signals for updating led
        self.zynqtgui.isExternalAppActiveChanged.connect(self.update_button_colors)
        self.zynqtgui.sketchpad.song_changed.connect(self.connect_dependent_property_signals)
        self.zynqtgui.sketchpad.selected_track_id_changed.connect(self.selected_track_id_changed_handler)
        self.zynqtgui.current_screen_id_changed.connect(self.update_button_colors)
        self.zynqtgui.current_modal_screen_id_changed.connect(self.update_button_colors)
        self.zynqtgui.leftSidebarActiveChanged.connect(self.update_button_colors)
        self.zynqtgui.channelsModActiveChanged.connect(self.update_button_colors)
        self.zynqtgui.sketchpad.isRecordingChanged.connect(self.update_button_colors)
        self.zynqtgui.sketchpad.isRecordingChanged.connect(self.update_button_colors)
        self.zynqtgui.sketchpad.metronome_running_changed.connect(self.update_button_colors)
        self.zynqtgui.sketchpad.metronomeEnabledChanged.connect(self.update_button_colors)
        self.zynqtgui.globalPopupOpenedChanged.connect(self.update_button_colors)

        for channel_id in range(self.zynqtgui.sketchpad.song.channelsModel.count):
            self.zynqtgui.sketchpad.song.channelsModel.getChannel(channel_id).track_type_changed.connect(
                self.update_button_colors)

        self.update_button_colors()

    @Slot()
    def selected_track_id_changed_handler(self):
        self.channel = self.zynqtgui.sketchpad.song.channelsModel.getChannel(self.zynqtgui.sketchpad.selectedTrackId)
        # Connect to part clips changed when channel changes
        self.channel.selectedPartNamesChanged.connect(self.update_button_colors)

        self.update_button_colors()

    @Slot()
    def update_button_colors(self):
        self.update_botton_colors_timer.start()

    @Slot()
    def update_button_colors_actual(self):
        logging.debug("Updating LEDs")

        if self.zynqtgui.sketchpad.song is not None and (self.channel is None or (self.channel is not None and self.channel.id != self.zynqtgui.sketchpad.selectedTrackId)):
            self.channel = self.zynqtgui.sketchpad.song.channelsModel.getChannel(self.zynqtgui.sketchpad.selectedTrackId)

        if self.channel is None:
            # Do not continue if channel is not yet instantiated
            return

        menu_page_active = self.zynqtgui.modal_screen is None and self.zynqtgui.active_screen == "main"
        sketchpad_page_active = self.zynqtgui.current_screen_id == "sketchpad"
        playgrid_page_active = self.zynqtgui.current_screen_id == "playgrid"
        song_manager_page_active = self.zynqtgui.current_screen_id == "song_manager"
        library_page_active = self.zynqtgui.current_screen_id in ["layers_for_channel", "bank", "preset"]
        edit_page_active = self.zynqtgui.current_screen_id == "control" or self.zynqtgui.current_screen_id in ["channel_wave_editor", "channel_external_setup"]

        # Light up 1-5 buttons when respective part clip is enabled when leftSidebar is active
        partClipEnabled = [
            self.zynqtgui.sketchpad.song.getClipByPart(self.channel.id, self.zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex, 0).enabled,
            self.zynqtgui.sketchpad.song.getClipByPart(self.channel.id, self.zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex, 1).enabled,
            self.zynqtgui.sketchpad.song.getClipByPart(self.channel.id, self.zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex, 2).enabled,
            self.zynqtgui.sketchpad.song.getClipByPart(self.channel.id, self.zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex, 3).enabled,
            self.zynqtgui.sketchpad.song.getClipByPart(self.channel.id, self.zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex, 4).enabled,
        ]
        # Light up 1-5 buttons when respective channel is selected when leftSidebar is not active
        channelDelta = 5 if self.zynqtgui.channelsModActive else 0
        selectedTrackIndex = self.zynqtgui.sketchpad.selectedTrackId - channelDelta

        if self.zynqtgui.isExternalAppActive:
            for button_id in range(0, 25):
                self.set_button_color(button_id, led_color_inactive)
        else:
            self.set_button_color(self.button_menu, led_color_active if menu_page_active else led_color_inactive)
            self.set_button_color(self.button_1, led_color_inactive, setChannelColor=partClipEnabled[0] if self.zynqtgui.leftSidebarActive else selectedTrackIndex == 0)
            self.set_button_color(self.button_2, led_color_inactive, setChannelColor=partClipEnabled[1] if self.zynqtgui.leftSidebarActive else selectedTrackIndex == 1)
            self.set_button_color(self.button_3, led_color_inactive, setChannelColor=partClipEnabled[2] if self.zynqtgui.leftSidebarActive else selectedTrackIndex == 2)
            self.set_button_color(self.button_4, led_color_inactive, setChannelColor=partClipEnabled[3] if self.zynqtgui.leftSidebarActive else selectedTrackIndex == 3)
            self.set_button_color(self.button_5, led_color_inactive, setChannelColor=partClipEnabled[4] if self.zynqtgui.leftSidebarActive else selectedTrackIndex == 4)
            self.set_button_color(self.button_star, led_color_inactive, setChannelColor=not self.zynqtgui.leftSidebarActive and self.zynqtgui.channelsModActive)
            self.set_button_color(self.button_mode, led_color_inactive, setChannelColor=self.zynqtgui.leftSidebarActive)
            self.set_button_color(self.button_under_screen_1, led_color_active if sketchpad_page_active else led_color_inactive)
            self.set_button_color(self.button_under_screen_2, led_color_active if playgrid_page_active else led_color_inactive)
            self.set_button_color(self.button_under_screen_3, led_color_active if song_manager_page_active else led_color_inactive)
            self.set_button_color(self.button_under_screen_4, led_color_active if library_page_active else led_color_inactive)
            self.set_button_color(self.button_under_screen_5, led_color_active if edit_page_active else led_color_inactive)
            self.set_button_color(self.button_alt, led_color_inactive)
            self.set_button_color(self.button_record, led_color_red if self.zynqtgui.sketchpad.isRecording else led_color_inactive)
            self.set_button_color(self.button_play, led_color_active if self.zynqtgui.sketchpad.isMetronomeRunning else led_color_inactive)
            self.set_button_color(self.button_metronome, led_color_inactive if self.zynqtgui.sketchpad.metronomeEnabled else led_color_off, blink=self.zynqtgui.sketchpad.metronomeEnabled)
            self.set_button_color(self.button_stop, led_color_inactive)
            self.set_button_color(self.button_back, led_color_red)
            self.set_button_color(self.button_up, led_color_inactive)
            self.set_button_color(self.button_select, led_color_active)
            self.set_button_color(self.button_left, led_color_inactive)
            self.set_button_color(self.button_down, led_color_inactive)
            self.set_button_color(self.button_right, led_color_inactive)
            self.set_button_color(self.button_global, led_color_active if self.zynqtgui.globalPopupOpened else led_color_inactive)

        wsleds.show()
