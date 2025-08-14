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
import json
import os
import re
import logging
import requests
import zynconf
from collections import OrderedDict
from subprocess import check_output
from PySide2.QtCore import QObject, Property, Signal, Slot
from . import zynthian_qt_gui_base


class country_detail(QObject):
    def __init__(self, index, country_code, country_name, parent):
        super(country_detail, self).__init__(parent)
        self.__index = index
        self.__country_code = country_code
        self.__country_name = country_name

    def get_index(self):
        return self.__index
    def get_countryCode(self):
        return self.__country_code
    def get_countryName(self):
        return self.__country_name

    index = Property(int, get_index, constant=True)
    countryCode = Property(str, get_countryCode, constant=True)
    countryName = Property(str, get_countryName, constant=True)


class zynthian_gui_wifi_settings(zynthian_qt_gui_base.zynqtgui):
    wpa_supplicant_config_fpath = os.environ.get('ZYNTHIAN_CONFIG_DIR', "/zynthian/config") + "/wpa_supplicant.conf"

    def __init__(self, parent=None):
        super(zynthian_gui_wifi_settings, self).__init__(parent)

        # Dict of available networks in the format :
        # { 'ssid': { "enctyption": <bool>, quality: <int>, signalLevel: <string> }, ... }
        self.available_wifi_networks = {}
        # Dict of saved networks in the format :
        # { 'ssid': { 'password': <string> }, ... }
        savedNetworks = self.zynqtgui.global_settings.value("WifiSettings/savedNetworks", None)
        if savedNetworks is None:
            self.saved_wifi_networks = {}
        else:
            self.saved_wifi_networks = json.loads(base64.b64decode(savedNetworks).decode("utf-8"))

        selected_country_code = self.zynqtgui.global_settings.value("WifiSettings/country", "DE")
        self.selected_country_detail = None
        self.country_details = []
        with open("/zynthian/zynthbox-qml/config/ISO3166-1.alpha2.json", "r") as f:
            country_codes = json.load(f)
            for id, country_code in enumerate(country_codes):
                detail = country_detail(id, country_code, country_codes[country_code], self)
                self.country_details.append(detail)
                # Set selected country object
                if country_code == selected_country_code:
                    self.selected_country_detail = detail
            self.country_details = sorted(self.country_details, key=lambda x: x.countryName.casefold())
            # If no country was selected, set the first country as default
            if self.selected_country_detail is None:
                self.selected_country_detail = self.country_details[0]

        # Restore previous wifi state
        self.set_wifiMode(self.zynqtgui.global_settings.value("WifiSettings/state", "off"), showLoadingScreen=False)

    def show(self):
        pass

    @staticmethod
    def generate_wpa_supplicant_conf(country, ssid, password):
        with open(zynthian_gui_wifi_settings.wpa_supplicant_config_fpath, "w") as f:
            f.write(f"country={country}\n")
            f.write("ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev\n")
            f.write("update_config=1\n")
            f.write("\n")
            f.write("network={\n")
            f.write(f"  ssid=\"{ssid}\"\n")
            f.write(f"  psk=\"{password}\"\n")
            f.write("}\n")

    def update_available_wifi_networks_list(self):
        wifiList = OrderedDict()

        try:
            for interface_byte in check_output("ifconfig -a | sed 's/[ \t].*//;/^$/d'", shell=True).splitlines():
                interface = interface_byte.decode("utf-8")

                if interface.startswith("wlan"):
                    if interface[-1:] == ":":
                        interface = interface[:-1]
                    logging.debug("Scanning wifi networks on {}...".format(interface))
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
                            ssid = line.split(':')[1].replace("\"", "")
                            if ssid:
                                wifiList[ssid] = {
                                    "encryption": encryption,
                                    "quality": quality,
                                    "signalLevel": signal_level
                                }
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

        self.available_wifi_networks = wifiList
        self.availableWifiNetworksModelChanged.emit()
        self.savedWifiNetworksModelChanged.emit()

    def addToSavedNetworks(self, ssid, password):
        if ssid not in self.saved_wifi_networks or (self.saved_wifi_networks[ssid]["password"] != password):
            self.saved_wifi_networks[ssid] = { "password": password }
            savedNetworksBytearray = json.dumps(self.saved_wifi_networks).encode("utf-8")
            self.zynqtgui.global_settings.setValue("WifiSettings/savedNetworks", base64.b64encode(savedNetworksBytearray).decode("utf-8"))
            self.availableWifiNetworksModelChanged.emit()
            self.savedWifiNetworksModelChanged.emit()

    def startWifi(self):
        if not zynconf.start_wifi():
            logging.error("Can't start WIFI network!")
            return False
        else:
            try:
                logging.debug("## WifiCheck : Making a request to networkcheck.kde.org to determine if wifi has a captive network")
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

    ### Property wifiMode
    def get_wifiMode(self):
        return zynconf.get_current_wifi_mode()

    def set_wifiMode(self, mode, message=None, showLoadingScreen=True):
        def task():
            result = False
            try:
                if mode == "on":
                    if showLoadingScreen:
                        self.zynqtgui.currentTaskMessage = "Attempting to connect to wifi"
                    result = self.startWifi()
                elif mode == "hotspot":
                    result = self.startHotspot()
                elif mode == "off":
                    if showLoadingScreen:
                        self.zynqtgui.currentTaskMessage = "Turning off wifi"
                    result = self.stopWifi()
                else:
                    # Do nothing if wifi mode is none of the above handled ones
                    pass
            except Exception as e:
                logging.error(f"Error setting wifi mode : {str(e)}")

            self.wifiModeChanged.emit()
            if showLoadingScreen:
                self.zynqtgui.end_long_task()
            # Save state if mode change was successful
            if result:
                self.zynqtgui.global_settings.setValue("WifiSettings/state", mode)
                self.connectedNetworkSsidChanged.emit()
                self.connectedNetworkIpChanged.emit()
            return result

        if showLoadingScreen:
            if message is None:
                self.zynqtgui.do_long_task(task, f"Setting wifi mode to {mode}")
            else:
                self.zynqtgui.do_long_task(task, message)
        else:
            return task()

    wifiModeChanged = Signal()

    wifiMode = Property(str, get_wifiMode, set_wifiMode, notify=wifiModeChanged)
    ### End Property wifiMode

    ### Property availableWifiNetworksModel
    def get_availableWifiNetworksModel(self):
        availableNetworksModel = []
        for ssid in self.available_wifi_networks:
            if ssid not in self.saved_wifi_networks:
                availableNetworksModel.append({
                    "ssid": ssid,
                    **self.available_wifi_networks[ssid]
                })
        return availableNetworksModel

    availableWifiNetworksModelChanged = Signal()

    availableWifiNetworksModel = Property('QVariantList', get_availableWifiNetworksModel, notify=availableWifiNetworksModelChanged)
    ### END Property availableWifiNetworks

    ### Property savedWifiNetworksModel
    def get_savedWifiNetworksModel(self):
        savedNetworksModel = []
        for ssid in self.saved_wifi_networks:
            savedNetworksModel.append({
                "ssid": ssid,
                "quality": self.available_wifi_networks[ssid]["quality"] if ssid in self.available_wifi_networks else -1,
                **self.saved_wifi_networks[ssid]
            })
        savedNetworksModel = sorted(savedNetworksModel, key=lambda x: x['quality'], reverse=True)
        return savedNetworksModel

    savedWifiNetworksModelChanged = Signal()

    savedWifiNetworksModel = Property('QVariantList', get_savedWifiNetworksModel, notify=savedWifiNetworksModelChanged)
    ### END Property savedWifiNetworks

    ### Property connectedNetworkSsid
    def get_connectedNetworkSsid(self):
        ssid = None
        for line_byte in check_output("iwconfig", shell=True).splitlines():
            line = line_byte.decode("utf-8")
            if line.find('ESSID') >= 0:
                matchResult = re.match('.*ESSID:"(.*)"', line, re.M | re.I)
                if matchResult:
                    ssid = matchResult.group(1)
                break
        return ssid

    connectedNetworkSsidChanged = Signal()

    connectedNetworkSsid = Property(str, get_connectedNetworkSsid, notify=connectedNetworkSsidChanged)
    ### END Property connectedNetworkSsid

    ### Property connectedNetworkIp
    def get_connectedNetworkIp(self):
        ip = ""
        if self.wifiMode == "on":
            for line_byte in check_output("ip -f inet addr show wlan0", shell=True).splitlines():
                line = line_byte.decode("utf-8")
                if line.find('inet ') >= 0:
                    matchResult = re.match('.*inet (.*)\/', line, re.M | re.I)
                    if matchResult:
                        ip = matchResult.group(1)
                    break
        return ip

    connectedNetworkIpChanged = Signal()

    connectedNetworkIp = Property(str, get_connectedNetworkIp, notify=connectedNetworkIpChanged)
    ### END Property connectedNetworkIp

    ### Property selectedCountryDetail
    def get_selectedCountryDetail(self):
        return self.selected_country_detail

    def set_selectedCountryDetail(self, value):
        if value != self.selected_country_detail:
            self.selected_country_detail = value
            self.zynqtgui.global_settings.setValue("WifiSettings/country", value.countryCode)
            self.selectedCountryDetailChanged.emit()

    selectedCountryDetailChanged = Signal()

    selectedCountryDetail = Property(QObject, get_selectedCountryDetail, set_selectedCountryDetail, notify=selectedCountryDetailChanged)
    ### END Property selectedCountryDetail

    ### Property countryDetailsModel
    def get_countryDetailsModel(self):
        return self.country_details

    countryDetailsModel = Property('QVariantList', get_countryDetailsModel, constant=True)
    ### END Property countryDetailsModel

    @Slot(None)
    def reloadLists(self):
        def task():
            self.update_available_wifi_networks_list()
            self.zynqtgui.end_long_task()
        self.zynqtgui.do_long_task(task, "Searching for wifi networks...")

    @Slot(str, str)
    def connectNewNetwork(self, ssid, password):
        self.addToSavedNetworks(ssid, password)
        self.connectSavedNetwork(ssid)

    @Slot(str)
    def connectSavedNetwork(self, ssid):
        def task():
            self.generate_wpa_supplicant_conf(self.selectedCountryDetail.countryCode, ssid, self.saved_wifi_networks[ssid]["password"])
            self.set_wifiMode("on", showLoadingScreen=False)
            self.zynqtgui.end_long_task()
        self.zynqtgui.do_long_task(task, f"Attempting to connect to wifi : {ssid}")

    @Slot(str)
    def removeSavedNetwork(self, ssid):
        # TODO
        if ssid in self.saved_wifi_networks:
            if self.connectedNetworkSsid == ssid:
                self.set_wifiMode("off")
            del self.saved_wifi_networks[ssid]
            self.availableWifiNetworksModelChanged.emit()
            self.savedWifiNetworksModelChanged.emit()

    openCaptivePortal = Signal(str)
