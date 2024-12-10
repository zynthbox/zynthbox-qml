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

import sys
import logging
import os
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
        self.__track_colors__ = [QColor("#E6194B"), QColor("#F58231"), QColor("#808000"), QColor("#000075"), QColor("#3CB44B"), QColor("#9A6324"), QColor("#4363D8"), QColor("#911EB4"), QColor("#469990"), QColor("#800000"), QColor("#008000"), QColor("#000080")]
        self.audiofx_layer = None
        self.audiofx_layers = None

        # Prepare installed themes list
        self.fill_list()

        # Read existing config to find previously selected theme name
        try:
            config = ConfigParser()
            config.read("/root/.config/plasmarc")
            selected_theme_name = config["Theme"]["name"]
        except Exception as e:
            # If theme config is not found or unable to read config, force set theme to zynthian
            for index, theme in enumerate(self.list_data):
                if theme[0] == "zynthian":
                    self.select_action(index)
                    break
            selected_theme_name = "zynthian"

        # Select correct index as per previously selected theme
        if selected_theme_name is not None:
            for index, theme in enumerate(self.list_data):
                if selected_theme_name == theme[0]:
                    self.select_action(index)

    def fill_list(self):
        self.list_data=[]

        if Path("/usr/share/plasma/desktoptheme").exists():
            for theme_dir in [f.name for f in os.scandir("/usr/share/plasma/desktoptheme") if f.is_dir()]:
                self.list_data.append((theme_dir,len(self.list_data),theme_dir))

        if Path("/root/.local/share/plasma/desktoptheme").exists():
            for theme_dir in [f.name for f in os.scandir("/root/.local/share/plasma/desktoptheme") if f.is_dir()]:
                self.list_data.append((theme_dir,len(self.list_data),theme_dir))

        super().fill_list()

    @Slot(int)
    def select_action(self, i, t='S'):
        if i < 0 or i >= len(self.list_data):
            return
        self.current_index = i

        config_file = Path("/root/.config/plasmarc")
        config = ConfigParser()
        config.read(config_file)
        if not "Theme" in config:
            config["Theme"] = {}
        config["Theme"]["name"] = self.list_data[self.current_index][0]
        with open(config_file, "w") as fd:
            config.write(fd)

        self.apply_font()

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
