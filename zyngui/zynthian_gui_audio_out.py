#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian GUI Audio-out Selector Class
# 
# Copyright (C) 2015-2018 Fernando Moyano <jofemodo@zynthian.org>
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
import tkinter
import logging

# Zynthian specific modules
import zynautoconnect
from . import zynthian_gui_config
from . import zynthian_gui_selector

#------------------------------------------------------------------------------
# Configure logging
#------------------------------------------------------------------------------

# Set root logging level
logging.basicConfig(stream=sys.stderr, level=zynthian_gui_config.log_level)

#------------------------------------------------------------------------------
# Zynthian MIDI Channel Selection GUI Class
#------------------------------------------------------------------------------

class zynthian_gui_audio_out(zynthian_gui_selector):

	def __init__(self):
		self.layer=None
		super().__init__('Audio Out', True)


	def set_layer(self, layer):
		self.layer = layer


	def fill_list(self):
		self.list_data = []

		for k in zynautoconnect.get_audio_input_ports().keys():
			if k != self.layer.get_jackname():
				if k in self.layer.get_audio_out():
					self.list_data.append((k,k,"-> " + k))
				else:
					self.list_data.append((k,k,k))

		super().fill_list()


	def fill_listbox(self):
		super().fill_listbox()
		self.index=self.highlight()


	# Highlight current engine assigned outputs ...
	def highlight(self):
		last=0
		for i in range(len(self.list_data)):
			if self.list_data[i][2][:2]=='->':
				self.listbox.itemconfig(i, {'fg':zynthian_gui_config.color_hl})
				last=i
			else:
				self.listbox.itemconfig(i, {'fg':zynthian_gui_config.color_panel_tx})
		return last


	def select_action(self, i):
		self.layer.toggle_audio_out(self.list_data[i][1])
		self.fill_list()


	def set_select_path(self):
		if self.layer and self.layer.get_basepath():
			self.select_path.set("Audio from {} to ...".format(self.layer.get_basepath()))
		else:
			self.select_path.set("Audio Routing ...")

#------------------------------------------------------------------------------
