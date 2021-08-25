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
from PySide2.QtQml import QQmlEngine,qmlRegisterType
from . import zynthian_qt_gui_base


class Note(QObject):
    __note_name__: str = ""
    __scale_index__: int = 0
    __octave__: int = 0
    __is_playing__: bool = False
    __midi_note__: int = 0
    __midi_port__: int = 0
    __midi_note_on_msg__ = None
    __midi_note_off_msg__ = None
    __midi_notes_on_msgs__ = []
    __midi_notes_off_msgs__ = []
    __subnotes__ = []
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
        self.__midi_note__ = midi_note
        self.__midi_port__ = midi_port

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
        elif 0 <= self.__midi_note__ <= 127:
            if self.__midi_note_on_msg__ is None:
                self.__midi_note_on_msg__ = mido.Message(
                    "note_on", note=self.__midi_note__
                )
            self.__midi_note_on_msg__.velocity = _velocity
            self.__midi_port__.send(self.__midi_note_on_msg__)

    @Slot(None)
    def off(self):
        if (len(self.__midi_notes_off_msgs__) > 0):
            for i in range(0, len(self.__midi_notes_off_msgs__)):
                self.__midi_port__.send(self.__midi_notes_off_msgs__[i])
        elif 0 <= self.__midi_note__ <= 127:
            if self.__midi_note_off_msg__ is None:
                self.__midi_note_off_msg__ = mido.Message(
                    "note_off", note=self.__midi_note__
                )
            self.__midi_port__.send(self.__midi_note_off_msg__)

    @Property(str, constant=True)
    def name(self):
        return self.__note_name__

    @Property(int, constant=True)
    def octave(self):
        return self.__octave__

    midiNote = Property(
        int, get_midi_note, constant=True
    )
    scaleIndex = Property(
        int, get_scale_index, constant=True
    )
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
        self.__grid_notes__ = []

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
        self.beginResetModel()
        self.__grid_notes__ = grid
        self.endResetModel()

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

    @Slot(None)
    def clear(self):
        temporary_notes = self.__grid_notes__
        self.beginResetModel()
        self.__grid_notes__ = []
        self.endResetModel()
        for row in temporary_notes:
            for note in row:
                note.deleteLater()

    @Slot('QVariantList')
    def addRow(self, notes):
        self.beginResetModel()
        self.__grid_notes__.insert(0, notes)
        self.endResetModel()


# A dictionary wrapper which notifies about changes to the values, and only
# when the value actually has changed. It supports setting a series of default
# values for the properties.
# TODO Persist settings (load on init, save on set)
class zynthian_gui_playgrid_settings(QObject):
    __settings__ = {}
    __defaults__ = {}
    __most_recently_changed__: str
    __name__: str
    def __init__(self, name:str, parent=None):
        super(zynthian_gui_playgrid_settings, self).__init__(parent)
        self.__name__ = name

    @Property(str, constant=True)
    def name(self):
        return self.__name__

    @Slot(str,result='QVariant')
    def property(self, property:str):
        if property in self.__settings__:
            return self.__settings__.get(property)
        return self.__defaults__.get(property)

    @Slot(str,'QVariant')
    def setProperty(self, property:str, value:'QVariant'):
        if not property in self.__settings__ or not self.__settings__[property] == value:
            self.__settings__[property] = value
            self.__most_recently_changed__ = property
            self.propertyChanged.emit()

    @Slot(str)
    def clearProperty(self, property:str):
        if property in self.__settings__:
            self.__settings__.remove(property)
            self.propertyChanged.emit()

    @Slot(str,result='QVariant')
    def default(self, property:str):
        return self.__defaults__.get(property)

    @Slot(str,'QVariant')
    def setDefault(self, property:str, value:'QVariant'):
        if not property in self.__defaults__ or not self.__defaults__[property] == value:
            self.__defaults__[property] = value
            self.__most_recently_changed__ = property
            self.defaultChanged.emit()
            if not property in self.__settings__:
                self.propertyChanged()

    @Slot(result=str)
    def mostRecentlyChanged(self):
        return self.__most_recently_changed__

    @Signal
    def propertyChanged(self):
        pass

    @Signal
    def defaultChanged(self):
        pass

class zynthian_gui_playgrid(zynthian_qt_gui_base.ZynGui):
    __rows__: int = 5
    __columns__: int = 8
    __starting_note__: int = 36
    __scale__ = "ionian"
    __chord_model__: QAbstractItemModel = None
    __chord_rows__ = 5
    __play_grid_index__ = 0
    __positional_velocity__ = False

    __pitch__ = 0
    __models__ = []
    __settings_stores__ = {}
    __note_state_map__ = {}

    def __init__(self, parent=None):
        super(zynthian_gui_playgrid, self).__init__(parent)
        qmlRegisterType(Note, "Zynthian.PlayGrid", 1, 0, "Note")
        qmlRegisterType(zynthian_gui_grid_notes_model, "Zynthian.PlayGrid", 1, 0, "Model")

        self.__chord_scales__ = [
            "ionian",
            "dorian",
            "phrygian",
            "aeolian",
            "chromatic"
        ]
        self.__chord_scales_starts__ = [
            60,
            60,
            60,
            60,
            60
        ]

        self.__model__ = zynthian_gui_grid_notes_model(self)
        self.__chord_model__ = zynthian_gui_grid_notes_model(self)
        self.__models__.append(self.__model__)
        self.__models__.append(self.__chord_model__)

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
                        name=(note_int_to_str_map[col % 12] if 0 <= col <= 127 else ""),
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

        # Let's grab ourselves some diatonic progressions...
        diatonic_progressions = [0, 2, 4]
        for row in range(0, self.__chord_rows__):
            scale_index = 0
            row_data = []
            row_scale = scale_mode_map[self.__chord_scales__[row]]
            col = self.__chord_scales_starts__[row]

            for i in range(0, len(row_scale)):
                # We will use a fake midi note to signify a chord (as only leaf nodes actually
                # get played, this is just used for identifying the chord (for example for highlighting
                # purposes))
                fake_midi_note = 0
                # First create the subnotes, so we can have us a proper chord
                subnotes = []
                for subnote_index in range(0, len(diatonic_progressions)):
                    subnote_col = col
                    for j in range(0, diatonic_progressions[subnote_index]):
                        subnote_scale_index = scale_index + j
                        if (subnote_scale_index >= len(row_scale)):
                            subnote_scale_index -= len(row_scale)
                        subnote_col += row_scale[subnote_scale_index]
                    subnote = Note(
                        name=note_int_to_str_map[subnote_col % 12],
                        scale_index=scale_index,
                        octave=subnote_col // 12,
                        midi_note=subnote_col,
                        midi_port=self.__midi_port__,
                        parent=self,
                    )
                    subnotes.append(subnote)
                    # Offset each note by a full midi note value spread, so we can kind of identify things
                    fake_midi_note += (127 * subnote_index) + subnote_col
                # Now create a Note object representing a music note for our current cell
                # This one's our container, and it will contain a series of subnotes which make up the scale
                note = Note(
                    name=note_int_to_str_map[col % 12],
                    scale_index=scale_index,
                    octave=col // 12,
                    midi_note=fake_midi_note,
                    midi_port=self.__midi_port__,
                    parent=self,
                )
                note.subnotes = subnotes
                row_data.append(note)

                # Cycle scale index value to 0 if it reaches the end of scale mode map
                if scale_index >= len(row_scale):
                    scale_index = 0

                # Calculate the next note value using the scale mode map and scale index
                col += row_scale[scale_index]
                scale_index += 1

            # Prepend the generated row to grid as the grid direction should be bottom to top
            chord_notes.insert(0, row_data)

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

    def __get_play_grid_index__(self):
        return self.__play_grid_index__

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
        self.__populate_grid__()

    def __set_play_grid_index__(self, play_grid_index):
        self.__play_grid_index__ = play_grid_index
        self.__play_grid_index_changed__.emit()

    @Slot(int, str)
    def setChordScale(self, chord_row: int, scale: str):
        self.__chord_scales__[chord_row] = scale
        self.__chord_scales_changed__.emit()
        self.__populate_grid__()

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
    def __play_grid_index_changed__(self):
        pass

    @Signal
    def __scale_changed__(self):
        pass

    @Slot(Note, int)
    def setNoteOn(self, note: Note, velocity: int = 64):
        self.setNoteState(note = note, velocity = velocity, setOn = True)

    @Slot(Note)
    def setNoteOff(self, note: Note):
        self.setNoteState(note = note, setOn = False)

    def setNoteState(self, note: Note, velocity: int = 64, setOn: bool = True):
        subnotes = note.get_subnotes()
        subnoteCount = len(note.get_subnotes())
        if subnoteCount > 0:
            for i in range(0, subnoteCount):
                self.setNoteState(subnotes[i], velocity, setOn)
            for model in self.__models__:
                model.highlight_playing_note(note, setOn)
        else:
            noteKey = str(note.get_midi_note())
            if noteKey in self.__note_state_map__:
                if setOn:
                    self.__note_state_map__[noteKey] += 1
                else:
                    self.__note_state_map__[noteKey] -= 1
                    if self.__note_state_map__[noteKey] == 0:
                        note.off()
                        self.__note_state_map__.pop(noteKey)
                        for model in self.__models__:
                            model.highlight_playing_note(note, False)
            else:
                if setOn:
                    note.on(velocity)
                    self.__note_state_map__[noteKey] = 1
                    for model in self.__models__:
                        model.highlight_playing_note(note, True)
                else:
                    note.off()
                    for model in self.__models__:
                        model.highlight_playing_note(note, False)

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

    @Slot(result=QObject)
    def createNotesModel(self):
        model = zynthian_gui_grid_notes_model(self)
        self.__models__.append(model)
        QQmlEngine.setObjectOwnership(model, QQmlEngine.CppOwnership)
        return model

    @Slot(str, int, int, int, result=QObject)
    def createNote(self,
                   _name: str,
                   _scale_index: int,
                   _octave: int,
                   _midi_note: int):
        note = Note(
            name=_name,
            scale_index=_scale_index,
            octave=_octave,
            midi_note=_midi_note,
            midi_port=self.__midi_port__,
            parent=self
        )
        QQmlEngine.setObjectOwnership(note, QQmlEngine.CppOwnership)
        return note

    @Slot(str, result=QObject)
    def getSettingsStore(self, name:str):
        if not name in self.__settings_stores__:
            settingsStore = zynthian_gui_playgrid_settings(name, self)
            self.__settings_stores__[name] = settingsStore
            QQmlEngine.setObjectOwnership(settingsStore, QQmlEngine.CppOwnership)
        return self.__settings_stores__[name]

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
        int, __get_chord_rows__, __set_chord_rows__, notify=__chord_rows_changed__
    )
    chordScales = Property(
        'QVariantList', __get_chord_scales__, notify=__chord_scales_changed__
    )
    pitch = Property(int, get_pitch, set_pitch, notify=__pitch_changed__)
    positionalVelocity = Property(bool, get_positional_velocity, set_positional_velocity, notify=__positional_velocity_changed__)
    playGridIndex = Property(int, __get_play_grid_index__, __set_play_grid_index__, notify=__play_grid_index_changed__)
