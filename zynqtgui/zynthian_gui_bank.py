#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian GUI Bank Selector Class
# 
# Copyright (C) 2015-2016 Fernando Moyano <jofemodo@zynthian.org>
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

import sys
import logging
from functools import cmp_to_key

# Zynthian specific modules
from . import zynthian_gui_config
from . import zynthian_gui_selector

# Qt modules
from PySide2.QtCore import Qt, QObject, Slot, Signal, Property, QTimer

#------------------------------------------------------------------------------
# Zynthian Bank Selection GUI Class
#------------------------------------------------------------------------------

def customSort(item1, item2):
    if item1[2].upper() > item2[2].upper():
        return 1
    elif item1[2].upper() == item2[2].upper():
        return 0
    else:
        return -1

class zynthian_gui_bank(zynthian_gui_selector):

    buttonbar_config = [
        (1, 'BACK'),
        (0, 'LAYER'),
        (2, 'FAVS'),
        (3, 'SELECT')
    ]

    def __init__(self, parent = None):
        super(zynthian_gui_bank, self).__init__('Bank', parent)
        self.__show_top_sounds = False
        self.auto_next_screen = False
        self.__list_data_cache = {}
        self.show()

    """
    Return appripriate curlayer as per opened effect screen
    """
    def get_curlayer(self):
        try:
            if self.zynqtgui.current_screen_id in ["effects_for_channel", "effect_preset"]:
                return self.zynqtgui.effects_for_channel.list_data[self.zynqtgui.effects_for_channel.current_index][3]
            elif self.zynqtgui.current_screen_id in ["sketch_effects_for_channel", "sketch_effect_preset"]:
                return self.zynqtgui.sketch_effects_for_channel.list_data[self.zynqtgui.sketch_effects_for_channel.current_index][3]
            else:
                # return self.zynqtgui.layers_for_channel.list_metadata[self.zynqtgui.layers_for_channel.current_index]["layer"]
                return self.zynqtgui.curlayer
        except:
            # In case any of the above dependent properties are unavailable and causes reference errors, return None.
            return None

    def fill_list(self):
        self.list_data = []

        if not self.get_curlayer():
            logging.debug("Can't fill bank list for None layer!")
            super().fill_list()
            return

        if self.__show_top_sounds:
            self.zynqtgui.screens['preset'].reload_top_sounds()
            top_sounds = self.zynqtgui.screens['preset'].get_all_top_sounds()
            for engine in top_sounds:
                parts = engine.split("/")
                readable_name = engine
                if len(parts) > 1:
                    readable_name = parts[1]
                if len(top_sounds[engine]) > 0:
                    self.list_data.append((engine, len(self.list_data), "{} ({})".format(readable_name, len(top_sounds[engine]))))
            self.list_data = sorted(self.list_data, key=cmp_to_key(customSort))
        else:
            self.get_curlayer().load_bank_list()
            self.list_data = self.get_curlayer().bank_list

        self.zynqtgui.screens['preset'].set_select_path()
        super().fill_list()

    def get_show_top_sounds(self):
        return self.__show_top_sounds

    def set_show_top_sounds(self, show : bool):
        if self.__show_top_sounds == show:
            return
        self.__show_top_sounds = show
        self.fill_list()
        self.show()
        if show and self.get_curlayer():
            top_sounds = self.zynqtgui.screens['preset'].get_all_top_sounds()
            self.select_action(0)
            self.zynqtgui.screens['preset'].select(0)
        elif self.get_curlayer():
            self.zynqtgui.screens['preset'].set_top_sounds_engine(None)
            self.zynqtgui.screens['bank'].show()
            self.zynqtgui.screens['preset'].show()
        else:
            self.zynqtgui.screens['preset'].set_top_sounds_engine(None)
            self.zynqtgui.screens['preset'].fill_list()

        self.show_top_sounds_changed.emit()

    def show(self):
        if self.__show_top_sounds: #don't support autosync when top sounds is enabled
            super().show()
            return
        if not self.get_curlayer():
            logging.debug("Can't show bank list for None layer!")
            super().show()
            return
        if self.get_curlayer().get_bank_name() is None:
            self.get_curlayer().set_bank(0)
        if self.zynqtgui.screens['preset'].get_show_only_favorites():
            self.select(0)
        elif self.get_curlayer() != None:
            for i in range(len(self.get_curlayer().bank_list)):
                if self.get_curlayer().bank_name == self.get_curlayer().bank_list[i][2]:
                    self.get_curlayer().bank_index = i
                    break
            self.select(self.get_curlayer().get_bank_index())
        # logging.debug("BANK INDEX => %s" % self.index)
        super().show()


    def select_action(self, i, t='S'):
        self.select(i)
        if i < 0 or i >= len(self.list_data):
            return
        if self.__show_top_sounds:
            self.zynqtgui.screens['preset'].set_top_sounds_engine(self.list_data[i][0])
            if self.get_curlayer() != None and self.get_curlayer().engine.nickname == self.list_data[i][0]:
                self.zynqtgui.screens['preset'].select_action(0) #TODO Enable /disable whether is wanted to switch on touch
                self.select(i)
                self.zynqtgui.screens['preset'].select(0)
            else:
                self.zynqtgui.screens['preset'].select(0)
            self.zynqtgui.show_screen("bank")
            self.set_select_path()
            return
        else:
            self.zynqtgui.screens['preset'].set_top_sounds_engine(None)

        if self.list_data[i][0]=='*FAVS*':
            self.zynqtgui.screens['preset'].set_show_only_favorites(True)
        else:
            self.zynqtgui.screens['preset'].set_show_only_favorites(False)

        if self.get_curlayer().set_bank(i):
            #self.zynqtgui.screens['preset'].disable_only_favs()
            self.zynqtgui.screens['preset'].fill_list()
            if self.auto_next_screen:
                self.next_action
            else:
                self.zynqtgui.screens['preset'].show() #FIXME: this show should be renamed in "load" or some similar name
            # If there is only one preset, jump to instrument control
            if len(self.get_curlayer().preset_list)<=1:
                self.zynqtgui.screens['preset'].select_action(0)
            self.zynqtgui.screens['layer'].fill_list()
        else:
            self.show()
        self.set_select_path()

    def next_action(self):
        return "preset"

    def back_action(self):
        return "sketchpad"

    def index_supports_immediate_activation(self, index=None):
        return True

    def set_select_path(self):
        if self.get_curlayer():
            self.select_path = self.get_curlayer().get_basepath()
            parts = str(self.get_curlayer().engine.name).split("/")
            if (len(parts) > 1):
                self.select_path_element = parts[1]
            else:
                self.select_path_element = self.get_curlayer().engine.name
        else:
            self.select_path_element = "Sounds"
            self.select_path = "Banks"
        super().set_select_path()


    show_top_sounds_changed = Signal()

    show_top_sounds = Property(bool, get_show_top_sounds, set_show_top_sounds, notify = show_top_sounds_changed)

#-------------------------------------------------------------------------------
