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
import traceback
from time import sleep
from threading  import Thread, Lock
from collections import OrderedDict
from itertools import cycle
from queue import SimpleQueue

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
# Post-autoconnect callback queues (for running commands after the next successful autoconnect runs)
#------------------------------------------------------------------------------

redoAutoconnectMidi = False
postMidiConnectCallbacks = SimpleQueue()
redoAutoconnectAudio = False
postAudioConnectCallbacks = SimpleQueue()

# Pass a callback to be run after autoconnecting midi next time and schedules a run of the midi autoconnect
# Calling this will abort the current autoconnect run if one is ongoing, and ask for another run
def callAfterMidiAutoconnect(callback):
    global postMidiConnectCallbacks
    global redoAutoconnectMidi
    global force_next_autoconnect
    redoAutoconnectMidi = True
    force_next_autoconnect = True
    postMidiConnectCallbacks.put(callback)

# Pass a callback to be run after autoconnecting audio next time and schedules a run of the audio autoconnect
# If one is ongoing, autoconnect will check first and ensure that it re-runs before attempting
# to run the callbacks, to try and ensure that all connections are completed first
def callAfterAudioAutoconnect(callback):
    global postAudioConnectCallbacks
    global redoAutoconnectAudio
    global force_next_autoconnect
    redoAutoconnectAudio = True
    force_next_autoconnect = True
    postAudioConnectCallbacks.put(callback)

# This will be done immediately prior to attempting to perform the enqueued callbacks
# If we are asked to redo the autoconnect, we will do precisely that (recursively,
# just for simplicity's sake)
def runCallbacksAfterMidiAutoconnect():
    global postMidiConnectCallbacks
    global redoAutoconnectMidi
    if redoAutoconnectMidi:
        # If we should redo the autoconnect, do so immediately
        redoAutoconnectMidi = False
        midi_autoconnect(force=True)
    else:
        # Otherwise run the callbacks
        while postMidiConnectCallbacks.empty() == False:
            if redoAutoconnectMidi:
                # In case we have been called in the middle of doing things here...
                # let's make sure we restart so the connections are completed first
                redoAutoconnectMidi = False
                midi_autoconnect(force=True)
                break
            else:
                callback = postMidiConnectCallbacks.get()
                if callable(callback):
                    callback()
                else:
                    logging.error(f"We have been asked to perform a callback which is not callable: {callback}")

# This will be done immediately prior to attempting to perform the enqueued callbacks
# If we are asked to redo the autoconnect, we will do precisely that (recursively,
# just for simplicity's sake)
def runCallbacksAfterAudioAutoconnect():
    global postAudioConnectCallbacks
    global redoAutoconnectAudio
    if redoAutoconnectAudio:
        # If we should redo the autoconnect, do so immediately
        redoAutoconnectAudio = False
        audio_autoconnect(force=True)
    else:
        # Otherwise run the callbacks
        while postAudioConnectCallbacks.empty() == False:
            if redoAutoconnectAudio:
                # In case we have been called in the middle of doing things here...
                # let's make sure we restart so the connections are completed first
                redoAutoconnectAudio = False
                audio_autoconnect(force=True)
                break
            else:
                callback = postAudioConnectCallbacks.get()
                if callable(callback):
                    callback()
                else:
                    logging.error(f"We have been asked to perform a callback which is not callable: {callback}")

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

# This will return the port name from any Jack port, or if we were passed a string, just return that string
def get_jack_port_name(port):
    if isinstance(port, str):
        return port
    return port.name
#------------------------------------------------------------------------------

def midi_autoconnect(force=False):
    global last_hw_str
    global force_next_autoconnect

    #Get Mutex Lock
    acquire_lock()

    logger.info("ZynAutoConnect: MIDI ...")

    zbjack = Zynthbox.JackConnectionHandler.instance()

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
        zbjack.clear()
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
    #             zbjack.disconnectPorts(get_jack_port_name(hw), get_jack_port_name(zmr_in['main_in']))
    #         else:
    #             zbjack.connectPorts(get_jack_port_name(hw), get_jack_port_name(zmr_in['main_in']))
    #     except Exception as e:
    #         #logger.debug("Exception {}".format(e))
    #         pass

    #logger.debug("Connecting RTP-MIDI & QMidiNet to ZynMidiRouter:net_in ...")

    #Connect RTP-MIDI output to ZynMidiRouter:net_in
    # if zynthian_gui_config.midi_rtpmidi_enabled:
    #     try:
    #         zbjack.connectPorts("jackrtpmidid:rtpmidi_out", get_jack_port_name(zmr_in['net_in']))
    #     except:
    #         pass

    #Connect QMidiNet output to ZynMidiRouter:net_in
    # if zynthian_gui_config.midi_network_enabled:
    #     try:
    #         zbjack.connectPorts("QmidiNet:out_1", get_jack_port_name(zmr_in['net_in']))
    #     except:
    #         pass

    #Connect ZynthStep output to ZynMidiRouter:step_in
    # try:
    #     zbjack.connectPorts("zynthstep:output", get_jack_port_name(zmr_in['step_in']))
    # except:
    #     pass

    #Connect Engine's Controller-FeedBack to ZynMidiRouter:ctrl_in
    # try:
    #     for efbp in engines_fb:
    #         zbjack.connectPorts(get_jack_port_name(efbp), get_jack_port_name(zmr_in['ctrl_in']))
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
                        zbjack.connectPorts(get_jack_port_name(ports[0]), get_jack_port_name(engines_in[mi]))
                        zbjack.disconnectPorts(get_jack_port_name(zmr_out['Zynthian-Channel{}'.format(layer.midi_chan)]), get_jack_port_name(engines_in[mi]))
                    else:
                        zbjack.disconnectPorts(get_jack_port_name(ports[0]), get_jack_port_name(engines_in[mi]))


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

    for jn, info in root_engine_info.items():
        #logger.debug("MIDI ROOT ENGINE INFO: {} => {}".format(jn, info))
        if None in info['chans']:
            zbjack.connectPorts(get_jack_port_name(zmr_out['main_out']), get_jack_port_name(info['port'].name))

        else:
            for ch in range(0,16):
                if ch in info['chans']:
                    zbjack.connectPorts(get_jack_port_name(zmr_out['Zynthian-Channel{}'.format(ch)]), get_jack_port_name(info['port']))
                else:
                    zbjack.disconnectPorts(get_jack_port_name(zmr_out['Zynthian-Channel{}'.format(ch)]), get_jack_port_name(info['port']))

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
                                    for connectedTo in zbjack.getAllConnections(midiInPort.jackname):
                                        zbjack.disconnectPorts(connectedTo, midiInPort.jackname)
                                    # Then hook up what we've been asked to
                                    for eventPort in eventPorts:
                                        zbjack.connectPorts(eventPort, midiInPort.jackname)
                        # END Midi Routing Overrides
    except Exception as e:
        logging.debug(f"Error while trying to run midi_autoconnect due to : {e}. Postponing midi_autoconnect request")
        force_next_autoconnect = True
        zbjack.clear()
        release_lock()
        return

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
                    if jn in layer.get_midi_out():
                        zbjack.connectPorts(get_jack_port_name(port_from), get_jack_port_name(info['port']))
                    else:
                        zbjack.disconnectPorts(get_jack_port_name(port_from), get_jack_port_name(info['port']))

                # Connect to enabled Hardware MIDI Output Ports ...
                if "MIDI-OUT" in layer.get_midi_out():
                    for hw in hw_in:
                        if get_port_alias_id(hw) in zynthian_gui_config.enabled_midi_out_ports:
                            zbjack.connectPorts(get_jack_port_name(port_from), get_jack_port_name(hw))
                        else:
                            zbjack.disconnectPorts(get_jack_port_name(port_from), get_jack_port_name(hw))
                else:
                    for hw in hw_in:
                        zbjack.disconnectPorts(get_jack_port_name(port_from), get_jack_port_name(hw))

                # Connect to enabled Network MIDI Output Ports ...
                if "NET-OUT" in layer.get_midi_out():
                    zbjack.connectPorts(get_jack_port_name(port_from), "QmidiNet:in_1")
                    zbjack.connectPorts(get_jack_port_name(port_from), "jackrtpmidid:rtpmidi_in")
                else:
                    zbjack.disconnectPorts(get_jack_port_name(port_from), "QmidiNet:in_1")
                    zbjack.disconnectPorts(get_jack_port_name(port_from), "jackrtpmidid:rtpmidi_in")

    #Connect ZynMidiRouter:midi_out to enabled Hardware MIDI Output Ports
    # for hw in hw_in:
        # if zynthian_gui_config.midi_filter_output and (get_port_alias_id(hw) in zynthian_gui_config.enabled_midi_out_ports or hw.name in  zynthian_gui_config.enabled_midi_out_ports):
            # zbjack.connectPorts(get_jack_port_name(zmr_out['midi_out']), get_jack_port_name(hw))
        # else:
            # zbjack.disconnectPorts(get_jack_port_name(zmr_out['midi_out']), get_jack_port_name(hw))

    # if zynthian_gui_config.midi_filter_output:
    #     #Connect ZynMidiRouter:net_out to QMidiNet input
    #     if zynthian_gui_config.midi_network_enabled:
    #         zbjack.connectPorts(get_jack_port_name(zmr_out['net_out']), "QmidiNet:in_1")
    #     #Connect ZynMidiRouter:net_out to RTP-MIDI input
    #     if zynthian_gui_config.midi_rtpmidi_enabled:
    #         zbjack.connectPorts(get_jack_port_name(zmr_out['net_out']), "jackrtpmidid:rtpmidi_in")
    # else:
    #     #Disconnect ZynMidiRouter:net_out to QMidiNet input
    #     if zynthian_gui_config.midi_network_enabled:
    #         zbjack.disconnectPorts(get_jack_port_name(zmr_out['net_out']), "QmidiNet:in_1")
    #     #Disconnect ZynMidiRouter:net_out to RTP-MIDI input
    #     if zynthian_gui_config.midi_rtpmidi_enabled:
    #         zbjack.disconnectPorts(get_jack_port_name(zmr_out['net_out']), "jackrtpmidid:rtpmidi_in")

    #Connect ZynMidiRouter:step_out to ZynthStep input
    # zbjack.connectPorts(get_jack_port_name(zmr_out['step_out']), "zynthstep:input")

    #Connect ZynMidiRouter:ctrl_out to enabled MIDI-FB ports (MIDI-Controller FeedBack)
    # for hw in hw_in:
        # if get_port_alias_id(hw) in zynthian_gui_config.enabled_midi_fb_ports:
            # zbjack.connectPorts(get_jack_port_name(zmr_out['ctrl_out']), get_jack_port_name(hw))
        # else:
            # zbjack.disconnectPorts(get_jack_port_name(zmr_out['ctrl_out']), get_jack_port_name(hw))

    #Finally, commit all the connections and disconnections
    zbjack.commit()

    #Release Mutex Lock
    release_lock()

    # Now we're done, test to see whether we've got any callbacks that need running
    runCallbacksAfterMidiAutoconnect()

    # Autoconnect ran fine. Reset force flag
    force_next_autoconnect = False

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

    zbjack = Zynthbox.JackConnectionHandler.instance()

    logger.info("ZynAutoConnect: Audio ...")

    #Get Audio Input Ports (ports receiving audio => inputs => you write on it!!)
    input_ports=get_audio_input_ports(True)

    #Get System Playbak Ports
    playback_ports = get_audio_playback_ports()

    #Disconnect Monitor from System Output
    mon_in=jclient.get_ports("mod-monitor", is_output=True, is_audio=True)
    if len(mon_in) == 2:
        zbjack.disconnectPorts(get_jack_port_name(mon_in[0]),'system:playback_1')
        zbjack.disconnectPorts(get_jack_port_name(mon_in[1]),'system:playback_2')

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
        zbjack.clear()
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
    #             zbjack.connectPorts(get_jack_port_name(port[0]), get_jack_port_name(port[1]))
    #     except Exception as e:
    #         logging.error(f"Failed to connect global fx passthrough to bluealsa playback. Postponing the auto connection until the next autoconnect run, at which point it should hopefully be fine. Reported error: {e}")
    #         # Logic below the return statement will be eventually evaluated when called again after the timeout
    #         force_next_autoconnect = True
    #         zbjack.clear()
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
    #                     zbjack.connectPorts(get_jack_port_name(port[0]), get_jack_port_name(port[1]))
    #             except Exception as e:
    #                 logging.error(f"Failed to connect effect engines to bluealsa ports. Postponing the auto connection until the next autoconnect run, at which point it should hopefully be fine. Reported error: {e}")
    #                 # Logic below the return statement will be eventually evaluated when called again after the timeout
    #                 force_next_autoconnect = True
    #                 zbjack.clear()
    #                 release_lock()
    #                 return
    # ### END Bluetooth ports connection
    globalPlaybackInputPorts = ["GlobalPlayback:inputLeft", "GlobalPlayback:inputRight"]

    # BEGIN Connect global FX ports to system playback
    for port in zip(globalFx1OutputPorts, globalPlaybackInputPorts):
        zbjack.connectPorts(get_jack_port_name(port[0]), get_jack_port_name(port[1]))
    for port in zip(globalFx2OutputPorts, globalPlaybackInputPorts):
        zbjack.connectPorts(get_jack_port_name(port[0]), get_jack_port_name(port[1]))
    # END Connect global FX ports to system playback

    # TODO We are only connecting the first pair of ports here (since the global channels don't really have advanced routing anyway).
    # TODO Maybe we could actually get away with only using the one global samplersynth, and instead use the two first lanes to perform the same job? (no effect for lane 0, effects for lane 1, no connection for the other three)
    # BEGIN Connect SamplerSynth's global effected to the global effects passthrough
    for laneType in ["sample", "sketch"]:
        samplerSynthEffectedPorts = jclient.get_ports(f"SamplerSynth:global-{laneType}2-", is_audio=True, is_output=True)
        for port in zip(samplerSynthEffectedPorts, globalFx1InputPorts):
            zbjack.connectPorts(get_jack_port_name(port[0]), get_jack_port_name(port[1]))
        for port in zip(samplerSynthEffectedPorts, globalFx2InputPorts):
            zbjack.connectPorts(get_jack_port_name(port[0]), get_jack_port_name(port[1]))
        for port in zip(samplerSynthEffectedPorts, globalPlaybackInputPorts):
            zbjack.connectPorts(get_jack_port_name(port[0]), get_jack_port_name(port[1]))
    # END Connect SamplerSynth's global effected to the global effects passthrough

    # logging.info("Clear out any connections TrackPassthrough and FXPassthrough might already have")
    # BEGIN Clear out any connections TrackPassthrough and FXPassthrough might already have
    try:
        # Disconnect all FXPassthrough ports
        passthrough_ports = jclient.get_ports("FXPassthrough", is_audio=True)
        # Also disconnect all the TrackPassthrough ports
        passthrough_ports.extend(jclient.get_ports("TrackPassthrough", is_audio=True))
        for port in passthrough_ports:
            port_name = get_jack_port_name(port)
            if port_name.endswith("-sidechainInputLeft") or port_name.endswith("-sidechainInputRight"):
                # Don't disconnect the passthrough's sidechain ports, as those are done by the clients internally
                pass
            else:
                for connected_port in zbjack.getAllConnections(port_name):
                # logging.info(f"Disonnecting {connected_port} from {port_name}")
                    zbjack.disconnectPorts(connected_port, port_name)
    except Exception as e:
        logging.info(f"Failed to autoconnect fully. Postponing the auto connection until the next autoconnect run, at which point it should hopefully be fine. Failed during passthrough connection clearing. Reported error: {e}")
        # Unlock mutex and return early as autoconnect is being rescheduled to be called after 1000ms because of an exception
        # Logic below the return statement will be eventually evaluated when called again after the timeout
        force_next_autoconnect = True;
        zbjack.clear()
        release_lock()
        return
    # END Clear out any connections TrackPassthrough and FXPassthrough might already have

    # logging.info("Connect channel sound sources (SamplerSynth and synths) to their relevant input lanes on TrackPassthrough and FXPassthrough")
    # BEGIN Connect channel sound sources (SamplerSynth and synths) to their relevant input lanes on TrackPassthrough and FXPassthrough
    try:
        usbGadgetInputs = jclient.get_ports(name_pattern="usb-gadget-in:", is_audio=True, is_output=False, is_input=True)
        song = zynthian_gui_config.zynqtgui.screens["sketchpad"].song
        synthEntryExists = [False] * 16 # TODO If we want to have more than 16 synth slots, this will need changing
        # Format is trackPassthroughLanesEnabled[trackId][laneId][laneType]
        # Annoying that you can't simply do [[[False,False]*5]*10 for this, but that results in duplicated reference instead, so...
        trackPassthroughLanesEnabled = []
        for trackId in range(0, 10):
            trackData = []
            for laneId in range(0, 5):
                trackData.append([False, False])
            trackPassthroughLanesEnabled.append(trackData)
        if song:
            for channelId in range(0, 10):
                channel = song.channelsModel.getChannel(channelId)
                channelAudioLevelsInputPorts = [f"AudioLevels:Channel{channelId + 1}-left_in", f"AudioLevels:Channel{channelId + 1}-right_in"]
                laneHasInput = [False] * 5; # needs to be lane-bound, to ensure we don't disconnect just because we end up without a thing later
                sketchLaneHasInput = [False] * 5; # needs to be lane-bound, to ensure we don't disconnect just because we end up without a thing later
                if channel is not None:
                    channelSynthRoutingData = channel.synthRoutingData
                    channelFxRoutingData = channel.fxRoutingData
                    channelInputLanes = [0] * 5 # The default is a serial layout, meaning all channel output goes through a single lane
                    if channel.trackRoutingStyle == "one-to-one":
                        channelInputLanes = [0, 1, 2, 3, 4]
                    for laneId in range(0, 5):
                        laneInputs = [f"TrackPassthrough:Channel{channelId + 1}-lane{channelInputLanes[laneId] + 1}-inputLeft", f"TrackPassthrough:Channel{channelId + 1}-lane{channelInputLanes[laneId] + 1}-inputRight"]
                        sketchLaneInputs = [f"TrackPassthrough:Channel{channelId + 1}-sketch{channelInputLanes[laneId] + 1}-inputLeft", f"TrackPassthrough:Channel{channelId + 1}-sketch{channelInputLanes[laneId] + 1}-inputRight"]
                        # BEGIN Handle external inputs for external mode channels
                        # only hook up the first lane, doesn't make super lots of sense otherwise
                        if laneId == 0 and channel.trackType == "external":
                            # logging.info(f"Channel {channelId} is external with the audio source {channel.externalAudioSource}")
                            if len(channel.externalAudioSource) > 0:
                                if (laneHasInput[channelInputLanes[laneId]] == False): laneHasInput[channelInputLanes[laneId]] = True
                                try:
                                    externalSourcePorts = jclient.get_ports(name_pattern=f"{channel.externalAudioSource}", is_audio=True, is_output=True, is_input=False)
                                    # logging.info(f"External source ports: {externalSourcePorts}")
                                    if len(externalSourcePorts) < 2:
                                        externalSourcePorts.append(externalSourcePorts[0])
                                    for port in zip(externalSourcePorts, laneInputs):
                                        zbjack.connectPorts(get_jack_port_name(port[0]), get_jack_port_name(port[1]))
                                except: pass
                        # END Handle external inputs for external mode channels
                        # BEGIN Handle sample slots
                        for sampleSlotRow in range(0, Zynthbox.Plugin.instance().sketchpadSampleSlotRowCount()):
                            sampleIndex = (sampleSlotRow * 5) + laneId
                            samplerOutputPorts = [f"SamplerSynth:channel_{channelId + 1}-sample{sampleIndex + 1}-left", f"SamplerSynth:channel_{channelId + 1}-sample{sampleIndex + 1}-right"]
                            sample = channel.samples[sampleIndex]
                            if sample.audioSource is not None:
                                # Connect sampler ports if there's a sample in the given slot
                                if (laneHasInput[channelInputLanes[laneId]] == False): laneHasInput[channelInputLanes[laneId]] = True
                                # logging.info(f"Connecting {samplerOutputPorts} to {laneInputs}")
                                for port in zip(samplerOutputPorts, laneInputs):
                                    # Make sure this is the only connection we've got
                                    for connectedTo in zbjack.getAllConnections(get_jack_port_name(port[0])):
                                        if connectedTo.endswith("-sidechainInputLeft") or connectedTo.endswith("-sidechainInputRight"):
                                            # Don't disconnect the sidechain ports, though...
                                            pass
                                        else:
                                            zbjack.disconnectPorts(get_jack_port_name(port[0]), connectedTo)
                                    # logging.info(f"Connecting {port[0]} to {port[1]}")
                                    zbjack.connectPorts(get_jack_port_name(port[0]), get_jack_port_name(port[1]))
                        # END Handle sample slots
                        # BEGIN Handle sketch slots
                        samplerOutputPorts = [f"SamplerSynth:channel_{channelId + 1}-sketch{laneId + 1}-left", f"SamplerSynth:channel_{channelId + 1}-sketch{laneId + 1}-right"]
                        loopSample = channel.clips[laneId].getClip(zynthian_gui_config.zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
                        if loopSample and loopSample.audioSource is not None:
                            # Connect sampler ports if there's a loop in the given slot
                            if (sketchLaneHasInput[channelInputLanes[laneId]] == False): sketchLaneHasInput[channelInputLanes[laneId]] = True
                            # logging.info(f"Connecting {samplerOutputPorts} to {sketchLaneInputs}")
                            for port in zip(samplerOutputPorts, sketchLaneInputs):
                                # Make sure this is the only connection we've got
                                for connectedTo in zbjack.getAllConnections(get_jack_port_name(port[0])):
                                    if connectedTo.endswith("-sidechainInputLeft") or connectedTo.endswith("-sidechainInputRight"):
                                        # Don't disconnect the sidechain ports, though...
                                        pass
                                    else:
                                        zbjack.disconnectPorts(get_jack_port_name(port[0]), connectedTo)
                                # logging.info(f"Connecting {port[0]} to {port[1]}")
                                zbjack.connectPorts(get_jack_port_name(port[0]), get_jack_port_name(port[1]))
                        # END Handle sketch slots
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
                            synthEntryExists[chainedSound] = True
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
                                            elif inputSource.port.startswith("usb-gadget:"):
                                                # hook up to the usb gadget input
                                                if inputSource.endswith(":left"):
                                                    capture_ports.append(usbGadgetInputs[0]);
                                                elif inputSource.endswith(":right"):
                                                    capture_ports.append(usbGadgetInputs[1]);
                                                else:
                                                    capture_ports = usbGadgetInputs
                                            elif inputSource.port.startswith("internal-master:"):
                                                # hook up to listen to the master output
                                                if inputSource.endswith(":left") or inputSource.endswith(":both"):
                                                    capture_ports.append("GlobalPlayback:dryOutLeft");
                                                if inputSource.endswith(":right") or inputSource.endswith(":both"):
                                                    capture_ports.append("GlobalPlayback:dryOutRight");
                                            elif inputSource.port.startswith("synthSlot:") or inputSource.port.startswith("sampleSlot:") or inputSource.port.startswith("fxSlot:"):
                                                # hook up to listen to the output of that specific graph port
                                                splitData = inputSource.split(":")
                                                portRootName = ""
                                                theLane = splitData[2][-1] + 1
                                                theTrack = 1
                                                if splitData[0] == "same":
                                                    theTrack = channelId + 1
                                                else:
                                                    theTrack = splitData[1] + 1
                                                if inputSource.port.startswith("synthSlot:"):
                                                    portRootName = f"TrackPassthrough:Channel{theTrack}-lane{theLane}"
                                                elif inputSource.port.startswith("sampleSlot:"):
                                                    portRootName = f"SamplerSynth:channel_{theTrack}-sample{theLane}"
                                                else:
                                                    portRootName = f"FXPassthrough-lane{theLane}:Channel{theTrack}"
                                                if inputSource.port.startswith("sampleSlot:"):
                                                    # sample slot outputs are named differently to the passthrough outputs, and don't have dry/wet prefixes
                                                    if splitData[3] == "left" or splitData[3] == "both":
                                                        capture_ports.append(f"{portRootName}-left")
                                                    if splitData[3] == "right" or splitData[3] == "both":
                                                        capture_ports.append(f"{portRootName}-right")
                                                else:
                                                    if splitData[2].startswith("dry"):
                                                        dryOrWet = "dryOut"
                                                    elif splitData[2].starswith("wet"):
                                                        dryOrWet = "wetOutFx1"
                                                    if splitData[3] == "left" or splitData[3] == "both":
                                                        capture_ports.append(f"{portRootName}-{dryOrWet}Left")
                                                    if splitData[3] == "right" or splitData[3] == "both":
                                                        capture_ports.append(f"{portRootName}-{dryOrWet}Right")
                                        # First disconnect anything already hooked up
                                        for connectedTo in zbjack.getAllConnections(audioInPort.jackname):
                                            if connectedTo.endswith("-sidechainInputLeft") or connectedTo.endswith("-sidechainInputRight"):
                                                # Don't disconnect the sidechain ports, though...
                                                pass
                                            else:
                                                zbjack.disconnectPorts(audioInPort.jackname, connectedTo)
                                        # Then hook up what we've been asked to
                                        for capture_port in capture_ports:
                                            zbjack.connectPorts(get_jack_port_name(capture_port), audioInPort.jackname)
                                # END Synth Inputs
                                # BEGIN Synth Outputs
                                engineOutPorts = jclient.get_ports(layer.jackname, is_output=True, is_input=False, is_audio=True)
                                if len(engineOutPorts) == 0:
                                    # If engine has no ports, it is very likely that autoconnect is running earlier than expected and engine has not started yet
                                    # In that case, return and schedule autoconnect again
                                    logging.info(f"Failed to autoconnect fully. Postponing the auto connection until the next autoconnect run, at which point it should hopefully be fine. Engine has no ports : layer({layer}), engine({layer.engine.name}), engine_jackname({layer.jackname}), engine_out_ports({engineOutPorts})")
                                    # Unlock mutex and return early as autoconnect is being rescheduled to be called after 1000ms because of an exception
                                    # Logic below the return statement will be eventually evaluated when called again after the timeout
                                    force_next_autoconnect = True;
                                    zbjack.clear()
                                    release_lock()
                                    return
                                elif len(engineOutPorts) == 1:
                                    # If this engine is mono, make sure we hook the output to both of the synth passthrough's inputs
                                    engineOutPorts.append(engineOutPorts[0])
                                # If the engine is connected to system_playback, disconnect it from there, just to be on the safe side
                                engineIsConnectedToSystem = False
                                for audioOutputPort in layer.get_audio_out():
                                    if audioOutputPort.startswith("system"):
                                        engineIsConnectedToSystem = True
                                        break
                                if engineIsConnectedToSystem:
                                    for port in zip(engineOutPorts, playback_ports):
                                        # logging.info(f"Disconnecting {port[0]} from {port[1]} in favour of the channel's passthrough client")
                                        zbjack.disconnectPorts(get_jack_port_name(port[0]), get_jack_port_name(port[1]))
                                # Connect synth engine to synth passthrough ports
                                for port in zip(engineOutPorts, synthPassthroughInputPorts):
                                    # logging.info(f"Connecting {port[0]} to synth passthrough client {port[1]}")
                                    zbjack.connectPorts(get_jack_port_name(port[0]), get_jack_port_name(port[1]))

                                # Connect synth passthrough ports to channel passthrough ports
                                for port in zip(synthPassthroughOutputPorts, laneInputs):
                                    # logging.info(f"Connecting {port[0]} to channel passthrough client {port[1]}")
                                    zbjack.connectPorts(get_jack_port_name(port[0]), get_jack_port_name(port[1]))
                                # END Synth Outputs
                        # END Handle synth slots
                        # BEGIN Connect TrackPassthrough wet ports to GlobalPlayback and AudioLevels via Global FX
                        laneOutputsFx1 = [f"TrackPassthrough:Channel{channelId + 1}-lane{channelInputLanes[laneId] + 1}-wetOutFx1Left", f"TrackPassthrough:Channel{channelId + 1}-lane{channelInputLanes[laneId] + 1}-wetOutFx1Right"]
                        laneOutputsFx2 = [f"TrackPassthrough:Channel{channelId + 1}-lane{channelInputLanes[laneId] + 1}-wetOutFx2Left", f"TrackPassthrough:Channel{channelId + 1}-lane{channelInputLanes[laneId] + 1}-wetOutFx2Right"]
                        for port in zip(laneOutputsFx1, globalFx1InputPorts):
                            if laneHasInput[channelInputLanes[laneId]]:
                                zbjack.connectPorts(get_jack_port_name(port[0]), get_jack_port_name(port[1]))
                            else:
                                zbjack.disconnectPorts(get_jack_port_name(port[0]), get_jack_port_name(port[1]))
                        for port in zip(laneOutputsFx2, globalFx2InputPorts):
                            if laneHasInput[channelInputLanes[laneId]]:
                                zbjack.connectPorts(get_jack_port_name(port[0]), get_jack_port_name(port[1]))
                            else:
                                zbjack.disconnectPorts(get_jack_port_name(port[0]), get_jack_port_name(port[1]))
                        # END Connect TrackPassthrough wet ports to GlobalPlayback and AudioLevels via Global FX
                        # BEGIN Connect TrackPassthrough sketch wet ports to GlobalPlayback and AudioLevels via Global FX
                        sketchLaneOutputsFx1 = [f"TrackPassthrough:Channel{channelId + 1}-sketch{channelInputLanes[laneId] + 1}-wetOutFx1Left", f"TrackPassthrough:Channel{channelId + 1}-sketch{channelInputLanes[laneId] + 1}-wetOutFx1Right"]
                        sketchLaneOutputsFx2 = [f"TrackPassthrough:Channel{channelId + 1}-sketch{channelInputLanes[laneId] + 1}-wetOutFx2Left", f"TrackPassthrough:Channel{channelId + 1}-sketch{channelInputLanes[laneId] + 1}-wetOutFx2Right"]
                        for port in zip(sketchLaneOutputsFx1, globalFx1InputPorts):
                            if sketchLaneHasInput[channelInputLanes[laneId]]:
                                zbjack.connectPorts(get_jack_port_name(port[0]), get_jack_port_name(port[1]))
                            else:
                                zbjack.disconnectPorts(get_jack_port_name(port[0]), get_jack_port_name(port[1]))
                        for port in zip(sketchLaneOutputsFx2, globalFx2InputPorts):
                            if sketchLaneHasInput[channelInputLanes[laneId]]:
                                zbjack.connectPorts(get_jack_port_name(port[0]), get_jack_port_name(port[1]))
                            else:
                                zbjack.disconnectPorts(get_jack_port_name(port[0]), get_jack_port_name(port[1]))
                        # END Connect TrackPassthrough sketch wet ports to GlobalPlayback and AudioLevels via Global FX
                        ### BEGIN Ensure TrackPassthrough only has ports where there's audio to work on
                        # Only override to True, never override to False (as that is the default value and if a field has been set to True, it's because *something* needs it)
                        # logging.info(f"Lane and sketch lane has input for track {channelId} lane {laneId} with effective lane {channelInputLanes[laneId]}? {laneHasInput[channelInputLanes[laneId]]} and {sketchLaneHasInput[channelInputLanes[laneId]]}")
                        if laneHasInput[channelInputLanes[laneId]]:
                            trackPassthroughLanesEnabled[channelId][channelInputLanes[laneId]][0] = True
                        if sketchLaneHasInput[channelInputLanes[laneId]]:
                            trackPassthroughLanesEnabled[channelId][channelInputLanes[laneId]][1] = True
                        # Actual creation/destruction operation happens after handling the song data (so we can ensure we only do it once per run)
                        ### END Ensure TrackPassthrough only pas ports where there's audio to work on
                    ### BEGIN Connect TrackPassthrough to GlobalPlayback and AudioLevels via FX
                    # logging.debug(f"# Channel{channelId+1} effects port connections :")
                    # Create a list of lists of ports to be connected in order, dependent on routing style
                    #   - For serial ("standard"): Single entry per track, containing (TrackPassthrough-lane1, Fx1, Fx2, Fx3, Fx4, Fx5, AudioLevels)
                    #   - For one-to-one: An entry per clip, entries contain the track passthrough for the clip's lane, the FXPassthrough lane for the equivalent clip, and AudioLevels. For example: (TrackPassthrough-lane1, Fx1, AudioLevels), (TrackPassthrough-lane2, Fx2, AudioLevels), (TrackPassthrough-lane3, Fx3, AudioLevels)...
                    # Only add an fx entry to the list if the slot is occupied (an fx entry consists of more than two sets of clients: one for the fx passthrough, and one for the fx passthrough)
                    # Further, if there are any overrides set on that slot, use those instead:
                    #   - standard-routing:(left, right, both)
                    #   - no-input (explicitly refuse audio input)
                    #   - external:(left, right, both)
                    #   - internal-master:(left, right, both)
                    #   - sketchpadTrack:(trackindex):(dry0, dry1, dry2, dry3, dry4, ):(left,right,both)
                    #   - fxSlot:(trackindex):(dry0, wet0, dry1, wet1, dry2, wet2, dry3, wet3, dry4, wet4):(left,right,both)
                    # TODO Implement overrides
                    allFxPassthroughClients = Zynthbox.Plugin.instance().fxPassthroughClients()
                    allSketchFxPassthroughClients = Zynthbox.Plugin.instance().sketchFxPassthroughClients()
                    # logging.info(f"Lanes on track {channelId + 1} have input: {laneHasInput}")
                    for laneType in ["sound", "sketch"]:
                        process_list = []

                        if channel.trackRoutingStyle == "standard":
                            # The order should be the track's TrackPassthrough -> pairs of FXPassthrough + FX layers in order -> the track's Audio levels
                            # If there are FX in chain, then there will be 1 entry per FX, made up of the the passthrough client, and the fx client itself
                            # For the FX, you connect the source to both the FX client and its passthrough's input, and then also the FX client's outputs to the wet input on the passthrough.

                            fx_client_names = []
                            # Create a set of client names for each FX in channel
                            # The fx client name should be placed first, and then the fx client name
                            for index, fxlayer in enumerate(channel.chainedFx if laneType == "sound" else channel.chainedSketchFx):
                                # Ensure ports on the FX passthrough ports only exist when there's contents in their slots
                                fxSlotPassthroughClient = allFxPassthroughClients[channel.id][index] if laneType == "sound" else allSketchFxPassthroughClients[channel.id][index]
                                fxSlotPassthroughClient.setCreatePorts(fxlayer is not None)
                                if fxlayer is not None:
                                    fx_client_names.append([f"FXPassthrough-lane{index + 1}:Channel{channel.id + 1}-{laneType}-", fxlayer.get_jackname()])

                            # Create final client names list, with the client names as it should be connected in order, and also only perform the connection if we have any sound input
                            if laneHasInput[channelInputLanes[laneId]] if laneType == "sound" else sketchLaneHasInput[channelInputLanes[laneId]]:
                                trackPassthroughClient = f"TrackPassthrough:Channel{channelId + 1}-lane{channelInputLanes[laneId] + 1}-" if laneType == "sound" else f"TrackPassthrough:Channel{channelId + 1}-sketch{channelInputLanes[laneId] + 1}-"
                                if len(fx_client_names) > 0:
                                    lane_client_names = [trackPassthroughClient] + fx_client_names + [f"AudioLevels:Channel{channel.id + 1}-"]
                                else:
                                    lane_client_names = [trackPassthroughClient, f"AudioLevels:Channel{channel.id + 1}-"]
                                process_list.append(lane_client_names)
                        elif channel.trackRoutingStyle == "one-to-one":
                            for laneId in range(0, 5):
                                fxlayer = channel.chainedFx[laneId] if laneType == "sound" else channel.chainedSketchFx[laneId]
                                # Ensure ports on the FX passthrough ports only exist when there's contents in their slots
                                fxSlotPassthroughClient = allFxPassthroughClients[channel.id][laneId] if laneType == "sound" else allSketchFxPassthroughClients[channel.id][laneId]
                                fxSlotPassthroughClient.setCreatePorts(fxlayer is not None)
                                if laneHasInput[channelInputLanes[laneId]] if laneType == "sound" else sketchLaneHasInput[channelInputLanes[laneId]]:
                                    trackPassthroughClient = f"TrackPassthrough:Channel{channelId + 1}-lane{channelInputLanes[laneId] + 1}-" if laneType == "sound" else f"TrackPassthrough:Channel{channelId + 1}-sketch{channelInputLanes[laneId] + 1}-"
                                    if fxlayer is None:
                                        lane_client_names = [trackPassthroughClient, f"AudioLevels:Channel{channel.id + 1}-"]
                                    else:
                                        lane_client_names = [trackPassthroughClient, [f"FXPassthrough-lane{laneId + 1}:Channel{channel.id + 1}-{laneType}-", fxlayer.get_jackname()], f"AudioLevels:Channel{channel.id + 1}-"]
                                    process_list.append(lane_client_names)

                        # logging.info(f"# Output client names : {process_list}")

                        # Disconnect any existing connections to and from from the fx layers audio ports
                        for index, fxlayer in enumerate(channel.chainedFx if laneType == "sound" else channel.chainedSketchFx):
                            if fxlayer is not None:
                                fx_in_ports = jclient.get_ports(fxlayer.get_jackname(), is_audio=True)
                                for fx_in_port in fx_in_ports:
                                    for connectedTo in zbjack.getAllConnections(get_jack_port_name(fx_in_port)):
                                        zbjack.disconnectPorts(get_jack_port_name(fx_in_port), connectedTo)

                        for client_names in process_list:
                            previousClient = None
                            # logging.info(f"## Processing list {client_names}")
                            output_client_names_count = len(client_names)
                            for (index, currentClient) in enumerate(client_names):
                                # logging.info(f"## Processing client : {currentClient}")
                                # The list entries are going to be either client names (the TrackPassthrough and AudioLevels clients, always the first and last entries), or lists containing a passthrough client and an FX client (the FX clusters, between the TrackPassthrough and AudioLevels clients)
                                # When connecting a client, connect it to the output of the previous client in the list:
                                # - If previous is a list (that is, an FX entry), then use the dry output of first entry in that list as the output (as that will be the FX passthrough)
                                # - If previous is not a list, then simply use the dry output of that one entry (which will be a TrackPassthrough)
                                # - If the current is a list, then connect that dry output to the wet input on the first entry (the FX Passthrough), and also to the first two inputs on the client

                                if previousClient == None:
                                    # The first client, TrackPassthrough, doesn't have a previous and is already connected to what it needs to be connected to, so skip that
                                    pass
                                else:
                                    # If the previous client is an FX cluster, use the first client to pull the dry output from, otherwise just use the entry directly (which will happen only if it's the TrackPassthrough)
                                    previousClientName = previousClient[0] if type(previousClient) is list else previousClient
                                    dry_out_ports = [previousClientName + "dryOutLeft", previousClientName + "dryOutRight"]

                                    # If the client that is being processed is a a list, then it's an FX cluster, so we need to:
                                    # - connect the previous client's dryOutput to the wet input on the first entry in the list (the FX passthrough)
                                    # - connect the previous client's dryOutput to the two first inputs (or both to the singular input) on the second entry in the list (the fx client itself)
                                    # - connect the outputs of the second entry in the list (the fx client) to the wet inputs on the first entry in the list (the FX passthrough)
                                    # If the client that is being processed is not a list, then it's the AudioLevels client, and it only needs to have its inputs connected to the dry outputs of previousClientName
                                    current_in_ports = []
                                    if type(currentClient) is list:
                                        # First collect all our source signal (dry) input ports
                                        current_in_ports = current_in_ports + [currentClient[0] + "inputLeft"] + [currentClient[0] + "inputRight"]
                                        fxClientInputs = jclient.get_ports(currentClient[1], is_audio=True, is_input=True)
                                        if len(fxClientInputs) == 1:
                                            fxClientInputs = [fxClientInputs[0], fxClientInputs[0]]
                                        current_in_ports = current_in_ports + fxClientInputs
                                        # Then remember to connect the fx client's output(s) to the wet input on the passthrough client
                                        fxClientOutputs = jclient.get_ports(currentClient[1], is_audio=True, is_output=True)
                                        if len(fxClientOutputs) == 1:
                                            fxClientOutputs = [fxClientOutputs[0], fxClientOutputs[0]]
                                        passthroughDryInputs = [currentClient[0] + "wetInputLeft", currentClient[0] + "wetInputRight"]
                                        # logging.info(f"## Connecting fx client output ports {fxClientOutputs} to passthrough dry inputs {passthroughDryInputs}")
                                        for ports in zip(fxClientOutputs, passthroughDryInputs):
                                            zbjack.connectPorts(get_jack_port_name(ports[0]), get_jack_port_name(ports[1]))
                                    else:
                                        # Simply collect all the inputs (this will be an AudioLevels client, and it's got a stereo pair for this)
                                        current_in_ports = [currentClient + "left_in", currentClient + "right_in"]

                                    # Connect the input ports to their related output ports (backward listing to ensure zip loops the potentially smaller list correctly)
                                    # logging.info(f"## Connecting current in ports {current_in_ports} to dry out ports {dry_out_ports}")
                                    for ports in zip(current_in_ports, cycle(dry_out_ports)):
                                        zbjack.connectPorts(get_jack_port_name(ports[0]), get_jack_port_name(ports[1]))

                                # Make sure we update previous client before heading into the next loop
                                previousClient = currentClient
                    ### END Connect TrackPassthrough to AudioLevels via FX
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
                                                for connectedTo in zbjack.getAllConnections(get_jack_port_name(port)):
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
                                        theLane = splitData[2][-1] + 1
                                        if inputSource.port.startswith("sketchpadTrack:"):
                                            portRootName = f"FXPassthrough-lane{theLane}:Channel{splitData[1] + 1}-"
                                        else:
                                            portRootName = f"TrackPassthrough:Channel{splitData[1] + 1}-lane{theLane}-"
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
                                    for connectedTo in zbjack.getAllConnections(audioInPort.jackname):
                                        zbjack.disconnectPorts(audioInPort.jackname, connectedTo)
                                except: pass
                                # Then hook up what we've been asked to
                                for capture_port in capture_ports:
                                    zbjack.connectPorts(get_jack_port_name(capture_port), audioInPort.jackname)
                    ### END FX Engine Audio Routing Overrides
        else:
            logging.info("No song yet, clearly ungood - also how?")
        ### BEGIN Actually create/destroy the TrackPassthrough ports
        # logging.info(f"Handling track passthrough data: {trackPassthroughLanesEnabled}")
        for trackId in range(0, 10):
            for laneId in range(0, 5):
                for laneTypeId in range(0, 2):
                    trackPassthrough = Zynthbox.Plugin.instance().trackPassthroughClient(trackId, laneTypeId, laneId)
                    trackPassthrough.setCreatePorts(trackPassthroughLanesEnabled[trackId][laneId][laneTypeId])
        ### END Actually create/destroy the TrackPassthrough ports
        ### BEGIN Ensure we only have synth passthrough ports for synths which exist
        synthPassthroughClients = Zynthbox.Plugin.instance().synthPassthroughClients()
        for synthEntryIndex, synthPassthroughClient in enumerate(synthPassthroughClients):
            synthPassthroughClient.setCreatePorts(synthEntryExists[synthEntryIndex])
        ### END Ensure we only have synth passthrough ports for synths which exist
    except Exception as e:
        logging.info(f"Failed to autoconnect fully. Postponing the auto connection until the next autoconnect run, at which point it should hopefully be fine. Failed during core routing setup. Reported error: {e} with backtrace {traceback.format_exc()}")
        # Unlock mutex and return early as autoconnect is being rescheduled to be called after 1000ms because of an exception
        # Logic below the return statement will be eventually evaluated when called again after the timeout
        force_next_autoconnect = True
        zbjack.clear()
        release_lock()
        return
    ### END Connect channel sound sources (SamplerSynth and synths) to their relevant input lanes on TrackPassthrough and FXPassthrough

    ### BEGIN Connect Samplersynth uneffected ports to GlobalPlayback client
    for laneType in ["sample", "sketch"]:
        # Most of the time we can do these with known lists, but since these sometimes get created dynamically, we need to make sure they're there to avoid zbjack's wrath
        for port in zip(jclient.get_ports(f"SamplerSynth:global-{laneType}1-", is_audio=True, is_output=True), globalPlaybackInputPorts):
            zbjack.connectPorts(get_jack_port_name(port[0]), get_jack_port_name(port[1]))
    ### END Connect Samplersynth uneffected ports to GlobalPlayback client

    ### BEGIN Connect GlobalPlayback ports
    globalPlaybackDryOutputPorts = ["GlobalPlayback:dryOutLeft", "GlobalPlayback:dryOutRight"]
    for port in zip(globalPlaybackDryOutputPorts, playback_ports):
        zbjack.connectPorts(get_jack_port_name(port[0]), get_jack_port_name(port[1]))

    for port in zip(globalPlaybackDryOutputPorts, jclient.get_ports("AudioLevels:SystemPlayback-", is_input=True, is_audio=True)):
        zbjack.connectPorts(get_jack_port_name(port[0]), get_jack_port_name(port[1]))
    ### END Connect GlobalPlayback ports

    ### BEGIN Attach any AudioLevels track output with connections to its input to the GlobalPlayback input
    for trackIndex in range(0, Zynthbox.Plugin.instance().sketchpadTrackCount()):
        if len(zbjack.getAllConnections(f"AudioLevels:Channel{trackIndex + 1}-left_in")) > 0:
            zbjack.connectPorts(f"AudioLevels:Channel{trackIndex + 1}-left_out", f"GlobalPlayback:inputLeft")
            zbjack.connectPorts(f"AudioLevels:Channel{trackIndex + 1}-right_out", f"GlobalPlayback:inputRight")
        else:
            zbjack.disconnectPorts(f"AudioLevels:Channel{trackIndex + 1}-left_out", f"GlobalPlayback:inputLeft")
            zbjack.disconnectPorts(f"AudioLevels:Channel{trackIndex + 1}-right_out", f"GlobalPlayback:inputRight")
    ### END Attach any AudioLevels track output with connections to its input to the GlobalPlayback input

    ### BEGIN Handle USB Gadget audio routing
    # Connect everything connected to the individual AudioLevels track and system playback client to the equivalent usb-gadget outputs (if that client exists)
    # For the first set, we should have precisely 2 playback ports
    usbGadgetOutputs = jclient.get_ports("usb-gadget-global:playback_")
    if len(usbGadgetOutputs) == 2:
        for port in zbjack.getAllConnections("AudioLevels:SystemPlayback-left_in"):
            zbjack.connectPorts(get_jack_port_name(port), get_jack_port_name(usbGadgetOutputs[0]))
        for port in zbjack.getAllConnections("AudioLevels:SystemPlayback-right_in"):
            zbjack.connectPorts(get_jack_port_name(port), get_jack_port_name(usbGadgetOutputs[1]))
    # We should have exactly 20 playback ports here, 2 for each track
    usbGadgetOutputs = jclient.get_ports("usb-gadget-tracks:playback_")
    if len(usbGadgetOutputs) == 20:
        # The first pair will be system playback (for the poor sods who end up unable to listen to more than the stereo input, we want it to be at least useful)
        # The remaining pairs will be for the individual tracks
        for channelId in range(0, 10):
            for port in zbjack.getAllConnections(f"AudioLevels:Channel{channelId + 1}-left_in"):
                zbjack.connectPorts(get_jack_port_name(port), get_jack_port_name(usbGadgetOutputs[(2 * channelId)]))
            for port in zbjack.getAllConnections(f"AudioLevels:Channel{channelId + 1}-right_in"):
                zbjack.connectPorts(get_jack_port_name(port), get_jack_port_name(usbGadgetOutputs[(2 * channelId) + 1]))
    ### END Handle USB Gadget audio routing

    headphones_out = jclient.get_ports("Headphones", is_input=True, is_audio=True)

    if len(headphones_out)==2 or not zynthian_gui_config.show_cpu_status:
        sysout_conports_1 = zbjack.getAllConnections("system:playback_1")
        sysout_conports_2 = zbjack.getAllConnections("system:playback_2")

        #Setup headphones connections if enabled ...
        if len(headphones_out)==2:
            #Prepare for setup headphones connections
            headphones_conports_1 = zbjack.getAllConnections("Headphones:playback_1")
            headphones_conports_2 = zbjack.getAllConnections("Headphones:playback_2")

            #Disconnect ports from headphones (those that are not connected to System Out, if any ...)
            for cp in headphones_conports_1:
                if cp not in sysout_conports_1:
                    zbjack.disconnectPorts(cp, get_jack_port_name(headphones_out[0]))
            for cp in headphones_conports_2:
                if cp not in sysout_conports_2:
                    zbjack.disconnectPorts(cp, get_jack_port_name(headphones_out[1]))

            #Connect ports to headphones (those currently connected to System Out)
            for cp in sysout_conports_1:
                zbjack.connectPorts(cp, get_jack_port_name(headphones_out[0]))
            for cp in sysout_conports_2:
                zbjack.connectPorts(cp, get_jack_port_name(headphones_out[1]))

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
        #                             zbjack.connectPorts(get_jack_port_name(scp), get_jack_port_name(rlp_inp))
        #                         else:
        #                             zbjack.disconnectPorts(get_jack_port_name(scp), get_jack_port_name(rlp_inp))
        #                         # Limit to 2 input ports
        #                         #if k>=1:
        #                         #    break
        #
        #                 else:
        #                     for rlp_inp in rlp_in:
        #                         zbjack.disconnectPorts(get_jack_port_name(scp), get_jack_port_name(rlp_inp))

        if zynthian_gui_config.midi_aubionotes_enabled:
            #Get Aubio Input ports ...
            aubio_in = jclient.get_ports("aubio", is_input=True, is_audio=True)
            if len(aubio_in)>0:
                nip = max(len(aubio_in), 2)
                #Connect System Capture to Aubio ports
                j=0
                for scp in capture_ports:
                    zbjack.connectPorts(get_jack_port_name(scp), get_jack_port_name(aubio_in[j%nip]))
                    j += 1

    #Finally, commit all changes
    success = zbjack.commit()

    #Release Mutex Lock
    release_lock()

    # Now we're done, test to see whether we've got any callbacks that need running
    runCallbacksAfterAudioAutoconnect()

    if success:
        # Autoconnect ran fine. Reset force flag
        force_next_autoconnect = False
    else:
        force_next_autoconnect = True


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
