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
from datetime import datetime
from pathlib import Path
from threading import Lock

from PySide2.QtCore import (
    Slot,
    QAbstractItemModel,
    QCoreApplication,
    QFileSystemWatcher,
    Qt,
    QModelIndex,
    QObject,
    QTimer,
    Property,
    Signal,
)
from PySide2.QtQml import QQmlEngine,qmlRegisterType
from . import zynthian_qt_gui_base
from .zynthiloops import zynthian_gui_zynthiloops


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
        if midi_note < 128:
            self.__midi_note_on_msg__ = self.__midi_note_on_msg__ = mido.Message(
                "note_on", note=self.__midi_note__
            )
            self.__midi_note_off_msg__ = self.__midi_note_off_msg__ = mido.Message(
                "note_off", note=self.__midi_note__
            )
        else:
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

    def on(self, _velocity: int = 64):
        if (len(self.__midi_notes_on_msgs__) > 0):
            for i in range(0, len(self.__midi_notes_on_msgs__)):
                self.__midi_notes_on_msgs__[i].velocity = _velocity
                self.__midi_port__.send(self.__midi_notes_on_msgs__[i])
        elif 0 <= self.__midi_note__ <= 127:
            self.__midi_note_on_msg__.velocity = _velocity
            self.__midi_port__.send(self.__midi_note_on_msg__)
        self.set_is_playing(True)

    def off(self):
        if (len(self.__midi_notes_off_msgs__) > 0):
            for i in range(0, len(self.__midi_notes_off_msgs__)):
                self.__midi_port__.send(self.__midi_notes_off_msgs__[i])
        elif 0 <= self.__midi_note__ <= 127:
            self.__midi_port__.send(self.__midi_note_off_msg__)
        self.set_is_playing(False)

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

    def __del__(self):
        self.clear()

    def roleNames(self) -> typing.Dict:
        roles = {self.NoteRole: b"note"}
        return roles

    def data(self, index: QModelIndex, role: int) -> Note:
        data = None
        if index.isValid():
            try:
                if role == self.NoteRole:
                    data = self.__grid_notes__[index.row()][index.column()]
            except:
                data = "No item at this position"
        return data

    def rowCount(self, index):
        return len(self.__grid_notes__)

    def __get_rows__(self):
        return len(self.__grid_notes__)

    @Signal
    def __rows_changed__(self):
        pass

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

    @Property(dict, constant=True)
    def roles(self):
        return {b"note": zynthian_gui_grid_notes_model.NoteRole}

    @Slot(None)
    def note_changed(self):
        theSender = self.sender()
        if self.__grid_notes__:
            rowIndex = 0
            found = False
            for row in self.__grid_notes__:
                columnIndex = 0
                for note in row:
                    if note == theSender:
                        found = True
                        idx = self.index(rowIndex, columnIndex)
                        self.dataChanged.emit(idx, idx)
                        break
                    columnIndex = columnIndex + 1
                if found:
                    break
                rowIndex = rowIndex + 1
        else:
            logging.error("Apparently we are notifying a model that no longer exists? Let's disconnect from that.")
            theSender.__is_playing_changed__.disconnect(self.note_changed)

    @Slot(None)
    def clear(self):
        self.beginResetModel()
        #for row in self.__grid_notes__:
            #for note in row:
                #note.__is_playing_changed__.disconnect(self.note_changed)
        self.__grid_notes__.clear()
        QTimer.singleShot(0, self.endResetModel)
        self.__rows_changed__.emit()

    @Slot('QVariantList')
    def addRow(self, notes):
        self.beginResetModel()
        #for note in notes:
            #note.__is_playing_changed__.connect(self.note_changed)
        self.__grid_notes__.insert(0, notes)
        QTimer.singleShot(0, self.endResetModel)
        self.__rows_changed__.emit()

    rows = Property(int, __get_rows__, notify=__rows_changed__)

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
        oldValue = self.property(property)
        if not property in self.__settings__ or not self.__settings__[property] == value:
            self.__settings__[property] = value
            self.__most_recently_changed__ = property
            if value != oldValue:
                self.propertyChanged.emit()

    @Slot(str)
    def clearProperty(self, property:str):
        if property in self.__settings__:
            value = self.__settings__.get(property)
            self.__settings__.remove(property)
            if value != self.default(property):
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
    # Use this when something needs to be signalled to /all/ the instances (such as note states)
    __playgrid_instances__ = []

    searchlist = [Path(Path.home() / ".local/share/zynthian/playgrids"), Path("/home/pi/zynthian-ui/qml-ui/playgrids")]
    dir_watcher = QFileSystemWatcher()

    __models__ = {}
    __notes__ = []
    __settings_stores__ = {}
    __note_state_map__ = {}
    __most_recently_changed_note__ = None
    __input_ports__ = []
    __mutex__ = Lock()

    def __init__(self, parent=None):
        super(zynthian_gui_playgrid, self).__init__(parent)
        zynthian_gui_playgrid.__playgrid_instances__.append(self)
        qmlRegisterType(Note, "Zynthian.PlayGrid", 1, 0, "Note")
        qmlRegisterType(zynthian_gui_grid_notes_model, "Zynthian.PlayGrid", 1, 0, "Model")
        self.__midi_port__ = mido.open_output("Midi Through Port-0")
        self.__play_grid_index__ = 0
        self.__play_grids__ = []
        self.__pitch__ = 0
        self.__modulation__ = 0
        self.__metronome_beat__ = 0
        self.__most_recently_changed_notes__ = [] # List of dicts
        self.updatePlayGrids()
        self.listen_to_everything()
        self.__metronome_manager__: zynthian_gui_zynthiloops = self.zyngui.screens["zynthiloops"]

        zynthian_gui_playgrid.dir_watcher.directoryChanged.connect(self.updatePlayGrids)
        zynthian_gui_playgrid.dir_watcher.fileChanged.connect(self.updatePlayGrids)
        for searchdir in zynthian_gui_playgrid.searchlist:
            if not searchdir.exists():
                searchdir.mkdir(parents=True)
            if not str(searchdir) in zynthian_gui_playgrid.dir_watcher.directories():
                success = zynthian_gui_playgrid.dir_watcher.addPath(str(searchdir))
                if not success:
                    logging.error("Could not set up watching for: " + str(searchdir))

    @staticmethod
    def findExistingNote(midi_note):
        note = None
        for existingNote in zynthian_gui_playgrid.__notes__:
            if (hasattr(existingNote, '__midi_note__') and existingNote.__midi_note__ == midi_note):
                note = existingNote
                break
        return note

    @staticmethod
    def listen_to_everything():
        for port in zynthian_gui_playgrid.__input_ports__:
            try:
                port.close()
            except:
                logging("Attempted to close a port that apparently is broken. It seems we can safely ignore this, so let's do that.")
        zynthian_gui_playgrid.__input_ports__.clear()
        # It's entirely possible we'll need to nab this out of zyngine or somesuch, but for now...
        #for input_name in mido.get_input_names():
        try:
            #input_port = mido.open_input(input_name)
            input_port = mido.open_input()
            input_port.callback = zynthian_gui_playgrid.handle_input_message
            zynthian_gui_playgrid.__input_ports__.append(input_port)
            logging.error("Successfully opened midi input for reading: " + str(input_port))
        except:
            logging.error("Failed to open midi input port for reading")

    @staticmethod
    def handle_input_message(message):
        #logging.error("Mido message did an arrive: %s", message.dict())
        note = None
        velocity = 0
        note_on = False
        message_data = message.dict()
        if message_data.get('type') == "note_on" or message_data.get('type') == "note_off":
            if message_data.get('type') == "note_on":
                note_on = True
            note_value = message_data.get('note')
            note = zynthian_gui_playgrid.findExistingNote(note_value)
            if note is None:
                logging.error("Got a message for a note we're apparently not aware of: %s", message_data)
            else:
                note.set_is_playing(note_on)
                for playgrid in zynthian_gui_playgrid.__playgrid_instances__:
                    playgrid.__note_state_changed__(note, message_data)

    def show(self):
        pass

    def zyncoder_read(self):
        pass

    def refresh_loading(self):
        pass

    @Slot(None)
    def updatePlayGrids(self):
        _new_list = []

        for searchdir in zynthian_gui_playgrid.searchlist:
            if searchdir.exists():
                for playgrid_dir in [f.name for f in os.scandir(searchdir) if f.is_dir()]:
                    if os.path.isfile(searchdir / playgrid_dir / "main.qml"):
                        _new_list.append(str(searchdir / playgrid_dir))
                    else:
                        logging.warning("A stray directory that does not contain a main.qml file was found in one of the playgrid search locations: " + str(searchdir / playgrid_dir))
            else:
                # A little naughty, but knewstuff kind of removes directories once everything in it's gone
                searchdir.mkdir(parents=True)
                if not str(searchdir) in zynthian_gui_playgrid.dir_watcher.directories():
                    success = zynthian_gui_playgrid.dir_watcher.addPath(str(searchdir))
                    if not success:
                        logging.error("Could not set up watching for: " + str(searchdir))

        _new_list = sorted(_new_list, key=lambda s: s.split("/")[-1])
        if not _new_list == self.__play_grids__:
            self.__play_grids__ = _new_list
            self.__play_grids_changed__.emit()
            logging.error("We now have the following known grids:\n {}".format('\n '.join(map(str, self.__play_grids__))))

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
        midi_pitch_message = mido.Message(
            "pitchwheel", channel=0, pitch=self.__pitch__
        )
        self.__midi_port__.send(midi_pitch_message)
        self.__pitch_changed__.emit()

    @Signal
    def __pitch_changed__(self):
        pass

    def __get_modulation__(self):
        return self.__modulation__

    def __set_modulation__(self, modulation):
        self.__modulation__ = modulation
        modulation_message = mido.Message(
            "control_change", channel=0, control=1, value=self.__modulation__
        )
        self.__midi_port__.send(modulation_message)
        self.__modulation_changed__.emit()

    @Signal
    def __modulation_changed__(self):
        pass

    @Slot(Note, int)
    def setNoteOn(self, note: Note, velocity: int = 64):
        self.setNoteState(note = note, velocity = velocity, setOn = True)

    @Slot(Note)
    def setNoteOff(self, note: Note):
        self.setNoteState(note = note, setOn = False)

    def setNoteState(self, note: Note, velocity: int = 64, setOn: bool = True):
        if note is None:
            logging.error("Attempted to set the state of a None-value note")
        else:
            subnotes = note.get_subnotes()
            subnoteCount = len(note.get_subnotes())
            if subnoteCount > 0:
                for i in range(0, subnoteCount):
                    self.setNoteState(subnotes[i], velocity, setOn)
            else:
                noteKey = str(note.get_midi_note())
                if noteKey in zynthian_gui_playgrid.__note_state_map__:
                    if setOn:
                        zynthian_gui_playgrid.__note_state_map__[noteKey] += 1
                    else:
                        zynthian_gui_playgrid.__note_state_map__[noteKey] -= 1
                        if zynthian_gui_playgrid.__note_state_map__[noteKey] == 0:
                            note.off()
                            zynthian_gui_playgrid.__note_state_map__.pop(noteKey)
                else:
                    if setOn:
                        note.on(velocity)
                        zynthian_gui_playgrid.__note_state_map__[noteKey] = 1
                    else:
                        note.off()

    def __note_state_changed__(self, note:Note, message_data):
        #logging.error("New note state for " + str(note.midiNote) + " now playing? " + str(note.isPlaying))
        zynthian_gui_playgrid.__mutex__.acquire()
        self.__most_recently_changed_notes__.append({
            'note': note,
            'state': note.isPlaying,
            'metadata': message_data,
            'time': datetime.now()
        })
        zynthian_gui_playgrid.__mutex__.release()
        self.__most_recently_changed_notes_changed__.emit()
        zynthian_gui_playgrid.__most_recently_changed_note__ = note
        for playgrid in zynthian_gui_playgrid.__playgrid_instances__:
            playgrid.noteStateChanged.emit()

    @Slot(result=Note)
    def mostRecentlyChangedNote(self):
        return zynthian_gui_playgrid.__most_recently_changed_note__

    @Signal
    def noteStateChanged(self):
        pass

    def __get_most_recently_changed_notes__(self):
        return self.__most_recently_changed_notes__

    @Signal
    def __most_recently_changed_notes_changed__(self):
        pass

    @Slot(str, result=QObject)
    def getNotesModel(self, modelName:str):
        zynthian_gui_playgrid.__mutex__.acquire()
        if not modelName in zynthian_gui_playgrid.__models__:
            model = zynthian_gui_grid_notes_model(QCoreApplication.instance())
            zynthian_gui_playgrid.__models__[modelName] = model
            QQmlEngine.setObjectOwnership(model, QQmlEngine.CppOwnership)
        model = zynthian_gui_playgrid.__models__.get(modelName)
        zynthian_gui_playgrid.__mutex__.release()
        return model

    @Slot(result=QObject)
    def createNotesModel(self):
        zynthian_gui_playgrid.__mutex__.acquire()
        if not hasattr(zynthian_gui_playgrid, "__fauxModelName__"):
            zynthian_gui_playgrid.__fauxModelName__ = ""
        zynthian_gui_playgrid.__fauxModelName__ = zynthian_gui_playgrid.__fauxModelName__ + "."
        logging.error("Fetching a new model with a name made up of dots (please port to using getNotesModel(str)): " + zynthian_gui_playgrid.__fauxModelName__)
        zynthian_gui_playgrid.__mutex__.release()
        return self.getNotesModel(zynthian_gui_playgrid.__fauxModelName__)

    def note_deleted(self, note:Note):
        if note in zynthian_gui_playgrid.__notes__:
            zynthian_gui_playgrid.__notes__.remove(note)

    @Slot(str, int, int, int, result=QObject)
    def getNote(self,
                   _name: str,
                   _scale_index: int,
                   _octave: int,
                   _midi_note: int):
        zynthian_gui_playgrid.__mutex__.acquire()
        note = zynthian_gui_playgrid.findExistingNote(_midi_note)
        if note is None:
            note = Note(
                name=_name,
                scale_index=_scale_index,
                octave=_octave,
                midi_note=_midi_note,
                midi_port=self.__midi_port__,
                parent=QCoreApplication.instance()
            )
            zynthian_gui_playgrid.__notes__.append(note)
            note.destroyed.connect(self.note_deleted)
        QQmlEngine.setObjectOwnership(note, QQmlEngine.CppOwnership)
        zynthian_gui_playgrid.__mutex__.release()
        return note

    @Slot('QVariantList', result=QObject)
    def getCompoundNote(self, notes:'QVariantList'):
        zynthian_gui_playgrid.__mutex__.acquire()
        note = None
        try:
            if len(notes) > 0:
                # Make the compound note's fake note value...
                fake_midi_note = 128;
                for subnote in notes:
                    fake_midi_note = fake_midi_note + (127 * subnote.__midi_note__)
                # Find if we've got a note with that note value already
                note = zynthian_gui_playgrid.findExistingNote(fake_midi_note)
                # If not, create it, and stuff it with these subnotes
                if note is None:
                    zynthian_gui_playgrid.__mutex__.release()
                    note = self.getNote(notes[0].name, notes[0].scaleIndex, fake_midi_note // 12, fake_midi_note)
                    zynthian_gui_playgrid.__mutex__.acquire()
                    zynthian_gui_playgrid.__notes__.append(note)
                note.set_subnotes(notes)
        except:
            logging.error("We have apparently got a broken thing - likely this is because the notes object passed in was an empty list, or a null pointer (which python doesn't know what to do with)")
        zynthian_gui_playgrid.__mutex__.release()
        return note

    @Slot(str, result=QObject)
    def getSettingsStore(self, name:str):
        zynthian_gui_playgrid.__mutex__.acquire()
        if not name in zynthian_gui_playgrid.__settings_stores__:
            settingsStore = zynthian_gui_playgrid_settings(name, QCoreApplication.instance())
            zynthian_gui_playgrid.__settings_stores__[name] = settingsStore
            QQmlEngine.setObjectOwnership(settingsStore, QQmlEngine.CppOwnership)
        settingsStore = zynthian_gui_playgrid.__settings_stores__[name]
        zynthian_gui_playgrid.__mutex__.release()
        return settingsStore

    @Slot(None)
    def startMetronomeRequest(self):
        self.__metronome_manager__.current_beat_changed.connect(self.metronome_update)
        self.__metronome_manager__.start_metronome_request()

    @Slot(None)
    def stopMetronomeRequest(self):
        try:
            self.__metronome_manager__.current_beat_changed.disconnect(self.metronome_update)
        except Exception as e:
            logging.error(f"Failed to disconnect. Not connected maybe? : {str(e)}")
        self.__metronome_manager__.stop_metronome_request()

    def metronome_update(self):
        self.__metronome_beat__ = self.__metronome_manager__.currentBeat
        self.__metronome_beat_changed__.emit()

    def __get_metronome_beat__(self):
        return self.__metronome_beat__

    @Signal
    def __metronome_beat_changed__(self):
        pass

    mostRecentlyChangedNotes = Property('QVariantList', __get_most_recently_changed_notes__, notify=__most_recently_changed_notes_changed__)
    playgrids = Property('QVariantList', __get_play_grids__, notify=__play_grids_changed__)
    pitch = Property(int, __get_pitch__, __set_pitch__, notify=__pitch_changed__)
    modulation = Property(int, __get_modulation__, __set_modulation__, notify=__modulation_changed__)
    playGridIndex = Property(int, __get_play_grid_index__, __set_play_grid_index__, notify=__play_grid_index_changed__)
    metronomeBeat = Property(int, __get_metronome_beat__, notify=__metronome_beat_changed__)
