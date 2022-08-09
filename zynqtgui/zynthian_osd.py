#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthbox OSD: A class for interacting with the user through an OSD style popup
#
# Copyright (C) 2022 Dan Leinir Turthra Jensen <admin@leinir.dk>
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

from PySide2.QtCore import Property, QObject, Qt, Signal, Slot

from . import zynthian_gui_config

class zynthian_osd(QObject):
    def __init__(self, parent=None):
        super(zynthian_osd, self).__init__(parent)
        self.zyngui = zynthian_gui_config.zyngui
        self.__parameterName = ""
        self.__description = ""
        self.__minimum = 0
        self.__maximum = 0
        self.__step = 0
        self.__defaultValue = 0
        self.__value = 0
        self.__setValueFunction = None

    def updateOsd(self, parameterName, description, minimum, maximum, step, defaultValue, currentValue, setValueFunction):
        self.__parameterName = parameterName
        self.__description = description
        self.__minimum = minimum
        self.__maximum = maximum
        self.__step = step
        self.__value = currentValue
        self.__setValueFunction = setValueFunction
        self.__defaultValue = defaultValue
        self.update.emit(parameterName)

    # Signal to cause the OSD to show up and do things. The string passed to it is the name of the parameter being changed
    update = Signal(str)

    @Property(str, notify=update)
    def name(self):
        return self.__parameterName

    @Property(str, notify=update)
    def description(self):
        return self.__description;

    @Property(float, notify=update)
    def minimum(self):
        return self.__minimum

    @Property(float, notify=update)
    def maximum(self):
        return self.__maximum

    @Property(float, notify=update)
    def step(self):
        return self.__step

    @Property(float, notify=update)
    def defaultValue(self):
        return self.__defaultValue

    @Property(float, notify=update)
    def value(self):
        return self.__value

    @Slot(str, float)
    def setValue(self, parameterName, newValue):
        if self.__parameterName == parameterName and self.__setValueFunction is not None:
            self.__setValueFunction(newValue);
