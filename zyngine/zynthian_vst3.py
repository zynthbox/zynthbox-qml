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


def generate_jucy_plugins_json_cache():
    plugins_json_file = Path(f"{os.environ.get('ZYNTHIAN_CONFIG_DIR')}/jucy/plugins.json")

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

    # Sort and store plugins cache
    with open(plugins_json_file, "w") as f:
        json.dump(OrderedDict(sorted(plugins_dict.items())), f)


if __name__ == '__main__':
    log_level=logging.WARNING
    logging.basicConfig(format='%(levelname)s:%(module)s: %(message)s', stream=sys.stderr, level=log_level)
    logging.getLogger().setLevel(level=log_level)
    generate_jucy_plugins_json_cache()
