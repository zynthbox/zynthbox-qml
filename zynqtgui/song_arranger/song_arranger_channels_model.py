#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# A model to for storing channels in Sketchpad page
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

from PySide2.QtCore import QAbstractListModel, QModelIndex, QObject, Qt, Property, Signal, Slot


class song_arranger_channels_model(QAbstractListModel):
    ChannelRole = Qt.UserRole + 1
    ZLChannelRole = ChannelRole + 1

    def __init__(self, parent=None):
        super(song_arranger_channels_model, self).__init__(parent)
        self.__channels__ = []

    ### Property count
    def count(self):
        return len(self.__channels__)

    countChanged = Signal()
    count = Property(int, count, notify=countChanged)
    ### END Property count

    @Slot(int, result=QObject)
    def getChannel(self, row: int):
        if row < 0 or row >= len(self.__channels__):
            return None
        return self.__channels__[row]

    def data(self, index, role=None):
        # logging.info(index.row(), self.__channels__[index.row()])

        if not index.isValid():
            return None

        if index.row() >= len(self.__channels__):
            return None

        if role == self.ChannelRole:
            return self.__channels__[index.row()]
        elif role == self.ZLChannelRole:
            return self.__channels__[index.row()].zlChannel
        else:
            return None

    def roleNames(self):
        role_names = {
            self.ChannelRole: b"channel",
            self.ZLChannelRole: b"zlChannel",
        }

        return role_names

    def rowCount(self, index):
        return len(self.__channels__)

    def add_channel(self, channel):
        length = len(self.__channels__)

        self.beginInsertRows(QModelIndex(), length, length)
        self.__channels__.append(channel)
        self.endInsertRows()
        self.countChanged.emit()

    def clear(self):
        if len(self.__channels__) > 0:
            self.beginRemoveRows(QModelIndex(), 0, len(self.__channels__)-1)

            for channel in self.__channels__:
                for cell_index in range(0, channel.cellsModel.count):
                    cell = channel.cellsModel.getCell(cell_index)
                    cell.destroy()

            self.__channels__ = []
            self.endRemoveRows()
