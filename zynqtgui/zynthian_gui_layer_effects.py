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

		self.midi_mode = False
		self.types_screen = "effect_types"
		self.effect_chooser_screen = "layer_effect_chooser"
		self.fx_layer = None
		self.fx_layers = None

	def show(self):
		if self.midi_mode:
			self.types_screen = "midi_effect_types"
			self.effect_chooser_screen = "layer_midi_effect_chooser"
		else:
			self.types_screen = "effect_types"
			self.effect_chooser_screen = "layer_effect_chooser"
		self.zyngui.screens[self.types_screen].show()
		self.zyngui.screens[self.effect_chooser_screen].show()
		super().show()

	def fill_list(self):
		self.list_data=[]

		if self.midi_mode:
			self.fx_layers = self.zyngui.screens['layer'].get_midichain_layers(self.zyngui.curlayer)
		else:
			self.fx_layers = self.zyngui.screens['layer'].get_fxchain_layers(self.zyngui.curlayer)
		if self.fx_layers and len(self.fx_layers) > 0:
			self.fx_layers.remove(self.zyngui.curlayer)

		if len(self.fx_layers) > 0:
			# Add Audio-FX layers
			sl0 = None

			for sl in self.fx_layers:
				if self.midi_mode:
					if sl.is_parallel_midi_routed(sl0):
						bullet = " || "
					else:
						bullet = " -> "
				else:
					if sl.is_parallel_audio_routed(sl0):
						bullet = " || "
					else:
						bullet = " -> "
				self.list_data.append((self.fx_layer_action, sl, bullet + sl.engine.get_path(sl)))
				sl0 = sl


		if self.midi_mode:
			if len(self.fx_layers) > 0:
				self.list_data.append(('ADD-SERIAL-FX',len(self.list_data),"Add Serial Midi-FX"))
				self.list_data.append(('ADD-PARALLEL-FX',len(self.list_data),"Add Parallel Midi-FX"))
				self.list_data.append(('CLEAR-FX',len(self.list_data),"Remove All Midi-FX"))
			else:
				self.list_data.append(('ADD-SERIAL-FX',len(self.list_data),"Add Midi-FX"))
				self.select_action(0)
				self.zyngui.screens[self.types_screen].select_action(0)
		else:
			if len(self.fx_layers) > 0:
				self.list_data.append(('ADD-SERIAL-FX',len(self.list_data),"Add Serial Audio-FX"))
				self.list_data.append(('ADD-PARALLEL-FX',len(self.list_data),"Add Parallel Audio-FX"))
				self.list_data.append(('CLEAR-FX',len(self.list_data),"Remove All Audio-FX"))
			else:
				self.list_data.append(('ADD-SERIAL-FX',len(self.list_data),"Add Audio-FX"))
				self.select_action(0)
				self.zyngui.screens[self.types_screen].select_action(0)

		super().fill_list()

	def get_effective_count(self):
		return len(self.fx_layers)

	def back_action(self):
		return 'preset'

	def next_action(self):
		return self.types_screen

	def select_action(self, i, t='S'):
		if i < 0 or i >= len(self.list_data):
			return

		if self.list_data[i][0] == 'CLEAR-FX':
			self.fx_reset()
			return
		elif self.list_data[i][0] == 'ADD-SERIAL-FX':
			self.zyngui.screens[self.effect_chooser_screen].layer_chain_parallel = False

		elif self.list_data[i][0] == 'ADD-PARALLEL-FX':
			self.zyngui.screens[self.effect_chooser_screen].layer_chain_parallel = True

		if i < len(self.fx_layers):
			self.fx_layer = self.fx_layers[i]
			if t is 'B':
				self.zyngui.show_confirm("Do you really want to remove This effect?", self.fx_remove_confirmed)
		else:
			self.fx_layer = None

		if self.fx_layer != None:
			self.zyngui.screens[self.types_screen].show()
		self.set_select_path()


	def index_supports_immediate_activation(self, index=None):
		return index >= 0 and index < len(self.fx_layers)

	def fx_layer_action(self, layer, t='S'):
		self.fx_layer = layer
		self.fx_layer_index = self.zyngui.screens['layer'].layers.index(layer)
		self.show()

	def fx_reset(self):
		if self.midi_mode:
			self.zyngui.show_confirm("Do you really want to remove all Midi-FXs for this layer?", self.fx_reset_confirmed)
		else:
			self.zyngui.show_confirm("Do you really want to remove all Audio-FXs for this layer?", self.fx_reset_confirmed)


	def fx_remove_confirmed(self, params=None):
		if self.fx_layer is None:
			return
		i = self.zyngui.screens['layer'].layers.index(self.fx_layer)
		self.zyngui.screens['layer'].remove_layer(i)

		self.fx_layer = None
		self.fill_list()
		self.zyngui.screens['main_layers_view'].fill_list()


	def fx_reset_confirmed(self, params=None):
		# Remove all layers
		for sl in self.fx_layers:
			i = self.zyngui.screens['layer'].layers.index(sl)
			self.zyngui.screens['layer'].remove_layer(i)

		self.fx_layer = None
		self.fill_list()

	def index_supports_immediate_activation(self, index=None):
		return True

	def set_select_path(self):
		if self.midi_mode:
			if self.zyngui.curlayer:
				self.select_path = self.zyngui.curlayer.get_basepath() + " Midi-FX"
			else:
				self.select_path = "Midi-FX"
		else:
			if self.zyngui.curlayer:
				self.select_path = self.zyngui.curlayer.get_basepath() + " Audio-FX"
			else:
				self.select_path = "Audio-FX"
		if len(self.fx_layers) > 0:
			self.select_path_element = "FX {}".format(min(self.index, len(self.fx_layers) - 1) + 1)
		else:
			if self.midi_mode:
				self.select_path_element = "Choose Midi-FX"
			else:
				self.select_path_element = "Choose Audio-FX"
		super().set_select_path()

#------------------------------------------------------------------------------
