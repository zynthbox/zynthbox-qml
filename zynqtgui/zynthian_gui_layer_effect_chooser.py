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

# Zynthian specific modules
from . import zynthian_gui_engine

#------------------------------------------------------------------------------
# Zynthian Option Selection GUI Class
#------------------------------------------------------------------------------

class zynthian_gui_layer_effect_chooser(zynthian_gui_engine):

	def __init__(self, parent = None):
		super(zynthian_gui_layer_effect_chooser, self).__init__(parent)

		self.selector_caption = "FX"

		self.single_category = "    " # Hack to get an empty list
		if self.zyngui.curlayer:
			self.set_fxchain_mode(self.zyngui.curlayer.midi_chan)

	def select_action(self, i, t='S'):
		if i is not None and self.list_data[i][0]:
			self.zyngui.start_loading()
			if self.zyngui.screens['layer_effects'].audiofx_layer != None:
				self.zyngui.screens['layer'].replace_layer_index = self.zyngui.screens['layer'].layers.index(self.zyngui.screens['layer_effects'].audiofx_layer)

			else:
				self.zyngui.screens['layer'].replace_layer_index = None
			self.zyngui.screens['layer'].add_layer_engine(self.list_data[i][0], self.zyngui.curlayer.midi_chan, False)
			self.zyngui.screens['layer'].replace_layer_index = None
			self.zyngui.screens['layer_effects'].show()
			self.zyngui.stop_loading()

	def back_action(self):
		self.zyngui.show_modal('effect_types')

	def show(self):
		if self.zyngui.curlayer:
			self.set_fxchain_mode(self.zyngui.curlayer.midi_chan)
		super().show()

	def set_select_path(self):
		self.select_path = "FX"
		self.selector_path_changed.emit()
		self.selector_path_element_changed.emit()

#------------------------------------------------------------------------------
