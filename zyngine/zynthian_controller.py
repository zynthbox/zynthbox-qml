# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian Controller (zynthian_controller)
# 
# zynthian controller
# 
# Copyright (C) 2015-2017 Fernando Moyano <jofemodo@zynthian.org>
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

import math
import liblo
import ctypes
import logging

from PySide2.QtCore import QObject, Signal, Slot, Property
# Zynthian specific modules
from zyncoder import *
import Zynthbox


class zynthian_controller(QObject):
    def __init__(self, engine, symbol, name=None, options=None, parent=None):
        super(zynthian_controller, self).__init__(parent)

        self.engine=engine
        self.symbol=symbol
        self.__name=symbol
        self.__short_name=symbol
        if name:
            self.__name=name
            self.__short_name=name

        self.group_symbol = None
        self.group_name = None
        self.value=0
        self.value_default=0
        self.value_min=0
        self.value_mid=64
        self.value_max=127
        self.value_range=127
        self.labels=None
        self.ticks=None
        self.is_toggle=False
        self.is_integer=True
        self.is_logarithmic=False
        self.index = -1

        self.midi_chan=None
        self.midi_cc=None
        self.osc_port=None
        self.osc_path=None
        self.graph_path=None

        self.midi_learn_chan=None
        self.midi_learn_cc=None

        self.label2value=None
        self.value2label=None

        self.hasValueLabel=False

        if options:
            self.set_options(options)


    def set_options(self, options):
        if 'symbol' in options:
            self.symbol=options['symbol']
        if 'name' in options:
            self.name=options['name']
        if 'short_name' in options:
            self.short_name=options['short_name']
        if 'group_name' in options:
            self.group_name=options['group_name']
        if 'group_symbol' in options:
            self.group_symbol=options['group_symbol']
        if 'value' in options:
            self.value=options['value']
        if 'value_default' in options:
            self.value_default=options['value_default']
        if 'value_min' in options:
            self.value_min=options['value_min']
        if 'value_max' in options:
            self.value_max=options['value_max']
        if 'labels' in options:
            self.labels=options['labels']
        if 'ticks' in options:
            self.ticks=options['ticks']
        if 'is_toggle' in options:
            self.is_toggle=options['is_toggle']
        if 'is_integer' in options:
            self.is_integer=options['is_integer']
        if 'is_logarithmic' in options:
            self.is_logarithmic=options['is_logarithmic']
        if 'midi_chan' in options:
            self.midi_chan=options['midi_chan']
        if 'midi_cc' in options:
            self.midi_cc=options['midi_cc']
        if 'osc_port' in options:
            self.osc_port=options['osc_port']
        if 'osc_path' in options:
            self.osc_path=options['osc_path']
        if 'graph_path' in options:
            self.graph_path=options['graph_path']
        self._configure()


    def _configure(self):
        #Configure Selector Controller
        if self.labels:

            if not self.ticks:
                #Generate ticks ...
                n = len(self.labels)
                self.ticks = []
                if self.is_integer:
                    for i in range(n):
                        self.ticks.append(self.value_min+int(i*(self.value_max+1)/n))
                else:
                    for i in range(n):
                        self.ticks.append(self.value_min+i*self.value_max/n)

            # If we have two labels, and they are on/off, then this is a toggle
            if len(self.labels) == 2:
                if self.labels[0].lower() in ["on","off"] and self.labels[1].lower() in ["on","off"]:
                    self.is_toggle = True

            #Calculate min, max
            if self.ticks[0]<=self.ticks[-1]:
                self.value_min = self.ticks[0]
                self.value_max = self.ticks[-1]
            else:
                self.value_min = self.ticks[-1]
                self.value_max = self.ticks[0]

            #Generate dictionary for fast conversion labels=>values
            self.label2value = {}
            self.value2label = {}
            for i in range(len(self.labels)):
                self.label2value[str(self.labels[i])] = self.ticks[i]
                self.value2label[str(self.ticks[i])] = self.labels[i]

        #Common configuration
        self.value_range = self.value_max-self.value_min

        if self.is_integer:
            self.value_mid = self.value_min+int(self.value_range/2)
        else:
            self.value_mid = self.value_min+self.value_range/2

        if self.is_logarithmic:
            self.powbase = self.value_max/self.value_min
            self.log_powbase = math.log(self.powbase)

        self._set_value(self.value)
        if self.value_default is None:
            self.value_default=self.value


    def setup_controller(self, chan, cc, val, maxval=127):
        self.midi_chan = chan

        # OSC Path / MIDI CC
        if isinstance(cc,str):
            self.osc_path = cc
        else:
            self.midi_cc = cc

        self.value_min = 0
        self.value_max = 127
        self.value = val
        self.is_toggle = False
        self.is_integer = True
        self.is_logarithmic = False

        # Numeric
        if isinstance(maxval,int):
            self.value_max = maxval
        # Selector
        elif isinstance(maxval,str):
            self.labels=maxval.split('|')
        elif isinstance(maxval,list):
            if isinstance(maxval[0],list):
                self.labels = maxval[0]
                self.ticks = maxval[1]
            else:
                self.labels = maxval

        self._configure()


    def getName(self):
        return self.__name
    def setName(self,name):
        if self.__name != name:
            self.__name = name
            self.nameChanged.emit()
    nameChanged = Signal()
    name = Property(str, getName, setName, notify=nameChanged)

    def getShortName(self):
        return self.__short_name
    def setShortName(self,short_name):
        if self.__short_name != short_name:
            self.__short_name = short_name
            self.shortNameChanged.emit()
    shortNameChanged = Signal()
    # Property name doesn't match the functions, mostly because the property's used in a bunch of places
    short_name = Property(str, getShortName, setShortName, notify=shortNameChanged)

    def get_path(self):
        if self.osc_path:
            return str(self.osc_path)
        elif self.graph_path:
            return str(self.graph_path)
        elif self.midi_chan is not None and self.midi_cc is not None:
            return "{}#{}".format(self_midi_chan,self.midi_cc)
        else:
            return None


    def set_midi_chan(self, chan):
        self.midi_chan = chan


    def get_ctrl_array(self):
        tit = self.__short_name
        if self.midi_chan:
            chan = self.midi_chan
        else:
            chan = 0
        if self.midi_cc:
            ctrl = self.midi_cc
        elif self.osc_path:
            ctrl = self.osc_path
        elif self.graph_path:
            ctrl = self.graph_path
        
        if self.labels:
            val = self.get_value2label()
            if self.ticks:
                minval = [self.labels, self.ticks]
                maxval = None
            else:
                minval = self.labels
                maxval = None
        else:
            val = self.value
            minval = self.value_min
            maxval = self.value_max
        return [tit,chan,ctrl,val,minval,maxval]


    def get_value(self):
        return self.value

    def get_valueLabel(self):
        if self.hasValueLabel == True and self.engine:
            return self.engine.get_controller_value_label(self)
        else:
            return self.value

    def _set_value(self, val):
        valueChanged = False
        if isinstance(val, str):
            newValue = self.get_label2value(val)
            if self.value != newValue:
                self.value = newValue
                valueChanged = True

        elif self.is_toggle:
            newValue = self.value
            if val==self.value_min or val==self.value_max:
                newValue = val
            else:
                if val<self.value_mid:
                    newValue = self.value_min
                else:
                    newValue = self.value_max

            if self.value != newValue:
                self.value = newValue
                valueChanged = True

        elif self.ticks:
            if val in self.ticks and self.value != val:
                self.value = val
                valueChanged = True

        else:
            newValue = val;
            if self.is_integer:
                newValue = int(val)

            if newValue>self.value_max:
                newValue=self.value_max
            elif newValue<self.value_min:
                newValue=self.value_min

            if self.value != newValue:
                self.value=newValue
                valueChanged = True

        if valueChanged:
            self.value_changed.emit(self)

    def set_value(self, val, force_sending=False, update_controllers=True):
        self._set_value(val)

        if self.engine:
            if self.midi_learn_cc or self.midi_cc:
                mval=self.get_ctrl_midi_val()

            try:
                # Send value using engine method...
                self.engine.send_controller_value(self)
            except:
                try:
                    # Send value using OSC/MIDI ...
                    if self.osc_path:
                        liblo.send(self.engine.osc_target,self.osc_path, self.get_ctrl_osc_val())
                        # logging.debug("Sending OSC controller '{}' value => {}".format(self.symbol, val))

                    elif self.midi_cc:
                        Zynthbox.MidiRouter.instance().sendMidiMessageToZynthianSynth(self.midi_chan, 3, 176, self.midi_cc, mval)
                        # logging.debug("Sending MIDI controller '{}' value => {} ({})".format(self.symbol, val, mval))

                except Exception as e:
                    logging.error("Can't send controller '{}' value: {} => {}".format(self.symbol, val, e))

            if update_controllers:
                # Send feedback to MIDI controllers
                # This needs to go to controllers only, so how do we do that... new function on midirouter for explicitly sending feedback to controllers maybe?
                try:
                    if self.midi_learn_cc:
                        Zynthbox.MidiRouter.instance().sendMidiMessageToControllers(3, 176 + self.midi_learn_chan, self.midi_learn_cc, mval)
                        # zyncoder.lib_zyncoder.ctrlfb_send_ccontrol_change(self.midi_learn_chan,self.midi_learn_cc,mval)
                        logging.error("Controller feedback '{}' (learn) => CH{}, CC{}, Val={}".format(self.symbol,self.midi_learn_chan,self.midi_learn_cc,mval))
                    elif self.midi_cc:
                        Zynthbox.MidiRouter.instance().sendMidiMessageToControllers(3, 176 + self.midi_chan, self.midi_cc, mval)
                        # zyncoder.lib_zyncoder.ctrlfb_send_ccontrol_change(self.midi_chan,self.midi_cc,mval)
                        #logging.debug("Controller feedback '{}' => CH{}, CC{}, Val={}".format(self.symbol,self.midi_chan,self.midi_cc,mval))

                except Exception as e:
                    logging.error("Can't send controller feedback '{}' => Val={}".format(self.symbol,e))


    def get_value2index(self, val=None):
        if val is None:
            val=self.value
        try:
            if self.ticks:
                if self.ticks[0]>self.ticks[-1]:
                    for i in reversed(range(len(self.labels))):
                        if val<=self.ticks[i]:
                            return i
                    return 0
                else:
                    for i in range(len(self.labels)-1):
                        #logging.debug("V2L testing range {} => {} in {}-{}".format(i,val,self.ticks[i],self.ticks[i+1]))
                        if val<self.ticks[i+1]:
                            return i
                    return i+1
            elif self.labels:
                i=min(int((val-self.value_min)*len(self.labels)/self.value_range), len(self.labels)-1)
                #logging.debug("V2L => {} has index {}".format(val,i))
                return i
            else:
                return None
        except Exception as e:
            logging.error(e)


    def get_value2label(self, val=None):
        i = self.get_value2index(val)
        if i is not None:
            return self.labels[i]
        else:
            return val


    def get_label2value(self, label):
        try:
            if self.ticks:
                return self.label2value[str(label)]
            elif self.labels:
                i=self.labels.index(label)
                if i>=0:
                    #logging.debug("L2V => {} has index {}".format(label,i))
                    if self.is_integer and self.value_range==127:
                        return self.value_min+i*128/len(self.labels)
                    else:
                        return self.value_min+i*self.value_range/len(self.labels)
            else:
                logging.error("No labels defined")

        except Exception as e:
            logging.error(e)


    def get_ctrl_midi_val(self):
        try:
            if self.is_logarithmic:
                val = int(127*math.log(self.value/self.value_min)/self.log_powbase)
            else:
                val = min(127, int(127*(self.value-self.value_min)/self.value_range))
        except Exception as e:
            logging.error(e)
            val=0

        return val


    def get_ctrl_osc_val(self):
        if self.labels and len(self.labels)==2:
            if self.value=='on': return True
            elif self.value=='off': return False
        return self.value


    #--------------------------------------------------------------------------
    # Snapshots
    #--------------------------------------------------------------------------


    def get_snapshot(self):
        snapshot = {}
        
        # Value
        if math.isnan(self.value):
            snapshot['value'] = None
        else:
            snapshot['value'] = self.value

        # MIDI learning info
        if self.midi_learn_chan is not None and self.midi_learn_cc is not None:
            snapshot['midi_learn_chan'] = self.midi_learn_chan
            snapshot['midi_learn_cc'] = self.midi_learn_cc
            # Specific ZynAddSubFX slot info
            try:
                snapshot['slot_i'] = self.slot_i
            except:
                pass

        return snapshot


    def restore_snapshot(self, snapshot):
        if isinstance(snapshot, dict):
            self.set_value(snapshot['value'], True)
            if 'midi_learn_chan' in snapshot and 'midi_learn_cc' in snapshot:
                # Specific ZynAddSubFX slot info
                if 'slot_i' in snapshot:
                    self.slot_i = snapshot['slot_i']
                # Restore MIDI-learn
                self.set_midi_learn(int(snapshot['midi_learn_chan']), int(snapshot['midi_learn_cc']))
        else:
            self.set_value(snapshot,True)
        self.refresh_gui()


    #--------------------------------------------------------------------------
    # MIDI Learning (Generic Methods)
    #--------------------------------------------------------------------------

    def getMidiLearnChannel(self):
        if self.midi_learn_chan is not None:
            return self.midi_learn_chan
        return -1;
    def setMidiLearnChannel(self,chan):
        if self.midi_learn_chan != chan:
            self.midi_learn_chan = chan
            self.midiLearnChannelChanged.emit()
    midiLearnChannelChanged = Signal()
    midiLearnChannel = Property(int,getMidiLearnChannel,setMidiLearnChannel,notify=midiLearnChannelChanged)

    def getMidiLearnCC(self):
        if self.midi_learn_cc is not None:
            return self.midi_learn_cc
        return -1
    def setMidiLearnCC(self,cc):
        if self.midi_learn_cc != cc:
            self.midi_learn_cc = cc
            self.midiLearnCCChanged.emit()
    midiLearnCCChanged = Signal()
    midiLearnCC = Property(int,getMidiLearnCC,setMidiLearnCC,notify=midiLearnCCChanged)

    @Slot(None)
    def init_midi_learn(self):
        # Learn only if there is a working engine ...
        if self.engine:
            logging.info("Init MIDI-learn: %s" % self.symbol)
            
            # If already learned, unlearn
            if self.midi_learn_cc:
                self.midi_unlearn()

            # If not a CC-mapped controller, delegate to engine's MIDI-learning implementation
            if not self.midi_cc:
                try:
                    self.engine.init_midi_learn(self)
                except Exception as e:
                    logging.error(e)

            # Call GUI method
            self.engine.zynqtgui.init_midi_learn(self)


    @Slot(None)
    def midi_unlearn(self):
        # Unlearn only if there is a working engine and something to unlearn ...
        if self.engine and self.midi_learn_chan is not None and self.midi_learn_cc is not None:
            logging.info("MIDI Unlearn: %s" % self.symbol)
            unlearned=False

            # If standard MIDI-CC controller, delete MIDI router map
            if self.midi_cc:
                unlearned = self.midi_unlearn_zyncoder()

            # Else delegate to engine's MIDI-learning implementation
            else:
                try:
                    unlearned = self.engine.midi_unlearn(self)
                except Exception as e:
                    logging.error(e)

            if unlearned:
                # Call GUI method
                self.engine.zynqtgui.refresh_midi_learn()
                # Return success
                return True
            else:
                return False

        # If not engine or nothing to unlearn, return success
        return True


    @Slot(int, int)
    def set_midi_learn(self, chan, cc):
        # Learn only if there is a working engine ...
        if self.engine:
            self.midi_unlearn()

            # If standard MIDI-CC controller, create zyncoder MIDI router map ...
            if self.midi_cc:
                return self.midi_learn_zyncoder(chan, cc)
            else:
                try:
                    return self.engine.set_midi_learn(self, chan, cc)
                except Exception as e:
                    logging.error(e)


    def _set_midi_learn(self, chan, cc):
        logging.info("MIDI-CC SET '{}' => {}, {}".format(self.symbol, chan, cc))
        
        self.setMidiLearnChannel(chan)
        self.setMidiLearnCC(cc)

        return True


    def _unset_midi_learn(self):
        logging.info("MIDI-CC UNSET '{}' => {}, {}".format(self.symbol, self.midi_learn_chan, self.midi_learn_cc))
        
        self.setMidiLearnChannel(None)
        self.setMidiLearnCC(None)

        return True


    def cb_midi_learn(self, chan, cc):
        # Learn only if there is a working engine ...
        if self.engine:
            learned=False

            # If standard MIDI-CC controller, create zyncoder MIDI router map ...
            if self.midi_cc:
                learned = self.midi_learn_zyncoder(chan, cc)
            else:
                try:
                    learned = self.engine.cb_midi_learn(self, chan, cc)
                except Exception as e:
                    return False

            if learned:
                # Call GUI method
                self.engine.zynqtgui.end_midi_learn()
                # Return success
                return True
            else:
                return False

        return True


    def _cb_midi_learn(self, chan, cc):
        if self._set_midi_learn(chan, cc):
            self.engine.zynqtgui.end_midi_learn()
            return True


    #--------------------------------------------------------------------------
    # MIDI Learning (Native Zyncoder CC-Map Implementation)
    #--------------------------------------------------------------------------


    def midi_learn_zyncoder(self, chan, cc):
        try:
            if zyncoder.lib_zyncoder.set_midi_filter_cc_swap(ctypes.c_ubyte(chan), ctypes.c_ubyte(cc), ctypes.c_ubyte(self.midi_chan), ctypes.c_ubyte(self.midi_cc)):
                logging.info("Set MIDI filter CC map: (%s, %s) => (%s, %s)" % (chan, cc, self.midi_chan, self.midi_cc))
                return self._set_midi_learn(chan, cc)
            else:
                logging.error("Can't set MIDI filter CC swap map: call returned 0")

        except Exception as e:
            logging.error("Can't set MIDI filter CC swap map: (%s, %s) => (%s, %s) => %s" % (self.midi_learn_chan, self.midi_learn_cc, self.midi_chan, self.midi_cc, e))


    def midi_unlearn_zyncoder(self):
        try:
            if zyncoder.lib_zyncoder.del_midi_filter_cc_swap(ctypes.c_ubyte(self.midi_learn_chan), ctypes.c_ubyte(self.midi_learn_cc)):
                logging.info("Deleted MIDI filter CC map: {}, {}".format(self.midi_learn_chan, self.midi_learn_cc))
                return self._unset_midi_learn()
            else:
                logging.error("Can't delete MIDI filter CC swap map: Call returned 0")

        except Exception as e:
            logging.error("Can't delete MIDI filter CC swap map: {}, {} => {}".format(self.midi_learn_chan, self.midi_learn_cc,e))


    #----------------------------------------------------------------------------
    # MIDI CC processing
    #----------------------------------------------------------------------------

    def midi_control_change(self, val):
        if self.is_logarithmic:
            value = self.value_min*pow(self.powbase, val/127)
        else:
            value = self.value_min+val*self.value_range/127
        self.set_value(value, update_controllers=False)
        self.refresh_gui()


    def refresh_gui(self):
        #Refresh GUI controller in screen when needed ...
        try:
            if (self.engine.zynqtgui.active_screen=='control' and not self.engine.zynqtgui.modal_screen) or self.engine.zynqtgui.modal_screen=='alsa_mixer':
                self.engine.zynqtgui.screens['control'].set_controller_value(self)
        except Exception as e:
            logging.debug(e)


    value_changed = Signal(QObject)

#******************************************************************************
