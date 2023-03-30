#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthian GUI Snapshots Menu Class
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
import logging
from time import sleep
from threading import Thread
from subprocess import check_output, Popen, PIPE, STDOUT

# Zynthian specific modules
from . import zynthian_gui_selector, zynthian_gui_config
from zynlibs.zynseq import zynseq
# -------------------------------------------------------------------------------
# Zynthian Snapshots Menu GUI Class
# -------------------------------------------------------------------------------
class zynthian_gui_snapshots_menu(zynthian_gui_selector):

    data_dir = os.environ.get("ZYNTHIAN_DATA_DIR", "/zynthian/zynthian-data")
    sys_dir = os.environ.get("ZYNTHIAN_SYS_DIR", "/zynthian/zynthian-sys")

    def __init__(self, parent=None):
        super(zynthian_gui_snapshots_menu, self).__init__("Engine", parent)
        self.commands = None
        self.thread = None
        self.child_pid = None
        self.last_action = None

    def fill_list(self):
        self.list_data = []
        # As per #299 rename Snapshots to Soundsets
        self.list_data.append((self.load_snapshot, 0, "Load Soundset"))
        if len(self.zyngui.screens["layer"].layers) > 0:
            self.list_data.append((self.save_snapshot, 0, "Save Soundset"))
            # self.list_data.append((self.clean_all, 0, "CLEAN ALL"))
        super().fill_list()

    def select_action(self, i, t="S"):
        if self.list_data[i][0]:
            self.last_action = self.list_data[i][0]
            self.last_action()

    def set_select_path(self):
        self.select_path = "Snapshots"
        self.select_path_element = "Snapshots"
        super().set_select_path()

    # def execute_commands(self):
    #     self.zyngui.start_loading()

    #     error_counter = 0
    #     for cmd in self.commands:
    #         logging.info("Executing Command: %s" % cmd)
    #         self.zyngui.add_info("EXECUTING:\n", "EMPHASIS")
    #         self.zyngui.add_info("{}\n".format(cmd))
    #         try:
    #             self.proc = Popen(
    #                 cmd,
    #                 shell=True,
    #                 stdout=PIPE,
    #                 stderr=STDOUT,
    #                 universal_newlines=True,
    #             )
    #             self.zyngui.add_info("RESULT:\n", "EMPHASIS")
    #             for line in self.proc.stdout:
    #                 if re.search("ERROR", line, re.IGNORECASE):
    #                     error_counter += 1
    #                     tag = "ERROR"
    #                 elif re.search("Already", line, re.IGNORECASE):
    #                     tag = "SUCCESS"
    #                 else:
    #                     tag = None
    #                 logging.info(line.rstrip())
    #                 self.zyngui.add_info(line, tag)
    #             self.zyngui.add_info("\n")
    #         except Exception as e:
    #             logging.error(e)
    #             self.zyngui.add_info("ERROR: %s\n" % e, "ERROR")

    #     if error_counter > 0:
    #         logging.info("COMPLETED WITH {} ERRORS!".format(error_counter))
    #         self.zyngui.add_info(
    #             "COMPLETED WITH {} ERRORS!".format(error_counter), "WARNING"
    #         )
    #     else:
    #         logging.info("COMPLETED OK!")
    #         self.zyngui.add_info("COMPLETED OK!", "SUCCESS")

    #     self.commands = None
    #     self.zyngui.add_info("\n\n")
    #     self.zyngui.hide_info_timer(5000)
    #     self.zyngui.stop_loading()

    # def start_command(self, cmds):
    #     if not self.commands:
    #         logging.info("Starting Command Sequence ...")
    #         self.commands = cmds
    #         self.thread = Thread(target=self.execute_commands, args=())
    #         self.thread.daemon = True  # thread dies with the program
    #         self.thread.start()

    # def killable_execute_commands(self):
    #     # self.zyngui.start_loading()
    #     for cmd in self.commands:
    #         logging.info("Executing Command: %s" % cmd)
    #         self.zyngui.add_info("EXECUTING:\n", "EMPHASIS")
    #         self.zyngui.add_info("{}\n".format(cmd))
    #         try:
    #             proc = Popen(cmd.split(" "), stdout=PIPE, stderr=PIPE)
    #             self.child_pid = proc.pid
    #             self.zyngui.add_info("\nPID: %s" % self.child_pid)
    #             (output, error) = proc.communicate()
    #             self.child_pid = None
    #             if error:
    #                 result = "ERROR: %s" % error
    #                 logging.error(result)
    #                 self.zyngui.add_info(result, "ERROR")
    #             if output:
    #                 logging.info(output)
    #                 self.zyngui.add_info(output)
    #         except Exception as e:
    #             result = "ERROR: %s" % e
    #             logging.error(result)
    #             self.zyngui.add_info(result, "ERROR")

    #     self.commands = None
    #     self.zyngui.hide_info_timer(5000)
    #     # self.zyngui.stop_loading()

    # def killable_start_command(self, cmds):
    #     if not self.commands:
    #         logging.info("Starting Command Sequence ...")
    #         self.commands = cmds
    #         self.thread = Thread(
    #             target=self.killable_execute_commands, args=()
    #         )
    #         self.thread.daemon = True  # thread dies with the program
    #         self.thread.start()

    # def kill_command(self):
    #     if self.child_pid:
    #         logging.info("Killing process %s" % self.child_pid)
    #         os.kill(self.child_pid, signal.SIGTERM)
    #         self.child_pid = None
    #         if self.last_action == self.test_midi:
    #             self.zyngui.all_sounds_off()

    # ------------------------------------------------------------------------------
    # SNAPSHOTS OPTIONS
    # ------------------------------------------------------------------------------

    def load_snapshot(self):
        logging.info("Load Snapshot")
        self.zyngui.load_snapshot()

    def save_snapshot(self):
        logging.info("Save Snapshot")
        self.zyngui.save_snapshot()

    def clean_all(self):
        self.zyngui.show_confirm(
            "Do you really want to clean all?", self.clean_all_confirmed
        )

    def clean_all_confirmed(self, params=None):
        if len(self.zyngui.screens["layer"].layers) > 0:
            self.zyngui.screens["snapshot"].save_last_state_snapshot()
        self.zyngui.screens["layer"].reset()
        if zynseq.libseq:
            zynseq.load("")
        self.zyngui.show_screen("layer")

# ------------------------------------------------------------------------------
