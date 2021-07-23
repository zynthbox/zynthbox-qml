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

	def __init__(self, parent=None):
		super(selector_list_model, self).__init__(parent)
		self.entries = []

	def set_entries(self, entries):
		was_empty = len(self.entries) == 0

		if len(entries) > len(self.entries):
			self.beginInsertRows(QModelIndex(), len(self.entries), len(entries)-1)
			self.entries = entries
			self.endInsertRows()
		elif len(entries) < len(self.entries):
			self.beginRemoveRows(QModelIndex(), len(entries), len(self.entries)-1)
			self.entries = entries
			self.endRemoveRows()
		else:
			self.entries = entries

		if not was_empty:
			self.dataChanged.emit(self.index(0,0), self.index(min(len(entries), len(self.entries)) - 1, 0))

		self.count_changed.emit()



	def roleNames(self):
		keys = {
			selector_list_model.DISPLAY : QByteArray(b'display'),
			selector_list_model.ACTION_ID : QByteArray(b'action_id'),
			selector_list_model.ENTRY_INDEX : QByteArray(b'entry_index'),
			selector_list_model.ICON : QByteArray(b'icon'),
			}
		return keys

	def rowCount(self, index):
		return len(self.entries)

	def get_count(self):
		return len(self.entries)

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
			if len(entry) > 3 and entry[3] != None and 'icon' in entry[3]:
				logging.error(entry[3])
				logging.error(entry[3]['icon'])
				return entry[3]['icon']
			else:
				return None
		else:
			return None


	count_changed = Signal()

	count = Property(int, get_count, notify = count_changed)



#------------------------------------------------------------------------------
# Zynthian Listbox Selector GUI Class
#------------------------------------------------------------------------------

class zynthian_gui_selector(zynthian_qt_gui_base.ZynGui):

	def __init__(self, selcap='Select', parent = None):
		super(zynthian_gui_selector, self).__init__(parent)

		self.index = 0
		self.list_data = []
		self.zselector = None
		self.zselector_hiden = False
		self.only_favs = True
		self.select_path = ''
		self.select_path_element = ''

		last_index_change_ts = datetime.min
		self.selector_caption=selcap
		self.list_model = None

		self.auto_activation_timer = QTimer(self)
		self.auto_activation_timer.setInterval(250)
		self.auto_activation_timer.setSingleShot(True)
		self.auto_activation_timer.timeout.connect(self.auto_activation_timeout)
		self.screen_at_timer_start = None

	def get_selector_list(self):
		if self.list_model == None:
			self.list_model = selector_list_model(self)
		self.list_model.set_entries(self.list_data)
		return self.list_model

	# TODO: should become load/reload or something like that
	@Slot('void')
	def show(self):
		self.fill_list()
		self.set_selector()
		self.set_select_path()

	def preload(self):
		self.zyngui.restore_curlayer()
		self.fill_list()
		self.set_selector()
		self.set_select_path()


	def set_selector(self, zs_hiden=False):
		if self.zselector:
			self.zselector_ctrl.set_options({ 'symbol':self.selector_caption, 'name':self.selector_caption, 'short_name':self.selector_caption, 'midi_cc':0, 'value_max':len(self.list_data), 'value':self.index })
			self.zselector.config(self.zselector_ctrl)
			self.zselector.show()
		else:
			self.zselector_ctrl=zynthian_controller(None,self.selector_caption,self.selector_caption,{ 'midi_cc':0, 'value_max':len(self.list_data), 'value':self.index })
			self.zselector=zynthian_gui_controller(zynthian_gui_config.select_ctrl,self.zselector_ctrl, self)

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
			self.list_model.set_entries(self.list_data)
		self.select()
		self.last_index_change_ts = datetime.min
		self.effective_count_changed.emit()


	def update_list(self):
		self.fill_list()
		self.set_selector()

	# This to allow subclasses to override the property without redeclaring
	def get_effective_count_prop(self):
		return self.get_effective_count()

	def get_effective_count(self):
		return self.list_model.get_count()

	# TODO: remove?
	def refresh_loading(self):
		pass
		#self.update_list();

	# TODO: remove
	def get_cursel(self):
		return self.index


	def zyncoder_read(self):
		# FIXME: figure out why sometimes the value is wrong
		if False: #self.zselector:
			self.zselector.read_zyncoder()
			if self.index!=self.zselector.value:
				self.select(self.zselector.value)
		return [0,1,2]

	@Slot('int')
	def activate_index(self, index):
		if index is not None:
			self.select(index)
		else:
			self.index=self.get_cursel()

		self.select_action(self.index, 'S')

	def auto_activation_timeout(self):
		#HACK
		if self.screen_at_timer_start == self.zyngui.get_current_screen_id() and self.index_supports_immediate_activation(self.index):
			old_screen = self.zyngui.get_current_screen_id()
			self.select_action(self.index, 'S')
			if self.zyngui.get_current_screen_id() != old_screen:
				if self.zyngui.modal_screen:
					self.zyngui.show_modal(old_screen)
				else:
					self.zyngui.show_screen(old_screen)

	@Slot('int')
	def activate_index_secondary(self, index):
		if index is not None:
			self.select(index)
		else:
			self.index=self.get_cursel()

		self.select_action(self.index, 'B')


	def set_current_index(self, index):
		self.select(index)

	def get_current_index(self):
		return self.index

	def select(self, index=None):
		if index is None: index=self.index
		# Ignore invalid indexes
		if index < 0 or index >= len(self.list_data):
			return
		self.index = index
		if self.zselector and self.zselector.value != self.index:
			self.zselector.set_value(self.index, True, False)
		self.current_index_changed.emit()

	def index_supports_immediate_activation(self, index=None):
		return False

	def select_up(self, n=1):
		self.screen_at_timer_start = self.zyngui.get_current_screen_id()
		self.auto_activation_timer.start()
		self.select(self.index-n)


	def select_down(self, n=1):
		self.screen_at_timer_start = self.zyngui.get_current_screen_id()
		self.auto_activation_timer.start()
		self.select(self.index+n)


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
				self.zyngui.zynswitch_defered('S',3)
			elif dts>=0.3 and dts<2:
				self.zyngui.zynswitch_defered('B',3)


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
				self.zyngui.zynswitch_defered('S',2)
			elif dts>=0.3 and dts<2:
				self.zyngui.zynswitch_defered('B',2)
			elif dts>=2:
				self.zyngui.zynswitch_defered('L',2)


	current_index_changed = Signal()
	selector_path_changed = Signal()
	selector_path_element_changed = Signal()
	effective_count_changed = Signal()

	selector_list = Property(QObject, get_selector_list, constant = True)
	current_index = Property(int, get_current_index, set_current_index, notify = current_index_changed)
	effective_count = Property(int, get_effective_count_prop, notify = effective_count_changed)
	selector_path = Property(str, get_selector_path, notify = selector_path_changed)
	selector_path_element = Property(str, get_selector_path_element, notify = selector_path_element_changed)
	caption = Property(str, get_caption, constant = True)
#------------------------------------------------------------------------------
