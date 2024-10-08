#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian GUI Selector Base Class
# 
# Copyright (C) 2015-2020 Fernando Moyano <jofemodo@zynthian.org>
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
import os
import sys
import logging
from datetime import datetime

from PySide2.QtCore import Qt, Property, Signal, Slot, QObject, QByteArray, QTimer, QAbstractListModel, QModelIndex

# Zynthian specific modules
from zyngine import zynthian_controller
from . import zynthian_qt_gui_base
from . import zynthian_gui_config
from . import zynthian_gui_controller

import traceback


#------------------------------------------------------------------------------
# Model Class for the selector list
#------------------------------------------------------------------------------

class selector_list_model(QAbstractListModel):
    DISPLAY = Qt.DisplayRole
    ACTION_ID = Qt.UserRole + 1
    ENTRY_INDEX = Qt.UserRole + 3
    ICON = Qt.UserRole + 4
    SHOW_NUMBERS = Qt.UserRole + 5
    METADATA = Qt.UserRole + 6
    LARGE = Qt.UserRole + 7

    def __init__(self, parent=None):
        super(selector_list_model, self).__init__(parent)
        self.entries = []
        self.metadata = []

    def set_entries(self, entries, metadata):
        was_empty = len(self.entries) == 0

        if len(entries) > len(self.entries):
            self.beginInsertRows(QModelIndex(), len(self.entries), len(entries)-1)
            self.entries = entries
            self.metadata = metadata
            self.endInsertRows()
        elif len(entries) < len(self.entries):
            self.beginRemoveRows(QModelIndex(), len(entries), len(self.entries)-1)
            self.entries = entries
            self.metadata = metadata
            self.endRemoveRows()
        else:
            self.entries = entries
            self.metadata = metadata

        if not was_empty:
            self.dataChanged.emit(self.index(0,0), self.index(min(len(entries), len(self.entries)) - 1, 0))

        self.count_changed.emit()



    def roleNames(self):
        keys = {
            selector_list_model.DISPLAY : QByteArray(b'display'),
            selector_list_model.ACTION_ID : QByteArray(b'action_id'),
            selector_list_model.ENTRY_INDEX : QByteArray(b'entry_index'),
            selector_list_model.ICON : QByteArray(b'icon'),
            selector_list_model.SHOW_NUMBERS : QByteArray(b'show_numbers'),
            selector_list_model.METADATA : QByteArray(b'metadata'),
            selector_list_model.LARGE : QByteArray(b'large'),
            }
        return keys

    def rowCount(self, index):
        return len(self.entries)

    def get_count(self):
        return len(self.entries)

    def get_metadata(self, index, role_label):
        if len(self.entries) != len(self.metadata):
            return None

        if not index.isValid():
            return None

        if index.row() > len(self.metadata):
            return None

        metadata_entry = self.metadata[index.row()]
        if isinstance(metadata_entry, dict) and role_label == None:
            return metadata_entry
        elif isinstance(metadata_entry, dict) and role_label in metadata_entry:
            return metadata_entry[role_label]
        else:
            return None



    def data(self, index, role):
        if not index.isValid():
            return None

        if index.row() > len(self.entries):
            return None

        entry = self.entries[index.row()]
        if role == selector_list_model.DISPLAY:
            return entry[2]
        elif role == selector_list_model.ACTION_ID:
            return entry[0]
        elif role == selector_list_model.ENTRY_INDEX:
            return entry[1]
        elif role == selector_list_model.ICON:
            return self.get_metadata(index, 'icon')
        elif role == selector_list_model.SHOW_NUMBERS:
            return self.get_metadata(index, 'show_numbers')
        elif role == selector_list_model.METADATA:
            return self.get_metadata(index, None)
        elif role == selector_list_model.LARGE:
            return self.get_metadata(index, 'large')
        else:
            return None

    @Slot(int, result=str)
    def getDisplayValue(self, index):
        try:
            entry = self.entries[index]
            return entry[2]
        except Exception as e:
            logging.error(f"Error while fetching display value : {str(e)}")
            return "-"

    @Slot(int, result='QVariantMap')
    def getMetadataByIndex(self, index):
        return self.get_metadata(self.index(index, 0), None)

    count_changed = Signal()

    count = Property(int, get_count, notify = count_changed)



#------------------------------------------------------------------------------
# Zynthian Listbox Selector GUI Class
#------------------------------------------------------------------------------

class zynthian_gui_selector(zynthian_qt_gui_base.zynqtgui):
    def __init__(self, selcap='Select', parent = None):
        super(zynthian_gui_selector, self).__init__(parent)

        self.index = 0
        self.list_data = []
        self.list_metadata = []
        self.zselector = None
        self.zselector_hiden = False
        self.only_favs = True
        self.select_path = ''
        self.select_path_element = ''
        self.selector_caption=selcap
        self.list_model = None
        self.__auto_activate_index_on_change = False
        self.__auto_activation_timer = QTimer(self)
        self.__auto_activation_timer.setSingleShot(True)
        self.__auto_activation_timer.setInterval(50)
        self.__auto_activation_timer.timeout.connect(self.auto_activate_selected_index)
        self.__last_auto_activated_index = -1

    def auto_activate_selected_index(self):
        # Auto activate selected index if current screen is self and not already activated
        if self.zynqtgui.get_current_screen_id() != None and self.zynqtgui.get_current_screen() == self and self.__last_auto_activated_index != self.index:
            self.select(self.index)
            self.select_action(self.index, 'S')
            self.__last_auto_activated_index = self.index

    def get_selector_list(self):
        if self.list_model == None:
            self.list_model = selector_list_model(self)
        self.list_model.set_entries(self.list_data, self.list_metadata)
        return self.list_model

    # TODO: should become load/reload or something like that
    @Slot('void')
    def show(self):
        self.fill_list()
        self.set_select_path()

    def preload(self):
        self.zynqtgui.restore_curlayer()
        self.fill_list()
        self.set_select_path()

    def get_caption(self):
        return self.selector_caption

    def set_select_path(self):
        self.selector_path_changed.emit()
        self.selector_path_element_changed.emit()

    def get_selector_path(self):
        return self.select_path

    def get_selector_path_element(self):
        return self.select_path_element

    # TODO: remove?
    def plot_zctrls(self):
        self.zselector.plot_value()

    def fill_list(self):
        if self.list_model != None:
            self.list_model.set_entries(self.list_data, self.list_metadata)
        self.select()
        self.last_index_change_ts = datetime.min
        self.effective_count_changed.emit()
        self.list_updated.emit()

    def update_list(self):
        self.fill_list()

    # This to allow subclasses to override the property without redeclaring
    def get_effective_count_prop(self):
        return self.get_effective_count()

    def get_effective_count(self):
        if self.list_model is None:
            return 0
        return self.list_model.get_count()

    def refresh_loading(self):
        pass

    # TODO: remove
    def get_cursel(self):
        return self.index

    @Slot('int')
    def activate_index(self, index):
        if index is not None:
            self.select(index)
        else:
            self.index=self.get_cursel()

        self.select_action(self.index, 'S')

    @Slot('int')
    def activate_index_secondary(self, index):
        if index is not None:
            self.select(index)
        else:
            self.index=self.get_cursel()

        self.select_action(self.index, 'B')

    def set_current_index(self, index):
        self.select(index)
        # Activate selected index automatically if autoActivateIndexOnChange is set to True
        if self.__auto_activate_index_on_change:
            self.__auto_activation_timer.start()

    def get_current_index(self):
        return self.index

    def select(self, index=None):
        if index is None: index=self.index
        # Ignore invalid indexes
        if index < -1 or index >= len(self.list_data):
            return
        self.index = index
        self.set_select_path()
        self.current_index_changed.emit()

    def index_supports_immediate_activation(self, index=None):
        return False

    @Slot()
    def select_up(self, n=1):
        new_index = max(0, self.index - n)
        self.set_current_index(new_index)

    @Slot()
    def select_down(self, n=1):
        new_index = min(len(self.list_data) - 1, self.index + n)
        self.set_current_index(new_index)

    # TODO: remove
    def click_listbox(self, index=None, t='S'):
        if index is not None:
            self.select(index)
        else:
            self.index=self.get_cursel()

        self.select_action(self.index, t)

    # TODO: remove
    def switch_select(self, t='S'):
        self.click_listbox(None, t)

    def select_action(self, index, t='S'):
        pass

    # TODO: remove
    def cb_listbox_push(self,event):
        self.listbox_push_ts=datetime.now()
        #logging.debug("LISTBOX PUSH => %s" % (self.listbox_push_ts))

    # TODO: remove
    def cb_listbox_release(self,event):
        if self.listbox_push_ts:
            dts=(datetime.now()-self.listbox_push_ts).total_seconds()
            #logging.debug("LISTBOX RELEASE => %s" % dts)
            if dts < 0.3:
                self.zynqtgui.zynswitch_defered('S',3)
            elif dts>=0.3 and dts<2:
                self.zynqtgui.zynswitch_defered('B',3)

    # TODO: remove
    def cb_listbox_wheel(self,event):
        index = self.index
        if (event.num == 5 or event.delta == -120) and self.index>0:
            index -= 1
        if (event.num == 4 or event.delta == 120) and self.index < (len(self.list_data)-1):
            index += 1
        if index!=self.index:
            self.zselector.set_value(index, True, False)

    # TODO: remove
    def cb_loading_push(self,event):
        self.loading_push_ts=datetime.now()
        #logging.debug("LOADING PUSH => %s" % self.canvas_push_ts)

    # TODO: remove
    def cb_loading_release(self,event):
        if self.loading_push_ts:
            dts=(datetime.now()-self.loading_push_ts).total_seconds()
            logging.debug("LOADING RELEASE => %s" % dts)
            if dts<0.3:
                self.zynqtgui.zynswitch_defered('S',2)
            elif dts>=0.3 and dts<2:
                self.zynqtgui.zynswitch_defered('B',2)
            elif dts>=2:
                self.zynqtgui.zynswitch_defered('L',2)

    def get_autoActivateIndexOnChange(self):
        return self.__auto_activate_index_on_change

    def set_autoActivateIndexOnChange(self, value):
        if self.__auto_activate_index_on_change != value:
            # logging.debug(f"Setting autoActivateIndexOnChange : {value}")
            self.__auto_activate_index_on_change = value
            self.autoActivateIndexOnChangeChanged.emit()

    current_index_changed = Signal()
    selector_path_changed = Signal()
    selector_path_element_changed = Signal()
    effective_count_changed = Signal()
    list_updated = Signal()
    autoActivateIndexOnChangeChanged = Signal()

    selector_list = Property(QObject, get_selector_list, constant = True)
    current_index = Property(int, get_current_index, set_current_index, notify = current_index_changed)
    effective_count = Property(int, get_effective_count_prop, notify = effective_count_changed)
    selector_path = Property(str, get_selector_path, notify = selector_path_changed)
    selector_path_element = Property(str, get_selector_path_element, notify = selector_path_element_changed)
    caption = Property(str, get_caption, constant = True)
    autoActivateIndexOnChange = Property(bool, get_autoActivateIndexOnChange, set_autoActivateIndexOnChange, notify=autoActivateIndexOnChangeChanged)
#------------------------------------------------------------------------------
