#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian Qt GUI Base Class: Base qtobject all gui logic uses
# 
# Copyright (C) 2021 Marco Martin <mart@kde.org>
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

import logging

# Zynthian specific modules
from . import zynthian_gui_config
from . import zynthian_gui_controller
from zyngine import zynthian_controller

# Qt modules
from PySide2.QtCore import QObject, Slot, Signal, Property, QMetaObject, Qt, QTimer

class zynqtgui(QObject):
    def __init__(self, parent=None):
        super(zynqtgui, self).__init__(parent)
        self.zynqtgui = zynthian_gui_config.zynqtgui
        self.select_path = ""
        self.shown = True
        self.__zselector = [None, None, None, None]
        self.__zselector_ctrl = [None, None, None, None]
        self.__bigknob_value = 10000
        self.__deltaKnobUpdates = False

        # Setup timers to reset knob zyncoder values
        # If value is reset immediately after reading then due to loss of precison when setting value,
        # decerasing happens faster than increasing which causes knobs to not work as expected
        # So instead of resetting on every read, set a timer to reset after 2 seconds of idle time
        self.__bigknob_reset_timer = QTimer(self)
        self.__bigknob_reset_timer.setSingleShot(True)
        self.__bigknob_reset_timer.setInterval(2000)
        self.__bigknob_reset_timer.timeout.connect(self.reset_bigknob)

    def show(self):        
        self.set_selector()

    def refresh_loading(self):
        pass

    def set_select_path(self):
        pass

    def refresh_status(self, status={}):
        pass

    def reset_bigknob(self):
        self.__zselector[0].set_value(10000, True)
        self.__bigknob_value = 10000

    @Slot()
    def zyncoder_bigknob(self):
        if self.__bigknob_value != self.__zselector[0].value:
            new_val = self.__zselector[0].value
            self.bigKnobDelta.emit(new_val - self.__bigknob_value)
            self.__bigknob_value = new_val
            self.__bigknob_reset_timer.start()

    def zyncoder_read(self):
        if self.is_set_selector_running or not self.deltaKnobUpdates:
            return

        if self.__zselector[0]:
            self.__zselector[0].read_zyncoder()
            QMetaObject.invokeMethod(self, "zyncoder_bigknob", Qt.QueuedConnection)

        return []

    def configure_big_knob(self):
        try:
            if self.__zselector[0] is None:
                self.__zselector_ctrl[0] = zynthian_controller(None, 'delta_bigknob', 'delta_bigknob', {'name': 'Big Knob Delta', 'short_name': 'Bigknob Delta', 'midi_cc': 0, 'value_max': 20000, 'value_min': 0, 'value': 10000})
                self.__zselector[0] = zynthian_gui_controller(3, self.__zselector_ctrl[0], self)
                self.__zselector[0].config(self.__zselector_ctrl[0])
                self.__zselector[0].step = 1
                self.__zselector[0].mult = 1
                self.__zselector[0].set_value(10000, True)

            self.__zselector[0].show()
            self.__zselector_ctrl[0].set_options({"value": 10000})
            self.__zselector[0].config(self.__zselector_ctrl[0])
        except:
            if self.__zselector[0] is not None:
                self.__zselector[0].hide()

    @Slot(None)
    def set_selector(self, zs_hiden=False):
        if (self.zynqtgui.globalPopupOpened or self.zynqtgui.metronomeButtonPressed or self.zynqtgui.altButtonPressed) or \
                (self.zynqtgui.get_current_screen_id() is not None and self.zynqtgui.get_current_screen() != self) or \
                not self.deltaKnobUpdates:
            if self.__zselector[0] is not None:
                self.__zselector[0].hide()

            return

        self.is_set_selector_running = True
#        self.configure_big_knob()
        self.is_set_selector_running = False

    ### Begin property deltaKnobUpdates
    def get_deltaKnobUpdates(self):
        return self.__deltaKnobUpdates

    def set_deltaKnobUpdates(self, val):
        if self.__deltaKnobUpdates != val:
            self.__deltaKnobUpdates = val
            self.set_selector()
            self.deltaKnobUpdatesChanged.emit()

    deltaKnobUpdatesChanged = Signal()

    deltaKnobUpdates = Property(int, get_deltaKnobUpdates, set_deltaKnobUpdates, notify=deltaKnobUpdatesChanged)
    ### End property deltaKnobUpdates

    bigKnobDelta = Signal(int)

#------------------------------------------------------------------------------
