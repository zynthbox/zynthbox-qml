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
        self.zynqtgui = zynthian_gui_config.zynqtgui
        self.__parameterName = ""
        self.__description = ""
        self.__start = 0
        self.__stop = 0
        self.__step = 0
        self.__defaultValue = 0
        self.__value = 0
        self.__setValueFunction = None
        self.__startLabel = ""
        self.__stopLabel = ""
        self.__visualZero = 0
        self.__valueLabel = ""
        self.__showValueLabel = True
        self.__showResetToDefault = True
        self.__showVisualZero = True

    def updateOsd(self, parameterName, description, start, stop, step, defaultValue, currentValue, setValueFunction, startLabel = "", stopLabel = "", valueLabel = "", showValueLabel = True, visualZero = None, showResetToDefault = True, showVisualZero = True):
        self.__parameterName = parameterName
        self.__description = description
        self.__start = start
        self.__stop = stop
        self.__step = step
        self.__defaultValue = defaultValue
        self.__value = currentValue
        self.__setValueFunction = setValueFunction
        self.__startLabel = startLabel
        self.__stopLabel = stopLabel
        self.__valueLabel = valueLabel
        self.__showValueLabel = showValueLabel
        self.__showResetToDefault = showResetToDefault
        self.__showVisualZero = showVisualZero
        if visualZero is None:
            self.__visualZero = start
        else:
            self.__visualZero = visualZero
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
    def start(self):
        return self.__start

    @Property(float, notify=update)
    def stop(self):
        return self.__stop

    @Property(float, notify=update)
    def step(self):
        return self.__step

    @Property(float, notify=update)
    def defaultValue(self):
        return self.__defaultValue

    @Property(float, notify=update)
    def value(self):
        return self.__value

    @Property(str, notify=update)
    def startLabel(self):
        return self.__startLabel

    @Property(str, notify=update)
    def stopLabel(self):
        return self.__stopLabel

    @Property(str, notify=update)
    def valueLabel(self):
        if self.__valueLabel is not None and len(self.__valueLabel) > 0:
            return self.__valueLabel
        else:
            return str(round(self.__value, 3))

    @Property(bool, notify=update)
    def showValueLabel(self):
        return self.__showValueLabel

    @Property(bool, notify=update)
    def showResetToDefault(self):
        return self.__showResetToDefault

    @Property(bool, notify=update)
    def showVisualZero(self):
        return self.__showVisualZero

    @Property(float, notify=update)
    def visualZero(self):
        return self.__visualZero

    @Slot(str, float)
    def setValue(self, parameterName, newValue):
        if self.__parameterName == parameterName and self.__setValueFunction is not None:
            self.__setValueFunction(newValue);
