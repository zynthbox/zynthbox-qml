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

		self.list_data.append(('ADD-AUDIOFX',len(self.list_data),"Add Audio-FX"))
		self.list_data.append(('CLEAR-AUDIOFX',len(self.list_data),"Remove All Audio-FX"))

		super().fill_list()
		self.select_action(0)


	def next_action(self):
		return 'effect_types'

	def select_action(self, i, t='S'):
		if self.list_data[i][0] == 'CLEAR-AUDIOFX':
			self.audiofx_reset()
			return
		elif self.list_data[i][0] == 'ADD-AUDIOFX':
			self.zyngui.screens['effect_types'].index = -1
			self.zyngui.screens['effect_types'].show()
			self.zyngui.screens['layer_effect_chooser'].single_category = "    "
			self.zyngui.screens['layer_effect_chooser'].show()

		if i < len(self.audiofx_layers):
			self.audiofx_layer = self.audiofx_layers[i]

		else:
			self.audiofx_layer = None

		if self.audiofx_layer != None:
			self.zyngui.screens['effect_types'].select_category_by_name(self.zyngui.screens['effect_types'].engine_info[self.audiofx_layer.engine.get_path(self.audiofx_layer)][3])


	def index_supports_immediate_activation(self, index=None):
		return index >= 0 and index < len(self.audiofx_layers)

	def audiofx_layer_action(self, layer, t='S'):
		self.index = 0
		self.audiofx_layer = layer
		self.audiofx_layer_index = self.zyngui.screens['layer'].layers.index(layer)
		self.show()

	def audiofx_reset(self):
		self.zyngui.show_confirm("Do you really want to remove all audio-FXs for this layer?", self.audiofx_reset_confirmed)


	def audiofx_reset_confirmed(self, params=None):
		# Remove all layers
		for sl in self.audiofx_layers:
			i = self.zyngui.screens['layer'].layers.index(sl)
			self.zyngui.screens['layer'].remove_layer(i)

		self.reset()
		self.show()


	def set_select_path(self):
		self.select_path = self.zyngui.curlayer.get_basepath() + " Audio-FX"
		super().set_select_path()

#------------------------------------------------------------------------------
