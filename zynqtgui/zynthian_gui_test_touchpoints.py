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

from PySide2.QtCore import Slot, QAbstractItemModel, Qt, QModelIndex, QObject, Property
from . import zynthian_qt_gui_base


class zynthian_gui_grid_notes_model(QAbstractItemModel):
  NoteRole = Qt.DisplayRole

  __grid_notes__ = [
    [49,50,51,52,53,54,55,56],
    [41,42,43,44,45,46,47,48],
    [33,34,35,36,37,38,39,40],
    [25,26,27,28,29,30,31,32],
    [17,18,19,20,21,22,23,24],
    [9,10,11,12,13,14,15,16],
    [1,2,3,4,5,6,7,8],
  ]

  def __init__(self, parent: QObject = None) -> None:
    super(zynthian_gui_grid_notes_model, self).__init__(parent)
  
  def roleNames(self) -> typing.Dict:
    roles = {
      self.NoteRole: b'note'
    }

    return roles

  def data(self, index: QModelIndex, role: int) -> typing.Any:
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
  


class zynthian_gui_test_touchpoints(zynthian_qt_gui_base.ZynGui):
  def __init__(self, parent = None):
    super(zynthian_gui_test_touchpoints, self).__init__(parent)

    self.__port__ = mido.open_output('Midi Through Port-0')
    self.__notes_model__ = zynthian_gui_grid_notes_model()

  def show(self):
    pass

  def zyncoder_read(self):
    pass

  def refresh_loading(self):
    pass

  @Slot(str, result=None)
  def play_sound(self, note: str):
    self.__port__.send(mido.Message('note_on', note=60))

  @Property(QObject)
  def notesModel(self):
    return self.__notes_model__