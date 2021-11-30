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
from PySide2.QtCore import Qt, QObject, Slot, Signal, Property

import alsaaudio
import logging
import re

#------------------------------------------------------------------------------
# Base QObject wrapper for alsaaudio import
#------------------------------------------------------------------------------

class zynthian_gui_master_alsa_mixer(QObject):
    def __init__(self, parent=None):
        super(zynthian_gui_master_alsa_mixer, self).__init__(parent)
        dev = ""

        # Read jack2.service file to find selected card name
        with open("/etc/systemd/system/jack2.service", "r") as f:
            data = f.read()

            # Get jackd command line args
            args = re.search("ExecStart=(.*)", data).group(1).split(" ")

            # Discard everything before first occurrence of -d
            while args.pop(0) != "-d":
                continue

            # Find next -d or -P
            while True:
                option = args.pop(0)
                if option == "-d" or option == "-P":
                    raw_dev = args.pop(0)
                    dev = re.search("hw:([^ ]*)", raw_dev).group(1)
                    break

        logging.error(f"### ALSA Mixer card : {dev}")

        try:
            card = alsaaudio.cards().index(dev)
            mixer_name = alsaaudio.mixers(card)[0]
            self.__mixer = alsaaudio.Mixer(mixer_name, 0, card)
        except Exception as e:
            self.__mixer = None
            logging.error(e)

    @Signal
    def volume_changed(self):
        pass

    def get_volume(self):
        if self.__mixer is None:
            return 0
        vol = self.__mixer.getvolume()
        if len(vol) == 0:
            return 0
        return vol[0]

    def set_volume(self, vol: int):
        logging.error("SETTING VOLUME TO{}".format(vol))
        if self.__mixer is None:
            return
        self.__mixer.setvolume(vol)
        self.volume_changed.emit()

    volume = Property(int, get_volume, set_volume, notify = volume_changed)

#-------------------------------------------------------------------------------
