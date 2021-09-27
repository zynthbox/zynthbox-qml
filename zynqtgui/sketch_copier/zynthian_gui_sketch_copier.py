#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthian Arranger: A page to copy tracks between sketches in a session
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
from pathlib import Path

from PySide2.QtCore import Property, Signal, Slot

from .. import zynthian_qt_gui_base
from ..zynthiloops.libzl.zynthiloops_song import zynthiloops_song


class zynthian_gui_sketch_copier(zynthian_qt_gui_base.ZynGui):
    def __init__(self, parent=None):
        super(zynthian_gui_sketch_copier, self).__init__(parent)
        self.__sketches__ = {}

        self.generate_sketches_from_session(True)

    ### Property sketches
    def get_sketches(self):
        return self.__sketches__
    sketches_changed = Signal()
    sketches = Property('QVariantMap', get_sketches, notify=sketches_changed)
    ### END Property sketches

    @Slot(None)
    def generate_sketches_from_session(self, connect_to_signal=False):
        logging.error("### Generating sketches from session")

        if connect_to_signal:
            self.zyngui.session_dashboard.sketches_changed.connect(self.generate_sketches_from_session)

        for slot in self.zyngui.session_dashboard.sketches:
            sketch = self.zyngui.session_dashboard.sketches[slot]
            logging.error(f"Loading sketch from slot[{slot}] : {sketch}")

            for file in Path(sketch).glob("**/*.json"):
                if file.name != "sketch.json":
                    self.__sketches__[slot] = zynthiloops_song(sketch + "/", file.name.replace(".json", ""), self.zyngui.zynthiloops)
                    break

        self.sketches_changed.emit()
