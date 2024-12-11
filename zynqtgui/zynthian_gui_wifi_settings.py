#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthian WIFI Settings : A page to display and configure wifi connections
#
# Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
#
# ******************************************************************************
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
# ******************************************************************************
import base64
import os
import re
from collections import OrderedDict
from subprocess import check_output

import requests
from PySide2.QtCore import Property, QTimer, Signal, Slot

import logging

import zynconf
import zyngine
from . import zynthian_qt_gui_base

from zyncoder import *


class zynthian_gui_wifi_settings(zynthian_qt_gui_base.zynqtgui):
    def __init__(self, parent=None):
        super(zynthian_gui_wifi_settings, self).__init__(parent)
        self.wpa_supplicant_config_fpath = os.environ.get('ZYNTHIAN_CONFIG_DIR', "/zynthian/config") + "/wpa_supplicant.conf"

        self.available_wifi_networks = []
        self.saved_wifi_networks = []

    def show(self):
        pass

    def zyncoder_read(self):
        pass

    def refresh_loading(self):
        pass

    @Slot(None)
    def reloadLists(self):
        def task():
            self.update_saved_wifi_networks_list()
            self.update_available_wifi_networks_list()
            self.wifiModeChanged.emit()
            self.zynqtgui.end_long_task()

        self.zynqtgui.do_long_task(task, "Searching for wifi networks...")

    ### BELOW METHODS ARE DERIVED FROM WEBCONF wifi_config_handler.py
    def update_available_wifi_networks_list(self):
        wifiList = OrderedDict()
        saved_wifi_ssids = [x["ssid"] for x in self.saved_wifi_networks]

        try:
            for interface_byte in check_output("ifconfig -a | sed 's/[ \t].*//;/^$/d'", shell=True).splitlines():
                interface = interface_byte.decode("utf-8")

                if interface.startswith("wlan"):
                    if interface[-1:] == ":":
                        interface = interface[:-1]

                    logging.error("Scanning wifi networks on {}...".format(interface))

                    network = None
                    ssid = None
                    encryption = False
                    quality = 0
                    signal_level = 0

                    check_output(f"ifconfig {interface} up", shell=True)

                    for line_byte in check_output(
                            "iwlist {0} scan | grep -e ESSID -e Encryption -e Quality".format(interface),
                            shell=True).splitlines():
                        line = line_byte.decode("utf-8")
                        if line.find('ESSID') >= 0:
                            network = {'encryption': False, 'quality': 0, 'signalLevel': 0}
                            ssid = line.split(':')[1].replace("\"", "")
                            if ssid and ssid not in saved_wifi_ssids:
                                self.add_network(wifiList, ssid, network, encryption, quality, signal_level)
                                logging.error("Found Network: %s" % ssid)
                                encryption = False
                            quality = 0
                            signal_level = 0
                        elif line.find('Encryption key:on') >= 0:
                            encryption = True
                        else:
                            m = re.match('.*Quality=(.*?)/(.*?) Signal level=(.*?(100|dBm)).*', line, re.M | re.I)
                            if m:
                                quality = round(int(m.group(1)) / int(m.group(2)) * 100, 2)
                                signal_level = m.group(3)

            wifiList = OrderedDict(sorted(wifiList.items(), key=lambda x: x[1]['quality']))
            wifiList = OrderedDict(reversed(list(wifiList.items())))
        except Exception as e:
            logging.error(e)

        self.available_wifi_networks = [{"ssid": ssid, **values} for ssid, values in wifiList.items()]
        self.availableWifiNetworksChanged.emit()

    def update_saved_wifi_networks_list(self):
        idx = 0
        networks = []
        p = re.compile('.*?network=\\{.*?ssid=\\"(.*?)\\".*?psk=\\"(.*?)\\"\n?(.*?)\\}.*?', re.I | re.M | re.S)
        iterator = p.finditer(self.read_wpa_supplicant_config())
        for m in iterator:
            networks.append({
                'idx': idx,
                'ssid': m.group(1),
                'ssid64': base64.b64encode(m.group(1).encode())[:5],
                'psk': m.group(2),
                'options': m.group(3)
            })
            idx += 1

        self.saved_wifi_networks = networks
        self.savedWifiNetworksChanged.emit()

    def add_network(self, wifiList, ssid, network, encryption, quality, signalLevel):
        network['quality'] = quality
        network['signalLevel'] = signalLevel
        network['encryption'] = encryption
        if ssid in wifiList:
            existingNetwork = wifiList[ssid]
            if existingNetwork:
                if existingNetwork['quality'] < network['quality']:
                    existingNetwork['quality'] = network['quality']
                    existingNetwork['signalLevel'] = network['signalLevel']
            else:
                wifiList.update({ssid: network})
        else:
            wifiList.update({ssid: network})

    def read_wpa_supplicant_config(self):
        try:
            fo = open(self.wpa_supplicant_config_fpath, "r")
            wpa_supplicant_config = "".join(fo.readlines())
            fo.close()
            return wpa_supplicant_config

        except Exception as e:
            logging.error("Can't read WIFI network configuration: {}".format(e))
            return ""

    def save_wpa_supplicant_config(self, data):
        try:
            fo = open(self.wpa_supplicant_config_fpath, "w")
            fo.write(data)
            fo.flush()
            fo.close()

        except Exception as e:
            logging.error("Can't save WIFI network configuration: {}".format(e))

    def add_new_network(self, newSSID, newPassword):
        logging.info("Add Network: {}".format(newSSID))
        wpa_supplicant_data = self.read_wpa_supplicant_config()
        wpa_supplicant_data += '\nnetwork={\n'
        wpa_supplicant_data += '\tssid="{}"\n'.format(newSSID)
        wpa_supplicant_data += '\tpsk="{}"\n'.format(newPassword)
        wpa_supplicant_data += '\tscan_ssid=1\n'
        wpa_supplicant_data += '\tkey_mgmt=WPA-PSK\n'
        wpa_supplicant_data += '\tpriority=10\n'
        wpa_supplicant_data += '}\n'
        self.save_wpa_supplicant_config(wpa_supplicant_data)

    @Slot(str)
    def remove_network(self, delSSID):
        logging.info("Remove Network: {}".format(delSSID))

        wpa_supplicant_data = self.read_wpa_supplicant_config()

        i = wpa_supplicant_data.find("network={")
        wpa_supplicant_header = wpa_supplicant_data[:i]

        p = re.compile('.*?network=\\{.*?ssid=\\"(.*?)\\".*?psk=\\"(.*?)\\"\n?(.*?)\\}.*?', re.I | re.M | re.S)
        iterator = p.finditer(wpa_supplicant_data[i:])

        for m in iterator:
            if m.group(1) != delSSID:
                wpa_supplicant_header += m.group(0)

        self.save_wpa_supplicant_config(wpa_supplicant_header)

    def update_network_options(self, updSSID, options):
        logging.info("Update Network Options: {}".format(updSSID))

        wpa_supplicant_data = self.read_wpa_supplicant_config()

        i = wpa_supplicant_data.find("network={")
        wpa_supplicant_header = wpa_supplicant_data[:i]

        p = re.compile('.*?network=\\{.*?ssid=\\"(.*?)\\".*?psk=\\"(.*?)\\"\n?(.*?)\\}.*?', re.I | re.M | re.S)
        iterator = p.finditer(wpa_supplicant_data[i:])

        for m in iterator:
            if m.group(1) != updSSID:
                wpa_supplicant_header += m.group(0)
            else:
                wpa_supplicant_header += '\nnetwork={\n'
                wpa_supplicant_header += '\tssid="{}"\n'.format(m.group(1))
                wpa_supplicant_header += '\tpsk="{}"\n'.format(m.group(2))
                wpa_supplicant_header += '\t{}\n'.format(options)
                wpa_supplicant_header += '}\n'

        self.save_wpa_supplicant_config(wpa_supplicant_header)
    ### ABOVE METHODS ARE DERIVED FROM WEBCONF wifi_config_handler.py

    def startWifi(self):
        if not zynconf.start_wifi():
            logging.error("Can't start WIFI network!")
            return False
        else:
            try:
                logging.debug(f"## WifiCheck : Making a request to networkcheck.kde.org to determine if wifi has a captive network")
                reply = requests.head("http://networkcheck.kde.org")
                logging.debug(f"## WifiCheck : Reply headers : {reply.headers}")

                # Check if server redirects to some other page when trying to get network check.
                # If there was a redirect, it probably means there is a captive portal. Open the url in a browser
                if "location" in reply.headers and \
                        reply.headers["location"] is not None and \
                        len(reply.headers["location"]) > 0:
                    logging.debug(f"### WifiCheck : There was a redirect when trying to get http://networkcheck.kde.org. There might be a captive portal. Open browser with the url {reply.headers['location']}")
                    self.openCaptivePortal.emit(reply.headers["location"])
            except Exception as e:
                logging.error(f"### WifiCheck : Error trying to determine if wifi network has a captive portal : {str(e)}")

            return True

    def stopWifi(self):
        if not zynconf.stop_wifi():
            logging.error("Can't start WIFI network!")
            return False
        else:
            return True

    def startHotspot(self):
        if not zynconf.start_wifi_hotspot():
            logging.error("Can't start WIFI Hotspot!")
            return False
        else:
            return True

    @Slot(str, str)
    def connect(self, ssid, password):
        logging.error(f"Connect to wifi : {ssid}, {password}")
        self.add_new_network(ssid, password)
        self.set_wifiMode("on", f"Attempting to connect to wifi : {ssid}")

    ### Property wifiMode
    def get_wifiMode(self):
        return zynconf.get_current_wifi_mode()

    def set_wifiMode(self, mode, message=None):
        def task():
            try:
                if mode == "on":
                    self.startWifi()
                elif mode == "hotspot":
                    self.startHotspot()
                elif mode == "off":
                    self.stopWifi()
                else:
                    # Do nothing if wifi mode is none of the above handled ones
                    pass
            except Exception as e:
                logging.error(f"Error setting wifi mode : {str(e)}")

            self.wifiModeChanged.emit()
            self.zynqtgui.end_long_task()

        if message is None:
            self.zynqtgui.do_long_task(task, f"Changing wifi mode to {mode}")
        else:
            self.zynqtgui.do_long_task(task, message)

    wifiModeChanged = Signal()

    wifiMode = Property(str, get_wifiMode, set_wifiMode, notify=wifiModeChanged)
    ### End Property wifiMode

    ### Property availableWifiNetworks
    def get_availableWifiNetworks(self):
        return self.available_wifi_networks

    availableWifiNetworksChanged = Signal()

    availableWifiNetworks = Property('QVariantList', get_availableWifiNetworks, notify=availableWifiNetworksChanged)
    ### END Property availableWifiNetworks

    ### Property savedWifiNetworks
    def get_savedWifiNetworks(self):
        return self.saved_wifi_networks

    savedWifiNetworksChanged = Signal()

    savedWifiNetworks = Property('QVariantList', get_savedWifiNetworks, notify=savedWifiNetworksChanged)
    ### END Property savedWifiNetworks

    openCaptivePortal = Signal(str)
