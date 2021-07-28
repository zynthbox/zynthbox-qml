#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian Test Touchpoints: A Test page to test multi
# 
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

import mido
import typing

from PySide2.QtCore import Slot, QAbstractItemModel, Qt, QModelIndex, QObject, Property, Signal
from PySide2.QtQml import qmlRegisterType
from . import zynthian_qt_gui_base


class Note(QObject):
  def __init__(self, name: str, midi_note: int, midi_port, parent:QObject = None):
    super(Note, self).__init__(parent)
    self.__note_name__ = name
    self.__midi_note__ = midi_note
    self.__midi_port__ = midi_port
    self.__midi_note_on_msg__ = mido.Message('note_on', note=self.__midi_note__)
    self.__midi_note_off_msg__ = mido.Message('note_off', note=self.__midi_note__)
  
  @Slot(None)
  def on(self):
    self.__midi_port__.send(self.__midi_note_on_msg__)

  @Slot(None)
  def off(self):
    self.__midi_port__.send(self.__midi_note_off_msg__)

  @Property(str, constant=True)
  def name(self):
    return self.__note_name__


class zynthian_gui_grid_notes_model(QAbstractItemModel):
  NoteRole = Qt.DisplayRole

  __rows__: int = 5
  __columns__: int = 8
  __starting_note__: int = 36
  __note_int_to_str_map__ = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']
  __grid_notes__ = []

  def __init__(self, parent: QObject = None) -> None:
    super(zynthian_gui_grid_notes_model, self).__init__(parent)

    self.__midi_port__ = mido.open_output('Midi Through Port-0')
    self.__populate_grid__()
  
  def roleNames(self) -> typing.Dict:
    roles = {
      self.NoteRole: b'note'
    }

    return roles

  def data(self, index: QModelIndex, role: int) -> Note:
    print(index.isValid(), role)

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

  def __get_note_str_from_int__(self, note: int) -> str:
    return '{note_str}{octave}'.format(note_str=self.__note_int_to_str_map__[note%12], octave=note//12)

  def __populate_grid__(self) -> None:
    for row in range(0, self.__rows__):
      row_data = []
      multiplier = row*self.__columns__

      for col in range(multiplier + self.__starting_note__, multiplier + self.__columns__ + self.__starting_note__):
        row_data.append(Note(
          name=self.__get_note_str_from_int__(col),
          midi_note=col,
          midi_port=self.__midi_port__,
          parent=self
        ))
      
      self.__grid_notes__.insert(0, row_data)

  def __get_rows__(self):
    return self.__rows__

  def __get_columns__(self):
    return self.__columns__

  def __get_starting_note__(self):
    return self.__starting_note__

  def __set_rows__(self, rows):
    self.__rows__ = rows
    self.__rows_changed__.emit()

  def __set_columns__(self, columns):
    self.__columns__ = columns
    self.__columns_changed__.emit()

  def __set_starting_note__(self, note):
    self.__starting_note__ = note
    self.__starting_note_changed__.emit()


  @Property(dict, constant=True)
  def roles(self):
    return {
      b'note': self.NoteRole
    }

  @Signal
  def __rows_changed__(self):
    pass

  @Signal
  def __columns_changed__(self):
    pass

  @Signal
  def __starting_note_changed__(self):
    pass
  
  rows = Property(int, __get_rows__, __set_rows__, notify=__rows_changed__)
  columns = Property(int, __get_columns__, __set_columns__, notify=__columns_changed__)
  startingNote = Property(int, __get_starting_note__, __set_starting_note__, notify=__starting_note_changed__)
  


class zynthian_gui_playgrid(zynthian_qt_gui_base.ZynGui):
  def __init__(self, parent = None):
    super(zynthian_gui_playgrid, self).__init__(parent)
    
    qmlRegisterType(zynthian_gui_grid_notes_model, 'Zynthian.QmlUI', 1, 0, 'PlayGridNotesGridModel')


  def show(self):
    pass

  def zyncoder_read(self):
    pass

  def refresh_loading(self):
    pass