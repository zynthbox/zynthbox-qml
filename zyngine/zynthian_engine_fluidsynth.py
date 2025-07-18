# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian Engine (zynthian_engine_fluidsynth)
# 
# zynthian_engine implementation for FluidSynth Sampler
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
import copy
import shutil
import logging
from pathlib import Path
from subprocess import check_output
from . import zynthian_engine

#------------------------------------------------------------------------------
# FluidSynth Engine Class
#------------------------------------------------------------------------------

class zynthian_engine_fluidsynth(zynthian_engine):

    # ---------------------------------------------------------------------------
    # Controllers & Screens
    # ---------------------------------------------------------------------------

    # Standard MIDI Controllers
    _ctrls=[
        ['volume',7,127],
        ['modulation',1,0],
        ['pan',10,64],
        ['expression',11,127],
        ['sustain',64,'off',['off','on']],
        ['reverb',91,64],
        ['chorus',93,2],
        ['portamento on/off',65,'off',['off','on']],
        ['portamento time-coarse',5,0],
        ['portamento time-fine',37,0],
        ['portamento control',84,0],
        ['sostenuto',66,'off',['off','on']],
        ['legato on/off',68,'off',['off','on']]
    ]

    # Controller Screens
    _ctrl_screens=[
        ['main',['volume','sostenuto','pan','sustain']],
        ['effects',['expression','modulation','reverb','chorus']],
        ['portamento',['legato on/off','portamento on/off','portamento time-coarse','portamento time-fine']],
    ]

    # ---------------------------------------------------------------------------
    # Config variables
    # ---------------------------------------------------------------------------

    fs_options = "-o synth.midi-bank-select=mma -o synth.cpu-cores=3 -o synth.polyphony=64 -o audio.jack.multi='yes'"

    # Only list soundfont from my-data. System soundfonts are listed from plugins json
    soundfont_dirs=[
        ('MY', zynthian_engine.my_data_dir + "/soundfonts/sf2")
    ]

    # ---------------------------------------------------------------------------
    # Initialization
    # ---------------------------------------------------------------------------

    def __init__(self, version_info, zynqtgui=None):
        super().__init__(version_info, zynqtgui)
        self.__most_recent_preset_transaction__ = None

        self.name = "FluidSynth"
        self.nickname = "FS"
        self.jackname = self.get_next_jackname('fluidsynth')

        self.options['drop_pc']=True

        self.command = f"fluidsynth -a jack -m jack -g 1 -o midi.jack.id='{self.jackname}' -o audio.jack.id='{self.jackname}' {self.fs_options}"
        self.command_prompt = "\n> "
        self.proc.setCommandPrompt(self.command_prompt)


        output = self.start()
        self.reset()

        logging.debug(f"Fluidsynth Startup output : {output}")


    def reset(self):
        super().reset()
        self.soundfont_index={}
        self.clear_midi_routes()
        self.unload_unused_soundfonts()

    # ---------------------------------------------------------------------------
    # Subproccess Management & IPC
    # ---------------------------------------------------------------------------

    def stop(self):
        # FIXME : `quit` call is not returning and hence stop gets stuck.
        #         For the time being call super().stop() to kill the process.
        # try:
        #     transaction = self.proc.call("quit", "cheers!\r\n")
        #     transaction.release()
        # except:
        #     super().stop()

        super().stop()

    # ---------------------------------------------------------------------------
    # Layer Management
    # ---------------------------------------------------------------------------

    def add_layer(self, layer):
        self.layers.append(layer)
#        layer.jackname = None
        layer.part_i=None
        self.setup_router(layer)


    def del_layer(self, layer):
        super().del_layer(layer)
        if layer.part_i is not None:
            self.set_all_midi_routes()
        self.unload_unused_soundfonts()

    # ---------------------------------------------------------------------------
    # MIDI Channel Management
    # ---------------------------------------------------------------------------

    def set_midi_chan(self, layer):
        self.setup_router(layer)

    # ---------------------------------------------------------------------------
    # Bank Management
    # ---------------------------------------------------------------------------

    def get_bank_list(self, layer=None):
        # Fluidsynth banks are simply the sf2 and sf3 files listed in the format : `[<string: sf2/sf3 file path>, <int: index>, <string: display name>, <string: 'MY' for files in my-data and '_' for others>, <string: file name with extension>]`
        # Sort list after gathering all sf2/sf3 files from both plugins json and my-data
        plugins_list = []
        index = 0
        # Add plugins from plugins json
        for plugin_id, plugin_info in self.zynqtgui.zynthbox_plugins_helper.get_plugins_by_type("soundfont").items():
            for _, version_info in plugin_info.versions.items():
                if version_info.visible and version_info.format.lower() in ["sf2", "sf3"]:
                    plugins_list.append([version_info.path, index, version_info.pluginName.replace("_", " "), "_", Path(version_info.path).name, version_info.plugin_info.id, version_info.version])
                    index += 1
        # Append sf2 from soundfont_dirs
        plugins_list += self.get_filelist(self.soundfont_dirs, "sf2", sort=False, start_index=len(plugins_list))
        # Append sf3 from soundfont_dirs
        plugins_list += self.get_filelist(self.soundfont_dirs, "sf3", sort=False, start_index=len(plugins_list))
        # Return plugins list sorted by name (case-insensitive)
        return sorted(plugins_list, key=lambda e: e[0].casefold())


    def set_bank(self, layer, bank):
        return self.load_bank(bank)


    def load_bank(self, bank, unload_unused_sf=True):
        if bank[0] in self.soundfont_index:
            return True
        else:
            max_retries = 5
            while max_retries > 0:
                logging.debug(f"Loading bank retries left : {max_retries}")
                if self.load_soundfont(bank[0]):
                    if unload_unused_sf:
                        self.unload_unused_soundfonts()
                    self.set_all_presets()
                    return True
                else:
                    max_retries -= 1
            return False

    # ---------------------------------------------------------------------------
    # Preset Management
    # ---------------------------------------------------------------------------

    def get_preset_list(self, bank):
        logging.info("Getting Preset List for {}".format(bank[2]))
        preset_list=[]

        max_retries = 5

        if bank[0] in self.soundfont_index:
            sfi = self.soundfont_index[bank[0]]
        else:
            if self.load_bank(bank, False) and bank[0] in self.soundfont_index:
                sfi = self.soundfont_index[bank[0]]
            else:
                logging.error(f"Big problem, we could not load the bank for {bank[2]} and will have to return an empty list")
                max_retries = 0

        while sfi and max_retries > 0:
            logging.debug(f"Trying to load preset list : Retries left {max_retries}")
            transaction = self.proc.call(f"inst {sfi}")
            if self.__most_recent_preset_transaction__ and self.__most_recent_preset_transaction__.command() == transaction.command() and transaction.transactionId() < self.__most_recent_preset_transaction__.transactionId():
                # If we have a previous transaction for presets for this bank, and that one is newer than the one we just got given, use that instead
                # logging.error(f"Using previously returned transaction with id {self.__most_recent_preset_transaction__.transactionId()} instead of {transaction.transactionId()}")
                transaction.release()
                transaction = self.__most_recent_preset_transaction__
            else:
                # Otherwise the one we just got given is newer (or exists), and becomes our most recent transaction
                if self.__most_recent_preset_transaction__:
                    self.__most_recent_preset_transaction__.release()
                self.__most_recent_preset_transaction__ = transaction
            output = transaction.standardOutput()
            # output=self.proc_cmd(f"inst {sfi}", wait_for_output=True)
            for f in output.split("\n"):
                try:
                    prg=int(f[4:7])
                    bank_msb=int(f[0:3])
                    bank_lsb=int(bank_msb/128)
                    bank_msb=bank_msb%128
                    # Only strip on the right hand side (left might be deliberate, for categorization
                    # use and whatnot, but right hand side is just padding)
                    title=str.replace(f[8:].rstrip(), '_', ' ')
                    preset_list.append([bank[0] + '/' + f.strip(),[bank_msb,bank_lsb,prg],title,bank[0]])
                except:
                    pass
            if len(preset_list) == 0:
                # Failed to load preset list. Retry
                max_retries -= 1
            else:
                break

        return preset_list


    def set_preset(self, layer, preset, preload=False, force_immediate=False):
        if preset[3] in self.soundfont_index:
            sfi = self.soundfont_index[preset[3]]
        else:
            if layer.set_bank_by_id(preset[3]) and preset[3] in self.soundfont_index:
                sfi = self.soundfont_index[preset[3]]
            else:
                return False

        midi_bank=preset[1][0]+preset[1][1]*128
        midi_prg=preset[1][2]
        logging.debug("Set Preset => Layer: {}, SoundFont: {}, Bank: {}, Program: {}".format(layer.part_i, sfi, midi_bank, midi_prg))
        self.proc_cmd("select {} {} {} {}".format(layer.part_i, sfi, midi_bank, midi_prg))
        layer.send_ctrl_midi_cc()
        return True


    def cmp_presets(self, preset1, preset2):
        try:
            if preset1[3]==preset2[3] and preset1[1][0]==preset2[1][0] and preset1[1][1]==preset2[1][1] and preset1[1][2]==preset2[1][2]:
                return True
            else:
                return False
        except:
            return False

    # ---------------------------------------------------------------------------
    # Specific functions
    # ---------------------------------------------------------------------------

    def get_free_parts(self):
        free_parts = list(range(0,16))
        for layer in self.layers:
            try:
                free_parts.remove(layer.part_i)
            except:
                pass
        return free_parts


    def load_soundfont(self, sf):
        if sf not in self.soundfont_index:
            logging.info("Loading SoundFont '{}' ...".format(sf))
            # Send command to FluidSynth
            output=self.proc_cmd("load \"{}\"".format(sf), wait_for_output=True)
            # Parse ouput ...
            sfi=None
            cre=re.compile(r"loaded SoundFont has ID (\d+)")
            for line in output.split("\n"):
                #logging.debug(" => {}".format(line))
                res=cre.match(line)
                if res:
                    sfi=int(res.group(1))
            # If soundfont was loaded succesfully ...
            if sfi is not None:
                logging.info("Loaded SoundFont '{}' => {}".format(sf,sfi))
                # Insert ID in soundfont_index dictionary
                self.soundfont_index[sf]=sfi
                # Return soundfont ID
                return sfi
            else:
                logging.warning("SoundFont '{}' can't be loaded".format(sf))
                return False
        else:
            return self.soundfont_index[sf]


    def unload_unused_soundfonts(self):
        #Make a copy of soundfont index and remove used soundfonts
        sf_unload=copy.copy(self.soundfont_index)
        for layer in self.layers:
            bi=layer.bank_info
            if bi is not None:
                if bi[2] and bi[0] in sf_unload:
                    #print("Skip "+bi[0]+"("+str(sf_unload[bi[0]])+")")
                    del sf_unload[bi[0]]
        #Then, remove the remaining ;-)
        for sf,sfi in sf_unload.items():
            logging.info("Unload SoundFont => {}".format(sfi))
            self.proc_cmd("unload {}".format(sfi))
            del self.soundfont_index[sf]


    # Set presets for all layers to restore soundfont assign (select) after load/unload soundfonts 
    def set_all_presets(self):
        for layer in self.layers:
            if layer.preset_info:
                self.set_preset(layer, layer.preset_info)


    def setup_router(self, layer):
        if layer.part_i is not None:
            # Clear and recreate all routes if the routes for this layer were set already
            self.set_all_midi_routes()
        else:
            # No need to clear routes if there is the only layer to add
            try:
                i = self.get_free_parts()[0]
                layer.part_i = i
                layer.jackname = "{}:((l|r)_{:02d}|fx_(l|r)_({:02d}|{:02d}))".format(self.jackname,i,i*2,i*2+1)
                self.zynqtgui.zynautoconnect_audio()
                logging.debug("Add part {} => {}".format(i, layer.jackname))
            except Exception as e:
                logging.error("Can't add part! => {}".format(e))

            self.set_layer_midi_routes(layer)


    def set_layer_midi_routes(self, layer):
        if layer.part_i is not None:
            router_chan_cmd = "router_chan 0 15 0 {0}".format(layer.part_i)
            self.proc_cmd("router_begin note")
            self.proc_cmd(router_chan_cmd)
            self.proc_cmd("router_end")
            self.proc_cmd("router_begin cc")
            self.proc_cmd(router_chan_cmd)
            self.proc_cmd("router_end")
            self.proc_cmd("router_begin pbend")
            self.proc_cmd(router_chan_cmd)
            self.proc_cmd("router_end")
            self.proc_cmd("router_begin prog")
            self.proc_cmd(router_chan_cmd)
            self.proc_cmd("router_end")


    def set_all_midi_routes(self):
        self.clear_midi_routes()
        for layer in self.layers:
            self.set_layer_midi_routes(layer)


    def clear_midi_routes(self):
        self.proc_cmd("router_clear")


    # ---------------------------------------------------------------------------
    # API methods
    # ---------------------------------------------------------------------------

    @classmethod
    def zynapi_get_banks(cls):
        banks=[]
        for b in cls.get_filelist(cls.soundfont_dirs,"sf2") + cls.get_filelist(cls.soundfont_dirs,"sf3"):
            head, tail = os.path.split(b[0])
            fname, fext = os.path.splitext(tail)
            banks.append({
                'text': tail,
                'name': fname,
                'fullpath': b[0],
                'raw': b,
                'readonly': False
            })
        return banks


    @classmethod
    def zynapi_get_presets(cls, bank):
        return []


    @classmethod
    def zynapi_rename_bank(cls, bank_path, new_bank_name):
        head, tail = os.path.split(bank_path)
        fname, ext = os.path.splitext(tail)
        new_bank_path = head + "/" + new_bank_name + ext
        os.rename(bank_path, new_bank_path)


    @classmethod
    def zynapi_remove_bank(cls, bank_path):
        os.remove(bank_path)


    @classmethod
    def zynapi_download(cls, fullpath):
        return fullpath


    @classmethod
    def zynapi_install(cls, dpath, bank_path):

        if os.path.isdir(dpath):
            # Get list of sf2/sf3 files ...
            sfx_files = check_output("find \"{}\" -type f -iname *.sf2 -o -iname *.sf3".format(dpath), shell=True).decode("utf-8").split("\n")

            # Copy sf2/sf3 files to destiny ...
            count = 0
            for f in sfx_files:
                head, fname = os.path.split(f)
                if fname:
                    shutil.move(f, zynthian_engine.my_data_dir + "/soundfonts/sf2/" + fname)
                    count += 1

            if count==0:
                raise Exception("No SF2/SF3 soundfont files found!")

        else:
            fname, ext = os.path.splitext(dpath)
            if ext.lower() in ['.sf2', '.sf3']:
                shutil.move(dpath, zynthian_engine.my_data_dir + "/soundfonts/sf2")
            else:
                raise Exception("File doesn't look like a SF2/SF3 soundfont")


    @classmethod
    def zynapi_get_formats(cls):
        return "sf2,sf3,zip,tgz,tar.gz,tar.bz2"


    @classmethod
    def zynapi_martifact_formats(cls):
        return "sf2,sf3"


#******************************************************************************
