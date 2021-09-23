#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian GUI Layer Selector Class
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


import os
import sys
import copy
import base64
import logging
import collections
from collections import OrderedDict
from json import JSONEncoder, JSONDecoder
from pathlib import Path

# Zynthian specific modules
from zyncoder import *
from . import zynthian_gui_config
from . import zynthian_gui_selector
from zyngine import zynthian_layer

from PySide2.QtCore import Qt, QObject, Slot, Signal, Property

#------------------------------------------------------------------------------
# Zynthian Layer Selection GUI Class
#------------------------------------------------------------------------------

class zynthian_gui_layer(zynthian_gui_selector):

	def __init__(self, parent = None):
		super(zynthian_gui_layer, self).__init__('Layer', parent)
		self.layers = []
		self.root_layers = []
		self.layer_midi_map = {}
		self.amixer_layer = None
		self.add_layer_eng = None
		self.replace_layer_index = None
		self.layer_chain_parallel = False
		self.last_snapshot_fpath = None
		self.auto_next_screen = False
		self.layer_index_replace_engine = None
		self.last_zs3_index = [0] * 16; # Last selected ZS3 snapshot, per MIDI channel
		self.create_amixer_layer()
		self.__soundsets_basepath__ = "/zynthian/zynthian-my-data/soundsets/" #TODO: all in fixed layers
		self.__sounds_basepath__ = "/zynthian/zynthian-my-data/sounds/"
		self.show()


	def reset(self):
		self.last_zs3_index = [0] * 16; # Last selected ZS3 snapshot, per MIDI channel
		self.show_all_layers = False
		self.add_layer_eng = None
		self.last_snapshot_fpath = None
		self.reset_clone()
		self.reset_note_range()
		self.remove_all_layers(True)
		self.reset_midi_profile()


	def fill_list(self):
		self.list_data=[]
		self.layer_midi_map = {}

		# Get list of root layers
		self.root_layers=self.get_fxchain_roots()

		for i,layer in enumerate(self.root_layers):
			self.list_data.append((str(i+1),i,layer.get_presetpath()))
			self.layer_midi_map[layer.midi_chan] = layer

		# Add separator
		if len(self.root_layers)>0:
			self.list_data.append((None,len(self.list_data),""))

		# Add fixed entries
		self.list_data.append(('NEW_SYNTH',len(self.list_data),"NEW Synth Layer"))
		self.list_data.append(('NEW_AUDIO_FX',len(self.list_data),"NEW Audio-FX Layer"))
		self.list_data.append(('NEW_MIDI_FX',len(self.list_data),"NEW MIDI-FX Layer"))
		self.list_data.append(('NEW_GENERATOR',len(self.list_data),"NEW Generator Layer"))
		self.list_data.append(('NEW_SPECIAL',len(self.list_data),"NEW Special Layer"))
		self.list_data.append(('RESET',len(self.list_data),"REMOVE All Layers"))
		self.list_data.append((None,len(self.list_data),""))
		self.list_data.append(('ALL_OFF',len(self.list_data),"PANIC! All Notes Off"))

		if 'fixed_layers' in self.zyngui.screens:
			self.zyngui.screens['fixed_layers'].fill_list()

		# Should be emitted only when the actual curlayer or its engine change
		self.engine_nick_changed.emit()

		super().fill_list()

	def get_effective_count(self):
		return len(self.root_layers)

	def select_action(self, i, t='S'):
		self.index = i

		if self.list_data[i][0] is None:
			pass

		elif self.list_data[i][0]=='NEW_SYNTH':
			self.add_layer("MIDI Synth")

		elif self.list_data[i][0]=='NEW_AUDIO_FX':
			self.add_layer("Audio Effect")

		elif self.list_data[i][0]=='NEW_MIDI_FX':
			self.add_layer("MIDI Tool")

		elif self.list_data[i][0]=='NEW_GENERATOR':
			self.add_layer("Audio Generator")

		elif self.list_data[i][0]=='NEW_SPECIAL':
			self.add_layer("Special")

		elif self.list_data[i][0]=='RESET':
			self.ask_reset()

		elif self.list_data[i][0]=='ALL_OFF':
			self.zyngui.callable_ui_action("ALL_OFF")

		else:
			if t=='S':
				self.layer_control()

			elif t=='B':
				self.layer_options()

		if i < len(self.root_layers):
			self.zyngui.screens['fixed_layers'].sync_index_from_curlayer()
		#self.zyngui.screens['bank'].show()

	def next_action(self):
		return "bank"

	def index_supports_immediate_activation(self, index=None):
		return index >= 0 and index < len(self.root_layers)

	def layer_up(self):
		self.previous(zynthian_gui_config.automatically_show_control_page)
		self.select_action(self.index)

	def layer_down(self):
		self.next(zynthian_gui_config.automatically_show_control_page)
		self.select_action(self.index)

	@Slot(None)
	def ask_reset(self):
		self.zyngui.show_confirm("Do you really want to remove all layers?", self.reset_confirmed)

	def reset_confirmed(self, params=None):
		if len(self.zyngui.screens['layer'].layers)>0:
			self.zyngui.screens['snapshot'].save_last_state_snapshot()
		self.reset()
		self.zyngui.show_screen('layer')
		self.zyngui.screens['layer'].set_select_path()
		self.zyngui.screens['bank'].fill_list()
		self.zyngui.screens['bank'].set_select_path()
		self.zyngui.screens['preset'].fill_list()
		self.zyngui.screens['preset'].set_select_path()


	def create_amixer_layer(self):
		mixer_eng = self.zyngui.screens['engine'].start_engine('MX')
		self.amixer_layer=zynthian_layer(mixer_eng, None, self.zyngui)


	def remove_amixer_layer(self):
		self.amixer_layer.reset()
		self.amixer_layer = None


	def layer_control(self, layer=None):
		if not layer:
			layer = self.root_layers[self.index]
		self.zyngui.layer_control(layer)


	def layer_options(self):
		i = self.get_layer_selected()
		if i is not None and self.root_layers[i].engine.nickname!='MX':
			self.zyngui.screens['layer_options'].reset()
			self.zyngui.show_modal('layer_options')

	@Slot(int)
	def activate_layer(self, i):
		if len(self.root_layers) == 0 or i < 0 or i >= len(self.root_layers):
			return
		self.activate_index(i)

	def activate_midichan_layer(self, midi_chan):
		if midi_chan in self.layer_midi_map:
			self.activate_index(self.root_layers.index(self.layer_midi_map[midi_chan]))
			self.zyngui.screens['bank'].set_select_path()
			self.zyngui.screens['preset'].set_select_path()
		else:
			self.zyngui.set_curlayer(None)
			self.zyngui.screens['bank'].fill_list()
			self.zyngui.screens['bank'].set_select_path()
			self.zyngui.screens['preset'].fill_list()
			self.zyngui.screens['preset'].set_select_path()
			zyncoder.lib_zyncoder.set_midi_active_chan(midi_chan)
			self.zyngui.screens['fixed_layers'].sync_index_from_curlayer()
			self.zyngui.screens['fixed_layers'].current_index_valid_changed.emit()
			self.set_select_path()
		#elif midi_chan < 5: #HACK to not open the engine selection on layers 6-10
			#self.replace_layer_index = None
			#self.layer_chain_parallel = False
			#self.zyngui.screens['engine'].set_engine_type("MIDI Synth")
			#self.zyngui.screens['engine'].set_midi_channel(midi_chan)
			#self.layer_index_replace_engine = None
			#self.zyngui.show_modal('engine')
		#else: # HACK Channels 6-10
			#for i in range(5, 10):
				#if i in self.layer_midi_map:
					#self.activate_index(self.root_layers.index(self.layer_midi_map[i]))

	def next(self, control=True):
		self.zyngui.restore_curlayer()
		if len(self.root_layers)>1:
			if self.zyngui.curlayer in self.layers:
				self.index += 1
				if self.index>=len(self.root_layers):
					self.index = 0

			if control:
				self.layer_control()
			else:
				self.zyngui.set_curlayer(self.root_layers[self.index])
				self.select(self.index)

	def previous(self, control=True):
		self.zyngui.restore_curlayer()
		if len(self.root_layers)>1:
			if self.zyngui.curlayer in self.layers:
				self.index -= 1
				if self.index < 0:
					self.index = len(self.root_layers) - 1

			if control:
				self.layer_control()
			else:
				self.zyngui.set_curlayer(self.root_layers[self.index])
				self.select(self.index)


	def get_num_layers(self):
		return len(self.layers)


	def get_num_root_layers(self):
		return len(self.root_layers)


	def get_layer_selected(self):
		if self.index < len(self.root_layers):
			return self.index
		else:
			return None


	def get_free_midi_chans(self):
		free_chans = list(range(16))

		for rl in self.layers:
			try:
				free_chans.remove(rl.midi_chan)
			except:
				pass

		#logging.debug("FREE MIDI CHANNELS: {}".format(free_chans))
		return free_chans


	def get_next_free_midi_chan(self, chan0):
		free_chans = self.get_free_midi_chans()
		for i in range(1,16):
			chan = (chan0 + i) % 16
			if chan in free_chans:
				return chan
		raise Exception("No available free MIDI channels!")


	def show_chain_options_modal(self):
		chain_modes = {
			"Serial": False,
			"Parallel": True
		}
		self.zyngui.screens['option'].config("Chain Mode", chain_modes, self.cb_chain_options_modal)
		self.zyngui.show_modal('option')


	def cb_chain_options_modal(self, chain_parallel):
		self.layer_chain_parallel = chain_parallel
		self.layer_index_replace_engine = None
		self.zyngui.show_modal('engine')


	def add_layer(self, etype):
		self.add_layer_eng = None
		self.replace_layer_index = None
		self.layer_chain_parallel = False
		self.zyngui.screens['engine'].set_engine_type(etype)
		self.layer_index_replace_engine = None
		self.zyngui.show_modal('engine')


	@Slot(int)
	def select_engine(self, midi_chan = -1):
		self.add_layer_eng = None
		self.replace_layer_index = None
		self.layer_chain_parallel = False
		self.zyngui.screens['engine'].set_engine_type("MIDI Synth")
		if midi_chan < 0:
			midi_chan = self.layers[self.index].midi_chan
		if midi_chan in self.layer_midi_map:
			self.layer_index_replace_engine = self.index
		else:
			self.layer_index_replace_engine = None

		self.zyngui.screens['engine'].set_midi_channel(midi_chan)
		self.zyngui.show_modal('engine')
		if midi_chan in self.layer_midi_map:
			self.zyngui.screens['engine'].select_by_engine(self.layers[self.index].engine.nickname)


	def add_fxchain_layer(self, midi_chan):
		self.add_layer_eng = None
		self.replace_layer_index = None
		self.layer_chain_parallel = False
		self.zyngui.screens['engine'].set_fxchain_mode(midi_chan)
		if self.get_fxchain_count(midi_chan)>0:
			self.show_chain_options_modal()
		else:
			self.layer_index_replace_engine = None
			self.zyngui.show_modal('engine')


	def replace_fxchain_layer(self, i):
		self.add_layer_eng = None
		self.replace_layer_index = i
		self.layer_chain_parallel = False
		self.zyngui.screens['engine'].set_fxchain_mode(self.layers[i].midi_chan)
		self.layer_index_replace_engine = None
		self.zyngui.show_modal('engine')


	def add_midichain_layer(self, midi_chan):
		self.add_layer_eng = None
		self.replace_layer_index = None
		self.layer_chain_parallel = False
		self.zyngui.screens['engine'].set_midichain_mode(midi_chan)
		if self.get_midichain_count(midi_chan)>0:
			self.show_chain_options_modal()
		else:
			self.layer_index_replace_engine = None
			self.zyngui.show_modal('engine')


	def replace_midichain_layer(self, i):
		self.add_layer_eng = None
		self.replace_layer_index = i
		self.layer_chain_parallel = False
		self.zyngui.screens['engine'].set_midichain_mode(self.layers[i].midi_chan)
		self.layer_index_replace_engine = None
		self.zyngui.show_modal('engine')


	def add_layer_engine(self, eng, midi_chan=None, select=True):
		self.add_layer_eng=eng

		if eng=='MD':
			self.add_layer_midich(None)

		elif eng=='AE':
			self.add_layer_midich(0, False)
			self.add_layer_midich(1, False)
			self.add_layer_midich(2, False)
			self.add_layer_midich(3, False)
			self.fill_list()
			self.index=len(self.layers)-4
			self.layer_control()

		elif midi_chan is None:
			self.replace_layer_index=None
			self.zyngui.screens['midi_chan'].set_mode("ADD", 0, self.get_free_midi_chans())
			self.zyngui.show_modal('midi_chan')

		else:
			self.add_layer_midich(midi_chan, select)
			self.zyngui.screens['bank'].set_show_top_sounds(False)


	def add_layer_midich(self, midich, select=True):
		if self.add_layer_eng:
			zyngine = self.zyngui.screens['engine'].start_engine(self.add_layer_eng)
			self.add_layer_eng = None

			if not self.layer_index_replace_engine == None and len(self.layers) > self.index:
				layer = self.layers[self.layer_index_replace_engine]
				layer.set_engine(zyngine);
				self.zyngui.screens['engine'].stop_unused_engines()
				# initialize the bank
				self.zyngui.screens['bank'].show()
				self.zyngui.screens['bank'].select_action(0)
			else:
				layer = zynthian_layer(zyngine, midich, self.zyngui)

			# Try to connect Audio Effects ...
			if len(self.layers)>0 and layer.engine.type=="Audio Effect":
				if self.replace_layer_index is not None:
					self.replace_on_fxchain(layer)
				else:
					self.add_to_fxchain(layer, self.layer_chain_parallel)
					self.layers.append(layer)
			# Try to connect MIDI tools ...
			elif len(self.layers)>0 and layer.engine.type=="MIDI Tool":
				if self.replace_layer_index is not None:
					self.replace_on_midichain(layer)
				else:
					self.add_to_midichain(layer, self.layer_chain_parallel)
					self.layers.append(layer)
			# New root layer
			else:
				self.layers.append(layer)

			self.zyngui.zynautoconnect()

			if select:
				self.fill_list()
				root_layer = self.get_fxchain_root(layer)
				try:
					self.index = self.root_layers.index(root_layer)
					self.layer_control(layer)
					self.current_index_changed.emit()
				except Exception as e:
					logging.error(e)
					self.zyngui.show_screen('layer')
		self.layer_index_replace_engine = None
		if layer.engine.type != "Audio Effect":
			self.zyngui.show_screen('layer')
			self.zyngui.screens['layer'].select_action(self.zyngui.screens['layer'].index)
			self.zyngui.screens['bank'].select_action(0)


	def remove_layer(self, i, stop_unused_engines=True):
		if i>=0 and i<len(self.layers):
			logging.debug("Removing layer {} => {} ...".format(i, self.layers[i].get_basepath()))

			if self.layers[i].engine.type == "MIDI Tool":
				self.drop_from_midichain(self.layers[i])
				self.layers[i].mute_midi_out()
			else:
				self.drop_from_fxchain(self.layers[i])
				self.layers[i].mute_audio_out()

			self.zyngui.zynautoconnect(True)

			self.zyngui.zynautoconnect_acquire_lock()
			self.layers[i].reset()
			self.layers.pop(i)
			self.zyngui.zynautoconnect_release_lock()

			# Stop unused engines
			if stop_unused_engines:
				self.zyngui.screens['engine'].stop_unused_engines()


	@Slot(int)
	def remove_midichan_layer(self, chan: int):
		if chan < 0:
			return
		if chan in self.layer_midi_map:
			self.remove_root_layer(self.root_layers.index(self.layer_midi_map[chan]))


	@Slot(None)
	def ask_remove_current_layer(self):
		self.zyngui.show_confirm("Do you really want to remove this layer?", self.remove_current_layer)

	def remove_current_layer(self, params=None):
		logging.error("REMOVING".format(self.index))
		self.remove_root_layer(self.index)

	def remove_root_layer(self, i, stop_unused_engines=True):
		if i>=0 and i<len(self.root_layers):
			# For some engines (Aeolus, setBfree), delete all layers from the same engine
			if self.root_layers[i].engine.nickname in ['BF', 'AE']:
				root_layers_to_delete = copy.copy(self.root_layers[i].engine.layers)
			else:
				root_layers_to_delete = [self.root_layers[i]]

			# Mute Audio Layers & build list of layers to delete
			layers_to_delete = []
			for root_layer in root_layers_to_delete:
				# Midichain layers
				midichain_layers = self.get_midichain_layers(root_layer)
				if len(midichain_layers)>0:
					midichain_layers.remove(root_layer)
				layers_to_delete += midichain_layers
				for layer in reversed(midichain_layers):
					logging.debug("Mute MIDI layer '{}' ...".format(i, layer.get_basepath()))
					self.drop_from_midichain(layer)
					layer.mute_midi_out()
				# Fxchain layers => Mute!
				fxchain_layers = self.get_fxchain_layers(root_layer)
				if len(fxchain_layers)>0:
					fxchain_layers.remove(root_layer)
				layers_to_delete += fxchain_layers
				for layer in reversed(fxchain_layers):
					logging.debug("Mute Audio layer '{}' ...".format(i, layer.get_basepath()))
					self.drop_from_fxchain(layer)
					layer.mute_audio_out()
				# Root_layer
				layers_to_delete.append(root_layer)
				root_layer.mute_midi_out()
				root_layer.mute_audio_out()

			self.zyngui.zynautoconnect(True)

			# Remove layers
			self.zyngui.zynautoconnect_acquire_lock()
			for layer in layers_to_delete:
				try:
					i = self.layers.index(layer)
					self.layers[i].reset()
					self.layers.pop(i)
				except Exception as e:
					logging.error("Can't delete layer {} => {}".format(i,e))
			self.zyngui.zynautoconnect_release_lock()

			# Stop unused engines
			if stop_unused_engines:
				self.zyngui.screens['engine'].stop_unused_engines()

			# Recalculate selector and root_layers list
			self.fill_list()

			if self.zyngui.curlayer in self.root_layers:
				self.index = self.root_layers.index(self.zyngui.curlayer)
			else:
				self.index=0
				try:
					self.zyngui.set_curlayer(self.root_layers[self.index])
				except:
					self.zyngui.set_curlayer(None)

			self.set_selector()


	def remove_all_layers(self, stop_engines=True):
		# Remove all layers: Step 1 => Drop from FX chain and mute
		i = len(self.layers)
		while i>0:
			i -= 1
			logging.debug("Mute layer {} => {} ...".format(i, self.layers[i].get_basepath()))
			self.drop_from_midichain(self.layers[i])
			self.layers[i].mute_midi_out()
			self.drop_from_fxchain(self.layers[i])
			self.layers[i].mute_audio_out()

		self.zyngui.zynautoconnect(True)

		# Remove all layers: Step 2 => Delete layers
		i = len(self.layers)
		self.zyngui.zynautoconnect_acquire_lock()
		while i>0:
			i -= 1
			logging.debug("Remove layer {} => {} ...".format(i, self.layers[i].get_basepath()))
			self.layers[i].reset()
			self.layers.pop(i)
		self.zyngui.zynautoconnect_release_lock()

		# Stop ALL engines
		if stop_engines:
			self.zyngui.screens['engine'].stop_unused_engines()

		self.index=0
		self.zyngui.set_curlayer(None)

		# Refresh UI
		self.fill_list()
		self.set_selector()


	#----------------------------------------------------------------------------
	# Clone, Note Range & Transpose
	#----------------------------------------------------------------------------

	def set_clone(self, clone_status):
		for i in range(0,16):
			for j in range(0,16):
				if isinstance(clone_status[i][j],dict):
					zyncoder.lib_zyncoder.set_midi_filter_clone(i,j,clone_status[i][j]['enabled'])
					self.zyngui.screens['midi_cc'].set_clone_cc(i,j,clone_status[i][j]['cc'])
				else:
					zyncoder.lib_zyncoder.set_midi_filter_clone(i,j,clone_status[i][j])
					zyncoder.lib_zyncoder.reset_midi_filter_clone_cc(i,j)


	def reset_clone(self):
		for i in range(0,16):
			zyncoder.lib_zyncoder.reset_midi_filter_clone(i)


	def set_transpose(self, tr_status):
		for i in range(0,16):
			zyncoder.lib_zyncoder.set_midi_filter_halftone_trans(i, tr_status[i])


	def set_note_range(self, nr_status):
		for i in range(0,16):
			zyncoder.lib_zyncoder.set_midi_filter_note_range(i, nr_status[i]['note_low'], nr_status[i]['note_high'], nr_status[i]['octave_trans'], nr_status[i]['halftone_trans'])


	def reset_note_range(self):
		for i in range(0,16):
			zyncoder.lib_zyncoder.reset_midi_filter_note_range(i)


	#----------------------------------------------------------------------------
	# MIDI Control (ZS3 & PC)
	#----------------------------------------------------------------------------

	def set_midi_chan_preset(self, midich, preset_index):
		selected = False
		for layer in self.layers:
			mch=layer.get_midi_chan()
			if mch is None or mch==midich:
				# Fluidsynth engine => ignore Program Change on channel 9
				if layer.engine.nickname=="FS" and mch==9:
					continue
				if layer.set_preset(preset_index,True) and not selected:
					try:
						if not self.zyngui.modal_screen and self.zyngui.active_screen in ('control'):
							self.select_action(self.root_layers.index(layer))
						selected = True
					except Exception as e:
						logging.error("Can't select layer => {}".format(e))


	def set_midi_chan_zs3(self, midich, zs3_index):
		selected = False
		for layer in self.layers:
			if zynthian_gui_config.midi_single_active_channel or midich==layer.get_midi_chan():
				if layer.restore_zs3(zs3_index) and not selected:
					self.last_zs3_index[midich] = zs3_index
					try:
						if not self.zyngui.modal_screen and self.zyngui.active_screen not in ('main','layer'):
							self.select_action(self.root_layers.index(layer))
						selected = True
					except Exception as e:
						logging.error("Can't select layer => {}".format(e))


	def get_last_zs3_index(self, midich):
		return self.last_zs3_index[midich]


	def save_midi_chan_zs3(self, midich, zs3_index):
		result = False
		for layer in self.layers:
			mch=layer.get_midi_chan()
			if mch is None or mch==midich:
				layer.save_zs3(zs3_index)
				result = True
			elif zynthian_gui_config.midi_single_active_channel:
				layer.delete_zs3(zs3_index)

		return result


	def delete_midi_chan_zs3(self, midich, zs3_index):
		for layer in self.layers:
			if zynthian_gui_config.midi_single_active_channel or midich==layer.get_midi_chan():
				layer.delete_zs3(zs3_index)


	def get_midi_chan_zs3_status(self, midich, zs3_index):
		for layer in self.layers:
			if zynthian_gui_config.midi_single_active_channel or midich==layer.get_midi_chan():
				if layer.get_zs3(zs3_index):
					return True
		return False


	def get_midi_chan_zs3_used_indexes(self, midich):
		res=[]
		for i in range(128):
			if self.get_midi_chan_zs3_status(midich,i):
				res.append(i)
		return res


	def midi_control_change(self, chan, ccnum, ccval):
		for layer in self.layers + [self.amixer_layer]:
			layer.midi_control_change(chan, ccnum, ccval)


	#----------------------------------------------------------------------------
	# Audio Routing
	#----------------------------------------------------------------------------

	def get_audio_routing(self):
		res = {}
		for i, layer in enumerate(self.layers):
			res[layer.get_jackname()] = layer.get_audio_out()
		return res


	def set_audio_routing(self, audio_routing=None):
		for i, layer in enumerate(self.layers):
			try:
				layer.set_audio_out(audio_routing[layer.get_jackname()])
			except:
				layer.reset_audio_out()


	def reset_audio_routing(self):
		self.set_audio_routing()


	#----------------------------------------------------------------------------
	# Audio Capture
	#----------------------------------------------------------------------------

	def get_audio_capture(self):
		res = {}
		for i, layer in enumerate(self.layers):
			res[layer.get_jackname()] = layer.get_audio_in()
		return res


	def set_audio_capture(self, audio_capture=None):
		for i, layer in enumerate(self.layers):
			try:
				layer.set_audio_in(audio_capture[layer.get_jackname()])
			except:
				layer.reset_audio_in()


	def reset_audio_capture(self):
		self.set_audio_capture()


	#----------------------------------------------------------------------------
	# MIDI Routing
	#----------------------------------------------------------------------------

	def get_midi_routing(self):
		res={}
		for i, layer in enumerate(self.layers):
			res[layer.get_jackname()]=layer.get_midi_out()
		return res


	def set_midi_routing(self, midi_routing=None):
		for i, layer in enumerate(self.layers):
			try:
				layer.set_midi_out(midi_routing[layer.get_jackname()])
			except:
				layer.set_midi_out([])


	def reset_midi_routing(self):
		self.set_midi_routing()

	#----------------------------------------------------------------------------
	# Jackname managing
	#----------------------------------------------------------------------------

	def get_layer_by_jackname(self, jackname):
		for layer in self.layers:
			if layer.jackname in jackname:
				return layer


	def get_jackname_count(self, jackname):
		count = 0
		for layer in self.layers:
			if layer.jackname is not None and layer.jackname.startswith(jackname):
				count += 1
		return count


	# ---------------------------------------------------------------------------
	# FX-Chain
	# ---------------------------------------------------------------------------

	def get_fxchain_roots(self):
		roots = []

		for layer in self.layers:
			if layer.midi_chan==None and layer.engine.type in ("Special"):
				roots.append(layer)

		for chan in range(16):
			for layer in self.layers:
				if layer.midi_chan==chan:
					roots.append(layer)
					break

		return roots


	def get_fxchain_layers(self, layer=None):
		if layer is None:
			layer = self.zyngui.curlayer

		if layer is not None:
			fxchain_layers = []

			if layer.midi_chan is not None:
				for l in self.layers:
					if l.engine.type!="MIDI Tool" and l not in fxchain_layers and l.midi_chan==layer.midi_chan:
						fxchain_layers.append(l)

			elif layer in self.layers:
					fxchain_layers.append(layer)

			return fxchain_layers

		else:
			return None


	def get_fxchain_count(self, midi_chan):
		count = 0
		if midi_chan is not None:
			for l in self.layers:
				if l.engine.type in ("Audio Effect") and l.midi_chan==midi_chan:
						count += 1
		return count


	def get_fxchain_root(self, layer):
		if layer.midi_chan is None:
			return layer
		for l in self.layers:
			if l.midi_chan==layer.midi_chan:
				return l


	# Returns FX-chain layers routed to extra-chain ports or not routed at all.
	def get_fxchain_ends(self, layer):
		fxlbjn = {}
		for fxlayer in self.get_fxchain_layers(layer):
			fxlbjn[fxlayer.jackname] = fxlayer

		ends=[]
		for layer in fxlbjn.values():
			try:
				if layer.get_audio_out()[0] not in fxlbjn:
					ends.append(layer)
			except:
				ends.append(layer)

		return ends


	def get_fxchain_upstream(self, layer):
		ups=[]
		for uslayer in self.layers:
			if layer.get_jackname() in uslayer.get_audio_out():
				ups.append(uslayer)

		return ups


	def get_fxchain_downstream(self, layer):
		downs=[]
		for uslayer in self.layers:
			if uslayer.get_jackname() in layer.get_audio_out():
				downs.append(uslayer)

		return downs


	def get_fxchain_pars(self, layer):
		pars = [layer]
		#logging.error("FX ROOT LAYER => {}".format(layer.get_basepath()))
		for l in self.layers:
			if l!=layer and l.engine.type=="Audio Effect" and l.midi_chan==layer.midi_chan and collections.Counter(l.audio_out)==collections.Counter(layer.audio_out):
				pars.append(l)
				#logging.error("PARALLEL LAYER => {}".format(l.get_audio_jackname()))
		return pars


	def add_to_fxchain(self, layer, chain_parallel=False):
		try:
			for end in self.get_fxchain_ends(layer):
				if end!=layer:
					logging.debug("Adding to FX-chain {} => {}".format(end.get_audio_jackname(), layer.get_audio_jackname()))
					layer.set_audio_out(end.get_audio_out())
					if chain_parallel:
						for uslayer in self.get_fxchain_upstream(end):
							uslayer.add_audio_out(layer.get_audio_jackname())
					else:
						end.set_audio_out([layer.get_audio_jackname()])

		except Exception as e:
			logging.error("Error chaining Audio Effect ({})".format(e))


	def replace_on_fxchain(self, layer):
		try:
			rlayer = self.layers[self.replace_layer_index]
			logging.debug("Replacing on FX-chain {} => {}".format(rlayer.get_jackname(), layer.get_jackname()))
			
			# Re-route audio
			layer.set_audio_out(rlayer.get_audio_out())
			rlayer.mute_audio_out()
			for uslayer in self.get_fxchain_upstream(rlayer):
				uslayer.del_audio_out(rlayer.get_jackname())
				uslayer.add_audio_out(layer.get_jackname())

			# Replace layer in list
			self.layers[self.replace_layer_index] = layer

			# Remove old layer and stop unused engines
			self.zyngui.zynautoconnect_acquire_lock()
			rlayer.reset()
			self.zyngui.zynautoconnect_release_lock()
			self.zyngui.screens['engine'].stop_unused_engines()

			self.replace_layer_index = None

		except Exception as e:
			logging.error("Error replacing Audio Effect ({})".format(e))


	def drop_from_fxchain(self, layer):
		try:
			for up in self.get_fxchain_upstream(layer):
				logging.debug("Dropping from FX-chain {} => {}".format(up.get_jackname(), layer.get_jackname()))
				up.del_audio_out(layer.get_jackname())
				if len(up.get_audio_out())==0:
					up.set_audio_out(layer.get_audio_out())

		except Exception as e:
			logging.error("Error unchaining Audio Effect ({})".format(e))


	def swap_fxchain(self, layer1, layer2):
		ups1 = self.get_fxchain_upstream(layer1)
		ups2 = self.get_fxchain_upstream(layer2)

		self.zyngui.zynautoconnect_acquire_lock()

		# Move inputs from layer1 to layer2
		for l in ups1:
			l.add_audio_out(layer2.get_jackname())
			l.del_audio_out(layer1.get_jackname())

		# Move inputs from layer2 to layer1
		for l in ups2:
			l.add_audio_out(layer1.get_jackname())
			l.del_audio_out(layer2.get_jackname())

		# Swap outputs from layer1 & layer2
		ao1 = layer1.audio_out
		ao2 = layer2.audio_out
		layer1.set_audio_out(ao2)
		layer2.set_audio_out(ao1)

		self.zyngui.zynautoconnect_release_lock()

		# Swap position in layer list
		for i,layer in enumerate(self.layers):
			if layer==layer1:
				self.layers[i] = layer2

			elif layer==layer2:
				self.layers[i] = layer1

	# ---------------------------------------------------------------------------
	# MIDI-Chain
	# ---------------------------------------------------------------------------

	def get_midichain_roots(self):
		roots = []

		for layer in self.layers:
			if layer.midi_chan==None and layer.engine.type in ("Special"):
				roots.append(layer)

		for chan in range(16):
			rl = self.get_midichain_root_by_chan(chan)
			if rl:
				roots.append(rl)

		return roots


	def get_midichain_layers(self, layer=None):
		if layer is None:
			layer = self.zyngui.curlayer

		if layer is not None:
			midichain_layers = []

			if layer.midi_chan is not None:
				for l in self.layers:
					if l.engine.type in ("MIDI Synth", "MIDI Tool", "Special") and l not in midichain_layers and l.midi_chan==layer.midi_chan:
						midichain_layers.append(l)

			return midichain_layers

		else:
			return None


	def get_midichain_count(self, midi_chan):
		count = 0
		if midi_chan is not None:
			for l in self.layers:
				if l.engine.type in ("MIDI Tool") and l.midi_chan==midi_chan:
						count += 1
		return count


	def get_midichain_root(self, layer):
		if layer.midi_chan is None:
			return layer

		for l in self.layers:
			if l.engine.type=="MIDI Tool" and l.midi_chan==layer.midi_chan:
				return l

		for l in self.layers:
			if l.engine.type in ("MIDI Synth", "Special") and l.midi_chan==layer.midi_chan:
				return l

		return None


	def get_midichain_root_by_chan(self, chan):
		if chan is None:
			for l in self.layers:
				if l.midi_chan is None:
					return l

		else:
			for l in self.layers:
				if l.engine.type=="MIDI Tool" and l.midi_chan==chan:
					return l

			for l in self.layers:
				if l.engine.type in ("MIDI Synth", "Special") and l.midi_chan==chan:
					return l

		return None


	# Returns MIDI-chain layers routed to extra-chain ports or not routed at all.
	def get_midichain_ends(self, layer):
		midilbjn = {}
		for midilayer in self.get_midichain_layers(layer):
			midilbjn[midilayer.get_midi_jackname()] = midilayer

		ends = []
		for layer in midilbjn.values():
			try:
				if layer.get_midi_out()[0] not in midilbjn:
					ends.append(layer)
			except:
				ends.append(layer)

		return ends


	def get_midichain_upstream(self, layer):
		ups = []
		for uslayer in self.layers:
			if layer.get_midi_jackname() in uslayer.get_midi_out():
				ups.append(uslayer)

		return ups


	def get_midichain_downstream(self, layer):
		downs = []
		for uslayer in self.layers:
			if uslayer.get_midi_jackname() in layer.get_midi_out():
				downs.append(uslayer)

		return downs


	def get_midichain_pars(self, layer):
		pars = [layer]
		#logging.error("MIDI ROOT LAYER => {}".format(layer.get_basepath()))
		for l in self.layers:
			if l!=layer and l.engine.type=="MIDI Tool" and l.midi_chan==layer.midi_chan and collections.Counter(l.midi_out)==collections.Counter(layer.midi_out):
				pars.append(l)
				#logging.error("PARALLEL LAYER => {}".format(l.get_midi_jackname()))
		return pars


	def add_to_midichain(self, layer, chain_parallel=False):
		try:
			for end in self.get_midichain_ends(layer):
				if end!=layer:
					logging.debug("Adding to MIDI-chain {} => {}".format(end.get_midi_jackname(), layer.get_midi_jackname()))
					if end.engine.type=="MIDI Tool":
						layer.set_midi_out(end.get_midi_out())
						if chain_parallel:
							for uslayer in self.get_midichain_upstream(end):
								uslayer.add_midi_out(layer.get_midi_jackname())
						else:
							end.set_midi_out([layer.get_midi_jackname()])
					else:
						layer.set_midi_out([end.get_midi_jackname()])
						if chain_parallel:
							for uslayer in self.get_midichain_upstream(end):
								for uuslayer in self.get_midichain_upstream(uslayer):
									uuslayer.add_midi_out(layer.get_midi_jackname())
						else:
							for uslayer in self.get_midichain_upstream(end):
								uslayer.del_midi_out(end.get_midi_jackname())
								uslayer.add_midi_out(layer.get_midi_jackname())

		except Exception as e:
			logging.error("Error chaining MIDI tool ({})".format(e))


	def replace_on_midichain(self, layer):
		try:
			rlayer = self.layers[self.replace_layer_index]
			logging.debug("Replacing on MIDI-chain {} => {}".format(rlayer.get_midi_jackname(), layer.get_midi_jackname()))
			
			# Re-route audio
			layer.set_midi_out(rlayer.get_midi_out())
			rlayer.mute_midi_out()
			for uslayer in self.get_midichain_upstream(rlayer):
				uslayer.del_midi_out(rlayer.get_midi_jackname())
				uslayer.add_midi_out(layer.get_midi_jackname())

			# Replace layer in list
			self.layers[self.replace_layer_index] = layer

			# Remove old layer and stop unused engines
			self.zyngui.zynautoconnect_acquire_lock()
			rlayer.reset()
			self.zyngui.zynautoconnect_release_lock()
			self.zyngui.screens['engine'].stop_unused_engines()

			self.replace_layer_index = None

		except Exception as e:
			logging.error("Error replacing MIDI tool ({})".format(e))


	def drop_from_midichain(self, layer):
		try:
			for up in self.get_midichain_upstream(layer):
				logging.debug("Dropping from MIDI-chain {} => {}".format(up.get_midi_jackname(), layer.get_midi_jackname()))
				up.del_midi_out(layer.get_midi_jackname())
				if len(up.get_midi_out())==0:
					up.set_midi_out(layer.get_midi_out())

		except Exception as e:
			logging.error("Error unchaining MIDI tool ({})".format(e))


	def swap_midichain(self, layer1, layer2):
		ups1 = self.get_midichain_upstream(layer1)
		ups2 = self.get_midichain_upstream(layer2)

		self.zyngui.zynautoconnect_acquire_lock()

		# Move inputs from layer1 to layer2
		for l in ups1:
			l.add_midi_out(layer2.get_midi_jackname())
			l.del_midi_out(layer1.get_midi_jackname())

		# Move inputs from layer2 to layer1
		for l in ups2:
			l.add_midi_out(layer1.get_midi_jackname())
			l.del_midi_out(layer2.get_midi_jackname())

		# Swap outputs from layer1 & layer2
		mo1 = layer1.midi_out
		mo2 = layer2.midi_out
		layer1.set_midi_out(mo2)
		layer2.set_midi_out(mo1)

		self.zyngui.zynautoconnect_release_lock()

		# Swap position in layer list
		for i,layer in enumerate(self.layers):
			if layer==layer1:
				self.layers[i] = layer2

			elif layer==layer2:
				self.layers[i] = layer1

	# ---------------------------------------------------------------------------
	# Extended Config
	# ---------------------------------------------------------------------------


	def get_extended_config(self):
		xconfigs={}
		for zyngine in self.zyngui.screens['engine'].zyngines.values():
			xconfigs[zyngine.nickname]=zyngine.get_extended_config()
		return xconfigs


	def set_extended_config(self, xconfigs):
		for zyngine in self.zyngui.screens['engine'].zyngines.values():
			if zyngine.nickname in xconfigs:
				zyngine.set_extended_config(xconfigs[zyngine.nickname])


	#----------------------------------------------------------------------------
	# Snapshot Save & Load
	#----------------------------------------------------------------------------

	def save_snapshot(self, fpath):
		try:
			snapshot={
				'index':self.index,
				'layers':[],
				'clone':[],
				'note_range':[],
				'audio_capture': self.get_audio_capture(),
				'audio_routing': self.get_audio_routing(),
				'midi_routing': self.get_midi_routing(),
				'extended_config': self.get_extended_config(),
				'midi_profile_state': self.get_midi_profile_state(),
			}

			#Layers info
			for layer in self.layers:
				snapshot['layers'].append(layer.get_snapshot())

			if zynthian_gui_config.snapshot_mixer_settings and self.amixer_layer:
				snapshot['layers'].append(self.amixer_layer.get_snapshot())

			#Clone info
			for i in range(0,16):
				snapshot['clone'].append([])
				for j in range(0,16):
					clone_info = {
						'enabled': zyncoder.lib_zyncoder.get_midi_filter_clone(i,j),
						'cc': list(map(int,zyncoder.lib_zyncoder.get_midi_filter_clone_cc(i,j).nonzero()[0]))
					}
					snapshot['clone'][i].append(clone_info)

			#Note-range info
			for i in range(0,16):
				info = {
					'note_low': zyncoder.lib_zyncoder.get_midi_filter_note_low(i),
					'note_high': zyncoder.lib_zyncoder.get_midi_filter_note_high(i),
					'octave_trans': zyncoder.lib_zyncoder.get_midi_filter_octave_trans(i),
					'halftone_trans': zyncoder.lib_zyncoder.get_midi_filter_halftone_trans(i)
				}
				snapshot['note_range'].append(info)

			#Zynseq RIFF data
			if 'stepseq' in self.zyngui.screens:
				binary_riff_data = self.zyngui.screens['stepseq'].get_riff_data()
				b64_data = base64_encoded_data = base64.b64encode(binary_riff_data)
				snapshot['zynseq_riff_b64'] = b64_data.decode('utf-8')

			#JSON Encode
			json=JSONEncoder().encode(snapshot)
			logging.info("Saving snapshot %s => \n%s" % (fpath,json))

		except Exception as e:
			logging.error("Can't generate snapshot: %s" %e)
			return False

		try:
			with open(fpath,"w") as fh:
				fh.write(json)
				fh.flush()
				os.fsync(fh.fileno())

		except Exception as e:
			logging.error("Can't save snapshot '%s': %s" % (fpath,e))
			return False

		self.last_snapshot_fpath = fpath
		return True


	def load_snapshot(self, fpath, quiet=False):
		try:
			with open(fpath,"r") as fh:
				json=fh.read()
				logging.info("Loading snapshot %s => \n%s" % (fpath,json))

		except Exception as e:
			logging.error("Can't load snapshot '%s': %s" % (fpath,e))
			return False

		try:
			snapshot=JSONDecoder().decode(json)

			#Clean all layers, but don't stop unused engines
			self.remove_all_layers(False)

			# Reusing Jalv engine instances raise problems (audio routing & jack names, etc..),
			# so we stop Jalv engines!
			self.zyngui.screens['engine'].stop_unused_jalv_engines()

			#Create new layers, starting engines when needed
			i = 0
			for lss in snapshot['layers']:
				if lss['engine_nick']=="MX":
					if zynthian_gui_config.snapshot_mixer_settings:
						snapshot['amixer_layer'] = lss
					del(snapshot['layers'][i])
				else:
					engine=self.zyngui.screens['engine'].start_engine(lss['engine_nick'])
					self.layers.append(zynthian_layer(engine,lss['midi_chan'], self.zyngui))
				i += 1

			# Finally, stop all unused engines
			self.zyngui.screens['engine'].stop_unused_engines()

			#Restore MIDI profile state
			if 'midi_profile_state' in snapshot:
				self.set_midi_profile_state(snapshot['midi_profile_state'])

			#Set MIDI Routing
			if 'midi_routing' in snapshot:
				self.set_midi_routing(snapshot['midi_routing'])
			else:
				self.reset_midi_routing()

			#Autoconnect MIDI
			self.zyngui.zynautoconnect_midi(True)

			#Set extended config
			if 'extended_config' in snapshot:
				self.set_extended_config(snapshot['extended_config'])

			# Restore layer state, step 1 => Restore Bank & Preset Status
			i = 0
			for lss in snapshot['layers']:
				self.layers[i].restore_snapshot_1(lss)
				i += 1

			# Restore layer state, step 2 => Restore Controllers Status
			i = 0
			for lss in snapshot['layers']:
				self.layers[i].restore_snapshot_2(lss)
				i += 1

			#Set Audio Routing
			if 'audio_routing' in snapshot:
				self.set_audio_routing(snapshot['audio_routing'])
			else:
				self.reset_audio_routing()

			#Set Audio Capture
			if 'audio_capture' in snapshot:
				self.set_audio_capture(snapshot['audio_capture'])
			else:
				self.reset_audio_routing()

			#Autoconnect Audio
			self.zyngui.zynautoconnect_audio()

			# Restore ALSA Mixer settings
			if self.amixer_layer and 'amixer_layer' in snapshot:
				self.amixer_layer.restore_snapshot_1(snapshot['amixer_layer'])
				self.amixer_layer.restore_snapshot_2(snapshot['amixer_layer'])

			#Fill layer list
			self.fill_list()

			#Set active layer
			if snapshot['index']<len(self.layers):
				self.index = snapshot['index']
				self.zyngui.set_curlayer(self.layers[self.index])
			elif len(self.layers)>0:
				self.index = 0
				self.zyngui.set_curlayer(self.layers[self.index])

			#Set Clone
			if 'clone' in snapshot:
				self.set_clone(snapshot['clone'])
			else:
				self.reset_clone()

			# Note-range & Tranpose
			self.reset_note_range()
			if 'note_range' in snapshot:
				self.set_note_range(snapshot['note_range'])
			#BW compat.
			elif 'transpose' in snapshot:
				self.set_transpose(snapshot['transpose'])

			#Zynseq RIFF data
			if 'zynseq_riff_b64' in snapshot and 'stepseq' in self.zyngui.screens:
				b64_bytes = snapshot['zynseq_riff_b64'].encode('utf-8')
				binary_riff_data = base64.decodebytes(b64_bytes)
				self.zyngui.screens['stepseq'].restore_riff_data(binary_riff_data)

			#Post action
			if not quiet:
				if self.index<len(self.root_layers):
					self.select_action(self.index)
				else:
					self.index = 0
					self.zyngui.show_screen('layer')

			self.ensure_special_layers_midi_cloned()


		except Exception as e:
			self.zyngui.reset_loading()
			logging.exception("Invalid snapshot: %s" % e)
			return False

		self.last_snapshot_fpath = fpath
		return True

	# snapshot is an array of objects with snapshots of few selected layers, replaces them if existing
	# All restored channels will be cloned among themselves
	def load_channels_snapshot(self, snapshot, from_channel, to_channel, channels_mapping = {}):
		if not isinstance(snapshot, dict):
			return []
		if not isinstance(channels_mapping, dict):
			return []
		if not "layers" in snapshot:
			return []
		if not isinstance(snapshot["layers"], list):
			return []
		self.zyngui.start_loading()
		for i in range(from_channel, to_channel + 1):
			for j in range(from_channel, to_channel + 1):
				if i in self.layer_midi_map and j in self.layer_midi_map and zyncoder.lib_zyncoder.get_midi_filter_clone(i, j):
					self.remove_clone_midi(i, j)
		restored_layers = []
		restored_channels = []
		restored_jacknames = []
		for layer_data in snapshot["layers"]:
			if "midi_chan" in layer_data and "engine_nick" in layer_data:
				midi_chan = layer_data["midi_chan"]
				if str(midi_chan) in channels_mapping and isinstance(channels_mapping[str(midi_chan)], int):
					midi_chan = channels_mapping[str(midi_chan)]
				if midi_chan >= from_channel and midi_chan <= to_channel:
					if midi_chan in self.layer_midi_map:
						self.remove_root_layer(self.root_layers.index(self.layer_midi_map[midi_chan]), True)
					engine = self.zyngui.screens['engine'].start_engine(layer_data['engine_nick'])
					new_layer = zynthian_layer(engine, midi_chan, self.zyngui)
					new_layer.restore_snapshot_1(layer_data)
					new_layer.restore_snapshot_2(layer_data)
					sublayers = self.get_fxchain_layers(new_layer) + self.get_midichain_layers(new_layer)
					for layer in sublayers:
						layer.set_midi_chan(midi_chan)
					self.layers.append(new_layer)
					restored_layers.append(new_layer)
					restored_channels.append(new_layer.midi_chan)
					restored_jacknames.append(new_layer.get_jackname())
		# try to map the jacknames of therestored channels with what it was snapshotted
		snapshotted_jacknames = []
		for jackname in snapshot['audio_routing']:
			if not jackname in snapshotted_jacknames: snapshotted_jacknames.append(jackname)
			for out in snapshot['audio_routing'][jackname]:
				if not out in snapshotted_jacknames: snapshotted_jacknames.append(out)
		restored_jacknames.sort()
		snapshotted_jacknames.sort()
		jacknames_r_s_map = {}
		jacknames_s_r_map = {}
		for rj in restored_jacknames:
			rjsize = len(rj)
			basename = rj[:rjsize - 3]
			for sj in snapshotted_jacknames:
				if basename == sj[:rjsize - 3]:
					jacknames_r_s_map[rj] = sj
					jacknames_s_r_map[sj] = rj
					snapshotted_jacknames.remove(sj)
					break

		if 'audio_routing' in snapshot:
			for layer in restored_layers:
				#Set Audio Routing: we have to remap all the jacknames that were saved on audio routing
				if layer.get_jackname() in jacknames_r_s_map:
					mapped_source_jackname = jacknames_r_s_map[layer.get_jackname()]
					if mapped_source_jackname in snapshot['audio_routing']:
						mapped_out_jacknames = []
						for name in snapshot['audio_routing'][mapped_source_jackname]:
							if name in jacknames_s_r_map:
								mapped_out_jacknames.append(jacknames_s_r_map[name])
						if len(mapped_out_jacknames) > 0:
							layer.set_audio_out(mapped_out_jacknames)
						else:
							layer.reset_audio_out()
				else:
					layer.reset_audio_out()
		else:
			for layer in restored_layers:
				layer.reset_audio_out()

		#TODO: always clone?
		for i in restored_channels:
			for j in restored_channels:
				if not zyncoder.lib_zyncoder.get_midi_filter_clone(i, j):
					zyncoder.lib_zyncoder.set_midi_filter_clone(i, j, True)

		self.zyngui.zynautoconnect_midi()
		self.zyngui.zynautoconnect_audio()

		self.fill_list()
		self.zyngui.stop_loading()
		return restored_layers




	@Slot(str)
	def load_soundset_from_file(self, file_name):
		try:
			f = open(self.__soundsets_basepath__ + file_name, "r")
			for i in range(5):
				self.remove_midichan_layer(i)
			layers = self.load_channels_snapshot(JSONDecoder().decode(f.read()), 0, 5)
			if len(layers) > 0:
				try:
					self.activate_index(root_layers.index(layers[0]))
				except:
					self.activate_index(0)
			else:
				self.activate_index(0)
			self.zyngui.screens['bank'].set_show_top_sounds(False)
		except Exception as e:
			logging.error(e)

	@Slot(str, result='QVariantList')
	def load_layer_channels_from_file(self, file_name):
		result = []
		try:
			f = open(self.__sounds_basepath__ + file_name, "r")
			snapshot = JSONDecoder().decode(f.read())
			if not isinstance(snapshot, dict):
				return
			if not "layers" in snapshot:
				return
			if not isinstance(snapshot["layers"], list):
				return
			for layer_data in snapshot["layers"]:
				if "midi_chan" in layer_data:
					midi_chan = layer_data['midi_chan']
					if not midi_chan in result:
						result.append(midi_chan)
			self.zyngui.screens['bank'].set_show_top_sounds(False)
		except Exception as e:
			logging.error(e)
		return result


	@Slot(str, 'QVariantMap')
	def load_layer_from_file(self, file_name, channels_mapping):
		try:
			f = open(self.__sounds_basepath__ + file_name, "r")
			self.load_channels_snapshot(JSONDecoder().decode(f.read()), 0, 16, channels_mapping)
			self.activate_index(self.index)
			self.zyngui.screens['bank'].set_show_top_sounds(False)
		except Exception as e:
			logging.error(e)

	def export_multichannel_snapshot(self, midi_chan):
		channels = [midi_chan]
		for i in range(16):
			if zyncoder.lib_zyncoder.get_midi_filter_clone(midi_chan, i):
				channels.append(i)
		if channels:
			return self.export_channels_snapshot(channels)
		else:
			return {}

	def export_channels_snapshot(self, channels):
		if not isinstance(channels, list):
			return
		snapshot = {"layers": [], "audio_routing": {}}
		# Double iteration because many layers can be on the same channel (one instrument + arbitrary effects)
		for layer in self.layers:
			if layer.midi_chan in channels:
				snapshot["layers"].append(layer.get_snapshot())
				snapshot["audio_routing"][layer.get_jackname()] = layer.get_audio_out()
		return snapshot


	@Slot(str, result=bool)
	def soundset_file_exists(self, file_name):
		final_name = file_name
		if not final_name.endswith(".json"):
				final_name += ".json"
		return os.path.isfile(self.__soundsets_basepath__ + final_name)


	@Slot(str, result=bool)
	def layer_file_exists(self, file_name):
		final_name = file_name
		if not final_name.endswith(".json"):
				final_name += ".json"
		return os.path.isfile(self.__sounds_basepath__ + final_name)

	@Slot(str)
	def save_curlayer_to_file(self, file_name):
		try:
			final_name = file_name
			if not final_name.endswith(".json"):
				final_name += ".json"
			Path(self.__sounds_basepath__).mkdir(parents=True, exist_ok=True)
			f = open(self.__sounds_basepath__ + final_name, "w")
			f.write(JSONEncoder().encode(self.export_multichannel_snapshot(self.zyngui.curlayer.midi_chan))) #TODO: get cloned midi channels
			f.close()
		except Exception as e:
			logging.error(e)

	@Slot(str)
	def save_soundset_to_file(self, file_name):
		try:
			final_name = file_name
			if not final_name.endswith(".json"):
				final_name += ".json"
			Path(self.__soundsets_basepath__).mkdir(parents=True, exist_ok=True)
			f = open(self.__soundsets_basepath__ + final_name, "w")
			f.write(JSONEncoder().encode(self.export_channels_snapshot(list(range(0, 5)))))
			f.close()
		except Exception as e:
			logging.error(e)


	@Slot(None)
	def ensure_special_layers_midi_cloned(self):
		for i in range(5, 10):
			for j in range(5, 10):
				if i in self.layer_midi_map and j in self.layer_midi_map and not zyncoder.lib_zyncoder.get_midi_filter_clone(i, j):
					logging.error("CLONING {} TO {}".format(i, j))
					self.clone_midi(i, j)
				#elif zyncoder.lib_zyncoder.get_midi_filter_clone(i, j):
					#self.remove_clone_midi(i, j)

	@Slot(int, int, result=bool)
	def is_midi_cloned(self, from_chan: int, to_chan: int):
		return zyncoder.lib_zyncoder.get_midi_filter_clone(from_chan, to_chan)

	@Slot(int, int)
	def clone_midi(self, from_chan: int, to_chan: int):
		if from_chan == to_chan:
			return
		zyncoder.lib_zyncoder.set_midi_filter_clone(from_chan, to_chan, 1)

	@Slot(int, int)
	def remove_clone_midi(self, from_chan: int, to_chan: int):
		if from_chan == to_chan:
			return
		zyncoder.lib_zyncoder.set_midi_filter_clone(from_chan, to_chan, 0)

	@Slot(int, int)
	def copy_midichan_layer(self, from_midichan: int, to_midichan: int):
		if from_midichan < 0 or to_midichan < 0:
			return
		if from_midichan in self.layer_midi_map:
			self.zyngui.start_loading()
			# If there was anything in that midi chan, remove it
			if to_midichan in self.layer_midi_map:
				self.remove_root_layer(self.root_layers.index(self.layer_midi_map[to_midichan]), True)
			layer_to_copy = self.layer_midi_map[from_midichan]
			logging.error("COPYING {} {}".format(from_midichan, to_midichan))
			engine = self.zyngui.screens['engine'].start_engine(layer_to_copy.engine.nickname)
			new_layer = zynthian_layer(engine, to_midichan, self.zyngui)
			#new_layer.set_bank(layer_to_copy.bank_index)
			snapshot = layer_to_copy.get_snapshot()
			new_layer.restore_snapshot_1(snapshot)
			new_layer.restore_snapshot_2(snapshot)
			sublayers = self.get_fxchain_layers(new_layer) + self.get_midichain_layers(new_layer)
			for layer in sublayers:
				layer.set_midi_chan(to_midichan)
			self.zyngui.zynautoconnect_midi()
			new_layer.reset_audio_out()
			self.layers.append(new_layer)

			self.fill_list()
			self.zyngui.stop_loading()


	def get_midi_profile_state(self):
		# Get MIDI profile state from environment
		midi_profile_state = OrderedDict()
		for key in os.environ.keys():
			if key.startswith("ZYNTHIAN_MIDI_"):
				midi_profile_state[key[14:]] = os.environ[key]
		return midi_profile_state


	def set_midi_profile_state(self, mps):
		# Load MIDI profile from saved state
		if mps is not None:
			for key in mps:
				os.environ["ZYNTHIAN_MIDI_" + key] = mps[key]
			zynthian_gui_config.set_midi_config()
			self.zyngui.init_midi()
			self.zyngui.init_midi_services()
			self.zyngui.zynautoconnect()
			return True


	def reset_midi_profile(self):
		self.zyngui.reload_midi_config()


	def set_select_path(self):
		self.select_path = "Layers"
		#self.select_path_element = str(zyngui.curlayer.engine.name)
		if self.zyngui.curlayer is None:
			midi_chan = zyncoder.lib_zyncoder.get_midi_active_chan()
			if midi_chan >= 0:
				self.select_path_element = str(midi_chan + 1)
			else:
				self.select_path_element = "Layers"
		else:
			self.select_path_element = str(self.zyngui.curlayer.midi_chan + 1)
		super().set_select_path()


	def get_engine_nick(self):
		return self.zyngui.curlayer.engine.nickname



	engine_nick_changed = Signal()

	engine_nick = Property(str, get_engine_nick, notify = engine_nick_changed)


#------------------------------------------------------------------------------
