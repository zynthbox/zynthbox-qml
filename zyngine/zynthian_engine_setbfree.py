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

from . import zynthian_engine

#------------------------------------------------------------------------------
# setBfree Engine Class
#------------------------------------------------------------------------------

class zynthian_engine_setbfree(zynthian_engine):

	# ---------------------------------------------------------------------------
	# Controllers & Screens
	# ---------------------------------------------------------------------------

	drawbar_values=[['0','1','2','3','4','5','6','7','8'], [128,119,103,87,71,55,39,23,7]]

	# MIDI Controllers
	_ctrls=[
		['volume',7,96],
#		['swellpedal 2',11,96],
#		['rotary speed',91,64,127,'rotaryspeed'],
		['rotary speed',91,'off','slow|off|fast','rotaryspeed'],
#		['rotary speed',91,'off',[['slow','off','fast'],[0,43,86]],'rotaryspeed'],
#		['rotary select',65,0,127],
#		['rotary select',65,'off/off','off/off|slow/off|fast/off|off/slow|slow/slow|fast/slow|off/fast|slow/fast|fast/fast'],
		['rotary select',65,'off/off',[['off/off','slow/off','fast/off','off/slow','slow/slow','fast/slow','off/fast','slow/fast','fast/fast'],[0,15,30,45,60,75,90,105,120]]],
#		['rotary toggle',64,0],
#		['16',70,0,127,'drawbar_1'],
		['16',70,'8',drawbar_values,'drawbar_1'],
		['5 1/3',71,'8',drawbar_values,'drawbar_2'],
		['8',72,'8',drawbar_values,'drawbar_3'],
		['4',73,'0',drawbar_values,'drawbar_4'],
		['2 2/3',74,'0',drawbar_values,'drawbar_5'],
		['2',75,'0',drawbar_values,'drawbar_6'],
		['1 3/5',76,'0',drawbar_values,'drawbar_7'],
		['1 1/3',77,'0',drawbar_values,'drawbar_8'],
		#['1',78,'8',drawbar_values,'drawbar_9'],
		['drawbar 1',78,'0',drawbar_values,'drawbar_9'],
		['reverb mix',99,4],
		['vibrato on/off',92,'off','off|on','vibratoupper'],
		['vibrato selector',83,'c3','v1|v2|v3|c1|c2|c3','vibrato'],
		['percussion on/off',80,'off','off|on','perc'],
		#['percussion.volume',xx,90,127,'percvol'],
		['percussion decay',81,'slow','slow|fast','percspeed'],
		['percussion harmonic',82,'3rd','2nd|3rd','percharm'],
		['overdrive on/off',23,'off','off|on','overdrive'],
		['overdrive character',93,64,127,'overdrive_char'],
		['overdrive inputgain',21,64,127,'overdrive_igain'],
		['overdrive outputgain',22,64,127,'overdrive_ogain']
	]

	# Controller Screens
	_ctrl_screens=[
		['main',['volume','percussion on/off','rotary speed','rotary select']],
#		['main',['volume','rotary toggle','rotary speed','rotary select']],
		['drawbars low',['16','5 1/3','8','4']],
		['drawbars hi',['2 2/3','2','1 3/5','1 1/3']],
		['reverb & vibrato',['drawbar 1','reverb mix','vibrato on/off','vibrato selector']],
		['percussion',['volume','percussion on/off','percussion decay','percussion harmonic']],
		['overdrive',['overdrive on/off','overdrive character','overdrive inputgain','overdrive outputgain']]
	]

	#----------------------------------------------------------------------------
	# Initialization
	#----------------------------------------------------------------------------

	def __init__(self, zyngui=None):
		super().__init__(zyngui)
		self.name="setBfree"
		self.nickname="BF"
		
		self.base_dir="./data/setbfree"
		self.chan_names=("upper","lower","pedals")
		
		self.generate_config_file()

		if self.config_remote_display():
			self.command=("/usr/local/bin/setBfree", "-p", self.base_dir+"/pgm/all.pgm", "-c", self.base_dir+"/cfg/zynthian.cfg")
		else:
			self.command=("/usr/local/bin/setBfree", "-p", self.base_dir+"/pgm/all.pgm", "-c", self.base_dir+"/cfg/zynthian.cfg")

		self.start()
		self.reset()

	def generate_config_file(self):
		cfg_tpl_fpath=self.base_dir+"/cfg/zynthian.cfg.tpl"
		cfg_fpath=self.base_dir+"/cfg/zynthian.cfg"
		with open(cfg_tpl_fpath, 'r') as cfg_tpl_file:
			cfg_data=cfg_tpl_file.read()
			cfg_data=cfg_data.replace('#OSC.TUNING#', str(self.zyngui.fine_tuning_freq))
			with open(cfg_fpath, 'w') as cfg_file:
				cfg_file.write(cfg_data)

	#----------------------------------------------------------------------------
	# Bank Managament
	#----------------------------------------------------------------------------

	def get_bank_list(self, layer=None):
		return self.get_filelist(self.get_bank_dir(layer),"pgm")

	#----------------------------------------------------------------------------
	# Preset Managament
	#----------------------------------------------------------------------------

	def get_preset_list(self, bank):
		return self.load_pgm_list(bank[0])

	def set_preset(self, layer, preset, preload=False):
		super().set_preset(layer,preset)
		#Set layer's refresh flag
		if not preload:
			layer.refresh_flag=True

	#----------------------------------------------------------------------------
	# Controller Managament
	#----------------------------------------------------------------------------

	def get_controllers_dict(self, layer):
		zctrls=super().get_controllers_dict(layer)
		#Preset param's values into controllers
		for zcname in zctrls:
			try:
				zctrl=zctrls[zcname]
				zctrl.value=layer.preset_info[3][zctrl.symbol]
				#logging.debug("%s => %s (%s)" % (zctrl.name,zctrl.symbol,zctrl.value))
				if zctrl.symbol=='rotaryspeed':
					if zctrl.value=='tremolo': zctrl.value='fast'
					elif zctrl.value=='chorale': zctrl.value='slow'
					else: zctrl.value='off'
			except:
				#logging.debug("No preset value for control %s" % zctrl.name)
				pass
		return zctrls

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
							if 'vibrato' in params: params['vibratoupper']='on'
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
		if preset1[1][2]==preset2[1][2]:
			return True
		else:
			return False

	# ---------------------------------------------------------------------------
	# Layer "Path" String
	# ---------------------------------------------------------------------------

	def get_path(self, layer):
		path=self.nickname
		chan_name=self.get_chan_name(layer.get_midi_chan())
		if chan_name:
			path=path+'/'+chan_name
		return path

#******************************************************************************
