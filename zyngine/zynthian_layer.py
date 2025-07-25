# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian Layer (zynthian_layer)
# 
# zynthian layer
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

import logging
import copy
from time import sleep
import collections
from collections import OrderedDict

# Zynthian specific modules
from zyncoder import *
from PySide2.QtCore import QObject, Signal, Property

class zynthian_layer(QObject):

    # ---------------------------------------------------------------------------
    # Initialization
    # ---------------------------------------------------------------------------


    def __init__(self, engine, midi_chan, zynqtgui=None, track_index=-1, slot_type="", slot_index=-1):
        super(zynthian_layer, self).__init__(zynqtgui)
        self.zynqtgui = zynqtgui
        self.engine = engine
        self.midi_chan = midi_chan
        self.track_index = track_index
        self.slot_type = slot_type
        self.slot_index = slot_index

        self.jackname = None
        self.audio_out = ["system:playback_1", "system:playback_2"]
        self.audio_in = ["system:capture_1", "system:capture_2"]
        self.midi_out = ["MIDI-OUT", "NET-OUT"]

        self.bank_list = []
        self.bank_index = 0
        self.bank_name = None
        self.bank_info = None

        self.show_fav_presets = False
        self.preset_list = []
        self.preset_index = 0
        self.preset_name = None
        self.preset_info = None
        self.preset_bank_index = None

        self.bank_list_cache = []
        # Preset list is cached per bank name
        self.preset_list_cache = {}

        self.preload_index = None
        self.preload_name = None
        self.preload_info = None

        self.controllers_dict = None
        self.ctrl_screens_dict = None
        self.active_screen_index = -1

        self.listen_midi_cc = True
        self.refresh_flag = False

        self.reset_zs3()

        # Some engines (for example LinuxSampler) in some rare cases fails to add a layer.
        # Hence try to handle those rare cases and try again before giving up
        restart_count = 0
        layer_added = False
        while not layer_added:
            try:
                self.engine.add_layer(self)
                layer_added = True
            except Exception as e:
                restart_count += 1
                logging.error(f"Can't add layer to engine {self.engine.name} : {e}")
                logging.debug(f"Engine {self.engine.name} Add Layer Restart Count : {restart_count}")
                if restart_count >= 5:
                    # Retried 5 times but failed. Force restart the entire application
                    self.zynqtgui.exit(102)

        self.engineChanged.connect(self.soundInfoChanged.emit)
        self.bankChanged.connect(self.soundInfoChanged.emit)
        self.bankCountChanged.connect(self.soundInfoChanged.emit)
        self.presetChanged.connect(self.soundInfoChanged.emit)
        self.presetCountChanged.connect(self.soundInfoChanged.emit)

        self.refresh_controllers()


    def refresh(self):
        if self.refresh_flag:
            self.refresh_flag=False
            self.refresh_controllers()

            #TODO: Improve this Dirty Hack!!
            #if self.engine.nickname=='MD':
                #self.zynqtgui.screens['preset'].fill_list()
                #if self.zynqtgui.active_screen=='bank':
                    #if self.preset_name:
                        #self.zynqtgui.show_screen('control')
                    #else:
                        #self.zynqtgui.show_screen('preset')

            self.zynqtgui.refresh_screen()


    def reset(self):
        # MIDI-unlearn all controllers
        for k,zctrl in self.controllers_dict.items():
            zctrl.midi_unlearn()
        # Delete layer from engine
        self.engine.del_layer(self)
        # Clear refresh flag
        self.refresh_flag=False

    def set_engine(self, engine):
        self.reset()
        self.engine = engine
        self.engine.add_layer(self)
        self.refresh_controllers()
        self.engineChanged.emit()

    def get_engine_name(self):
        if self.engine is not None:
            return self.engine.name
        else:
            return ""

    engineChanged = Signal()
    engineName = Property(str, get_engine_name, notify=engineChanged)

    def get_soundInfo(self):
        result = {
            "synth": "--",
            "bank": "--",
            "preset": "--"
        }

        try:
            result["synth"] = f"{self.engineName}"
        except: pass

        try:
            if self.bankCount > 0:
                result["bank"] = f"({self.bankIndex + 1}/{self.bankCount}) {'--' if len(self.bankName) == 0 else self.bankName}"
        except: pass

        try:
            if self.presetCount > 0:
                result["preset"] = f"({self.presetIndex + 1}/{self.presetCount}) {'--' if len(self.presetName) == 0 else self.presetName}"
        except: pass

        return result

    soundInfoChanged = Signal()

    """
    soundInfo property will contain an object as follows :
    {
        "synth": "<synth details string>",
        "bank": "<bank details string>",
        "preset": "<preset details string>"
    }
    This is meant to display the layer details
    """
    soundInfo = Property("QVariant", get_soundInfo, notify=soundInfoChanged)

    # ---------------------------------------------------------------------------
    # MIDI chan Management
    # ---------------------------------------------------------------------------


    def set_midi_chan(self, midi_chan):
        self.midi_chan=midi_chan
        self.engine.set_midi_chan(self)
        for zctrl in self.controllers_dict.values():
            zctrl.set_midi_chan(midi_chan)


    def get_midi_chan(self):
        return self.midi_chan


    # ---------------------------------------------------------------------------
    # Bank Management
    # ---------------------------------------------------------------------------


    def load_bank_list(self, force=False):
        caching_failed = False

        if self.engine.nickname == "BF":
            # Disable caching for setBfree engine
            caching_failed = True
        else:
            try:
                # Calling self.engine.get_bank_list() causes quite some file reads.
                # Too much file IO causes jackd thread to be not scheduled which causes XRUNS which in turn causes glitchiness during playback
                # Instead of reading files every run, cache the list data.
                # Since bank data of a synth should not change while the application is running, it should be fairly safe to cache the data
                if len(self.bank_list_cache) == 0 or force:
                    self.bank_list_cache = self.engine.get_bank_list(self)

                # Disable FAVS entry in bank list. Favorites are now toggled via a button on qml side
                # if len(self.engine.get_preset_favs(self)) > 0:
                #     self.bank_list = [["*FAVS*",0,"Favorites (%d)" % len(self.engine.get_preset_favs(self))]] + self.bank_list_cache.copy()
                # else:
                #     self.bank_list = self.bank_list_cache.copy()

                # Explicitly call get_preset_favs to generate preset fav list. Otherwise *BOOM*
                self.engine.get_preset_favs(self)
                self.bank_list = self.bank_list_cache.copy()
                self.bankCountChanged.emit()
                # logging.debug("BANK LIST => \n%s" % str(self.bank_list))
            except Exception as e:
                logging.exception(f"Error generating bank list from cache. Forcing call to engine.get_bank_list : {str(e)}")
                caching_failed = True

        if caching_failed:
            # Explicitly call get_preset_favs to generate preset fav list. Otherwise *BOOM*
            self.engine.get_preset_favs(self)
            self.bank_list = self.engine.get_bank_list(self)
            self.bankCountChanged.emit()


    def reset_bank(self):
        self.bank_index=0
        self.bank_name=None
        self.bank_info=None
        self.bankChanged.emit()


    def reset_bank_cache(self):
        self.bank_list_cache = []


    def set_bank(self, i, set_engine=True):
        returnVal = False
        if i < len(self.bank_list):
            last_bank_index=self.bank_index
            last_bank_name=self.bank_name
            self.bank_index=i
            self.bank_name=self.bank_list[i][2]
            self.bank_info=copy.deepcopy(self.bank_list[i])
            logging.info("Bank Selected: %s (%d)" % (self.bank_name,i))
            if set_engine and (last_bank_index!=i or not last_bank_name):
                self.reset_preset()
                returnVal = self.engine.set_bank(self, self.bank_info)
                if returnVal:
                    # TODO : Make sure to not call fill_list when preset is not in view
                    self.zynqtgui.preset.fill_list()
            else:
                returnVal = True
            self.bankChanged.emit()
        return returnVal


    #TODO Optimize search!!
    def set_bank_by_name(self, bank_name, set_engine=True):
        for i in range(len(self.bank_list)):
            if bank_name==self.bank_list[i][2]:
                return self.set_bank(i,set_engine)
        return False


    #TODO Optimize search!!
    def set_bank_by_id(self, bank_id, set_engine=True):
        for i in range(len(self.bank_list)):
            if bank_id==self.bank_list[i][0]:
                return self.set_bank(i,set_engine)
        return False


    # FIXME
    def get_bank_name(self):
        return self.bank_name

    def get_bank_index(self):
        return self.bank_index

    def get_bank_count(self):
        return len(self.bank_list)

    bankChanged = Signal()
    bankCountChanged = Signal()
    bankName = Property(str, get_bank_name, notify=bankChanged)
    bankIndex = Property(int, get_bank_index, notify=bankChanged)
    bankCount = Property(int, get_bank_count, notify=bankCountChanged)

    # ---------------------------------------------------------------------------
    # Presest Management
    # ---------------------------------------------------------------------------


    def load_preset_list(self, force=False):
        preset_list = []

        if self.show_fav_presets:
            for v in self.get_preset_favs().values():
                preset_list.append(v[1])

        elif self.bank_info:
            caching_failed = False

            if self.engine.nickname == "BF":
                # Disable caching for setBfree engine
                caching_failed = True
            else:
                try:
                    bank_name = self.bank_info[2]

                    # Calling self.engine.get_preset_list() causes quite some file reads.
                    # Too much file IO causes jackd thread to be not scheduled which causes XRUNS which in turn causes glitchiness during playback
                    # Instead of reading files every run, cache the list data.
                    # Since preset data of a synth should not change while the application is running, it should be fairly safe to cache the data
                    if bank_name not in self.preset_list_cache or force:
                        self.preset_list_cache[bank_name] = self.engine.get_preset_list(self.bank_info)
                    preset_list = preset_list + self.preset_list_cache[bank_name].copy()
                except Exception as e:
                    logging.exception(f"Error generating preset list from cache. Forcing call to engine.get_preset_list : {str(e)}")
                    caching_failed = True

            if caching_failed:
                preset_list = preset_list + self.engine.get_preset_list(self.bank_info)
        else:
            return

        self.preset_list = sorted(preset_list, key=lambda e: e[2].casefold())
        self.presetCountChanged.emit()
        # logging.debug("PRESET LIST => \n%s" % str(self.preset_list))


    def reset_preset(self):
        logging.debug("PRESET RESET!")
        self.preset_index=0
        self.preset_name=None
        self.preset_info=None
        self.presetChanged.emit()


    def reset_preset_cache(self):
        self.preset_list_cache = {}


    def set_preset(self, i, set_engine=True, force_immediate=False):
        if i < len(self.preset_list):
            last_preset_index=self.preset_index
            last_preset_name=self.preset_name
            
            preset_id = str(self.preset_list[i][0])
            preset_name = self.preset_list[i][2]

            if preset_id in self.engine.preset_favs:
                bank_name = self.engine.preset_favs[preset_id][0][2]
                if bank_name!=self.bank_name:
                    self.set_bank_by_name(bank_name)

            self.preset_index=i
            self.preset_name=preset_name
            self.preset_info=copy.deepcopy(self.preset_list[i])
            self.preset_bank_index=self.bank_index

            logging.info("Preset Selected: %s (%d)" % (self.preset_name,i))
            #=> '+self.preset_list[i][3]

            if self.preload_info:
                if not self.engine.cmp_presets(self.preload_info,self.preset_info):
                    set_engine_needed = True
                    self.preload_index = None
                    self.preload_name = None
                    self.preload_info = None
                else:
                    set_engine_needed = False

            elif last_preset_index!=i or not last_preset_name:
                set_engine_needed = True

            else:
                set_engine_needed = False

            if set_engine and set_engine_needed:
                #TODO => Review this!!
                #self.load_ctrl_config()
                return self.engine.set_preset(self, self.preset_info,force_immediate=force_immediate)

            self.presetChanged.emit()
            return True
        return False


    #TODO Optimize search!!
    def set_preset_by_name(self, preset_name, set_engine=True, force_immediate=False):
        for i in range(len(self.preset_list)):
            name_i=self.preset_list[i][2]
            try:
                if name_i[0]=='*':
                    name_i=name_i[1:]
                if preset_name==name_i:
                    return self.set_preset(i,set_engine,force_immediate)
            except:
                pass

        return False


    #TODO Optimize search!!
    def set_preset_by_id(self, preset_id, set_engine=True, force_immediate=False):
        for i in range(len(self.preset_list)):
            if preset_id==self.preset_list[i][0]:
                return self.set_preset(i,set_engine,force_immediate)
        return False


    def preload_preset(self, i):
        if i < len(self.preset_list):
            if (not self.preload_info and not self.engine.cmp_presets(self.preset_list[i], self.preset_info)) or (self.preload_info and not self.engine.cmp_presets(self.preset_list[i], self.preload_info)):
                self.preload_index = i
                self.preload_name = self.preset_list[i][2]
                self.preload_info = copy.deepcopy(self.preset_list[i])
                logging.info("Preset Preloaded: %s (%d)" % (self.preload_name,i))
                self.engine.set_preset(self,self.preload_info,True,force_immediate=True)
                return True
        return False


    def restore_preset(self):
        if self.preset_name is not None and self.preload_info is not None and not self.engine.cmp_presets(self.preload_info,self.preset_info):
            if self.preset_bank_index is not None and self.bank_index!=self.preset_bank_index:
                self.set_bank(self.preset_bank_index,False)
            self.preload_index=None
            self.preload_name=None
            self.preload_info=None
            logging.info("Restore Preset: %s (%d)" % (self.preset_name,self.preset_index))
            self.engine.set_preset(self,self.preset_info,force_immediate=True)
            return True
        return False


    def get_preset_name(self):
        return self.preset_name


    def get_preset_index(self):
        return self.preset_index


    def toggle_preset_fav(self, preset):
        self.engine.toggle_preset_fav(self, preset)


    def get_preset_favs(self):
        return self.engine.get_preset_favs(self)


    def set_show_fav_presets(self, flag=True):
        if flag:
            self.show_fav_presets = True
            self.reset_preset()
        else:
            self.show_fav_presets = False

    def get_preset_count(self):
        return len(self.preset_list)

    presetCountChanged = Signal()
    presetChanged = Signal()
    presetName = Property(str, get_preset_name, notify=presetChanged)
    presetIndex = Property(int, get_preset_index, notify=presetChanged)
    presetCount = Property(int, get_preset_count, notify=presetCountChanged)

    # ---------------------------------------------------------------------------
    # Controllers Management
    # ---------------------------------------------------------------------------


    def refresh_controllers(self):
        self.init_controllers()
        self.init_ctrl_screens()


    def init_controllers(self):
        self.controllers_dict=self.engine.get_controllers_dict(self)


    # Create controller screens from zynthian controller keys
    def init_ctrl_screens(self):
        #Build control screens ...
        self.ctrl_screens_dict=OrderedDict()
        for cscr in self.engine._ctrl_screens:
            self.ctrl_screens_dict[cscr[0]]=self.build_ctrl_screen(cscr[1])
            
        #Set active the first screen
        if len(self.ctrl_screens_dict)>0:
            self.active_screen_index=0
        else:
            self.active_screen_index=-1


    def get_ctrl_screens(self):
        return self.ctrl_screens_dict


    def get_ctrl_screen(self, key):
        try:
            return self.ctrl_screens_dict[key]
        except:
            return None


    def get_active_screen_index(self):
        return self.active_screen_index


    def set_active_screen_index(self, i):
        self.active_screen_index = i


    # Build array of zynthian_controllers from list of keys
    def build_ctrl_screen(self, ctrl_keys):
        zctrls=[]
        for i, k in enumerate(ctrl_keys):
            try:
                self.controllers_dict[k].index = i
                zctrls.append(self.controllers_dict[k])
            except:
                logging.error("Controller %s is not defined" % k)
        return zctrls


    def send_ctrl_midi_cc(self):
        for k, zctrl in self.controllers_dict.items():
            if zctrl.midi_cc:
                self.zynqtgui.zynmidi.set_midi_control(zctrl.midi_chan, zctrl.midi_cc, int(zctrl.value))
                logging.debug("Sending MIDI CC{}={} for {}".format(zctrl.midi_cc, zctrl.value, k))


    def midi_unlearn(self):
        for k, zctrl in self.controllers_dict.items():
            zctrl.midi_unlearn()


    #----------------------------------------------------------------------------
    # MIDI CC processing
    #----------------------------------------------------------------------------


    def midi_control_change(self, chan, ccnum, ccval):
        if self.engine:
            #logging.debug("Receving MIDI CH{}#CC{}={}".format(chan, ccnum, ccval))

            # Engine MIDI-Learn zctrls
            try:
                self.engine.midi_control_change(chan, ccnum, ccval)
            except:
                pass

            # MIDI-CC zctrls (also router MIDI-learn, aka CC-swaps)
            #TODO => Optimize!! Use the MIDI learning mechanism for caching this ...
            if self.listen_midi_cc:
                swap_info = zyncoder.lib_zyncoder.get_midi_filter_cc_swap(chan, ccnum)
                midi_chan = swap_info >> 8
                midi_cc = swap_info & 0xFF

                if self.zynqtgui.is_single_active_channel():
                    for k, zctrl in self.controllers_dict.items():
                        try:
                            if zctrl.midi_learn_cc and zctrl.midi_learn_cc>0:
                                if self.midi_chan==chan and zctrl.midi_learn_cc==ccnum:
                                    self.engine.midi_zctrl_change(zctrl, ccval)
                            else:
                                if self.midi_chan==midi_chan and zctrl.midi_cc==midi_cc:
                                    self.engine.midi_zctrl_change(zctrl, ccval)
                        except:
                            pass
                else:
                    for k, zctrl in self.controllers_dict.items():
                        try:
                            if zctrl.midi_learn_cc and zctrl.midi_learn_cc>0:
                                if zctrl.midi_learn_chan==chan and zctrl.midi_learn_cc==ccnum:
                                    self.engine.midi_zctrl_change(zctrl, ccval)
                            else:
                                if zctrl.midi_chan==midi_chan and zctrl.midi_cc==midi_cc:
                                    self.engine.midi_zctrl_change(zctrl, ccval)
                        except:
                            pass


    # ---------------------------------------------------------------------------
    # Snapshot Management
    # ---------------------------------------------------------------------------


    def get_snapshot(self):
        snapshot={
            'plugin_id': self.engine.version_info.plugin_info.id if self.engine.version_info is not None else None,
            'plugin_version': self.engine.version_info.version if self.engine.version_info is not None else None,
            'engine_name': self.engine.name,
            'engine_nick': self.engine.nickname,
            'engine_type': self.engine.type,
            'midi_chan': self.midi_chan,
            'track_index': self.track_index,
            'slot_type': self.slot_type,
            'slot_index': self.slot_index,
            'bank_index': self.bank_index,
            'bank_name': self.bank_name,
            'bank_info': self.bank_info,
            'preset_index': self.preset_index,
            'preset_name': self.preset_name,
            'preset_info': self.preset_info,
            'controllers_dict': {},
            'zs3_list': self.zs3_list,
            'active_screen_index': self.active_screen_index
        }
        for k in self.controllers_dict:
            snapshot['controllers_dict'][k] = self.controllers_dict[k].get_snapshot()
        return snapshot


    def restore_snapshot_1(self, snapshot):
        #Constructor, including engine and midi_chan info, is called before

        self.wait_stop_loading()

        #Load bank list and set bank
        try:
            self.bank_name=snapshot['bank_name']    #tweak for working with setbfree extended config!! => TODO improve it!!
            self.load_bank_list()
            self.bank_name=None
            self.set_bank_by_name(snapshot['bank_name'])

        except Exception as e:
            logging.warning("Invalid Bank on layer {}: {}".format(self.get_basepath(), e))

        self.wait_stop_loading()
    
        #Load preset list and set preset
        #try:
        self.load_preset_list()
        self.preset_loaded=self.set_preset_by_name(snapshot['preset_name'],force_immediate=True)

        #except Exception as e:
            #logging.warning("Invalid Preset on layer {}: {}".format(self.get_basepath(), e))

        self.wait_stop_loading()

        #Refresh controller config
        if self.refresh_flag:
            self.refresh_flag=False
            self.refresh_controllers()

        #Set zs3 list
        if 'zs3_list' in snapshot:
            self.zs3_list = snapshot['zs3_list']

        #Set active screen
        if 'active_screen_index' in snapshot:
            self.active_screen_index=snapshot['active_screen_index']


    def restore_snapshot_2(self, snapshot):

        # Wait a little bit if a preset has been loaded 
        if self.preset_loaded:
            sleep(0.2)

        self.wait_stop_loading()

        #Set controller values
        for k in snapshot['controllers_dict']:
            try:
                self.controllers_dict[k].restore_snapshot(snapshot['controllers_dict'][k])
            except Exception as e:
                logging.warning("Invalid Controller on layer {}: {}".format(self.get_basepath(), e))


    def wait_stop_loading(self):
        while self.engine.loading>0:
            logging.debug("WAITING FOR STOP LOADING ...")
            sleep(0.1)


    # ---------------------------------------------------------------------------
    # ZS3 Management (Zynthian SubSnapShots)
    # ---------------------------------------------------------------------------


    def reset_zs3(self):
        self.zs3_list = [None]*128


    def delete_zs3(self, i):
        self.zs3_list[i] = None


    def get_zs3(self, i):
        return self.zs3_list[i]


    def save_zs3(self, i):
        try:
            zs3 = {
                'bank_index': self.bank_index,
                'bank_name': self.bank_name,
                'bank_info': self.bank_info,
                'preset_index': self.preset_index,
                'preset_name': self.preset_name,
                'preset_info': self.preset_info,
                'active_screen_index': self.active_screen_index,
                'controllers_dict': {},
                'note_range': {}
            }

            for k in self.controllers_dict:
                logging.debug("Saving {}".format(k))
                zs3['controllers_dict'][k] = self.controllers_dict[k].get_snapshot()

            if self.midi_chan>=0 and self.midi_chan<16:
                zs3['note_range'] = {
                    'note_low': zyncoder.lib_zyncoder.get_midi_filter_note_low(self.midi_chan),
                    'note_high': zyncoder.lib_zyncoder.get_midi_filter_note_high(self.midi_chan),
                    'octave_trans': zyncoder.lib_zyncoder.get_midi_filter_octave_trans(self.midi_chan),
                    'halftone_trans': zyncoder.lib_zyncoder.get_midi_filter_halftone_trans(self.midi_chan)
                }

            self.zs3_list[i] = zs3

        except Exception as e:
            logging.error(e)


    def restore_zs3(self, i):
        zs3 = self.zs3_list[i]

        if zs3:
            # Set bank and load preset list if needed
            if zs3['bank_name'] and zs3['bank_name']!=self.bank_name:
                self.set_bank_by_name(zs3['bank_name'])
                self.load_preset_list()
                self.wait_stop_loading()

            # Set preset if needed
            if zs3['preset_name'] and zs3['preset_name']!=self.preset_name:
                self.set_preset_by_name(zs3['preset_name'],force_immediate=True)
                self.wait_stop_loading()

            # Refresh controller config
            if self.refresh_flag:
                self.refresh_flag=False
                self.refresh_controllers()
            
            # For non-LV2 engines, bank and preset can affect what controllers do.
            # In case of LV2, just restoring the controllers ought to be enough, which is nice
            # since it saves the 0.3 second delay between setting a preset and updating controllers.
            if not self.engine.nickname.startswith('JV'):
                sleep(0.3)

            # Set active screen
            if 'active_screen_index' in zs3:
                self.active_screen_index=zs3['active_screen_index']

            # Set controller values
            for k in zs3['controllers_dict']:
                self.controllers_dict[k].restore_snapshot(zs3['controllers_dict'][k])

            # Set Note Range
            if self.midi_chan>=0 and self.midi_chan<16 and 'note_range' in zs3:
                nr = zs3['note_range']
                zyncoder.lib_zyncoder.set_midi_filter_note_range(self.midi_chan, nr['note_low'], nr['note_high'], nr['octave_trans'], nr['halftone_trans'])

            return True

        else:
            return False


    # ---------------------------------------------------------------------------
    # Audio Output Routing:
    # ---------------------------------------------------------------------------


    def get_jackname(self):
        return self.jackname


    def get_audio_jackname(self):
        return self.jackname


    def get_audio_out(self):
        return self.audio_out


    def set_audio_out(self, ao):
        #Fix legacy routing (backward compatibility with old snapshots)
        if "system" in ao:
            ao.remove("system")
            ao += ["system:playback_1", "system:playback_2"]

        # pushing through a dictionary to both ensure order, and get rid of any duplicate entries
        self.audio_out=list(OrderedDict.fromkeys(ao))
        self.zynqtgui.zynautoconnect_audio()


    def add_audio_out(self, jackname):
        if isinstance(jackname, zynthian_layer):
            jackname=jackname.get_audio_jackname()

        if jackname not in self.audio_out:
            self.audio_out.append(jackname)
            logging.debug("Connecting Audio Output {} => {}".format(self.get_audio_jackname(), jackname))

        self.zynqtgui.zynautoconnect_audio()


    def del_audio_out(self, jackname):
        if isinstance(jackname, zynthian_layer):
            jackname=jackname.get_audio_jackname()

        try:
            self.audio_out.remove(jackname)
            logging.debug("Disconnecting Audio Output {} => {}".format(self.get_audio_jackname(), jackname))
        except:
            pass

        self.zynqtgui.zynautoconnect_audio()


    def toggle_audio_out(self, jackname):
        if isinstance(jackname, zynthian_layer):
            jackname=jackname.get_audio_jackname()

        if jackname not in self.audio_out:
            self.audio_out.append(jackname)
        else:
            self.audio_out.remove(jackname)

        self.zynqtgui.zynautoconnect_audio()


    def reset_audio_out(self):
        self.audio_out=["system:playback_1", "system:playback_2"]
        self.zynqtgui.zynautoconnect_audio()


    def mute_audio_out(self):
        self.audio_out=[]
        self.zynqtgui.zynautoconnect_audio()


    # ---------------------------------------------------------------------------
    # Audio Input Routing:
    # ---------------------------------------------------------------------------


    def get_audio_in(self):
        return self.audio_in


    def set_audio_in(self, ai):        
        self.audio_in=ai
        self.zynqtgui.zynautoconnect_audio()


    def add_audio_in(self, jackname):
        if jackname not in self.audio_in:
            self.audio_in.append(jackname)
            logging.debug("Connecting Audio Capture {} => {}".format(jackname, self.get_audio_jackname()))

        self.zynqtgui.zynautoconnect_audio()


    def del_audio_in(self, jackname):
        try:
            self.audio_in.remove(jackname)
            logging.debug("Disconnecting Audio Capture {} => {}".format(jackname, self.get_audio_jackname()))
        except:
            pass

        self.zynqtgui.zynautoconnect_audio()


    def toggle_audio_in(self, jackname):
        if jackname not in self.audio_in:
            self.audio_in.append(jackname)
        else:
            self.audio_in.remove(jackname)

        logging.debug("Toggling Audio Capture: {}".format(jackname))

        self.zynqtgui.zynautoconnect_audio()


    def reset_audio_in(self):
        self.audio_in=["system:capture_1", "system:capture_2"]
        self.zynqtgui.zynautoconnect_audio()


    def mute_audio_in(self):
        self.audio_in=[]
        self.zynqtgui.zynautoconnect_audio()


    def is_parallel_audio_routed(self, layer):
        if isinstance(layer, zynthian_layer) and layer!=self and layer.midi_chan==self.midi_chan and collections.Counter(layer.audio_out)==collections.Counter(self.audio_out):
            return True
        else:
            return False

    # ---------------------------------------------------------------------------
    # MIDI Routing:
    # ---------------------------------------------------------------------------

    def get_midi_jackname(self):
        return self.engine.jackname


    def get_midi_out(self):
        return self.midi_out


    def set_midi_out(self, mo):
        self.midi_out=mo
        #logging.debug("Setting MIDI connections:")
        #for jn in mo:
        #    logging.debug("  {} => {}".format(self.engine.jackname, jn))
        self.zynqtgui.zynautoconnect_midi()


    def add_midi_out(self, jackname):
        if isinstance(jackname, zynthian_layer):
            jackname=jackname.get_midi_jackname()

        if jackname not in self.midi_out:
            self.midi_out.append(jackname)
            logging.debug("Connecting MIDI {} => {}".format(self.get_midi_jackname(), jackname))

        self.zynqtgui.zynautoconnect_midi()


    def del_midi_out(self, jackname):
        if isinstance(jackname, zynthian_layer):
            jackname=jackname.get_midi_jackname()

        try:
            self.midi_out.remove(jackname)
            logging.debug("Disconnecting MIDI {} => {}".format(self.get_midi_jackname(), jackname))
        except:
            pass

        self.zynqtgui.zynautoconnect_midi()


    def toggle_midi_out(self, jackname):
        if isinstance(jackname, zynthian_layer):
            jackname=jackname.get_midi_jackname()

        if jackname not in self.midi_out:
            self.midi_out.append(jackname)
        else:
            self.midi_out.remove(jackname)

        self.zynqtgui.zynautoconnect_midi()


    def mute_midi_out(self):
        self.midi_out=[]
        self.zynqtgui.zynautoconnect_midi()


    def is_parallel_midi_routed(self, layer):
        if isinstance(layer, zynthian_layer) and layer!=self and layer.midi_chan==self.midi_chan and collections.Counter(layer.midi_out)==collections.Counter(self.midi_out):
            return True
        else:
            return False


    # ---------------------------------------------------------------------------
    # Channel "Path" String
    # ---------------------------------------------------------------------------


    def get_path(self):
        path = self.bank_name
        if self.preset_name:
            path = path + "/" + self.preset_name
        return path


    def get_basepath(self):
        path = self.engine.get_path(self)
        if self.midi_chan is not None:
            path = "{}#{}".format(self.midi_chan+1, path)
        return path


    def get_bankpath(self):
        path = self.get_basepath()
        if self.bank_name and self.bank_name!="None":
            path += " > " + self.bank_name
        return path


    def get_presetpath(self):
        path = self.get_basepath()

        subpath = None
        if self.bank_name and self.bank_name!="None":
            subpath = self.bank_name
            if self.preset_name:
                subpath += "/" + self.preset_name
        elif self.preset_name:
            subpath = self.preset_name

        if subpath:
            path += " > " + subpath

        return path


#******************************************************************************
