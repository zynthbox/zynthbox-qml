# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian Engine (zynthian_engine_jalv)
#
# zynthian_engine implementation for Jalv Plugin Host
#
# Copyright (C) 2015-2018 Fernando Moyano <jofemodo@zynthian.org>
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
import shutil
import logging
import random
import string
from collections import OrderedDict
from subprocess import check_output, STDOUT

from . import zynthian_lv2
from . import zynthian_engine
from . import zynthian_controller

#------------------------------------------------------------------------------
# Jalv Engine Class
#------------------------------------------------------------------------------

class zynthian_engine_jalv(zynthian_engine):


    #------------------------------------------------------------------------------
    # Native formats configuration (used by zynapi_install, preset converter, etc.)
    #------------------------------------------------------------------------------

    plugin2native_ext = {
        "Dexed": "syx",
        "synthv1": "synthv1",
        "padthv1": "padthv1",
        "Obxd": "fxb"
        #"Helm": "helm"
    }

    plugin2preset2lv2_format = {
        "Dexed": "dx7syx",
        "synthv1": "synthv1",
        "padthv1": "padthv1",
        "Obxd": "obxdfxb"
        #"Helm": "helm"
    }

    # ---------------------------------------------------------------------------
    # Controllers & Screens
    # ---------------------------------------------------------------------------

    plugin_ctrl_info = {
        "Dexed": {
        },
        "Helm": {
        },
        "MDA DX10": {
            "ctrls": [
                ['volume',7,96],
                ['mod-wheel',1,0],
                ['sustain on/off',64,'off','off|on']
            ],
            "ctrl_screens": [['MIDI Controllers',['volume','mod-wheel','sustain on/off']]]
        },
        "MDA JX10": {
            "ctrls": [
                ['volume',7,96],
                ['mod-wheel',1,0],
            ],
            "ctrl_screens": [['MIDI Controllers',['volume','mod-wheel']]]
        },
        "MDA ePiano": {
            "ctrls": [
                ['volume',7,96],
                ['mod-wheel',1,0],
                ['sustain on/off',64,'off','off|on']
            ],
            "ctrl_screens": [['MIDI Controllers',['volume','mod-wheel','sustain on/off']]]
        },
        "MDA Piano": {
            "ctrls": [
                ['volume',7,96],
                ['mod-wheel',1,0],
                ['sustain on/off',64,'off','off|on']
            ],
            "ctrl_screens": [['MIDI Controllers',['volume','mod-wheel','sustain on/off']]]
        },
        "Noize Mak3r": {
        },
        "Obxd": {
        },
        "synthv1": {
        },
        "reMID": {
            "ctrls": [
                ['volume',7,96],
            ],
            "ctrl_screens": [['MIDI Controllers',['volume']]]
        }
    }

    _ctrls = None
    _ctrl_screens = None

    #----------------------------------------------------------------------------
    # ZynAPI variables
    #----------------------------------------------------------------------------

    zynapi_instance = None

    #----------------------------------------------------------------------------
    # Initialization
    #----------------------------------------------------------------------------

    def __init__(self, plugin_info, zynqtgui=None, dryrun=False):
        super().__init__(plugin_info, zynqtgui)

        self.type = plugin_info.type
        self.name = "Jalv/" + plugin_info.name
        self.nickname = "JV/" + plugin_info.name
        self.plugin_name = plugin_info.name
        self.plugin_url = plugin_info.url
        self.jackname = self.get_jalv_jackname()

        self.ui = False
        # if self.plugin_url not in self.broken_ui and 'UI' in self.plugins_dict[plugin_name]:
        #     self.ui = self.plugins_dict[plugin_name]['UI']

        if plugin_info.type=="MIDI Tool":
            self.options['midi_route'] = True
            self.options['audio_route'] = False
        elif plugin_info.type=="Audio Effect":
            self.options['audio_capture'] = True
            self.options['note_range'] = False

        if not dryrun:
            if self.config_remote_display() and self.ui:
                self.command = ("jalv.gtk --jack-name {} {}".format(self.jackname, self.plugin_url))
            else:
                self.command_env['DISPLAY'] = ":0"
                self.command_env['QT_QPA_PLATFORM'] = "offscreen"
                self.command = ("jalv -n {} {}".format(self.jackname, self.plugin_url))

            self.command_prompt = "\n> "
            self.proc.setCommandPrompt(self.command_prompt)
            self.start()

            # TODO : We probably do not need it anymore as the core issues with ProcessWrapper has been fixed and works like a charm
            #        Still keeping this commented for a few days and monitor if this an issue
            # Run presets command explicitly after starting otherwise loading a preset does not work
            # transaction = self.proc.call("presets")
            # logging.debug(f"--- presets command output BEGIN\n{transaction.standardOutput()}\n--- presets command output END")
            # transaction.release()
            # if self.proc.waitForOutput(self.command_prompt) == Zynthbox.ProcessWrapper.WaitForOutputResult.WaitForOutputSuccess:
                # pass
            # else:
                # logging.error("An error occurred while waiting for the function to return")

            # Set static MIDI Controllers from hardcoded plugin info
            try:
                self._ctrls = self.plugin_ctrl_info[self.plugin_name]['ctrls']
                self._ctrl_screens = self.plugin_ctrl_info[self.plugin_name]['ctrl_screens']
            except:
                logging.info("No defined MIDI controllers for '{}'.".format(self.plugin_name))

            # Generate LV2-Plugin Controllers
            self.lv2_monitors_dict = OrderedDict()
            self.lv2_zctrl_dict = self.get_lv2_controllers_dict()
            self.generate_ctrl_screens(self.lv2_zctrl_dict)

        # Get bank & presets info
        self.preset_info = zynthian_lv2.get_plugin_presets(self.plugin_name)

        self.bank_list = []
        for bank_label, info in self.preset_info.items():
            self.bank_list.append((str(info['bank_url']), None, bank_label, None))

        if len(self.bank_list)==0:
            self.bank_list.append(("", None, "", None))

        self.reset()


    # Jack, when listing ports, accepts regular expressions as the jack name.
    # So, for avoiding problems, jack names shouldn't contain regex characters.
    def get_jalv_jackname(self):
        try:
            jname = re.sub("[\_]{2,}","_",re.sub("[\'\*\(\)\[\]\s]","_",self.plugin_name))
            jname_count = self.zynqtgui.screens['layer'].get_jackname_count(jname)
        except:
            jname_count = 0

        # Append a 4 letter random id to jackname to prevent name clashes
        return "{}-{:02d}-{}".format(jname, jname_count, ''.join(random.choices(string.ascii_lowercase + string.digits, k=4)))

    # ---------------------------------------------------------------------------
    # Layer Management
    # ---------------------------------------------------------------------------

    def add_layer(self, layer):
        layer.listen_midi_cc = False
        super().add_layer(layer)
        self.set_midi_chan(layer)

    # ---------------------------------------------------------------------------
    # MIDI Channel Management
    # ---------------------------------------------------------------------------

    def set_midi_chan(self, layer):
        if self.plugin_name=="Triceratops":
            self.lv2_zctrl_dict["midi_channel"].set_value(layer.midi_chan+1.5)
        elif self.plugin_name.startswith("SO-"):
            self.lv2_zctrl_dict["channel"].set_value(layer.midi_chan)

    #----------------------------------------------------------------------------
    # Bank Managament
    #----------------------------------------------------------------------------

    def get_bank_list(self, layer=None):
        return self.bank_list


    def set_bank(self, layer, bank):
        return True

    #----------------------------------------------------------------------------
    # Preset Managament
    #----------------------------------------------------------------------------

    def get_preset_list(self, bank):
        preset_list = []
        try:
            for info in  self.preset_info[bank[2]]['presets']:
                preset_list.append([info['url'], None, info['label'], bank[0]])
        except:
            preset_list.append(("", None, "", None))

        return preset_list


    def set_preset(self, layer, preset, preload=False, force_immediate=False):
        if not preset[0]:
            return
        output=self.proc_cmd("preset {}".format(preset[0]), wait_for_output=True)

        #Parse new controller values
        for line in output.split("\n"):
            try:
                parts=line.split(" = ")
                if len(parts)==2:
                    self.lv2_zctrl_dict[parts[0]]._set_value(float(parts[1]))
            except Exception as e:
                # logging.debug(e)
                pass

        return True


    def cmp_presets(self, preset1, preset2):
        try:
            if preset1[0]==preset2[0]:
                return True
            else:
                return False
        except:
            return False

    #----------------------------------------------------------------------------
    # Controllers Managament
    #----------------------------------------------------------------------------

    def get_lv2_controllers_dict(self):
        logging.info("Getting Controller List from LV2 Plugin ...")

        zctrls = OrderedDict()
        for i, info in zynthian_lv2.get_plugin_ports(self.plugin_url).items():
            symbol = info['symbol']
            # logging.error("Controller {} info =>\n{}!".format(symbol, info))
            try:
                zctrl = None
                #If there is points info ...
                if len(info['scale_points'])>1:
                    labels = []
                    values = []
                    for p in info['scale_points']:
                        labels.append(p['label'])
                        values.append(p['value'])

                    zctrl = zynthian_controller(self, symbol, info['name'], {
                        'group_symbol': info['group_symbol'],
                        'group_name': info['group_name'],
                        'graph_path': info['index'],
                        'value': info['value'],
                        'labels': labels,
                        'ticks': values,
                        'value_min': values[0],
                        'value_max': values[-1],
                        'is_toggle': info['is_toggled'],
                        'is_integer': info['is_integer']
                    })

                #If it's a numeric controller ...
                else:
                    r = info['range']['max'] - info['range']['min']
                    if info['is_integer']:
                        if info['is_toggled']:
                            if info['value']==0:
                                val = 'off'
                            else:
                                val = 'on'
                            if info['range']['default']==0:
                                val_default = 'off'
                            else:
                                val_default = 'on'

                            zctrl = zynthian_controller(self, symbol, info['name'], {
                                'group_symbol': info['group_symbol'],
                                'group_name': info['group_name'],
                                'graph_path': info['index'],
                                'value': val,
                                'labels': ['off','on'],
                                'ticks': [int(info['range']['min']), int(info['range']['max'])],
                                'value_default': val_default,
                                'value_min': int(info['range']['min']),
                                'value_max': int(info['range']['max']),
                                'is_toggle': True,
                                'is_integer': True
                            })
                        else:
                            zctrl = zynthian_controller(self, symbol, info['name'], {
                                'group_symbol': info['group_symbol'],
                                'group_name': info['group_name'],
                                'graph_path': info['index'],
                                'value': int(info['value']),
                                'value_default': int(info['range']['default']),
                                'value_min': int(info['range']['min']),
                                'value_max': int(info['range']['max']),
                                'is_toggle': False,
                                'is_integer': True,
                                'is_logarithmic': info['is_logarithmic']
                            })
                    else:
                        if info['is_toggled']:
                            if info['value']==0:
                                val = 'off'
                            else:
                                val = 'on'
                            if info['range']['default']==0:
                                val_default = 'off'
                            else:
                                val_default = 'on'

                            zctrl = zynthian_controller(self, symbol, info['name'], {
                                'group_symbol': info['group_symbol'],
                                'group_name': info['group_name'],
                                'graph_path': info['index'],
                                'value': val,
                                'labels': ['off','on'],
                                'ticks': [info['range']['min'], info['range']['max']],
                                'value_default': val_default,
                                'value_min': info['range']['min'],
                                'value_max': info['range']['max'],
                                'is_toggle': True,
                                'is_integer': False
                            })
                        else:
                            zctrl = zynthian_controller(self, symbol, info['name'], {
                                'group_symbol': info['group_symbol'],
                                'group_name': info['group_name'],
                                'graph_path': info['index'],
                                'value': info['value'],
                                'value_default': info['range']['default'],
                                'value_min': info['range']['min'],
                                'value_max': info['range']['max'],
                                'is_toggle': False,
                                'is_integer': False,
                                'is_logarithmic': info['is_logarithmic']
                            })
                if symbol.casefold() == "bypass":
                    self.setBypassController(zctrl)
                else:
                    zctrls[symbol] = zctrl

            #If control info is not OK
            except Exception as e:
                logging.error(e)
        return zctrls

    def get_lv2_monitors_dict(self):
        self.lv2_monitors_dict = OrderedDict()
        for line in self.proc_cmd("monitors", wait_for_output=True).split("\n"):
            try:
                parts=line.split(" = ")
                if len(parts)==2:
                    self.lv2_monitors_dict[parts[0]] = float(parts[1])
            except Exception as e:
                logging.error(e)

        return self.lv2_monitors_dict


    def get_ctrl_screen_name(self, gname, i):
        if i>0:
            gname = "{}#{}".format(gname, i)
        return gname

    def generate_ctrl_screens(self, zctrl_dict=None):
        if zctrl_dict is None:
            zctrl_dict=self.zctrl_dict

        if self._ctrl_screens is None:
            self._ctrl_screens=[]

        # Get zctrls by group
        zctrl_group = OrderedDict()
        for symbol, zctrl in zctrl_dict.items():
            gsymbol = zctrl.group_symbol
            if gsymbol is None:
                gsymbol = "_"
            if gsymbol not in zctrl_group:
                zctrl_group[gsymbol] = [zctrl.group_name, OrderedDict()]
            zctrl_group[gsymbol][1][symbol] = zctrl
        if "_" in zctrl_group:
            last_group = zctrl_group["_"]
            del zctrl_group["_"]
            if len(zctrl_group)==0:
                last_group[0] = "Ctrls"
            else:
                last_group[0] = "Ungroup"
            zctrl_group["_"] = last_group

        for gsymbol, gdata in zctrl_group.items():
            ctrl_set=[]
            gname = gdata[0]
            if len(gdata[1])<=4:
                c=0
            else:
                c=1
            for symbol, zctrl in gdata[1].items():
                try:
                    #logging.debug("CTRL {}".format(symbol))
                    ctrl_set.append(symbol)
                    if len(ctrl_set)>=4:
                        #logging.debug("ADDING CONTROLLER SCREEN {}".format(self.get_ctrl_screen_name(gname,c)))
                        self._ctrl_screens.append([self.get_ctrl_screen_name(gname,c),ctrl_set])
                        ctrl_set=[]
                        c=c+1
                except Exception as err:
                    logging.error("Generating Controller Screens => {}".format(err))

            if len(ctrl_set)>=1:
                #logging.debug("ADDING CONTROLLER SCREEN {}",format(self.get_ctrl_screen_name(gname,c)))
                self._ctrl_screens.append([self.get_ctrl_screen_name(gname,c),ctrl_set])


    def get_controllers_dict(self, layer):
        # Get plugin static controllers
        zctrls=super().get_controllers_dict(layer)
        # Add plugin native controllers
        zctrls.update(self.lv2_zctrl_dict)
        return zctrls


    def send_controller_value(self, zctrl):
        self.proc_cmd("set %d %.6f" % (zctrl.graph_path, zctrl.value))


    # ---------------------------------------------------------------------------
    # API methods
    # ---------------------------------------------------------------------------

    @classmethod
    def init_zynapi_instance(cls, plugin_name, plugin_type):
        if cls.zynapi_instance and cls.zynapi_instance.plugin_name!=plugin_name:
            cls.zynapi_instance.stop()
            cls.zynapi_instance = None

        if not cls.zynapi_instance:
            cls.zynapi_instance = cls(plugin_name, plugin_type, None, True)
        else:
            logging.debug("\n\n********** REUSING INSTANCE for '{}'***********".format(plugin_name))


    @classmethod
    def refresh_zynapi_instance(cls):
        if cls.zynapi_instance:
            zynthian_lv2.generate_plugin_presets_cache(cls.zynapi_instance.plugin_url)
            plugin_name = cls.zynapi_instance.plugin_name
            plugin_type = cls.zynapi_instance.type
            cls.zynapi_instance.stop()
            cls.zynapi_instance = cls(plugin_name, plugin_type, None, True)


    @classmethod
    def zynapi_get_banks(cls):
        banks=[]
        for b in cls.zynapi_instance.get_bank_list():
            banks.append({
                'text': b[2],
                'name': b[2],
                'fullpath': b[0],
                'raw': b,
                'readonly': False if not b[0] or b[0].startswith("file:///") else True
            })
        return banks


    @classmethod
    def zynapi_get_presets(cls, bank):
        presets=[]
        for p in cls.zynapi_instance.get_preset_list(bank['raw']):
            presets.append({
                'text': p[2],
                'name': p[2],
                'fullpath': p[0],
                'raw': p,
                'readonly': False if not p[0] or p[0].startswith("file:///") else True
            })
        return presets


    @classmethod
    def zynapi_rename_bank(cls, bank_path, new_bank_name):
        if bank_path.startswith("file:///"):
            cls.lv2_rename_bank(bank_path, new_bank_name)
            cls.refresh_zynapi_instance()
        else:
            raise Exception("Bank is read-only!")


    @classmethod
    def zynapi_remove_bank(cls, bank_path):
        if bank_path.startswith("file:///"):
            bundle_path, bank_name = os.path.split(bank_path)
            bundle_path = bundle_path[7:]
            shutil.rmtree(bundle_path)
            cls.refresh_zynapi_instance()
        else:
            raise Exception("Bank is read-only")


    @classmethod
    def zynapi_rename_preset(cls, preset_path, new_preset_name):
        if preset_path.startswith("file:///"):
            cls.lv2_rename_preset(preset_path, new_preset_name)
            cls.refresh_zynapi_instance()
        else:
            raise Exception("Preset is read-only!")


    @classmethod
    def zynapi_remove_preset(cls, preset_path):
        if preset_path.startswith("file:///"):
            cls.lv2_remove_preset(preset_path)
            cls.refresh_zynapi_instance()
        else:
            raise Exception("Preset is read-only")


    @classmethod
    def zynapi_download(cls, fullpath):
        if fullpath.startswith("file:///"):
            bundle_path, bank_name = os.path.split(fullpath)
            bundle_path = bundle_path[7:]
            return bundle_path
        else:
            raise Exception("Bank is not downloadable!")


    @classmethod
    def zynapi_install(cls, dpath, bank_path):
        fname, ext = os.path.splitext(dpath)
        native_ext = cls.zynapi_get_native_ext()

        # Try to copy LV2 bundles ...
        if os.path.isdir(dpath):
            # Find manifest.ttl
            manifest_files = check_output("find \"{}\" -type f -iname manifest.ttl".format(dpath), shell=True).decode("utf-8").split("\n")
            # Copy LV2 bundle directories to destiny ...
            count = 0
            for f in manifest_files:
                bpath, fname = os.path.split(f)
                head, bname = os.path.split(bpath)
                if bname:
                    shutil.rmtree(zynthian_engine.my_data_dir + "/presets/lv2/" + bname, ignore_errors=True)
                    shutil.move(bpath, zynthian_engine.my_data_dir + "/presets/lv2/")
                    count += 1
            if count>0:
                cls.refresh_zynapi_instance()
                return

        # Else, try to convert from native format ...
        if os.path.isdir(dpath) or ext[1:].lower()==native_ext:
            preset2lv2_cmd = "cd /tmp; /usr/local/bin/preset2lv2 {} \"{}\"".format(cls.zynapi_get_preset2lv2_format(), dpath)
            try:
                res = check_output(preset2lv2_cmd, stderr=STDOUT, shell=True).decode("utf-8")
                for bname in re.compile("Bundle '(.*)' generated").findall(res):
                    bpath = "/tmp/" + bname
                    logging.debug("Copying LV2-Bundle '{}' ...".format(bpath))
                    shutil.rmtree(zynthian_engine.my_data_dir + "/presets/lv2/" + bname, ignore_errors=True)
                    shutil.move(bpath, zynthian_engine.my_data_dir + "/presets/lv2/")

                cls.refresh_zynapi_instance()

            except Exception as e:
                raise Exception("Conversion from {} to LV2 failed! => {}".format(native_ext, e))

        else:
            raise Exception("Unknown preset format: {}".format(native_ext))


    @classmethod
    def zynapi_get_formats(cls):
        formats = "zip,tgz,tar.gz,tar.bz2"
        fmt = cls.zynapi_get_native_ext()
        if fmt:
            formats = fmt + "," + formats

        return formats


    @classmethod
    def zynapi_martifact_formats(cls):
        fmt = cls.zynapi_get_native_ext()
        if fmt:
            return fmt
        else:
            return "lv2"


    @classmethod
    def zynapi_get_native_ext(cls):
        try:
            return cls.plugin2native_ext[cls.zynapi_instance.plugin_name]
        except:
            return None


    @classmethod
    def zynapi_get_preset2lv2_format(cls):
        try:
            return cls.plugin2preset2lv2_format[cls.zynapi_instance.plugin_name]
        except:
            return None


    #--------------------------------------------------------------------------
    # LV2 Bundle TTL file manipulations
    #--------------------------------------------------------------------------

    @staticmethod
    def ttl_read_parts(fpath):
        with open(fpath, 'r') as f:
            data = f.read()
            parts = data.split(".\n")
            f.close()
            return parts


    @staticmethod
    def ttl_write_parts(fpath, parts):
        with open(fpath, 'w') as f:
            data = ".\n".join(parts)
            f.write(data)
            #logging.debug(data)
            f.close()


    @staticmethod
    def lv2_rename_bank(bank_path, new_bank_name):
        bank_path = bank_path[7:]
        bundle_path, bank_dname = os.path.split(bank_path)

        man_fpath = bundle_path + "/manifest.ttl"
        parts = zynthian_engine_jalv.ttl_read_parts(man_fpath)

        bmre1 = re.compile(r"<{}>".format(bank_dname))
        bmre2 = re.compile(r"(.*)a pset:Bank ;")
        brre = re.compile(r"([\s]+rdfs:label[\s]+\").*(\" )")
        for i,p in enumerate(parts):
            if bmre1.search(p) and bmre2.search(p):
                new_bank_name = zynthian_engine_jalv.sanitize_text(new_bank_name)
                parts[i] = brre.sub(lambda m: m.group(1)+new_bank_name+m.group(2), p)
                zynthian_engine_jalv.ttl_write_parts(man_fpath, parts)
                return

        raise Exception("Format doesn't match!")


    @staticmethod
    def lv2_rename_preset(preset_path, new_preset_name):
        preset_path = preset_path[7:]
        bundle_path, preset_fname = os.path.split(preset_path)

        man_fpath = bundle_path + "/manifest.ttl"
        man_parts = zynthian_engine_jalv.ttl_read_parts(man_fpath)
        prs_parts = zynthian_engine_jalv.ttl_read_parts(preset_path)

        bmre1 = re.compile(r"<{}>".format(preset_fname))
        bmre2 = re.compile(r"(.*)a pset:Preset ;")
        brre = re.compile("([\s]+rdfs:label[\s]+\").*(\" )")

        renamed = False
        for i,p in enumerate(man_parts):
            if bmre1.search(p) and bmre2.search(p):
                new_preset_name = zynthian_engine_jalv.sanitize_text(new_preset_name)
                man_parts[i] = brre.sub(lambda m: m.group(1) + new_preset_name + m.group(2), p)
                zynthian_engine_jalv.ttl_write_parts(man_fpath, man_parts)
                renamed = True

        for i,p in enumerate(prs_parts):
            if bmre2.search(p):
                new_preset_name = zynthian_engine_jalv.sanitize_text(new_preset_name)
                prs_parts[i] = brre.sub(lambda m: m.group(1) + new_preset_name + m.group(2), p)
                zynthian_engine_jalv.ttl_write_parts(preset_path, prs_parts)
                renamed = True

        if not renamed:
            raise Exception("Format doesn't match!")


    @staticmethod
    def lv2_remove_preset(preset_path):
        preset_path = preset_path[7:]
        bundle_path, preset_fname = os.path.split(preset_path)

        man_fpath = bundle_path + "/manifest.ttl"
        parts = zynthian_engine_jalv.ttl_read_parts(man_fpath)

        bmre1 = re.compile(r"<{}>".format(preset_fname))
        bmre2 = re.compile(r"(.*)a pset:Preset ;")
        for i,p in enumerate(parts):
            if bmre1.search(p) and bmre2.search(p):
                del parts[i]
                zynthian_engine_jalv.ttl_write_parts(man_fpath, parts)
                os.remove(preset_path)
                return

        raise Exception("Format doesn't match!")


    @staticmethod
    def sanitize_text(text):
        # Remove bad chars
        bad_chars = ['.', ',', ';', ':', '!', '*', '+', '?', '@', '&', '$', '%', '=', '"', '\'', '`', '/', '\\', '^', '<', '>', '[', ']', '(', ')', '{', '}']
        for i in bad_chars:
            text = text.replace(i, ' ')

        # Strip and replace (multi)spaces by single underscore
        text = '_'.join(text.split())
        text = '_'.join(filter(None,text.split('_')))

        return text


#******************************************************************************
