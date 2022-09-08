#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian Test Touchpoints: A Test page to test multi
# 
# Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
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

from . import zynthian_qt_gui_base

from zyngine import zynthian_controller
from . import zynthian_gui_config
from . import zynthian_gui_controller

# Qt modules
from PySide2.QtCore import Qt, QObject, Slot, Signal, Property

class zynthian_gui_test_knobs(zynthian_qt_gui_base.ZynGui):
    def __init__(self, parent = None):
        super(zynthian_gui_test_knobs, self).__init__(parent)

        self.__zselector = [None, None, None, None]
        self.__zselector_ctrl = [None, None, None, None]

    def show(self):
        self.set_selector()

    def zyncoder_read(self):
        pass

    def refresh_loading(self):
        pass

    def set_selector(self, zs_hiden=True):
        for i in range(4):
            if self.__zselector[i] is not None:
                if not (self.zyngui.globalPopupOpened or self.zyngui.metronomeButtonPressed) and \
                        self.zyngui.get_current_screen_id() is not None and \
                        self.zyngui.get_current_screen() == self:
                    self.__zselector[i].show()
                else:
                    self.__zselector[i].hide()

            if self.__zselector[i]:
                self.__zselector_ctrl[i].set_options(
                    {'symbol': 'test knob {}'.format(i), 'name': 'Test Knob {}'.format(i),
                     'short_name': 'Knob{}'.format(i), 'midi_cc': 0,
                     'value_max': 100,
                     'value': 0})
                self.__zselector[i].config(self.__zselector_ctrl[i])
            elif not (self.zyngui.globalPopupOpened or self.zyngui.metronomeButtonPressed) and \
                    self.zyngui.get_current_screen_id() is not None and \
                    self.zyngui.get_current_screen() == self:
                self.__zselector_ctrl[i] = zynthian_controller(None, 'test knob {}'.format(i), 'test knob {}'.format(i),
                                                               {'midi_cc': 0, 'value': 0, 'value_max': 100})
                self.__zselector[i] = zynthian_gui_controller(i, self.__zselector_ctrl[i], self)
                self.__zselector[i].show()

    def zyncoder_read(self):
        for i in range(4):
            self.__zselector[i].read_zyncoder()
        return [0, 1, 2, 3]

    @Property(QObject, constant=True)
    def controller0(self):
        return self.__zselector[0]

    @Property(QObject, constant=True)
    def controller1(self):
        return self.__zselector[1]

    @Property(QObject, constant=True)
    def controller2(self):
        return self.__zselector[2]

    @Property(QObject, constant=True)
    def controller3(self):
        return self.__zselector[3]

