#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthbox Plugin helper class
#
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


import copy
import json
import logging
import re
from string import Template
from pathlib import Path
from PySide2.QtCore import QObject


class zynthbox_plugin(QObject):
    """
    A Class that represents a zynthbox plugin and stores its details like plugin id, plugin type, etc as defined on plugins json
    """
    def __init__(self, key, plugin_details, type, parent=None):
        super(zynthbox_plugin, self).__init__(parent)

        self.id = key
        self.name = plugin_details["name"]
        self.path = plugin_details["path"]
        self.type = type
        self.version = ""
        self.version_added = ""
        self.format = ""
        self.url = ""
        self.category = ""
        self.engineType = None
        self.substitution_map = {}
        self.volumeControls = [] # List of strings
        self.cutoffControl = ""
        self.resonanceControl = ""
        self.description = ""

        if "version" in plugin_details:
            self.version = plugin_details["version"]
        if "zynthbox_version_added" in plugin_details:
            self.version_added = plugin_details["zynthbox_version_added"]
        if "format" in plugin_details:
            self.format = plugin_details["format"]
        if "url" in plugin_details:
            self.url = plugin_details["url"]
        if type == "MIDI Synth":
            self.category = "Instrument"
        elif type != "MIDI Synth" and "category" in plugin_details:
            self.category = plugin_details["category"]
        if "engineType" in plugin_details:
            self.engineType = plugin_details["engineType"]
        if "volumeControls" in plugin_details:
            self.volumeControls = plugin_details["volumeControls"]
        if "cutoffControl" in plugin_details:
            self.cutoffControl = plugin_details["cutoffControl"]
        if "resonanceControl" in plugin_details:
            self.resonanceControl = plugin_details["resonanceControl"]
        if "description" in plugin_details:
            self.description = plugin_details["description"]

        for key in plugin_details:
            self.substitution_map[f"{self.id}_{key}"] = plugin_details[key]


class zynthbox_plugins_helper(QObject):
    """
    zynthian_plugin_helper class will be used to translate between Zynthbox plugin ids and plugin names in sketch files
    This is required for future proofing sketches and other files that references plugins so that if plugin name changes,
    sketches can still be unbounced without any issues
    """
    def __init__(self, parent=None):
        super(zynthbox_plugins_helper, self).__init__(parent)

        self.plugins_by_name = {}
        self.plugins_by_id = {}
        self.old_plugins_by_name = {}
        self.old_plugins_by_id = {}

        with open("/zynthian/zynthbox-qml/config/plugins.json", "r") as f:
            plugins_json = json.load(f)

        with open("/zynthian/zynthbox-qml/config/plugins.old.json", "r") as f:
            old_plugins_json = json.load(f)

        for key in plugins_json["synth"]:
            plugin = zynthbox_plugin(key, plugins_json["synth"][key], "MIDI Synth", self)
            self.plugins_by_id[key] = plugin
            self.plugins_by_name[f"{plugins_json['synth'][key]['format'].lower()}/{plugins_json['synth'][key]['name']}"] = plugin
        for key in plugins_json["audioFx"]:
            plugin = zynthbox_plugin(key, plugins_json["audioFx"][key], "Audio Effect", self)
            self.plugins_by_id[key] = plugin
            self.plugins_by_name[f"{plugins_json['audioFx'][key]['format'].lower()}/{plugins_json['audioFx'][key]['name']}"] = plugin
        for key in plugins_json["soundfont"]:
            plugin = zynthbox_plugin(key, plugins_json["soundfont"][key], "MIDI Synth", self)
            self.plugins_by_id[key] = plugin
            self.plugins_by_name[f"{plugins_json['soundfont'][key]['format'].lower()}/{plugins_json['soundfont'][key]['name']}"] = plugin

        for key in old_plugins_json:
            # type parameter in old json used to store the plugin format.
            plugin = zynthbox_plugin(key, old_plugins_json[key], "", self)
            self.old_plugins_by_id[key] = plugin
            self.old_plugins_by_name[f"{old_plugins_json[key]['type']}/{old_plugins_json[key]['name']}"] = plugin

    def update_layer_snapshot_plugin_name_to_id(self, source_snapshot):
        """
        Translate plugin name to plugin id in the layer snapshot
        """
        snapshot = copy.deepcopy(source_snapshot)
        # Handle Plugin ID substitution for engines having plugin support like (Jalv: lv2, SFizz: sfz, FluidSynth: sf2, Jucy: vst3)
        if snapshot["engine_nick"].startswith("JV/"):
            # Jalv stores the plugin name in its nickname and name like `JV/<plugin name>` and `Jalv/<plugin name>`
            plugin_name = snapshot["engine_nick"].split("/")[1]
            if f"lv2/{plugin_name}" in self.plugins_by_name:
                plugin_id = self.plugins_by_name[f"lv2/{plugin_name}"].id
                logging.info(f"Found ZBP plugin id for plugin when generating snapshot. Translating plugin name {plugin_name} to {plugin_id}")
                snapshot["plugin_id"] = plugin_id
                snapshot["engine_name"] = "{0}/${{{1}_name}}".format(snapshot['engine_name'].split('/')[0], plugin_id)
                snapshot["engine_nick"] = "{0}/${{{1}_name}}".format(snapshot['engine_nick'].split('/')[0], plugin_id)
            else:
                logging.info(f"Plugin name JV/{plugin_name} not found in plugin database. Plugin might be added by user. Handle user added plugins accordingly")
        elif snapshot["engine_nick"].startswith("JY/"):
            # Jucy stores the plugin name in its nickname and name like `JY/<plugin name>` and `Jucy/<plugin name>`
            plugin_name = snapshot["engine_nick"].split("/")[1]
            if f"vst3/{plugin_name}" in self.plugins_by_name:
                plugin_id = self.plugins_by_name[f"vst3/{plugin_name}"].id
                logging.info(f"Found ZBP plugin id for plugin when generating snapshot. Translating plugin name {plugin_name} to {plugin_id}")
                snapshot["plugin_id"] = plugin_id
                snapshot["engine_name"] = "{0}/${{{1}_name}}".format(snapshot['engine_name'].split('/')[0], plugin_id)
                snapshot["engine_nick"] = "{0}/${{{1}_name}}".format(snapshot['engine_nick'].split('/')[0], plugin_id)
            else:
                logging.info(f"Plugin name JY/{plugin_name} not found in plugin database. Plugin might be added by user. Handle user added plugins accordingly")
        elif snapshot["engine_nick"] == "SF":
            # SFizz stores the plugin name in a few places
            # 1. bank_name: `SFZ/<plugin name>` or `MySFZ/<plugin name>`
            # 2. bank_info[0]: path to plugin `/zynthian/zynthian-data/soundfonts/sfz/<plugin name>`
            # 3. bank_info[2]: same as bank_name
            # 4. bank_info[4]: `<plugin name>`
            # 5. preset_info[0]: `<path to plugin as in bank_info[0]>/...`
            plugin_name = snapshot["bank_name"].split("/")[1]
            if f"sfz/{plugin_name}" in self.plugins_by_name:
                plugin = self.plugins_by_name[f"sfz/{plugin_name}"]
                logging.info(f"Found ZBP plugin id for plugin when generating snapshot. Translating plugin name {plugin_name} to {plugin.id}")
                snapshot["plugin_id"] = plugin.id
                snapshot["bank_name"] = "{0}/${{{1}_name}}".format(snapshot['bank_name'].split('/')[0], plugin.id)
                snapshot["bank_info"][0] = "${{{0}_path}}".format(plugin.id)
                snapshot["bank_info"][2] = snapshot["bank_name"]
                snapshot["bank_info"][4] = "${{{0}_name}}".format(plugin.id)
                snapshot["preset_info"][0] = snapshot["preset_info"][0].replace(plugin.path, "${{{0}_path}}".format(plugin.id))
            else:
                logging.info(f"Plugin name SF/{plugin_name} not found in plugin database. Plugin might be added by user. Handle user added plugins accordingly")
        elif snapshot["engine_nick"] == "FS":
            # Fluidsynth stores the plugin name in a few places
            # 1. bank_name: `<plugin name>`
            # 2. bank_info[0]: path to plugin `/zynthian/zynthian-data/soundfonts/sf2/<plugin name>.sf2`
            # 3. bank_info[2]: `<plugin name>`
            # 4. bank_info[4]: stem from plugin path
            # 5. preset_info[0]: `<path to plugin as in bank_info[0]>/...`
            # 6. preset_info[3]: path to plugin `/zynthian/zynthian-data/soundfonts/sf2/<plugin name>.sf2`
            plugin_name = snapshot["bank_name"]
            if f"sf2/{plugin_name}" in self.plugins_by_name:
                plugin = self.plugins_by_name[f"sf2/{plugin_name}"]
                logging.info(f"Found ZBP plugin id for plugin when generating snapshot. Translating plugin name {plugin_name} to {plugin.id}")
                snapshot["plugin_id"] = plugin.id
                snapshot["bank_name"] = "${{{0}_name}}".format(plugin.id)
                snapshot["bank_info"][0] = "${{{0}_path}}".format(plugin.id)
                snapshot["bank_info"][2] = "${{{0}_name}}".format(plugin.id)
                snapshot["bank_info"][4] = "${{{0}_name}}.sf2".format(plugin.id)
                snapshot["preset_info"][0] = snapshot["preset_info"][0].replace(plugin.path, "${{{0}_path}}".format(plugin.id))
                snapshot["preset_info"][3] = "${{{0}_path}}".format(plugin.id)
            else:
                logging.info(f"Plugin name FS/{plugin_name} not found in plugin database. Plugin might be added by user. Handle user added plugins accordingly")

        return snapshot

    def update_layer_snapshot_plugin_id_to_name(self, source_snapshot):
        """
        Translate plugin id to plugin name in the layer snapshot
        """
        snapshot = copy.deepcopy(source_snapshot)

        if "plugin_id" in snapshot and snapshot["plugin_id"].startswith("ZBP_"):
            plugin_id = snapshot["plugin_id"]

            # Check if the plugin id is <1000
            # If < 1000, then the snapshot is saved with the old plugin json. Use the correct plugins json accordingly
            try:
                plugin_id_integer = int(re.findall("\\d+", plugin_id)[0])

                if plugin_id_integer < 1000 and plugin_id in self.old_plugins_by_id:
                    plugin = self.old_plugins_by_id[plugin_id]
                elif plugin_id in self.plugins_by_id:
                    plugin = self.plugins_by_id[plugin_id]

                if plugin is not None:
                    # Handle Plugin Name substitution for engines
                    if snapshot["engine_nick"].startswith("JV/"):
                        # Jalv stores the plugin name in its nickname and name like `JV/<plugin name>` and `Jalv/<plugin name>`
                        logging.info(f"Found ZBP plugin id when restoring snapshot. Translating plugin id {plugin_id} to {plugin.name}")
                        snapshot["engine_name"] = Template(snapshot["engine_name"]).substitute(plugin.substitution_map)
                        snapshot["engine_nick"] = Template(snapshot["engine_nick"]).substitute(plugin.substitution_map)
                    elif snapshot["engine_nick"].startswith("JY/"):
                        # Jucy stores the plugin name in its nickname and name like `JY/<plugin name>` and `Jucy/<plugin name>`
                        logging.info(f"Found ZBP plugin id when restoring snapshot. Translating plugin id {plugin_id} to {plugin.name}")
                        snapshot["engine_name"] = Template(snapshot["engine_name"]).substitute(plugin.substitution_map)
                        snapshot["engine_nick"] = Template(snapshot["engine_nick"]).substitute(plugin.substitution_map)
                    elif snapshot["engine_nick"] == "SF":
                        # SFizz stores the plugin name in a few places
                        # 1. bank_name: `SFZ/<plugin name>` or `MySFZ/<plugin name>`
                        # 2. bank_info[0]: path to plugin `/zynthian/zynthian-data/soundfonts/sfz/<plugin name>`
                        # 3. bank_info[2]: same as bank_name
                        # 4. bank_info[4]: `<plugin name>`
                        # 5. preset_info[0]: `<path to plugin as in bank_info[0]>/...`
                        logging.info(f"Found ZBP plugin id when restoring snapshot. Translating plugin id {plugin_id} to {plugin.name}")
                        snapshot["bank_name"] = Template(snapshot["bank_name"]).substitute(plugin.substitution_map)
                        snapshot["bank_info"][0] = Template(snapshot["bank_info"][0]).substitute(plugin.substitution_map)
                        snapshot["bank_info"][2] = Template(snapshot["bank_info"][2]).substitute(plugin.substitution_map)
                        snapshot["bank_info"][4] = Template(snapshot["bank_info"][4]).substitute(plugin.substitution_map)
                        snapshot["preset_info"][0] = Template(snapshot["preset_info"][0]).substitute(plugin.substitution_map)
                    elif snapshot["engine_nick"] == "FS":
                        # Fluidsynth stores the plugin name in a few places
                        # 1. bank_name: `<plugin name>`
                        # 2. bank_info[0]: path to plugin `/zynthian/zynthian-data/soundfonts/sf2/<plugin name>.sf2`
                        # 3. bank_info[2]: `<plugin name>`
                        # 4. bank_info[4]: Filename `<plugin_name>.sf2` from plugin path
                        # 5. preset_info[0]: `<path to plugin as in bank_info[0]>/...`
                        # 6. preset_info[3]: path to plugin `/zynthian/zynthian-data/soundfonts/sf2/<plugin name>.sf2`
                        logging.info(f"Found ZBP plugin id when restoring snapshot. Translating plugin id {plugin_id} to {plugin.name}")
                        snapshot["bank_name"] = Template(snapshot["bank_name"]).substitute(plugin.substitution_map)
                        snapshot["bank_info"][0] = Template(snapshot["bank_info"][0]).substitute(plugin.substitution_map)
                        snapshot["bank_info"][2] = Template(snapshot["bank_info"][2]).substitute(plugin.substitution_map)
                        snapshot["bank_info"][4] = Template(snapshot["bank_info"][4]).substitute(plugin.substitution_map)
                        snapshot["preset_info"][0] = Template(snapshot["preset_info"][0]).substitute(plugin.substitution_map)
                        snapshot["preset_info"][3] = Template(snapshot["preset_info"][3]).substitute(plugin.substitution_map)
                else:
                    logging.error(f"FATAL ERROR : Stored plugin id {plugin_id} is not found and cannot be translated to plugin name. This should not happen unless the files are tampered with.")
            except Exception as e:
                logging.error(f"Error while trying to translate plugin id to name : {str(e)}")
        return snapshot

    def generate_plugins_json(self):
        """
        Calling this method will generate a plugins.json file in zynthbox-qml/config/plugins.json
        This is not to be automated and only invoked manually when plugin.json is requried to be rebuilt
        """

        plugin_count = 0
        plugins = {}

        # Read lv2 plugins and add to list
        with open("/zynthian/config/jalv/plugins.json", "r") as f:
            lv2 = json.load(f)
            for plugin_name in lv2:
                plugins[f"ZBP_{plugin_count:05d}"] = {
                    "name": plugin_name,
                    "path": lv2[plugin_name]["BUNDLE_URI"].replace("file://", ""),
                    "type": "lv2",
                    "version_added": 1
                }
                plugin_count += 1

        # Read sf2 plugins and add to list
        for plugin in Path("/zynthian/zynthian-data/soundfonts/sf2").glob("*.sf2"):
            plugins[f"ZBP_{plugin_count:05d}"] = {
                "name": str(plugin).split("/")[-1].replace(".sf2", ""),
                "path": "/zynthian/zynthian-data/soundfonts/sf2/" + str(plugin).split("/")[-1],
                "type": "sf2",
                "version_added": 1
            }
            plugin_count += 1

        # Read sfz plugins and add to list
        for plugin in Path("/zynthian/zynthian-data/soundfonts/sfz").iterdir():
            if plugin.is_dir():
                plugins[f"ZBP_{plugin_count:05d}"] = {
                    "name": str(plugin).split("/")[-1],
                    "path": "/zynthian/zynthian-data/soundfonts/sfz/" + str(plugin).split("/")[-1],
                    "type": "sfz",
                    "version_added": 1
                }
                plugin_count += 1

        with open("/zynthian/zynthbox-qml/config/plugins.json", "w") as f:
            json.dump(plugins, f)

