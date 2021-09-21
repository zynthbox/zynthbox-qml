#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian GUI Bank Selector Class
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
import logging

# Zynthian specific modules
from . import zynthian_gui_config
from . import zynthian_gui_selector

# Qt modules
from PySide2.QtCore import Qt, QObject, Slot, Signal, Property

#------------------------------------------------------------------------------
# Zynthian Bank Selection GUI Class
#------------------------------------------------------------------------------

class zynthian_gui_bank(zynthian_gui_selector):

	buttonbar_config = [
		(1, 'BACK'),
		(0, 'LAYER'),
		(2, 'FAVS'),
		(3, 'SELECT')
	]

	def __init__(self, parent = None):
		super(zynthian_gui_bank, self).__init__('Bank', parent)
		self.__show_top_sounds = False
		self.auto_next_screen = False
		self.show()


	def fill_list(self):
		self.list_data = []
		if self.__show_top_sounds:
			self.zyngui.screens['preset'].reload_top_sounds()
			top_sounds = self.zyngui.screens['preset'].get_all_top_sounds()
			for engine in top_sounds:
				parts = engine.split("/")
				readable_name = engine
				if len(parts) > 1:
					parts[1]
				self.list_data.append((engine, len(self.list_data), "{} ({})".format(readable_name, len(top_sounds[engine]))))
		else:
			if not self.zyngui.curlayer:
				logging.error("Can't fill bank list for None layer!")
				super().fill_list()
				return
			self.zyngui.curlayer.load_bank_list()
			self.list_data = self.zyngui.curlayer.bank_list
		super().fill_list()

	def get_show_top_sounds(self):
		return self.__show_top_sounds

	def set_show_top_sounds(self, show : bool):
		if self.__show_top_sounds == show:
			return
		self.__show_top_sounds = show
		self.fill_list()
		self.show()
		bank_found = False
		if show and self.zyngui.curlayer:
			top_sounds = self.zyngui.screens['preset'].get_all_top_sounds()
			for i, engine in enumerate(top_sounds):
				if engine == self.zyngui.curlayer.engine.nickname:
					self.select_action(i)
					bank_found = True
					break
			self.zyngui.screens['preset'].select(-1)
			for i, preset in enumerate(self.zyngui.screens['preset'].list_data):
				if preset[2] == self.zyngui.curlayer.preset_name:
					self.zyngui.screens['preset'].select_action(i)
					break
		elif self.zyngui.curlayer:
			self.zyngui.screens['preset'].set_top_sounds_engine(None)
			for i, bank in enumerate(self.list_data):
				if bank[2] == self.zyngui.curlayer.bank_name:
					self.select_action(i)
					bank_found = True
					break
			self.zyngui.screens['preset'].select(-1)
			for i, preset in enumerate(self.zyngui.screens['preset'].list_data):
				if preset[2] == self.zyngui.curlayer.preset_name:
					self.zyngui.screens['preset'].select_action(i)
					break
		else:
			self.zyngui.screens['preset'].set_top_sounds_engine(None)
			self.zyngui.screens['preset'].fill_list()
		if not bank_found:
			self.select_action(0)
			self.zyngui.screens['preset'].select(0)
		self.show_top_sounds_changed.emit()

	def show(self):
		if self.__show_top_sounds: #don't support autosync when top sounds is enabled
			return
		if not self.zyngui.curlayer:
			logging.error("Can't show bank list for None layer!")
			return
		if not self.zyngui.curlayer.get_bank_name():
			self.zyngui.curlayer.set_bank(0)
		if self.zyngui.screens['preset'].get_show_only_favorites():
			self.select(0)
		else:
			self.select(self.zyngui.curlayer.get_bank_index())
		logging.debug("BANK INDEX => %s" % self.index)
		super().show()


	def select_action(self, i, t='S'):
		self.select(i)
		if i < 0 or i >= len(self.list_data):
			return
		if self.__show_top_sounds:
			self.zyngui.screens['preset'].set_top_sounds_engine(self.list_data[i][0])
			return
		else:
			self.zyngui.screens['preset'].set_top_sounds_engine(None)

		if self.list_data[i][0]=='*FAVS*':
			self.zyngui.screens['preset'].set_show_only_favorites(True)
		else:
			self.zyngui.screens['preset'].set_show_only_favorites(False)

		if self.zyngui.curlayer.set_bank(i):
			#self.zyngui.screens['preset'].disable_only_favs()
			self.zyngui.screens['preset'].update_list()
			if self.auto_next_screen:
				self.next_action
			else:
				self.zyngui.screens['preset'].show() #FIXME: this show should be renamed in "load" or some similar name
			# If there is only one preset, jump to instrument control
			if len(self.zyngui.curlayer.preset_list)<=1:
				self.zyngui.screens['preset'].select_action(0)
			self.zyngui.screens['layer'].fill_list()
		else:
			self.show()
		self.set_select_path()

	def next_action(self):
		return "preset"

	def index_supports_immediate_activation(self, index=None):
		return True

	def set_select_path(self):
		if self.zyngui.curlayer:
			self.select_path = self.zyngui.curlayer.get_basepath()
			self.select_path_element = str(self.zyngui.curlayer.engine.name)
		else:
			self.select_path_element = "Banks"
			self.select_path = "Banks"
		super().set_select_path()


	show_top_sounds_changed = Signal()

	show_top_sounds = Property(bool, get_show_top_sounds, set_show_top_sounds, notify = show_top_sounds_changed)

#-------------------------------------------------------------------------------
