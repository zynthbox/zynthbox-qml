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
from . import zynthian_gui_layer
from . import zynthian_gui_selector

#------------------------------------------------------------------------------
# Zynthian Option Selection GUI Class
#------------------------------------------------------------------------------

class zynthian_gui_fixed_layers(zynthian_gui_layer):

	def __init__(self, parent = None):
		super(zynthian_gui_fixed_layers, self).__init__(parent)

		self.fixed_layers_count = 6
		self.layer_map = {}

	def fill_list(self):
		self.list_data=[]

		# Get list of root layers
		self.root_layers=self.get_fxchain_roots()

		self.layer_map = {}
		for layer in self.root_layers:
			self.layer_map[layer.midi_chan] = layer

		for i in range(6): #FIXME
			if i in self.layer_map:
				self.list_data.append((str(i+1),i,self.layer_map[i].get_presetpath()))
			else:
				self.list_data.append((str(i+1),i, "{}#  - -  ".format(i+1)))

		zynthian_gui_selector.fill_list(self)


	def select_action(self, i, t='S'):
		if i in self.layer_map:
			layer = self.layer_map[i]
			self.zyngui.layer_control(layer)
		else:
			self.add_layer_eng = None
			self.replace_layer_index = None
			self.layer_chain_parallel = False
			self.zyngui.screens['engine'].set_engine_type("MIDI Synth")
			self.layer_index_replace_engine = self.index
			self.zyngui.screens['engine'].set_midi_channel(self.index)
			self.zyngui.show_modal('engine')


	def back_action(self):
		return 'main'

	def next_action(self):
		return 'bank'


	def index_supports_immediate_activation(self, index=None):
		return False


#------------------------------------------------------------------------------
