#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian GUI Confirm Class
# 
# Copyright (C) 2021 MArco Martin <mart@kde.org>
#
#******************************************************************************
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
#******************************************************************************

# Qt modules
import numpy as np
from PySide2.QtCore import Qt, QObject, Slot, Signal, Property

import alsaaudio
import logging
import re

#------------------------------------------------------------------------------
# Base QObject wrapper for alsaaudio import
#------------------------------------------------------------------------------
from zynqtgui import zynthian_gui_config


class zynthian_gui_master_alsa_mixer(QObject):
    def __init__(self, parent=None):
        super(zynthian_gui_master_alsa_mixer, self).__init__(parent)
        self.audio_device = ""
        self.zyngui = zynthian_gui_config.zyngui

        # Read jack2.service file to find selected card name
        with open("/etc/systemd/system/jack2.service", "r") as f:
            data = f.read()

            # Get jackd command line args
            args = re.search("\nExecStart=(.*)", data).group(1).split(" ")

            # Discard everything before first occurrence of -d
            while args.pop(0) != "-d":
                continue

            # Find next -d or -P
            while True:
                option = args.pop(0)
                if option == "-d" or option == "-P":
                    raw_dev = args.pop(0)
                    self.audio_device = re.search("hw:([^ ]*)", raw_dev).group(1)
                    break

        logging.debug(f"### ALSA Mixer card : {self.audio_device}")

        try:
            accepted_mixer_names = ["Master", "Headphone", "HDMI", "Digital"];
            card = alsaaudio.cards().index(self.audio_device)
            for mixer_name in alsaaudio.mixers(card):
                if mixer_name in accepted_mixer_names:
                    self.__mixer = alsaaudio.Mixer(mixer_name, 0, card)
                    self.set_volume(65)
                    break
            logging.debug(f"Using the mixer named {self.__mixer.mixer()}")
        except Exception as e:
            self.__mixer = None
            logging.error(e)

    @Signal
    def volume_changed(self):
        pass

    def get_volume(self):
        # FIXME : pyalsaaudio wrongly interpolates percentage value to dB value and causes audio to be not hearable
        #         at 40%. Hence interpolate value from alsamixer(from 40 to 100) to 0 to 100 so that 40%
        #         in alsamixer will mean 0% in UI
        if self.__mixer is None:
            return 0
        vol = self.__mixer.getvolume()
        if len(vol) == 0:
            return 0
        return int(np.interp(vol[0], (40, 100), (0, 100)))

    def set_volume(self, vol: int):
        logging.debug("SETTING VOLUME TO{}".format(vol))
        if self.__mixer is None:
            return

        if vol == 0:
            # If input volume is 0, force set alsa mixer value to 0 instead of interpolating
            self.__mixer.setvolume(0)
        else:
            # FIXME : pyalsaaudio wrongly interpolates percentage value to dB value and causes audio to be not hearable
            #         at 40%. Hence interpolate percentage value from UI(from 0 to 100) to 40 to 100 so that 0% in UI
            #         will mean 40% for alsamixer
            self.__mixer.setvolume(int(np.interp(vol, (0, 100), (40, 100))))


        # Call zyngui global set_selector when volume changes as
        # volume is controlled by Small Knob 1 when global popup is opened
        self.zyngui.set_selector()

        self.volume_changed.emit()

    volume = Property(int, get_volume, set_volume, notify = volume_changed)

#-------------------------------------------------------------------------------
