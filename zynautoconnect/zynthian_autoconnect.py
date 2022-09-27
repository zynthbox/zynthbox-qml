# -*- coding: utf-8 -*-
#********************************************************************
# ZYNTHIAN PROJECT: Zynthian Autoconnector
# 
# Autoconnect Jack clients
# 
# Copyright (C) 2015-2016 Fernando Moyano <jofemodo@zynthian.org>
#
#********************************************************************
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
#********************************************************************

import sys
import os
import jack
import copy
import logging
from time import sleep
from threading  import Thread, Lock
from collections import OrderedDict

# Zynthian specific modules
from PySide2.QtCore import QTimer

from zyncoder import *
from zynqtgui import zynthian_gui_config

#-------------------------------------------------------------------------------
# Configure logging
#-------------------------------------------------------------------------------

log_level = logging.WARNING

logger=logging.getLogger(__name__)
logger.setLevel(log_level)

#if log_level==logging.DEBUG:
#	import inspect

#-------------------------------------------------------------------------------
# Define some Constants and Global Variables
#-------------------------------------------------------------------------------

refresh_time = 2
jclient: jack.Client = None
thread = None
exit_flag = False
force_next_autoconnect = False
xrun_count = 0

last_hw_str = None


def xrun_counter_timer_timeout():
	global xrun_count

	if xrun_count > 0:
		logging.warning(f"Got {xrun_count} XRUNS in last 10 seconds")
		xrun_count = 0


xrun_counter_timer = QTimer()
xrun_counter_timer.setInterval(10000)
xrun_counter_timer.setSingleShot(False)
xrun_counter_timer.timeout.connect(xrun_counter_timer_timeout)

#------------------------------------------------------------------------------

def get_port_alias_id(midi_port):
	try:
		alias_id='_'.join(midi_port.aliases[0].split('-')[5:])
	except:
		alias_id=midi_port.name
	return alias_id


#Dirty hack for having MIDI working with PureData & CSound: #TODO => Improve it!!
def get_fixed_midi_port_name(port_name):
	if port_name=="pure_data":
		port_name = "Pure Data"

	elif port_name=="csound6":
		port_name = "Csound"

	return port_name

#------------------------------------------------------------------------------

def midi_autoconnect(force=False):
	global last_hw_str

	#Get Mutex Lock
	acquire_lock()

	logger.info("ZynAutoConnect: MIDI ...")

	#------------------------------------
	# Get Input/Output MIDI Ports:
	#  - outputs are inputs for jack
	#  - inputs are outputs for jack
	#------------------------------------

	### NOTE Zynthbox ZLRouter does hardware pre-routing, so disable all hardware device handling in
	### zynthian itself by just setting the list of hardware in/out devices to empty:
	hw_out=[]
	hw_in=[]
	#Get Physical MIDI input ports ...
	#try:
		#hw_out=jclient.get_ports(is_output=True, is_physical=True, is_midi=True)
	#except:
		#logging.error("Failed to get ports via jack")
	#if len(hw_out)==0:
		#hw_out=[]

	#Get Physical MIDI output ports ...
	#hw_in=jclient.get_ports(is_input=True, is_physical=True, is_midi=True)
	#if len(hw_in)==0:
		#hw_in=[]


	#Add Aubio MIDI out port ...
	if zynthian_gui_config.midi_aubionotes_enabled:
		aubio_out=jclient.get_ports("aubio", is_output=True, is_physical=False, is_midi=True)
		try:
			hw_out.append(aubio_out[0])
		except:
			pass

	#Add TouchOSC out ports ...
	if zynthian_gui_config.midi_touchosc_enabled:
		rtmidi_out=jclient.get_ports("RtMidiOut Client", is_output=True, is_physical=False, is_midi=True)
		for port in rtmidi_out:
			try:
				hw_out.append(port)
			except:
				pass

	#logger.debug("Input Device Ports: {}".format(hw_out))
	#logger.debug("Output Device Ports: {}".format(hw_in))

	#Calculate device list fingerprint (HW & virtual)
	hw_str=""
	for hw in hw_out:
		hw_str += hw.name + "\n"
	for hw in hw_in:
		hw_str += hw.name + "\n"

	#Check for new devices (HW and virtual)...
	if not force and hw_str==last_hw_str:
		last_hw_str = hw_str
		#Release Mutex Lock
		release_lock()
		logger.info("ZynAutoConnect: MIDI Shortened ...")
		return
	else:
		last_hw_str = hw_str

	#Get Engines list from UI
	zyngine_list=zynthian_gui_config.zyngui.screens["engine"].zyngines

	#Get Engines MIDI input, output & feedback ports:
	engines_in={}
	engines_out=[]
	engines_fb=[]
	try:
		for k, zyngine in zyngine_list.items():
			if not zyngine.jackname or zyngine.nickname=="MD":
				continue

			if zyngine.type in ("MIDI Synth", "MIDI Tool", "Special"):
				port_name = get_fixed_midi_port_name(zyngine.jackname)
				#logger.debug("Zyngine Port Name: {}".format(port_name))

				ports = jclient.get_ports(port_name, is_input=True, is_midi=True, is_physical=False)
				try:
					#logger.debug("Engine {}:{} found".format(zyngine.jackname,ports[0].short_name))
					engines_in[zyngine.jackname]=ports[0]
				except:
					#logger.warning("Engine {} is not present".format(zyngine.jackname))
					pass

				ports = jclient.get_ports(port_name, is_output=True, is_midi=True, is_physical=False)
				try:
					#logger.debug("Engine {}:{} found".format(zyngine.jackname,ports[0].short_name))
					if zyngine.type=="MIDI Synth":
						engines_fb.append(ports[0])
					else:
						engines_out.append(ports[0])
				except:
					#logger.warning("Engine {} is not present".format(zyngine.jackname))
					pass
	except Exception as e:
		logging.error(f"Failed to connect an engine up. Postponing the auto connection until the next autoconnect run, at which point it should hopefully be fine. Reported error: {e}")
		# Unlock mutex and return early as autoconnect is being rescheduled to be called after 1000ms because of an exception
		# Logic below the return statement will be eventually evaluated when called again after the timeout
		force_next_autoconnect = True;
		release_lock()
		return

	#logger.debug("Synth Engine Input Ports: {}".format(engines_in))
	#logger.debug("Synth Engine Output Ports: {}".format(engines_out))
	#logger.debug("Synth Engine Feedback Ports: {}".format(engines_fb))

	#Get Zynthian Midi Router MIDI ports
	zmr_out=OrderedDict()
	for p in jclient.get_ports("ZynMidiRouter", is_output=True, is_midi=True):
		zmr_out[p.shortname]=p
	zmr_in=OrderedDict()
	for p in jclient.get_ports("ZynMidiRouter", is_input=True, is_midi=True):
		zmr_in[p.shortname]=p

	#logger.debug("ZynMidiRouter Input Ports: {}".format(zmr_out))
	#logger.debug("ZynMidiRouter Output Ports: {}".format(zmr_in))

	#------------------------------------
	# Auto-Connect MIDI Ports
	#------------------------------------

	#Connect "Not Disabled" Input Device Ports to ZynMidiRouter:main_in
	for hw in hw_out:
		#logger.debug("Connecting MIDI Input {} => {}".format(hw,zmr_in['main_in']))
		try:
			if get_port_alias_id(hw) in zynthian_gui_config.disabled_midi_in_ports:
				jclient.disconnect(hw,zmr_in['main_in'])
			else:
				jclient.connect(hw,zmr_in['main_in'])
		except Exception as e:
			#logger.debug("Exception {}".format(e))
			pass

	#logger.debug("Connecting RTP-MIDI & QMidiNet to ZynMidiRouter:net_in ...")

	#Connect RTP-MIDI output to ZynMidiRouter:net_in
	if zynthian_gui_config.midi_rtpmidi_enabled:
		try:
			jclient.connect("jackrtpmidid:rtpmidi_out", zmr_in['net_in'])
		except:
			pass

	#Connect QMidiNet output to ZynMidiRouter:net_in
	if zynthian_gui_config.midi_network_enabled:
		try:
			jclient.connect("QmidiNet:out_1",zmr_in['net_in'])
		except:
			pass

	#Connect ZynthStep output to ZynMidiRouter:step_in
	try:
		jclient.connect("zynthstep:output", zmr_in['step_in'])
	except:
		pass

	#Connect zynsmf output to ZynMidiRouter:seq_in
	try:
		jclient.connect("zynsmf:midi_out", zmr_in['seq_in'])
	except:
		pass

	#Connect ZynMidiRouter:main_out to zynsmf input
	try:
		jclient.connect(zmr_out['main_out'], "zynsmf:midi_in")
	except:
		pass

	#Connect Engine's Controller-FeedBack to ZynMidiRouter:ctrl_in
	try:
		for efbp in engines_fb:
			jclient.connect(efbp,zmr_in['ctrl_in'])
	except:
		pass

	#logger.debug("Connecting ZynMidiRouter to engines ...")

	#Get layers list from UI
	layers_list=zynthian_gui_config.zyngui.screens["layer"].layers

	#Connect MIDI chain elements
	for i, layer in enumerate(layers_list):
		if layer.get_midi_jackname() and layer.engine.type=="MIDI Tool":
			port_name = get_fixed_midi_port_name(layer.get_midi_jackname())
			ports=jclient.get_ports(port_name, is_output=True, is_midi=True, is_physical=False)
			if ports:
				#Connect to assigned ports and disconnect from the rest ...
				for mi in engines_in:
					#logger.debug(" => Probing {} => {}".format(port_name, mi))
					if mi in layer.get_midi_out():
						#logger.debug(" => Connecting {} => {}".format(port_name, mi))
						try:
							jclient.connect(ports[0],engines_in[mi])
						except:
							pass
						try:
							jclient.disconnect(zmr_out['ch{}_out'.format(layer.midi_chan)], engines_in[mi])
						except:
							pass
					else:
						try:
							jclient.disconnect(ports[0],engines_in[mi])
						except:
							pass


	#Connect ZynMidiRouter to MIDI-chain roots
	midichain_roots = zynthian_gui_config.zyngui.screens["layer"].get_midichain_roots()

	# => Get Root-engines info
	root_engine_info = {}
	for mcrl in midichain_roots:
		for mcprl in zynthian_gui_config.zyngui.screens["layer"].get_midichain_pars(mcrl):
			if mcprl.get_midi_jackname():
				jackname = mcprl.get_midi_jackname()
				if jackname in root_engine_info:
					root_engine_info[jackname]['chans'].append(mcprl.midi_chan)
				else:
					port_name = get_fixed_midi_port_name(jackname)
					ports=jclient.get_ports(port_name, is_input=True, is_midi=True, is_physical=False)
					if ports:
						root_engine_info[jackname] = {
							'port': ports[0],
							'chans': [mcprl.midi_chan]
						}

	for jn, info in root_engine_info.items():
		#logger.debug("MIDI ROOT ENGINE INFO: {} => {}".format(jn, info))
		if None in info['chans']:
			try:
				jclient.connect(zmr_out['main_out'], info['port'])
			except:
				pass

		else:
			for ch in range(0,16):
				try:
					if ch in info['chans']:
						jclient.connect(zmr_out['ch{}_out'.format(ch)], info['port'])
					else:
						jclient.disconnect(zmr_out['ch{}_out'.format(ch)], info['port'])
				except:
					pass

	# Connect Engine's MIDI output to assigned ports
	for layer in zynthian_gui_config.zyngui.screens["layer"].root_layers:
		if layer.midi_chan is None:
			continue

		# Set "Drop Program Change" flag for each MIDI chan
		zyncoder.lib_zyncoder.zmop_chan_set_flag_droppc(layer.midi_chan, int(layer.engine.options['drop_pc']))

		if layer.engine.type in ("MIDI Tool", "Special"):
			port_from_name = get_fixed_midi_port_name(layer.get_midi_jackname())
			ports_from=jclient.get_ports(port_from_name, is_output=True, is_midi=True, is_physical=False)
			if ports_from:
				port_from = ports_from[0]

				# Connect to MIDI-chain root layers ...
				for jn, info in root_engine_info.items():
					try:
						if jn in layer.get_midi_out():
							jclient.connect(port_from, info['port'])
						else:
							jclient.disconnect(port_from, info['port'])
					except:
						pass

				# Connect to enabled Hardware MIDI Output Ports ...
				if "MIDI-OUT" in layer.get_midi_out():
					for hw in hw_in:
						try:
							if get_port_alias_id(hw) in zynthian_gui_config.enabled_midi_out_ports:
								jclient.connect(port_from, hw)
							else:
								jclient.disconnect(port_from, hw)
						except:
							pass
				else:
					for hw in hw_in:
						try:
							jclient.disconnect(port_from, hw)
						except:
							pass

				# Connect to enabled Network MIDI Output Ports ...
				if "NET-OUT" in layer.get_midi_out():
					try:
						jclient.connect(port_from, "QmidiNet:in_1")
					except:
						pass
					try:
						jclient.connect(port_from, "jackrtpmidid:rtpmidi_in")
					except:
						pass
				else:
					try:
						jclient.disconnect(port_from, "QmidiNet:in_1")
					except:
						pass
					try:
						jclient.disconnect(port_from, "jackrtpmidid:rtpmidi_in")
					except:
						pass

	#Connect ZynMidiRouter:midi_out to enabled Hardware MIDI Output Ports
	for hw in hw_in:
		try:
			if zynthian_gui_config.midi_filter_output and (get_port_alias_id(hw) in zynthian_gui_config.enabled_midi_out_ports or hw.name in  zynthian_gui_config.enabled_midi_out_ports):
				jclient.connect(zmr_out['midi_out'],hw)
			else:
				jclient.disconnect(zmr_out['midi_out'],hw)
		except:
			pass

	if zynthian_gui_config.midi_filter_output:
		#Connect ZynMidiRouter:net_out to QMidiNet input
		if zynthian_gui_config.midi_network_enabled:
			try:
				jclient.connect(zmr_out['net_out'],"QmidiNet:in_1")
			except:
				pass
		#Connect ZynMidiRouter:net_out to RTP-MIDI input
		if zynthian_gui_config.midi_rtpmidi_enabled:
			try:
				jclient.connect(zmr_out['net_out'],"jackrtpmidid:rtpmidi_in")
			except:
				pass
	else:
		#Disconnect ZynMidiRouter:net_out to QMidiNet input
		if zynthian_gui_config.midi_network_enabled:
			try:
				jclient.disconnect(zmr_out['net_out'],"QmidiNet:in_1")
			except:
				pass
		#Disconnect ZynMidiRouter:net_out to RTP-MIDI input
		if zynthian_gui_config.midi_rtpmidi_enabled:
			try:
				jclient.disconnect(zmr_out['net_out'],"jackrtpmidid:rtpmidi_in")
			except:
				pass

	#Connect ZynMidiRouter:step_out to ZynthStep input
	try:
		jclient.connect(zmr_out['step_out'], "zynthstep:input")
	except:
		pass

	#Connect ZynMidiRouter:ctrl_out to enabled MIDI-FB ports (MIDI-Controller FeedBack)
	for hw in hw_in:
		try:
			if get_port_alias_id(hw) in zynthian_gui_config.enabled_midi_fb_ports:
				jclient.connect(zmr_out['ctrl_out'],hw)
			else:
				jclient.disconnect(zmr_out['ctrl_out'],hw)
		except:
			pass

	#Release Mutex Lock
	release_lock()

def audio_autoconnect(force=False):

	if not force or not zynthian_gui_config.zyngui.isBootingComplete:
		logger.info("ZynAutoConnect: Audio Escaped ...")
		return

	#Get Mutex Lock
	acquire_lock()

	logger.info("ZynAutoConnect: Audio ...")

	#Get Audio Input Ports (ports receiving audio => inputs => you write on it!!)
	input_ports=get_audio_input_ports(True)

	#Get System Playbak Ports
	playback_ports = get_audio_playback_ports()

	#Disconnect Monitor from System Output
	mon_in=jclient.get_ports("mod-monitor", is_output=True, is_audio=True)
	try:
		jclient.disconnect(mon_in[0],'system:playback_1')
		jclient.disconnect(mon_in[1],'system:playback_2')
	except:
		pass

	###
	# Handle SamplerSynth ports:
	# - Always leave the global uneffected port alone (as that should just
	#   always be connected to system playback, which SamplerSynth does by default)
	# - If the global effects stack is empty, connect the global effected port to
	#   system playback, otherwise connect to the effects
	# - For each channel, check whether the effects stack is empty. It it is, connect
	#   the SamplerSynth output for that channel to system playback, otherwise connect
	#   to the effects

	# Connect the global effects passthrough wet output to the global effects
	hasGlobalEffects = False
	if len(zynthian_gui_config.zyngui.global_fx_engines) > 0:
		for engine, _ in zynthian_gui_config.zyngui.global_fx_engines:
			try:
				engineInPorts = jclient.get_ports(engine.jackname, is_audio=True, is_input=True);
				# Some engines only take mono input, but we want them to receive both our left and right outputs, so connect l and r both to that one input
				if len(engineInPorts) == 1:
					engineInPorts[1] = engineInPorts[0];
				for port in zip(jclient.get_ports("GlobalFXPassthrough:wetOut", is_audio=True, is_output=True), engineInPorts):
					hasGlobalEffects = True
					try:
						jclient.connect(port[0], port[1])
					except: pass
			except Exception as e:
				logging.error(f"Failed to connect global fx passthrough to one of the effect engines. Postponing the auto connection until the next autoconnect run, at which point it should hopefully be fine. Reported error: {e}")
				# Logic below the return statement will be eventually evaluated when called again after the timeout
				force_next_autoconnect = True;
				release_lock()
				return
	# Connect the global effects passthrough dry output to system out
	try:
		for port in zip(jclient.get_ports("GlobalFXPassthrough:dryOut", is_audio=True, is_output=True), playback_ports):
			try:
				jclient.connect(port[0], port[1])
			except: pass
	except Exception as e:
		logging.error(f"Failed to connect global fx passthrough to system playback. Postponing the auto connection until the next autoconnect run, at which point it should hopefully be fine. Reported error: {e}")
		# Logic below the return statement will be eventually evaluated when called again after the timeout
		force_next_autoconnect = True;
		release_lock()
		return

	globalFxPassthroughInput = jclient.get_ports("GlobalFXPassthrough:input", is_audio=True, is_input=True)
	logging.error(f"Global FX Inputs are {globalFxPassthroughInput}")
	
	# Connect SamplerSynth's global effected to the global effects passthrough
	for port in zip(jclient.get_ports("SamplerSynth-global-effected", is_audio=True, is_output=True), globalFxPassthroughInput):
		try:
			jclient.connect(port[0], port[1])
		except: pass
	# Disconnect global effected port from system playback
	for port in zip(jclient.get_ports("SamplerSynth-global-effected", is_audio=True, is_output=True), playback_ports):
		try:
			#logging.info(f"Disconnecting global effected port from {port[1]}")
			jclient.disconnect(port[0], port[1])
		except Exception as e:
			#logging.info(f"Could not disconnect the global effected channel from playback: {e}")
			pass

	# Connect global FX ports to system playback
	try:
		for engine, _ in zynthian_gui_config.zyngui.global_fx_engines:
			try:
				engineOutPorts = jclient.get_ports(engine.jackname, is_audio=True, is_output=True);
				for port in zip(engineOutPorts, playback_ports):
					try:
						jclient.connect(port[0], port[1])
					except: pass
			except Exception as e:
				logging.error(f"Failed to connect an engine up. Postponing the auto connection until the next autoconnect run, at which point it should hopefully be fine. Reported error: {e}")
				# Unlock mutex and return early as autoconnect is being rescheduled to be called after 1000ms because of an exception
				# Logic below the return statement will be eventually evaluated when called again after the timeout
				force_next_autoconnect = True;
				release_lock()
				return
	except: pass

	# Connect each channel's ports to either that channel's effects inputs ports, or to the system playback ports, depending on whether there are any effects for the channel
	# If there's no song yet, we can't do a lot...
	song = zynthian_gui_config.zyngui.screens["sketchpad"].song
	if not song:
		pass
	else:
		for channelId in range(0, 10):
			channel = song.channelsModel.getChannel(channelId)
			if channel is not None:
				channelPorts = jclient.get_ports(f"SamplerSynth-channel_{channelId + 1}:", is_audio=True, is_output=True)
				# Only connect the sampelersynth client for the channel to the outputs if this is a sample based channel, otherwise disconnect SamplerSynth
				if channel.channelAudioType.startswith("sample-"):
					# Firstly, attempt to connect the channel to any effects attached to the channel
					channelHasEffects = False
					if len(channel.chainedSounds) > 0:
						for chainedSound in channel.chainedSounds:
							if chainedSound > -1 and channel.checkIfLayerExists(chainedSound):
								layer = zynthian_gui_config.zyngui.screens['layer'].layer_midi_map[chainedSound]
								effectsLayers = zynthian_gui_config.zyngui.screens['layer'].get_fxchain_layers(layer)
								if effectsLayers != None and len(effectsLayers) > 0:
									# As there are effects, connect the channel's outputs to their inputs
									for sl in effectsLayers:
										if sl.engine.type == "Audio Effect":
											try:
												engineInPorts = jclient.get_ports(sl.engine.jackname, is_audio=True, is_input=True);
												if len(engineInPorts) == 1:
													engineInPorts.append(engineInPorts[0]);
												for port in zip(channelPorts, engineInPorts):
													channelHasEffects = True
													try:
														jclient.connect(port[0], port[1])
													except: pass
											except Exception as e:
												logging.error(f"Failed to connect an engine up. Postponing the auto connection until the next autoconnect run, at which point it should hopefully be fine. Reported error: {e}")
												# Unlock mutex and return early as autoconnect is being rescheduled to be called after 1000ms because of an exception
												# Logic below the return statement will be eventually evaluated when called again after the timeout
												force_next_autoconnect = True;
												release_lock()
												return
									pass
					# If the channel wants to route through global FX, connect its outputs to the global effects
					if not channelHasEffects:
						try:
							if channel.routeThroughGlobalFX:
								for port in zip(channelPorts, playback_ports):
									try:
										jclient.disconnect(port[0], port[1])
									except: pass
								for port in zip(channelPorts, globalFxPassthroughInput):
									try:
										jclient.connect(port[0], port[1])
									except: pass
							else:
								for port in zip(channelPorts, playback_ports):
									try:
										jclient.connect(port[0], port[1])
									except: pass
						except Exception as e:
							logging.error(f"Failed to connect an engine up. Postponing the auto connection until the next autoconnect run, at which point it should hopefully be fine. Reported error: {e}")
							# Unlock mutex and return early as autoconnect is being rescheduled to be called after 1000ms because of an exception
							# Logic below the return statement will be eventually evaluated when called again after the timeout
							force_next_autoconnect = True;
							release_lock()
							return
				else:
					for port in channelPorts:
						try:
							portConnections = jclient.get_all_connections(port)
							for otherPort in portConnections:
								jclient.disconnect(port, otherPort)
						except Exception as e:
							logging.error(f"OUCH! {e}")
	###

	#Get layers list from UI
	layers_list=zynthian_gui_config.zyngui.screens["layer"].layers

	#Connect Synth Engines to assigned outputs
	for i, layer in enumerate(layers_list):
		if not layer.get_audio_jackname() or layer.engine.type=="MIDI Tool":
			continue

		layer_playback = [jn for jn in layer.get_audio_out() if jn.startswith("system:playback_")]
		nlpb = len(layer_playback)

		ports=jclient.get_ports(layer.get_audio_jackname(), is_output=True, is_audio=True, is_physical=False)
		if len(ports)>0:
			#logger.debug("Connecting Layer {} ...".format(layer.get_jackname()))
			np = min(len(ports), 2)
			#logger.debug("Num of {} Audio Ports: {}".format(layer.get_jackname(), np))

			#Connect layer to routed playback ports and disconnect from the rest ...
			if len(playback_ports)>0:
				npb = min(nlpb,len(ports))
				for j, pbp in enumerate(playback_ports):
					if pbp.name in layer_playback:
						for k, lop in enumerate(ports):
							if k%npb==j%npb:
								#logger.debug("Connecting {} to {} ...".format(lop.name, pbp.name))
								try:
									jclient.connect(lop, pbp)
								except:
									pass
							else:
								#logger.debug("Disconnecting {} from {} ...".format(lop.name, pbp.name))
								try:
									jclient.disconnect(lop, pbp)
								except:
									pass
					else:
						for lop in ports:
							#logger.debug("Disconnecting {} from {} ...".format(lop.name, pbp.name))
							try:
								jclient.disconnect(lop, pbp)
							except:
								pass

			#Connect to routed layer input ports and disconnect from the rest ...
			for ao in input_ports:
				nip = min(len(input_ports[ao]), 2)
				jrange = list(range(max(np, nip)))
				if ao in layer.get_audio_out():
					#logger.debug(" => Connecting to {} : {}".format(ao,jrange))
					for j in jrange:
						try:
							jclient.connect(ports[j%np],input_ports[ao][j%nip])
						except:
							pass
				else:
					logger.info(" => Disconnecting from {} : {}".format(ao,jrange))
					for j in jrange:
						try:
							jclient.disconnect(ports[j%np],input_ports[ao][j%nip])
						except:
							pass

		#Connect MIDI-Input on Audio-FXs, if it exist ... (i.e. x42 AutoTune)
		if layer.engine.type=="Audio Effect":
			midi_ports=jclient.get_ports(layer.get_midi_jackname(), is_input=True, is_midi=True, is_physical=False)
			if len(midi_ports)>0:
				try:
					jclient.connect("ZynMidiRouter:ch{}_out".format(layer.midi_chan), midi_ports[0])
				except:
					pass

	### Connect synth engines to global effects
	try:
		if zynthian_gui_config.zyngui.sketchpad.song:
			for midi_channel in zynthian_gui_config.zyngui.layer.layer_midi_map:
				synth_engine = zynthian_gui_config.zyngui.layer.layer_midi_map[midi_channel]
				for channel_index in range(0, 10):
					channel = zynthian_gui_config.zyngui.sketchpad.song.channelsModel.getChannel(channel_index)

					# Find which channel midichannel belongs to
					if channel is not None and midi_channel in channel.chainedSounds:
						# Check if channel wants to route through global FX
						if channel.routeThroughGlobalFX:
							is_synth_engine_connected_to_system = False
							synth_engine_output_ports = jclient.get_ports(synth_engine.jackname, is_output=True, is_audio=True)

							if len(synth_engine_output_ports) < 2:
								synth_engine_output_ports[1] = synth_engine_output_ports[0]

							for audio_output_port in synth_engine.get_audio_out():
								if audio_output_port.startswith("system"):
									is_synth_engine_connected_to_system = True
									break

							if is_synth_engine_connected_to_system:
								# Synth engine is connected to system playback, disconnect from system playback and
								# connect synth engine output to global effects

								# Disconnect synth engine from playback port
								for port in zip(synth_engine_output_ports, playback_ports):
									try:
										logging.info(f"Disconnecting {port[0]} from {port[1]} in favour of global effects")
										jclient.disconnect(port[0], port[1])
									except:
										pass

							# Connect synth engine to global fx passthrough ports
							for port in zip(synth_engine_output_ports, globalFxPassthroughInput):
								try:
									logging.info(f"Connecting {port[0]} to global effect {port[1]}")
									jclient.connect(port[0], port[1])
								except:
									pass
						else:
							# Channel does not want to route through Global FX. Break out of loop carry on with next midi channel
							break
	except Exception as e:
		logging.error(f"Failed to autoconnect fully. Postponing the auto connection until the next autoconnect run, at which point it should hopefully be fine. Reported error: {e}")
		# Unlock mutex and return early as autoconnect is being rescheduled to be called after 1000ms because of an exception
		# Logic below the return statement will be eventually evaluated when called again after the timeout
		force_next_autoconnect = True;
		release_lock()
		return
	### END Connect synth engines to global effects

	headphones_out = jclient.get_ports("Headphones", is_input=True, is_audio=True)

	if len(headphones_out)==2 or not zynthian_gui_config.show_cpu_status:
		sysout_conports_1 = jclient.get_all_connections("system:playback_1")
		sysout_conports_2 = jclient.get_all_connections("system:playback_2")

		#Setup headphones connections if enabled ...
		if len(headphones_out)==2:
			#Prepare for setup headphones connections
			headphones_conports_1=jclient.get_all_connections("Headphones:playback_1")
			headphones_conports_2=jclient.get_all_connections("Headphones:playback_2")

			#Disconnect ports from headphones (those that are not connected to System Out, if any ...)
			for cp in headphones_conports_1:
				if cp not in sysout_conports_1:
					try:
						jclient.disconnect(cp,headphones_out[0])
					except:
						pass
			for cp in headphones_conports_2:
				if cp not in sysout_conports_2:
					try:
						jclient.disconnect(cp,headphones_out[1])
					except:
						pass

			#Connect ports to headphones (those currently connected to System Out)
			for cp in sysout_conports_1:
				try:
					jclient.connect(cp,headphones_out[0])
				except:
					pass
			for cp in sysout_conports_2:
				try:
					jclient.connect(cp,headphones_out[1])
				except:
					pass

		#Setup dpmeter connections if enabled ...
		if False: #not zynthian_gui_config.show_cpu_status:
			#Prepare for setup dpmeter connections
			dpmeter_out = jclient.get_ports("jackpeak", is_input=True, is_audio=True)
			dpmeter_conports_1=jclient.get_all_connections("jackpeak:input_a")
			dpmeter_conports_2=jclient.get_all_connections("jackpeak:input_b")

			#Disconnect ports from dpmeter (those that are not connected to System Out, if any ...)
			for cp in dpmeter_conports_1:
				if cp not in sysout_conports_1:
					try:
						jclient.disconnect(cp,dpmeter_out[0])
					except:
						pass
			for cp in dpmeter_conports_2:
				if cp not in sysout_conports_2:
					try:
						jclient.disconnect(cp,dpmeter_out[1])
					except:
						pass

			#Connect ports to dpmeter (those currently connected to System Out)
			for cp in sysout_conports_1:
				try:
					jclient.connect(cp,dpmeter_out[0])
				except:
					pass
			for cp in sysout_conports_2:
				try:
					jclient.connect(cp,dpmeter_out[1])
				except:
					pass

	# Connect to AudioLevels client
	audiolevels_out = jclient.get_ports("AudioLevels-SystemPlayback:", is_input=True, is_audio=True)
	audiolevels_connected_ports_1 = jclient.get_all_connections("AudioLevels-SystemPlayback:left_in")
	audiolevels_connected_ports_2 = jclient.get_all_connections("AudioLevels-SystemPlayback:right_in")
	sysout_conports_1 = jclient.get_all_connections("system:playback_1")
	sysout_conports_2 = jclient.get_all_connections("system:playback_2")
	# Disconnect ports (that is, any that aren't connected to the system playback ports)
	for connected_port in audiolevels_connected_ports_1:
		if connected_port not in sysout_conports_1:
			try:
				logging.info(f"Disconnecting port {connected_port} from audiolevels")
				jclient.disconnect(connected_port, audiolevels_out[0])
			except:
				pass
	for connected_port in audiolevels_connected_ports_2:
		if connected_port not in sysout_conports_2:
			try:
				logging.info(f"Disconnecting port {connected_port} from audiolevels")
				jclient.disconnect(connected_port, audiolevels_out[1])
			except:
				pass
	# Connect anything that is connected to the system playback ports to the audiolevels client, except for the global uneffected
	# SamplerSynth port (which is used for system sound type stuff that shouldn't go in recordings and the like)
	for port_to_connect in sysout_conports_1:
		if not port_to_connect.name.startswith("SamplerSynth-global-uneffected"):
			try:
				logging.info(f"Connecting port {port_to_connect} to audiolevels")
				jclient.connect(port_to_connect, audiolevels_out[0])
			except:
				pass
	for port_to_connect in sysout_conports_2:
		if not port_to_connect.name.startswith("SamplerSynth-global-uneffected"):
			try:
				logging.info(f"Connecting port {port_to_connect} to audiolevels")
				jclient.connect(port_to_connect, audiolevels_out[1])
			except:
			    pass

	#Get System Capture ports => jack output ports!!
	capture_ports = get_audio_capture_ports()
	if len(capture_ports)>0:

		root_layers = zynthian_gui_config.zyngui.screens["layer"].get_fxchain_roots()
		#Connect system capture ports to FX-layers root ...
		for rl in root_layers:
			if not rl.get_audio_jackname() or layer.engine.type!="Audio Effect":
				continue

			# Connect to FX-layers roots and their "pars" (parallel layers)
			for rlp in zynthian_gui_config.zyngui.screens["layer"].get_fxchain_pars(rl):
				#Get Root Layer Input ports ...
				rlp_in = jclient.get_ports(rlp.get_audio_jackname(), is_input=True, is_audio=True)
				if len(rlp_in)>0:
					nsc = min(len(rlp.get_audio_in()),len(rlp_in))

					#Connect System Capture to Root Layer ports
					for j, scp in enumerate(capture_ports):
						if scp.name in rlp.get_audio_in():
							for k, rlp_inp in enumerate(rlp_in):
								if k%nsc==j%nsc:
									#logger.debug("Connecting {} to {} ...".format(scp.name, layer.get_audio_jackname()))
									try:
										jclient.connect(scp, rlp_inp)
									except:
										pass
								else:
									try:
										jclient.disconnect(scp, rlp_inp)
									except:
										pass
								# Limit to 2 input ports
								#if k>=1:
								#	break

						else:
							for rlp_inp in rlp_in:
								try:
									jclient.disconnect(scp, rlp_inp)
								except:
									pass

		if zynthian_gui_config.midi_aubionotes_enabled:
			#Get Aubio Input ports ...
			aubio_in = jclient.get_ports("aubio", is_input=True, is_audio=True)
			if len(aubio_in)>0:
				nip = max(len(aubio_in), 2)
				#Connect System Capture to Aubio ports
				j=0
				for scp in capture_ports:
					try:
						jclient.connect(scp, aubio_in[j%nip])
					except:
						pass
					j += 1

	#Release Mutex Lock
	release_lock()


def audio_disconnect_sysout():
	sysout_ports=jclient.get_ports("system", is_input=True, is_audio=True)
	for sop in sysout_ports:
		conports = jclient.get_all_connections(sop)
		for cp in conports:
			try:
				jclient.disconnect(cp, sop)
			except:
				pass


def get_audio_capture_ports():
	return jclient.get_ports("system", is_output=True, is_audio=True, is_physical=True)


def get_audio_playback_ports():
	return jclient.get_ports("system", is_input=True, is_audio=True, is_physical=True)


def get_audio_input_ports(exclude_system_playback=False):
	res=OrderedDict()
	try:
		for aip in jclient.get_ports(is_input=True, is_audio=True, is_physical=False):
			parts=aip.name.split(':')
			client_name=parts[0]
			if client_name=="jack_capture" or client_name=="jackpeak" or client_name[:7]=="effect_" or client_name.startswith("AudioLevels-"):
				continue
			if client_name=="system":
				if exclude_system_playback:
					continue
				else:
					client_name = aip.name
			if client_name not in res:
				res[client_name]=[aip]
				#logger.debug("AUDIO INPUT PORT: {}".format(client_name))
			else:
				res[client_name].append(aip)
	except:
		pass
	return res


def autoconnect(force=False):
	midi_autoconnect(force)
	audio_autoconnect(force)
	force_next_autoconnect = False;


def autoconnect_thread():
	while not exit_flag:
		try:
			autoconnect(force_next_autoconnect)
		except Exception as err:
			logger.error("ZynAutoConnect ERROR: {}".format(err))
		sleep(refresh_time)


def acquire_lock():
	#if log_level==logging.DEBUG:
	#	calframe = inspect.getouterframes(inspect.currentframe(), 2)
	#	logger.debug("Waiting for lock, requested from '{}'...".format(format(calframe[1][3])))
	lock.acquire()
	#logger.debug("... lock acquired!!")



def release_lock():
	#if log_level==logging.DEBUG:
	#	calframe = inspect.getouterframes(inspect.currentframe(), 2)
	#	logger.debug("Lock released from '{}'".format(calframe[1][3]))
	lock.release()


def start(rt=2):
	global refresh_time, exit_flag, jclient, thread, lock
	refresh_time=rt
	exit_flag=False

	try:
		jclient=jack.Client("Zynthian_autoconnect")
		jclient.set_xrun_callback(cb_jack_xrun)
		jclient.activate()
	except Exception as e:
		logger.error("ZynAutoConnect ERROR: Can't connect with Jack Audio Server ({})".format(e))

	xrun_counter_timer.start()

	# Create Lock object (Mutex) to avoid concurrence problems
	lock=Lock()

	# Start Autoconnect Thread
	thread=Thread(target=autoconnect_thread, args=())
	thread.daemon = True # thread dies with the program
	thread.start()


def stop():
	global exit_flag
	exit_flag=True
	acquire_lock()
	audio_disconnect_sysout()
	release_lock()


def is_running():
	global thread
	return thread.is_alive()


def cb_jack_xrun(delayed_usecs: float):
	global xrun_count

	xrun_count += 1
	zynthian_gui_config.zyngui.status_info['xrun'] = True


def get_jackd_cpu_load():
	return jclient.cpu_load()


def get_jackd_samplerate():
	return jclient.samplerate


def get_jackd_blocksize():
	return jclient.blocksize


#------------------------------------------------------------------------------
