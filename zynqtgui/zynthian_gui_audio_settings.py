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
from PySide2.QtCore import Property

from . import zynthian_qt_gui_base


class zynthian_gui_audio_settings(zynthian_qt_gui_base.ZynGui):
    def __init__(self, parent=None):
        super(zynthian_gui_audio_settings, self).__init__(parent)

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
        _channels = []
        for port in jack.Client('').get_ports("system:capture"):
            _channels.append(port.name.replace("system:", ""))

        return _channels
    channels = Property('QVariantList', get_channels, constant=True)
    ### END Property channels