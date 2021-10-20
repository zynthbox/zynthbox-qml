#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# A model to store scenes of a song in ZynthiLoops
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
import logging

from PySide2.QtCore import QAbstractListModel, QObject, Qt, Property, Signal, Slot

from zynqtgui.zynthiloops.libzl.zynthiloops_clip import zynthiloops_clip


class zynthiloops_scenes_model(QAbstractListModel):
    SceneRole = Qt.UserRole + 1

    def __init__(self, song=None):
        super().__init__(song)
        self.__song__ = song
        self.__selected_scene_index__ = 0
        self.__scenes__ = {
            "0": {"name": "A", "clips": []},
            "1": {"name": "B", "clips": []},
            "2": {"name": "C", "clips": []},
            "3": {"name": "D", "clips": []},
            "4": {"name": "E", "clips": []},
            "5": {"name": "F", "clips": []},
            "6": {"name": "G", "clips": []},
            "7": {"name": "H", "clips": []},
            "8": {"name": "I", "clips": []},
            "9": {"name": "J", "clips": []},
            "10": {"name": "K", "clips": []},
            "11": {"name": "L", "clips": []},
        }

    def serialize(self):
        logging.error("### Serializing Scenes")
        scene_data = {}

        for key, val in self.__scenes__.items():
            scene_data[key] = {
                "name": val["name"],
                "clips": val["clips"].copy()
            }
            for index, clip in enumerate(scene_data[key]["clips"]):
                scene_data[key]["clips"][index] = {
                    "row": clip.row,
                    "col": clip.col
                }
        logging.error(f"{self.__scenes__}")
        return {
            "scenesData": scene_data,
            "selectedIndex": self.__selected_scene_index__
        }

    def deserialize(self, obj):
        logging.error("### Deserializing Scenes")
        if "scenesData" in obj:
            self.beginResetModel()
            for key, val in obj["scenesData"].items():
                self.__scenes__[key] = val.copy()
                for index, clip in enumerate(self.__scenes__[key]["clips"]):
                    self.__scenes__[key]["clips"][index] = self.__song__.getClip(clip["row"], clip["col"])
            self.endResetModel()

        if "selectedIndex" in obj:
            self.__selected_scene_index__ = obj["selectedIndex"]
            self.selected_scene_index_changed.emit()

    def data(self, index, role=None):
        if not index.isValid():
            return None

        if index.row() > len(self.__scenes__):
            return None

        if role == self.SceneRole:
            return self.getScene(index.row())
        else:
            return None

    def roleNames(self):
        role_names = {
            Qt.DisplayRole: b'display',
            self.SceneRole: b"scene",
        }

        return role_names

    def rowCount(self, index):
        return len(self.__scenes__)

    ### Property count
    def count(self):
        return len(self.__scenes__)
    countChanged = Signal()
    count = Property(int, count, notify=countChanged)
    ### END Property count

    ### Property selectedSceneIndex
    def get_selected_scene_index(self):
        return self.__selected_scene_index__
    def set_selected_scene_index(self, index):
        self.__selected_scene_index__ = index
        self.selected_scene_index_changed.emit()

        if self.__song__.get_metronome_manager().isMetronomeRunning:
            self.playScene(index)

        self.__song__.schedule_save()
    selected_scene_index_changed = Signal()
    selectedSceneIndex = Property(int, get_selected_scene_index, set_selected_scene_index, notify=selected_scene_index_changed)
    ### END Property selectedSceneIndex

    @Slot(int)
    def playScene(self, sceneIndex):
        scene = self.getScene(sceneIndex)

        for i in range(0, len(scene["clips"])):
            clip = scene["clips"][i]
            clip.play()

    @Slot(int)
    def stopScene(self, sceneIndex):
        scene = self.getScene(sceneIndex)

        for i in range(0, len(scene["clips"])):
            clip = scene["clips"][i]
            clip.stop()

    @Slot(int, result='QVariantMap')
    def getScene(self, index):
        return self.__scenes__[str(index)]

    @Slot(QObject)
    def toggleClipInCurrentScene(self, clip: zynthiloops_clip):
        if clip in self.getScene(self.__selected_scene_index__)["clips"]:
            self.getScene(self.__selected_scene_index__)["clips"].remove(clip)
        else:
            clips_model = self.__song__.tracksModel.getTrack(clip.row).clipsModel

            # Remove other clips in same track from scene before adding clip to scene
            for clip_index in range(0, clips_model.count):
                m_clip: zynthiloops_clip = clips_model.getClip(clip_index)

                if m_clip in self.getScene(self.__selected_scene_index__)["clips"]:
                    self.getScene(self.__selected_scene_index__)["clips"].remove(m_clip)

            self.getScene(self.__selected_scene_index__)["clips"].append(clip)

            if self.__song__.get_metronome_manager().isMetronomeRunning:
                clip.play()

        clip.in_current_scene_changed.emit()
        self.__song__.schedule_save()

    @Slot(QObject, int, result=bool)
    def isClipInScene(self, clip, sceneIndex):
        return clip in self.getScene(sceneIndex)["clips"]

    @Slot(QObject, result=bool)
    def isClipInCurrentScene(self, clip):
        return self.isClipInScene(clip, self.__selected_scene_index__)
