#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian VST3-plugin management
# 
# zynthian VST3
# 
# Copyright (C) 2024 Anupam Basak <anupam.basak27@gmail.com>
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


import Jucy
import os
import json
import logging
import sys

from pathlib import Path
from collections import OrderedDict
from enum import Enum


plugins = None
plugins_by_type = None
plugins_json_file = Path(f"{os.environ.get('ZYNTHIAN_CONFIG_DIR')}/jucy/plugins.json")


class PluginType(Enum):
    MIDI_SYNTH = "MIDI Synth"
    MIDI_TOOL = "MIDI Tool"
    AUDIO_EFFECT = "Audio Effect"
    AUDIO_GENERATOR = "Audio Generator"
    #UNKNOWN = "Unknown"


def get_plugins():
    global plugins, plugins_json_file
    if plugins is None:
        if not plugins_json_file.exists():
            generate_jucy_plugins_json_cache()
        with open(plugins_json_file, "r") as f:
            plugins = json.load(f, object_pairs_hook=OrderedDict)
    return plugins


def get_plugins_by_type():
    global plugins_by_type
    if plugins_by_type is None:
        plugins_by_type = OrderedDict()
        for t in PluginType:
            plugins_by_type[t.value] = OrderedDict()

        for name, properties in get_plugins().items():
            plugins_by_type[properties['TYPE']][name] = properties
    return plugins_by_type


def generate_jucy_plugins_json_cache():
    global plugins, plugins_by_type, plugins_json_file

    def get_plugin_type(plugin: Jucy.PluginDescription):
        result = "Unknown"
        # Plugin category string from Juce is a string seperated by `|`
        # where the first element is the plugin type and if applicable the 2nd string is the subtype
        # For example, the category could be `Instrument` or `FX|Reverb`
        plugin_category = plugin.category.split("|")
        if len(plugin_category) > 0:
            if plugin_category[0] == "Instrument":
                result = "MIDI Synth"
            elif plugin_category[0] == "Fx":
                result = "Audio Effect"
        return result

    def get_plugin_class(plugin: Jucy.PluginDescription):
        result = "Uncategorized"
        # Plugin category string from Juce is a string seperated by `|`
        # where the first element is the plugin type and if applicable the 2nd string is the subtype
        # For example, the category could be `Instrument` or `FX|Reverb`
        plugin_category = plugin.category.split("|")
        if len(plugin_category) > 0:
            if plugin_category[0] == "Instrument":
                result = "Instrument"
            elif plugin_category[0] == "Fx" and plugin.name == "Airwindows Consolidated":
                # Special case for Airwindows. Put airwindows in its own category.
                result = "Airwindows"
            elif plugin_category[0] == "Fx" and len(plugin_category) > 1:
                result = plugin_category[1]
        return result

    plugins_dict = OrderedDict()
    jucy_pluginhost = Jucy.VST3PluginHost("", "", None)
    plugins_json_file.parent.mkdir(parents=True, exist_ok=True)
    # Invalidate existing plugins and plugins_by_type lists when cache is generated
    plugins = None
    plugins_by_type = None
    # First read the existing plugins json if available
    if plugins_json_file.exists():
        with open(plugins_json_file, "r") as f:
            plugins_dict = json.load(f)

    for plugin in jucy_pluginhost.getAllPlugins():
        enabled = False
        # If plugin already exists in cache, use the previous value for enabled
        if plugin.name in plugins_dict:
            enabled = plugins_dict[plugin.name]["ENABLED"]
        plugins_dict[plugin.name] = {
            'TYPE': get_plugin_type(plugin),
            'CLASS': get_plugin_class(plugin),
            'URL': plugin.fileOrIdentifier,
            'ENABLED': enabled
        }

    save_plugins(plugins_dict)


def save_plugins(_plugins=None):
    global plugins_json_file
    # If plugins dict is passed, save it to file.
    # Otherwise save the global plugins dict
    if _plugins is None:
        _plugins = get_plugins()
    # Sort and store plugins cache
    with open(plugins_json_file, "w") as f:
        json.dump(OrderedDict(sorted(_plugins.items())), f)


if __name__ == '__main__':
    log_level=logging.WARNING
    logging.basicConfig(format='%(levelname)s:%(module)s: %(message)s', stream=sys.stderr, level=log_level)
    logging.getLogger().setLevel(level=log_level)
    generate_jucy_plugins_json_cache()
