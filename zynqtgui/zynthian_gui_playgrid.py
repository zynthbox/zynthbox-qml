#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthian PlayGrid: A page to play ntoes with buttons
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

import mido
import typing
import logging

from PySide2.QtCore import (
    Slot,
    QAbstractItemModel,
    Qt,
    QModelIndex,
    QObject,
    Property,
    Signal,
)
from PySide2.QtQml import qmlRegisterType
from . import zynthian_qt_gui_base


class Note(QObject):
    def __init__(
        self,
        name: str,
        scale_index: int,
        octave: int,
        midi_note: int,
        midi_port,
        parent: QObject = None,
    ):
        super(Note, self).__init__(parent)
        self.__note_name__ = name
        self.__scale_index__ = scale_index
        self.__octave__ = octave
        self.__is_playing__ = False
        self.__midi_note__ = midi_note
        self.__midi_port__ = midi_port
        self.__midi_note_on_msg__ = mido.Message(
            "note_on", note=self.__midi_note__
        )
        self.__midi_note_off_msg__ = mido.Message(
            "note_off", note=self.__midi_note__
        )
        self.__midi_notes_on_msgs__ = []
        self.__midi_notes_off_msgs__ = []
        self.__subnotes__ = [];

    def get_midi_note(self):
        return self.__midi_note__

    def get_scale_index(self):
        return self.__scale_index__

    def get_is_playing(self):
        return self.__is_playing__

    def set_is_playing(self, playing: bool):
        self.__is_playing__ = playing
        self.__is_playing_changed__.emit()

    @Signal
    def __is_playing_changed__(self):
        pass

    def get_subnotes(self):
        return self.__subnotes__

    def set_subnotes(self, subnotes):
        self.__subnotes__ = subnotes
        self.__subnotes_changed__.emit()
        if (len(subnotes) > 0):
            messages_on = []
            messages_off = []
            for i in range(0, len(subnotes)):
                messages_on.append(mido.Message(
                    "note_on", note=subnotes[i].__midi_note__
                ))
                messages_off.append(mido.Message(
                    "note_off", note=subnotes[i].__midi_note__
                ))
            self.__midi_notes_on_msgs__ = messages_on
            self.__midi_notes_off_msgs__ = messages_off

    @Signal
    def __subnotes_changed__(self):
        pass

    @Slot(int)
    def on(self, _velocity: int = 64):
        if (len(self.__midi_notes_on_msgs__) > 0):
            for i in range(0, len(self.__midi_notes_on_msgs__)):
                self.__midi_notes_on_msgs__[i].velocity = _velocity
                self.__midi_port__.send(self.__midi_notes_on_msgs__[i])
        else:
            self.__midi_note_on_msg__.velocity = _velocity
            self.__midi_port__.send(self.__midi_note_on_msg__)

    @Slot(None)
    def off(self):
        if (len(self.__midi_notes_off_msgs__) > 0):
            for i in range(0, len(self.__midi_notes_off_msgs__)):
                self.__midi_port__.send(self.__midi_notes_off_msgs__[i])
        else:
            self.__midi_port__.send(self.__midi_note_off_msg__)

    @Property(str, constant=True)
    def name(self):
        return self.__note_name__

    @Property(int, constant=True)
    def octave(self):
        return self.__octave__

    isPlaying = Property(
        bool, get_is_playing, set_is_playing, notify=__is_playing_changed__
    )
    subnotes = Property(
        'QVariantList', get_subnotes, set_subnotes, notify=__subnotes_changed__
    )


class zynthian_gui_grid_notes_model(QAbstractItemModel):
    NoteRole = Qt.DisplayRole

    def __init__(self, parent: QObject = None) -> None:
        super(zynthian_gui_grid_notes_model, self).__init__(parent)

    def roleNames(self) -> typing.Dict:
        roles = {self.NoteRole: b"note"}

        return roles

    def data(self, index: QModelIndex, role: int) -> Note:
        if not index.isValid():
            return None

        if role == self.NoteRole:
            return self.__grid_notes__[index.row()][index.column()]
        else:
            return None

    def rowCount(self, index):
        return len(self.__grid_notes__)

    def columnCount(self, index):
        return len(self.__grid_notes__[index.row()])

    def index(self, row: int, column: int, parent: QModelIndex = None):
        return self.createIndex(row, column)

    def parent(self, index):
        return QModelIndex()

    def set_grid(self, grid):
        self.__grid_notes__ = grid

    def highlight_playing_note(
        self, playingNote: Note, highlight: bool = True
    ):
        for row in self.__grid_notes__:
            for note in row:
                if note.get_midi_note() == playingNote.get_midi_note():
                    note.set_is_playing(highlight)

    @Property(dict, constant=True)
    def roles(self):
        return {b"note": zynthian_gui_grid_notes_model.NoteRole}


class zynthian_gui_playgrid(zynthian_qt_gui_base.ZynGui):
    __rows__: int = 5
    __columns__: int = 8
    __starting_note__: int = 36
    __scale__ = "ionian"
    __pitch__ = 0
    __chord_model__: QAbstractItemModel = None
    __chord_rows__ = 5

    __positional_velocity__ = False

    def __init__(self, parent=None):
        super(zynthian_gui_playgrid, self).__init__(parent)

        self.__chord_scales__ = [
            "ionian",
            "chromatic",
            "phrygian",
            "aeolian",
            "locrian"
        ]
        self.__chord_scales_starts__ = [
            36,
            36,
            36,
            36,
            36
        ]

        self.__model__ = zynthian_gui_grid_notes_model(self)
        self.__chord_model__ = zynthian_gui_grid_notes_model(self)

        self.__midi_port__ = mido.open_output("Midi Through Port-0")
        self.__populate_grid__()
        self.__midi_port__ = mido.open_output("Midi Through Port-0")

        self.__populate_grid__()

    def show(self):
        pass

    def zyncoder_read(self):
        pass

    def refresh_loading(self):
        pass

    ###
    # The grid generation logic follows Ableton's grid mapping which is :
    #   Horizontally  : 1 Half Note per cell
    #   Vertically    : 5 Half Notes per cell
    ###
    def __populate_grid__(self) -> None:
        note_int_to_str_map = [
            "C",
            "C#",
            "D",
            "D#",
            "E",
            "F",
            "F#",
            "G",
            "G#",
            "A",
            "A#",
            "B",
        ]
        scale_mode_map = {
            "chromatic": [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
            "ionian": [2, 2, 1, 2, 2, 2, 1],
            "dorian": [2, 1, 2, 2, 2, 1, 2],
            "phrygian": [1, 2, 2, 2, 1, 2, 2],
            "lydian": [2, 2, 2, 1, 2, 2, 1],
            "mixolydian": [2, 2, 1, 2, 2, 1, 2],
            "aeolian": [2, 1, 2, 2, 1, 2, 2],
            "locrian": [1, 2, 2, 1, 2, 2, 2],
        }

        ##########################################
        # First we sort out our notes grid
        ##########################################
        grid_notes = []

        # Scale index is the index of the current note in scale from scale_mode_map
        # This value is used to calculate the next note in current scale
        scale_index = 0

        # col value denotes the midi note number of the note to be
        # inserted in the grid
        # Starts with the selected key's midi note
        col = self.__starting_note__

        for row in range(0, self.__rows__):
            row_data = []

            for i in range(0, self.__columns__):
                # Create a Note Object representing a Music Note for current cell
                row_data.append(
                    Note(
                        name=note_int_to_str_map[col % 12],
                        scale_index=scale_index,
                        octave=col // 12,
                        midi_note=col,
                        midi_port=self.__midi_port__,
                        parent=self,
                    )
                )

                # Cycle scale index value to 0 if it reaches the end of scale mode map
                if scale_index >= len(scale_mode_map[self.__scale__]):
                    scale_index = 0

                # Calculate the next note value using the scale mode map and scale index
                col += scale_mode_map[self.__scale__][scale_index]
                scale_index += 1

            # Prepend the generated row to grid as the grid direction should be bottom to top
            grid_notes.insert(0, row_data)

            # If scale mode is not chromatic, calculate the next row's starting note
            if self.__scale__ != "chromatic":
                col = row_data[0].get_midi_note()
                scale_index = row_data[0].get_scale_index()

                for i in range(0, 3):
                    col += scale_mode_map[self.__scale__][
                        scale_index % len(scale_mode_map[self.__scale__])
                    ]
                    scale_index = (scale_index + 1) % len(
                        scale_mode_map[self.__scale__]
                    )

        self.__model__.set_grid(grid_notes)
        self.__model_changed__.emit()

        ##########################################
        # Next up, let us sort out out chord rows
        ##########################################
        chord_notes = []
        # Reset our basic selector values
        scale_index = 0

        for row in range(0, self.__chord_rows__):
            row_data = []
            col = self.__chord_scales_starts__[row]

            for i in range(0, 8):
                # Create a Note object representing a music note for our current cell
                # This one's a container, and it will contain a series of subnotes which make up the scale
                note = Note(
                    name=note_int_to_str_map[col % 12],
                    scale_index=scale_index,
                    octave=col // 12,
                    midi_note=col,
                    midi_port=self.__midi_port__,
                    parent=self,
                )
                # Now create the subnotes, so we can have us a proper chord
                subnotes = []
                for subnote_index in range(0, 3):
                    subnote_col = col + subnote_index
                    subnote = Note(
                        name=note_int_to_str_map[subnote_col % 12],
                        scale_index=scale_index,
                        octave=subnote_col // 12,
                        midi_note=subnote_col,
                        midi_port=self.__midi_port__,
                        parent=self,
                    )
                    subnotes.append(subnote)
                note.subnotes = subnotes
                row_data.append(note)

                # Cycle scale index value to 0 if it reaches the end of scale mode map
                if scale_index >= len(scale_mode_map[self.__chord_scales__[row]]):
                    scale_index = 0

                # Calculate the next note value using the scale mode map and scale index
                col += scale_mode_map[self.__chord_scales__[row]][scale_index]
                scale_index += 1

            # Prepend the generated row to grid as the grid direction should be bottom to top
            chord_notes.insert(0, row_data)

            # If scale mode is not chromatic, calculate the next row's starting note
            if self.__chord_scales__[row] != "chromatic":
                col = row_data[0].get_midi_note()
                scale_index = row_data[0].get_scale_index()

                for i in range(0, 3):
                    col += scale_mode_map[self.__chord_scales__[row]][
                        scale_index % len(scale_mode_map[self.__chord_scales__[row]])
                    ]
                    scale_index = (scale_index + 1) % len(
                        scale_mode_map[self.__chord_scales__[row]]
                    )

        self.__chord_model__.set_grid(chord_notes)
        self.__chord_model_changed__.emit()

    def __get_model__(self):
        return self.__model__

    def __get_chord_model__(self):
        return self.__chord_model__

    def __get_rows__(self):
        return self.__rows__

    def __get_columns__(self):
        return self.__columns__

    def __get_starting_note__(self):
        return self.__starting_note__

    def __get_scale__(self):
        return self.__scale__

    def __get_chord_rows__(self):
        return self.__chord_rows__

    def __get_chord_scales__(self):
        return self.__chord_scales__

    def __set_rows__(self, rows):
        self.__rows__ = rows
        self.__rows_changed__.emit()
        self.__populate_grid__()

    def __set_columns__(self, columns):
        self.__columns__ = columns
        self.__columns_changed__.emit()
        self.__populate_grid__()

    def __set_starting_note__(self, note):
        self.__starting_note__ = note
        self.__starting_note_changed__.emit()
        self.__populate_grid__()

    def __set_scale__(self, scale: str):
        self.__scale__ = scale
        self.__scale_changed__.emit()
        self.__populate_grid__()

    def __set_chord_rows__(self, chord_rows):
        self.__chord_rows__ = chord_rows
        self.__chord_rows_changed__.emit()

    @Slot(int, int)
    def setChordScale(self, chord_row: int, scale: int):
        self.__chord_scales__[chord_row] = scale
        self.__chord_scales_changed__.emit()

    @Signal
    def __rows_changed__(self):
        pass

    @Signal
    def __columns_changed__(self):
        pass

    @Signal
    def __starting_note_changed__(self):
        pass

    @Signal
    def __model_changed__(self):
        pass

    @Signal
    def __chord_model_changed__(self):
        pass

    @Signal
    def __chord_rows_changed__(self):
        pass

    @Signal
    def __chord_scales_changed__(self):
        pass

    @Signal
    def __scale_changed__(self):
        pass

    @Slot(Note, bool)
    def highlightPlayingNotes(self, note: Note, highlight: bool):
        self.__model__.highlight_playing_note(note, highlight)

    def get_pitch(self):
        return self.__pitch__

    @Signal
    def __pitch_changed__(self):
        pass

    def set_pitch(self, pitch: int):
        self.__pitch__ = pitch
        midi_pitch_message = mido.Message(
            "pitchwheel", channel=0, pitch=self.__pitch__
        )
        self.__midi_port__.send(midi_pitch_message)
        self.__pitch_changed__.emit()

    def get_positional_velocity(self):
        return self.__positional_velocity__

    def set_positional_velocity(self, positional_velocity: int):
        self.__positional_velocity__ = positional_velocity
        self.__positional_velocity_changed__.emit()

    @Signal
    def __positional_velocity_changed__(self):
        pass

    rows = Property(int, __get_rows__, __set_rows__, notify=__rows_changed__)
    columns = Property(
        int, __get_columns__, __set_columns__, notify=__columns_changed__
    )
    startingNote = Property(
        int,
        __get_starting_note__,
        __set_starting_note__,
        notify=__starting_note_changed__,
    )
    model = Property(
        QAbstractItemModel, __get_model__, notify=__model_changed__
    )
    scale = Property(
        str, __get_scale__, __set_scale__, notify=__scale_changed__
    )
    chordModel = Property(
        QAbstractItemModel, __get_chord_model__, notify=__chord_model_changed__
    )
    chordRows = Property(
        int, __set_chord_rows__, __get_chord_rows__, notify=__chord_rows_changed__
    )
    chordScales = Property(
        'QVariantList', __get_chord_scales__, notify=__chord_scales_changed__
    )
    pitch = Property(int, get_pitch, set_pitch, notify=__pitch_changed__)
    positionalVelocity = Property(bool, get_positional_velocity, set_positional_velocity, notify=__positional_velocity_changed__)
