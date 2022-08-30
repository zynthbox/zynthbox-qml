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

from os import listdir
from os.path import isfile, join

# Zynthian specific modules
from . import zynthian_gui_config
from . import zynthian_gui_selector

# Qt modules
from PySide2.QtCore import Qt, QObject, Slot, Signal, Property
import traceback
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
		self.__top_sounds = {}
		self.__fav_root = "/zynthian/zynthian-my-data/preset-favorites/"
		self.reload_top_sounds()
		self.__select_in_progess = False
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
							self.list_data.append(sound["list_item"])
							self.list_metadata.append({"icon": "starred-symbolic", "show_numbers": True})

		else:
			if not self.zyngui.curlayer:
				logging.info("Can't fill preset list for None layer!")
				super().fill_list()
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
		self.set_select_path()


	def show(self, show_fav_presets=None):
		if not self.zyngui.curlayer:
			logging.info("Can't show preset list for None layer!")
			return

		if self.__top_sounds_engine != None:
			for i, item in enumerate(self.list_data):
				if item[2] == self.zyngui.curlayer.preset_name:
					self.select(i)
					break
		else:
			self.select(self.zyngui.curlayer.get_preset_index())
		if not self.zyngui.curlayer.get_preset_name():
			self.zyngui.curlayer.set_preset(self.zyngui.curlayer.get_preset_index())

		self.set_select_path()
		super().show()


	def select_action(self, i, t='S'):
		if i < 0 or i >= len(self.list_data):
			return
		if self.__select_in_progess: #HACK: this is due from the process events in the spinner. should be fixed there
			return
		self.__select_in_progess = True
		self.select(i)
		engine_created = False
		if self.__top_sounds_engine != None:
			sound = self.__top_sounds[self.__top_sounds_engine][min(i, len(self.__top_sounds[self.__top_sounds_engine]) - 1)]
			layer = self.zyngui.curlayer
			old_audio_out = None
			if self.zyngui.curlayer == None:
				self.zyngui.start_loading()
				engine_created = True
				engine = self.zyngui.screens['engine'].start_engine(sound['engine'])
				midi_chan = self.zyngui.screens["layers_for_channel"].list_data[self.zyngui.screens["layers_for_channel"].index][1]
				layer = zynthian_layer(engine, midi_chan, self.zyngui)
				self.zyngui.screens['layer'].layers.append(layer)
				self.zyngui.screens['engine'].stop_unused_engines()
				self.zyngui.set_curlayer(layer)
				self.zyngui.screens['layer'].reset_midi_routing()
				self.zyngui.zynautoconnect_midi(True)
				self.zyngui.screens['layer'].reset_audio_routing()
				self.zyngui.zynautoconnect_audio()
				self.zyngui.screens['layer'].add_midichannel_to_channel(midi_chan, self.zyngui.screens["layers_for_channel"].index)
			else:
				if self.zyngui.curlayer.preset_name == sound["preset"] and self.zyngui.curlayer.bank_name == sound["bank"]:
					self.__select_in_progess = False
					return

				self.zyngui.set_curlayer(layer) # FIXME: sometimes after the event processing in self.zyngui.start_loading() curlayer is changed??
				old_audio_out = layer.get_audio_out()

				if self.zyngui.curlayer.engine.nickname != sound["engine"]:
					self.zyngui.start_loading()
					engine_created = True
					midi_chan = self.zyngui.curlayer.midi_chan
					index_to_replace = self.zyngui.screens['layer'].root_layers.index(layer)
					self.zyngui.screens['layer'].replace_layer_index = index_to_replace
					self.zyngui.screens['layer'].layer_chain_parallel = False
					self.zyngui.screens['layer'].layer_index_replace_engine = index_to_replace
					self.zyngui.screens['layer'].add_layer_engine(sound['engine'], midi_chan, True)
					layer = self.zyngui.curlayer
				else:
					#Workaround: make sure that layer is really selected or we risk to replace the old one
					for i, candidate in enumerate(self.zyngui.screens['layer'].root_layers):
						if candidate == self.zyngui.curlayer:
							self.zyngui.screens['layer'].select_action(i)
							break

			layer.wait_stop_loading()
			#Load bank list and set bank
			try:
				layer.wait_stop_loading()
				layer.bank_name=sound['bank']	#tweak for working with setbfree extended config!! => TODO improve it!!
				layer.load_bank_list()
				layer.bank_name=None
				layer.set_bank_by_name(sound['bank'])
				layer.wait_stop_loading()

			except Exception as e:
				logging.warning("Invalid Bank on layer {}: {}".format(layer.get_basepath(), e))

			if engine_created:
				layer.wait_stop_loading()

			#Load preset list and set preset
			layer.load_preset_list()
			layer.preset_name = None
			layer.preload_info = True
			layer.preset_loaded = layer.set_preset_by_name(sound['preset'])
			layer.refresh_controllers()
			self.zyngui.layer_control(layer)
			self.zyngui.screens['layer'].fill_list()
			self.show()
			self.zyngui.stop_loading()
			self.__select_in_progess = False
			self.zyngui.screens['bank'].set_select_path()
			self.zyngui.screens['control'].show()
			self.set_select_path()
			return

		if t=='S':
			self.zyngui.curlayer.set_preset(i)
			self.zyngui.screens['control'].show()
			self.zyngui.screens['layer'].fill_list()
		else:
			# We selected i as current index so we can assume we're working on the current index
			self.__select_in_progess = False
			self.set_current_is_favorite(not self.get_current_is_favorite())

		self.__select_in_progess = False
		self.set_select_path()



	def select(self, index=None):
		super().select(index)
		self.set_select_path()
		self.current_is_favorite_changed.emit()


	def get_current_is_favorite(self):
		if self.zyngui.curlayer == None:
			return False
		if self.index < 0 or self.index >= len(self.list_data):
			return False
		if self.__top_sounds_engine != None:
			return True  # We can assume all topsounds are always favorite
		if self.index >= len(self.zyngui.curlayer.preset_list):
			return False
		return self.zyngui.curlayer.engine.is_preset_fav(self.zyngui.curlayer.preset_list[self.index])

	def set_current_is_favorite(self, new_fav_state: bool):
		fav_owner_engine = None
		fav_bank_name = None
		if self.__top_sounds_engine == None:
			fav_owner_engine = self.zyngui.curlayer.engine
		else:
			for eng in self.zyngui.screens['engine'].zyngines:
				candidate_engine = self.zyngui.screens['engine'].zyngines[eng]
				if candidate_engine.nickname == self.__top_sounds_engine and len(candidate_engine.layers) > 0:
					fav_owner_engine = candidate_engine
					break
		# if we are operating on an active engine, we can just use its internal api
		if fav_owner_engine != None:
			preset_id = str(self.list_data[self.index][0])
			# Find the bank name we might have to restore
			if preset_id in self.zyngui.curlayer.engine.preset_favs:
				fav_bank_name = self.zyngui.curlayer.engine.preset_favs[preset_id][0][2]

			if fav_owner_engine.is_preset_fav(self.list_data[self.index]) != new_fav_state:
				fav_owner_engine.toggle_preset_fav(fav_owner_engine.layers[0], self.list_data[self.index])

		# otherwise we need to manipulate the json file ourselves, support only fav *removal* for now
		# TODO: support also adding a fav?
		elif self.__top_sounds_engine != None and not new_fav_state:
			try:
				filename = self.__top_sounds_engine.replace("/", "_").replace() + ".json"
				parsed = None
				with open(self.__fav_root + filename, "r") as fh:
					json = fh.read()
					fh.close()
					logging.info("Loading top sounds for update %s" % (json))

					parsed = JSONDecoder().decode(json)
					if not isinstance(parsed, dict):
						raise Exception("Unexpected fileformat: not a dict")

				for entry in parsed:
					if len(entry) == 0:
						continue
					if not isinstance(parsed[entry], list):
						continue
					if len(parsed[entry]) < 2:
						continue
					if len(parsed[entry][0]) < 3:
						continue
					if len(parsed[entry][1]) < 3:
						continue
					if (parsed[entry][0][2] == self.__top_sounds[self.__top_sounds_engine][self.index]["bank"]
						and parsed[entry][1][2] == self.__top_sounds[self.__top_sounds_engine][self.index]["preset"]):
						del parsed[entry]
						break

				with open(self.__fav_root + filename, "w") as fh:
					f.write(JSONEncoder().encode(parsed))
					f.close()

			except Exception as e:
				logging.error("Can't update top sounds: %s" % (e))

		self.fill_list()
		self.zyngui.screens['bank'].fill_list()
		self.zyngui.screens['bank'].show()

		#if we were showing only favorites and removed the current one, select another
		if not new_fav_state and self.zyngui.curlayer != None and (self.zyngui.curlayer.show_fav_presets or self.__top_sounds_engine != None):
			if len(self.list_data) > 0:
				self.select_action(max(0, self.index - 1))
			else:
				self.zyngui.screens['bank'].select_action(0)

		self.show()
		self.current_is_favorite_changed.emit()


	def sync_current_bank(self):
		if self.zyngui.curlayer == None:
			return
		self.zyngui.screens['bank'].select(self.zyngui.curlayer.bank_index)
		self.zyngui.screens['preset'].fill_list()
		self.zyngui.screens['preset'].select(self.zyngui.curlayer.preset_index)


	def reload_top_sounds(self):
		self.__top_sounds = {}
		allfiles = [f for f in listdir(self.__fav_root) if isfile(join(self.__fav_root, f))]
		for f in allfiles:
			if not f.endswith(".json"):
				continue
			try:
				with open(self.__fav_root + f, "r") as fh:
					json = fh.read()
					fh.close()
					logging.debug("Loading top sounds %s" % (json))

					parsed = JSONDecoder().decode(json)
					if not isinstance(parsed, dict):
						continue
					engine = f.replace("_", "/")
					engine = engine.replace(".json", "")
					if not engine in self.__top_sounds:
						self.__top_sounds[engine] = []
					for entry in parsed:
						if len(entry) == 0:
							continue
						if not isinstance(parsed[entry], list):
							continue
						if len(parsed[entry]) < 2:
							continue
						if len(parsed[entry][0]) < 3:
							continue
						if len(parsed[entry][1]) < 3:
							continue
						sound = {"engine": engine,
							"bank": parsed[entry][0][2],
							"preset": parsed[entry][1][2],
							"list_item": parsed[entry][1]}
						self.__top_sounds[engine].append(sound)
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
		return self.__top_sounds_engine == None or (self.zyngui.curlayer != None and self.zyngui.curlayer.engine.nickname == self.__top_sounds_engine)

	def next_action(self): #DON't go to edit or effect
		return "preset"

	def back_action(self):
		return "bank"

	def preselect_action(self):
		if self.index < 0 or self.index >= len(self.list_data):
			return False
		if self.__top_sounds_engine == None:
			return self.zyngui.curlayer.preload_preset(self.index)
		else:
			mapped_index = -1
			for i in range(len(self.zyngui.curlayer.preset_list)):
				name_i=self.zyngui.curlayer.preset_list[i][2]
				try:
					if name_i[0] == '*':
						name_i = name_i[1:]
					if preset_name == name_i:
						return self.zyngui.curlayer.preload_preset(i)
				except:
					return False



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
		if self.zyngui.curlayer and self.zyngui.curlayer.show_fav_presets:
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
	top_sounds_engine_changed = Signal()

	show_only_favorites = Property(bool, get_show_only_favorites, set_show_only_favorites, notify = show_only_favorites_changed)
	current_is_favorite = Property(bool, get_current_is_favorite, set_current_is_favorite, notify = current_is_favorite_changed)
	top_sounds_engine = Property(str, get_top_sounds_engine, set_top_sounds_engine, notify = top_sounds_engine_changed)


#------------------------------------------------------------------------------
