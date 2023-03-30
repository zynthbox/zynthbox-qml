#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian GUI Confirm Class
# 
# Copyright (C) 2018 Markus Heidt <markus@heidt-tech.com>
#                    Fernando Moyano <jofemodo@zynthian.org>
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
import tkinter
import logging

# Zynthian specific modules
from . import zynthian_gui_config

# Qt modules
from PySide2.QtCore import Qt, QObject, Slot, Signal, Property


#------------------------------------------------------------------------------
# Zynthian Info GUI Class
#------------------------------------------------------------------------------

# TODO: properties to read/write from QML
class zynthian_gui_confirm(QObject):

	def __init__(self, parent=None):
		super(zynthian_gui_confirm, self).__init__(parent)
		self.shown = False
		self.callback = None
		self.callback_params = None
		self.zynqtgui = zynthian_gui_config.zynqtgui

		self.prop_text = ''


	def hide(self):
		if self.shown:
			self.shown=False


	def show(self, text, callback=None, cb_params=None):
		self.prop_text = text
		self.callback = callback
		self.callback_params = cb_params
		if not self.shown:
			self.shown=True
		self.text_changed.emit()

	def get_text(self):
		return self.prop_text

	def zyncoder_read(self):
		pass


	def refresh_loading(self):
		pass


	def switch_select(self, t='S'):
		logging.info("callback %s" % self.callback_params)
		print("TRYING TO CALL CALLBACK")
		
		try:
			self.callback(self.callback_params)
		except:
			pass

		self.zynqtgui.close_modal()


	@Slot(None)
	def accept(self):
		self.switch_select() #FIXME need to call it directly otherwise calling it from another thread causes problems to Qt models
		#self.zynqtgui.zynswitch_defered('S',3)

	@Slot(None)
	def reject(self):
		self.zynqtgui.zynswitch_defered('S',1)


	text_changed = Signal()

	text = Property(str, get_text, notify = text_changed)

#-------------------------------------------------------------------------------
