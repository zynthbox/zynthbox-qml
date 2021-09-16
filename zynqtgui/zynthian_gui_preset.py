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
		self.reload_top_sounds()
		self.show()


	def fill_list(self):
		self.list_data = []
		self.list_metadata = []

		if self.__top_sounds_engine != None:
			self.reload_top_sounds()
			if isinstance(self.__top_sounds, dict) and self.__top_sounds_engine in self.__top_sounds:
				if isinstance(self.__top_sounds[self.__top_sounds_engine], list):
					for sound in self.__top_sounds[self.__top_sounds_engine]:
						if isinstance(sound, dict):
							self.list_data.append(("topsound", len(self.list_data), sound["preset"]))
							self.list_metadata.append({"icon": "", "show_numbers": True, "is_top" : True})

		else:
			if not self.zyngui.curlayer:
				logging.error("Can't fill preset list for None layer!")
				super().fill_list()
				return

			self.zyngui.curlayer.load_preset_list()
			if not self.zyngui.curlayer.preset_list:
				self.set_select_path()
				self.zyngui.curlayer.load_preset_list()

			for item in self.zyngui.curlayer.preset_list:
				self.list_data.append(item)
				is_top = False
				if self.zyngui.curlayer != None and self.zyngui.curlayer.engine.nickname in self.__top_sounds:
					for sound in self.__top_sounds[self.zyngui.curlayer.engine.nickname]:
						if sound["preset"] == item[2]:
							is_top = True
							break
				self.list_metadata.append({"icon": "starred-symbolic" if self.zyngui.curlayer.engine.is_preset_fav(item) else "non-starred-symbolic",
								"show_numbers": True, "is_top" : is_top})

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
			sound = self.__top_sounds[self.__top_sounds_engine][i]
			layer = self.zyngui.curlayer
			if self.zyngui.curlayer == None:
				self.zyngui.start_loading()
				engine = self.zyngui.screens['engine'].start_engine(sound['engine'])
				midi_chan = self.zyngui.screens["fixed_layers"].list_data[self.zyngui.screens["fixed_layers"].index][1]
				layer = zynthian_layer(engine, midi_chan, self.zyngui)
				self.zyngui.screens['layer'].layers.append(layer)
				self.zyngui.screens['engine'].stop_unused_engines()
			else:
				if self.zyngui.curlayer.preset_name == sound["preset"]:
					return
				self.zyngui.start_loading()
				#Workaround: make sure that layer is really selected or we risk to replace the old one
				for i, candidate in enumerate(self.zyngui.screens['layer'].root_layers):
					if candidate == layer:
						self.zyngui.screens['layer'].select_action(i)
						break
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
				self.zyngui.layer_control(layer)

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



	def select(self, index=None):
		super().select(index)
		self.current_is_favorite_changed.emit()
		self.current_is_top_changed.emit()


	def get_current_is_favorite(self):
		if self.index < 0 or self.index >= len(self.list_data):
			return False
		if self.list_data[self.index][0] == "topsound":
			return False  # TODO we don't have a way to know if presets of non loaded engines are favorite
		if self.index >= len(self.zyngui.curlayer.preset_list):
			return False
		return self.zyngui.curlayer.engine.is_preset_fav(self.zyngui.curlayer.preset_list[self.index])

	def set_current_is_favorite(self, fav: bool):
		self.zyngui.curlayer.toggle_preset_fav(self.list_data[self.index])
		self.fill_list()
		self.zyngui.screens['bank'].fill_list()
		self.current_is_favorite_changed.emit()

	def get_current_is_top(self):
		if self.zyngui.curlayer is None:
			return False
		if self.__top_sounds_engine != None:
			return True
		if not self.zyngui.curlayer.engine.nickname in self.__top_sounds:
			return False
		for sound in self.__top_sounds[self.zyngui.curlayer.engine.nickname]:
			if sound["preset"] == self.list_data[self.index][2]:
				return True
		return False

	def set_current_is_top(self, top: bool):
		if not top and self.__top_sounds_engine != None:
			del self.__top_sounds[self.__top_sounds_engine][self.index]
		elif top:
			self.__top_sounds[self.zyngui.curlayer.engine.nickname].append({
							 "engine": self.zyngui.curlayer.engine.nickname,
							 "bank": self.zyngui.curlayer.bank_name,
							 "preset": self.zyngui.curlayer.preset_name})
		else:
			return
		try:
			f = open("/zynthian/zynthian-my-data/top-sounds.json", "w")
			f.write(JSONEncoder().encode(self.__top_sounds))
			f.close()
			self.fill_list()
			self.zyngui.screens['bank'].fill_list()
			self.current_is_top_changed.emit()
		except Exception as e:
			logging.warning("Can't save top sounds: {}".format(e))


	def reload_top_sounds(self):
		try:
			with open("/zynthian/zynthian-my-data/top-sounds.json", "r") as fh:
				json=fh.read()
				logging.info("Loading top sounds %s" % (json))

				self.__top_sounds = JSONDecoder().decode(json)
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

	def next_action(self): #DON't go to edit or effect
		return "preset"

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
				self.select_path_element = self.zyngui.curlayer.preset_name
			else:
				self.select_path = self.zyngui.curlayer.get_bankpath()
				self.select_path_element = self.zyngui.curlayer.preset_name
		else:
			self.select_path_element = "Presets"
		super().set_select_path()

	show_only_favorites_changed = Signal()
	current_is_favorite_changed = Signal()
	current_is_top_changed = Signal()
	top_sounds_engine_changed = Signal()

	show_only_favorites = Property(bool, get_show_only_favorites, set_show_only_favorites, notify = show_only_favorites_changed)
	current_is_favorite = Property(bool, get_current_is_favorite, set_current_is_favorite, notify = current_is_favorite_changed)
	current_is_top = Property(bool, get_current_is_top, set_current_is_top, notify = current_is_top_changed)
	top_sounds_engine = Property(str, get_top_sounds_engine, set_top_sounds_engine, notify = top_sounds_engine_changed)


#------------------------------------------------------------------------------
