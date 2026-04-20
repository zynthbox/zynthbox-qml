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

import board
import sys
import time
import logging
from neopixel_spi import NeoPixel_SPI, GRB
from configparser import ConfigParser

from PySide2.QtCore import Slot
from PySide2.QtGui import QColor


# Try reading ledBrightness from config and set a fallback value
try:
    config = ConfigParser()
    config.read("/root/.config/zynthbox/zynthbox-qml.conf")
    ledBrightness = config["UI"]["ledBrightness"] / 100
except:
    ledBrightness = 15 / 100
led_color_off = (0, 0, 0)
led_color_inactive = (0, 0, 1 * ledBrightness)

num_leds = 36
spi_freq = 6400000
wsleds = None


def init_wsleds():
    global wsleds, num_leds, spi_freq
    if wsleds is None:
        wsleds = NeoPixel_SPI(board.SPI(), num_leds, pixel_order=GRB, auto_write=False, frequency=spi_freq)


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
            for i in range(num_leds):
                color = QColor.fromHsl((rainbow_led_counter + i * 10) % 359, 242, 127, 127)
                wsleds[i] = (int(color.red() * ledBrightness), int(color.green() * ledBrightness), int(color.blue() * ledBrightness))
            wsleds.show()
            rainbow_led_counter += 3
            rainbow_led_counter = rainbow_led_counter % 359
            time.sleep(0.05)
    elif sys.argv[1] == "on":
        # Turn on all leds with blue color
        for i in range(num_leds):
            wsleds[i] = led_color_inactive
        wsleds.show()
        sys.exit(0)
    elif sys.argv[1] == "off":
        # Turn off all leds
        for i in range(num_leds):
            wsleds[i] = led_color_off
        wsleds.show()
        sys.exit(0)
    else:
        print_help()
        sys.exit(1)


########################################################################################################################
# END Standalone script to set led colors
########################################################################################################################


from . import zynthian_qt_gui_base
from . import zynthian_gui_config
from PySide2.QtGui import QColor
import Zynthbox

class zynthian_gui_led_config(zynthian_qt_gui_base.zynqtgui):
    def __init__(self, parent=None):
        super(zynthian_gui_led_config, self).__init__(parent)
        self.__blinkingButtons = {}
        # self.zynqtgui.ui_settings.ledBrightness ranges from 1-100. Normalize value to be in range 0.0-1.0
        self.__ledBrightness = self.zynqtgui.ui_settings.ledBrightness / 100
        init_wsleds()
        Zynthbox.PlayGridManager.instance().metronomeBeat128thChanged.connect(self.metronomeBeatUpdate128thHandler)
        self.zynqtgui.ui_settings.ledBrightnessChanged.connect(self.updateLedBrightness)

    def show(self):
        pass

    def zyncoder_read(self):
        pass

    def refresh_loading(self):
        pass

    @Slot()
    def updateLedBrightness(self):
        self.__ledBrightness = self.zynqtgui.ui_settings.ledBrightness / 100

    """
    A method to set a button to blink with a base color..
    The button will blink on every beat when the metronome is running.
    The base color will be used when the button is not blinking.

    @param buttonId: The ID of the button to set blinking. See ZynthboxBasics.buttonId for reference.
    @param baseColor: The base color of the button when it is not blinking
    @param enableBlinking: A boolean value to enable or disable blinking
    """
    @Slot(int, QColor, bool)
    def setButtonBlink(self, buttonId, baseColor, enableBlinking):
        if enableBlinking:
            self.__blinkingButtons[buttonId] = baseColor
        else:
            del self.__blinkingButtons[buttonId]

    @Slot()
    def metronomeBeatUpdate128thHandler(self, subBeat):
        if self.zynqtgui.sketchpad.isMetronomeRunning:
            if (subBeat % 32) == 0:
                # Blinkon on every beat
                for buttonId, _ in self.__blinkingButtons.items():
                    wsleds[buttonId] = (255 * self.__ledBrightness, 255 * self.__ledBrightness, 255 * self.__ledBrightness)
            elif (subBeat % 32) == 4:
                # Blink off after every 4 subBeats
                for buttonId, color in self.__blinkingButtons.items():
                    wsleds[buttonId] = (int(color.red() * self.__ledBrightness), int(color.green() * self.__ledBrightness), int(color.blue() * self.__ledBrightness))
            wsleds.show()

    """
    Slot to update led colors based on the provided ledColors map and brightness value.
    The ledColors map should have button IDs as keys and QColor objects as values.
    """
    @Slot("QVariantMap")
    def updateLedColors(self, ledColors = {}):
        for buttonId, color in ledColors.items():
            id = int(buttonId)
            if not self.zynqtgui.sketchpad.isMetronomeRunning or (self.zynqtgui.sketchpad.isMetronomeRunning and id not in self.__blinkingButtons):
                # Blinking buttons will be managed by the metronomeBeatUpdate128thHandler when metronome is running. Do not override the blinking button colors
                wsleds[id] = (int(color.red() * self.__ledBrightness), int(color.green() * self.__ledBrightness), int(color.blue() * self.__ledBrightness))

        if self.zynqtgui.isBootingComplete:
            wsleds.show()
