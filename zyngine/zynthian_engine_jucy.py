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

import re
import Jucy
from collections import OrderedDict

from . import zynthian_engine
from . import zynthian_controller

class zynthian_engine_jucy(zynthian_engine):
    plugins_dict = OrderedDict([
        ("AirWindows", {'TYPE': "Audio Effect", 'CLASS': "VST3 FX", 'URL': "/zynthian/airwin2rack/build/awcons-products/Airwindows Consolidated.vst3"}),
        ("Nekobi", {'TYPE': "MIDI Synth", 'CLASS': "VST3 Instrument", 'URL': "/usr/lib/vst3/Nekobi.vst3"}),
    ])

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

        # # Generate LV2-Plugin Controllers
        self.vst3_zctrl_dict = self.get_vst3_controllers_dict()
        self.generate_ctrl_screens(self.vst3_zctrl_dict)

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

    # ---------------------------------------------------------------------------
    # Layer Management
    # ---------------------------------------------------------------------------

    def add_layer(self, layer):
        super().add_layer(layer)

    #----------------------------------------------------------------------------
    # Bank Managament
    #----------------------------------------------------------------------------

    def get_bank_list(self, layer=None):
        # TODO
        return self.bank_list

    def set_bank(self, layer, bank):
        # TODO
        return True

    #----------------------------------------------------------------------------
    # Preset Managament
    #----------------------------------------------------------------------------

    def get_plugin_presets(self):
        # TODO
        pass

    def get_preset_list(self, bank):
        # TODO
        preset_list = []
        # try:
        #     for info in  self.preset_info[bank[2]]['presets']:
        #         preset_list.append([info['url'], None, info['label'], bank[0]])
        # except:
        #     preset_list.append(("", None, "", None))

        return preset_list


    def set_preset(self, layer, preset, preload=False):
        # TODO
        # if not preset[0]:
        #     return
        # output=self.proc_cmd("preset {}".format(preset[0]), wait_for_output=True)

        # #Parse new controller values
        # for line in output.split("\n"):
        #     try:
        #         parts=line.split(" = ")
        #         if len(parts)==2:
        #             self.lv2_zctrl_dict[parts[0]]._set_value(float(parts[1]))
        #     except Exception as e:
        #         # logging.debug(e)
        #         pass

        # return True
        pass


    def cmp_presets(self, preset1, preset2):
        # TODO
        # try:
        #     if preset1[0]==preset2[0]:
        #         return True
        #     else:
        #         return False
        # except:
        #     return False
        pass

    #----------------------------------------------------------------------------
    # Controllers Managament
    #----------------------------------------------------------------------------

    def get_vst3_controllers_dict(self):
        # TODO
        zctrls = OrderedDict()
        # for i, info in zynthian_lv2.get_plugin_ports(self.plugin_url).items():
        #     symbol = info['symbol']
        #     #logging.debug("Controller {} info =>\n{}!".format(symbol, info))
        #     try:
        #         #If there is points info ...
        #         if len(info['scale_points'])>1:
        #             labels = []
        #             values = []
        #             for p in info['scale_points']:
        #                 labels.append(p['label'])
        #                 values.append(p['value'])

        #             zctrls[symbol] = zynthian_controller(self, symbol, info['name'], {
        #                 'group_symbol': info['group_symbol'],
        #                 'group_name': info['group_name'],
        #                 'graph_path': info['index'],
        #                 'value': info['value'],
        #                 'labels': labels,
        #                 'ticks': values,
        #                 'value_min': values[0],
        #                 'value_max': values[-1],
        #                 'is_toggle': info['is_toggled'],
        #                 'is_integer': info['is_integer']
        #             })

        #         #If it's a numeric controller ...
        #         else:
        #             r = info['range']['max'] - info['range']['min']
        #             if info['is_integer']:
        #                 if info['is_toggled']:
        #                     if info['value']==0:
        #                         val = 'off'
        #                     else:
        #                         val = 'on'

        #                     zctrls[symbol] = zynthian_controller(self, symbol, info['name'], {
        #                         'group_symbol': info['group_symbol'],
        #                         'group_name': info['group_name'],
        #                         'graph_path': info['index'],
        #                         'value': val,
        #                         'labels': ['off','on'],
        #                         'ticks': [int(info['range']['min']), int(info['range']['max'])],
        #                         'value_min': int(info['range']['min']),
        #                         'value_max': int(info['range']['max']),
        #                         'is_toggle': True,
        #                         'is_integer': True
        #                     })
        #                 else:
        #                     zctrls[symbol] = zynthian_controller(self, symbol, info['name'], {
        #                         'group_symbol': info['group_symbol'],
        #                         'group_name': info['group_name'],
        #                         'graph_path': info['index'],
        #                         'value': int(info['value']),
        #                         'value_default': int(info['range']['default']),
        #                         'value_min': int(info['range']['min']),
        #                         'value_max': int(info['range']['max']),
        #                         'is_toggle': False,
        #                         'is_integer': True,
        #                         'is_logarithmic': info['is_logarithmic']
        #                     })
        #             else:
        #                 if info['is_toggled']:
        #                     if info['value']==0:
        #                         val = 'off'
        #                     else:
        #                         val = 'on'

        #                     zctrls[symbol] = zynthian_controller(self, symbol, info['name'], {
        #                         'group_symbol': info['group_symbol'],
        #                         'group_name': info['group_name'],
        #                         'graph_path': info['index'],
        #                         'value': val,
        #                         'labels': ['off','on'],
        #                         'ticks': [info['range']['min'], info['range']['max']],
        #                         'value_min': info['range']['min'],
        #                         'value_max': info['range']['max'],
        #                         'is_toggle': True,
        #                         'is_integer': False
        #                     })
        #                 else:
        #                     zctrls[symbol] = zynthian_controller(self, symbol, info['name'], {
        #                         'group_symbol': info['group_symbol'],
        #                         'group_name': info['group_name'],
        #                         'graph_path': info['index'],
        #                         'value': info['value'],
        #                         'value_default': info['range']['default'],
        #                         'value_min': info['range']['min'],
        #                         'value_max': info['range']['max'],
        #                         'is_toggle': False,
        #                         'is_integer': False,
        #                         'is_logarithmic': info['is_logarithmic']
        #                     })

        #     #If control info is not OK
        #     except Exception as e:
        #         logging.error(e)
        return zctrls


    def get_ctrl_screen_name(self, gname, i):
        # TODO
        # if i>0:
        #     gname = "{}#{}".format(gname, i)
        # return gname
        return ""

    def generate_ctrl_screens(self, zctrl_dict=None):
        # TODO
        # if zctrl_dict is None:
        #     zctrl_dict=self.zctrl_dict

        # # Get zctrls by group
        # zctrl_group = OrderedDict()
        # for symbol, zctrl in zctrl_dict.items():
        #     gsymbol = zctrl.group_symbol
        #     if gsymbol is None:
        #         gsymbol = "_"
        #     if gsymbol not in zctrl_group:
        #         zctrl_group[gsymbol] = [zctrl.group_name, OrderedDict()]
        #     zctrl_group[gsymbol][1][symbol] = zctrl
        # if "_" in zctrl_group:
        #     last_group = zctrl_group["_"]
        #     del zctrl_group["_"]
        #     if len(zctrl_group)==0:
        #         last_group[0] = "Ctrls"
        #     else:
        #         last_group[0] = "Ungroup"
        #     zctrl_group["_"] = last_group

        # for gsymbol, gdata in zctrl_group.items():
        #     ctrl_set=[]
        #     gname = gdata[0]
        #     if len(gdata[1])<=4:
        #         c=0
        #     else:
        #         c=1
        #     for symbol, zctrl in gdata[1].items():
        #         try:
        #             #logging.debug("CTRL {}".format(symbol))
        #             ctrl_set.append(symbol)
        #             if len(ctrl_set)>=4:
        #                 #logging.debug("ADDING CONTROLLER SCREEN {}".format(self.get_ctrl_screen_name(gname,c)))
        #                 self._ctrl_screens.append([self.get_ctrl_screen_name(gname,c),ctrl_set])
        #                 ctrl_set=[]
        #                 c=c+1
        #         except Exception as err:
        #             logging.error("Generating Controller Screens => {}".format(err))

        #     if len(ctrl_set)>=1:
        #         #logging.debug("ADDING CONTROLLER SCREEN {}",format(self.get_ctrl_screen_name(gname,c)))
        #         self._ctrl_screens.append([self.get_ctrl_screen_name(gname,c),ctrl_set])
        pass

    def get_controllers_dict(self, layer):
        # TODO
        # Get plugin static controllers
        zctrls=super().get_controllers_dict(layer)
        # # Add plugin native controllers
        # zctrls.update(self.lv2_zctrl_dict)
        return zctrls

    def send_controller_value(self, zctrl):
        # TODO
        # self.proc_cmd("set %d %.6f" % (zctrl.graph_path, zctrl.value))
        pass


#******************************************************************************
