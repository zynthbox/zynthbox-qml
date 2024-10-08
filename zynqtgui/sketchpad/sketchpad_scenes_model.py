#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# A model to store scenes of a song in Sketchpad
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
import Zynthbox

from PySide2.QtCore import QAbstractListModel, QObject, QTimer, Qt, Property, Signal, Slot

from zynqtgui import zynthian_gui_config
from zynqtgui.sketchpad.sketchpad_clip import sketchpad_clip


class sketchpad_scenes_model(QAbstractListModel):
    SceneRole = Qt.UserRole + 1

    def __init__(self, song=None):
        super().__init__(song)
        self.zynqtgui = zynthian_gui_config.zynqtgui
        self.__song__ = song
        self.__selected_sketchpad_song_index__ = 0
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
        }

        self.selected_sketchpad_song_index_changed.connect(self.__song__.setBpmFromTrack)

        self.__track_name_change_timer = QTimer(self)
        self.__track_name_change_timer.setInterval(10)
        self.__track_name_change_timer.setSingleShot(True)
        self.__track_name_change_timer.timeout.connect(self.selected_sketchpad_song_name_changed)

        self.__new_name_change_timer = QTimer(self)
        self.__new_name_change_timer.setInterval(10)
        self.__new_name_change_timer.setSingleShot(True)
        self.__new_name_change_timer.timeout.connect(self.selected_scene_name_changed)

    def serialize(self):
        logging.debug("### Serializing Scenes")
        scene_data = {}

        for key, val in self.__scenes__.items():
            scene_data[key] = {
                "name": val["name"],
                "clips": [{
                    "row": clip.row,
                    "col": clip.col,
                    "id": clip.id
                } for clip in val["clips"].copy() if clip is not None]
            }
        return {
            "scenesData": scene_data,
            "selectedSketchpadSongIndex": self.__selected_sketchpad_song_index__,
            "selectedSceneIndex": self.__selected_scene_index__,
        }

    def deserialize(self, obj):
        logging.debug("### Deserializing Scenes")
        if "scenesData" in obj:
            self.beginResetModel()
            for key, val in obj["scenesData"].items():
                self.__scenes__[key] = val.copy()
                for index, clip in enumerate(self.__scenes__[key]["clips"]):
                    if "part" in clip:
                        # TODO Old stuff, remove before release
                        self.__scenes__[key]["clips"][index] = self.__song__.getClipById(clip["row"], clip["col"], clip["part"])
                    else:
                        self.__scenes__[key]["clips"][index] = self.__song__.getClipById(clip["row"], clip["col"], clip["id"])
            self.endResetModel()

        if "selectedSketchpadSongIndex" in obj:
            self.__selected_sketchpad_song_index__ = obj["selectedSketchpadSongIndex"]
            self.selected_sketchpad_song_index_changed.emit()

        if "selectedSceneIndex" in obj:
            self.__selected_scene_index__ = obj["selectedSceneIndex"]
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

    ### Property selectedSketchpadSongIndex
    def get_selected_sketchpad_song_index(self):
        return self.__selected_sketchpad_song_index__
    def set_selected_sketchpad_song_index(self, index, force_set=False):
        if self.__selected_sketchpad_song_index__ != index or force_set is True:
            self.stopScene(self.selectedSceneIndex, self.selectedSketchpadSongIndex)
            self.__selected_sketchpad_song_index__ = index
            self.playScene(self.selectedSceneIndex, self.selectedSketchpadSongIndex)
            self.__song__.schedule_save()

            self.selected_sketchpad_song_index_changed.emit()
            self.syncClipsEnabledFromCurrentScene()
            self.__track_name_change_timer.start()

    selected_sketchpad_song_index_changed = Signal()
    selectedSketchpadSongIndex = Property(int, get_selected_sketchpad_song_index, set_selected_sketchpad_song_index, notify=selected_sketchpad_song_index_changed)
    ### END Property selectedSketchpadSongIndex

    ### Property selectedSceneIndex
    def get_selected_scene_index(self):
        return self.__selected_scene_index__
    def set_selected_scene_index(self, index):
        self.stopScene(self.selectedSceneIndex, self.selectedSketchpadSongIndex)
        self.__selected_scene_index__ = index
        self.playScene(self.selectedSceneIndex, self.selectedSketchpadSongIndex)
        self.__song__.schedule_save()

        self.selected_scene_index_changed.emit()
        self.syncClipsEnabledFromCurrentScene()
        self.__new_name_change_timer.start()

    selected_scene_index_changed = Signal()
    selected_scene_name_changed = Signal()
    selectedSceneIndex = Property(int, get_selected_scene_index, set_selected_scene_index, notify=selected_scene_index_changed)
    ### END Property selectedSketchpadSongIndex

    ### Property selectedSketchpadSongName
    def get_selected_sketchpad_song_name(self):
        return f"T{self.__selected_sketchpad_song_index__ + 1}"

    selected_sketchpad_song_name_changed = Signal()

    selectedSketchpadSongName = Property(str, get_selected_sketchpad_song_name, notify=selected_sketchpad_song_name_changed)
    ### END Property selectedSketchpadSongName

    ### Property selectedSequenceName
    # Convenience property for the name of the sequence matching the currently selected track
    def get_selected_sequence_name(self):
        if self.__selected_sketchpad_song_index__ == 0:
            return "global"
        return f"global{self.__selected_sketchpad_song_index__ + 1}"
    selectedSequenceName = Property(str, get_selected_sequence_name, notify=selected_sketchpad_song_name_changed)
    ### END Property selectedSequenceName

    ### Property selectedSceneName
    def get_selected_scene_name(self):
        return chr(self.__selected_scene_index__ + 65)

    selectedSceneName = Property(str, get_selected_scene_name, notify=selected_scene_name_changed)
    ### END Property selectedSceneName

    def syncClipsEnabledFromCurrentScene(self):
        # Sync enabled attribute for clips in scene
        for trackIndex in range(0, Zynthbox.Plugin.instance().sketchpadTrackCount()):
            for clipId in range(0, Zynthbox.Plugin.instance().sketchpadSlotCount()):
                clip = self.__song__.getClipById(trackIndex, self.selectedSketchpadSongIndex, clipId)

                if clip is not None and self.isClipInCurrentScene(clip):
                    clip.enabled = True
                else:
                    clip.enabled = False

    @Slot(int)
    def playScene(self, sceneIndex, trackIndex=-1):
        scene = self.getScene(sceneIndex)

        for i in range(0, len(scene["clips"])):
            clip = scene["clips"][i]

            # Start all clips except clip to be recorded
            if clip != self.zynqtgui.sketchpad.clipToRecord and (trackIndex < 0 or (0 <= trackIndex == clip.col)):
                clip.play()

    @Slot(int)
    def stopScene(self, sceneIndex, trackIndex=-1):
        scene = self.getScene(sceneIndex)

        for i in range(0, len(scene["clips"])):
            clip = scene["clips"][i]
            if trackIndex < 0 or (0 <= trackIndex == clip.col):
                clip.stop()

    @Slot(int, result='QVariantMap')
    def getScene(self, index):
        return self.__scenes__[str(index)]

    @Slot(QObject)
    def toggleClipInCurrentScene(self, clip: sketchpad_clip):
        if clip in self.getScene(self.__selected_scene_index__)["clips"]:
            self.removeClipFromCurrentScene(clip)
        else:
            self.addClipToCurrentScene(clip)

    @Slot(QObject)
    def addClipToCurrentScene(self, clip):
        if clip in self.getScene(self.__selected_scene_index__)["clips"]:
            self.removeClipFromCurrentScene(clip)

        self.getScene(self.__selected_scene_index__)["clips"].append(clip)

        if self.__song__.get_metronome_manager().isMetronomeRunning:
            clip.play()

        self.clipCountChanged.emit()
        clip.in_current_scene_changed.emit()
        self.__song__.schedule_save()

    @Slot(QObject)
    def removeClipFromCurrentScene(self, clip):
        try:
            self.getScene(self.__selected_scene_index__)["clips"].remove(clip)
        except Exception as e:
            # logging.debug(f"Error removing clip from scene : {str(e)}")
            pass

        if self.__song__.get_metronome_manager().isMetronomeRunning:
            clip.stop()

        self.clipCountChanged.emit()
        clip.in_current_scene_changed.emit()
        self.__song__.schedule_save()

    @Slot(QObject, int, result=bool)
    def isClipInScene(self, clip, sceneIndex):
        return clip in self.getScene(sceneIndex)["clips"]

    @Slot(QObject, result=bool)
    def isClipInCurrentScene(self, clip):
        return self.isClipInScene(clip, self.__selected_scene_index__)

    @Slot(int, result=int)
    def clipCountInScene(self, scene_index):
        return len(self.getScene(scene_index)["clips"])

    @Slot(int, int, result=None)
    def copyTrack(self, from_track, to_track):
        for i in range(0, self.__song__.channelsModel.count):
            channel = self.__song__.channelsModel.getChannel(i)
            for clipId in range(0, Zynthbox.Plugin.instance().sketchpadSlotCount()):
                channel.clips[clipId].getClip(to_track).copyFrom(channel.clips[clipId].getClip(from_track))

    clipCountChanged = Signal()
