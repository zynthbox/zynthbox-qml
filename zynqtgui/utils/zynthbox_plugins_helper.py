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


class zynthbox_plugin_version_info(QObject):
    """
    A Class that represents a zynthbox plugin version and stores its details like plugin name, format, path, category, etc as defined on plugins json
    """
    def __init__(self, version, version_details, plugin_info):
        super(zynthbox_plugin_version_info, self).__init__(plugin_info)

        self.version = version
        self.plugin_info = plugin_info
        self.visible = version_details["visible"]
        self.pluginName = version_details["pluginName"]
        self.format = version_details["format"]
        self.path = version_details["path"]
        self.engineType = version_details["engineType"]
        self.sha256sum = version_details["sha256sum"]
        self.zynthboxVersionAdded = version_details["zynthboxVersionAdded"]
        self.url = version_details["url"]
        self.volumeControls = version_details["volumeControls"]
        self.cutoffControl = version_details["cutoffControl"]
        self.resonanceControl = version_details["resonanceControl"]


class zynthbox_plugin_info(QObject):
    """
    A Class that represents a zynthbox plugin and stores its details like plugin id, plugin type, etc as defined on plugins json
    """
    def __init__(self, key, plugin_details, type, parent=None):
        global categories_by_type
        super(zynthbox_plugin_info, self).__init__(parent)

        self.id = key
        self.type = type
        self.displayName = plugin_details["displayName"]
        self.description = plugin_details["description"]
        self.longDescription = plugin_details["longDescription"]
        self.image = plugin_details["image"]
        # List of category_info instances
        self.categories = []
        for category_details in plugin_details["categories"]:
            self.categories.append(zynthbox_plugins_helper.categories_by_type[category_details["type"]][category_details["id"]])
        # Stores the current version name
        self.currentVersion = plugin_details["currentVersion"]
        # Stores the instance of current version info
        self.currentVersionInfo = None
        # Stores plugin details per version. A plugin can have different version with different engineType
        self.versions = {}

        if "versions" in plugin_details:
            for version in plugin_details["versions"]:
                self.versions[version] = zynthbox_plugin_version_info(version, plugin_details["versions"][version], self)
                if version == self.currentVersion:
                    self.currentVersionInfo = self.versions[version]


class zynthbox_plugin_category_info(QObject):
    """
    A Class that represents a zynthbox plugin category and stores its details like category id and name
    """
    def __init__(self, type, id, category_details, parent):
        super(zynthbox_plugin_category_info, self).__init__(parent)

        self.type = type
        self.id = id
        if type == "synth":
            # Set displayName to "Instrument" as a fallback for MIDI Synths
            # This is to maintain compatibility with old gui_engine logic where synths
            # were always displayed as "Instrument"
            self.displayName = "Instrument"
        else:
            self.displayName = category_details["displayName"]
        self.image = category_details["image"]
        self.description = category_details["description"]
        self.defaultDryWetMixAmount = category_details["defaultDryWetMixAmount"]


class zynthbox_old_plugin_info(QObject):
    """
    A Class that represents a zynthbox plugin and stores its details like plugin id, plugin type, etc as defined on plugins json
    """
    def __init__(self, key, plugin_details, type, parent=None):
        super(zynthbox_old_plugin_info, self).__init__(parent)

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
        self.visible = True

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
        if "visible" in plugin_details:
            self.visible = plugin_details["visible"]

        for key in plugin_details:
            self.substitution_map[f"{self.id}_{key}"] = plugin_details[key]


class zynthbox_plugins_helper(QObject):
    categories_by_type = {
        "synth": {},
        "soundfont": {},
        "audioFx": {}
    }
    plugins_by_type = {
        "synth": {},
        "soundfont": {},
        "audioFx": {}
    }
    old_plugins_by_name = {}
    old_plugins_by_id = {}

    """
    zynthian_plugin_helper class will be used to translate between Zynthbox plugin ids and plugin names in sketch files
    This is required for future proofing sketches and other files that references plugins so that if plugin name changes,
    sketches can still be unbounced without any issues
    """
    def __init__(self, parent=None):
        super(zynthbox_plugins_helper, self).__init__(parent)

        with open("/zynthian/zynthbox-qml/config/plugins.json", "r") as f:
            plugins_json = json.load(f)
        with open("/zynthian/zynthbox-qml/config/categories.json", "r") as f:
            categories_json = json.load(f)
        with open("/zynthian/zynthbox-qml/config/plugins.old.json", "r") as f:
            old_plugins_json = json.load(f)

        for key in categories_json["synth"]:
            category_info = zynthbox_plugin_category_info("synth", key, categories_json["synth"][key], self)
            zynthbox_plugins_helper.categories_by_type["synth"][key] = category_info
        for key in categories_json["audioFx"]:
            category_info = zynthbox_plugin_category_info("audioFx", key, categories_json["audioFx"][key], self)
            zynthbox_plugins_helper.categories_by_type["audioFx"][key] = category_info
        for key in categories_json["soundfont"]:
            category_info = zynthbox_plugin_category_info("soundfont", key, categories_json["soundfont"][key], self)
            zynthbox_plugins_helper.categories_by_type["soundfont"][key] = category_info

        for key in plugins_json["synth"]:
            plugin_info = zynthbox_plugin_info(key, plugins_json["synth"][key], "MIDI Synth", self)
            zynthbox_plugins_helper.plugins_by_type["synth"][key] = plugin_info
        for key in plugins_json["audioFx"]:
            plugin_info = zynthbox_plugin_info(key, plugins_json["audioFx"][key], "Audio Effect", self)
            zynthbox_plugins_helper.plugins_by_type["audioFx"][key] = plugin_info
        for key in plugins_json["soundfont"]:
            plugin_info = zynthbox_plugin_info(key, plugins_json["soundfont"][key], "MIDI Synth", self)
            zynthbox_plugins_helper.plugins_by_type["soundfont"][key] = plugin_info

        for key in old_plugins_json:
            # type parameter in old-old json(plugin id < 1000) used to store the plugin format.
            # old plugins json also contains newer plugin ids but they do not have version data in them.
            plugin_info = zynthbox_old_plugin_info(key, old_plugins_json[key], "", self)
            zynthbox_plugins_helper.old_plugins_by_id[key] = plugin_info
            if "type" in old_plugins_json[key]:
                zynthbox_plugins_helper.old_plugins_by_name[f"{old_plugins_json[key]['type']}/{old_plugins_json[key]['name']}"] = plugin_info
            else:
                zynthbox_plugins_helper.old_plugins_by_name[f"{old_plugins_json[key]['format'].lower()}/{old_plugins_json[key]['name']}"] = plugin_info

    def get_plugins_by_type(self, type):
        return zynthbox_plugins_helper.plugins_by_type[type]

    def update_layer_snapshot_plugin_id_to_name(self, source_snapshot):
        """
        Translate plugin id to plugin name in the layer snapshot
        """
        # FIXME : This is a temporary fallback logic that needs to be removed before 1.0 release

        if "plugin_id" in source_snapshot and "plugin_version" in source_snapshot:
            # snapshot has both plugin id and plugin version. This snapshot is the newer one and does not need translating
            return source_snapshot
        else:
            # snapshot deos not have plugin version. This snapshot is the old one and needs translating
            snapshot = copy.deepcopy(source_snapshot)

            if "plugin_id" in snapshot and snapshot["plugin_id"].startswith("ZBP_"):
                plugin_id = snapshot["plugin_id"]

                # If a snapshot needs id to name translation, it is from old plugins.
                # New plugins json logic do not need conversion.
                try:
                    plugin_info = self.old_plugins_by_id[plugin_id]

                    if plugin_info is not None:
                        # Handle Plugin Name substitution for engines
                        if snapshot["engine_nick"].startswith("JV/"):
                            # Jalv stores the plugin name in its nickname and name like `JV/<plugin name>` and `Jalv/<plugin name>`
                            logging.info(f"Found ZBP plugin id when restoring snapshot. Translating plugin id {plugin_id} to {plugin_info.name}")
                            snapshot["engine_name"] = Template(snapshot["engine_name"]).substitute(plugin_info.substitution_map)
                            snapshot["engine_nick"] = Template(snapshot["engine_nick"]).substitute(plugin_info.substitution_map)
                        elif snapshot["engine_nick"].startswith("JY/"):
                            # Jucy stores the plugin name in its nickname and name like `JY/<plugin name>` and `Jucy/<plugin name>`
                            logging.info(f"Found ZBP plugin id when restoring snapshot. Translating plugin id {plugin_id} to {plugin_info.name}")
                            snapshot["engine_name"] = Template(snapshot["engine_name"]).substitute(plugin_info.substitution_map)
                            snapshot["engine_nick"] = Template(snapshot["engine_nick"]).substitute(plugin_info.substitution_map)
                        elif snapshot["engine_nick"] == "SF":
                            # SFizz stores the plugin name in a few places
                            # 1. bank_name: `SFZ/<plugin name>` or `MySFZ/<plugin name>`
                            # 2. bank_info[0]: path to plugin `/zynthian/zynthian-data/soundfonts/sfz/<plugin name>`
                            # 3. bank_info[2]: same as bank_name
                            # 4. bank_info[4]: `<plugin name>`
                            # 5. preset_info[0]: `<path to plugin as in bank_info[0]>/...`
                            logging.info(f"Found ZBP plugin id when restoring snapshot. Translating plugin id {plugin_id} to {plugin_info.name}")
                            snapshot["bank_name"] = Template(snapshot["bank_name"]).substitute(plugin_info.substitution_map)
                            snapshot["bank_info"][0] = Template(snapshot["bank_info"][0]).substitute(plugin_info.substitution_map)
                            snapshot["bank_info"][2] = Template(snapshot["bank_info"][2]).substitute(plugin_info.substitution_map)
                            snapshot["bank_info"][4] = Template(snapshot["bank_info"][4]).substitute(plugin_info.substitution_map)
                            snapshot["preset_info"][0] = Template(snapshot["preset_info"][0]).substitute(plugin_info.substitution_map)
                        elif snapshot["engine_nick"] == "FS":
                            # Fluidsynth stores the plugin name in a few places
                            # 1. bank_name: `<plugin name>`
                            # 2. bank_info[0]: path to plugin `/zynthian/zynthian-data/soundfonts/sf2/<plugin name>.sf2`
                            # 3. bank_info[2]: `<plugin name>`
                            # 4. bank_info[4]: Filename `<plugin_name>.sf2` from plugin path
                            # 5. preset_info[0]: `<path to plugin as in bank_info[0]>/...`
                            # 6. preset_info[3]: path to plugin `/zynthian/zynthian-data/soundfonts/sf2/<plugin name>.sf2`
                            logging.info(f"Found ZBP plugin id when restoring snapshot. Translating plugin id {plugin_id} to {plugin_info.name}")
                            snapshot["bank_name"] = Template(snapshot["bank_name"]).substitute(plugin_info.substitution_map)
                            snapshot["bank_info"][0] = Template(snapshot["bank_info"][0]).substitute(plugin_info.substitution_map)
                            snapshot["bank_info"][2] = Template(snapshot["bank_info"][2]).substitute(plugin_info.substitution_map)
                            snapshot["bank_info"][4] = Template(snapshot["bank_info"][4]).substitute(plugin_info.substitution_map)
                            snapshot["preset_info"][0] = Template(snapshot["preset_info"][0]).substitute(plugin_info.substitution_map)
                            snapshot["preset_info"][3] = Template(snapshot["preset_info"][3]).substitute(plugin_info.substitution_map)
                    else:
                        logging.error(f"FATAL ERROR : Stored plugin id {plugin_id} is not found and cannot be translated to plugin name. This should not happen unless the files are tampered with.")
                except Exception as e:
                    logging.error(f"Error while trying to translate plugin id to name : {str(e)}")
            return snapshot
