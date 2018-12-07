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
import re
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
		#['volume','/part$i/Pvolume',96],
		['volume',7,115],
		['panning',10,64],
		#['expression',11,127],
		['filter cutoff',74,64],
		['filter resonance',71,64],
		['panning depth','/part$i/ctl/panning.depth',64],
		['filter.cutoff depth','/part$i/ctl/filtercutoff.depth',64],
		['filter.Q depth','/part$i/ctl/filterq.depth',64],
		['drum on/off','/part$i/Pdrummode','off','off|on'],
		['legato on/off','/part$i/Plegatomode','off','off|on'],
		['poly on/off','/part$i/Ppolymode','on','off|on'],
		['sustain on/off',64,'off','off|on'],
		['portamento on/off',65,'off','off|on'],
		#['portamento receive','/part$i/ctl/portamento.receive','off','off|on'],
		['portamento time','/part$i/ctl/portamento.time',64],
		['portamento up/down','/part$i/ctl/portamento.updowntimestretch',64],
		['portamento thresh','/part$i/ctl/portamento.pitchthresh',3],
		['modulation',1,0],
		['modulation amplitude',76,127],
		['modulation depth','/part$i/ctl/modwheel.depth',64],
		['modulation exp','/part$i/ctl/modwheel.exponential','off','off|on'],
		['bandwidth',75,64],
		['bandwidth depth','/part$i/ctl/bandwidth.depth',64],
		['bandwidth exp','/part$i/ctl/modwheel.exponential','off','off|on'],
		['resonance center',77,64],
		['resonance bandwidth',78,64],
		['res.center depth','/part$i/ctl/resonancecenter.depth',64],
		['res.bw depth','/part$i/ctl/resonancebandwidth.depth',64],
		['velocity sens.','/part$i/Pvelsns',64],
		['velocity offs.','/part$i/Pveloffs',64]
	]

	# Controller Screens
	_ctrl_screens=[
		['main',['volume','panning','filter cutoff','filter resonance']],
		['mode',['drum on/off','sustain on/off','legato on/off','poly on/off']],
		['portamento',['portamento on/off','portamento time','portamento up/down','portamento thresh']],
		['modulation',['modulation','modulation amplitude','modulation depth','modulation exp']],
		['resonance',['resonance center','res.center depth','resonance bandwidth','res.bw depth']],
		['bandwidth',['volume','bandwidth','bandwidth depth','bandwidth exp']],
		['velocity',['volume','panning','velocity sens.','velocity offs.']],
		['depth',['volume','panning depth','filter.cutoff depth','filter.Q depth']]
	]


	#----------------------------------------------------------------------------
	# Initialization
	#----------------------------------------------------------------------------


	def __init__(self, zyngui=None):
		super().__init__(zyngui)
		self.name = "ZynAddSubFX"
		self.nickname = "ZY"
		self.jackname = "zynaddsubfx"

		self.osc_target_port = 6693
	
		if self.config_remote_display():
			self.command = "/usr/local/bin/zynaddsubfx -O jack-multi -I jack -P {} -a".format(self.osc_target_port)
		else:
			self.command = "/usr/local/bin/zynaddsubfx -O jack-multi -I jack -P {} -a -U".format(self.osc_target_port)

		self.command_prompt = "\n\\[INFO] Main Loop..."

		self.conf_dir = self.data_dir + "/zynconf"
		self.bank_dirs = [
			('MY', self.my_data_dir + "/zynbanks"),
			('_', self.data_dir + "/zynbanks")
		]
		self.osc_paths_data = []

		self.current_slot_zctrl = None
		self.slot_zctrls = {}

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
		self.layers.append(layer)
		layer.part_i = self.get_free_parts()[0]
		layer.jackname = "{}:part{}".format(self.jackname, layer.part_i)
		logging.debug("ADD LAYER => Part {} ({})".format(layer.part_i, self.jackname))


	def del_layer(self, layer):
		super().del_layer(layer)
		self.disable_part(layer.part_i)
		layer.part_i = None
		layer.jackname = None


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
		layer.send_ctrl_midi_cc()
		return True


	def cmp_presets(self, preset1, preset2):
		try:
			if preset1[0]==preset2[0]:
				return True
			else:
				return False
		except:
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
			self.osc_server.add_method("/automate/active-slot", 'i', self.cb_osc_automate_active_slot)
			for i in range(0,16):
				self.osc_server.add_method("/automate/slot%d/midi-cc" % i, 'i', self.cb_osc_automate_slot_midi_cc)
			#self.osc_server.add_method(None, 'i', self.zyngui.cb_osc_ctrl)
			#super().osc_add_methods()


	def cb_osc_load_preset(self, path, args):
		self.stop_loading()


	#----------------------------------------------------------------------------
	# MIDI learning
	#----------------------------------------------------------------------------


	def midi_learn(self, zctrl):
		if zctrl.osc_path:
			# Set current learning-slot zctrl
			logging.info("Learning '%s' ..." % zctrl.osc_path)
			self.current_slot_zctrl = zctrl
			# Start MIDI learning for osc_path in a new slot
			liblo.send(self.osc_target, "/automate/learn-binding-new-slot", zctrl.osc_path)
			# Get slot number
			liblo.send(self.osc_target, "/automate/active-slot")
			# Setup CB method for param change
			self.osc_server.add_method(zctrl.osc_path, 'i', self.cb_osc_param_change)


	def midi_unlearn(self, zctrl):
		if zctrl.osc_path in self.slot_zctrls:
			logging.info("Unlearning '%s' ..." % zctrl.osc_path)
			try:
				del self.slot_zctrls[zctrl.osc_path]
				liblo.send(self.osc_target, "/automate/slot%d/clear" % zctrl.slot_i)
				self.osc_server.del_method(zctrl.osc_path, 'i')
				logging.info("Automate Slot %d Cleared => %s" % (zctrl.slot_i, zctrl.osc_path))
				zctrl.slot_i = None
				return True
			except Exception as e:
				logging.warning("Can't Clear Automate Slot %s => %s" % (zctrl.osc_path,e))


	def set_midi_learn(self, zctrl):
		try:
			if zctrl.osc_path and zctrl.slot_i is not None and zctrl.midi_learn_chan is not None and zctrl.midi_learn_cc is not None:
				logging.info("Set Automate Slot %d: %s => %d, %d" % (zctrl.slot_i, zctrl.osc_path, zctrl.midi_learn_chan, zctrl.midi_learn_cc))
				# Reset current MIDI-learning slot
				self.current_slot_zctrl=None
				# Call midi_learn
				self.midi_learn(zctrl)
				# Wait for setting automation
				while self.current_slot_zctrl:
					sleep(0.01)
		except Exception as e:
			logging.error("Can't set slot automation for %s => %s" % (zctrl.osc_path, e))


	def reset_midi_learn(self):
		logging.info("Reset MIDI-learn ...")
		liblo.send(self.osc_target, "/automate/clear", "*")
		self.current_slot_zctrl=None
		self.slot_zctrls={}


	def cb_osc_automate_active_slot(self, path, args, types, src):
		if self.current_slot_zctrl:
			slot_i=args[0]
			logging.debug("Automate active-slot: %s" % slot_i)
			# Add extra info to zctrl
			self.current_slot_zctrl.slot_i = int(slot_i)
			# Add zctrl to slots dictionary
			self.slot_zctrls[self.current_slot_zctrl.osc_path] = self.current_slot_zctrl
			# set_midi_learn
			if self.current_slot_zctrl.midi_learn_cc is not None:
				zcc = (self.current_slot_zctrl.midi_learn_chan * 128) + self.current_slot_zctrl.midi_learn_cc
				liblo.send(self.osc_target, "/automate/slot%d/learning" % slot_i, 0)
				liblo.send(self.osc_target, "/automate/slot%d/active" % slot_i, True)
				#sleep(0.05)
				liblo.send(self.osc_target, "/automate/slot%d/name" % slot_i, self.current_slot_zctrl.symbol)
				#logging.debug("OSC send => /automate/slot%d/name '%s'" % (slot_i, self.current_slot_zctrl.symbol))
				liblo.send(self.osc_target, "/automate/slot%d/midi-cc" % slot_i, zcc)
				#logging.debug("OSC send => /automate/slot%d/midi-cc %d" % (slot_i, zcc))
				liblo.send(self.osc_target, "/automate/slot%d/param0/active" % slot_i, True)
				liblo.send(self.osc_target, "/automate/slot%d/param0/used" % slot_i, True)
				liblo.send(self.osc_target, "/automate/slot%d/param0/path" % slot_i, self.current_slot_zctrl.osc_path)
				logging.debug("Automate Slot %d SET: %s => %d" % (slot_i, self.current_slot_zctrl.osc_path, zcc))
				self.current_slot_zctrl=None
			# midi_learn
			else:
				# Send twice for get it working when re-learning ...
				liblo.send(self.osc_target, "/automate/slot%d/clear" % slot_i)
				liblo.send(self.osc_target, "/automate/learn-binding-new-slot", self.current_slot_zctrl.osc_path)


	def cb_osc_param_change(self, path, args):
		if path in self.slot_zctrls:
			#logging.debug("OSC Param Change %s => %s" % (path, args[0]))
			zctrl=self.slot_zctrls[path]
			try:
				self.zyngui.screens['control'].get_zgui_controller(zctrl).set_value(args[0],True,False)
			except:
				pass
			if zctrl.midi_learn_cc is None:
				liblo.send(self.osc_target, "/automate/slot%d/midi-cc" % zctrl.slot_i)


	def cb_osc_automate_slot_midi_cc(self, path, args, types, src):
		# Test if there is a current MIDI-learning zctrl and a valid MIDI-CC number is returned
		if self.current_slot_zctrl and args[0]>=0:
			try:
				# Parse slot from path and set zctrl midi_cc
				m=re.match("\/automate\/slot(\d+)\/midi-cc",path)
				slot_i=int(m.group(1))
				chan= int(int(args[0]) / 128)
				cc = int(args[0]) % 128
				logging.debug("Automate Slot %d MIDI-CC: %s => %s" % (slot_i, path, args[0]))
				if self.current_slot_zctrl.slot_i==slot_i:
					self.current_slot_zctrl.cb_midi_learn(chan,cc)
					self.current_slot_zctrl=None
			except Exception as e:
				logging.error("Can't match zctrl slot for the returned MIDI-CC! => %s" % e)


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
