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
            self.plugins_by_name[plugins_json[key]["plugin_name"]] = plugin
