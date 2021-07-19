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
		f.close()



	def set_select_path(self):
		self.select_path = "Theme"
		super().set_select_path()

#------------------------------------------------------------------------------
