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
import threading
from time import sleep
from datetime import datetime
from subprocess import check_output, Popen, PIPE, STDOUT

# Zynthian specific modules
from . import zynthian_gui_selector
from zyngui import zynthian_gui_config
from zynlibs.zynseq import zynseq
from PySide2.QtCore import Property, QTimer, Signal, Slot

from json import JSONDecoder

import os
from pathlib import Path
from subprocess import Popen

# ------------------------------------------------------------------------------
# Zynthian App Selection GUI Class
# ------------------------------------------------------------------------------


class zynthian_gui_main(zynthian_gui_selector):
    mplayer_ctrl_fifo_path = "/tmp/mplayer-control"
    def __init__(self, parent=None):
        super(zynthian_gui_main, self).__init__("Main", parent)
        self.__is_recording__ = False
        self.__is_playing__ = False
        self.playback_process = None
        self.__most_recent_recording_file__ = ""
        self.__recording_file__ = ""
        # Possible values : modules(all zynthian modules + appimages), appimages(only appimages), sessions(sketchpad folders), sessions-versions(sketchpad files inside sketchpad folders), templates, discover
        self.__current_module_name__ = ""
        self.__current_module_recordalsa__ = False
        self.__current_module_recordingports_left__ = ""
        self.__current_module_recordingports_right__ = ""
        self.__visible_category__ = "modules"
        self.__selected_sketchpad_folder__ = None
        self.recorder_process = None
        self.show()

    def show(self):
        self.select(-1)
        super().show()

    def sync_selector_visibility(self):
        self.fill_list()
        self.set_selector()

    def fill_list(self):
        self.list_data = []
        self.list_metadata = []

        if self.visibleCategory == "modules":
            # Main Apps
            self.list_data.append((self.sketchpad, 0, "Sketchpad"))
            self.list_metadata.append({"icon":"../../img/clipsview.svg"})

            self.list_data.append((self.playgrid, 0, "Playground"))
            self.list_metadata.append({"icon":"../../img/playground.svg"})

            self.list_data.append((self.layers, 0, "Library"))
            self.list_metadata.append({"icon":"../../img/library.svg"})

            self.list_data.append((self.song_arranger, 0, "Song Arranger"))
            self.list_metadata.append({"icon":"../../img/song_arranger.svg"})

            self.list_data.append((self.song_player, 0, "Song Player"))
            #self.list_metadata.append({"icon":"../../img/song_player.svg"})
            self.list_metadata.append({"icon":"../../img/song-player.svg"})

            self.list_data.append((self.admin, 0, "Settings"))
            self.list_metadata.append({"icon":"../../img/settings.svg"})

            # As per #299, rename Snapshots to Soundsets
            self.list_data.append((self.snapshots_menu, 0, "Soundsets"))
            self.list_metadata.append({"icon":"../../img/snapshots.svg"})

            self.list_data.append((self.sketchpad_copier, 0, "Sketchpad Copier"))
            self.list_metadata.append({"icon":"../../img/sketchpad_copier.svg"})

            #self.list_data.append((self.session_dashboard, 0, "Channels"))
            #self.list_metadata.append({"icon":"../../img/channels.svg"})

            #if "zynseq" in zynthian_gui_config.experimental_features:
                # self.list_data.append((self.step_sequencer, 0, "Sequencer"))
            # self.list_data.append((self.alsa_mixer, 0, "Audio Levels"))

            #self.list_data.append((self.audio_recorder, 0, "Audio Recorder"))
            #self.list_metadata.append({"icon":"../../img/rec-audio.svg"})

            #self.list_data.append((self.midi_recorder, 0, "MIDI Recorder"))
            #self.list_metadata.append({"icon":"../../img/rec.svg"})

            # if "autoeq" in zynthian_gui_config.experimental_features:
            #    self.list_data.append((self.auto_eq, 0, "Auto EQ (alpha)"))

            # Snapshot Management
            # self.list_data.append((None, 0, ""))

            # if len(self.zyngui.screens["layer"].layers) > 0:
                # self.list_data.append((self.save_snapshot, 0, "Save Snapshot"))
                # self.list_data.append((self.clean_all, 0, "CLEAN ALL"))

            # self.list_data.append((None, 0, ""))

        if self.visibleCategory == "modules" or self.visibleCategory == "appimages":
            apps_folder = os.path.expanduser('~') + "/.local/share/zynthian/modules/"
            if Path(apps_folder).exists():
                for appimage_dir in [f.name for f in os.scandir(apps_folder) if f.is_dir()]:
                    try:
                        f = open(apps_folder + appimage_dir + "/metadata.json", "r")
                        metadata = JSONDecoder().decode(f.read())
                        if (not "Exec" in metadata) or (not "Name" in metadata) or (not "Icon" in metadata):
                            continue
                        autoFilled = False
                        if not "RecordingPortsLeft" in metadata:
                            metadata["RecordingPortsLeft"] = ""
                            autoFilled = True
                        if not "RecordingPortsRight" in metadata:
                            metadata["RecordingPortsRight"] = ""
                            autoFilled = True
                        # TODO Just some heuristics so we end up with stuff in these for some of our stuff without having to update... We can get rid of these a bit later on
                        if autoFilled:
                            if metadata["Name"] == "Norns":
                                metadata["RecordingPortsLeft"] = "SuperCollider:out_1"
                                metadata["RecordingPortsRight"] = "SuperCollider:out_2"
                        recordAlsa = False
                        if "RecordAlsa" in metadata:
                            recordAlsa = metadata["RecordAlsa"].lower() in ['true', '1', 't', 'y', 'yes', 'yeah', 'yup', 'certainly', 'uh-huh']
                        self.list_data.append(("appimage", apps_folder + "/" + appimage_dir + "/" + metadata["Exec"], metadata["Name"]))
                        # the recordings_file_base thing might seem potentially clashy, but it's only the base filename anyway
                        # and we'll de-clash the filename in start_recording (by putting an increasing number at the end)
                        self.list_metadata.append({"icon": apps_folder + "/" + appimage_dir + "/" + metadata["Icon"], "recordings_file_base" : metadata["Name"], "recording_ports_left" : metadata["RecordingPortsLeft"], "recording_ports_right" : metadata["RecordingPortsRight"], "record_alsa" : recordAlsa})
                    except Exception as e:
                        logging.error(e)

        if self.visibleCategory == "sessions":
            for sketchpad in self.zyngui.sketchpad.get_sketchpad_folders():
                self.list_data.append(("sketchpad", str(sketchpad), sketchpad.stem))
                self.list_metadata.append({"icon": "/zynthian/zynthian-ui/img/folder.svg"})

        if self.visibleCategory == "sessions-versions":
            for version in self.zyngui.sketchpad.get_sketchpad_versions(self.__selected_sketchpad_folder__):
                self.list_data.append(("sketchpad-version", str(version), version.name.replace(".sketchpad.json", "")))
                self.list_metadata.append({"icon": "/zynthian/zynthian-ui/img/file.svg"})

        super().fill_list()

    def select_action(self, i, t="S"):
        if self.list_data[i][0] and self.list_data[i][0] == "appimage":
            self.song_recordings_dir = self.zyngui.screens["sketchpad"].song.sketchpad_folder + "wav"
            self.__current_recordings_file_base__ = self.song_recordings_dir + "/" + self.list_metadata[i]["recordings_file_base"]
            apps_folder = os.path.expanduser('~') + "/.local/share/zynthian/modules/"
            self.__current_module_name__ = self.list_data[i][2]
            self.__current_module_recordalsa__ = self.list_metadata[i]["record_alsa"]
            self.__current_module_recordingports_left__ = self.list_metadata[i]["recording_ports_left"]
            self.__current_module_recordingports_right__ = self.list_metadata[i]["recording_ports_right"]
            self.currentModuleChanged.emit
            Popen([self.list_data[i][1]])

            # Open sketchpad after opening appimage to mimic closing of menu after opening an app like other modules in main page
            QTimer.singleShot(5000, lambda: self.zyngui.show_modal("sketchpad"))
        elif self.list_data[i][0] and self.list_data[i][0] == "sketchpad":
            self.__selected_sketchpad_folder__ = self.list_data[i][1]
            self.visibleCategory = "sessions-versions"
        elif self.list_data[i][0] and self.list_data[i][0] == "sketchpad-version":
            self.zyngui.sketchpad.loadSketchpad(self.list_data[i][1], False)
            self.zyngui.show_modal("sketchpad")
        elif self.list_data[i][0]:
            self.last_action = self.list_data[i][0]
            self.last_action()

    @Slot(None)
    def start_recording_alsa(self):
        if (self.__is_recording__ == False):
            Path(self.song_recordings_dir).mkdir(parents=True, exist_ok=True)
            timestamp = datetime.now().strftime("%Y%m%d-%H%M%S");
            self.__recording_file__ = f"{self.__current_recordings_file_base__}{'-'+timestamp}.clip.wav"

            audioDeviceName = self.zyngui.audio_settings.zynthian_mixer.zynapi_get_device_name()
            self.recorder_process = Popen(("/usr/bin/arecord", "-f", "dat", "-D", f"hw:{audioDeviceName}", self.__recording_file__))
            logging.info("Started recording using arecord into the file " + self.__recording_file__)
            self.__is_recording__ = True
            self.is_recording_changed.emit()

    @Slot(None)
    def start_recording(self):
        if (self.__is_recording__ == False):
            Path(self.song_recordings_dir).mkdir(parents=True, exist_ok=True)
            timestamp = datetime.now().strftime("%Y%m%d-%H%M%S");
            self.__recording_file__ = f"{self.__current_recordings_file_base__}{'-'+timestamp}.clip.wav"

            self.recorder_process = Popen(("/usr/local/bin/jack_capture", "--daemon", "--port", f"system:playback_*", self.__recording_file__))
            logging.info("Started recording into the file " + self.__recording_file__)
            self.__is_recording__ = True
            self.is_recording_changed.emit()

    @Slot(str)
    def stop_recording_and_move(self, destination):
        if (self.recorder_process is not None):
            self.recorder_process.terminate()
            self.recorder_process = None
            self.__is_recording__ = False
            self.is_recording_changed.emit()
            if (destination != self.__recording_file__):
                # Move the file from its temporary destination to its new home if the destination is somewhere other than where the file already lives
                os.rename(self.__recording_file__, destination)
            self.__most_recent_recording_file__ = destination
            self.most_recent_recording_file_changed.emit()
            self.__recording_file__ = ""
            self.recording_file_changed.emit();
        pass

    @Slot(None)
    def stop_recording(self):
        self.stop_recording_and_move(self.__recording_file__)

    @Signal
    def is_recording_changed(self):
        pass

    @Property(bool, notify=is_recording_changed)
    def isRecording(self):
        return self.__is_recording__;

    @Signal
    def recording_file_changed(self):
        pass

    @Property(str, notify=recording_file_changed)
    def recordingFile(self):
        return self.__recording_file__

    @Signal
    def most_recent_recording_file_changed(self):
        pass

    @Property(str, notify=most_recent_recording_file_changed)
    def mostRecentRecordingFile(self):
        return self.__most_recent_recording_file__

    @Slot(None)
    def discardMostRecentRecording(self):
        if (self.__most_recent_recording_file__ != ""):
            if (os.path.exists(self.__most_recent_recording_file__)):
                os.remove(self.__most_recent_recording_file__)
                if (not os.path.exists(self.__most_recent_recording_file__)):
                    self.__most_recent_recording_file__ = ""
                    self.most_recent_recording_file_changed.emit()

    @Slot(None)
    def playMostRecentRecording(self):
        if (self.__most_recent_recording_file__ != ""):
            if (os.path.exists(self.__most_recent_recording_file__)):
                self.stopMostRecentRecordingPlayback()

                # Create control fifo is needed ...
                try:
                    os.mkfifo(self.mplayer_ctrl_fifo_path)
                except:
                    pass

                try:
                    cmd="/usr/bin/mplayer -nogui -noconsolecontrols -nolirc -nojoystick -really-quiet -slave -ao jack -input file=\"{}\" \"{}\"".format(self.mplayer_ctrl_fifo_path, self.__most_recent_recording_file__)
                    logging.info("COMMAND: %s" % cmd)

                    def runInThread(onExit, cmd):
                        self.playback_process = Popen(cmd, shell=True, universal_newlines=True)
                        self.playback_process.wait()
                        self.playback_ended()
                        return

                    thread = threading.Thread(target=runInThread, args=(self.playback_ended, cmd), daemon=True)
                    thread.start()

                    self.__is_playing__ = True
                    self.is_playing_changed.emit()

                except Exception as e:
                    logging.error("ERROR STARTING AUDIO PLAY: %s" % e)

    def send_mplayer_command(self, cmd):
        with open(self.mplayer_ctrl_fifo_path, "w") as f:
            f.write(cmd + "\n")
            f.close()

    def playback_ended(self):
        self.playback_process = None
        self.__is_playing__ = False
        self.is_playing_changed.emit()

    @Slot(None)
    def stopMostRecentRecordingPlayback(self):
        if (self.playback_process is not None):
            try:
                self.send_mplayer_command("quit")
            except Exception as e:
                logging.error("ERROR STOPPING AUDIO PLAY: %s" % e)

    @Signal
    def is_playing_changed(self):
        pass

    @Property(bool, notify=is_playing_changed)
    def isPlaying(self):
        return self.__is_playing__

    def next_action(self):
        return "main"

    def back_action(self):
        return "sketchpad"

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

    def channel(self):
        logging.info("Channel")
        self.zyngui.show_modal("channel")

    def session_dashboard(self):
        logging.info("Session")
        self.zyngui.show_modal("session_dashboard")

    def sketchpad(self):
        logging.info("Sketchpad")
        self.zyngui.show_modal("sketchpad")

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

    def song_player(self):
        logging.info("Song Player")
        self.zyngui.show_modal("song_player")

    def sketchpad_copier(self):
        logging.info("Sketchpad Copier")
        self.zyngui.show_modal("sketchpad_copier")

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

    ### Property visibleCategory
    def get_visibleCategory(self):
        return self.__visible_category__

    def set_visibleCategory(self, category):
        if self.__visible_category__ != category:
            self.__visible_category__ = category
            self.visibleCategoryChanged.emit()
            self.fill_list()

    visibleCategoryChanged = Signal()

    visibleCategory = Property(str, get_visibleCategory, set_visibleCategory, notify=visibleCategoryChanged)
    ### END Property visibleCategory

    currentModuleChanged = Signal()
    ### Property currentModuleName
    def get_currentModuleName(self):
        return self.__current_module_name__

    currentModuleName = Property(str, get_currentModuleName, notify=currentModuleChanged)
    ### END Property currentModuleName

    ### Property currentModuleRecordAlsa
    def get_currentModuleRecordAlsa(self):
        return self.__current_module_recordalsa__

    currentModuleRecordAlsa = Property(str, get_currentModuleRecordAlsa, notify=currentModuleChanged)
    ### END Property currentModuleRecordingPortsLeft

    ### Property currentModuleRecordingPortsLeft
    def get_currentModuleRecordingPortsLeft(self):
        return self.__current_module_recordingports_left__

    currentModuleRecordingPortsLeft = Property(str, get_currentModuleRecordingPortsLeft, notify=currentModuleChanged)
    ### END Property currentModuleRecordingPortsLeft

    ### Property currentModuleRecordingPortsRight
    def get_currentModuleRecordingPortsRight(self):
        return self.__current_module_recordingports_right__

    currentModuleRecordingPortsRight = Property(str, get_currentModuleRecordingPortsRight, notify=currentModuleChanged)
    ### END Property currentModuleRecordingPortsRight
# ------------------------------------------------------------------------------
