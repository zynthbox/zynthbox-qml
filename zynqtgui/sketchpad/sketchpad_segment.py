#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Sketchpad Segment: An object to store a segment (single element in a segments model), representing rules for individual clips at a point in time
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

from PySide2.QtCore import Property, QObject, QTimer, Qt, Signal, Slot
from zynqtgui import zynthian_gui_config


class sketchpad_segment(QObject):
    def __init__(self, arrangement, segment_model, song):
        super().__init__(song)
        self.zynqtgui = zynthian_gui_config.zynqtgui

        self.__song = song
        self.__arrangement = arrangement
        self.__bar_length = 1
        self.__beat_length = 0
        self.__tick_length = 0
        self.__clips = []
        self.__restartClips = []
        self.__timerCommandDetailsBefore = []
        self.__timerCommandDetailsAfter = []

        self.__segment_model = segment_model
        self.__segment_model.countChanged.connect(self.segmentIdChanged.emit)
        self.__segment_model.totalBeatDurationChanged.connect(self.beatStartPositionChanged)

        # Update isEmpty when bar/beat length changes
        self.barLengthChanged.connect(self.isEmptyChanged.emit)
        self.beatLengthChanged.connect(self.isEmptyChanged.emit)
        self.clipsChanged.connect(self.isEmptyChanged.emit)

        # Update arrangement isEmpty when segment isEmpty is updated
        self.isEmptyChanged.connect(self.__arrangement.segment_is_empty_changed_handler, Qt.QueuedConnection)

        self.__song.scenesModel.selected_sketchpad_song_index_changed.connect(self.clipsChanged.emit)

    def serialize(self):
        logging.debug("### Serializing Segment")

        return {
            "barLength": self.__bar_length,
            "beatLength": self.__beat_length,
            "tickLength": self.__tick_length,
            "clips": [
                {
                    "row": clip.row,
                    "col": clip.col,
                    "id": clip.id
                } for clip in self.__clips
            ],
            "restartClips": [
                {
                    "row": clip.row,
                    "col": clip.col,
                    "id": clip.id
                } for clip in self.__restartClips
            ],
            "timerCommandDetailsBefore": [
                {
                    "operation": timerCommandDetails["operation"] if "operation" in timerCommandDetails else 0,
                    "parameter": timerCommandDetails["parameter"] if "parameter" in timerCommandDetails else 0,
                    "parameter2": timerCommandDetails["parameter2"] if "parameter2" in timerCommandDetails else 0,
                    "parameter3": timerCommandDetails["parameter3"] if "parameter3" in timerCommandDetails else 0,
                    "parameter4": timerCommandDetails["parameter4"] if "parameter4" in timerCommandDetails else 0,
                    "bigParameter": timerCommandDetails["bigParameter"] if "bigParameter" in timerCommandDetails else 0,
                    "dataParameter": timerCommandDetails["dataParameter"] if "dataParameter" in timerCommandDetails else 0,
                    "variantParameter": timerCommandDetails["variantParameter"] if "variantParameter" in timerCommandDetails else None
                } for timerCommandDetails in self.__timerCommandDetailsBefore
            ],
            "timerCommandDetailsAfter": [
                {
                    "operation": timerCommandDetails["operation"] if "operation" in timerCommandDetails else 0,
                    "parameter": timerCommandDetails["parameter"] if "parameter" in timerCommandDetails else 0,
                    "parameter2": timerCommandDetails["parameter2"] if "parameter2" in timerCommandDetails else 0,
                    "parameter3": timerCommandDetails["parameter3"] if "parameter3" in timerCommandDetails else 0,
                    "parameter4": timerCommandDetails["parameter4"] if "parameter4" in timerCommandDetails else 0,
                    "bigParameter": timerCommandDetails["bigParameter"] if "bigParameter" in timerCommandDetails else 0,
                    "dataParameter": timerCommandDetails["dataParameter"] if "dataParameter" in timerCommandDetails else 0,
                    "variantParameter": timerCommandDetails["variantParameter"] if "variantParameter" in timerCommandDetails else None
                } for timerCommandDetails in self.__timerCommandDetailsAfter
            ]
        }

    def deserialize(self, obj):
        logging.debug("### Deserializing Segment")

        if "barLength" in obj:
            self.set_barLength(obj["barLength"], True)
        if "beatLength" in obj:
            self.set_beatLength(obj["beatLength"], True)
        if "tickLength" in obj:
            self.set_tickLength(obj["tickLength"], True)
        else:
            self.set_tickLength(0, True)
        if "clips" in obj:
            for clip in obj["clips"]:
                if "part" in clip:
                    # TODO Old stuff, remove before release
                    self.__clips.append(self.__song.getClipById(clip["row"], clip["col"], clip["part"]))
                else:
                    self.__clips.append(self.__song.getClipById(clip["row"], clip["col"], clip["id"]))
        if "restartClips" in obj:
            for clip in obj["restartClips"]:
                if "part" in clip:
                    self.__restartClips.append(self.__song.getClipById(clip["row"], clip["col"], clip["part"]))
                else:
                    self.__restartClips.append(self.__song.getClipById(clip["row"], clip["col"], clip["id"]))
        self.__timerCommandDetailsBefore = []
        if "timerCommandDetailsBefore" in obj:
            for timerCommandDetails in obj["timerCommandDetailsBefore"]:
                self.__timerCommandDetailsBefore.append({ "operation": timerCommandDetails["operation"], "parameter": timerCommandDetails["parameter"], "parameter2": timerCommandDetails["parameter2"], "parameter3": timerCommandDetails["parameter3"], "parameter4": timerCommandDetails["parameter4"], "bigParameter": timerCommandDetails["bigParameter"], "dataParameter": timerCommandDetails["dataParameter"], "variantParameter": timerCommandDetails["variantParameter"] })
        self.__timerCommandDetailsAfter = []
        if "timerCommandDetailsAfter" in obj:
            for timerCommandDetails in obj["timerCommandDetailsAfter"]:
                self.__timerCommandDetailsAfter.append({ "operation": timerCommandDetails["operation"], "parameter": timerCommandDetails["parameter"], "parameter2": timerCommandDetails["parameter2"], "parameter3": timerCommandDetails["parameter3"], "parameter4": timerCommandDetails["parameter4"], "bigParameter": timerCommandDetails["bigParameter"], "dataParameter": timerCommandDetails["dataParameter"], "variantParameter": timerCommandDetails["variantParameter"] })

    def clear_clips(self):
        for clip in self.clips.copy():
            self.removeClip(clip)

    ### Property className
    def get_className(self):
        return "sketchpad_segment"

    className = Property(str, get_className, constant=True)
    ### END Property className

    ### Property name
    def get_name(self):
        return f"Segment {self.get_segmentId() + 1}"

    name = Property(str, get_name, constant=True)
    ### END Property name

    ### Property arrangementId
    def get_arrangementId(self):
        return self.__arrangement.arrangementId

    arrangementIdChanged = Signal()

    arrangementId = Property(int, get_arrangementId, notify=arrangementIdChanged)
    ### END Property arrangementId

    ### Property segmentId
    def get_segmentId(self):
        return self.__segment_model.segment_index(self)

    segmentIdChanged = Signal()

    segmentId = Property(int, get_segmentId, notify=segmentIdChanged)
    ### END Property segmentId

    ### Property isEmpty
    def get_isEmpty(self):
        if self.__bar_length == 0 and \
                self.__beat_length == 0 and \
                len(self.__clips) == 0:
            return True
        else:
            return False

    isEmptyChanged = Signal()

    isEmpty = Property(bool, get_isEmpty, notify=isEmptyChanged)
    ### END Property isEmpty

    ### Property barLength
    def get_barLength(self):
        return self.__bar_length

    def set_barLength(self, length, force_set=False):
        if self.__bar_length != length or force_set:
            self.__bar_length = length

            if self.zynqtgui.sketchpad.song is not None:
                self.zynqtgui.sketchpad.song.schedule_save()

            self.barLengthChanged.emit()

    barLengthChanged = Signal()

    barLength = Property(int, get_barLength, set_barLength, notify=barLengthChanged)
    ### END Property barLength

    ### Property beatLength
    def get_beatLength(self):
        return self.__beat_length

    def set_beatLength(self, length, force_set=False):
        if self.__beat_length != length or force_set:
            self.__beat_length = length

            if self.zynqtgui.sketchpad.song is not None:
                self.zynqtgui.sketchpad.song.schedule_save()

            self.beatLengthChanged.emit()

    beatLengthChanged = Signal()

    beatLength = Property(int, get_beatLength, set_beatLength, notify=beatLengthChanged)
    ### END Property beatLength

    ### BEGIN Property tickLength
    def get_tickLength(self):
        return self.__tick_length

    def set_tickLength(self, length, force_set=False):
        if self.__tick_length != length or force_set:
            self.__tick_length = length

            if self.zynqtgui.sketchpad.song is not None:
                self.zynqtgui.sketchpad.song.schedule_save()

            self.tickLengthChanged.emit()

    tickLengthChanged = Signal()

    tickLength = Property(int, get_tickLength, set_tickLength, notify=tickLengthChanged)
    ### END Property tickLength

    ### BEGIN Property beatStartPosition
    def get_beatStartPosition(self):
        return self.__segment_model.beatDurationAtIndex(self.__segment_model.segment_index(self))
    beatStartPositionChanged = Signal()
    beatStartPosition = Property(int, get_beatStartPosition, notify=beatStartPositionChanged)
    ### END Property beatStartPosition

    ### Property clips
    def get_clips(self):
        return self.__clips

    def set_clips(self, clips):
        self.__clips.clear()
        self.__clips = clips
        self.clipsChanged.emit()

    clipsChanged = Signal()

    clips = Property('QVariantList', get_clips, set_clips, notify=clipsChanged)
    ### END Property clips

    ### BEGIN Property restartClips
    @Slot(QObject, result=bool)
    def restartClip(self, clip:QObject):
        return clip in self.__restartClips

    @Slot(QObject, bool, result=None)
    def setRestartClip(self, clip:QObject, restart:bool):
        if restart == True and clip not in self.__restartClips:
            self.addClip(clip)
            self.__restartClips.append(clip)
            self.restartClipsChanged.emit()
            if self.zynqtgui.sketchpad.song is not None:
                self.zynqtgui.sketchpad.song.schedule_save()
        elif restart == False and clip in self.__restartClips:
            self.__restartClips.remove(clip)
            self.restartClipsChanged.emit()
            if self.zynqtgui.sketchpad.song is not None:
                self.zynqtgui.sketchpad.song.schedule_save()

    def get_restartClips(self):
        return self.__restartClips
    restartClipsChanged = Signal()
    restartClips = Property("QVariantList", get_restartClips, notify=restartClipsChanged)
    ### END Property restartClips

    ### BEGIN Property timerCommandDetailsBefore
    @Slot('QVariant')
    def addTimerCommandBefore(self, timerCommandDetails):
        self.__timerCommandDetailsBefore.append(timerCommandDetails.toVariant())
        self.timerCommandDetailsBeforeChanged.emit()

    @Slot(int, 'QVariant')
    def replaceTimerCommandBefore(self, index, timerCommandDetails):
        if -1 < index and index < len(self.__timerCommandDetailsBefore):
            self.__timerCommandDetailsBefore[index] = timerCommandDetails.toVariant()
            self.timerCommandDetailsBeforeChanged.emit()

    @Slot(int)
    def removeTimerCommandBefore(self, index):
        if -1 < index and index < len(self.__timerCommandDetailsBefore):
            self.__timerCommandDetailsBefore.pop(index)
            self.timerCommandDetailsBeforeChanged.emit()

    def get_timerCommandsDetailsBefore(self):
        return self.__timerCommandDetailsBefore
    def set_timerCommandsDetailsBefore(self, newDetails):
        self.__timerCommandDetailsBefore = newDetails
        self.timerCommandDetailsBeforeChanged.emit()
    timerCommandDetailsBeforeChanged = Signal()
    timerCommandDetailsBefore = Property("QVariantList", get_timerCommandsDetailsBefore, set_timerCommandsDetailsBefore, notify=timerCommandDetailsBeforeChanged)
    ### END Property timerCommandDetailsBefore

    ### BEGIN Property timerCommandDetailsAfter
    @Slot('QVariant')
    def addTimerCommandAfter(self, timerCommandDetails):
        self.__timerCommandDetailsAfter.append(timerCommandDetails.toVariant())
        self.timerCommandDetailsAfterChanged.emit()

    @Slot(int, 'QVariant')
    def replaceTimerCommandAfter(self, index, timerCommandDetails):
        if -1 < index and index < len(self.__timerCommandDetailsAfter):
            self.__timerCommandDetailsAfter[index] = timerCommandDetails.toVariant()
            self.timerCommandDetailsAfterChanged.emit()

    @Slot(int)
    def removeTimerCommandAfter(self, index):
        if -1 < index and index < len(self.__timerCommandDetailsAfter):
            self.__timerCommandDetailsAfter.pop(index)
            self.timerCommandDetailsAfterChanged.emit()

    def get_timerCommandsDetailsAfter(self):
        return self.__timerCommandDetailsAfter
    def set_timerCommandsDetailsAfter(self, newDetails):
        self.__timerCommandDetailsAfter = newDetails
        self.timerCommandDetailsAfterChanged.emit()
    timerCommandDetailsAfterChanged = Signal()
    timerCommandDetailsAfter = Property("QVariantList", get_timerCommandsDetailsAfter, set_timerCommandsDetailsAfter, notify=timerCommandDetailsAfterChanged)
    ### END Property timerCommandDetailsAfter

    @Slot(QObject, result=None)
    def addClip(self, clip):
        """
        Add clip to a segment
        """

        if clip not in self.__clips:
            # Don't limit the number of concurrent clips on a track the way we do for non-song-mode playback - kind of gets in the way of things a lot...
            # TODO does this need to just go away on a global level, not just for song mode?

            logging.debug(f"Adding clip(row: {clip.row}, col: {clip.col}) to segment {self.segmentId}")
            self.__clips.append(clip)
            self.zynqtgui.sketchpad.song.arrangementsModel.clipAdded.emit(self.__arrangement.arrangementId, self.segmentId, clip)
            self.clipsChanged.emit()

            # If we are editing the model, ensure multiclip is taken into account
            # For playback purposes, this is done by SegmentHandler, which will check
            # when updating, whether there are multiple clips set to run on a track,
            # and then only allow whatever the first one is.
            if clip.channel and clip.channel.allowMulticlip == False:
                clipsToRemove = []
                for otherClip in self.__clips:
                    if otherClip != clip and otherClip.channel == clip.channel:
                        clipsToRemove.append(otherClip)
                for otherClip in clipsToRemove:
                    self.removeClip(otherClip)

            if self.zynqtgui.sketchpad.song is not None:
                self.zynqtgui.sketchpad.song.schedule_save()

    @Slot(QObject, result=None)
    def removeClip(self, clip):
        """
        Remove clip from a segment
        """

        if clip in self.__clips:
            logging.debug(f"Removing clip(row: {clip.row}, col: {clip.col}) from segment {self.segmentId}")
            self.__clips.remove(clip)
            self.zynqtgui.sketchpad.song.arrangementsModel.clipRemoved.emit(self.__arrangement.arrangementId, self.segmentId, clip)
            self.clipsChanged.emit()
            self.setRestartClip(clip, False)

            if self.zynqtgui.sketchpad.song is not None:
                self.zynqtgui.sketchpad.song.schedule_save()

    @Slot(QObject, result=None)
    def toggleClip(self, clip):
        """
        Toggle clip in a segment
        """

        if clip in self.__clips:
            self.removeClip(clip)
        else:
            self.addClip(clip)

    @Slot(int)
    def copyClipsFromScene(self, sceneIndex):
        """
        Copy clips from a scene to current segment
        """

        # Remove all previously selected clips of current sketchpad from this segment
        self.__clips = [clip for clip in self.__clips if clip.col != self.zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex]

        # Add all clips of current sketchpad from selected scene to this segment
        for scene_clip in self.zynqtgui.sketchpad.song.scenesModel.getScene(sceneIndex)["clips"]:
            if scene_clip.col == self.zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex:
                self.addClip(scene_clip)

    @Slot(QObject)
    def copyFrom(self, origin_segment):
        self.barLength = origin_segment.barLength
        self.beatLength = origin_segment.beatLength
        self.clear_clips()

        for clip in origin_segment.clips.copy():
            self.addClip(clip)

    @Slot()
    def clear(self):
        self.barLength = 0
        self.beatLength = 0
        self.clear_clips()

    @Slot(result=int)
    def getOffsetInBeats(self):
        offset = 0

        # Iterate all segments till current to determine offset in beats
        for segment_index in range(self.segmentId):
            segment = self.__arrangement.segmentsModel.get_segment(segment_index)
            offset += segment.barLength * 4 + segment.beatLength

        return offset
