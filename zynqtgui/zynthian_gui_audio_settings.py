#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthian Audio Settings : A page to display channels of selected audio device
#                           and monitor audio level of respective channels
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
import os

import jack
from PySide2.QtCore import Property,Signal,Slot

import logging
import re
import zyngine
from . import zynthian_qt_gui_base,zynthian_gui_master_alsa_mixer

class zynthian_gui_audio_settings(zynthian_qt_gui_base.ZynGui):
    def __init__(self, parent=None):
        super(zynthian_gui_audio_settings, self).__init__(parent)
        try:
            scmix = os.environ.get('SOUNDCARD_MIXER',"").replace("\\n","")
            self.ctrl_list = [item.strip() for item in scmix.split(',')]
        except:
            self.ctrl_list = None
        self.audio_device = ""

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
        soundcard_name = self.audio_device
        self.zynthian_mixer = zyngine.zynthian_engine_mixer()

        if self.audio_device == "Headphones":
            self.zctrls = self.zynthian_mixer.get_mixer_zctrls(device_name=soundcard_name, ctrl_list=["Headphone", "PCM"])
        else:
            self.zctrls = self.zynthian_mixer.get_mixer_zctrls(device_name=soundcard_name, ctrl_list=self.ctrl_list)

        self.update_channels()

    def show(self):
        pass

    def zyncoder_read(self):
        pass

    def refresh_loading(self):
        pass

    ### Property soundcardName
    def get_soundcard_name(self):
        return os.environ.get("SOUNDCARD_NAME", "Unknown")
    soundcardName = Property(str, get_soundcard_name, constant=True)
    ### END Property soundcardName

    ### Property channels
    def get_channels(self):
        return self._channels

    @Signal
    def channels_changed(self):
        pass

    def update_channels(self):
        self._channels = []
        for key,zctrl in self.zctrls.items():
            self._channels.append({
                "name": key,
                "value": zctrl.value,
                "value_min": zctrl.value_min,
                "value_max": zctrl.value_max
            })
        self.channels_changed.emit()

    channels = Property('QVariantList', get_channels, notify=channels_changed)
    ### END Property channels

    @Slot(str, int)
    def setChannelValue(self, channel_index, new_value):
        if channel_index in self.zctrls:
            if self.zctrls[channel_index].get_value() != new_value:
                self.zctrls[channel_index].set_value(new_value)
                self.channels_changed.emit()
