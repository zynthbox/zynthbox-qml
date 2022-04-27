#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthian GUI Admin Class
#
# Copyright (C) 2015-2016 Fernando Moyano <jofemodo@zynthian.org>
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

import os
import re
import socket
import sys
import signal
import logging
from collections import OrderedDict
from time import sleep
from threading import Thread
from subprocess import check_output, Popen, PIPE, STDOUT

# Zynthian specific modules
from PySide2.QtCore import Property, Signal, Slot

import zynconf
from . import zynthian_gui_config
from . import zynthian_gui_selector

# -------------------------------------------------------------------------------
# Zynthian Admin GUI Class
# -------------------------------------------------------------------------------
class zynthian_gui_network(zynthian_gui_selector):

    data_dir = os.environ.get("ZYNTHIAN_DATA_DIR", "/zynthian/zynthian-data")
    sys_dir = os.environ.get("ZYNTHIAN_SYS_DIR", "/zynthian/zynthian-sys")

    def __init__(self, parent=None):
        super(zynthian_gui_network, self).__init__("Engine", parent)
        self.commands = None
        self.thread = None
        self.child_pid = None
        self.last_action = None

    def fill_list(self):
        self.list_data = []

        self.list_data.append((self.network_info, 0, "Network Info"))

        if zynconf.is_wifi_active():
            if zynconf.is_service_active("hostapd"):
                self.list_data.append((self.stop_wifi, 0, "[x] Wi-Fi Hotspot"))
            else:
                self.list_data.append((self.stop_wifi, 0, "[x] Wi-Fi"))
        else:
            self.list_data.append((self.start_wifi, 0, "[  ] Wi-Fi"))
            self.list_data.append(
                (self.start_wifi_hotspot, 0, "[  ] Wi-Fi Hotspot")
            )

        if zynconf.is_service_active("vncserver@:1"):
            self.list_data.append((self.stop_vncserver, 0, "[x] VNC Server"))
        else:
            self.list_data.append((self.start_vncserver, 0, "[  ] VNC Server"))

        super().fill_list()

    def select_action(self, i, t="S"):
        if self.list_data[i][0]:
            self.last_action = self.list_data[i][0]
            self.last_action()

    def set_select_path(self):
        self.select_path = "Network"
        self.select_path_element = "Network"
        super().set_select_path()

    def execute_commands(self):
        self.zyngui.start_loading()

        error_counter = 0
        for cmd in self.commands:
            logging.info("Executing Command: %s" % cmd)
            self.zyngui.add_info("EXECUTING:\n", "EMPHASIS")
            self.zyngui.add_info("{}\n".format(cmd))
            try:
                self.proc = Popen(
                    cmd,
                    shell=True,
                    stdout=PIPE,
                    stderr=STDOUT,
                    universal_newlines=True,
                )
                self.zyngui.add_info("RESULT:\n", "EMPHASIS")
                for line in self.proc.stdout:
                    if re.search("ERROR", line, re.IGNORECASE):
                        error_counter += 1
                        tag = "ERROR"
                    elif re.search("Already", line, re.IGNORECASE):
                        tag = "SUCCESS"
                    else:
                        tag = None
                    logging.info(line.rstrip())
                    self.zyngui.add_info(line, tag)
                self.zyngui.add_info("\n")
            except Exception as e:
                logging.error(e)
                self.zyngui.add_info("ERROR: %s\n" % e, "ERROR")

        if error_counter > 0:
            logging.info("COMPLETED WITH {} ERRORS!".format(error_counter))
            self.zyngui.add_info(
                "COMPLETED WITH {} ERRORS!".format(error_counter), "WARNING"
            )
        else:
            logging.info("COMPLETED OK!")
            self.zyngui.add_info("COMPLETED OK!", "SUCCESS")

        self.commands = None
        self.zyngui.add_info("\n\n")
        self.zyngui.hide_info_timer(5000)
        self.zyngui.stop_loading()

    def start_command(self, cmds):
        if not self.commands:
            logging.info("Starting Command Sequence ...")
            self.commands = cmds
            self.thread = Thread(target=self.execute_commands, args=())
            self.thread.daemon = True  # thread dies with the program
            self.thread.start()

    def killable_execute_commands(self):
        # self.zyngui.start_loading()
        for cmd in self.commands:
            logging.info("Executing Command: %s" % cmd)
            self.zyngui.add_info("EXECUTING:\n", "EMPHASIS")
            self.zyngui.add_info("{}\n".format(cmd))
            try:
                proc = Popen(cmd.split(" "), stdout=PIPE, stderr=PIPE)
                self.child_pid = proc.pid
                self.zyngui.add_info("\nPID: %s" % self.child_pid)
                (output, error) = proc.communicate()
                self.child_pid = None
                if error:
                    result = "ERROR: %s" % error
                    logging.error(result)
                    self.zyngui.add_info(result, "ERROR")
                if output:
                    logging.info(output)
                    self.zyngui.add_info(output)
            except Exception as e:
                result = "ERROR: %s" % e
                logging.error(result)
                self.zyngui.add_info(result, "ERROR")

        self.commands = None
        self.zyngui.hide_info_timer(5000)
        # self.zyngui.stop_loading()

    def killable_start_command(self, cmds):
        if not self.commands:
            logging.info("Starting Command Sequence ...")
            self.commands = cmds
            self.thread = Thread(
                target=self.killable_execute_commands, args=()
            )
            self.thread.daemon = True  # thread dies with the program
            self.thread.start()

    def kill_command(self):
        if self.child_pid:
            logging.info("Killing process %s" % self.child_pid)
            os.kill(self.child_pid, signal.SIGTERM)
            self.child_pid = None
            if self.last_action == self.test_midi:
                self.zyngui.all_sounds_off()

    # ------------------------------------------------------------------------------
    # NETWORK FEATURES
    # ------------------------------------------------------------------------------

    def network(self):
        logging.info("Network")
        self.zyngui.show_modal("network")

    def network_info(self):
        # self.zyngui.show_info("NETWORK INFO\n")
        #
        # res = zynconf.network_info()
        # for k, v in res.items():
        #     self.zyngui.add_info(" {} => {}\n".format(k, v[0]), v[1])
        #
        # self.zyngui.hide_info_timer(5000)
        # self.zyngui.stop_loading()
        self.zyngui.show_modal("network_info")

    def start_wifi(self):
        if not zynconf.start_wifi():
            self.zyngui.show_info("STARTING WIFI ERROR\n")
            self.zyngui.add_info("Can't start WIFI network!", "WARNING")
            self.zyngui.hide_info_timer(2000)

        self.fill_list()

    def start_wifi_hotspot(self):
        if not zynconf.start_wifi_hotspot():
            self.zyngui.show_info("STARTING WIFI HOTSPOT ERROR\n")
            self.zyngui.add_info("Can't start WIFI Hotspot!", "WARNING")
            self.zyngui.hide_info_timer(2000)

        self.fill_list()

    def stop_wifi(self):
        if not zynconf.stop_wifi():
            self.zyngui.show_info("STOPPING WIFI ERROR\n")
            self.zyngui.add_info("Can't stop WIFI network!", "WARNING")
            self.zyngui.hide_info_timer(2000)

        self.fill_list()

    def start_vncserver(self, save_config=True):
        logging.info("STARTING VNC SERVICES")

        # Save state and stop engines
        if len(self.zyngui.screens["layer"].layers) > 0:
            self.zyngui.screens["snapshot"].save_last_state_snapshot()
            self.zyngui.screens["layer"].reset()
            restore_state = True
        else:
            restore_state = False

        try:
            check_output(
                "systemctl start vncserver@:1; systemctl start novnc",
                shell=True,
            )
            zynthian_gui_config.vncserver_enabled = 1
            # Update Config
            if save_config:
                zynconf.save_config(
                    {
                        "ZYNTHIAN_VNCSERVER_ENABLED": str(
                            zynthian_gui_config.vncserver_enabled
                        )
                    }
                )
        except Exception as e:
            logging.error(e)

        # Restore state
        if restore_state:
            self.zyngui.screens["snapshot"].load_last_state_snapshot(True)

        self.fill_list()

    def stop_vncserver(self, save_config=True):
        logging.info("STOPPING VNC SERVICES")

        # Save state and stop engines
        if len(self.zyngui.screens["layer"].layers) > 0:
            self.zyngui.screens["snapshot"].save_last_state_snapshot()
            self.zyngui.screens["layer"].reset()
            restore_state = True
        else:
            restore_state = False

        try:
            check_output(
                "systemctl stop novnc; systemctl stop vncserver@:1", shell=True
            )
            zynthian_gui_config.vncserver_enabled = 0
            # Update Config
            if save_config:
                zynconf.save_config(
                    {
                        "ZYNTHIAN_VNCSERVER_ENABLED": str(
                            zynthian_gui_config.vncserver_enabled
                        )
                    }
                )
        except Exception as e:
            logging.error(e)

        # Restore state
        if restore_state:
            self.zyngui.screens["snapshot"].load_last_state_snapshot(True)

        self.fill_list()

    # Start/Stop VNC Server depending on configuration
    def default_vncserver(self):
        if zynthian_gui_config.vncserver_enabled:
            self.start_vncserver(False)
        else:
            self.stop_vncserver(False)

    @Slot(None, result='QVariantMap')
    def getNetworkInfo(self):
        return zynconf.network_info()

    @Slot(None, result=str)
    def getHostname(self):
        return socket.gethostname()

    @Slot(str)
    def setHostname(self, hostname):
        self.update_system_hostname(hostname)
        self.zyngui.show_confirm(
            "Device needs to reboot for the hostname change to take effect.\nDo you want to reboot?",
            self.reboot_confirmed)
    
    def reboot_confirmed(self, params=None):
        logging.info(f"Rebooting")
        self.zyngui.screens["admin"].reboot_confirmed()

    # Derived from webconf security_config_handler.py
    def update_system_hostname(self, newHostname):
        previousHostname = ''
        with open("/etc/hostname", 'r') as f:
            previousHostname = f.readline()
            f.close()

        if previousHostname != newHostname:
            with open("/etc/hostname", 'w') as f:
                f.write(newHostname)
                f.close()

            with open("/etc/hosts", "r+") as f:
                contents = f.read()
                # contents = contents.replace(previousHostname, newHostname)
                contents = re.sub(r"127\.0\.1\.1.*$", "127.0.1.1\t{}".format(newHostname), contents)
                f.seek(0)
                f.truncate()
                f.write(contents)
                f.close()

            check_output(["hostnamectl", "set-hostname", newHostname])

            try:
                fpath = '/etc/hostapd/hostapd.conf'
                conf = OrderedDict()
                with open(fpath, 'r+') as f:
                    lines = f.readlines()
                    for l in lines:
                        parts = l.split("=", 1)
                        conf[parts[0]] = parts[1]
                    conf["ssid"] = newHostname + "\n"
                    f.seek(0)
                    f.truncate()
                    for k, v in conf.items():
                        f.write("{}={}".format(k, v))
                    f.close()
            except Exception as e:
                logging.error("Can't set WIFI HotSpot name! => {}".format(e))

# ------------------------------------------------------------------------------
