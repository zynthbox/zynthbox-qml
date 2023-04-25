#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# A proxy controller for controlling multiple zynthian_controller objects
#
# This provides an abstraction to control all added controllers by percentage.
# Setting value of this controller will interpolate the value to the respective
# controller value and set it accordingly
#
# Copyright (C) 2021 Marco Martin <mart@kde.org>
# Copyright (C) 2023 Anupam Basak <anupam.basak27@gmail.com>
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


import numpy as np
from PySide2.QtCore import Property, QObject, Signal


class MultiController(QObject):
    def __init__(self, name, parent=None):
        super(MultiController, self).__init__(parent)
        self.__controls = []
        self.__value = 0
        self.__value_min = 0
        self.__value_max = 100
        self.__step_size = 1
        self.__name = name

    def add_control(self, control):
        if control not in self.__controls:
            self.__controls.append(control)
            # Interpolate controller's value to percentage
            controller_current_interp_value = np.interp(control.value, (control.value_min, control.value_max), (self.value_min, self.value_max))
            if controller_current_interp_value < self.value:
                # Current controller's value is less than set value
                # force set value to update current controllers value
                self.set_value(self.value, True)
            else:
                # Current controller's value is greater than set value
                # update value to current controller
                self.set_value(controller_current_interp_value, True)

            self.controlsCountChanged.emit()
            self.controllable_changed.emit()
            self.value_changed.emit()

    def clear_controls(self):
        self.__controls.clear()
        self.controlsCountChanged.emit()
        self.value = 0

    ### Property controllable
    def get_controllable(self):
        return len(self.__controls) > 0

    controllable_changed = Signal()

    controllable = Property(bool, get_controllable, notify=controllable_changed)
    ### END Property controllable

    ### Property value
    def get_value(self):
        return self.__value

    def set_value(self, value_percent: int, force_set=False):
        value = int(np.clip(value_percent, 0, 100))

        if self.__value != value or force_set is True:
            self.__value = value

            for control in self.__controls:
                # Interpolate volume percentage to controller's value range
                control.set_value(np.interp(value, (self.value_min, self.value_max), (control.value_min, control.value_max)), True)

            self.value_changed.emit()

    value_changed = Signal()

    value = Property(int, get_value, set_value, notify=value_changed)
    ### END Property value

    ### Property value_min
    def get_value_min(self):
        return self.__value_min

    value_min = Property(int, get_value_min, constant=True)
    ### END Property value_min

    ### Property value_max
    def get_value_max(self):
        return self.__value_max

    value_max = Property(int, get_value_max, constant=True)
    ### END Property value_max

    ### Property step_size
    def get_step_size(self):
        return self.__step_size

    step_size = Property(int, get_step_size, constant=True)
    ### END Property step_size

    ### Property name
    def get_name(self):
        return self.__name

    name = Property(str, get_name, constant=True)
    ### END Property step_size

    ### Property controlsCount
    def get_controlsCount(self):
        return len(self.__controls)

    controlsCountChanged = Signal()

    controlsCount = Property(int, get_controlsCount, notify=controlsCountChanged)
    ### END Property controlsCount

