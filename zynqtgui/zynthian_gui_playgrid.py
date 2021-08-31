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
import os
from pathlib import Path

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
        self.__is_playing__: bool = False
        self.__midi_note_on_msg__ = None
        self.__midi_note_off_msg__ = None
        self.__midi_notes_on_msgs__ = []
        self.__midi_notes_off_msgs__ = []
        self.__subnotes__ = []

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
        if 0 <= index.row() < len(self.__grid_notes__):
            return len(self.__grid_notes__[index.row()])
        return 0

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
    def __init__(self, name:str, parent=None):
        super(zynthian_gui_playgrid_settings, self).__init__(parent)
        self.__name__ = name
        self.__settings__ = {}
        self.__defaults__ = {}
        self.__most_recently_changed__: str

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
                self.propertyChanged.emit()

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
    def __init__(self, parent=None):
        super(zynthian_gui_playgrid, self).__init__(parent)
        qmlRegisterType(Note, "Zynthian.PlayGrid", 1, 0, "Note")
        qmlRegisterType(zynthian_gui_grid_notes_model, "Zynthian.PlayGrid", 1, 0, "Model")
        self.__midi_port__ = mido.open_output("Midi Through Port-0")
        self.__play_grid_index__ = 0
        self.__play_grids__ = []
        self.__pitch__ = 0
        self.__models__ = []
        self.__notes__ = []
        self.__settings_stores__ = {}
        self.__note_state_map__ = {}
        self.__update_play_grids__()

    def show(self):
        pass

    def zyncoder_read(self):
        pass

    def refresh_loading(self):
        pass

    def __update_play_grids__(self):
        _new_list = []
        searchlist = [Path("/home/pi/zynthian-ui/qml-ui/playgrids"), Path(Path.home() / ".local/zynthian/playgrids")]
        for searchdir in searchlist:
            if searchdir.exists():
                for playgrid_dir in [f.name for f in os.scandir(searchdir) if f.is_dir()]:
                    _new_list.append(str(searchdir / playgrid_dir))
        _new_list = sorted(_new_list, key=lambda s: s.split("/")[-1])
        self.__play_grids__ = _new_list
        self.__play_grids_changed__.emit()

    def __get_play_grids__(self):
        return self.__play_grids__

    @Signal
    def __play_grids_changed__(self):
        pass

    def __get_play_grid_index__(self):
        return self.__play_grid_index__

    def __set_play_grid_index__(self, play_grid_index):
        self.__play_grid_index__ = play_grid_index
        self.__play_grid_index_changed__.emit()

    @Signal
    def __play_grid_index_changed__(self):
        pass

    def __get_pitch__(self):
        return self.__pitch__

    def __set_pitch__(self, pitch):
        self.__pitch__ = pitch
        self.__pitch_changed__.emit()

    @Signal
    def __pitch_changed__(self):
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

    def model_deleted(self, model:zynthian_gui_grid_notes_model):
        if model in self.__models__:
            self.__models__.remove(model)

    @Slot(result=QObject)
    def createNotesModel(self):
        model = zynthian_gui_grid_notes_model(self)
        self.__models__.append(model)
        model.destroyed.connect(self.model_deleted)
        QQmlEngine.setObjectOwnership(model, QQmlEngine.CppOwnership)
        return model

    def note_deleted(self, note:Note):
        if note in self.__notes__:
            self.__notes__.remove(note)

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
        self.__notes__.append(note)
        note.destroyed.connect(self.note_deleted)
        QQmlEngine.setObjectOwnership(note, QQmlEngine.CppOwnership)
        return note

    @Slot(str, result=QObject)
    def getSettingsStore(self, name:str):
        if not name in self.__settings_stores__:
            settingsStore = zynthian_gui_playgrid_settings(name, self)
            self.__settings_stores__[name] = settingsStore
            QQmlEngine.setObjectOwnership(settingsStore, QQmlEngine.CppOwnership)
        return self.__settings_stores__[name]

    playgrids = Property('QVariantList', __get_play_grids__, notify=__play_grids_changed__)
    pitch = Property(int, __get_pitch__, __set_pitch__, notify=__pitch_changed__)
    playGridIndex = Property(int, __get_play_grid_index__, __set_play_grid_index__, notify=__play_grid_index_changed__)
