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
import logging
from json import JSONEncoder, JSONDecoder

# Zynthian specific modules
from zyncoder import *
from . import zynthian_gui_config
from . import zynthian_gui_selector
from zyngine import zynthian_layer


#------------------------------------------------------------------------------
# Configure logging
#------------------------------------------------------------------------------


# Set root logging level
logging.basicConfig(stream=sys.stderr, level=zynthian_gui_config.log_level)


#------------------------------------------------------------------------------
# Zynthian Layer Selection GUI Class
#------------------------------------------------------------------------------


class zynthian_gui_layer(zynthian_gui_selector):


	def __init__(self):
		self.layers = []
		self.curlayer = None
		self.add_layer_eng = None
		self.last_snapshot_fpath = None
		super().__init__('Layer', True)


	def reset(self):
		self.reset_clone()
		self.reset_transpose()
		self.remove_all_layers()
		self.layers=[]
		self.curlayer=None
		self.index=0
		self.fill_list()


	def fill_list(self):
		self.list_data=[]
		#Add list of layers
		for i,layer in enumerate(self.layers):
			self.list_data.append((str(i+1),i,layer.get_presetpath()))
		#Add fixed entries
		if len(self.layers)>0:
			self.list_data.append((None,len(self.list_data),"--------------------------"))
		self.list_data.append(('NEW_SYNTH',len(self.list_data),"NEW Synth Layer"))
		self.list_data.append(('NEW_EFFECT',len(self.list_data),"NEW Effect Layer"))
		self.list_data.append(('NEW_GENERATOR',len(self.list_data),"NEW Generator Layer"))
		self.list_data.append(('NEW_SPECIAL',len(self.list_data),"NEW Special Layer"))
		self.list_data.append(('RESET',len(self.list_data),"REMOVE ALL"))
		self.list_data.append((None,len(self.list_data),"--------------------------"))
		self.list_data.append(('ALL_NOTES_OFF',len(self.list_data),"PANIC! All Notes Off"))
		self.list_data.append(('ALL_SOUNDS_OFF',len(self.list_data),"PANIC!!! All Sounds Off"))
		super().fill_list()


	def select_action(self, i):
		self.index=i
		if self.list_data[self.index][0] is None:
			pass
		elif self.list_data[self.index][0]=='NEW_SYNTH':
			self.add_layer("MIDI Synth")
		elif self.list_data[self.index][0]=='NEW_EFFECT':
			self.add_layer("Audio Effect")
		elif self.list_data[self.index][0]=='NEW_GENERATOR':
			self.add_layer("Audio Generator")
		elif self.list_data[self.index][0]=='NEW_SPECIAL':
			self.add_layer("Special")
		elif self.list_data[self.index][0]=='RESET':
			self.reset()
		elif self.list_data[self.index][0]=='ALL_NOTES_OFF':
			zynthian_gui_config.zyngui.all_notes_off()
		elif self.list_data[self.index][0]=='ALL_SOUNDS_OFF':
			zynthian_gui_config.zyngui.all_sounds_off()
		else:
			self.curlayer=self.layers[self.index]
			zynthian_gui_config.zyngui.set_curlayer(self.curlayer)
			# If there is an preset selection for the active layer ...
			if self.curlayer.get_preset_name():
				zynthian_gui_config.zyngui.show_screen('control')
			else:
				zynthian_gui_config.zyngui.show_screen('bank')
				# If there is only one bank, jump to preset selection
				if len(self.curlayer.bank_list)<=1:
					zynthian_gui_config.zyngui.screens['bank'].select_action(0)


	def next(self):
		self.index=self.index+1;
		if self.index>=len(self.layers):
			self.index=0
		self.select_listbox(self.index)
		self.select_action(self.index)


	def get_num_layers(self):
		return len(self.layers)


	def get_layer_selected(self):
		i=self.get_cursel()
		if i<len(self.layers):
			return i
		else:
			return None


	def add_layer(self, etype):
		self.add_layer_eng=None
		zynthian_gui_config.zyngui.screens['engine'].set_engine_type(etype)
		zynthian_gui_config.zyngui.show_modal('engine')


	def add_layer_engine(self, eng):
		self.add_layer_eng=eng
		if eng.nickname=='MD' or eng.nickname=='PD':
			self.add_layer_midich(None)
		elif eng.nickname=='AE':
			self.add_layer_midich(0,False)
			self.add_layer_midich(1,False)
			self.add_layer_midich(2,False)
			self.add_layer_midich(3,False)
			self.index=len(self.layers)-4
			self.select_action(self.index)
		else:
			zynthian_gui_config.zyngui.screens['midi_chan'].set_mode("ADD")
			zynthian_gui_config.zyngui.show_modal('midi_chan')


	def add_layer_midich(self, midich, select=True):
		if self.add_layer_eng:
			layer=zynthian_layer(self.add_layer_eng, midich,zynthian_gui_config.zyngui)

			# Try to connect effects ...
			if len(self.layers)>0 and layer.engine.type=="Audio Effect":
				self.add_to_fxchain(layer)

			self.layers.append(layer)
			zynthian_gui_config.zyngui.zynautoconnect()

			self.fill_list()

			if select:
				self.index=len(self.layers)-1
				self.select_action(self.index)


	def remove_layer(self, i, cleanup_unused_engines=True):
		if i>=0 and i<len(self.layers):
			self.drop_from_fxchain(self.layers[i])
			zynthian_gui_config.zyngui.zynautoconnect()

			zynthian_gui_config.zyngui.zynautoconnect_acquire_lock()
			self.layers[i].reset()
			del self.layers[i]
			zynthian_gui_config.zyngui.zynautoconnect_release_lock()

			if len(self.layers)==0:
				self.index=0
				self.curlayer=None
			elif self.index>(len(self.layers)-1):
				self.index=len(self.layers)-1
				self.curlayer=self.layers[self.index]
			else:
				self.curlayer=self.layers[self.index-1]

			self.fill_list()
			self.set_selector()
			zynthian_gui_config.zyngui.set_curlayer(self.curlayer)
			if cleanup_unused_engines:
				zynthian_gui_config.zyngui.screens['engine'].clean_unused_engines()


	def remove_all_layers(self, cleanup_unused_engines=True):
		while len(self.layers)>0:
			self.remove_layer(0, False)
		if cleanup_unused_engines:
			zynthian_gui_config.zyngui.screens['engine'].clean_unused_engines()


	#def refresh(self):
	#	self.curlayer.refresh()


	#----------------------------------------------------------------------------
	# Clone & Transpose
	#----------------------------------------------------------------------------


	def set_clone(self, clone_status):
		for i in range(0,16):
			for j in range(0,16):
				zyncoder.lib_zyncoder.set_midi_filter_clone(i,j,clone_status[i][j])


	def reset_clone(self):
		for i in range(0,16):
			for j in range(0,16):
				zyncoder.lib_zyncoder.set_midi_filter_clone(i,j,0)


	def set_transpose(self, transpose_status):
		for i in range(0,16):
			zyncoder.lib_zyncoder.set_midi_filter_transpose(i,transpose_status[i])


	def reset_transpose(self):
		for i in range(0,16):
			zyncoder.lib_zyncoder.set_midi_filter_transpose(i,0)


	#----------------------------------------------------------------------------
	# MIDI Control (ZS3 & CC)
	#----------------------------------------------------------------------------

	def set_midi_chan_preset(self, midich, preset_index):
		for layer in self.layers:
			mch=layer.get_midi_chan()
			if mch is None or mch==midich:
				layer.set_preset(preset_index,True)


	def set_midi_chan_zs3(self, midich, zs3_index):
		selected = False
		for layer in self.layers:
			if zynthian_gui_config.midi_single_active_channel or midich==layer.get_midi_chan():
				if layer.restore_zs3(zs3_index) and not selected:
					try:
						self.select_action(self.layers.index(layer))
						selected = True
					except Exception as e:
						logging.error("Can't select layer => {}".format(e))


	def save_midi_chan_zs3(self, midich, zs3_index):
		for layer in self.layers:
			mch=layer.get_midi_chan()

			if mch is None or mch==midich:
				layer.save_zs3(zs3_index)
			elif zynthian_gui_config.midi_single_active_channel:
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
		for layer in self.layers:
			layer.midi_control_change(chan, ccnum, ccval)


	#----------------------------------------------------------------------------
	# Audio Routing
	#----------------------------------------------------------------------------


	def get_audio_routing(self):
		res={}
		for i, layer in enumerate(self.layers):
			res[layer.get_jackname()]=layer.get_audio_out()
		return res


	def set_audio_routing(self, audio_routing=None):
		for i, layer in enumerate(self.layers):
			try:
				layer.set_audio_out(audio_routing[layer.get_jackname()])
			except:
				layer.set_audio_out(["system"])


	def reset_audio_routing(self):
		self.set_audio_routing()


	# ---------------------------------------------------------------------------
	# FX-Chain
	# ---------------------------------------------------------------------------


	def get_fxchain_ends(self, layer):
		ends=[]
		for uslayer in reversed(self.layers):
			if uslayer.get_jackname()!=layer.get_jackname():
				if layer.get_midi_chan()==uslayer.get_midi_chan() and 'system' in uslayer.get_audio_out():
					ends.append(uslayer)

		return ends


	def get_fxchain_upstream(self, layer):
		ups=[]
		for uslayer in self.layers:
			if layer.get_jackname() in uslayer.get_audio_out():
				ups.append(uslayer)

		return ups


	def add_to_fxchain(self, layer):
		try:
			ends=self.get_fxchain_ends(layer)
			if len(ends)>0:
				for end in ends:
					logging.debug("Adding to FX-chain {} => {}".format(end.get_jackname(), layer.get_jackname()))
					end.add_audio_out(layer.get_jackname())
					end.del_audio_out("system")
			else:
				logging.warning("Can't find the FX chain end ({})".format(layer.get_jackname()))

		except Exception as e:
			logging.error("Error chaining effect ({})".format(e))


	def drop_from_fxchain(self, layer):
		try:
			ups=self.get_fxchain_upstream(layer)
			if len(ups)>0:
				for up in ups:
					logging.debug("Dropping from FX-chain {} => {}".format(up.get_jackname(), layer.get_jackname()))
					up.del_audio_out(layer.get_jackname())
					for ao in layer.get_audio_out():
						up.add_audio_out(ao)

		except Exception as e:
			logging.error("Error unchaining effect ({})".format(e))


	# ---------------------------------------------------------------------------
	# Extended Config
	# ---------------------------------------------------------------------------


	def get_extended_config(self):
		xconfigs={}
		for zyngine in zynthian_gui_config.zyngui.screens['engine'].zyngines.values():
			xconfigs[zyngine.nickname]=zyngine.get_extended_config()
		return xconfigs


	def set_extended_config(self, xconfigs):
		for zyngine in zynthian_gui_config.zyngui.screens['engine'].zyngines.values():
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
				'transpose':[],
				'audio_routing': self.get_audio_routing(),
				'extended_config': self.get_extended_config()
			}
			#Layers info
			for layer in self.layers:
				snapshot['layers'].append(layer.get_snapshot())
			#Clone info
			for i in range(0,16):
				snapshot['clone'].append([])
				for j in range(0,16):
					snapshot['clone'][i].append(zyncoder.lib_zyncoder.get_midi_filter_clone(i,j))
			#Transpose info
			for i in range(0,16):
				snapshot['transpose'].append(zyncoder.lib_zyncoder.get_midi_filter_transpose(i))
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
			self.last_snapshot_fpath=fpath
		except Exception as e:
			logging.error("Can't save snapshot '%s': %s" % (fpath,e))
			return False
		return True


	def load_snapshot(self, fpath):
		try:
			with open(fpath,"r") as fh:
				json=fh.read()
				logging.info("Loading snapshot %s => \n%s" % (fpath,json))
			self.last_snapshot_fpath=fpath
		except Exception as e:
			logging.error("Can't load snapshot '%s': %s" % (fpath,e))
			return False
		try:
			snapshot=JSONDecoder().decode(json)
			#Clean all layers
			self.remove_all_layers(False)
			#Start engines
			for lss in snapshot['layers']:
				engine=zynthian_gui_config.zyngui.screens['engine'].start_engine(lss['engine_nick'])
				self.layers.append(zynthian_layer(engine,lss['midi_chan'],zynthian_gui_config.zyngui))
			#Remove unused engines
			zynthian_gui_config.zyngui.screens['engine'].clean_unused_engines()
			#Set extended config
			if 'extended_config' in snapshot:
				self.set_extended_config(snapshot['extended_config'])
			#Load layers
			i=0
			for lss in snapshot['layers']:
				self.layers[i].restore_snapshot(lss)
				i+=1
			#Fill layer list
			self.fill_list()
			#Set active layer
			self.index=snapshot['index']
			self.curlayer=self.layers[self.index]
			zynthian_gui_config.zyngui.set_curlayer(self.curlayer)
			#Set Clone
			if 'clone' in snapshot:
				self.set_clone(snapshot['clone'])
			else:
				self.reset_clone()
			#Set Transpose
			if 'transpose' in snapshot:
				self.set_transpose(snapshot['transpose'])
			else:
				self.reset_transpose()
			#Set CC-Map
			#TODO
			#Set Audio Routing
			if 'audio_routing' in snapshot:
				self.set_audio_routing(snapshot['audio_routing'])
			else:
				self.reset_audio_routing()
			#Post action
			if self.list_data[self.index][0] in ('NEW','RESET'):
				self.index=0
				zynthian_gui_config.zyngui.show_screen('layer')
			else:
				self.select_action(self.index)
		except Exception as e:
			logging.error("Invalid snapshot format: %s" % e)
			return False
		return True


	def set_select_path(self):
		self.select_path.set("Layer List")


#------------------------------------------------------------------------------
