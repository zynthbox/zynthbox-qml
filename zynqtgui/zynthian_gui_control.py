#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian GUI Instrument-Control Class
# 
# Copyright (C) 2015-2016 Fernando Moyano <jofemodo@zynthian.org>
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
import math
import os
from time import sleep
from string import Template
from datetime import datetime
from pathlib import Path
from json import JSONEncoder, JSONDecoder

# Zynthian specific modules
from zyngine import zynthian_controller
from . import zynthian_gui_config
from . import zynthian_gui_controller
from . import zynthian_gui_selector

# Qt modules
from PySide2.QtCore import Qt, QObject, Slot, Signal, Property, QAbstractListModel, QModelIndex, QByteArray

#------------------------------------------------------------------------------
# Zynthian Instrument Controller GUI Class
#------------------------------------------------------------------------------

class control_pages_list_model(QAbstractListModel):
	DISPLAY = Qt.DisplayRole
	PATH = Qt.UserRole + 1

	def __init__(self, parent=None):
		super(control_pages_list_model, self).__init__(parent)
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
			control_pages_list_model.DISPLAY : QByteArray(b'display'),
			control_pages_list_model.PATH : QByteArray(b'path'),
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
		if role == control_pages_list_model.DISPLAY:
			return entry["display"]
		elif role == control_pages_list_model.PATH:
			return entry["path"]
		else:
			return None

	count_changed = Signal()

	count = Property(int, get_count, notify = count_changed)



class zynthian_gui_control(zynthian_gui_selector):

	def __init__(self, selcap='Controllers', parent = None):
		super(zynthian_gui_control, self).__init__(selcap, parent)

		self.mode=None

		self.ctrl_screens={}
		self.zcontrollers=[]
		self.screen_name=None
		self.controllers_lock=False

		self.zgui_controllers=[]
		self.zgui_controllers_map={}

		self.zgui_custom_controllers=[]
		self.zgui_custom_controllers_map={}
		self.custom_controller_id_start = 100

		self.__last_custom_control_page = None
		self.__control_pages_model = control_pages_list_model(self)
		self.__custom_control_page = None
		self.__conf = {}
		self.__single_effect_engine = None
		self.__custom_controller_mode = False
		self._active_custom_controller = None

		# xyselect mode vars
		self.xyselect_mode=False
		self.x_zctrl=None
		self.y_zctrl=None

		self.load_config()

		self.show()

	def load_config(self):
		json = None
		fpath = "/zynthian/config/control_page.conf"
		try:
			with open(fpath, "r") as fh:
				json = fh.read()
				logging.info("Loading control config %s => \n%s" % (fpath, json))

		except Exception as e:
			logging.error("Can't load control config '%s': %s" % (fpath, e))

		try:
			self.__conf = JSONDecoder().decode(json)
			if self.__single_effect_engine == None:
				if self.zyngui.curlayer.engine.nickname in self.__conf:
					self.set_custom_control_page(self.__conf[self.zyngui.curlayer.engine.nickname]["custom_control_page"])
				else:
					self.set_custom_control_page("")
			else:
				if self.__single_effect_engine in self.__conf:
					self.set_custom_control_page(self.__conf[self.__single_effect_engine]["custom_control_page"])
				else:
					self.set_custom_control_page("")
		except Exception as e:
			logging.error("Can't parse control config '%s': %s" % (fpath, e))
			if self.__single_effect_engine != None:
				self.set_custom_control_page("")


	def set_single_effect_engine(self, eng : str):
		if self.__single_effect_engine == eng:
			return
		if eng == "":
			self.__single_effect_engine = None
		else:
			self.__single_effect_engine = eng
		self.fill_list()
		self.single_effect_engine_changed.emit()

	def get_single_effect_engine(self):
		return self.__single_effect_engine

	def get_active_custom_controller(self):
		return self._active_custom_controller

	def set_active_custom_controller(self, controller):
		if self._active_custom_controller == controller:
			return
		if self._active_custom_controller:
			self._active_custom_controller.index = self._active_custom_controller.old_index
			self._active_custom_controller.setup_zyncoder()
		self._active_custom_controller = controller
		if controller:
			self._active_custom_controller.old_index = self._active_custom_controller.index
			self._active_custom_controller.index = 3
			self._active_custom_controller.setup_zyncoder()
		active_custom_controller_changed.emit()

	def show(self):
		super().show()
		self.click_listbox()
		if self.zyngui.curlayer:
			path = "/root/.local/share/zynthian/engineeditpages/"
			entries = []
			engine = self.zyngui.curlayer.engine.nickname
			if self.__single_effect_engine != None:
				engine = self.__single_effect_engine
			if Path(path).exists():
				for module_dir in [f for f in os.scandir(path) if f.is_dir()]:
					if module_dir.is_dir():
						metadatapath = module_dir.path + "/metadata.json";
						try:
							fh = open(metadatapath, "r")
							json = fh.read()
							metadata = JSONDecoder().decode(json)
							if metadata["Engine"] == engine:
								entries.append({"display": metadata["Name"],
												"path": module_dir.path})
						except:
							continue

			engine_folder_name = engine.replace("/", "_").replace(" ", "_")
			path = "/zynthian/zynthian-ui/qml-ui/engineeditpages/" + engine_folder_name + "/contents/main.qml"
			if Path(path).exists():
				entries.append({"display": "Default",
								"path": "/zynthian/zynthian-ui/qml-ui/engineeditpages/" + engine_folder_name})
			entries.append({"display": "Zynthian",
							"path": ""})
			self.__control_pages_model.set_entries(entries)
		else:
			self.__control_pages_model.set_entries([])


	def hide(self):
		super().hide()
		#if self.shown:
		#	for zc in self.zgui_controllers: zc.hide()
		#	if self.zselector: self.zselector.hide()

	def preload(self):
		super().preload()
		self.set_controller_screen()

	def fill_list(self):
		self.list_data = []

		if not self.zyngui.curlayer:
			logging.error("Can't fill control screen list for None layer!")
			return

		self.layers = self.zyngui.screens['layer'].get_fxchain_layers()
		# If no FXChain layers, then use the curlayer itself
		if self.layers is None or len(self.layers)==0:
			self.layers = [self.zyngui.curlayer]

		midichain_layers = self.zyngui.screens['layer'].get_midichain_layers()
		if midichain_layers is not None and len(midichain_layers)>1:
			try:
				midichain_layers.remove(self.zyngui.curlayer)
			except:
				pass
			self.layers += midichain_layers

		i = 0
		for layer in self.layers:
			if self.__single_effect_engine != None and layer.engine.nickname != self.__single_effect_engine:
				continue
			j = 0
			if self.__single_effect_engine == None and len(self.layers) > 1:
				self.list_data.append((None,None,"> {}".format(layer.engine.name.split("/")[-1])))
			for cscr in layer.get_ctrl_screens():
				self.list_data.append((cscr,i,cscr,layer,j))
				i += 1
				j += 1
		if self.__single_effect_engine == None:
			self.index = self.zyngui.curlayer.get_active_screen_index()
		else:
			self.index = 0
		if len(self.list_data) > self.index and len(self.list_data[self.index]) < 4:
			self.index = 1
		super().fill_list()


	def set_selector(self, zs_hiden=True):
		if self.mode=='select': super().set_selector(zs_hiden)

	def get_controllers_count(self):
		return len(self.zgui_controllers)

	@Slot(int, result=QObject)
	def controller(self, index):
		if index < 0 or index >= len(self.zgui_controllers):
			return None
		return self.zgui_controllers[index]

	@Slot(str, int, result=QObject)
	def controller_by_category(self, cat, index):
		controllers = []
		if self.__single_effect_engine != None:
			fxchain_layers = self.zyngui.screens['layer'].get_fxchain_layers()
			if fxchain_layers != None:
				for layer in fxchain_layers:
					if layer.engine.nickname == self.__single_effect_engine:
						controllers = layer.get_ctrl_screens()
			midichain_layers = self.zyngui.screens['layer'].get_midichain_layers()
			if midichain_layers != None:
				for layer in midichain_layers:
					if layer.engine.nickname == self.__single_effect_engine:
						controllers = layer.get_ctrl_screens()
		elif self.zyngui.curlayer:
			controllers = self.zyngui.curlayer.get_ctrl_screens()
		else:
			return None
		if cat in controllers:
			controllers_cat = controllers[cat]
			if index < 0 or index >= len(controllers_cat):
				return None

			zctrl = controllers[cat][index]
			if zctrl in self.zgui_custom_controllers_map:
				return self.zgui_custom_controllers_map[zctrl]
			else:
				self.set_custom_zcontroller(len(self.zgui_custom_controllers), zctrl)
			return self.zgui_custom_controllers_map[zctrl]
		else:
			return None

	@Slot(str, int, result=QObject)
	def amixer_controller_by_category(self, cat, index):
		if not self.zyngui.screens["layer"].amixer_layer:
			return None

		controllers = self.zyngui.screens["layer"].amixer_layer.get_ctrl_screens()
		if cat in controllers:
			controllers_cat = controllers[cat]
			if index < 0 or index >= len(controllers_cat):
				return None

			zctrl = controllers[cat][index]
			if zctrl in self.zgui_custom_controllers_map:
				return self.zgui_custom_controllers_map[zctrl]
			else:
				self.set_custom_zcontroller(len(self.zgui_custom_controllers), zctrl)
			return self.zgui_custom_controllers_map[zctrl]
		else:
			return None

	def get_control_pages_model(self):
		return self.__control_pages_model

	def set_custom_control_page(self, path):
		if self.zyngui.curlayer is None or self.zyngui.curlayer.engine is None:
			return
		final_path = path
		if not final_path.endswith("/contents/main.qml"):
			final_path += "/contents/main.qml"
		if path == "":
			if self.__custom_control_page != path:
				self.__custom_control_page = path
				self.custom_control_page_changed.emit()
		elif Path(final_path).exists():
			if self.__custom_control_page != final_path:
				self.__custom_control_page = final_path
				self.custom_control_page_changed.emit()
			for ctrl in self.zgui_custom_controllers_map.values():
				ctrl.setup_zyncoder()
		try:
			if self.__single_effect_engine == None:
				self.__conf[self.zyngui.curlayer.engine.nickname] = {"custom_control_page": self.__custom_control_page}
			else:
				self.__conf[self.__single_effect_engine] = {"custom_control_page": self.__custom_control_page}
			json = JSONEncoder().encode(self.__conf)
			with open("/zynthian/config/control_page.conf","w") as fh:
				fh.write(json)
				fh.flush()
				os.fsync(fh.fileno())
		except Exception as e:
			logging.error("Can't save config '/zynthian/config/control_page.conf': %s" % (e))


	def get_default_custom_control_page(self):
		if self.zyngui.curlayer is None or self.zyngui.curlayer.engine is None:
			return None
		engine_folder_name = self.zyngui.curlayer.engine.nickname.replace("/", "_").replace(" ", "_")
		# TODO: also search for stuff installed in ~/.local
		path = "/zynthian/zynthian-ui/qml-ui/engineeditpages/" + engine_folder_name + "/contents/main.qml"
		if Path(path).exists():
			self.__last_custom_control_page = path
			return path
		else:
			self.__last_custom_control_page = None
			return None



	def get_custom_control_page(self):
		if self.zyngui.curlayer is None or self.zyngui.curlayer.engine is None:
			return None
		if self.__custom_control_page == None:
			return self.get_default_custom_control_page()
		else:
			return self.__custom_control_page

	def lock_controllers(self):
		self.controllers_lock = True


	def unlock_controllers(self):
		self.controllers_lock = False


	def set_controller_screen(self):
		#Get Mutex Lock 
		#self.zyngui.lock.acquire()

		# Destroy all the custom controllers
		self.zgui_custom_controllers_map={}
		for gctrl in self.zgui_custom_controllers:
			gctrl.deleteLater()
		self.zgui_custom_controllers=[]

		#Get screen info
		if self.index < len(self.list_data):
			screen_info = self.list_data[self.index]
			screen_title = screen_info[2]
			if len(screen_info) > 3:
				screen_layer = screen_info[3]

			#Get controllers for the current screen
			self.zyngui.curlayer.set_active_screen_index(self.index)
			if len(screen_info) > 3:
				self.zcontrollers = screen_layer.get_ctrl_screen(screen_title)

		else:
			self.zcontrollers = None

		#Setup GUI Controllers
		if self.zcontrollers:
			logging.debug("SET CONTROLLER SCREEN {}".format(screen_title))
			#Configure zgui_controllers
			i=0
			for ctrl in self.zcontrollers:
				try:
					#logging.debug("CONTROLLER ARRAY {} => {} ({})".format(i, ctrl.symbol, ctrl.short_name))
					self.set_zcontroller(i,ctrl)
					i=i+1
				except Exception as e:
					logging.exception("Controller %s (%d) => %s" % (ctrl.short_name,i,e))
					if len(self.zgui_controllers) < i:
						self.zgui_controllers[i].hide()

			#Hide rest of GUI controllers
			for i in range(i,len(self.zgui_controllers)):
				self.zgui_controllers[i].hide()

			#Set/Restore XY controllers highlight
			self.set_xyselect_controllers()

		#Hide All GUI controllers
		else:
			for zgui_controller in self.zgui_controllers:
				zgui_controller.hide()

		self.lock_controllers()

		self.controllers_count_changed.emit()

		self.load_config()

		if self.__last_custom_control_page != self.get_custom_control_page():
			self.custom_control_page_changed.emit()
			self.default_custom_control_page_changed.emit()
		#Release Mutex Lock
		#self.zyngui.lock.release()


	def set_zcontroller(self, i, ctrl):
		if i < len(self.zgui_controllers):
			self.zgui_controllers[i].config(ctrl)
			self.zgui_controllers[i].show()
		else:
			self.zgui_controllers.append(zynthian_gui_controller(i, ctrl, self))
			self.controllers_count_changed.emit()
		self.zgui_controllers_map[ctrl]=self.zgui_controllers[i]


	def set_custom_zcontroller(self, i, ctrl):
		if i < len(self.zgui_custom_controllers):
			self.zgui_custom_controllers[i].config(ctrl)
			self.zgui_custom_controllers[i].show()
		else:
			self.zgui_custom_controllers.append(zynthian_gui_controller(i + self.custom_controller_id_start, ctrl, self))
		self.zgui_custom_controllers_map[ctrl]=self.zgui_custom_controllers[i]


	def set_xyselect_controllers(self):
		for i in range(0,len(self.zgui_controllers)):
			try:
				if self.xyselect_mode:
					zctrl=self.zgui_controllers[i].zctrl
					if zctrl==self.x_zctrl or zctrl==self.y_zctrl:
						self.zgui_controllers[i].set_hl()
						continue
				self.zgui_controllers[i].unset_hl()
			except:
				pass


	def set_selector_screen(self): 
		for i in range(0,len(self.zgui_controllers)):
			self.zgui_controllers[i].set_hl(zynthian_gui_config.color_ctrl_bg_off)
		self.set_selector()


	def set_mode_select(self):
		self.mode='select'
		self.set_selector_screen()
		#self.listbox.config(selectbackground=zynthian_gui_config.color_ctrl_bg_on,
		#	selectforeground=zynthian_gui_config.color_ctrl_tx,
		#	fg=zynthian_gui_config.color_ctrl_tx)
		#self.listbox.config(selectbackground=zynthian_gui_config.color_ctrl_bg_off,
			#selectforeground=zynthian_gui_config.color_ctrl_tx,
			#fg=zynthian_gui_config.color_ctrl_tx_off)
		self.select(self.index)
		self.set_select_path()


	def set_mode_control(self):
		self.mode='control'
		if self.zselector: self.zselector.hide()
		self.set_controller_screen()
		self.set_select_path()
		self.controllers_changed.emit()


	def set_xyselect_mode(self, xctrl_i, yctrl_i):
		self.xyselect_mode=True
		self.xyselect_zread_axis='X'
		self.xyselect_zread_counter=0
		self.xyselect_zread_last_zctrl=None
		self.x_zctrl=self.zgui_controllers[xctrl_i].zctrl
		self.y_zctrl=self.zgui_controllers[yctrl_i].zctrl
		#Set XY controllers highlight
		self.set_xyselect_controllers()
		
		
	def unset_xyselect_mode(self):
		self.xyselect_mode=False
		#Set XY controllers highlight
		self.set_xyselect_controllers()


	def set_xyselect_x(self, xctrl_i):
		zctrl=self.zgui_controllers[xctrl_i].zctrl
		if self.x_zctrl!=zctrl and self.y_zctrl!=zctrl:
			self.x_zctrl=zctrl
			#Set XY controllers highlight
			self.set_xyselect_controllers()
			return True


	def set_xyselect_y(self, yctrl_i):
		zctrl=self.zgui_controllers[yctrl_i].zctrl
		if self.y_zctrl!=zctrl and self.x_zctrl!=zctrl:
			self.y_zctrl=zctrl
			#Set XY controllers highlight
			self.set_xyselect_controllers()
			return True


	def select_action(self, i, t='S'):
		self.set_mode_control()

	def index_supports_immediate_activation(self, index=None):
		return True

	def back_action(self):
		if self.__single_effect_engine != None:
			if "MIDI" in self.__single_effect_engine:
				return "layer_midi_effect_chooser"
			else:
				return "layer_effect_chooser"
		# If in controller map selection, back to instrument control
		if self.mode=='select':
			self.set_mode_control()
			return ''

		# If control xyselect mode active, disable xyselect mode
		elif self.xyselect_mode:
			logging.debug("DISABLE XYSELECT MODE")
			self.unset_xyselect_mode()
			return 'control'

		# If in MIDI-learn mode, back to instrument control
		elif self.zyngui.midi_learn_mode or self.zyngui.midi_learn_zctrl:
			self.zyngui.exit_midi_learn_mode()
			return ''

		else:
			self.zyngui.screens['layer'].restore_curlayer()
			return None


	def next(self):
		self.index+=1
		if self.index>=len(self.list_data):
			self.index=0
		self.select(self.index)
		self.click_listbox()
		return True


	def switch_select(self, t='S'):
		if t=='S':
			if self.mode in ('control','xyselect'):
				self.next()
				logging.info("Next Control Screen")
			elif self.mode=='select':
				self.click_listbox()

		elif t=='B':
			#if self.mode=='control':
			if self.mode in ('control','xyselect'):
				self.set_mode_select()
			elif self.mode=='select':
				self.click_listbox()


	def select(self, index=None):
		if index != None and index >= 0 and index < len(self.list_data) and len(self.list_data[index]) < 4:
			if self.index > index:
				index = max(0, index - 1)
			else:
				index = min(len(self.list_data), index + 1)

		super().select(index)
		if self.mode=='select':
			self.set_controller_screen()
			self.set_selector_screen()
		

	@Slot(None)
	# This is to make sure that the visual controller are synced between custom and basic views
	def refresh_values(self):
		for gctrl in self.zgui_custom_controllers:
			gctrl.ctrl_value = gctrl.zctrl.value

	def zyncoder_read(self, zcnums=None):
		#Read Controller
		if self.controllers_lock and self.mode=='control' and self.zcontrollers:
			if self._active_custom_controller:
				self._active_custom_controller.read_zyncoder()
			elif self.__custom_control_page == "":
				for i, zctrl in enumerate(self.zcontrollers):
					#print('Read Control ' + str(self.zgui_controllers[i].title))

					if not zcnums or i in zcnums:
						if i >= len(self.zgui_controllers):
							continue
						res=self.zgui_controllers[i].read_zyncoder()

						if res and self.zyngui.midi_learn_mode:
							logging.debug("MIDI-learn ZController {}".format(i))
							self.zyngui.midi_learn_mode = False
							self.midi_learn(i)

						if res and self.xyselect_mode:
							self.zyncoder_read_xyselect(zctrl, i)
			else:
				for ctrl in self.zgui_custom_controllers_map.values():
					if ctrl.index <= 3:
						ctrl.read_zyncoder()

		elif self.mode=='select':
			super().zyncoder_read()


	def zyncoder_read_xyselect(self, zctrl, i):
		#Detect a serie of changes in the same controller
		if zctrl==self.xyselect_zread_last_zctrl:
			self.xyselect_zread_counter+=1
		else:
			self.xyselect_zread_last_zctrl=zctrl
			self.xyselect_zread_counter=0

		#If the change counter is major of ...
		if self.xyselect_zread_counter>5:
			if self.xyselect_zread_axis=='X' and self.set_xyselect_x(i):
				self.xyselect_zread_axis='Y'
				self.xyselect_zread_counter=0
			elif self.xyselect_zread_axis=='Y' and self.set_xyselect_y(i):
				self.xyselect_zread_axis='X'
				self.xyselect_zread_counter=0


	def get_zgui_controller(self, zctrl):
		for zgui_controller in self.zgui_controllers:
			if zgui_controller.zctrl==zctrl:
				return zgui_controller


	def get_zgui_controller_by_index(self, i):
		return self.zgui_controllers[i]


	def refresh_midi_bind(self):
		for zgui_controller in self.zgui_controllers:
			zgui_controller.set_midi_bind()

	def refresh_loading(self):
		return

	def plot_zctrls(self):
		if self.mode=='select':
			super().plot_zctrls()
		if self.zgui_controllers:
			for zgui_ctrl in self.zgui_controllers:
				zgui_ctrl.plot_value()


	def set_controller_value(self, zctrl, val=None):
		if val is not None:
			zctrl.set_value(val)
		for i,zgui_controller in enumerate(self.zgui_controllers):
			if zgui_controller.zctrl==zctrl:
				if i==zynthian_gui_config.select_ctrl and self.mode=='select':
					zgui_controller.zctrl_sync(False)
				else:
					zgui_controller.zctrl_sync(True)


	def set_controller_value_by_index(self, i, val=None):
		zgui_controller=self.zgui_controllers[i]
		if val is not None:
			zgui_controller.zctrl.set_value(val)
		if i==zynthian_gui_config.select_ctrl and self.mode=='select':
			zgui_controller.zctrl_sync(False)
		else:
			zgui_controller.zctrl_sync(True)


	def get_controller_value(self, zctrl):
		for i in self.zgui_controllers:
			if self.zgui_controllers[i].zctrl==zctrl:
				return zctrl.get_value()

	def get_controller_value_by_index(self, i):
		return self.zgui_controllers[i].zctrl.get_value()


	def midi_learn(self, i):
		if self.mode=='control':
			self.zgui_controllers[i].zctrl.init_midi_learn()


	def midi_unlearn(self, i):
		if self.mode=='control':
			self.zgui_controllers[i].zctrl.midi_unlearn()


	def cb_listbox_push(self,event):
		if self.xyselect_mode:
			logging.debug("XY-Controller Mode ...")
			self.zyngui.show_control_xy(self.x_zctrl, self.y_zctrl)
		else:
			super().cb_listbox_push(event)


	# TODO: remove?
	def cb_listbox_release(self, event):
		if self.xyselect_mode:
			return
		if self.mode=='select':
			super().cb_listbox_release(event)
		elif self.listbox_push_ts:
			dts=(datetime.now()-self.listbox_push_ts).total_seconds()
			#logging.debug("LISTBOX RELEASE => %s" % dts)
			if dts<0.3:
				self.zyngui.start_loading()
				self.click_listbox()
				self.zyngui.stop_loading()


	# TODO: remove?
	def cb_listbox_motion(self, event):
		if self.xyselect_mode:
			return
		if self.mode=='select':
			super().cb_listbox_motion(event)
		elif self.listbox_push_ts:
			dts=(datetime.now()-self.listbox_push_ts).total_seconds()
			if dts>0.1:
				index=self.get_cursel()
				if index!=self.index:
					#logging.debug("LISTBOX MOTION => %d" % self.index)
					self.zyngui.start_loading()
					self.select_listbox(self.get_cursel())
					self.zyngui.stop_loading()
					sleep(0.04)


	# TODO: remove?
	def cb_listbox_wheel(self, event):
		index = self.index
		if (event.num == 5 or event.delta == -120) and self.index>0:
			index -= 1
		if (event.num == 4 or event.delta == 120) and self.index < (len(self.list_data)-1):
			index += 1
		if index!=self.index:
			self.zyngui.start_loading()
			self.select_listbox(index)
			self.zyngui.stop_loading()


	def set_select_path(self):
		if self.zyngui.curlayer:
			if self.mode=='control' and self.zyngui.midi_learn_mode:
				self.select_path = (self.zyngui.curlayer.get_basepath() + "/CTRL MIDI-Learn")
			else:
				self.select_path = (self.zyngui.curlayer.get_presetpath())
			self.select_path_element = "EDIT"
		super().set_select_path()



	controllers_changed = Signal()
	controllers_count_changed = Signal()
	custom_control_page_changed = Signal()
	default_custom_control_page_changed = Signal()
	single_effect_engine_changed = Signal()
	custom_controller_mode_changed = Signal()
	active_custom_controller_changed = Signal()

	controllers_count = Property(int, get_controllers_count, notify = controllers_count_changed)
	custom_control_page = Property(str, get_custom_control_page, set_custom_control_page, notify = custom_control_page_changed)
	default_custom_control_page = Property(str, get_default_custom_control_page, notify = default_custom_control_page_changed)
	control_pages_model = Property(QObject, get_control_pages_model, constant = True)
	single_effect_engine = Property(str, get_single_effect_engine, set_single_effect_engine, notify = single_effect_engine_changed)
	active_custom_controller = Property(QObject, get_active_custom_controller, set_active_custom_controller, notify = active_custom_controller_changed)

#------------------------------------------------------------------------------
