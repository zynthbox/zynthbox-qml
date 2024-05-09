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
from itertools import cycle

from PySide2.QtCore import QTimer
import Zynthbox

# Zynthian specific modules
from zyncoder import *
from zynqtgui import zynthian_gui_config

#-------------------------------------------------------------------------------
# Configure logging
#-------------------------------------------------------------------------------

log_level = logging.WARNING

logger=logging.getLogger(__name__)
logger.setLevel(log_level)

#if log_level==logging.DEBUG:
#    import inspect

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
        logging.debug(f"Got {xrun_count} XRUNS in last 10 seconds")
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
    global force_next_autoconnect

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
    zyngine_list=zynthian_gui_config.zynqtgui.screens["engine"].zyngines

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
    # for p in jclient.get_ports("ZynMidiRouter", is_output=True, is_midi=True):
    for p in jclient.get_ports("ZLRouter:Zynthian-Channel", is_output=True, is_midi=True):
        zmr_out[p.shortname]=p
    # zmr_in=OrderedDict()
    # for p in jclient.get_ports("ZynMidiRouter", is_input=True, is_midi=True):
        # zmr_in[p.shortname]=p

    #logger.debug("ZynMidiRouter Input Ports: {}".format(zmr_out))
    #logger.debug("ZynMidiRouter Output Ports: {}".format(zmr_in))

    #------------------------------------
    # Auto-Connect MIDI Ports
    #------------------------------------

    #Connect "Not Disabled" Input Device Ports to ZynMidiRouter:main_in
    # for hw in hw_out:
    #     #logger.debug("Connecting MIDI Input {} => {}".format(hw,zmr_in['main_in']))
    #     try:
    #         if get_port_alias_id(hw) in zynthian_gui_config.disabled_midi_in_ports:
    #             jclient.disconnect(hw,zmr_in['main_in'])
    #         else:
    #             jclient.connect(hw,zmr_in['main_in'])
    #     except Exception as e:
    #         #logger.debug("Exception {}".format(e))
    #         pass

    #logger.debug("Connecting RTP-MIDI & QMidiNet to ZynMidiRouter:net_in ...")

    #Connect RTP-MIDI output to ZynMidiRouter:net_in
    # if zynthian_gui_config.midi_rtpmidi_enabled:
    #     try:
    #         jclient.connect("jackrtpmidid:rtpmidi_out", zmr_in['net_in'])
    #     except:
    #         pass

    #Connect QMidiNet output to ZynMidiRouter:net_in
    # if zynthian_gui_config.midi_network_enabled:
    #     try:
    #         jclient.connect("QmidiNet:out_1",zmr_in['net_in'])
    #     except:
    #         pass

    #Connect ZynthStep output to ZynMidiRouter:step_in
    # try:
    #     jclient.connect("zynthstep:output", zmr_in['step_in'])
    # except:
    #     pass

    #Connect Engine's Controller-FeedBack to ZynMidiRouter:ctrl_in
    # try:
    #     for efbp in engines_fb:
    #         jclient.connect(efbp,zmr_in['ctrl_in'])
    # except:
    #     pass

    #logger.debug("Connecting ZynMidiRouter to engines ...")

    #Get layers list from UI
    layers_list=zynthian_gui_config.zynqtgui.screens["layer"].layers

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
                            jclient.disconnect(zmr_out['Zynthian-Channel{}'.format(layer.midi_chan)], engines_in[mi])
                        except:
                            pass
                    else:
                        try:
                            jclient.disconnect(ports[0],engines_in[mi])
                        except:
                            pass


    #Connect ZynMidiRouter to MIDI-chain roots
    midichain_roots = zynthian_gui_config.zynqtgui.screens["layer"].get_midichain_roots()

    # => Get Root-engines info
    root_engine_info = {}
    for mcrl in midichain_roots:
        for mcprl in zynthian_gui_config.zynqtgui.screens["layer"].get_midichain_pars(mcrl):
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

    # If there are any overrides set on that slot (information is on sketchpad_channel), use those instead:
    #   - sketchpadTrack:(-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9) where -1 is whatever the current is
    #   - no-input (explicitly refuse midi data)
    #   - specifically named hardware devices
    try:
        song = zynthian_gui_config.zynqtgui.screens["sketchpad"].song
        if song:
            for channelId in range(0, 10):
                channel = song.channelsModel.getChannel(channelId)
                if channel is not None:
                    for routingData in [channel.synthRoutingData, channel.fxRoutingData]:
                        for slotId in range(0, 5):
                            # BEGIN Midi Routing Overrides
                            for midiInPort in routingData[slotId].midiInPorts:
                                if len(midiInPort.sources) > 0:
                                    # Only actually perform overriding if there are any sources defined, otherwise leave well enough alone
                                    eventPorts = []
                                    # Gather up what inputs we should be connected to
                                    for inputSource in midiInPort.sources:
                                        if inputSource.port == "no-input":
                                            # Just do nothing in this case
                                            pass
                                        elif inputSource.port.startswith("sketchpadTrack:"):
                                            splitData = inputSource.port.split(":")
                                            if splitData[1] == "-1":
                                                eventPorts.append("ZLRouter:CurrentTrackMirror")
                                                pass
                                            else:
                                                if channel.trackType == "synth":
                                                    eventPorts.append(f"ZLRouter:Channel{splitData[1]}")
                                                else:
                                                    eventPorts.append(f"ZLRouter:Zynthian-Channel{splitData[1]}")
                                                pass
                                        elif inputSource.port.startswith("external:"):
                                            # Listen to input from a specific hardware device
                                            splitData = inputSource.port.split(":")
                                            hardwareDevice = Zynthbox.MidiRouter.instance().model().getDevice(splitData[1])
                                            if hardwareDevice is not None:
                                                eventPorts.append(hardwareDevice.inputPortName())
                                    # First disconnect anything already hooked up
                                    try:
                                        for connectedTo in jclient.get_all_connections(midiInPort.jackname):
                                            jclient.disconnect(midiInPort.jackname, connectedTo)
                                    except: pass
                                    # Then hook up what we've been asked to
                                    for eventPort in eventPorts:
                                        try:
                                            jclient.connect(eventPort, midiInPort.jackname)
                                        except: pass
                        # END Midi Routing Overrides
    except Exception as e:
        logging.debug(f"Error while trying to run midi_autoconnect due to : {e}. Postponing midi_autoconnect request")
        force_next_autoconnect = True
        release_lock()
        return

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
                        jclient.connect(zmr_out['Zynthian-Channel{}'.format(ch)], info['port'])
                    else:
                        jclient.disconnect(zmr_out['Zynthian-Channel{}'.format(ch)], info['port'])
                except:
                    pass

    # Connect Engine's MIDI output to assigned ports
    for layer in zynthian_gui_config.zynqtgui.screens["layer"].root_layers:
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
    global force_next_autoconnect

    try:
        if not zynthian_gui_config.zynqtgui.isBootingComplete or zynthian_gui_config.zynqtgui.sketchpad.sketchpadLoadingInProgress:
            # If Booting is not complete, do not run autoconnect
            # If a sketchpad is being loaded do not run autoconnect
            # Autoconnect will be explicitly called once after booting is complete
            # logging.debug("Skipping audio_autoconnect")
            return
    except Exception as e:
        logging.debug(f"Error while trying to run audio_autoconnect due to : {e}. Postponing midi_autoconnect request")
        force_next_autoconnect = True
        return

    if not force:
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

    try:
        # This assumes FX input and output ports to have left and right channel stereo input and output respectively
        globalFx1InputPorts = jclient.get_ports(zynthian_gui_config.zynqtgui.global_fx_engines[0][0].jackname, is_audio=True, is_input=True)
        globalFx2InputPorts = jclient.get_ports(zynthian_gui_config.zynqtgui.global_fx_engines[1][0].jackname, is_audio=True, is_input=True)
        globalFx1OutputPorts = jclient.get_ports(zynthian_gui_config.zynqtgui.global_fx_engines[0][0].jackname, is_audio=True, is_output=True)
        globalFx2OutputPorts = jclient.get_ports(zynthian_gui_config.zynqtgui.global_fx_engines[1][0].jackname, is_audio=True, is_output=True)
    except Exception as e:
        logging.error(f"Failed to connect effect engines to bluealsa ports. Postponing the auto connection until the next autoconnect run, at which point it should hopefully be fine. Reported error: {e}")
        # Logic below the return statement will be eventually evaluated when called again after the timeout
        force_next_autoconnect = True
        release_lock()
        return

    ###
    # Handle SamplerSynth ports:
    # - Always leave the global uneffected port alone (as that should just
    #   always be connected to system playback, which SamplerSynth does by default)
    # - If the global effects stack is empty, connect the global effected port to
    #   system playback, otherwise connect to the effects
    # - For each channel, check whether the effects stack is empty. It it is, connect
    #   the SamplerSynth output for that channel to system playback, otherwise connect
    #   to the effects

    # Disable bluetooth ports connection for now
    # Re-enable when bluetooth functionality is enabled
    ###################################
    # ### Bluetooth ports connection
    # bluealsa_ports = jclient.get_ports("bluealsa", is_audio=True, is_input=True)
    #
    # # Connect to bluealsa ports only if bluealsa ports are available
    # if len(bluealsa_ports) > 0:
    #     # Connect GlobalFXPassthrough dry ports to bluealsa (if available)
    #     try:
    #         for port in zip(jclient.get_ports("GlobalFXPassthrough:dryOut", is_audio=True, is_output=True), bluealsa_ports):
    #             try:
    #                 jclient.connect(port[0], port[1])
    #             except: pass
    #     except Exception as e:
    #         logging.error(f"Failed to connect global fx passthrough to bluealsa playback. Postponing the auto connection until the next autoconnect run, at which point it should hopefully be fine. Reported error: {e}")
    #         # Logic below the return statement will be eventually evaluated when called again after the timeout
    #         force_next_autoconnect = True
    #         release_lock()
    #         return
    #
    #     # Connect Global effects output to bluealsa (if available)
    #     if len(zynthian_gui_config.zynqtgui.global_fx_engines) > 0:
    #         for engine, _ in zynthian_gui_config.zynqtgui.global_fx_engines:
    #             try:
    #                 engineOutPorts = jclient.get_ports(engine.jackname, is_audio=True, is_output=True)
    #                 # Some engines only take mono output, but we want them to receive both our left and right outputs, so connect l and r both to that one output
    #                 if len(engineOutPorts) == 1:
    #                     engineOutPorts[1] = engineOutPorts[0]
    #                 for port in zip(engineOutPorts, bluealsa_ports):
    #                     try:
    #                         jclient.connect(port[0], port[1])
    #                     except: pass
    #             except Exception as e:
    #                 logging.error(f"Failed to connect effect engines to bluealsa ports. Postponing the auto connection until the next autoconnect run, at which point it should hopefully be fine. Reported error: {e}")
    #                 # Logic below the return statement will be eventually evaluated when called again after the timeout
    #                 force_next_autoconnect = True
    #                 release_lock()
    #                 return
    # ### END Bluetooth ports connection
    globalPlaybackInputPorts = jclient.get_ports("GlobalPlayback", is_audio=True, is_input=True)

    # BEGIN Connect global FX ports to system playback
    for port in zip(globalFx1OutputPorts, globalPlaybackInputPorts):
        try:
            jclient.connect(port[0], port[1])
        except: pass
    for port in zip(globalFx2OutputPorts, globalPlaybackInputPorts):
        try:
            jclient.connect(port[0], port[1])
        except: pass
    # END Connect global FX ports to system playback

    # TODO We are only connecting the first pair of ports here (since the global channels don't really have advanced routing anyway).
    # TODO Maybe we could actually get away with only using the one global samplersynth, and instead use the two first lanes to perform the same job? (no effect for lane 0, effects for lane 1, no connection for the other three)
    # BEGIN Connect SamplerSynth's global effected to the global effects passthrough
    samplerSynthEffectedPorts =jclient.get_ports("SamplerSynth:global-lane2", is_audio=True, is_output=True)
    for port in zip(samplerSynthEffectedPorts, globalFx1InputPorts):
        try:
            jclient.connect(port[0], port[1])
        except: pass
    for port in zip(samplerSynthEffectedPorts, globalFx2InputPorts):
        try:
            jclient.connect(port[0], port[1])
        except: pass
    for port in zip(samplerSynthEffectedPorts, globalPlaybackInputPorts):
        try:
            jclient.connect(port[0], port[1])
        except: pass
    # END Connect SamplerSynth's global effected to the global effects passthrough

    # logging.info("Clear out any connections ChannelPassthrough and FXPassthrough might already have")
    # BEGIN Clear out any connections ChannelPassthrough and FXPassthrough might already have
    try:
        # Disconnect all FXPassthrough ports
        passthrough_ports = jclient.get_ports("FXPassthrough", is_audio=True)
        # Also disconnect all the ChannelPassthrough ports
        passthrough_ports.extend(jclient.get_ports("ChannelPassthrough", is_audio=True))
        for port in passthrough_ports:
            for connected_port in jclient.get_all_connections(port):
                # logging.info(f"Disonnecting {connected_port} from {port}")
                try:
                    jclient.disconnect(connected_port, port)
                except: pass
    except Exception as e:
        logging.info(f"Failed to autoconnect fully. Postponing the auto connection until the next autoconnect run, at which point it should hopefully be fine. Failed during passthrough connection clearing. Reported error: {e}")
        # Unlock mutex and return early as autoconnect is being rescheduled to be called after 1000ms because of an exception
        # Logic below the return statement will be eventually evaluated when called again after the timeout
        force_next_autoconnect = True;
        release_lock()
        return
    # END Clear out any connections ChannelPassthrough and FXPassthrough might already have

    # logging.info("Connect channel sound sources (SamplerSynth and synths) to their relevant input lanes on ChannelPassthrough and FXPassthrough")
    # BEGIN Connect channel sound sources (SamplerSynth and synths) to their relevant input lanes on ChannelPassthrough and FXPassthrough
    try:
        song = zynthian_gui_config.zynqtgui.screens["sketchpad"].song
        if song:
            for channelId in range(0, 10):
                channel = song.channelsModel.getChannel(channelId)
                channelAudioLevelsInputPorts = jclient.get_ports(f"AudioLevels:Channel{channelId + 1}-", is_audio=True, is_input=True)
                laneHasInput = [False] * 5; # needs to be lane-bound, to ensure we don't disconnect just because we end up without a thing later
                if channel is not None:
                    channelSynthRoutingData = channel.synthRoutingData
                    channelFxRoutingData = channel.fxRoutingData
                    channelInputLanes = [1] * 5 # The default is a serial layout, meaning all channel output goes through a single lane
                    if channel.channelRoutingStyle == "one-to-one":
                        channelInputLanes = [1, 2, 3, 4, 5]
                    for laneId in range(0, 5):
                        laneInputs = jclient.get_ports(name_pattern=f"ChannelPassthrough:Channel{channelId + 1}-lane{channelInputLanes[laneId]}-input", is_audio=True, is_output=False, is_input=True)
                        # BEGIN Handle external inputs for external mode channels
                        # only hook up the first lane, doesn't make super lots of sense otherwise
                        if laneId == 0 and channel.trackType == "external":
                            # logging.info(f"Channel {channelId} is external with the audio source {channel.externalAudioSource}")
                            if len(channel.externalAudioSource) > 0:
                                if (laneHasInput[channelInputLanes[laneId]] == False): laneHasInput[channelInputLanes[laneId]] = True
                                try:
                                    externalSourcePorts = jclient.get_ports(name_pattern=f"{channel.externalAudioSource}:", is_audio=True, is_output=True, is_input=False)
                                    # logging.info(f"External source ports: {externalSourcePorts}")
                                    if len(externalSourcePorts) < 2:
                                        externalSourcePorts.append(externalSourcePorts[0])
                                    for port in zip(externalSourcePorts, laneInputs):
                                        jclient.connect(port[0], port[1])
                                except: pass
                        # END Handle external inputs for external mode channels
                        # BEGIN Handle sample slots
                        samplerOutputPorts = jclient.get_ports(name_pattern=f"SamplerSynth:channel_{channelId + 1}-lane{laneId + 1}", is_audio=True, is_output=True, is_input=False)
                        sample = channel.samples[laneId]
                        loopSample = channel.parts[laneId].getClip(0)
                        if sample.audioSource is not None or (loopSample and loopSample.audioSource is not None):
                            # Connect sampler ports if there's a sample or loop in the given slot
                            if (laneHasInput[channelInputLanes[laneId]] == False): laneHasInput[channelInputLanes[laneId]] = True
                            # logging.info(f"Connecting {samplerOutputPorts} to {laneInputs}")
                            for port in zip(samplerOutputPorts, laneInputs):
                                try:
                                    # Make sure this is the only connection we've got
                                    for connectedTo in jclient.get_all_connections(port[0]):
                                        try:
                                            jclient.disconnect(port[0], connectedTo)
                                        except: pass
                                    # logging.info(f"Connecting {port[0]} to {port[1]}")
                                    jclient.connect(port[0], port[1])
                                except: pass
                        # END Handle sample slots
                        # BEGIN Handle synth slots
                        # If there are any overrides set on that slot, use those instead:
                        #   - standard-routing:(left, right, both) - synth have none, but the option exists and would function the same as no-input
                        #   - no-input (explicitly refuse audio input) - this is the default, but again, option exists
                        #   - external:(left, right, both)
                        #   - internal-master:(left, right, both)
                        #   - sketchpadTrack:(trackindex):(dry0, dry1, dry2, dry3, dry4):(left,right,both)
                        #   - fxSlot:(trackindex):(dry0, wet0, dry1, wet1, dry2, wet2, dry3, wet3, dry4, wet4):(left,right,both)
                        chainedSound = channel.chainedSounds[laneId]
                        if chainedSound > -1 and channel.checkIfLayerExists(chainedSound):
                            # We have a synth to hook up, let's do that thing
                            if (laneHasInput[channelInputLanes[laneId]] == False): laneHasInput[channelInputLanes[laneId]] = True
                            synthPassthroughInputPorts = [f"SynthPassthrough:Synth{chainedSound + 1}-inputLeft", f"SynthPassthrough:Synth{chainedSound + 1}-inputRight"]
                            synthPassthroughOutputPorts = [f"SynthPassthrough:Synth{chainedSound + 1}-dryOutLeft", f"SynthPassthrough:Synth{chainedSound + 1}-dryOutRight"]
                            layer = zynthian_gui_config.zynqtgui.screens['layer'].layer_midi_map[chainedSound]
                            if layer is not None:
                                # BEGIN Synth Inputs
                                slotRoutingData = channelSynthRoutingData[laneId]
                                for audioInPort in slotRoutingData.audioInPorts:
                                    if len(audioInPort.sources) > 0:
                                        # Only actually perform overriding if there are any sources defined, otherwise leave well enough alone
                                        capture_ports = []
                                        for inputSource in audioInPort.sources:
                                            if inputSource.port.starswith("standard-routing:") or inputSource.port == "no-input":
                                                # just do nothing in this case:
                                                # - standard routing is to have no sound connected to synth engines
                                                # - no-input means don't make any connections
                                                pass
                                            elif inputSource.port.startswith("external:"):
                                                # hook up to the system/mic input
                                                if inputSource.endswith(":left"):
                                                    capture_ports.append(get_audio_capture_ports()[0]);
                                                elif inputSource.endswith(":right"):
                                                    capture_ports.append(get_audio_capture_ports()[1]);
                                                else:
                                                    capture_ports = get_audio_capture_ports()
                                            elif inputSource.port.startswith("internal-master:"):
                                                # hook up to listen to the master output
                                                if inputSource.endswith(":left") or inputSource.endswith(":both"):
                                                    capture_ports.append("GlobalPlayback:dryOutLeft");
                                                if inputSource.endswith(":right") or inputSource.endswith(":both"):
                                                    capture_ports.append("GlobalPlayback:dryOutRight");
                                            elif inputSource.port.startswith("sketchpadTrack:") or inputSource.port.startswith("fxSlot:"):
                                                # hook up to listen to the output of that specific graph port
                                                splitData = inputSource.split(":")
                                                portRootName = ""
                                                theLane = splitData[2][-1]
                                                if inputSource.port.startswith("sketchpadTrack:"):
                                                    portRootName = f"FXPassthrough-lane{theLane}-Channel{splitData[1]}"
                                                else:
                                                    portRootName = f"ChannelPassthrough:Channel{splitData[1]}-lane{theLane}"
                                                if splitData[2].startswith("dry"):
                                                    dryOrWet = "dryOut"
                                                elif splitData[2].starswith("wet"):
                                                    dryOrWet = "wetOutFx1"
                                                if splitData[3] == "left" or splitData[3] == "both":
                                                    capture_ports.append(f"{portRootName}-{dryOrWet}Left")
                                                if splitData[3] == "right" or splitData[3] == "both":
                                                    capture_ports.append(f"{portRootName}-{dryOrWet}Right")
                                        # First disconnect anything already hooked up
                                        try:
                                            for connectedTo in jclient.get_all_connections(audioInPort.jackname):
                                                jclient.disconnect(audioInPort.jackname, connectedTo)
                                        except: pass
                                        # Then hook up what we've been asked to
                                        for capture_port in capture_ports:
                                            try:
                                                jclient.connect(capture_port, audioInPort.jackname)
                                            except: pass
                                # END Synth Inputs
                                # BEGIN Synth Outputs
                                engineOutPorts = jclient.get_ports(layer.jackname, is_output=True, is_input=False, is_audio=True)
                                # If this engine is mono, make sure we hook the output to both of the synth passthrough's inputs
                                if len(engineOutPorts) < 2:
                                    engineOutPorts.append(engineOutPorts[0])
                                # If the engine is connected to system_playback, disconnect it from there, just to be on the safe side
                                engineIsConnectedToSystem = False
                                for audioOutputPort in layer.get_audio_out():
                                    if audioOutputPort.startswith("system"):
                                        engineIsConnectedToSystem = True
                                        break
                                if engineIsConnectedToSystem:
                                    for port in zip(engineOutPorts, playback_ports):
                                        try:
                                            # logging.info(f"Disconnecting {port[0]} from {port[1]} in favour of the channel's passthrough client")
                                            jclient.disconnect(port[0], port[1])
                                        except: pass
                                # Connect synth engine to synth passthrough ports
                                for port in zip(engineOutPorts, synthPassthroughInputPorts):
                                    try:
                                        # logging.info(f"Connecting {port[0]} to synth passthrough client {port[1]}")
                                        jclient.connect(port[0], port[1])
                                    except: pass

                                # Connect synth passthrough ports to channel passthrough ports
                                for port in zip(synthPassthroughOutputPorts, laneInputs):
                                    try:
                                        # logging.info(f"Connecting {port[0]} to channel passthrough client {port[1]}")
                                        jclient.connect(port[0], port[1])
                                    except: pass
                                # END Synth Outputs
                        # END Handle synth slots
                        # BEGIN Connect lane to its relevant FX input port (or disconnect if there's no audio input)
                        laneOutputs = jclient.get_ports(name_pattern=f"ChannelPassthrough:Channel{channelId + 1}-lane{channelInputLanes[laneId]}-dryOut", is_audio=True, is_output=True, is_input=False)
                        portsToConnect = globalPlaybackInputPorts + channelAudioLevelsInputPorts
                        # In standard routing mode, any fx on the channel should result in routing to the first slot with an fx - if there are no fx in the track, route it to global out
                        if channel.channelRoutingStyle == "standard":
                            for index, fxlayer in enumerate(channel.chainedFx):
                                if fxlayer is not None:
                                    portsToConnect = jclient.get_ports(f"FXPassthrough-lane{index + 1}:Channel{channel.id + 1}-input", is_audio=True, is_output=False, is_input=True)
                                    break
                        # In one-to-one mode, check if the matching fx slot for a sound slot has an effect in it, and if there is one, route to it - if there is not one, route it to global out
                        elif channel.channelRoutingStyle == "one-to-one":
                            if channel.chainedFx[laneId] is not None:
                                portsToConnect = jclient.get_ports(name_pattern=f"FXPassthrough-lane{channelInputLanes[laneId]}:Channel{channelId + 1}-input", is_audio=True, is_output=False, is_input=True)
                        for port in zip(portsToConnect, cycle(laneOutputs)):
                            # The order of the ports is uncommonly reversed here, to ensure we can use cycle() without causing trouble
                            try:
                                if laneHasInput[channelInputLanes[laneId]]:
                                    jclient.connect(port[1], port[0])
                            except: pass
                        # END Connect lane to its relevant FX or GlobalPlayback input port (or disconnect if there's no audio input)
                        # BEGIN Connect ChannelPassthrough wet ports to GlobalPlayback and AudioLevels via Global FX
                        laneOutputsFx1 = jclient.get_ports(name_pattern=f"ChannelPassthrough:Channel{channelId + 1}-lane{channelInputLanes[laneId]}-wetOutFx1", is_audio=True, is_output=True, is_input=False)
                        laneOutputsFx2 = jclient.get_ports(name_pattern=f"ChannelPassthrough:Channel{channelId + 1}-lane{channelInputLanes[laneId]}-wetOutFx2", is_audio=True, is_output=True, is_input=False)
                        for port in zip(laneOutputsFx1, channelAudioLevelsInputPorts):
                            try:
                                if laneHasInput[channelInputLanes[laneId]]:
                                    jclient.connect(port[0], port[1])
                                else:
                                    jclient.disconnect(port[0], port[1])
                            except: pass
                        for port in zip(laneOutputsFx2, channelAudioLevelsInputPorts):
                            try:
                                if laneHasInput[channelInputLanes[laneId]]:
                                    jclient.connect(port[0], port[1])
                                else:
                                    jclient.disconnect(port[0], port[1])
                            except: pass
                        for port in zip(laneOutputsFx1, globalFx1InputPorts):
                            try:
                                if laneHasInput[channelInputLanes[laneId]]:
                                    jclient.connect(port[0], port[1])
                                else:
                                    jclient.disconnect(port[0], port[1])
                            except: pass
                        for port in zip(laneOutputsFx2, globalFx2InputPorts):
                            try:
                                if laneHasInput[channelInputLanes[laneId]]:
                                    jclient.connect(port[0], port[1])
                                else:
                                    jclient.disconnect(port[0], port[1])
                            except: pass
                        # END Connect ChannelPassthrough wet ports to GlobalPlayback and AudioLevels via Global FX
                    ### BEGIN Connect ChannelPassthrough to GlobalPlayback and AudioLevels via FX
                    logging.debug(f"# Channel{channelId+1} effects port connections :")

                    # Create a list of lists of ports to be connected in order, dependent on routing style
                    # For serial ("standard"): Single entry containing (Fx1, Fx2, Fx3, Fx4, Fx5, GlobalPlayback)
                    # one-to-one: An entry per part, entries contain the FXPassthrough lane for the equivalent part, and GlobalPlayback. For example: (Fx1, GlobalPlayback), (Fx2, GlobalPlayback), (Fx3, GlobalPlayback)...
                    # Only add an fx entry to the list if the slot is occupied (an fx entry consists of two clients: the fx passthrough, and the fx jack client itself)
                    # Only add GlobalPlayback to the list if the list is not empty
                    # Only add the individual list to the processing list if it is not empty
                    # Further, if there are any overrides set on that slot, use those instead:
                    #   - standard-routing:(left, right, both)
                    #   - no-input (explicitly refuse audio input)
                    #   - external:(left, right, both)
                    #   - internal-master:(left, right, both)
                    #   - sketchpadTrack:(trackindex):(dry0, dry1, dry2, dry3, dry4, ):(left,right,both)
                    #   - fxSlot:(trackindex):(dry0, wet0, dry1, wet1, dry2, wet2, dry3, wet3, dry4, wet4):(left,right,both)
                    # TODO Implement overrides
                    process_list = []

                    if channel.channelRoutingStyle == "standard":
                        # The order should be FXPassthrough + FX layers in order -> global playback / Audio levels
                        # If there are FX in chain, then there will be 2 clients per FX, i.e. one FX Passthrough and the actual FX client

                        fx_client_names = []
                        # Create a set of client names for each FX in channel
                        # The FX Passthrough should be placed first and then the fx client name
                        for index, fxlayer in enumerate(channel.chainedFx):
                            if fxlayer is not None:
                                fx_client_names = fx_client_names + [f"FXPassthrough-lane{index + 1}:Channel{channel.id + 1}-", fxlayer.get_jackname()]

                        # Create final client names list, with the client names as it should be connected in order,
                        # and only add that list to the process list if there are actually any effects in the list
                        if len(fx_client_names) > 0:
                            lane_client_names = fx_client_names + ["GlobalPlayback"]
                            process_list.append(lane_client_names)
                    elif channel.channelRoutingStyle == "one-to-one":
                        for laneId in range(0, 5):
                            fxlayer = channel.chainedFx[laneId]
                            if fxlayer is not None:
                                lane_client_names = [f"FXPassthrough-lane{laneId + 1}:Channel{channel.id + 1}-", fxlayer.get_jackname(), "GlobalPlayback"]
                                process_list.append(lane_client_names)

                    # logging.info(f"# Output client names : {process_list}")

                    # Disconnect any existing connections to and from from the fx layers audio ports
                    for index, fxlayer in enumerate(channel.chainedFx):
                        if fxlayer is not None:
                            fx_in_ports = jclient.get_ports(fxlayer.get_jackname(), is_audio=True)
                            for fx_in_port in fx_in_ports:
                                for connectedTo in jclient.get_all_connections(fx_in_port):
                                    try:
                                        jclient.disconnect(fx_in_port, connectedTo)
                                    except: pass

                    for output_client_names in process_list:
                        # logging.info(f"## Processing list {output_client_names}")
                        output_client_names_count = len(output_client_names)
                        for (index, client_name) in enumerate(output_client_names):
                            # logging.info(f"## Processing client : {client_name}")
                            # The last client is global playback and consequently does not need to be processed
                            # This will create a two scenarios based if FX clients are connected:
                            #    Scenario 1 : There are no FX in channel
                            #                 Then the final client list would be empty
                            #    Scenario 2 : There is one or more FX Client
                            #                 Then the final client list would be : [FXPassthrough-laneY:ChannelX -> FX](There will be a set of passthrough + fx for each fx client) -> GlobalPlayback
                            # In any of the scenarios the last port, GlobalPlayback, does not need to be connected to anything else. Hence do not process GlobalPlayback
                            # For all other clients, check if the client is an FXPassthrough.
                            # If the client is not a FXPassthrough, then it means it can either be a ChannelPassthrough or an FX. So connect it's output to the next client
                            # If the client is an FXPassthrough then it means the next client is FX and the next to next client can either be another passthrough or GlobalPlayback (does not matter as the logic is same for both). In that case connect dry ports to next to next client and wet ports to the fx for dry/wet mix to actually work like it should
                            # When connecting ports check if the port is getting connected to GlobalPlayback. If it is getting connected to GlobalPlayback then connect the same port to AudioLevels too of the channel being processed for the AudioLevel meter to work

                            # The last client can either be an FX or the ChannelPassthrough if there are no FX.
                            # For both cases, it should be connected to AudioLevels and GlobalPlayback as it is the end node

                            if index == output_client_names_count - 1:
                                # The last port, GlobalPlayback, does not need to be connected to anything else. Hence do not process GlobalPlayback
                                pass
                            else:
                                # If the client that is being processed is not the last client,
                                # that means this client is either ChannelPassthrough, or FXPassthrough or FX itself.

                                # If the client that is being processed is a passthrough then connect the dryOutput to the
                                # next to next client so that the dry output is passed on the the next in line FX or Global Playback

                                # If the client that is being processed is ChannelPassthrough or an FX then just connect it to the
                                # next in line client

                                if client_name.startswith("FXPassthrough"):
                                    # Client being processed is an FXPassthrough client
                                    # It means that the next client is FX and the next to next client can either be another passthrough or GlobalPlayback (does not matter as the logic is same for both).
                                    # In that case connect dry ports to next to next client and wet ports to the fx for dry/wet mix to actually work like it should

                                    # Connect this client to the next client in list
                                    dry_out_ports = jclient.get_ports(client_name + "dryOut", is_audio=True, is_output=True)
                                    wet_out_ports = jclient.get_ports(client_name + "wetOutFx1", is_audio=True, is_output=True)
                                    next_in_ports = jclient.get_ports(output_client_names[index+1], is_audio=True, is_input=True)
                                    next_next_in_ports = jclient.get_ports(output_client_names[index+2], is_audio=True, is_input=True)

                                    # If input/output is mono, make to connect to stereo input/output.
                                    if len(dry_out_ports) == 1:
                                        dry_out_ports = [dry_out_ports[0], dry_out_ports[0]]
                                    if len(wet_out_ports) == 1:
                                        wet_out_ports = [wet_out_ports[0], wet_out_ports[0]]
                                    if len(next_in_ports) == 1:
                                        next_in_ports = [next_in_ports[0], next_in_ports[0]]
                                    if len(next_next_in_ports) == 1:
                                        next_next_in_ports = [next_next_in_ports[0], next_next_in_ports[0]]

                                    # Connect dry ports to next to next client
                                    for ports in zip(dry_out_ports, next_next_in_ports):
                                        logging.info(f"Connecting {ports[0]} to {ports[1]}")
                                        try:
                                            jclient.connect(ports[0], ports[1])
                                        except: pass
                                    # Connect wet ports to FX client which is right next to this client in output_client_names
                                    for ports in zip(wet_out_ports, next_in_ports):
                                        logging.info(f"Connecting {ports[0]} to {ports[1]}")
                                        try:
                                            jclient.connect(ports[0], ports[1])
                                        except: pass
                                    # If next to next client is GlobalPlayback then connect the same port to AudioLevels too
                                    if output_client_names[index+2] == "GlobalPlayback":
                                        for ports in zip(dry_out_ports, channelAudioLevelsInputPorts):
                                            logging.info(f"Connecting {ports[0]} to {ports[1]}")
                                            try:
                                                jclient.connect(ports[0], ports[1])
                                            except: pass
                                else:
                                    # This client is not a FXPassthrough, and not the last client in the list, which means it will be an FX. So connect it's output to the next client

                                    # Connect this client to the next client in list
                                    next_client_name = output_client_names[index+1]
                                    out_ports = jclient.get_ports(client_name, is_audio=True, is_output=True)
                                    if len(out_ports) == 1:
                                        # If output is mono, connect both input to same output.
                                        out_ports = [out_ports[0], out_ports[0]]

                                    if next_client_name == "GlobalPlayback":
                                        # Next client is GlobalPlayback then connect the same port to both GlobalPlayback and AudioLevels
                                        for ports in zip(out_ports, channelAudioLevelsInputPorts):
                                            logging.info(f"Connecting {ports[0]} to {ports[1]}")
                                            try:
                                                jclient.connect(ports[0], ports[1])
                                            except: pass
                                        for ports in zip(out_ports, globalPlaybackInputPorts):
                                            logging.info(f"Connecting {ports[0]} to {ports[1]}")
                                            try:
                                                jclient.connect(ports[0], ports[1])
                                            except: pass
                                    else:
                                        # Next client is not GlobalPlayback. Connect the ports to next client
                                        next_in_ports = jclient.get_ports(next_client_name, is_audio=True, is_input=True)

                                        if len(next_in_ports) == 1:
                                            # If input is mono, connect both output to same input.
                                            next_in_ports = [next_in_ports[0], next_in_ports[0]]

                                        for ports in zip(out_ports, next_in_ports):
                                            logging.info(f"Connecting {ports[0]} to {ports[1]}")
                                            try:
                                                jclient.connect(ports[0], ports[1])
                                            except: pass
                    ### END Connect ChannelPassthrough to GlobalPlayback and AudioLevels via FX
                    ### BEGIN FX Engine Audio Routing Overrides
                    for laneId in range(0, 5):
                        slotRoutingData = channelFxRoutingData[laneId]
                        fxSlotInputs = {
                            "left": [],
                            "right": []
                            }
                        for audioInPort in slotRoutingData.audioInPorts:
                            if len(audioInPort.sources) > 0:
                                # Only actually perform overriding if there are any sources defined, otherwise leave well enough alone
                                capture_ports = []
                                for inputSource in audioInPort.sources:
                                    if inputSource.port == "no-input":
                                        # just do nothing in this case:
                                        pass
                                    if inputSource.port.starswith("standard-routing:"):
                                        # hook up with the default route input
                                        if len(fxSlotInputs["left"]) == 0:
                                            # Lazily fill the slots input list here, in case it hasn't happened yet
                                            # Bit of a tricky trick - usually there will be two ports, sometimes there will be only one, so we'll have to deal with both those eventualities
                                            for port, leftOrRight in zip(slotRoutingData.audioInPorts, cycle("left", "right")):
                                                for connectedTo in jclient.get_all_connections(port):
                                                    fxSlotInputs[leftOrRight].append(connectedTo)
                                            if len(slotRoutingData.audioInPorts) == 1:
                                                fxSlotInputs["right"] = fxSlotInputs["left"]
                                        if inputSource.endswith(":left"):
                                            capture_ports.append(fxSlotInputs["left"]);
                                        elif inputSource.endswith(":right"):
                                            capture_ports.append(fxSlotInputs["right"]);
                                        else:
                                            capture_ports.append(fxSlotInputs["left"]);
                                            capture_ports.append(fxSlotInputs["right"]);
                                    elif inputSource.port.startswith("external:"):
                                        # hook up to the system/mic input
                                        if inputSource.endswith(":left"):
                                            capture_ports.append(get_audio_capture_ports()[0]);
                                        elif inputSource.endswith(":right"):
                                            capture_ports.append(get_audio_capture_ports()[1]);
                                        else:
                                            capture_ports = get_audio_capture_ports()
                                    elif inputSource.port.startswith("internal-master:"):
                                        # hook up to listen to the master output
                                        if inputSource.endswith(":left") or inputSource.endswith(":both"):
                                            capture_ports.append("GlobalPlayback:dryOutLeft");
                                        if inputSource.endswith(":right") or inputSource.endswith(":both"):
                                            capture_ports.append("GlobalPlayback:dryOutRight");
                                    elif inputSource.port.startswith("sketchpadTrack:") or inputSource.port.startswith("fxSlot:"):
                                        # hook up to listen to the output of that specific graph port
                                        splitData = inputSource.split(":")
                                        portRootName = ""
                                        theLane = splitData[2][-1]
                                        if inputSource.port.startswith("sketchpadTrack:"):
                                            portRootName = f"FXPassthrough-lane{theLane}-Channel{splitData[1]}-"
                                        else:
                                            portRootName = f"ChannelPassthrough:Channel{splitData[1]}-lane{theLane}-"
                                        if splitData[2].startswith("dry"):
                                            dryOrWet = "dryOut"
                                        elif splitData[2].starswith("wet"):
                                            dryOrWet = "wetOutFx1"
                                        if splitData[3] == "left" or splitData[3] == "both":
                                            capture_ports.append(f"{portRootName}{dryOrWet}Left")
                                        if splitData[3] == "right" or splitData[3] == "both":
                                            capture_ports.append(f"{portRootName}{dryOrWet}Right")
                                # First disconnect anything already hooked up
                                try:
                                    for connectedTo in jclient.get_all_connections(audioInPort.jackname):
                                        jclient.disconnect(audioInPort.jackname, connectedTo)
                                except: pass
                                # Then hook up what we've been asked to
                                for capture_port in capture_ports:
                                    try:
                                        jclient.connect(capture_port, audioInPort.jackname)
                                    except: pass
                    ### END FX Engine Audio Routing Overrides
        else:
            logging.info("No song yet, clearly ungood - also how?")
    except Exception as e:
        logging.info(f"Failed to autoconnect fully. Postponing the auto connection until the next autoconnect run, at which point it should hopefully be fine. Failed during core routing setup. Reported error: {e}")
        # Unlock mutex and return early as autoconnect is being rescheduled to be called after 1000ms because of an exception
        # Logic below the return statement will be eventually evaluated when called again after the timeout
        force_next_autoconnect = True;
        release_lock()
        return
    ### END Connect channel sound sources (SamplerSynth and synths) to their relevant input lanes on ChannelPassthrough and FXPassthrough


    ### BEGIN Connect Samplersynth uneffected ports to globalPlayback client
    for port in zip(jclient.get_ports("SamplerSynth:global-lane1", is_audio=True, is_output=True), globalPlaybackInputPorts):
        try:
            jclient.connect(port[0], port[1])
        except: pass
    ### END Connect Samplersynth uneffected ports to globalPlayback client

    ### Connect globalPlayback ports
    globalPlaybackDryOutputPorts = jclient.get_ports("GlobalPlayback:dryOut", is_audio=True, is_output=True)
    for port in zip(globalPlaybackDryOutputPorts, playback_ports):
        try:
            jclient.connect(port[0], port[1])
        except:
            #logging.debug("Error connecting ports")
            pass

    for port in zip(globalPlaybackDryOutputPorts, jclient.get_ports("AudioLevels:SystemPlayback-", is_input=True, is_audio=True)):
        try:
            jclient.connect(port[0], port[1])
        except:
            # logging.debug("Error connecting ports")
            pass
    ### END Connect globalPlayback ports

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

    #Get System Capture ports => jack output ports!!
    capture_ports = get_audio_capture_ports()
    if len(capture_ports)>0:

        # Not doing this - we've got explicit routing for capturing the system in ports, so this bit of automagic seems a bit awkward now
        # root_layers = zynthian_gui_config.zynqtgui.screens["layer"].get_fxchain_roots()
        # #Connect system capture ports to FX-layers root ...
        # for rl in root_layers:
        #     if not rl.get_audio_jackname() or rl.engine.type!="Audio Effect":
        #         continue
        #
        #     # Connect to FX-layers roots and their "pars" (parallel layers)
        #     for rlp in zynthian_gui_config.zynqtgui.screens["layer"].get_fxchain_pars(rl):
        #         #Get Root Layer Input ports ...
        #         rlp_in = jclient.get_ports(rlp.get_audio_jackname(), is_input=True, is_audio=True)
        #         if len(rlp_in)>0:
        #             nsc = min(len(rlp.get_audio_in()),len(rlp_in))
        #
        #             #Connect System Capture to Root Layer ports
        #             for j, scp in enumerate(capture_ports):
        #                 if scp.name in rlp.get_audio_in():
        #                     for k, rlp_inp in enumerate(rlp_in):
        #                         if k%nsc==j%nsc:
        #                             #logger.debug("Connecting {} to {} ...".format(scp.name, layer.get_audio_jackname()))
        #                             try:
        #                                 jclient.connect(scp, rlp_inp)
        #                             except:
        #                                 pass
        #                         else:
        #                             try:
        #                                 jclient.disconnect(scp, rlp_inp)
        #                             except:
        #                                 pass
        #                         # Limit to 2 input ports
        #                         #if k>=1:
        #                         #    break
        #
        #                 else:
        #                     for rlp_inp in rlp_in:
        #                         try:
        #                             jclient.disconnect(scp, rlp_inp)
        #                         except:
        #                             pass

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
            if client_name=="jack_capture" or client_name[:7]=="effect_" or client_name.startswith("AudioLevels:"):
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
    global force_next_autoconnect

    midi_autoconnect(force)
    audio_autoconnect(force)
    force_next_autoconnect = False


def autoconnect_thread():
    while not exit_flag:
        try:
            autoconnect(force_next_autoconnect)
        except Exception as err:
            logger.error("ZynAutoConnect ERROR: {}".format(err))
        sleep(refresh_time)


def acquire_lock():
    #if log_level==logging.DEBUG:
    #    calframe = inspect.getouterframes(inspect.currentframe(), 2)
    #    logger.debug("Waiting for lock, requested from '{}'...".format(format(calframe[1][3])))
    lock.acquire()
    #logger.debug("... lock acquired!!")



def release_lock():
    #if log_level==logging.DEBUG:
    #    calframe = inspect.getouterframes(inspect.currentframe(), 2)
    #    logger.debug("Lock released from '{}'".format(calframe[1][3]))
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
    zynthian_gui_config.zynqtgui.status_info['xrun'] = True


def get_jackd_cpu_load():
    return jclient.cpu_load()


def get_jackd_samplerate():
    return jclient.samplerate


def get_jackd_blocksize():
    return jclient.blocksize


#------------------------------------------------------------------------------
