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
from . import zynthian_gui_selector

#------------------------------------------------------------------------------
# Zynthian Listing effects for active layer GUI Class
#------------------------------------------------------------------------------

class zynthian_gui_layer_effects(zynthian_gui_selector):

	def __init__(self, parent = None):
		super(zynthian_gui_layer_effects, self).__init__('Active FX', parent)

		self.audiofx_layer = None
		self.audiofx_layers = None

	def show(self):
		self.zyngui.screens['effect_types'].show()
		self.zyngui.screens['layer_effect_chooser'].show()
		super().show()

	def fill_list(self):
		self.list_data=[]

		self.audiofx_layers = self.zyngui.screens['layer'].get_fxchain_layers(self.zyngui.curlayer)
		if self.audiofx_layers and len(self.audiofx_layers) > 0:
			self.audiofx_layers.remove(self.zyngui.curlayer)

		if len(self.audiofx_layers) > 0:
			# Add Audio-FX layers
			sl0 = None

			for sl in self.audiofx_layers:
				if sl.is_parallel_audio_routed(sl0):
					bullet = " || "
				else:
					bullet = " -> "
				self.list_data.append((self.audiofx_layer_action, sl, bullet + sl.engine.get_path(sl)))
				sl0 = sl


		if len(self.audiofx_layers) > 0:
			self.list_data.append(('ADD-SERIAL-AUDIOFX',len(self.list_data),"Add Serial Audio-FX"))
			self.list_data.append(('ADD-PARALLEL-AUDIOFX',len(self.list_data),"Add Parallel Audio-FX"))
			self.list_data.append(('CLEAR-AUDIOFX',len(self.list_data),"Remove All Audio-FX"))
		else:
			self.list_data.append(('ADD-SERIAL-AUDIOFX',len(self.list_data),"Add Audio-FX"))
			self.select_action(0)
			self.zyngui.screens['effect_types'].select_action(0)

		super().fill_list()

	def get_effective_count(self):
		return len(self.audiofx_layers)

	def back_action(self):
		return 'preset'

	def next_action(self):
		return 'effect_types'

	def select_action(self, i, t='S'):
		if i < 0 or i >= len(self.list_data):
			return

		if self.list_data[i][0] == 'CLEAR-AUDIOFX':
			self.audiofx_reset()
			return
		elif self.list_data[i][0] == 'ADD-SERIAL-AUDIOFX':
			self.zyngui.screens['layer_effect_chooser'].layer_chain_parallel = False

		elif self.list_data[i][0] == 'ADD-PARALLEL-AUDIOFX':
			self.zyngui.screens['layer_effect_chooser'].layer_chain_parallel = True

		if i < len(self.audiofx_layers):
			self.audiofx_layer = self.audiofx_layers[i]
			if t is 'B':
				self.zyngui.show_confirm("Do you really want to remove This effect?", self.fx_remove_confirmed)
		else:
			self.audiofx_layer = None

		if self.audiofx_layer != None:
			self.zyngui.screens['effect_types'].show()
		self.set_select_path()


	def index_supports_immediate_activation(self, index=None):
		return index >= 0 and index < len(self.audiofx_layers)

	def audiofx_layer_action(self, layer, t='S'):
		self.audiofx_layer = layer
		self.audiofx_layer_index = self.zyngui.screens['layer'].layers.index(layer)
		self.show()

	def audiofx_reset(self):
		self.zyngui.show_confirm("Do you really want to remove all audio-FXs for this layer?", self.audiofx_reset_confirmed)


	def fx_remove_confirmed(self, params=None):
		if self.audiofx_layer is None:
			return
		i = self.zyngui.screens['layer'].layers.index(self.audiofx_layer)
		self.zyngui.screens['layer'].remove_layer(i)

		self.audiofx_layer = None
		self.fill_list()
		self.zyngui.screens['main_layers_view'].fill_list()


	def audiofx_reset_confirmed(self, params=None):
		# Remove all layers
		for sl in self.audiofx_layers:
			i = self.zyngui.screens['layer'].layers.index(sl)
			self.zyngui.screens['layer'].remove_layer(i)

		self.audiofx_layer = None
		self.fill_list()


	def set_select_path(self):
		self.select_path = self.zyngui.curlayer.get_basepath() + " Audio-FX"
		if len(self.audiofx_layers) > 0:
			self.select_path_element = "FX {}".format(min(self.index, len(self.audiofx_layers) - 1) + 1)
		else:
			self.select_path_element = "Choose Audio-FX"
		super().set_select_path()

#------------------------------------------------------------------------------
