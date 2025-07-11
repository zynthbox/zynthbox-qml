# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian Engine (zynthian_engine)
# 
# zynthian_engine is the base class for the Zynthian Synth Engine
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

#import sys
import os
import json
import liblo
import logging
import shlex
import Zynthbox
import re
import random
import string
from os.path import isfile, isdir, join
from string import Template
from collections import OrderedDict
from PySide2.QtCore import Property, QObject, Signal, Slot

from . import zynthian_controller

#--------------------------------------------------------------------------------
# Basic Engine Class: Spawn a proccess & manage IPC communication using pexpect
#--------------------------------------------------------------------------------

class zynthian_basic_engine(QObject):

    # ---------------------------------------------------------------------------
    # Data dirs 
    # ---------------------------------------------------------------------------

    config_dir = os.environ.get('ZYNTHIAN_CONFIG_DIR',"/zynthian/config")
    data_dir = os.environ.get('ZYNTHIAN_DATA_DIR',"/zynthian/zynthian-data")
    my_data_dir = os.environ.get('ZYNTHIAN_MY_DATA_DIR',"/zynthian/zynthian-my-data")
    ex_data_dir = os.environ.get('ZYNTHIAN_EX_DATA_DIR',"/media/usb0")

    # ---------------------------------------------------------------------------
    # Initialization
    # ---------------------------------------------------------------------------

    def __init__(self, name=None, command=None, prompt=None, zynqtgui=None):
        super(zynthian_basic_engine, self).__init__(zynqtgui)
        self.zynqtgui = zynqtgui
        self.name = name
        self.proc = Zynthbox.ProcessWrapper(self)
        self.proc.setCommandPrompt(prompt)
        self.proc.stateChanged.connect(self.handleStateChanged)
        self.command = command
        self.command_env = os.environ.copy()
        self.command_prompt = prompt
        self.is_running = False
        # A flag to detect if process has crashed has been restarted in handleStateChanged
        self.has_restarted = False

    def __del__(self):
        # If this fails, it is likely that the engine was already stopped and the process object deleted, so let's just not worry too much
        try:
            self.stop()
        except: pass

    # ---------------------------------------------------------------------------
    # Subproccess Management & IPC
    # ---------------------------------------------------------------------------

    @Slot()
    def handleStateChanged(self):
        logging.debug(f"--- {self.name} state is now {self.proc.state()}")
        if self.proc.state() == Zynthbox.ProcessWrapper.ProcessState.RunningState:
            self.is_running = True
            if self.has_restarted:
                self.processRestartedAfterCrash.emit()
                self.has_restarted = False
        elif self.proc.state() == Zynthbox.ProcessWrapper.ProcessState.RestartingState:
            self.is_running = False
            self.has_restarted = True

    """
    Start the engine and return output if it is waiting for a prompt
    """
    def start(self):
        command = shlex.split(self.command)[0]
        command_args = shlex.split(self.command)[1:]
        output = ""
        if not self.proc.state() == Zynthbox.ProcessWrapper.ProcessState.RunningState:
            logging.info(f"Starting Engine {self.name}")
            logging.debug(f"Engine start command : {self.command}")
            startTransaction = self.proc.start(command, command_args, self.command_env)
            # logging.debug("Waiting for start command to complete...")
            if self.command_prompt:
                startTransaction.waitForState()
                output = startTransaction.standardOutput()
                # logging.debug(f"--- Engine Start Output BEGIN\n{output}\n--- Engine Start Output END")
            startTransaction.release()
        return output

    def stop(self):
        if self.proc.state() == Zynthbox.ProcessWrapper.ProcessState.RunningState:
            try:
                logging.info("Stoping Engine " + self.name)
                self.proc.stop()
            except Exception as err:
                logging.error("Can't stop engine {} => {}".format(self.name, err))

    # This will call a function on the process, and if wait_for_output is set also return
    # the output of that function (after waiting for it to complete). If wait_for_output
    # is False, it will return an empty string immediately, and just expect the call to do
    # what it's supposed to.
    # NOTE This function will also return an empty string when wait_for_output is set to True but the call fails for whatever reason
    def proc_cmd(self, cmd:str, wait_for_output=False):
        out = ""
        if self.proc is not None and self.proc.state() == Zynthbox.ProcessWrapper.ProcessState.RunningState:
            logging.debug(f"{self.name} proc command: {cmd} - blocking? {wait_for_output}")
            if wait_for_output:
                transaction = self.proc.call(cmd)
                if transaction is not None:
                    out = transaction.standardOutput()
                    transaction.release()
            else:
                transaction = self.proc.send(cmd)
                if transaction is not None:
                    transaction.release()
            logging.debug(f"{self.name} proc command output: {out}")
        return out

    # This will return the transaction rather than the transaction's output, which can
    # be used to manually ensure order-of-events (by testing the transaction IDs against
    # each other), for example for situations where you might require some output from a
    # function to always be the most recent (which, let's be honest, is likely to be the
    # common case).
    # NOTE Remember to release the returned transaction when it is no longer needed
    def proc_transact(self, cmd:str, wait_for_output=False):
        if wait_for_output:
            return self.proc.call(cmd)
        else:
            return self.proc.send(cmd)

    processRestartedAfterCrash = Signal()

#------------------------------------------------------------------------------
# Synth Engine Base Class
#------------------------------------------------------------------------------

class zynthian_engine(zynthian_basic_engine):

    # ---------------------------------------------------------------------------
    # Default Controllers & Screens
    # ---------------------------------------------------------------------------

    # Standard MIDI Controllers
    _ctrls=[
        ['volume',7,96],
        ['modulation',1,0],
        ['pan',10,64],
        ['sustain',64,'off',['off','on']]
    ]

    # Controller Screens
    _ctrl_screens=[
        ['main',['volume','modulation','pan','sustain']]
    ]

    # ---------------------------------------------------------------------------
    # Config variables
    # ---------------------------------------------------------------------------

    # ---------------------------------------------------------------------------
    # Initialization
    # ---------------------------------------------------------------------------

    def __init__(self, version_info, zynqtgui=None):
        super().__init__(zynqtgui=zynqtgui)

        self.version_info = version_info
        self.zynqtgui=zynqtgui
        self.type = "MIDI Synth"
        self.nickname = ""
        self.jackname = ""

        self.loading = 0
        self.layers = []

        self.options = {
            'clone': True,
            'note_range': True,
            'audio_route': True,
            'midi_chan': True,
            'drop_pc': False
        }

        self.osc_target = None
        self.osc_target_port = None
        self.osc_server = None
        self.osc_server_port = None
        self.osc_server_url = None

        self.preset_favs = None
        self.preset_favs_fpath = None

        self.learned_cc = [[None for c in range(128)] for chan in range(16)]
        self.learned_zctrls = {}

        self.__bypassController = None
        self.__volumeController = None


    def __del__(self):
        self.stop()


    def reset(self):
        #Reset Vars
        self.loading=0
        self.loading_snapshot=False
        #TODO: OSC, IPC, ...


    def config_remote_display(self):
        if 'ZYNTHIAN_X11_SSH' in os.environ and 'SSH_CLIENT' in os.environ and 'DISPLAY' in os.environ:
            return True
        elif os.system('systemctl -q is-active vncserver@\:1'):
            return False
        else:
            self.command_env['DISPLAY'] = ':1'
            return True


    def get_next_jackname(self, jname, sanitize=False):
        try:
            # Jack, when listing ports, accepts regular expressions as the jack name.
            # So, for avoiding problems, jack names shouldn't contain regex characters.
            if sanitize:
                jname = re.sub("[\_]{2,}","_",re.sub("[\'\*\(\)\[\]\s]","_",jname))
            jname_count = self.zynqtgui.screens['layer'].get_jackname_count(jname)
        except:
            jname_count = 0

        # Append a 4 letter random id to jackname to prevent name clashes
        return "{}-{:02d}-{}".format(jname, jname_count, ''.join(random.choices(string.ascii_lowercase + string.digits, k=4)))


    # ---------------------------------------------------------------------------
    # Loading GUI signalization
    # ---------------------------------------------------------------------------

    def start_loading(self):
        self.loading=self.loading+1
        if self.loading<1: self.loading=1
        if self.zynqtgui:
            self.zynqtgui.start_loading()

    def stop_loading(self):
        self.loading=self.loading-1
        if self.loading<0: self.loading=0
        if self.zynqtgui:
            self.zynqtgui.stop_loading()

    def reset_loading(self):
        self.loading=0
        if self.zynqtgui:
            self.zynqtgui.stop_loading()

    # ---------------------------------------------------------------------------
    # Refresh Management
    # ---------------------------------------------------------------------------

    def refresh_all(self, refresh=True):
        for layer in self.layers:
            layer.refresh_flag=refresh

    # ---------------------------------------------------------------------------
    # OSC Management
    # ---------------------------------------------------------------------------

    def osc_init(self, target_port=None, proto=liblo.UDP):
        if target_port:
            self.osc_target_port=target_port
        try:
            self.osc_target=liblo.Address('localhost',self.osc_target_port,proto)
            logging.info("OSC target in port %s" % str(self.osc_target_port))
            self.osc_server=liblo.ServerThread(None,proto)
            self.osc_server_port=self.osc_server.get_port()
            self.osc_server_url=liblo.Address('localhost',self.osc_server_port,proto).get_url()
            logging.info("OSC server running in port %s" % str(self.osc_server_port))
            self.osc_add_methods()
            self.osc_server.start()
        except liblo.AddressError as err:
            logging.error("OSC Server can't be initialized (%s). Running without OSC feedback." % err)


    def osc_end(self):
        if self.osc_server:
            try:
                #self.osc_server.stop()
                logging.info("OSC server stopped")
            except Exception as err:
                logging.error("Can't stop OSC server => %s" % err)


    def osc_add_methods(self):
        self.osc_server.add_method(None, None, self.cb_osc_all)


    def cb_osc_all(self, path, args, types, src):
        logging.info("OSC MESSAGE '%s' from '%s'" % (path, src.url))
        for a, t in zip(args, types):
            logging.debug("argument of type '%s': %s" % (t, a))


    # ---------------------------------------------------------------------------
    # Generating list from different sources
    # ---------------------------------------------------------------------------

    @staticmethod
    def get_filelist(dpath, fext, sort=True, start_index=0):
        res=[]
        if isinstance(dpath, str): dpath=[('_', dpath)]
        fext='.'+fext
        xlen=len(fext)
        i=start_index
        for dpd in dpath:
            dp=dpd[1]
            dn=dpd[0]
            try:
                if sort:
                    files = sorted(os.listdir(dp))
                else:
                    files = os.listdir(dp)
                for f in files:
                    if not f.startswith('.') and isfile(join(dp,f)) and f[-xlen:].lower()==fext:
                        title=str.replace(f[:-xlen], '_', ' ')
                        if dn!='_': title=dn+'/'+title
                        #print("filelist => "+title)
                        res.append([join(dp,f),i,title,dn,f])
                        i=i+1
            except:
                pass

        return res


    @staticmethod
    def get_dirlist(dpath, exclude_empty=True, sort=True, start_index=0):
        res=[]
        if isinstance(dpath, str): dpath=[('_', dpath)]
        i=start_index
        for dpd in dpath:
            dp=dpd[1]
            dn=dpd[0]
            try:
                if sort:
                    files = sorted(os.listdir(dp))
                else:
                    files = os.listdir(dp)
                for f in files:
                    if exclude_empty and next(os.scandir(join(dp,f)), None) is None:
                        continue
                    if not f.startswith('.') and isdir(join(dp,f)):
                        title,ext=os.path.splitext(f)
                        title=str.replace(title, '_', ' ')
                        if dn!='_': title=dn+'/'+title
                        #print("dirlist => "+title)
                        res.append([join(dp,f),i,title,dn,f])
                        i=i+1
            except:
                pass

        return res


    @staticmethod
    def get_cmdlist(cmd):
        res=[]
        i=0
        output=check_output(cmd, shell=True)
        lines=output.decode('utf8').split('\n')
        for f in lines:
            title=str.replace(f, '_', ' ')
            res.append([f,i,title])
            i=i+1
        return res


    # ---------------------------------------------------------------------------
    # Layer Management
    # ---------------------------------------------------------------------------

    def add_layer(self, layer):
        self.layers.append(layer)
        layer.jackname = self.jackname


    def del_layer(self, layer):
        try:
            self.layers.remove(layer)
        except: pass
        layer.jackname = None


    def del_all_layers(self):
        for layer in self.layers:
            self.del_layer(layer)


    # ---------------------------------------------------------------------------
    # MIDI Channel Management
    # ---------------------------------------------------------------------------

    def set_midi_chan(self, layer):
        pass


    def get_active_midi_channels(self):
        chans=[]
        for layer in self.layers:
            if layer.midi_chan is None:
                return None
            elif layer.midi_chan>=0 and layer.midi_chan<=15:
                chans.append(layer.midi_chan)
        return chans


    # ---------------------------------------------------------------------------
    # Bank Management
    # ---------------------------------------------------------------------------


    def get_bank_list(self, layer=None):
        logging.info('Getting Bank List for %s: NOT IMPLEMENTED!' % self.name)


    def set_bank(self, layer, bank):
        self.zynqtgui.zynmidi.set_midi_bank_msb(layer.get_midi_chan(), bank[1])
        return True


    # ---------------------------------------------------------------------------
    # Preset Management
    # ---------------------------------------------------------------------------

    def get_preset_list(self, bank):
        logging.info('Getting Preset List for %s: NOT IMPLEMENTED!' % self.name),'PD'


    def set_preset(self, layer, preset, preload=False, force_immediate=False):
        if isinstance(preset[1],int):
            self.zynqtgui.zynmidi.set_midi_prg(layer.get_midi_chan(), preset[1])
        else:
            self.zynqtgui.zynmidi.set_midi_preset(layer.get_midi_chan(), preset[1][0], preset[1][1], preset[1][2])
        return True


    def cmp_presets(self, preset1, preset2):
        try:
            if preset1[1][0]==preset2[1][0] and preset1[1][1]==preset2[1][1] and preset1[1][2]==preset2[1][2]:
                return True
            else:
                return False
        except:
            return False


    # ---------------------------------------------------------------------------
    # Preset Favorites Management
    # ---------------------------------------------------------------------------

    def toggle_preset_fav(self, layer, preset):
        if self.preset_favs is None:
            self.load_preset_favs()

        try:
            del self.preset_favs[str(preset[0])]
            fav_status = False
        except:
            self.preset_favs[str(preset[0])]=[layer.bank_info, preset]
            fav_status = True

        try:
            with open(self.preset_favs_fpath, 'w') as f:
                json.dump(self.preset_favs, f)
        except Exception as e:
            logging.error("Can't save preset favorites! => {}".format(e))

        return fav_status


    def get_preset_favs(self, layer):
        if self.preset_favs is None:
            self.load_preset_favs()

        return self.preset_favs


    def is_preset_fav(self, preset):
        if self.preset_favs is None:
            self.load_preset_favs()

        #if str(preset[0]) in [str(item[1][0]) for item in self.preset_favs.values()]:
        if str(preset[0]) in self.preset_favs:
            return True
        else:
            return False


    def load_preset_favs(self):
        if self.nickname:
            fname = self.nickname.replace("/","_")
            self.preset_favs_fpath = self.my_data_dir + "/preset-favorites/" + fname + ".json"

            try:
                with open(self.preset_favs_fpath) as f:
                    self.preset_favs = json.load(f, object_pairs_hook=OrderedDict)
            except:
                self.preset_favs = OrderedDict()
        else:
            logging.warning("Can't load preset favorites until the engine have a nickname!")


    # ---------------------------------------------------------------------------
    # Controllers Management
    # ---------------------------------------------------------------------------

    # Get zynthian controllers dictionary:
    # + Default implementation uses a static controller definition array
    def get_controllers_dict(self, layer=None):
        if layer is not None:
            midich=layer.get_midi_chan()
        else:
            midich = -1
        zctrls=OrderedDict()

        if self._ctrls is not None:
            for ctrl in self._ctrls:
                options={}

                #OSC control =>
                if layer is not None and isinstance(ctrl[1], str):
                    #replace variables ...
                    tpl=Template(ctrl[1])
                    cc=tpl.safe_substitute(ch=midich)
                    try:
                        cc=tpl.safe_substitute(i=layer.part_i)
                    except:
                        pass
                    #set osc_port option ...
                    if self.osc_target_port>0:
                        options['osc_port']=self.osc_target_port
                    #debug message
                    logging.debug('CONTROLLER %s OSC PATH => %s' % (ctrl[0],cc))
                #MIDI Control =>
                else:
                    cc=ctrl[1]

                #Build controller depending on array length ...
                if len(ctrl)>4:
                    if isinstance(ctrl[4],str):
                        zctrl=zynthian_controller(self,ctrl[4],ctrl[0])
                    else:
                        zctrl=zynthian_controller(self,ctrl[0])
                        zctrl.graph_path=ctrl[4]
                    zctrl.setup_controller(midich,cc,ctrl[2],ctrl[3])
                elif len(ctrl)>3:
                    zctrl=zynthian_controller(self,ctrl[0])
                    zctrl.setup_controller(midich,cc,ctrl[2],ctrl[3])
                else:
                    zctrl=zynthian_controller(self,ctrl[0])
                    zctrl.setup_controller(midich,cc,ctrl[2])

                #Set controller extra options
                if len(options)>0:
                    zctrl.set_options(options)

                if zctrl.symbol.casefold() == "volume" or (self.version_info.volumeControls is not None and zctrl.symbol in self.version_info.volumeControls):
                    self.setVolumeController(zctrl)
                    # When encountering a volume controller, set it to max, and add to controller list otherwise CC messages do not get sent
                    # This is to handle any CC controllers from any engines other than jalv
                    zctrl.set_value(zctrl.value_max)

                zctrls[zctrl.symbol]=zctrl
        return zctrls

    def get_controllers_dict_without_layer(self):
        """
        Get controllers dict for an engine when you dont have a layer instance.
        This would be helpful to get controllers for engines not associated to any layer like global FX

        Note : If an engine is associated to a layer, make sure to call get_controllers_dict instead with layer object
        """

        return self.get_controllers_dict(None)

    def generate_ctrl_screens(self, zctrl_dict=None):
        if zctrl_dict is None:
            zctrl_dict=self.zctrl_dict

        if self._ctrl_screens is None:
            self._ctrl_screens=[]

        c=1
        ctrl_set=[]
        for symbol, zctrl in zctrl_dict.items():
            try:
                #logging.debug("CTRL {}".format(symbol))
                ctrl_set.append(symbol)
                if len(ctrl_set)>=4:
                    #logging.debug("ADDING CONTROLLER SCREEN {}#{}".format(self.nickname,c))
                    self._ctrl_screens.append(["{}#{}".format(self.nickname,c),ctrl_set])
                    ctrl_set=[]
                    c=c+1
            except Exception as err:
                logging.error("Generating Controller Screens => {}".format(err))

        if len(ctrl_set)>=1:
            #logging.debug("ADDING CONTROLLER SCREEN #"+str(c))
            self._ctrl_screens.append(["{}#{}".format(self.nickname,c),ctrl_set])


    def send_controller_value(self, zctrl):
        raise Exception("NOT IMPLEMENTED!")

    def get_controller_value_label(self, zctrl):
        raise Exception("NOT IMPLEMENTED!")

    # BEGIN Property bypassController
    def setBypassController(self, newBypassController):
        if self.__bypassController != newBypassController:
            self.__bypassController = newBypassController
            self.bypassControllerChanged.emit()

    def getBypassController(self):
        return self.__bypassController

    bypassControllerChanged = Signal()

    bypassController = Property(QObject, getBypassController, notify=bypassControllerChanged)
    # END Property bypassController
    
    # BEGIN Property volumeController
    def setVolumeController(self, newVolumeController):
        if self.__volumeController != newVolumeController:
            self.__volumeController = newVolumeController
            self.volumeControllerChanged.emit()
            
    def getVolumeController(self):
        return self.__volumeController
    
    volumeControllerChanged = Signal()
    volumeController = Property(QObject, getVolumeController, setVolumeController, notify=volumeControllerChanged)
    # END Property volumeController

    #----------------------------------------------------------------------------
    # MIDI learning
    #----------------------------------------------------------------------------

    def init_midi_learn(self, zctrl):
        logging.info("Learning '{}' ({}) ...".format(zctrl.symbol,zctrl.get_path()))


    def midi_unlearn(self, zctrl):
        if zctrl.get_path() in self.learned_zctrls:
            logging.info("Unlearning '{}' ...".format(zctrl.symbol))
            try:
                self.learned_cc[zctrl.midi_learn_chan][zctrl.midi_learn_cc] = None
                del self.learned_zctrls[zctrl.get_path()]
                return zctrl._unset_midi_learn()
            except Exception as e:
                logging.warning("Can't unlearn => {}".format(e))


    def set_midi_learn(self, zctrl ,chan, cc):
        try:
            # Clean current binding if any ...
            try:
                self.learned_cc[chan][cc].midi_unlearn()
            except:
                pass
            # Add midi learning info
            self.learned_zctrls[zctrl.get_path()] = zctrl
            self.learned_cc[chan][cc] = zctrl
            return zctrl._set_midi_learn(chan, cc)
        except Exception as e:
            logging.error("Can't learn {} => {}".format(zctrl.symbol, e))


    def keep_midi_learn(self, zctrl):
        try:
            zpath = zctrl.get_path()
            old_zctrl = self.learned_zctrls[zpath]
            chan = old_zctrl.midi_learn_chan
            cc = old_zctrl.midi_learn_cc
            self.learned_zctrls[zpath] = zctrl
            self.learned_cc[chan][cc] = zctrl
            return zctrl._set_midi_learn(chan, cc)
        except:
            pass


    def reset_midi_learn(self):
        logging.info("Reset MIDI-learn ...")
        self.learned_zctrls = {}
        self.learned_cc = [[None for chan in range(16)] for cc in range(128)]


    def cb_midi_learn(self, zctrl, chan, cc):
        return self.set_midi_learn(zctrl, chan, cc)


    #----------------------------------------------------------------------------
    # MIDI CC processing
    #----------------------------------------------------------------------------

    def midi_control_change(self, chan, ccnum, val):
        try:
            self.learned_cc[chan][ccnum].midi_control_change(val)
        except:
            pass


    def midi_zctrl_change(self, zctrl, val):
        try:
            if val!=zctrl.get_value():
                zctrl.set_value(val)
                #logging.debug("MIDI CC {} -> '{}' = {}".format(zctrl.midi_cc, zctrl.name, val))

                #Refresh GUI controller in screen when needed ...
                if (self.zynqtgui.active_screen=='control' and not self.zynqtgui.modal_screen) or self.zynqtgui.modal_screen=='alsa_mixer':
                    self.zynqtgui.screens['control'].set_controller_value(zctrl)

        except Exception as e:
            logging.debug(e)


    # ---------------------------------------------------------------------------
    # Layer "Path" String
    # ---------------------------------------------------------------------------

    def get_path(self, layer):
        return self.nickname


    # ---------------------------------------------------------------------------
    # Options and Extended Config
    # ---------------------------------------------------------------------------

    def get_options(self):
        return self.options


    def get_extended_config(self):
        return None


    def set_extended_config(self, xconfig):
        pass

    # ---------------------------------------------------------------------------
    # API methods
    # ---------------------------------------------------------------------------

    @classmethod
    def get_zynapi_methods(cls):
        return [f for f in dir(cls) if f.startswith('zynapi_')]
        #callable(f) and


#******************************************************************************
