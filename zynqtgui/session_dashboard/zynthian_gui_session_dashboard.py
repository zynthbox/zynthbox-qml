#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian GUI Info Class
# 
# Copyright (C) 2021 Marco MArtin <mart@kde.org>
# Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
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
import json
import sys
import logging
import os

from datetime import datetime

# Zynthian specific modules
from pathlib import Path

from zynqtgui import zynthian_gui_selector

# Qt modules
from PySide2.QtCore import QTimer, Qt, QObject, Slot, Signal, Property, QMetaObject


#------------------------------------------------------------------------------
# Zynthian Session Dashboard GUI Class
#------------------------------------------------------------------------------
from zynqtgui.session_dashboard.session_dashboard_session_sketchpads_model import session_dashboard_session_sketchpads_model


class zynthian_gui_session_dashboard(zynthian_gui_selector):

    def __init__(self, parent=None):
        super(zynthian_gui_session_dashboard, self).__init__('Session', parent)
        logging.info(f"Initializing Session Dashboard")
        self.__sessionStartTime = datetime.now()
        self.__sessions_base_dir__ = Path("/zynthian/zynthian-my-data/sessions/")
        self.__save_timer__ = QTimer(self)
        self.__session_sketchpads_model__ = session_dashboard_session_sketchpads_model(self)
        self.__cache_json_path__ = self.__sessions_base_dir__ / ".cache.json"
        self.__visible_channels_start__ = 0
        self.__visible_channels_end__ = 5
        self.__last_selected_sketchpad__ = None
        self.__selected_channel__ = 0

        # Sound changes even though change_to_channel_sound is not called.
        # Someone else is doing the job and there is no point in doing it twice.
        # Disabling for now but this is a HACK
        # FIXME : Find the real place which actually switches sound
        # self.__change_channel_sound_timer__ = QTimer()
        # self.__change_channel_sound_timer__.setInterval(10000)
        # self.__change_channel_sound_timer__.setSingleShot(True)
        # self.__change_channel_sound_timer__.timeout.connect(self.change_to_channel_sound, Qt.QueuedConnection)

        if not self.restore():
            def cb():
                logging.info("Session dashboard Init Sketchpad CB (No restore)")
                self.set_selected_channel(self.__selected_channel__, True)

                selected_channel = self.zyngui.screens['sketchpad'].song.channelsModel.getChannel(self.selectedChannel)
                selected_channel.set_chained_sounds(selected_channel.get_chained_sounds())

            self.__name__ = None
            self.__id__ = 0

            self.zyngui.screens["sketchpad"].init_sketchpad(None, cb)

        self.__save_timer__.setInterval(1000)
        self.__save_timer__.setSingleShot(True)
        self.__save_timer__.timeout.connect(self.save)

        self.zyngui.screens["layer"].layer_created.connect(self.layer_created)
        self.zyngui.screens["layer_effects"].fx_layers_changed.connect(self.fx_layers_changed)

        self.show()

    def back_action(self):
        return "sketchpad"

    def layer_created(self, index):
       QMetaObject.invokeMethod(self, "emit_chained_sounds_changed", Qt.QueuedConnection)

    def fx_layers_changed(self):
        logging.debug(f"FX Layer Changed")
        QMetaObject.invokeMethod(self, "emit_chained_sounds_changed", Qt.QueuedConnection)

    @Signal
    def midiSelectionRequested(self):
        pass

    @Slot(None)
    def emit_chained_sounds_changed(self):
        selected_channel = self.zyngui.screens['sketchpad'].song.channelsModel.getChannel(self.selectedChannel)
        if selected_channel is not None:
            selected_channel.set_chained_sounds(selected_channel.get_chained_sounds())
        self.zyngui.screens['sketchpad'].song.channelsModel.connected_sounds_count_changed.emit()
        # self.set_selected_channel(self.selectedChannel, True)

    @Slot(None)
    def set_selected_channel_complete(self):
        self.zyngui.fixed_layers.fill_list()
        # self.__change_channel_sound_timer__.start()

    ### Property name
    def get_name(self):
        if self.__name__ is not None:
            return self.__name__
        else:
            return f"Project {self.__id__ + 1}"
    def set_name(self, name):
        self.__name__ = name
        self.name_changed.emit()
        self.schedule_save()
    name_changed = Signal()
    name = Property(str, get_name, set_name, notify=name_changed)
    ### END Property name

    ### Property id
    def get_id(self):
        return self.__id__
    id_changed = Signal()
    id = Property(int, get_id, notify=id_changed)
    ### END Property name

    ### Property sessionSketchpadsModel
    def get_session_sketchpads_model(self):
        return self.__session_sketchpads_model__
    session_sketchpads_model_changed = Signal()
    sessionSketchpadsModel = Property(QObject, get_session_sketchpads_model, notify=session_sketchpads_model_changed)
    ### END Property sessionSketchpadsModel

    ### Property selectedChannel
    def change_to_channel_sound(self):
        self.zyngui.screens["layers_for_channel"].update_channel_sounds()
        
        # Set correct interval in case it was set to 0 when pressing a mixer column for immediate sound change
        # self.__change_channel_sound_timer__.setInterval(10000)

        self.schedule_save()
    def get_selected_channel(self):
        return self.__selected_channel__
    def set_selected_channel(self, channel, force_set=False):
        if self.__selected_channel__ != channel or force_set is True:
            logging.debug(f"### Setting selected channel : channel({channel})")
            self.__selected_channel__ = channel
            self.selected_channel_changed.emit()

            # Set is_set_selector_running way before set_selector is called so that
            # knob values are discarded. set_selector will be called by change_to_channel_sound
            # after 1000ms when active midi channel is switched
            # self.zyngui.sketchpad.set_set_selector_active()
            self.zyngui.sketchpad.set_selector() #(True, False, False, False)

            # Do heavy tasks in a slot invoked with QueuedConnection to not cause UI stutters when channel changes
            # fill_list and emitting selected_channel_changed event is a bit on the heavier side and hence should go
            # in the set_selected_channel_complete slot
            QMetaObject.invokeMethod(self, "set_selected_channel_complete", Qt.QueuedConnection)
    selected_channel_changed = Signal()
    selectedChannel = Property(int, get_selected_channel, set_selected_channel, notify=selected_channel_changed)
    ### END Property selectedChannel

    ### Property visibleChannelsStart
    def get_visible_channels_start(self):
        return self.__visible_channels_start__
    def set_visible_channels_start(self, index):
        self.__visible_channels_start__ = index
        self.visible_channels_changed.emit()
    visible_channels_changed = Signal()
    visibleChannelsStart = Property(int, get_visible_channels_start, set_visible_channels_start, notify=visible_channels_changed)
    ### END Property visibleChannelsStart

    ### Property visibleChannelsEnd
    def get_visible_channels_end(self):
        return self.__visible_channels_end__
    def set_visible_channels_end(self, index):
        self.__visible_channels_end__ = index
        self.visible_channels_changed.emit()
    visibleChannelsEnd = Property(int, get_visible_channels_end, set_visible_channels_end, notify=visible_channels_changed)
    ### END Property visibleChannelsEnd

    ### Property selectedChannelName
    def get_selected_channel_name(self):
        channel = self.zyngui.screens["sketchpad"].song.channelsModel.getChannel(self.__selected_channel__)
        if channel.connectedSound >= 0:
            return self.zyngui.screens["fixed_layers"].selector_list.getDisplayValue(channel.connectedSound)
        else:
            return ""
    selected_channel_name_changed = Signal()
    selectedChannelName = Property(str, get_selected_channel_name, notify=selected_channel_name_changed)
    ### END Property selectedChannelName

    def serialize(self):
        return {
            "name": self.__name__,
            "id": self.__id__,
            "selectedChannel": self.__selected_channel__,
            "sketchpads": self.__session_sketchpads_model__.serialize(),
            "lastSelectedSketchpad": self.__last_selected_sketchpad__
        }

    def schedule_save(self):
        self.__save_timer__.start()

    def save(self):
        # Save session to cache
        self.__sessions_base_dir__.mkdir(parents=True, exist_ok=True)

        logging.info(f"Saving session to cache : {self.__cache_json_path__}")

        try:
            with open(self.__cache_json_path__, "w") as f:
                json.dump(self.serialize(), f)
                f.flush()
                os.fsync(f.fileno())
        except Exception as e:
            logging.error(f"Error saving cache : {str(e)}")

    @Slot(str)
    def saveAs(self, fileName):
        self.__sessions_base_dir__.mkdir(parents=True, exist_ok=True)

        session_json_path = self.__sessions_base_dir__ / (fileName + ".json")
        logging.info(f"Saving session to file : {session_json_path}")

        try:
            with open(session_json_path, "w") as f:
                json.dump(self.serialize(), f)
                f.flush()
                os.fsync(f.fileno())
        except Exception as e:
            logging.error(f"Error saving session : {str(e)}")

        logging.info(f"Deleting cache : {self.__cache_json_path__}")

        try:
            self.__cache_json_path__.unlink()
        except Exception as e:
            logging.error(f"Error deleting cache : {str(e)}")

    def restore(self, sketchpad=""):
        def sketchpad_loaded_cb():
            self.selected_channel_changed.emit()
            QMetaObject.invokeMethod(self, "emit_chained_sounds_changed", Qt.QueuedConnection)
            logging.info(f"Session Dashboard Initialization Complete")

        if self.__cache_json_path__.exists():
            logging.info(f"Cache found. Restoring Session from {self.__cache_json_path__}")
            session_json_path = self.__cache_json_path__
        elif len(sketchpad) > 0 and Path(sketchpad).exists():
            session_json_path = Path(sketchpad)
            logging.info(f"Cache not found. Restoring Session from {session_json_path}")
        else:
            logging.info("Nothing to restore session from")
            return False

        try:
            with open(session_json_path, "r") as f:
                session = json.load(f)

            if "name" in session:
                self.__name__ = session["name"]
                self.name_changed.emit()
            if "id" in session:
                self.__id__ = session["id"]
                self.id_changed.emit()
            # if "selectedChannel" in session:
            #     self.__selected_channel__ = session["selectedChannel"]
            #     self.set_selected_channel(session["selectedChannel"], True)
            if "sketchpads" in session:
                self.__session_sketchpads_model__.deserialize(session["sketchpads"])
                self.session_sketchpads_model_changed.emit()
            if "lastSelectedSketchpad" in session:
                self.__last_selected_sketchpad__ = session["lastSelectedSketchpad"]
                self.zyngui.screens["sketchpad"].init_sketchpad(self.__last_selected_sketchpad__, sketchpad_loaded_cb)
            else:
                self.zyngui.screens["sketchpad"].init_sketchpad(None, sketchpad_loaded_cb)

            return True
        except Exception as e:
            logging.error(f"Error restoring session({session_json_path}) : {str(e)}")
            return False

    def fill_list(self):
        self.list_data = []
        self.list_metadata = []
        super().fill_list()

    def select_action(self, i, t='S'):
        self.index = i

    @Slot(None, result=float)
    def get_session_time(self):
        logging.debug((datetime.now() - self.__sessionStartTime).total_seconds())
        return (datetime.now() - self.__sessionStartTime).total_seconds()

    def set_select_path(self):
        self.select_path = "Session"
        self.select_path_element = "Session"
        super().set_select_path()

    @Slot(int, str)
    def setSketchpadSlot(self, slot, sketchpad):
        self.__session_sketchpads_model__.add_sketchpad(slot, sketchpad)
        self.schedule_save()

    @Slot(str)
    def load(self, sketchpad):
        self.__session_sketchpads_model__.clear()
        self.restore(sketchpad)

    @Slot(str, result=bool)
    def exists(self, filename):
        return (Path(self.__sessions_base_dir__) / (filename + ".json")).exists()

    def get_last_selected_sketchpad(self):
        return self.__last_selected_sketchpad__

    def set_last_selected_sketchpad(self, sketchpad):
        self.__last_selected_sketchpad__ = sketchpad
        self.schedule_save()

    # @Slot(None)
    # def disableNextSoundSwitchTimer(self):
    #     self.__change_channel_sound_timer__.setInterval(0)
