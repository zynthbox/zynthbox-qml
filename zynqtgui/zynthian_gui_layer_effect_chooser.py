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
		self.layer_chain_parallel = False

		self.single_category = "    " # Hack to get an empty list
		if self.zyngui.curlayer:
			self.set_fxchain_mode(self.zyngui.curlayer.midi_chan)


	def show(self):
		if self.zyngui.curlayer:
			self.set_fxchain_mode(self.zyngui.curlayer.midi_chan)
			self.reset_index = False

		super().show()

		if self.zyngui.screens['layer_effects'].audiofx_layer != None:
			for i, item in enumerate(self.list_data):
				if item[0] == self.zyngui.screens['layer_effects'].audiofx_layer.engine.get_path(self.zyngui.screens['layer_effects'].audiofx_layer):
					self.select(i)
					return

				self.select(0)
		else:
			self.select(-1)


	def select_action(self, i, t='S'):
		if i is not None and self.list_data[i][0]:
			self.zyngui.start_loading()
			if self.zyngui.screens['layer_effects'].audiofx_layer != None and self.zyngui.screens['layer_effects'].audiofx_layer in self.zyngui.screens['layer'].layers:
				self.zyngui.screens['layer'].replace_layer_index = self.zyngui.screens['layer'].layers.index(self.zyngui.screens['layer_effects'].audiofx_layer)

			else:
				self.zyngui.screens['layer'].replace_layer_index = None

			self.zyngui.screens['layer'].layer_chain_parallel = self.layer_chain_parallel

			self.zyngui.screens['layer'].add_layer_engine(self.list_data[i][0], self.zyngui.curlayer.midi_chan, False)

			self.zyngui.screens['layer_effects'].show()

			if self.zyngui.screens['layer'].replace_layer_index is None:
				self.zyngui.screens['layer_effects'].select_action(len(self.zyngui.screens['layer_effects'].audiofx_layers) - 1)
			else:
				self.zyngui.screens['layer_effects'].select_action(self.zyngui.screens['layer'].replace_layer_index)

			self.zyngui.screens['layer'].replace_layer_index = None

			self.zyngui.screens['main_layers_view'].fill_list()
			self.zyngui.stop_loading()


	def back_action(self):
		return 'effect_types'


	def set_select_path(self):
		self.select_path = ''
		if self.zyngui.screens['layer_effects'].audiofx_layer != None:
			self.select_path = self.engine_info[self.zyngui.screens['layer_effects'].audiofx_layer.engine.get_path(self.zyngui.screens['layer_effects'].audiofx_layer)][0]
		self.selector_path_changed.emit()
		self.selector_path_element_changed.emit()

#------------------------------------------------------------------------------
