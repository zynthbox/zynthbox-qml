#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# A model to for storing parts of a song in ZynthiLoops
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

from PySide2.QtCore import QAbstractListModel, QModelIndex, QObject, Qt
from .zynthiloops_part import zynthiloops_part


class zynthiloops_parts_model(QAbstractListModel):
    IdRole = Qt.UserRole + 1
    NameRole = IdRole + 1

    __parts__: [zynthiloops_part] = []

    def __init__(self, parent: QObject = None):
        super(zynthiloops_parts_model, self).__init__(parent)

        # for i in range(0, 2):
        #     self.add_part(zynthiloops_part(i))

        logging.info(self.__parts__)

    def data(self, index, role=None):
        # if not index.isValid():
        #     return None

        logging.info(index.row(), self.__parts__[index.row()])

        # if index.row() > len(self.__parts__):
        #     return None

        if role == self.IdRole:
            return self.__parts__[index.row()].id
        elif role == self.NameRole:
            return self.__parts__[index.row()].name
        else:
            return self.__parts__[index.row()]

    def roleNames(self):
        role_names = {
            self.IdRole: b"id",
            self.NameRole: b"name",
        }

        return role_names

    def rowCount(self, index):
        return len(self.__parts__)

    def add_part(self, part: zynthiloops_part):
        length = len(self.__parts__)

        self.beginInsertRows(QModelIndex(), length, length)
        self.__parts__.append(part)
        self.endInsertRows()
