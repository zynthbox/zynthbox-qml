# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian Engine (zynthian_engine_jucy)
#
# zynthian_engine implementation for Jucy Plugin Host for VST3 plugin hosting
#
# Copyright (C) 2024 Anupam Basak <anupam.basak27@gmail.com>
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
import re
import Jucy
import os
import json
from collections import OrderedDict
from pathlib import Path
from PySide2.QtCore import QTimer

from . import zynthian_engine
from . import zynthian_controller
from . import zynthian_vst3


def get_jucy_plugins():
    plugins_json_file = Path(f"{os.environ.get('ZYNTHIAN_CONFIG_DIR')}/jucy/plugins.json")
    if zynthian_engine_jucy.plugins_dict is None:
        if not plugins_json_file.exists():
            zynthian_vst3.generate_jucy_plugins_json_cache()
        with open(plugins_json_file, "r") as f:
            zynthian_engine_jucy.plugins_dict = json.load(f)
    return zynthian_engine_jucy.plugins_dict


class zynthian_engine_jucy(zynthian_engine):
    plugins_dict = None

    def __init__(self, plugin_name, plugin_type, zynqtgui=None):
        super().__init__(zynqtgui)

        self.type = plugin_type
        self.name = "Jucy/" + plugin_name
        self.nickname = "JY/" + plugin_name
        self.plugin_name = plugin_name
        # # TODO : Populate plugins dict
        self.plugin_url = self.plugins_dict[plugin_name]['URL']
        self.jackname = self.get_jucy_jackname()
        self.jucy_pluginhost = Jucy.VST3PluginHost(self.plugin_url, self.jackname, self)
        self._ctrl_screens = []
        self.bank_list = []
        self.start()

        # Get bank & presets info
        self.bank_list.append(("", None, "", None))
        self.preset_info = self.get_plugin_presets()

        # Generate Plugin Controllers
        self.update_controllers_timer = QTimer()
        self.update_controllers_timer.setInterval(100)
        self.update_controllers_timer.setSingleShot(True)
        self.update_controllers_timer.timeout.connect(self.update_controllers)
        self.update_controllers()

        self.reset()

    def start(self):
        self.jucy_pluginhost.loadPlugin()

    def stop(self):
        self.jucy_pluginhost.unloadPlugin()

    # Jack, when listing ports, accepts regular expressions as the jack name.
    # So, for avoiding problems, jack names shouldn't contain regex characters.
    def get_jucy_jackname(self):
        try:
            jname = re.sub("[\_]{2,}","_",re.sub("[\'\*\(\)\[\]\s]","_",self.plugin_name))
            jname_count = self.zynqtgui.screens['layer'].get_jackname_count(jname)
        except:
            jname_count = 0

        return "{}-{:02d}".format(jname, jname_count)

    def update_controllers(self):
        self.pluginhost_parameters_dict = {}
        self.generate_vst3_controllers_dict()
        self.generate_ctrl_screens(self.vst3_zctrl_dict)
        if len(self.layers) > 0:
            self.layers[0].refresh_controllers()

    # ---------------------------------------------------------------------------
    # Layer Management
    # ---------------------------------------------------------------------------

    def add_layer(self, layer):
        super().add_layer(layer)

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

    def get_plugin_presets(self):
        return {
            "": {
                "bank_url" : None,
                "presets": self.jucy_pluginhost.getAllPresets()
            }
        }

    def get_preset_list(self, bank):
        preset_list = []
        try:
            for info in  self.preset_info[bank[2]]['presets']:
                preset_list.append([info, None, info, bank[0]])
        except:
            preset_list.append(("", None, "", None))

        return preset_list


    def set_preset(self, layer, preset, preload=False):
        if not preset[0]:
            return False
        logging.debug(f"Setting preset {preset[0]}")
        self.jucy_pluginhost.setCurrentPreset(preset[0])
        self.update_controllers_timer.start()
        return True


    def cmp_presets(self, preset1, preset2):
        try:
            if preset1[0] == preset2[0]:
                return True
            else:
                return False
        except:
            return False

    #----------------------------------------------------------------------------
    # Controllers Managament
    #----------------------------------------------------------------------------

    def generate_vst3_controllers_dict(self):
        zctrls = OrderedDict()
        for index, parameter in enumerate(self.jucy_pluginhost.getAllParameters()):
            self.pluginhost_parameters_dict[parameter.getName()] = parameter

            if type(parameter) == Jucy.StringParameter:
                # Controller value is a set of string
                zctrls[parameter.getName()] = zynthian_controller(self, parameter.getName(), parameter.getName(), {
                    'group_symbol': "ctrl",
                    'group_name': "Ctrl",
                    'graph_path': index,
                    'value': parameter.getValue(),
                    'labels': parameter.getAllValueStrings(),
                    'ticks': parameter.getAllValues(),
                    'value_min': 0.0,
                    'value_max': 1.0,
                    'is_toggle': False,
                    'is_integer': False
                })

            elif type(parameter) == Jucy.BooleanParameter:
                # Controller value is a boolean
                zctrls[parameter.getName()] = zynthian_controller(self, parameter.getName(), parameter.getName(), {
                    'group_symbol': "ctrl",
                    'group_name': "Ctrl",
                    'graph_path': index,
                    'value': parameter.getValue(),
                    'labels': ["Off", "On"],
                    'ticks': [0.0, 1.0],
                    'value_min': 0.0,
                    'value_max': 1.0,
                    'is_toggle': True,
                    'is_integer': False
                })
            elif type(parameter) == Jucy.Parameter:
                # Controller value is normalized float from 0.0 to 1.0
                zctrls[parameter.getName()] = zynthian_controller(self, parameter.getName(), parameter.getName(), {
                    'group_symbol': "ctrl",
                    'group_name': "Ctrl",
                    'graph_path': index,
                    'value': parameter.getValue(),
                    'value_min': 0.0,
                    'value_max': 1.0,
                    'is_toggle': False,
                    'is_integer': False
                })
            else:
                # Controller type is unknown. Handle accordingly
                logging.debug("Unknown controller type. Handle accordingly")
        self.vst3_zctrl_dict = zctrls


    def get_ctrl_screen_name(self, gname, i):
        if i>0:
            gname = "{}#{}".format(gname, i)
        return gname

    def generate_ctrl_screens(self, zctrl_dict=None):
        if zctrl_dict is None:
            zctrl_dict=self.vst3_zctrl_dict

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
        # # Add plugin native controllers
        zctrls.update(self.vst3_zctrl_dict)
        return zctrls

    def send_controller_value(self, zctrl):
        self.pluginhost_parameters_dict[zctrl.name].setValue(zctrl.value)


#******************************************************************************
