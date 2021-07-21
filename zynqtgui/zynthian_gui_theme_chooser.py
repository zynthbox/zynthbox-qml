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

from PySide2.QtCore import QSettings
from PySide2.QtGui import QGuiApplication, QFontDatabase


#------------------------------------------------------------------------------
# Zynthian Listing effects for active layer GUI Class
#------------------------------------------------------------------------------

class zynthian_gui_theme_chooser(zynthian_gui_selector):

	def __init__(self, parent = None):
		super(zynthian_gui_theme_chooser, self).__init__('Themes', parent)

		self.audiofx_layer = None
		self.audiofx_layers = None


	def fill_list(self):
		self.list_data=[]

		if Path("/usr/share/plasma/desktoptheme").exists():
			for theme_dir in [f.name for f in os.scandir("/usr/share/plasma/desktoptheme") if f.is_dir()]:
				self.list_data.append((theme_dir,len(self.list_data),theme_dir))

		if Path("/root/.local/share/plasma/desktoptheme").exists():
			for theme_dir in [f.name for f in os.scandir("/root/.local/share/plasma/desktoptheme") if f.is_dir()]:
				self.list_data.append((theme_dir,len(self.list_data),theme_dir))

		super().fill_list()


	def select_action(self, i, t='S'):
		if i < 0 or i >= len(self.list_data):
			return
		f = open("/root/.config/plasmarc", "w")
		f.write("[Theme]\nname={}".format(self.list_data[i][0]))
		self.apply_font()
		f.close()



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

		font_config_path = theme_path + "/fonts"
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
		font_file_path = theme_path + "/" + font_file
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

#------------------------------------------------------------------------------
