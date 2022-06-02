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
import sys
import signal
import logging
from time import sleep
from threading import Thread
from subprocess import check_output, Popen, PIPE, STDOUT

# Zynthian specific modules
import zynconf
from . import zynthian_gui_config
from . import zynthian_gui_selector

# -------------------------------------------------------------------------------
# Zynthian Admin GUI Class
# -------------------------------------------------------------------------------
class zynthian_gui_hardware(zynthian_gui_selector):

    data_dir = os.environ.get("ZYNTHIAN_DATA_DIR", "/zynthian/zynthian-data")
    sys_dir = os.environ.get("ZYNTHIAN_SYS_DIR", "/zynthian/zynthian-sys")

    def __init__(self, parent=None):
        super(zynthian_gui_hardware, self).__init__("Engine", parent)
        self.commands = None
        self.thread = None
        self.child_pid = None
        self.last_action = None

    def fill_list(self):
        self.list_data = []

        self.list_data.append((self.test_audio, 0, "Start Test Audio"))
        self.list_data.append((self.kill_command, 0, "Stop Test Audio"))
        self.list_data.append((self.test_midi, 0, "Start Test MIDI"))
        self.list_data.append((self.kill_command, 0, "Stop Test MIDI"))
        self.list_data.append((self.test_touchpoints, 0, "Test Touchpoints"))
        self.list_data.append((self.test_knobs, 0, "Test Knobs"))
        self.list_data.append(
            (self.zyngui.calibrate_touchscreen, 0, "Calibrate Touchscreen")
        )
        super().fill_list()

    def select_action(self, i, t="S"):
        if self.list_data[i][0]:
            self.last_action = self.list_data[i][0]
            self.last_action()

    def set_select_path(self):
        self.select_path = "Hardware"
        self.select_path_element = "Hardware"
        super().set_select_path()

    def execute_commands(self):
        # self.zyngui.start_loading()

        error_counter = 0
        for cmd in self.commands:
            logging.info("Executing Command: %s" % cmd)
            # self.zyngui.add_info("EXECUTING:\n", "EMPHASIS")
            # self.zyngui.add_info("{}\n".format(cmd))
            try:
                self.proc = Popen(
                    cmd,
                    shell=True,
                    stdout=PIPE,
                    stderr=STDOUT,
                    universal_newlines=True,
                )
                # self.zyngui.add_info("RESULT:\n", "EMPHASIS")
                for line in self.proc.stdout:
                    if re.search("ERROR", line, re.IGNORECASE):
                        error_counter += 1
                        tag = "ERROR"
                    elif re.search("Already", line, re.IGNORECASE):
                        tag = "SUCCESS"
                    else:
                        tag = None
                    logging.info(line.rstrip())
                    # self.zyngui.add_info(line, tag)
                # self.zyngui.add_info("\n")
            except Exception as e:
                logging.error(e)
                # self.zyngui.add_info("ERROR: %s\n" % e, "ERROR")

        if error_counter > 0:
            logging.info("COMPLETED WITH {} ERRORS!".format(error_counter))
            # self.zyngui.add_info(
            #     "COMPLETED WITH {} ERRORS!".format(error_counter), "WARNING"
            # )
        else:
            logging.info("COMPLETED OK!")
            # self.zyngui.add_info("COMPLETED OK!", "SUCCESS")

        self.commands = None
        # self.zyngui.add_info("\n\n")
        # self.zyngui.hide_info_timer(5000)
        # self.zyngui.stop_loading()

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
            # self.zyngui.add_info("EXECUTING:\n", "EMPHASIS")
            # self.zyngui.add_info("{}\n".format(cmd))
            try:
                proc = Popen(cmd.split(" "), stdout=PIPE, stderr=PIPE)
                self.child_pid = proc.pid
                # self.zyngui.add_info("\nPID: %s" % self.child_pid)
                (output, error) = proc.communicate()
                self.child_pid = None
                if error:
                    result = "ERROR: %s" % error
                    logging.error(result)
                    # self.zyngui.add_info(result, "ERROR")
                if output:
                    logging.info(output)
                    # self.zyngui.add_info(output)
            except Exception as e:
                result = "ERROR: %s" % e
                logging.error(result)
                # self.zyngui.add_info(result, "ERROR")

        self.commands = None
        # self.zyngui.hide_info_timer(5000)
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
    # CONFIG OPTIONS
    # ------------------------------------------------------------------------------

    # ------------------------------------------------------------------------------
    # SYSTEM FEATURES
    # ------------------------------------------------------------------------------

    def test_audio(self):
        logging.info("TESTING AUDIO")
        # self.zyngui.show_info("TEST AUDIO")
        # self.killable_start_command(["mpg123 {}/audio/test.mp3".format(self.data_dir)])
        self.killable_start_command(
            [
                "mplayer -nogui -noconsolecontrols -nolirc -nojoystick -really-quiet -ao jack {}/audio/test.mp3".format(
                    self.data_dir
                )
            ]
        )
        sleep(0.5)
        self.zyngui.zynautoconnect_audio()

    def test_midi(self):
        logging.info("TESTING MIDI")
        # self.zyngui.show_info("TEST MIDI")
        self.killable_start_command(
            ["aplaymidi -p 14 {}/mid/test.mid".format(self.data_dir)]
        )

    def test_touchpoints(self):
        logging.info("Testing Touchpoints")
        self.zyngui.show_modal("test_touchpoints")

    def test_knobs(self):
        logging.info("Testing Knobs")
        self.zyngui.show_modal("test_knobs")

    def last_state_action(self):
        if (
            zynthian_gui_config.restore_last_state
            and len(self.zyngui.screens["layer"].layers) > 0
        ):
            self.zyngui.screens["snapshot"].save_last_state_snapshot()
        else:
            self.zyngui.screens["snapshot"].delete_last_state_snapshot()

    # def back_action(self):
    # 	self.zyngui.show_screen("main")
    # 	return ''


# ------------------------------------------------------------------------------
