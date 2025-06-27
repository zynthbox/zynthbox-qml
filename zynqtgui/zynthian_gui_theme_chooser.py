#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian GUI Option Selector Class
# 
# Copyright (C) 2021 Marco Martin <mart@kde.org>
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
import os
import json
from pathlib import Path

# Zynthian specific modules
from . import zynthian_gui_selector

from PySide2.QtCore import QSettings, Property, Signal, Slot
from PySide2.QtGui import QGuiApplication, QFontDatabase, QColor
from configparser import ConfigParser


#------------------------------------------------------------------------------
# Zynthian Listing effects for active layer GUI Class
#------------------------------------------------------------------------------

class zynthian_gui_theme_chooser(zynthian_gui_selector):

    def __init__(self, parent = None):
        super(zynthian_gui_theme_chooser, self).__init__('Themes', parent)

        # Basic note colour logic: Hue from 0 through 359, and saturation from 80 through 190 for each of the twelve notes, and value from 155 for the lowest notes (darkest) to 255 for the highest (brightest)
        self.__note_colors__ = [
            QColor.fromHsv(0, 80, 155), QColor.fromHsv(33, 90, 155), QColor.fromHsv(65, 100, 155), QColor.fromHsv(98, 110, 155), QColor.fromHsv(131, 120, 155),QColor.fromHsv(164, 130, 155),
            QColor.fromHsv(196, 140, 155), QColor.fromHsv(229, 150, 155), QColor.fromHsv(262, 160, 155), QColor.fromHsv(295, 170, 155), QColor.fromHsv(327, 180, 155), QColor.fromHsv(359, 190, 155),

            QColor.fromHsv(0, 80, 165), QColor.fromHsv(33, 90, 165), QColor.fromHsv(65, 100, 165), QColor.fromHsv(98, 110, 165), QColor.fromHsv(131, 120, 165),QColor.fromHsv(164, 130, 165),
            QColor.fromHsv(196, 140, 165), QColor.fromHsv(229, 150, 165), QColor.fromHsv(262, 160, 165), QColor.fromHsv(295, 170, 165), QColor.fromHsv(327, 180, 165), QColor.fromHsv(359, 190, 165),

            QColor.fromHsv(0, 80, 175), QColor.fromHsv(33, 90, 175), QColor.fromHsv(65, 100, 175), QColor.fromHsv(98, 110, 175), QColor.fromHsv(175, 120, 175),QColor.fromHsv(164, 130, 175),
            QColor.fromHsv(196, 140, 175), QColor.fromHsv(229, 150, 175), QColor.fromHsv(262, 160, 175), QColor.fromHsv(295, 170, 175), QColor.fromHsv(327, 180, 175), QColor.fromHsv(359, 190, 175),

            QColor.fromHsv(0, 80, 185), QColor.fromHsv(33, 90, 185), QColor.fromHsv(65, 100, 185), QColor.fromHsv(98, 110, 185), QColor.fromHsv(131, 120, 185),QColor.fromHsv(164, 130, 185),
            QColor.fromHsv(196, 140, 185), QColor.fromHsv(229, 150, 185), QColor.fromHsv(262, 160, 185), QColor.fromHsv(295, 170, 185), QColor.fromHsv(327, 180, 185), QColor.fromHsv(359, 190, 185),

            QColor.fromHsv(0, 80, 195), QColor.fromHsv(33, 90, 195), QColor.fromHsv(65, 100, 195), QColor.fromHsv(98, 110, 195), QColor.fromHsv(131, 120, 195),QColor.fromHsv(164, 130, 195),
            QColor.fromHsv(196, 140, 195), QColor.fromHsv(229, 150, 195), QColor.fromHsv(262, 160, 195), QColor.fromHsv(295, 170, 195), QColor.fromHsv(327, 180, 195), QColor.fromHsv(359, 190, 195),

            QColor.fromHsv(0, 80, 205), QColor.fromHsv(33, 90, 205), QColor.fromHsv(65, 100, 205), QColor.fromHsv(98, 110, 205), QColor.fromHsv(131, 120, 205),QColor.fromHsv(164, 130, 205),
            QColor.fromHsv(196, 140, 205), QColor.fromHsv(229, 150, 205), QColor.fromHsv(262, 160, 205), QColor.fromHsv(295, 170, 205), QColor.fromHsv(327, 180, 205), QColor.fromHsv(359, 190, 205),

            QColor.fromHsv(0, 80, 215), QColor.fromHsv(33, 90, 215), QColor.fromHsv(65, 100, 215), QColor.fromHsv(98, 110, 215), QColor.fromHsv(131, 120, 215),QColor.fromHsv(164, 130, 215),
            QColor.fromHsv(196, 140, 215), QColor.fromHsv(229, 150, 215), QColor.fromHsv(262, 160, 215), QColor.fromHsv(295, 170, 215), QColor.fromHsv(327, 180, 215), QColor.fromHsv(359, 190, 215),

            QColor.fromHsv(0, 80, 225), QColor.fromHsv(33, 90, 225), QColor.fromHsv(65, 100, 225), QColor.fromHsv(98, 110, 225), QColor.fromHsv(131, 120, 225),QColor.fromHsv(164, 130, 225),
            QColor.fromHsv(196, 140, 225), QColor.fromHsv(229, 150, 225), QColor.fromHsv(262, 160, 225), QColor.fromHsv(295, 170, 225), QColor.fromHsv(327, 180, 225), QColor.fromHsv(359, 190, 225),

            QColor.fromHsv(0, 80, 235), QColor.fromHsv(33, 90, 235), QColor.fromHsv(65, 100, 235), QColor.fromHsv(98, 110, 235), QColor.fromHsv(131, 120, 235),QColor.fromHsv(164, 130, 235),
            QColor.fromHsv(196, 140, 235), QColor.fromHsv(229, 150, 235), QColor.fromHsv(262, 160, 235), QColor.fromHsv(295, 170, 235), QColor.fromHsv(327, 180, 235), QColor.fromHsv(359, 190, 235),

            QColor.fromHsv(0, 80, 245), QColor.fromHsv(33, 90, 245), QColor.fromHsv(65, 100, 245), QColor.fromHsv(98, 110, 245), QColor.fromHsv(131, 120, 245),QColor.fromHsv(164, 130, 245),
            QColor.fromHsv(196, 140, 245), QColor.fromHsv(229, 150, 245), QColor.fromHsv(262, 160, 245), QColor.fromHsv(295, 170, 245), QColor.fromHsv(327, 180, 245), QColor.fromHsv(359, 190, 245),

            QColor.fromHsv(0, 80, 255), QColor.fromHsv(33, 90, 255), QColor.fromHsv(65, 100, 255), QColor.fromHsv(98, 110, 255), QColor.fromHsv(131, 120, 255),QColor.fromHsv(164, 130, 255),
            QColor.fromHsv(196, 140, 255), QColor.fromHsv(229, 150, 255)
            ]
        self.__track_colors__ = [QColor("#B34D00"), QColor("#B37A00"), QColor("#B39D00"), QColor("#7CB301"), QColor("#008F00"), QColor("#006642"), QColor("#4F0099"), QColor("#7A00AB"), QColor("#B000A7"), QColor("#E60000"), QColor("#000000"), QColor("#808080")]
        self.audiofx_layer = None
        self.audiofx_layers = None
        self.selected_theme_name = None
        self.theme_base_dirs = ["/usr/share/plasma/desktoptheme", "/root/.local/share/plasma/desktoptheme"]

        # Prepare installed themes list
        self.fill_list()

        # Read existing config to find previously selected theme name
        try:
            config = ConfigParser()
            config.read("/root/.config/plasmarc")
            self.selected_theme_name = config["Theme"]["name"]
        except: pass

        # Check if current selected theme is valid or not. Select appropriate if necessary
        self.check_current_selected_theme()

    def show(self):
        self.select(-1)
        for index, theme in enumerate(self.list_data):
            if theme[0] == self.selected_theme_name:
                self.select(index)
                break

        super().show()

    def check_current_selected_theme(self):
        selected_theme_exists = False
        switch_theme_to = None

        # Check if the selected theme exists in system
        if self.selected_theme_name is not None:
            for theme_base_dir in self.theme_base_dirs:
                if (Path(theme_base_dir) / self.selected_theme_name).exists():
                    selected_theme_exists = True

        # TODO : 1.0 Before releasing, remove the fallback logic and directly set to zynthbox-theme-v1
        # zynthian theme has been renamed to zynthbox-theme-v1
        # If selected theme is zynthian and zynthbox-theme-v1 exists, switch to zynthbox-theme-v1
        if selected_theme_exists and self.selected_theme_name == "zynthian" and Path("/usr/share/plasma/desktoptheme/zynthbox-theme-v1").exists():
            switch_theme_to = "zynthbox-theme-v1"
        elif not selected_theme_exists:
            if Path("/usr/share/plasma/desktoptheme/zynthbox-theme-v1").exists():
                switch_theme_to = "zynthbox-theme-v1"
            elif Path("/usr/share/plasma/desktoptheme/zynthian").exists():
                switch_theme_to = "zynthian"

        if switch_theme_to is not None:
            logging.debug(f"Switching theme to {switch_theme_to}")
            self.apply_theme(switch_theme_to)

    def get_theme_name(self, theme_base_dir, theme_dir_name):
        theme_name = None

        # Check if metadata.desktop exists and try reading name
        metadata_path = Path(theme_base_dir) / theme_dir_name / "metadata.desktop"
        try:
            if metadata_path.exists():
                config = ConfigParser()
                config.read(metadata_path)
                theme_name = config["Desktop Entry"]["Name"]
        except: pass

        # If above failed, try checking if metadata.json exists and try reading name
        if theme_name is None:
            metadata_path = Path(theme_base_dir) / theme_dir_name / "metadata.json"
            try:
                if metadata_path.exists():
                    with open(metadata_path, "r") as f:
                        config = json.load(f)
                        theme_name = config["KPlugin"]["Name"]
            except: pass

        # If still failed, fallback to dir name
        if theme_name is None:
            theme_name = theme_dir_name

        return theme_name

    def fill_list(self):
        self.list_data=[]

        for theme_base_dir in self.theme_base_dirs:
            if Path(theme_base_dir).exists():
                for theme_dir in [f.name for f in os.scandir(theme_base_dir) if f.is_dir()]:
                    self.list_data.append((theme_dir,len(self.list_data),self.get_theme_name(theme_base_dir, theme_dir)))

        super().fill_list()

    def select(self, index=None):
        super().select(index)

    @Slot(int)
    def select_action(self, i, t='S'):
        if i < 0 or i >= len(self.list_data):
            return
        self.select(i)
        self.apply_theme(self.list_data[self.current_index][0])
        self.apply_font()

    def apply_theme(self, theme_name):
        config_file = Path("/root/.config/plasmarc")
        config = ConfigParser()
        config.read(config_file)
        if not "Theme" in config:
            config["Theme"] = {}
        config["Theme"]["name"] = theme_name
        with open(config_file, "w") as fd:
            config.write(fd)
        self.selected_theme_name = theme_name

    def apply_font(self):
        plasma_settings = QSettings("/root/.config/plasmarc", QSettings.IniFormat)
        if plasma_settings.status() != QSettings.NoError:
            self.apply_default_font()
            return

        plasma_settings.beginGroup("Theme")
        theme_name = plasma_settings.value("name")

        if theme_name is None:
            self.apply_default_font()
            return
        theme_path = "/root/.local/share/plasma/desktoptheme/" + theme_name
        plasma_settings.endGroup()

        if not Path(theme_path).exists():
            theme_path = "/usr/share/plasma/desktoptheme/" + theme_name
            if not Path(theme_path).exists():
                self.apply_default_font()
                return

        font_config_path = theme_path + "/zynthian-config"
        if not Path(font_config_path).exists():
            self.apply_default_font()
            return

        font_settings = QSettings(font_config_path, QSettings.IniFormat)
        if font_settings.status() != QSettings.NoError:
            self.apply_default_font()
            return

        font_settings.beginGroup("Font")
        font_file = font_settings.value("files")
        if font_file is None:
            self.apply_default_font()
            return
        # TODO: support more files
        font_file_path = theme_path + "/fonts/" + font_file
        if not Path(font_file_path).exists():
            self.apply_default_font()
            return
        QFontDatabase.addApplicationFont(font_file_path)

        app = QGuiApplication.instance()
        font = app.font()
        font.setFamily(font_settings.value("family", "Roboto"))
        font.setPointSize(int(font_settings.value("size", 12)))
        app.setFont(font)

        font_settings.endGroup()


    def apply_default_font(self):
        app = QGuiApplication.instance()
        font = app.font()
        font.setFamily("Roboto")
        font.setPointSize(12)
        app.setFont(font)


    def set_select_path(self):
        self.select_path = "Theme"
        super().set_select_path()

    ### BEGIN Property noteColors
    def get_note_colors(self):
        return self.__note_colors__

    def set_note_colors(self, noteColors):
        self.__note_colors__ = noteColors
        self.note_colors_changed.emit()
        pass

    note_colors_changed = Signal()

    noteColors = Property('QVariantList', get_note_colors, set_note_colors, notify=note_colors_changed)
    ### END Property noteColors

    ### BEGIN Property trackColors
    def get_track_colors(self):
        return self.__track_colors__

    def set_track_colors(self, trackColors):
        self.__track_colors__ = trackColors
        self.track_colors_changed.emit()
        pass

    track_colors_changed = Signal()

    trackColors = Property('QVariantList', get_track_colors, set_track_colors, notify=track_colors_changed)
    ### END Property trackColors
#------------------------------------------------------------------------------
