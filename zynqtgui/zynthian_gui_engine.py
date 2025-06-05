#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian GUI Engine Selector Class
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

import logging
from time import sleep
from collections import OrderedDict
from functools import cmp_to_key

# Zynthian specific modules
from zyngine import *
from zyngine.zynthian_engine_jalv import zynthian_engine_jalv
from . import zynthian_gui_selector

from PySide2.QtCore import Signal, Property

#------------------------------------------------------------------------------
# Zynthian Engine Selection GUI Class
#------------------------------------------------------------------------------


def customSort(item1, item2):
    if item1[2].upper() > item2[2].upper():
        return 1
    elif item1[2].upper() == item2[2].upper():
        return 0
    else:
        return -1

class zynthian_gui_engine(zynthian_gui_selector):
    def __init__(self, parent = None):
        super(zynthian_gui_engine, self).__init__('Engine', parent)

        self.reset_index = True
        self.zyngine_counter = 0
        self.zyngines = OrderedDict()

        # [<short name>, (<long name>, <description>, <plugin type>, <plugin category>, <plugin class>, <enabled>, <plugin format>, <version object>)]
        engine_info = {"MX": ("Mixer", "ALSA Mixer", "MIXER", None, zynthian_engine_mixer, False, "Other", None)}
        # Generate list of synth and fx plugin items
        plugins = self.zynqtgui.zynthbox_plugins_helper.get_plugins_by_type("synth") | self.zynqtgui.zynthbox_plugins_helper.get_plugins_by_type("fx")
        for plugin_id, plugin_info in plugins.items():
            try:
                for _, version_info in plugin_info.versions.items():
                    if version_info.visible:
                        eng = ""

                        if version_info.engineType == "aeolus":
                            eng = "AE"
                        elif version_info.engineType == "fluidsynth":
                            eng = "FS"
                        elif version_info.engineType == "setbfree":
                            eng = "BF"
                        elif version_info.engineType == "sfizz":
                            eng = "SF"
                        elif version_info.engineType == "zynaddsubfx":
                            eng = "ZY"
                        elif version_info.engineType == "jalv":
                            eng = 'JV/{}'.format(version_info.pluginName)

                        if eng != "":
                            engine_info[eng] = (version_info.pluginName, version_info.pluginName, version_info.plugin_info.type, version_info.plugin_info.category, globals()[f"zynthian_engine_{version_info.engineType}"], True, version_info.format, version_info)
            except Exception as e:
                logging.exception(f"Error while trying to parse plugin details : {str(e)}")

        # Sort the engine details by name (case insensitive)
        self.engine_info = OrderedDict(sorted(engine_info.items(), key=lambda e: e[1][0].lower()))

        self.only_categories = False
        self.single_category = None
        # A variable to filter which type of plugin to list
        self.plugin_format = "LV2"
        self.set_engine_type("MIDI Synth")

    def set_midi_channel(self, chan):
        self.midi_chan = chan
        self.midi_channel_changed.emit()

    def get_midi_channel(self):
        return self.midi_chan


    @Signal
    def engine_type_changed(self):
        pass

    def get_engine_type(self):
        return self.engine_type

    def set_engine_type(self, etype):
        self.engine_type = etype
        self.set_midi_channel(None)
        self.reset_index = True
        self.fill_list()
        self.engine_type_changed.emit()


    def set_fxchain_mode(self, midi_chan):
        self.engine_type = "Audio Effect"
        self.set_midi_channel(midi_chan)
        self.reset_index = True
        self.engine_type_changed.emit()


    def set_midichain_mode(self, midi_chan):
        self.engine_type = "MIDI Tool"
        self.set_midi_channel(midi_chan)
        self.reset_index = True
        self.engine_type_changed.emit()

    synth_engine_type = Property(str, get_engine_type, set_engine_type, notify = engine_type_changed)

    def filtered_engines_by_cat(self):
        result = OrderedDict()
        for eng, info in self.engine_info.items():
            eng_type = info[2]
            cat = info[3]
            enabled = info[5]
            if enabled and (eng_type==self.engine_type or self.engine_type is None) and eng not in self.zyngines and self.plugin_format == info[6]:
                if cat not in result:
                    result[cat] = OrderedDict()
                result[cat][eng] = info
        return result


    def fill_list(self):
        self.list_data=[]
        self.list_metadata = []

        if self.engine_type == "MIDI Synth":
            for engine_short_name, engine_info in self.engine_info.items():
                eng_type = engine_info[2]
                enabled = engine_info[5]
                version_info = engine_info[7]
                if enabled and (eng_type == self.engine_type or self.engine_type is None) and engine_short_name not in self.zyngines:
                    metadata = {}
                    if version_info.plugin_info.description != "":
                        metadata["description"] = version_info.plugin_info.description
                    elif engine_info[1] is not None and engine_info[0] != engine_info[1]:
                        # Do not set description text if the synth name and description text is the same
                        metadata["description"] = engine_info[1]
                    metadata["pluginFormat"] = engine_info[6]

                    self.list_data.append((engine_short_name, len(self.list_data), engine_info[0]))
                    self.list_metadata.append(metadata)
        else:
            # Sort category headings, but headings starting with "Zynthian" are shown first

            for cat, infos in sorted(self.filtered_engines_by_cat().items(), key = lambda kv:"!" if kv[0] is None else kv[0]):
                # Add category header...
                if self.single_category == None:
                    if self.engine_type=="MIDI Synth":
                        if self.only_categories:
                            self.list_data.append((cat,len(self.list_data),"LV2 {}".format(cat)))
                        else:
                            self.list_data.append((None,len(self.list_data),"> LV2 {}".format(cat)))
                    else:
                        if self.only_categories:
                            self.list_data.append((cat,len(self.list_data),format(cat)))
                        else:
                            self.list_data.append((None,len(self.list_data),"> {}".format(cat)))

                    self.list_metadata.append({})

                cat_entries = []
                # Metadata entries have to be a set of 3 items in the format (<metadata>, None, info[1])
                # This is because the customSort method sorts the cat_entries by the value at index `2` and hence
                # metadata_entries has to have the info[1] enter at index 2, so it sorts correctly along with cat_entries
                metadata_entries = []

                if not self.only_categories and (self.single_category == None or self.single_category == cat or (cat == None and self.single_category == "None")): # Treat the string None as "we only want engines of None category
                    # Add engines on this category...
                    for eng, info in infos.items():
                        metadata = {}
                        version_info = info[7]
                        cat_entries.append((eng,len(self.list_data),info[1],info[0]))

                        if version_info.plugin_info.description != "":
                            metadata["description"] = version_info.plugin_info.description
                        elif info[1] is not None and not info[0] == info[1]:
                            # Do not set description text if the synth name and description text is the same
                            metadata["description"] = info[1]
                        metadata["pluginFormat"] = info[6]
                        metadata_entries.append((metadata, None, info[1]))

                cat_entries = sorted(cat_entries, key=cmp_to_key(customSort))
                metadata_entries = sorted(metadata_entries, key=cmp_to_key(customSort))

                self.list_data.extend(cat_entries)
                # Append only the metadata after sorting metadata_entries
                self.list_metadata.extend([x[0] for x in metadata_entries])

            # Select the first element that is not a category heading
            if self.reset_index:
                self.index = 0
                for i, val in enumerate(self.list_data):
                    if val[0] != None:
                        self.index = i
                        break
                self.reset_index = False

        super().fill_list()


    # def fill_listbox(self):
    #     super().fill_listbox()
    #     for i, val in enumerate(self.list_data):
    #         if val[0]==None:
    #             self.listbox.itemconfig(i, {'bg':zynthian_gui_config.color_off,'fg':zynthian_gui_config.color_tx_off})


    def select_action(self, i, t='S'):
        # during hte event processing done while the spinner is running, sometimes a spurious secondary action is invked...
        # this causes a second invisible layer to be added, causing the sound of two engines at a time to be heard.
        #FIXME: this needs a proper solution
        if t != 'S':
            return
        if i is not None and self.list_data[i][0]:
            if self.midi_chan is None:
                self.zynqtgui.screens['layer'].add_layer_engine(self.list_data[i][0], None)
            else:
                self.zynqtgui.start_loading()
                self.zynqtgui.screens['bank'].set_show_top_sounds(False)
                self.zynqtgui.screens['layer'].add_layer_engine(self.list_data[i][0], self.midi_chan)
                self.zynqtgui.stop_loading()

            # Try to set created synth engine's volume to max
            try:
                logging.debug("Setting synth volume to max when initializing")
                self.zynqtgui.fixed_layers.volumeControllers[self.midi_chan].value = self.zynqtgui.fixed_layers.volumeControllers[self.midi_chan].value_max
            except:
                logging.error("Error setting synth volume to max when initializing")

    def select_by_engine(self, eng):
        for i, val in enumerate(self.list_data):
            if eng == val[0]:
                self.select(i)
                return

    def start_engine(self, eng, setTaskMessage=True, taskMessagePrefix:str=""):
        if eng not in self.zyngines:
            if setTaskMessage:
                self.zynqtgui.currentTaskMessage = f"{taskMessagePrefix}Starting engine {eng}"

            info=self.engine_info[eng]
            zynthian_engine_class=info[4]
            if eng[0:3]=="JV/":
                eng="JV/{}".format(self.zyngine_counter)
            else:
                if eng=="AE":
                    eng="AE/{}".format(self.zyngine_counter)
                elif eng=="FS":
                    eng="FS/{}".format(self.zyngine_counter)
                elif eng=="BF":
                    eng="BF/{}".format(self.zyngine_counter)
                elif eng=="SF":
                    eng="SF/{}".format(self.zyngine_counter)
                elif eng=="ZY":
                    eng="ZY/{}".format(self.zyngine_counter)
            self.zyngines[eng]=zynthian_engine_class(info[7], self.zynqtgui)

        self.zyngine_counter+=1
        return self.zyngines[eng]


    def stop_engine(self, eng, wait=0):
        if eng in self.zyngines:
            self.zynqtgui.currentTaskMessage = f"Stopping engine {eng}"
            self.zyngines[eng].stop()
            del self.zyngines[eng]
            if wait>0:
                sleep(wait)


    def stop_unused_engines(self):
        global_fx_engines = [fx_engine for fx_engine, _, _ in self.zynqtgui.global_fx_engines]

        for eng in list(self.zyngines.keys()):
            if len(self.zyngines[eng].layers) == 0 and self.zyngines[eng] not in global_fx_engines:
                logging.debug("Stopping Unused Engine '{}' ...".format(eng))
                self.zyngines[eng].stop()
                del self.zyngines[eng]


    def stop_unused_jalv_engines(self):
        global_fx_engines = [fx_engine for fx_engine, _, _ in self.zynqtgui.global_fx_engines]

        for eng in list(self.zyngines.keys()):
            if len(self.zyngines[eng].layers) == 0 and self.zyngines[eng] not in global_fx_engines and eng[0:3] == "JV/":
                self.zyngines[eng].stop()
                del self.zyngines[eng]


    def get_engine_info(self, eng):
        return self.engine_info[eng]

    def get_shown_category(self):
        return self.single_category

    def set_shown_category(self, shown : str):
        if len(shown) == 0:
            self.single_category = None
        else:
            if self.single_category == shown:
                return
            self.single_category = shown
        self.fill_list()
        self.shown_category_changed.emit()


    def set_select_path(self):
        self.select_path = "Engine"
        self.select_path_element = "Engine"
        super().set_select_path()

    def get_pluginFormat(self):
        return self.plugin_format
    def set_pluginFormat(self, format):
        if not self.plugin_format == format:
            self.plugin_format = format
            self.fill_list()
            self.pluginFormatChanged.emit()
    pluginFormatChanged = Signal()
    pluginFormat = Property(str, get_pluginFormat, set_pluginFormat, notify=pluginFormatChanged)

    midi_channel_changed = Signal()
    shown_category_changed = Signal()

    midi_channel = Property(int, get_midi_channel, set_midi_channel, notify = midi_channel_changed)

    shown_category = Property(str, get_shown_category, set_shown_category, notify = shown_category_changed)

#------------------------------------------------------------------------------
