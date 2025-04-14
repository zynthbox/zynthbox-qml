#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# A model to store an arrangement of a song in Sketchpad, made from individual segments
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
import math

from PySide2.QtCore import QAbstractListModel, QObject, Qt, QTimer, Property, Signal, Slot
from zynqtgui import zynthian_gui_config
from zynqtgui.sketchpad.sketchpad_segment import sketchpad_segment


class sketchpad_segments_model(QAbstractListModel):
    SegmentRole = Qt.UserRole + 1

    def __init__(self, song, sketch):
        super().__init__(song)
        self.zynqtgui = zynthian_gui_config.zynqtgui

        self.__song = song
        self.__sketch = sketch
        self.__selected_segment_index = 0
        self.__segments = []
        self.totalBeatDurationThrottle = QTimer()
        self.totalBeatDurationThrottle.setInterval(1)
        self.totalBeatDurationThrottle.setSingleShot(True)
        self.totalBeatDurationThrottle.timeout.connect(self.totalReset)
        self.countChanged.connect(self.totalBeatDurationThrottle.start)
        self.countChangedThrottle = QTimer()
        self.countChangedThrottle.setInterval(1)
        self.countChangedThrottle.setSingleShot(True)
        self.countChangedThrottle.timeout.connect(self.countChanged.emit)

    @Slot(None)
    def totalReset(self):
        self.beginResetModel()
        self.endResetModel()
        self.totalBeatDurationChanged.emit()

    def serialize(self):
        logging.debug("### Serializing Segments Model")

        return [segment.serialize() for segment in self.__segments]

    def deserialize(self, obj):
        logging.debug("### Deserializing Segments Model")

        self.beginResetModel()
        self.__segments.clear()

        for index, segment_obj in enumerate(obj):
            segment = sketchpad_segment(self.__sketch, self, self.__song)
            segment.deserialize(segment_obj)
            self.add_segment(index, segment)

        # We must always have at least one segment
        if len(self.__segments) == 0:
            self.new_segment()

        self.__selected_segment_index = 0
        self.selectedSegmentIndexChanged.emit()

        self.endResetModel()

    def data(self, index, role=None):
        if not index.isValid():
            return None

        if index.row() > len(self.__segments):
            return None

        if role == self.SegmentRole:
            return self.__segments[index.row()]
        else:
            return None

    def roleNames(self):
        role_names = {
            Qt.DisplayRole: b'display',
            self.SegmentRole: b"segment",
        }

        return role_names

    def rowCount(self, index):
        return self.get_count()

    # Inserts the given segment at the given location
    @Slot(int, QObject)
    def add_segment(self, segment_index, segment: sketchpad_segment):
        self.__segments.insert(segment_index, segment)
        segment.barLengthChanged.connect(self.totalBeatDurationThrottle.start)
        segment.beatLengthChanged.connect(self.totalBeatDurationThrottle.start)
        self.countChangedThrottle.start()
        self.totalBeatDurationThrottle.start()
        if self.__selected_segment_index >= segment_index:
            self.__selected_segment_index = self.__selected_segment_index + 1
        self.selectedSegmentIndexChanged.emit()
        if not self.__song.isLoading:
            self.__song.schedule_save()

    # Creates a new segment at the given location
    # Returns the newly created segment
    @Slot(int, result=QObject)
    def new_segment(self, segment_index = -1):
        if segment_index == -1:
            segment_index = len(self.__segments)
        newSegment = sketchpad_segment(self.__sketch, self, self.__song)
        newSegment.barLengthChanged.connect(self.totalBeatDurationThrottle.start)
        newSegment.beatLengthChanged.connect(self.totalBeatDurationThrottle.start)
        self.__segments.insert(segment_index, newSegment)
        self.countChangedThrottle.start()
        self.totalBeatDurationThrottle.start()
        self.selectedSegmentIndexChanged.emit()
        if not self.__song.isLoading:
            self.__song.schedule_save()
        return newSegment

    # Inserts a TimerCommand to be run at the given position (can be either in the segment prior, or the segment after the split)
    # The function will first ensure the position exists, and then set the timer command to be run on the specific segment given
    # The command is given as a dictionary with the TimerCommand values (the command itself will be constructed by SegmentHandler)
    # {
    #     "operation": integer value, like TimerCommand::Operation
    #     "parameter": integer value,
    #     "parameter2": integer value,
    #     "parameter3": integer value,
    #     "parameter4": integer value,
    #     "bigParameter": a uint64 value,
    #     "dataParameter": a void pointer value,
    #     "variantParameter": a QVariant (as mentioned in the documentation for TimerCommand, this should be used extremely sparingly)
    # }
    @Slot(float, 'QVariant', bool)
    def insertTimerCommandAtSplit(self, splitPosition, timerCommandDetails, afterSplit = False):
        indexBeforeSplit = self.ensureSplit(splitPosition)
        if afterSplit == True:
            # If we are asking to add after the split, but the previous segment is the last in the list, then we need to ensure there's a segment after the split.
            if indexBeforeSplit + 1 == len(self.__segments):
                segmentToAddTimerCommandTo = self.new_segment();
            else:
                segmentToAddTimerCommandTo = self.get_segment(indexBeforeSplit + 1)
            segmentToAddTimerCommandTo.addTimerCommandBefore(timerCommandDetails)
        else:
            segmentToAddTimerCommandTo = self.get_segment(indexBeforeSplit)
            segmentToAddTimerCommandTo.addTimerCommandAfter(timerCommandDetails)

    # Ensure that a position given in beats exists (that is, that a segment exists which stops at that position)
    # The return value is the index of the position of the segment which stops at the given position
    # Note that if the given split position is 0 (that is, the start of the song), the returned index is -1
    # This may well seem reasonable when explained (any segment at position 0 would almost certainly not stop
    # at position 0), but it seems reasonable to make explicit.
    @Slot(float, result=int)
    def ensure_split(self, splitPosition):
        positionEnsured = False
        segmentIndex = -1
        logging.error(f"Checking for split position {splitPosition}")
        if splitPosition == 0:
            # logging.error("This is position zero, that'll always exist")
            positionEnsured = True
        else:
            totalPosition = 0
            for segment in self.__segments:
                segmentIndex = segmentIndex + 1
                # logging.error(f"Checking position {segmentIndex}")
                segmentLength = (segment.barLength * 4) + segment.beatLength
                if totalPosition + segmentLength == splitPosition:
                    # logging.error(f"Position already exists, great!")
                    # This is the best possible case - then the position already exists
                    positionEnsured = True
                    break
                elif totalPosition + segmentLength > splitPosition:
                    # The least best case - we need to split a segment into two
                    # First create the new segment, and give it a length far enough back that it starts at the position we want the split to be at
                    newSegmentLength = (totalPosition + segmentLength) - splitPosition
                    newSegmentBarLength = math.floor(newSegmentLength / 4)
                    newSegmentBeatLength = newSegmentLength - (newSegmentBarLength * 4)
                    newSegment = self.new_segment(segmentIndex + 1)
                    newSegment.barLength = newSegmentBarLength
                    newSegment.beatLength = newSegmentBeatLength
                    # Also ensure that the new segment has all the same clips the one we're splitting had
                    newSegment.clear_clips()
                    for clip in segment.clips.copy():
                        newSegment.addClip(clip)
                    # Move the post-segment timer commands to the new segment and remove them from the old
                    newSegment.timerCommandsAfter = segment.timerCommandsAfter
                    segment.timerCommandsAfter = []
                    # Now adjust the existing segment so that the new segment ends up stopping where the old one used to, and the old one stops at our split position
                    oldSegmentLength = segmentLength - newSegmentLength
                    oldSegmentBarLength = math.floor(oldSegmentLength / 4)
                    oldSegmentBeatLength = oldSegmentLength - (oldSegmentBarLength * 4)
                    segment.barLength = oldSegmentBarLength
                    segment.beatLength = oldSegmentBeatLength
                    positionEnsured = True
                    logging.error(f"The position exists inside the current segment which ends at {totalPosition + segmentLength}, split that segment in two segments with durations {oldSegmentLength} and {newSegmentLength}")
                    break
                totalPosition = totalPosition + segmentLength
            if positionEnsured == False:
                # logging.error("This position is further ahead than the end of the last position, so create a new segment and set the duration as expected")
                # In case we reached this position, we will need to add a new segment at the end, and
                # set its end point to the position we need, so the position exists as a stop
                newSegmentLength = splitPosition - totalPosition
                newSegmentBarLength = math.floor(newSegmentLength / 4)
                newSegmentBeatLength = newSegmentLength - (newSegmentBarLength * 4)
                newSegment = self.new_segment();
                newSegment.barLength = newSegmentBarLength
                newSegment.beatLength = newSegmentBeatLength
                segmentIndex = segmentIndex + 1
                positionEnsured = True
        totalPosition = 0;
        for segment in self.__segments:
            logging.error(f"segment {segment} at position {totalPosition} has duration {(segment.barLength * 4) + segment.beatLength} beats, with {len(segment.clips)} clips")
            totalPosition = totalPosition + (segment.barLength * 4) + segment.beatLength
        logging.error(f"Final segment ends at {totalPosition}")
        return segmentIndex

    # Position a clip to be played from start_position until end_position (as given in beats), creating any splits as required to make that possible
    @Slot(QObject, float, float)
    def insert_clip(self, clip, start_position, end_position):
        # Firstly, make sure that there are at least splits to work with
        firstSegmentIndex = self.ensure_split(start_position) + 1
        lastSegmentIndex = self.ensure_split(end_position)
        logging.error(f"Insert clip into segments from {firstSegmentIndex} to {lastSegmentIndex} inclusive given start and end positions of {start_position} and {end_position}")
        # Then add the clip to all segments in the now-known range
        for segmentIndex in range(firstSegmentIndex, lastSegmentIndex + 1):
            logging.error(f"Adding clip to segment {segmentIndex}")
            segment = self.__segments[segmentIndex]
            segment.addClip(clip)

    # Removes the given segment from the list of segments
    # Returns the segment which was removed from the list
    @Slot(int, result=QObject)
    def remove_segment(self, segment_index):
        segment = self.__segments.pop(segment_index)
        self.countChangedThrottle.start()
        self.totalBeatDurationThrottle.start()
        if self.__selected_segment_index == len(self.__segments):
            self.__selected_segment_index = self.__selected_segment_index - 1
        # Always emit the index changed signal here - even if we're staying in the same place, the selected /segment/ has changed
        self.selectedSegmentIndexChanged.emit()
        if not self.__song.isLoading:
            self.__song.schedule_save()
        return segment

    @Slot(QObject, result=int)
    def segment_index(self, segment: sketchpad_segment):
        if segment in self.__segments:
            return self.__segments.index(segment)
        return -1

    ### Property count
    def get_count(self):
        return len(self.__segments)

    countChanged = Signal()

    count = Property(int, get_count, notify=countChanged)
    ### END Property count

    @Slot(int, result=int)
    def beatDurationAtIndex(self, index):
        beatDuration = 0
        currentIndex = 0
        while currentIndex < len(self.__segments) and currentIndex < index:
            currentSegment = self.__segments[currentIndex]
            beatDuration += currentSegment.barLength * 4 + currentSegment.beatLength
            currentIndex += 1
        return beatDuration

    ### Property totalBeatDuration
    def get_totalBeatDuration(self):
        totalDuration = 0
        for segment in self.__segments:
            totalDuration += segment.barLength * 4 + segment.beatLength
        return totalDuration

    totalBeatDurationChanged = Signal()

    totalBeatDuration = Property(int, get_totalBeatDuration, notify=totalBeatDurationChanged)
    ### END Property totalBeatDuration

    ### Property selectedSegmentIndex
    def get_selectedSegmentIndex(self):
        return self.__selected_segment_index

    def set_selectedSegmentIndex(self, index):
        if self.__selected_segment_index != index and index > -1 and index < len(self.__segments):
            self.__selected_segment_index = index
            self.selectedSegmentIndexChanged.emit()

    selectedSegmentIndexChanged = Signal()

    selectedSegmentIndex = Property(int, get_selectedSegmentIndex, set_selectedSegmentIndex,
                                    notify=selectedSegmentIndexChanged)
    ### END Property selectedSegmentIndex

    ### Property selectedSegment
    def get_selectedSegment(self):
        return self.get_segment(self.__selected_segment_index)

    selectedSegment = Property(QObject, get_selectedSegment, notify=selectedSegmentIndexChanged)
    ### END Property selectedSegment

    @Slot(int,result=QObject)
    def get_segment(self, segment_index):
        if segment_index > -1 and segment_index < len(self.__segments):
            return self.__segments[segment_index]
        else:
            return None

    @Slot(QObject)
    def copyFrom(self, dest_segments_model):
        for segment_index in range(self.count):
            self.get_segment(segment_index).copyFrom(dest_segments_model.get_segment(segment_index))

    @Slot()
    def clear(self):
        self.beginResetModel()
        for segment_index in range(self.count):
            self.get_segment(segment_index).clear()
        self.endResetModel()
