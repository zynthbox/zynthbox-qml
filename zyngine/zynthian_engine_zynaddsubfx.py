# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian Engine (zynthian_engine_zynaddsubfx)
# 
# zynthian_engine implementation for ZynAddSubFX Synthesizer
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
import copy
import logging
import liblo
from time import sleep
from os.path import isfile, join
from . import zynthian_engine

#------------------------------------------------------------------------------
# ZynAddSubFX Engine Class
#------------------------------------------------------------------------------

class zynthian_engine_zynaddsubfx(zynthian_engine):

	# ---------------------------------------------------------------------------
	# Controllers & Screens
	# ---------------------------------------------------------------------------

	# MIDI Controllers
	_ctrls=[
		['volume','/part$i/Pvolume',96],
		#['volume',7,96],
		['pan',10,64],
		['expression',11,127],
		['cutoff',74,64],
		['resonance',71,64],
		['drum on/off','/part$i/Pdrummode','off','off|on'],
		['legato on/off','/part$i/Plegatomode','off','off|on'],
		['poly on/off','/part$i/Ppolymode','on','off|on'],
		['sustain on/off',64,'off','off|on'],
		['portamento on/off',65,'off','off|on'],
		['portamento time',5,64],
		#['portamento on/off','/part$ch/ctl/portamento.receive','off','off|on'],
		#['portamento time','/part$ch/ctl/portamento.time',64]
		['modulation',1,0],
		['modulation amplitude',76,127],
		['bandwidth',75,64],
		['resonance frequency',77,64],
		['resonance bandwidth',78,64]
	]

	# Controller Screens
	_ctrl_screens=[
		['main',['volume','pan','cutoff','resonance']],
		['mode',['volume','drum on/off','legato on/off','poly on/off']],
		#['mode',['volume','gain','legato on/off','poly on/off']],
		['portamento',['volume','sustain on/off','portamento on/off','portamento time']],
		['modulation',['volume','expression','modulation','modulation amplitude']],
		['resonance',['volume','bandwidth','resonance frequency','resonance bandwidth']]
	]

	#----------------------------------------------------------------------------
	# Initialization
	#----------------------------------------------------------------------------

	def __init__(self, zyngui=None):
		super().__init__(zyngui)
		self.name="ZynAddSubFX"
		self.nickname="ZY"

		if self.config_remote_display():
			self.command=("/usr/local/bin/zynaddsubfx", "-O", "jack", "-I", "jack", "-P", str(self.osc_target_port), "-a")
		else:
			self.command=("/usr/local/bin/zynaddsubfx", "-O", "jack", "-I", "jack", "-P", str(self.osc_target_port), "-a", "-U")

		self.conf_dir="./data/zynconf"
		self.bank_dirs=[
			('MY', os.getcwd()+"/my-data/zynbanks"),
			('_', os.getcwd()+"/data/zynbanks")
		]
		self.osc_paths_data=[]

		self.start()
		self.osc_init()
		self.reset()
		
	def reset(self):
		super().reset()
		self.disable_all_parts()

	# ---------------------------------------------------------------------------
	# Layer Management
	# ---------------------------------------------------------------------------

	def add_layer(self, layer):
		super().add_layer(layer)
		layer.part_i=self.get_free_parts()[0]
		logging.debug("ADD LAYER => PART %s" % layer.part_i)

	def del_layer(self, layer):
		super().del_layer(layer)
		self.disable_part(layer.part_i)
		layer.part_i=None

	# ---------------------------------------------------------------------------
	# MIDI Channel Management
	# ---------------------------------------------------------------------------

	def set_midi_chan(self, layer):
		if layer.part_i is not None:
			liblo.send(self.osc_target, "/part%d/Prcvchn" % layer.part_i, layer.get_midi_chan())

	#----------------------------------------------------------------------------
	# Bank Managament
	#----------------------------------------------------------------------------

	def get_bank_list(self, layer=None):
		return self.get_dirlist(self.bank_dirs)

	#----------------------------------------------------------------------------
	# Preset Managament
	#----------------------------------------------------------------------------

	def get_preset_list(self, bank):
		preset_list=[]
		preset_dir=bank[0]
		index=0
		logging.info("Getting Preset List for %s" % bank[2])
		for f in sorted(os.listdir(preset_dir)):
			preset_fpath=join(preset_dir,f)
			ext=f[-3:].lower()
			if (isfile(preset_fpath) and (ext=='xiz' or ext=='xmz' or ext=='xsz' or ext=='xlz')):
				try:
					index=int(f[0:4])-1
					title=str.replace(f[5:-4], '_', ' ')
				except:
					index+=1
					title=str.replace(f[0:-4], '_', ' ')
				bank_lsb=int(index/128)
				bank_msb=bank[1]
				prg=index%128
				preset_list.append((preset_fpath,[bank_msb,bank_lsb,prg],title,ext))
		return preset_list

	def set_preset(self, layer, preset, preload=False):
		self.start_loading()
		if preset[3]=='xiz':
			self.enable_part(layer)
			liblo.send(self.osc_target, "/load-part",layer.part_i,preset[0])
			#logging.debug("OSC => /load-part %s, %s" % (layer.part_i,preset[0]))
		elif preset[3]=='xmz':
			self.enable_part(layer)
			liblo.send(self.osc_target, "/load_xmz",preset[0])
			logging.debug("OSC => /load_xmz %s" % preset[0])
		elif preset[3]=='xsz':
			liblo.send(self.osc_target, "/load_xsz",preset[0])
			logging.debug("OSC => /load_xsz %s" % preset[0])
		elif preset[3]=='xlz':
			liblo.send(self.osc_target, "/load_xlz",preset[0])
			logging.debug("OSC => /load_xlz %s" % preset[0])
		liblo.send(self.osc_target, "/volume")
		i=0
		while self.loading and i<100: 
			sleep(0.1)
			i=i+1

	def cmp_presets(self, preset1, preset2):
		if preset1[0]==preset2[0]:
			return True
		else:
			return False

	# ---------------------------------------------------------------------------
	# Specific functions
	# ---------------------------------------------------------------------------

	def get_free_parts(self):
		free_parts=list(range(0,16))
		for layer in self.layers:
			try:
				free_parts.remove(layer.part_i)
			except:
				pass
		logging.debug("FREE PARTS => %s" % free_parts)
		return free_parts

	def enable_part(self, layer):
		if layer.part_i is not None:
			liblo.send(self.osc_target, "/part%d/Penabled" % layer.part_i, True)
			liblo.send(self.osc_target, "/part%d/Prcvchn" % layer.part_i, layer.get_midi_chan())

	def disable_part(self, i):
		liblo.send(self.osc_target, "/part%d/Penabled" % i, False)

	def enable_layer_parts(self):
		for layer in self.layers:
			self.enable_part(layer)
		for i in self.get_free_parts():
			self.disable_part(i)

	def disable_all_parts(self):
		for i in range(0,16):
			self.disable_part(i)

	#----------------------------------------------------------------------------
	# OSC Managament
	#----------------------------------------------------------------------------

	def osc_add_methods(self):
			self.osc_server.add_method("/volume", 'i', self.cb_osc_load_preset)
			#self.osc_server.add_method("/paths", None, self.cb_osc_paths)
			self.osc_server.add_method(None, 'i', self.zyngui.cb_osc_ctrl)
			#super().osc_add_methods()
			#liblo.send(self.osc_target, "/echo")

	def cb_osc_load_preset(self, path, args):
		self.stop_loading()

	# ---------------------------------------------------------------------------
	# Deprecated functions
	# ---------------------------------------------------------------------------

	def cb_osc_paths(self, path, args, types, src):
		self.get_cb_osc_paths(path, args, types, src)
		self.zyngui.screens['control'].list_data=self.osc_paths_data
		self.zyngui.screens['control'].fill_list()

	def get_cb_osc_paths(self, path, args, types, src):
		for a, t in zip(args, types):
			if not a or t=='b':
				continue
			print("=> %s (%s)" % (a,t))
			a=str(a)
			postfix=prefix=firstchar=lastchar=''
			if a[-1:]=='/':
				tnode='dir'
				postfix=lastchar='/'
				a=a[:-1]
			elif a[-1:]==':':
				tnode='cmd'
				postfix=':'
				a=a[:-1]
				continue
			elif a[0]=='P':
				tnode='par'
				firstchar='P'
				a=a[1:]
			else:
				continue
			parts=a.split('::')
			if len(parts)>1:
				a=parts[0]
				pargs=parts[1]
				if tnode=='par':
					if pargs=='i':
						tnode='ctrl'
						postfix=':i'
					elif pargs=='T:F':
						tnode='bool'
						postfix=':b'
					else:
						continue
			parts=a.split('#',1)
			if len(parts)>1:
				n=int(parts[1])
				if n>0:
					for i in range(0,n):
						title=prefix+parts[0]+str(i)+postfix
						path=firstchar+parts[0]+str(i)+lastchar
						self.osc_paths.append((path,tnode,title))
			else:
				title=prefix+a+postfix
				path=firstchar+a+lastchar
				self.osc_paths_data.append((path,tnode,title))

#******************************************************************************
