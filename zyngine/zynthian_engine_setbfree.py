# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian Engine (zynthian_engine_setbfree)
# 
# zynthian_engine implementation for setBfree Hammond Emulator
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

import re
import logging
import pexpect

from . import zynthian_engine

#------------------------------------------------------------------------------
# setBfree Engine Class
#------------------------------------------------------------------------------

class zynthian_engine_setbfree(zynthian_engine):


	# ---------------------------------------------------------------------------
	# Banks
	# ---------------------------------------------------------------------------


	bank_manuals_list = [
		['Upper', 0, 'Upper', '_', [False, False, None]],
		['Lower + Upper', 1, 'Lower + Upper', '_', [True, False, None]],
		['Pedals + Upper', 2, 'Pedals + Upper', '_', [False, True, None]],
		['Pedals + Lower + Upper', 3, 'Pedals + Lower + Upper', '_', [True, True, None]],
		['Split: Lower + Upper', 4, 'Split Lower + Upper', '_', [True, False, 57]],
		['Split: Pedals + Upper', 5, 'Split Pedals + Upper', '_', [False, True, 59]],
		['Split: Pedals + Lower + Upper', 6, 'Split Pedals + Lower + Upper', '_', [True, True, 58]]
	]


	bank_twmodels_list = [
		['Sin', 0, 'Sine', '_'],
		['Sqr', 1, 'Square', '_'],
		['Tri', 2, 'Triangle', '_']
	]


	tonewheel_config = { 
		"Sin": "",

		"Sqr": """
			osc.harmonic.1=1.0
			osc.harmonic.3=0.333333333333
			osc.harmonic.5=0.2
			osc.harmonic.7=0.142857142857
			osc.harmonic.9=0.111111111111
			osc.harmonic.11=0.090909090909""",

		"Tri": """
			osc.harmonic.1=1.0
			osc.harmonic.3=0.111111111111
			osc.harmonic.5=0.04
			osc.harmonic.7=0.02040816326530612
			osc.harmonic.9=0.012345679012345678
			osc.harmonic.11=0.008264462809917356"""
	}


	# ---------------------------------------------------------------------------
	# Controllers & Screens
	# ---------------------------------------------------------------------------

	drawbar_values=[['0','1','2','3','4','5','6','7','8'], [128,119,103,87,71,55,39,23,7]]

	# MIDI Controllers
	_ctrls=[
		['volume',7,96,127],
#		['swellpedal 2',11,96],
		['reverb',91,4,127,'reverbmix'],
		['convol. mix',94,64,127],

		['rotary toggle',64,'off','off|on'],
#		['rotary speed',1,64,127,'rotaryspeed'],
		['rotary speed',1,'off','slow|off|fast','rotaryspeed'],
#		['rotary speed',1,'off',[['slow','off','fast'],[0,43,86]],'rotaryspeed'],
#		['rotary select',67,0,127],
#		['rotary select',67,'off/off','off/off|slow/off|fast/off|off/slow|slow/slow|fast/slow|off/fast|slow/fast|fast/fast'],
		['rotary select',67,'off/off',[['off/off','slow/off','fast/off','off/slow','slow/slow','fast/slow','off/fast','slow/fast','fast/fast'],[0,15,30,45,60,75,90,105,120]]],

		['DB 16',70,'8',drawbar_values,'drawbar_1'],
		['DB 5 1/3',71,'8',drawbar_values,'drawbar_2'],
		['DB 8',72,'8',drawbar_values,'drawbar_3'],
		['DB 4',73,'0',drawbar_values,'drawbar_4'],
		['DB 2 2/3',74,'0',drawbar_values,'drawbar_5'],
		['DB 2',75,'0',drawbar_values,'drawbar_6'],
		['DB 1 3/5',76,'0',drawbar_values,'drawbar_7'],
		['DB 1 1/3',77,'0',drawbar_values,'drawbar_8'],
		['DB 1',78,'0',drawbar_values,'drawbar_9'],

		['vibrato upper',31,'off','off|on','vibratoupper'],
		['vibrato lower',30,'off','off|on','vibratolower'],
		['vibrato routing',95,'off','off|lower|upper|both','vibratorouting'],
		#['vibrato selector',92,'c3','v1|v2|v3|c1|c2|c3','vibrato'],
		['vibrato selector',92,'c3',[['v1','v2','v3','c1','c2','c3'],[0,23,46,69,92,115]]],

		#['percussion',66,'off','off|on','perc'],
		['percussion',80,'off','off|on','perc'],
		['percussion volume',81,'soft','soft|hard','percvol'],
		['percussion decay',82,'slow','slow|fast','percspeed'],
		['percussion harmonic',83,'3rd','2nd|3rd','percharm'],

		['overdrive',65,'off','off|on','overdrive'],
		['overdrive character',93,64,127,'overdrive_char'],
		['overdrive inputgain',21,64,127,'overdrive_igain'],
		['overdrive outputgain',22,64,127,'overdrive_ogain']
	]

	# Controller Screens
	_ctrl_screens=[
		['main',['volume','percussion','rotary speed','vibrato routing']],
		['drawbars low',['volume','DB 16','DB 5 1/3','DB 8']],
		['drawbars medium',['volume','DB 4','DB 2 2/3','DB 2']],
		['drawbars high',['volume','DB 1 3/5','DB 1 1/3','DB 1']],
		['rotary',['rotary toggle','rotary select','rotary speed','convol. mix']],
		['vibrato',['vibrato upper','vibrato lower','vibrato routing','vibrato selector']],
		['percussion',['percussion','percussion decay','percussion harmonic','percussion volume']],
		['overdrive',['overdrive','overdrive character','overdrive inputgain','overdrive outputgain']],
		['reverb',['volume','convol. mix','reverb']],
	]

	#----------------------------------------------------------------------------
	# Initialization
	#----------------------------------------------------------------------------


	def __init__(self, zyngui=None):
		super().__init__(zyngui)
		self.name = "setBfree"
		self.nickname = "BF"
		self.jackname = "setBfree"

		self.options['midi_chan']=False

		self.base_dir = self.data_dir + "/setbfree"

		self.manuals_config = None
		self.tonewheel_model = None

		#Process command ...
		preset_fpath = self.base_dir + "/pgm/all.pgm"
		config_fpath = self.base_dir + "/cfg/zynthian.cfg"
		if self.config_remote_display():
			self.command = "/usr/local/bin/setBfree -p \"{}\" -c \"{}\"".format(preset_fpath, config_fpath)
		else:
			self.command = "/usr/local/bin/setBfree -p \"{}\" -c \"{}\"".format(preset_fpath, config_fpath)

		self.command_prompt = "\nAll systems go."

		self.reset()


	def generate_config_file(self):
		# Get user's config
		my_cfg_fpath= self.my_data_dir + "/setbfree/cfg/zynthian.cfg"
		try:
			with open(my_cfg_fpath, 'r') as my_cfg_file:
				my_cfg_data=my_cfg_file.read()
		except:
			my_cfg_data=""

		# Generate on-the-fly config
		cfg_tpl_fpath = self.base_dir + "/cfg/zynthian.cfg.tpl"
		cfg_fpath = self.base_dir + "/cfg/zynthian.cfg"
		with open(cfg_tpl_fpath, 'r') as cfg_tpl_file:
			cfg_data = cfg_tpl_file.read()
			cfg_data = cfg_data.replace('#OSC.TUNING#', str(self.zyngui.fine_tuning_freq))
			cfg_data = cfg_data.replace('#MIDI.UPPER.CHANNEL#', str(1 + self.layers[0].midi_chan))
			cfg_data = cfg_data.replace('#MIDI.LOWER.CHANNEL#', str(1 + (self.layers[0].midi_chan + 1) % 16))
			cfg_data = cfg_data.replace('#MIDI.PEDALS.CHANNEL#', str(1 + (self.layers[0].midi_chan + 2) % 16))
			cfg_data = cfg_data.replace('#TONEWHEEL.CONFIG#', self.tonewheel_config[self.tonewheel_model])
			cfg_data += "\n" + my_cfg_data
			with open(cfg_fpath, 'w') as cfg_file:
				cfg_file.write(cfg_data)


	# ---------------------------------------------------------------------------
	# Layer Management
	# ---------------------------------------------------------------------------


	def add_layer(self, layer):
		super().add_layer(layer)
		layer.listen_midi_cc=True


	def del_layer(self, layer):
		super().del_layer(layer)
		layer.listen_midi_cc=False


	# ---------------------------------------------------------------------------
	# MIDI Channel Management
	# ---------------------------------------------------------------------------


	def set_midi_chan(self, layer):
		pass


	#----------------------------------------------------------------------------
	# Bank Managament
	#----------------------------------------------------------------------------


	def get_bank_list(self, layer):
		if not self.manuals_config:
			return self.bank_manuals_list
		elif not self.tonewheel_model:
			return self.bank_twmodels_list
		else:
			if layer.bank_name == "Upper":
				return [[self.base_dir + "/pgm-banks/upper/most_popular.pgm",0, "Upper", "_"]]
			elif layer.bank_name == "Lower":
				return [[self.base_dir + "/pgm-banks/lower/lower_voices.pgm",0, "Lower", "_"]]
			elif layer.bank_name == "Pedals":
				return [[self.base_dir + "/pgm-banks/pedals/pedals.pgm",0, "Pedals", "_"]]

		#return self.get_filelist(self.get_bank_dir(layer),"pgm")


	def set_bank(self, layer, bank):
		if not self.manuals_config:
			self.manuals_config = bank
			self.layers[0].load_bank_list()
			self.layers[0].reset_bank()
			return False

		elif not self.tonewheel_model:
			self.tonewheel_model = bank[0]

		if not self.proc:
			logging.debug("STARTING SETBFREE!!")
			self.generate_config_file()
			self.stop()
			self.start()
			self.zyngui.zynautoconnect()

			midi_chan = layer.get_midi_chan()
			midi_prog = self.manuals_config[4][2]

			if midi_prog and isinstance(midi_prog, int):
				logging.debug("Loading manuals configuration program: {}".format(midi_prog-1))
				self.zyngui.zynmidi.set_midi_prg(midi_chan, midi_prog-1)

			self.layers[0].bank_name = "Upper"
			self.layers[0].load_bank_list()
			self.layers[0].set_bank(0)

			if self.manuals_config[4][0]:
				self.zyngui.screens['layer'].add_layer_midich((midi_chan + 1) % 16, False)
				self.layers[1].bank_name = "Lower"
				self.layers[1].load_bank_list()
				self.layers[1].set_bank(0)

			if self.manuals_config[4][1]:
				self.zyngui.screens['layer'].add_layer_midich((midi_chan + 2) % 16, False)
				i=len(self.layers)-1
				self.layers[i].bank_name = "Pedals"
				self.layers[i].load_bank_list()
				self.layers[i].set_bank(0)

			#self.zyngui.screens['layer'].fill_list()

			return True


	#----------------------------------------------------------------------------
	# Preset Managament
	#----------------------------------------------------------------------------


	def get_preset_list(self, bank):
		logging.debug("Preset List for Bank {}".format(bank[0]))
		return self.load_pgm_list(bank[0])


	def set_preset(self, layer, preset, preload=False):
		if super().set_preset(layer,preset):
			self.update_controller_values(preset)
			return True
		else:
			return False


	#----------------------------------------------------------------------------
	# Controller Managament
	#----------------------------------------------------------------------------

	def update_controller_values(self, preset):
		#Get values from preset params and set them into controllers
		for zcsymbol, v in preset[3].items():
			try:
				zctrl=zctrls[zcsymbol]

				if zctrl.symbol=='rotaryspeed':
					if v=='tremolo': v='fast'
					elif v=='chorale': v='slow'
					else: v='off'

				zctrl.set_value(v)
				#logging.debug("%s => %s (%s)" % (zctrl.name,zctrl.symbol,zctrl.value))

				#Refresh GUI controller in screen when needed ...
				if self.zyngui.active_screen=='control' and self.zyngui.screens['control'].mode=='control':
					self.zyngui.screens['control'].set_controller_value(zctrl)

			except:
				#logging.debug("No preset value for control %s" % zctrl.name)
				pass


	def midi_control_change(self, zctrl, val):
		try:
			if val!=zctrl.get_value():
				zctrl.set_value(val)
				#logging.debug("MIDI CC {} -> '{}' = {}".format(zctrl.midi_cc, zctrl.name, val))

				#Refresh GUI controller in screen when needed ...
				if self.zyngui.active_screen=='control' and self.zyngui.screens['control'].mode=='control':
					self.zyngui.screens['control'].set_controller_value(zctrl)

		except Exception as e:
			logging.debug(e)


	#----------------------------------------------------------------------------
	# Specific functionality
	#----------------------------------------------------------------------------


	def get_chan_name(self, chan):
		try:
			return self.chan_names[chan]
		except:
			return None


	def get_bank_dir(self, layer):
		bank_dir=self.base_dir+"/pgm-banks"
		chan_name=self.get_chan_name(layer.get_midi_chan())
		if chan_name:
			bank_dir=bank_dir+'/'+chan_name
		return bank_dir


	def load_pgm_list(self,fpath):
		self.start_loading()
		pgm_list=None
		try:
			with open(fpath) as f:
				pgm_list=[]
				lines = f.readlines()
				ptrn1=re.compile("^([\d]+)[\s]*\{[\s]*name\=\"([^\"]+)\"")
				ptrn2=re.compile("[\s]*[\{\}\,]+[\s]*")
				i=0
				for line in lines:
					#Test with first pattern
					m=ptrn1.match(line)
					if not m: continue
					#Get line parts...
					fragments=ptrn2.split(line)
					params={}
					try:
						#Get program MIDI number
						prg=int(fragments[0])-1
						if prg>=0:
							#Get params from line parts ...
							for frg in fragments[1:]:
								parts=frg.split('=')
								try:
									params[parts[0].lower()]=parts[1].strip("\"\'")
								except:
									pass
							#Extract program name
							title=params['name']
							del params['name']
							#Complete program params ...
							#if 'vibrato' in params:
							#	params['vibratoupper']='on'
							#	params['vibratorouting']='upper'
							if 'drawbars' in params:
								j=1
								for v in params['drawbars']:
									if v in ['0','1','2','3','4','5','6','7','8']:
										params['drawbar_'+str(j)]=v
										j=j+1
							#Add program to list
							pgm_list.append((i,[0,0,prg],title,params))
							i=i+1
					except:
						#print("Ignored line: %s" % line)
						pass
		except Exception as err:
			pgm_list=None
			logging.error("Getting program info from %s => %s" % (fpath,err))
		self.stop_loading()
		return pgm_list


	def cmp_presets(self, preset1, preset2):
		try:
			if preset1[1][2]==preset2[1][2]:
				return True
			else:
				return False
		except:
			return False


	# ---------------------------------------------------------------------------
	# Extended Config
	# ---------------------------------------------------------------------------


	def get_extended_config(self):
		xconfig = { 
			'manuals_config': self.manuals_config,
			'tonewheel_model': self.tonewheel_model
		}
		return xconfig


	def set_extended_config(self, xconfig):
		try:
			self.manuals_config = xconfig['manuals_config']
			self.tonewheel_model = xconfig['tonewheel_model']

		except Exception as e:
			logging.error("Can't setup extended config => {}".format(e))


	# ---------------------------------------------------------------------------
	# Layer "Path" String
	# ---------------------------------------------------------------------------

	def get_path(self, layer):
		path = self.nickname
		if not self.manuals_config:
			path += "/Manuals"
		elif not self.tonewheel_model:
			path += "/Tonewheel"
		else:
			path += "/" + self.tonewheel_model
		return path

#******************************************************************************
