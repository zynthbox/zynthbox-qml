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

class zynthian_gui_effect_types(zynthian_gui_engine):

	def __init__(self, parent = None):
		super(zynthian_gui_effect_types, self).__init__(parent)

		self.selector_caption = "FX Type"

		if self.zyngui.curlayer:
			self.set_fxchain_mode(self.zyngui.curlayer.midi_chan)
		self.only_categories = True


	def show(self):
		if self.zyngui.curlayer:
			self.set_fxchain_mode(self.zyngui.curlayer.midi_chan)
		super().show()
		self.select_action(self.index)


	def select_action(self, i, t='S'):
		if i is not None and self.list_data[i][0]:
			self.zyngui.screens['layer_effect_chooser'].single_category = self.list_data[i][0]
			self.zyngui.screens['layer_effect_chooser'].show()
		self.set_select_path()


	def back_action(self):
		return 'layer_effects'

	def next_action(self):
		return 'layer_effect_chooser'


	def index_supports_immediate_activation(self, index=None):
		return True


	def select_category_by_name(self, cat):
		for i, item in enumerate(self.list_data):
			if item[2] == cat:
				self.activate_index(i)
				return


	def set_select_path(self):
		self.select_path = self.zyngui.curlayer.get_basepath() + " Audio-FX > " + self.list_data[self.index][2]
		self.select_path_element = self.list_data[self.index][2]
		self.selector_path_changed.emit()
		self.selector_path_element_changed.emit()

#------------------------------------------------------------------------------
