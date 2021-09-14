#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian GUI Preset Selector Class
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

from zyngine import zynthian_layer

from json import JSONEncoder, JSONDecoder

# Zynthian specific modules
from . import zynthian_gui_config
from . import zynthian_gui_selector

# Qt modules
from PySide2.QtCore import Qt, QObject, Slot, Signal, Property

#-------------------------------------------------------------------------------
# Zynthian Preset/Instrument Selection GUI Class
#-------------------------------------------------------------------------------

class zynthian_gui_preset(zynthian_gui_selector):

	buttonbar_config = [
		(1, 'BACK'),
		(0, 'LAYER'),
		(2, 'FAVS'),
		(3, 'SELECT')
	]

	def __init__(self, parent = None):
		super(zynthian_gui_preset, self).__init__('Preset', parent)
		self.__top_sounds_engine = None
		self.__top_sounds = []
		self.next_screen_prop = 'control'
		self.show()


	def fill_list(self):
		self.list_data = []
		self.list_metadata = []

		if self.__top_sounds_engine != None:
			self.reload_top_sounds()
			if isinstance(self.__top_sounds, dict) and self.__top_sounds_engine in self.__top_sounds:
				logging.error("ISDICT")
				if isinstance(self.__top_sounds[self.__top_sounds_engine], list):
					logging.error("ISLIST")
					for sound in self.__top_sounds:
						logging.error(sound)
						if isinstance(sound, dict):
							logging.error("ISDICT2")
							self.list_data.append(("topsound", len(self.list_data), sound["name"]))
							self.list_metadata.append({"icon": "", "show_numbers": True})

		else:
			if not self.zyngui.curlayer:
				logging.error("Can't fill preset list for None layer!")
				return

			self.zyngui.curlayer.load_preset_list()
			if not self.zyngui.curlayer.preset_list:
				self.set_select_path()
				self.zyngui.curlayer.load_preset_list()

			for item in self.zyngui.curlayer.preset_list:
				self.list_data.append(item)
				self.list_metadata.append({"icon": "starred-symbolic" if self.zyngui.curlayer.engine.is_preset_fav(item) else "non-starred-symbolic",
								"show_numbers": True})

		super().fill_list()


	def show(self, show_fav_presets=None):
		if not self.zyngui.curlayer:
			logging.error("Can't show preset list for None layer!")
			return

		self.select(self.zyngui.curlayer.get_preset_index())
		if not self.zyngui.curlayer.get_preset_name():
			self.zyngui.curlayer.set_preset(self.zyngui.curlayer.get_preset_index())

		super().show()


	def select_action(self, i, t='S'):
		if self.list_data[i][0] == "topsound":
			self.zyngui.start_loading()
			sound = self.__top_sounds[self.__top_sounds_engine][i]
			layer = self.zyngui.curlayer
			if self.zyngui.curlayer.engine.nickname != sound["engine"]:
				midi_chan = self.zyngui.curlayer.midi_chan
				self.zyngui.screens['layer'].remove_current_layer()
				engine = self.zyngui.screens['engine'].start_engine(sound['engine'])
				layer = zynthian_layer(engine, midi_chan, self.zyngui)
				self.zyngui.screens['layer'].layers.append(layer)
				self.zyngui.screens['engine'].stop_unused_engines()

			layer.wait_stop_loading()
			#Load bank list and set bank
			try:
				layer.bank_name=sound['bank']	#tweak for working with setbfree extended config!! => TODO improve it!!
				layer.load_bank_list()
				layer.bank_name=None
				layer.set_bank_by_name(sound['bank'])
				self.zyngui.screens['layer'].reset_midi_routing()
				self.zyngui.zynautoconnect_midi(True)
				self.zyngui.screens['layer'].reset_audio_routing()
				self.zyngui.zynautoconnect_audio()

			except Exception as e:
				logging.warning("Invalid Bank on layer {}: {}".format(layer.get_basepath(), e))

			layer.wait_stop_loading()

			#Load preset list and set preset
			layer.load_preset_list()
			layer.preset_loaded = layer.set_preset_by_name(sound['preset'])
			self.zyngui.screens['layer'].fill_list()
			self.zyngui.stop_loading()

			return
		if t=='S':
			self.zyngui.curlayer.set_preset(i)
			self.zyngui.screens['control'].show()
			self.zyngui.screens['layer'].fill_list()
		else:
			self.zyngui.curlayer.toggle_preset_fav(self.list_data[i])
			self.update_list()
			self.zyngui.screens['bank'].fill_list()

	def toggle_top_sound(self):
		if self.__top_sounds_engine == None:
			self.__top_sounds[self.zyngui.curlayer.engine.nickname].remove(self.index)
		else:
			self.__top_sounds[self.zyngui.curlayer.engine.nickname].append({"name": self.select_path,
							 "engine": self.zyngui.curlayer.engine.nickname,
							 "bank": self.zyngui.curlayer.bank_name,
							 "preset": self.zyngui.curlayer.preset_name})
		try:
			f = open("/zynthian/zynthian-my-data/top-sounds.json", "w")
			f.write(JSONEncoder().encode(self.__top_sounds))
			f.close()
			self.fill_list()
		except Exception as e:
			logging.warning("Can't save top sounds: {}".format(e))


	def reload_top_sounds(self):
		try:
			with open("/zynthian/zynthian-my-data/top-sounds.json", "r") as fh:
				json=fh.read()
				logging.info("Loading top sounds %s" % (json))

				self.__top_sounds = JSONDecoder().decode(json)
				logging.error(self.__top_sounds)
		except Exception as e:
			logging.error("Can't load top sounds: %s" % (e))

	def get_all_top_sounds(self):
		return self.__top_sounds

	def set_top_sounds_engine(self, engine : str):
		self.__top_sounds_engine = engine
		self.top_sounds_engine_changed.emit()
		self.fill_list()


	def get_top_sounds_engine(self):
		return self.__top_sounds_engine


	def index_supports_immediate_activation(self, index=None):
		return True

	def next_action(self):
		return self.next_screen_prop

	def back_action(self):
		return "bank"

	def preselect_action(self):
		return self.zyngui.curlayer.preload_preset(self.index)


	def restore_preset(self):
		return self.zyngui.curlayer.restore_preset()

	def set_show_only_favorites(self, show):
		if show:
			self.enable_show_fav_presets()
		else:
			self.disable_show_fav_presets()

	def get_show_only_favorites(self):
		return self.zyngui.curlayer.show_fav_presets

	def enable_show_fav_presets(self):
		if not self.zyngui.curlayer.show_fav_presets:
			self.zyngui.curlayer.show_fav_presets = True
			self.set_select_path()
			self.update_list()
			self.show_only_favorites_changed.emit()
			if self.zyngui.curlayer.get_preset_name():
				self.zyngui.curlayer.set_preset_by_name(self.zyngui.curlayer.get_preset_name())


	def disable_show_fav_presets(self):
		if self.zyngui.curlayer.show_fav_presets:
			self.zyngui.curlayer.show_fav_presets = False
			self.set_select_path()
			self.update_list()
			self.show_only_favorites_changed.emit()
			if self.zyngui.curlayer.get_preset_name():
				self.zyngui.curlayer.set_preset_by_name(self.zyngui.curlayer.get_preset_name())


	def toggle_show_fav_presets(self):
		if self.zyngui.curlayer.show_fav_presets:
			self.disable_show_fav_presets()
		else:
			self.enable_show_fav_presets()


	def set_select_path(self):
		if self.zyngui.curlayer:
			if self.zyngui.curlayer.show_fav_presets:
				self.select_path = (self.zyngui.curlayer.get_basepath() + " > Favorites")
				if self.zyngui.curlayer is None:
					self.select_path_element = "Favorites"
				else:
					self.select_path_element = self.zyngui.curlayer.preset_name
			else:
				self.select_path = self.zyngui.curlayer.get_bankpath()
				if self.zyngui.curlayer is None:
					self.select_path_element = "Presets"
				else:
					self.select_path_element = self.zyngui.curlayer.preset_name
		super().set_select_path()

	def set_next_screen(self, screen):
		self.next_screen_prop = screen
		self.next_screen_changed.emit()

	show_only_favorites_changed = Signal()
	top_sounds_engine_changed = Signal()
	next_screen_changed = Signal()

	show_only_favorites = Property(bool, get_show_only_favorites, set_show_only_favorites, notify = show_only_favorites_changed)
	top_sounds_engine = Property(str, get_top_sounds_engine, set_top_sounds_engine, notify = top_sounds_engine_changed)
	next_screen = Property(str, next_action, set_next_screen, notify = next_screen_changed)


#------------------------------------------------------------------------------
