#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthian GUI Main Menu Class
#
# Copyright (C) 2015-2020 Fernando Moyano <jofemodo@zynthian.org>
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

import logging
import re
from subprocess import check_output, Popen, PIPE, STDOUT

# Zynthian specific modules
from . import zynthian_gui_selector
from zyngui import zynthian_gui_config
from zynlibs.zynseq import zynseq
from PySide2.QtCore import Slot

from json import JSONDecoder

import os
from pathlib import Path
from subprocess import Popen


# ------------------------------------------------------------------------------
# Zynthian App Selection GUI Class
# ------------------------------------------------------------------------------


class zynthian_gui_main(zynthian_gui_selector):
    def __init__(self, parent=None):
        super(zynthian_gui_main, self).__init__("Main", parent)
        self.show()

    def show(self):
        self.select(-1)
        super().show()

    def fill_list(self):
        self.list_data = []
        self.list_metadata = []

        # Main Apps
        self.list_data.append((self.session_dashboard, 0, "Session"))
        self.list_metadata.append({"icon":"../../img/session-dashboard.svg"})

        self.list_data.append((self.zynthiloops, 0, "Looper"))
        self.list_metadata.append({"icon":"../../img/looper.svg"})

        self.list_data.append((self.song_arranger, 0, "Song Arranger"))
        self.list_metadata.append({"icon":"../../img/song_arranger.svg"})

        self.list_data.append((self.sketch_copier, 0, "Sketch Copier"))
        self.list_metadata.append({"icon":"../../img/sketch_copier.svg"})
        
        self.list_data.append((self.playgrid, 0, "Play Grid"))
        self.list_metadata.append({"icon":"../../img/playgrid.svg"})
        
        self.list_data.append((self.layers, 0, "Library"))
        self.list_metadata.append({"icon":"../../img/layers.svg"})
        
        #if "zynseq" in zynthian_gui_config.experimental_features:
            # self.list_data.append((self.step_sequencer, 0, "Sequencer"))
        # self.list_data.append((self.alsa_mixer, 0, "Audio Levels"))

        self.list_data.append((self.audio_recorder, 0, "Audio Recorder"))
        self.list_metadata.append({"icon":"../../img/rec-audio.svg"})

        self.list_data.append((self.midi_recorder, 0, "MIDI Recorder"))
        self.list_metadata.append({"icon":"../../img/rec.svg"})

        # if "autoeq" in zynthian_gui_config.experimental_features:
        #    self.list_data.append((self.auto_eq, 0, "Auto EQ (alpha)"))

        # Snapshot Management
        # self.list_data.append((None, 0, ""))

        self.list_data.append((self.snapshots_menu, 0, "Snapshots"))
        self.list_metadata.append({"icon":"../../img/snapshots.svg"})

        # if len(self.zyngui.screens["layer"].layers) > 0:
            # self.list_data.append((self.save_snapshot, 0, "Save Snapshot"))
            # self.list_data.append((self.clean_all, 0, "CLEAN ALL"))

        # self.list_data.append((None, 0, ""))
        self.list_data.append((self.admin, 0, "Settings"))
        self.list_metadata.append({"icon":"../../img/settings.svg"})

        apps_folder = os.path.expanduser('~') + "/.local/share/zynthian/modules/"
        if Path(apps_folder).exists():
            for appimage_dir in [f.name for f in os.scandir(apps_folder) if f.is_dir()]:
                try:
                    f = open(apps_folder + appimage_dir + "/metadata.json", "r")
                    metadata = JSONDecoder().decode(f.read())
                    if (not "Exec" in metadata) or (not "Name" in metadata) or (not "Icon" in metadata):
                        continue
                    self.list_data.append(("appimage", apps_folder + "/" + appimage_dir + "/" + metadata["Exec"], metadata["Name"]))
                    self.list_metadata.append({"icon": apps_folder + "/" + appimage_dir + "/" + metadata["Icon"]})
                except Exception as e:
                    logging.error(e)

        super().fill_list()

    def select_action(self, i, t="S"):
        if self.list_data[i][0] and self.list_data[i][0] == "appimage":
            apps_folder = os.path.expanduser('~') + "/.local/share/zynthian/modules/"
            Popen([self.list_data[i][1]])
        elif self.list_data[i][0]:
            self.last_action = self.list_data[i][0]
            self.last_action()

    def next_action(self):
        return "main"

    def back_action(self):
        return "session_dashboard"

    def layers(self):
        logging.info("Layers")
        self.zyngui.show_screen("layer")

    def load_snapshot(self):
        logging.info("Load Snapshot")
        self.zyngui.load_snapshot()

    def save_snapshot(self):
        logging.info("Save Snapshot")
        self.zyngui.save_snapshot()

    def snapshots_menu(self):
        logging.info("Snapshots")
        self.zyngui.show_modal("snapshots_menu")

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

    def audio_recorder(self):
        logging.info("Audio Recorder")
        self.zyngui.show_modal("audio_recorder")

    def midi_recorder(self):
        logging.info("MIDI Recorder")
        self.zyngui.show_modal("midi_recorder")

    def playgrid(self):
        logging.info("Play Grid")
        self.zyngui.show_modal("playgrid")

    def track(self):
        logging.info("Track")
        self.zyngui.show_modal("track")

    def session_dashboard(self):
        logging.info("Session")
        self.zyngui.show_screen("session_dashboard")

    def zynthiloops(self):
        logging.info("ZynthiLoops")
        self.zyngui.show_modal("zynthiloops")

    def alsa_mixer(self):
        logging.info("ALSA Mixer")
        self.zyngui.show_modal("alsa_mixer")

    def auto_eq(self):
        logging.info("Auto EQ")
        self.zyngui.show_modal("autoeq")

    def step_sequencer(self):
        logging.info("Step Sequencer")
        self.zyngui.show_modal("stepseq")

    def song_arranger(self):
        logging.info("Song Arranger")
        self.zyngui.show_modal("song_arranger")

    def sketch_copier(self):
        logging.info("Sketch Copier")
        self.zyngui.show_modal("sketch_copier")

    def admin(self):
        logging.info("Admin")
        self.zyngui.show_modal("admin")

    def set_select_path(self):
        self.select_path = "Main"
        self.select_path_element = "Main"
        super().set_select_path()

    @Slot('void')
    def restart_gui(self):
        logging.info("RESTART ZYNTHIAN-UI")
        self.last_state_action()
        #self.zyngui.exit(102)
        self.zyngui.screens["admin"].restart_gui()

    def exit_to_console(self):
        logging.info("EXIT TO CONSOLE")
        self.last_state_action()
        self.zyngui.exit(101)

    @Slot('void')
    def reboot(self):
        self.zyngui.show_confirm(
            "Do you really want to reboot?", self.reboot_confirmed
        )

    def reboot_confirmed(self, params=None):
        logging.info("REBOOT")
        self.last_state_action()
        #self.zyngui.exit(100)
        self.zyngui.screens["admin"].reboot_confirmed()

    @Slot('void')
    def power_off(self):
        self.zyngui.show_confirm(
            "Do you really want to power off?", self.power_off_confirmed
        )

    @Slot(None)
    def refresh(self):
        self.fill_list()

    def power_off_confirmed(self, params=None):
        logging.info("POWER OFF")
        self.last_state_action()
        #self.zyngui.exit(0)
        self.zyngui.screens["admin"].power_off_confirmed()

    def last_state_action(self):
        if (
            zynthian_gui_config.restore_last_state
            and len(self.zyngui.screens["layer"].layers) > 0
        ):
            self.zyngui.screens["snapshot"].save_last_state_snapshot()
        else:
            self.zyngui.screens["snapshot"].delete_last_state_snapshot()


# ------------------------------------------------------------------------------
