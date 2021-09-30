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

from datetime import datetime

# Zynthian specific modules
from pathlib import Path

from zynqtgui import zynthian_gui_selector

# Qt modules
from PySide2.QtCore import QTimer, Qt, QObject, Slot, Signal, Property


#------------------------------------------------------------------------------
# Zynthian Session Dashboard GUI Class
#------------------------------------------------------------------------------
from zynqtgui.session_dashboard.session_dashboard_session_sketches_model import session_dashboard_session_sketches_model


class zynthian_gui_session_dashboard(zynthian_gui_selector):

    def __init__(self, parent=None):
        super(zynthian_gui_session_dashboard, self).__init__('Session', parent)
        self.__sessionStartTime = datetime.now()
        self.__sessions_base_dir__ = Path("/zynthian/zynthian-my-data/sessions/")
        self.__save_timer__ = QTimer(self)
        self.__session_sketches_model__ = session_dashboard_session_sketches_model(self)
        self.__cache_json_path__ = self.__sessions_base_dir__ / ".cache.json"

        if not self.restore():
            self.__name__ = None
            self.__id__ = 0

        self.__save_timer__.setInterval(1000)
        self.__save_timer__.setSingleShot(True)
        self.__save_timer__.timeout.connect(self.save)

        self.show()

    ### Property name
    def get_name(self):
        if self.__name__ is not None:
            return self.__name__
        else:
            return f"Session {self.__id__ + 1}"
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

    ### Property sessionSketchesModel
    def get_session_sketches_model(self):
        return self.__session_sketches_model__
    session_sketches_model_changed = Signal()
    sessionSketchesModel = Property(QObject, get_session_sketches_model, notify=session_sketches_model_changed)
    ### END Property sessionSketchesModel

    def serialize(self):
        return {
            "name": self.__name__,
            "id": self.__id__,
            "sketches": self.__session_sketches_model__.serialize()
        }

    def schedule_save(self):
        self.__save_timer__.start()

    def save(self):
        # Save session to cache
        self.__sessions_base_dir__.mkdir(parents=True, exist_ok=True)

        logging.error(f"Saving session to cache : {self.__cache_json_path__}")

        with open(self.__cache_json_path__, "w") as f:
            json.dump(self.serialize(), f)

    @Slot(str)
    def saveAs(self, fileName):
        session_json_path = self.__sessions_base_dir__ / (fileName + ".json")
        logging.error(f"Saving session to file : {session_json_path}")

        with open(session_json_path, "w") as f:
            json.dump(self.serialize(), f)

        logging.error(f"Deleting cache : {self.__cache_json_path__}")

        try:
            self.__cache_json_path__.unlink()
        except:
            pass

    def restore(self, sketch=""):
        if self.__cache_json_path__.exists():
            logging.error(f"Cache found. Restoring Session from {self.__cache_json_path__}")
            session_json_path = self.__cache_json_path__
        elif len(sketch) > 0 and Path(sketch).exists():
            session_json_path = Path(sketch)
            logging.error(f"Cache not found. Restoring Session from {session_json_path}")
        else:
            logging.error("Nothing to restore session from")
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
            if "sketches" in session:
                self.__session_sketches_model__.deserialize(session["sketches"])
                self.session_sketches_model_changed.emit()

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
        logging.error((datetime.now() - self.__sessionStartTime).total_seconds())
        return (datetime.now() - self.__sessionStartTime).total_seconds()

    def set_select_path(self):
        self.select_path = "Session"
        self.select_path_element = "Session"
        super().set_select_path()

    @Slot(int, str)
    def setSketchSlot(self, slot, sketch):
        self.__session_sketches_model__.add_sketch(slot, sketch)
        self.schedule_save()

    @Slot(str)
    def load(self, sketch):
        self.__session_sketches_model__.clear()
        self.restore(sketch)

    @Slot(str, result=bool)
    def exists(self, filename):
        return (Path(self.__sessions_base_dir__) / (filename + ".json")).exists()
