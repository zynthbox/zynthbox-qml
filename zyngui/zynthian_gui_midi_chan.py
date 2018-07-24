#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian GUI Midi-Channel Selector Class
# 
# Copyright (C) 2015-2016 Fernando Moyano <jofemodo@zynthian.org>
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
from zyncoder import *
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

class zynthian_gui_midi_chan(zynthian_gui_selector):

	def __init__(self, max_chan=16):
		self.mode='ADD'
		self.max_chan=max_chan
		super().__init__('Channel', True)

	def set_mode(self, mode, midich=None):
		self.mode=mode
		if self.mode=='ADD':
			self.listbox.config(selectmode='browse')
		elif self.mode=='SET':
			self.listbox.config(selectmode='browse')
			self.index=midich
		elif self.mode=='CLONE':
			self.listbox.config(selectmode='browse')
			self.midi_chan=midich

	def fill_list(self):
		self.list_data=[]
		if self.mode=='ADD' or self.mode=='SET':
			for i in range(self.max_chan):
				self.list_data.append((str(i+1),i,"MIDI CH#"+str(i+1)))
		elif self.mode=='CLONE':
			for i in range(self.max_chan):
				if i==self.midi_chan:
					self.list_data.append((str(i+1),i,"MIDI CH#"+str(i+1)+" ->"))
				elif zyncoder.lib_zyncoder.get_midi_filter_clone(self.midi_chan, i):
					self.list_data.append((str(i+1),i,"-> MIDI CH#"+str(i+1)))
				else:
					self.list_data.append((str(i+1),i,"MIDI CH#"+str(i+1)))
		super().fill_list()

	def fill_listbox(self):
		super().fill_listbox()
		if self.mode=='CLONE':
			self.index=self.highlight_cloned()

	# Highlight current channels to which is cloned to ...
	def highlight_cloned(self):
		last=0
		for i in range(self.max_chan):
			if self.list_data[i][2][-2:]=='->':
				self.listbox.itemconfig(i, {'bg':zynthian_gui_config.color_hl})
			elif self.list_data[i][2][:2]=='->':
				self.listbox.itemconfig(i, {'fg':zynthian_gui_config.color_hl})
				last=i
			else:
				self.listbox.itemconfig(i, {'fg':zynthian_gui_config.color_panel_tx})
		return last

	def select_action(self, i):
		if self.mode=='ADD':
			zynthian_gui_config.zyngui.screens['layer'].add_layer_midich(self.list_data[i][1])
		elif self.mode=='SET':
			layer_index=zynthian_gui_config.zyngui.screens['layer_options'].layer_index
			zynthian_gui_config.zyngui.screens['layer'].layers[layer_index].set_midi_chan(self.list_data[i][1])
			zynthian_gui_config.zyngui.show_screen('layer')
		elif self.mode=='CLONE':
			if self.list_data[i][1]!=self.midi_chan:
				if zyncoder.lib_zyncoder.get_midi_filter_clone(self.midi_chan, self.list_data[i][1]):
					zyncoder.lib_zyncoder.set_midi_filter_clone(self.midi_chan, self.list_data[i][1], 0)
					self.fill_list()
				else:
					zyncoder.lib_zyncoder.set_midi_filter_clone(self.midi_chan, self.list_data[i][1], 1)
					self.fill_list()

	def set_select_path(self):
		if self.mode=='ADD' or self.mode=='SET':
			self.select_path.set("MIDI Channel")
		elif self.mode=='CLONE':
			self.select_path.set("MIDI Channel {} Clone to ...".format(self.midi_chan+1))

#------------------------------------------------------------------------------
