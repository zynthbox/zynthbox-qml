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


import json
import logging
from PySide2.QtCore import QObject


class zynthbox_plugin(QObject):
    """
    A Class that represents a zynthbox plugin and stores its details like plugin id, plugin type, etc as defined on plugins json
    """
    def __init__(self, key, plugin_details, parent=None):
        super(zynthbox_plugin, self).__init__(parent)
        self.plugin_id = key
        self.path = plugin_details["path"]
        self.plugin_name = plugin_details["plugin_name"]
        self.plugin_type = plugin_details["plugin_type"]
        self.version_added = plugin_details["version_added"]


class zynthbox_plugins_helper(QObject):
    """
    zynthian_plugin_helper class will be used to translate between Zynthbox plugin ids and plugin names in sketch files
    This is required for future proofing sketches and other files that references plugins so that if plugin name changes,
    sketches can still be unbounced without any issues
    """
    def __init__(self, parent=None):
        super(zynthbox_plugins_helper, self).__init__(parent)
        self.read_plugins_json()

    def read_plugins_json(self):
        self.plugins_by_name = {}
        self.plugins_by_id = {}

        with open("/zynthian/zynthbox-qml/config/plugins.json", "r") as f:
            plugins_json = json.load(f)

        for key in plugins_json:
            plugin = zynthbox_plugin(key, plugins_json[key], self)
            self.plugins_by_id[key] = plugin
            self.plugins_by_name[f"{plugins_json[key]['plugin_type']}/{plugins_json[key]['plugin_name']}"] = plugin

    def update_layer_snapshot_plugin_name_to_id(self, snapshot):
        """
        Translate plugin name to plugin id in the layer snapshot
        """
        # Handle Plugin ID substitution for engines having plugin support like (Jalv: lv2, SFizz: sfz, FluidSynth: sf2)
        if snapshot["engine_nick"].startswith("JV/"):
            # Jalv stores the plugin name in its nickname and name like `JV/<plugin name>` and `Jalv/<plugin name>`
            plugin_name = snapshot["engine_nick"].split("/")[1]
            if f"lv2/{plugin_name}" in self.plugins_by_name:
                plugin_id = self.plugins_by_name[f"lv2/{plugin_name}"].plugin_id
                logging.info(f"Found ZBP plugin id for plugin when generating snapshot. Translating plugin name {plugin_name} to {plugin_id}")
                snapshot["engine_name"] = f"{snapshot['engine_name'].split('/')[0]}/{plugin_id}"
                snapshot["engine_nick"] = f"{snapshot['engine_nick'].split('/')[0]}/{plugin_id}"
            else:
                logging.info("Plugin name not found in plugin database. Plugin might be added by user. Handle user added plugins accordingly")
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
                logging.info(f"Found ZBP plugin id for plugin when generating snapshot. Translating plugin name {plugin_name} to {plugin.plugin_id}")
                snapshot["bank_name"] = f"{snapshot['bank_name'].split('/')[0]}/{plugin.plugin_id}"
                snapshot["bank_info"][0] = plugin.plugin_id
                snapshot["bank_info"][2] = snapshot["bank_name"]
                snapshot["bank_info"][4] = plugin.plugin_id
                snapshot["preset_info"][0] = snapshot["preset_info"][0].replace(plugin.path, plugin.plugin_id)
            else:
                logging.info("Plugin name not found in plugin database. Plugin might be added by user. Handle user added plugins accordingly")
        return snapshot

    def update_layer_snapshot_plugin_id_to_name(self, snapshot):
        """
        Translate plugin id to plugin name in the layer snapshot
        """
        # Handle Plugin Name substitution for engines having plugin support like (Jalv: lv2, SFizz: sfz, FluidSynth: sf2)
        if snapshot["engine_nick"].startswith("JV/"):
            plugin_id = snapshot["engine_nick"].split("/")[1]
            if plugin_id.startswith("ZBP-"):
                if plugin_id in self.plugins_by_id:
                    # Jalv stores the plugin name in its nickname and name like `JV/<plugin name>` and `Jalv/<plugin name>`
                    plugin_name = self.plugins_by_id[plugin_id].plugin_name
                    logging.info(f"Found ZBP plugin id when restoring snapshot. Translating plugin id {plugin_id} to {plugin_name}")
                    snapshot["engine_name"] = f"{snapshot['engine_name'].split('/')[0]}/{plugin_name}"
                    snapshot["engine_nick"] = f"{snapshot['engine_nick'].split('/')[0]}/{plugin_name}"
                else:
                    logging.error(f"FATAL ERROR : Stored plugin id {plugin_id} is not found and cannot be translated to plugin name. This should not happen unless the files are tampered with.")
        elif snapshot["engine_nick"] == "SF":
            # SFizz stores the plugin name in a few places
            # 1. bank_name: `SFZ/<plugin name>` or `MySFZ/<plugin name>`
            # 2. bank_info[0]: path to plugin `/zynthian/zynthian-data/soundfonts/sfz/<plugin name>`
            # 3. bank_info[2]: same as bank_name
            # 4. bank_info[4]: `<plugin name>`
            # 5. preset_info[0]: `<path to plugin as in bank_info[0]>/...`
            plugin_id = snapshot["bank_name"].split("/")[1]
            if plugin_id.startswith("ZBP-"):
                if plugin_id in self.plugins_by_id:
                    plugin = self.plugins_by_id[plugin_id]
                    logging.info(f"Found ZBP plugin id when restoring snapshot. Translating plugin id {plugin_id} to {plugin.plugin_name}")
                    snapshot["bank_name"] = f"{snapshot['bank_name'].split('/')[0]}/{plugin.plugin_name}"
                    snapshot["bank_info"][0] = plugin.path
                    snapshot["bank_info"][2] = snapshot["bank_name"]
                    snapshot["bank_info"][4] = plugin.plugin_name
                    snapshot["preset_info"][0] = snapshot["preset_info"][0].replace(plugin.plugin_id, plugin.path)
                else:
                    logging.error(f"FATAL ERROR : Stored plugin id {plugin_id} is not found and cannot be translated to plugin name. This should not happen unless the files are tampered with.")

        return snapshot

