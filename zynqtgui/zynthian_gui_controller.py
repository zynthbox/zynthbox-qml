#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian GUI Controller Class
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
import math
import liblo
import ctypes
import tkinter
import logging
from time import sleep
from string import Template
from datetime import datetime

# Zynthian specific modules
from zyncoder import *
from zyngine import zynthian_controller
from . import zynthian_gui_config

# Qt modules
from PySide2.QtCore import Qt, QObject, Slot, Signal, Property

import traceback

#------------------------------------------------------------------------------
# Controller GUI Class
#------------------------------------------------------------------------------

class zynthian_gui_controller(QObject):

	def __init__(self, indx, zctrl, parent=None):
		super(zynthian_gui_controller, self).__init__(parent)
		self.zyngui = zynthian_gui_config.zyngui
		self.zctrl=None
		self.n_values=127
		self.ctrl_max_value=127
		self.inverted=False
		self.selmode = False
		self.logarithmic = False
		self.step=1
		self.mult=1
		self.val0=0
		self.ctrl_title=''
		self.ctrl_value=0
		self.scale_plot=1
		self.scale_value=1
		self.ctrl_value_plot=0
		self.ctrl_value_print=None
		self.__visible = True
		self.custom_encoder_speed = 0


		self.ctrl_midi_bind=None

		self.index=indx
		self.old_index = indx
		#self.row=zynthian_gui_config.ctrl_pos[indx][0]
		#self.col=zynthian_gui_config.ctrl_pos[indx][1]
		#self.sticky=zynthian_gui_config.ctrl_pos[indx][2]

		# Setup Controller and Zyncoder
		self.config(zctrl)
		self.calculate_plot_values()


	def show(self):
		#logging.error("SHOWING")
		#self.calculate_plot_values()
		self.__visible = True
		self.visible_changed.emit()

	def hide(self):
		self.__visible = False
		self.visible_changed.emit()

	def get_visible(self):
		return self.__visible

	def set_visible(self, visible):
		if self.__visible == visible:
			return
		self.__visible = visible
		self.visible_changed.emit()

	def get_index(self):
		return self.index

	def set_index(self, idx: int):
		if self.index == idx:
			return
		self.index = idx
		self.setup_zyncoder()
		self.index_changed.emit()

	def calculate_plot_values(self):
		# FIXME: probably what's needed would be an actual threading semaphore?
		self.zyngui.zynread_wait_flag = True

		if self.ctrl_value>self.ctrl_max_value:
			self.ctrl_value=self.ctrl_max_value

		elif self.ctrl_value<0:
			self.ctrl_value=0

		if self.zctrl.labels:
			valplot=None
			val=self.ctrl_value

			#DIRTY HACK => It should be improved!!
			#if self.zctrl.value_min<0:
			#	val=self.zctrl.value_min+self.ctrl_value

			try:
				if self.zctrl.ticks:
					if self.selmode:
						i = int(val)
						valplot=self.scale_plot*val
						val=self.zctrl.ticks[i]
					elif self.inverted:
						for i in reversed(range(self.n_values)):
							if val<=self.zctrl.ticks[i]:
								break
						valplot=self.scale_plot*(self.ctrl_max_value-self.zctrl.ticks[i])
						val=self.zctrl.ticks[i]
					else:
						for i in range(self.n_values-1):
							if val<self.zctrl.ticks[i+1]:
								valplot=self.scale_plot*(self.zctrl.ticks[i]-self.zctrl.ticks[0])
								break
						if valplot==None:
							i+=1
							valplot=self.scale_plot*(self.zctrl.ticks[i]-self.zctrl.ticks[0])
						val=self.zctrl.ticks[i]
				else:
					i=int(self.n_values*val/(self.ctrl_max_value+self.step))
					#logging.debug("i => %s=int(%s*%s/(%s+%s))" % (i,self.n_values,val,self.ctrl_max_value,self.step))
					valplot=self.scale_plot*i

				self.ctrl_value_plot=valplot
				self.ctrl_value_print=self.zctrl.labels[i]
				#self.zctrl.set_value(self.ctrl_value)
				self.zctrl.set_value(val)

			except Exception as err:
				logging.error("Calc Error => %s" % (err))
				self.ctrl_value_plot=self.ctrl_value
				self.ctrl_value_print="ERR"

		else:
			self.ctrl_value_plot=self.ctrl_value
			if self.zctrl.midi_cc==0:
				val = self.val0+self.ctrl_value
				self.zctrl.set_value(val)
				self.ctrl_value_print = str(val)
			else:
				if self.logarithmic:
					val = self.zctrl.value_min*pow(self.scale_value, self.ctrl_value/self.n_values)
				else:
					val = self.zctrl.value_min+self.ctrl_value*self.scale_value

				self.zctrl.set_value(val)
				if self.format_print and val<1000 and val>-1000:
					self.ctrl_value_print = self.format_print.format(val)
				else:
					self.ctrl_value_print = str(int(val))

		self.value_print_changed.emit()

		self.zyngui.zynread_wait_flag = False
		#print("VALUE: %s" % self.ctrl_value)
		#print("VALUE PLOT: %s" % self.ctrl_value_plot)
		#print("VALUE PRINT: %s" % self.ctrl_value_print)



	def set_midi_bind(self):
		if self.zctrl.midi_cc==0:
			#self.erase_midi_bind()
			self.ctrl_midi_bind = "/{}".format(self.zctrl.value_range)
		elif self.zyngui.midi_learn_mode:
			self.ctrl_midi_bind = "??"
		elif self.zyngui.midi_learn_zctrl and self.zctrl==self.zyngui.midi_learn_zctrl:
			self.ctrl_midi_bind = "??"
		elif self.zctrl.midi_learn_cc and self.zctrl.midi_learn_cc>0:
			midi_cc = self.zctrl.midi_learn_cc
			if not self.zyngui.is_single_active_channel():
				midi_cc = "{}#{}".format(self.zctrl.midi_learn_chan+1,midi_cc)
			self.ctrl_midi_bind = midi_cc
		elif self.zctrl.midi_cc and self.zctrl.midi_cc>0:
			#midi_cc = self.zctrl.midi_cc
			swap_info= zyncoder.lib_zyncoder.get_midi_filter_cc_swap(self.zctrl.midi_chan, self.zctrl.midi_cc)
			midi_chan = swap_info >> 8
			midi_cc = swap_info & 0xFF
			if not self.zyngui.is_single_active_channel():
				midi_cc = "{}#{}".format(midi_chan+1,midi_cc)
			self.ctrl_midi_bind = midi_cc
		self.midi_bind_changed.emit()

	def get_midi_bind(self):
		return self.ctrl_midi_bind;

	def set_title(self, title):
		self.ctrl_title = str(title)
		self.title_changed.emit()

	def get_title(self):
		return self.ctrl_title

	def write_value(self, v):
		self.set_value(v, True)
		self.calculate_plot_values()

	def get_value(self):
		return self.ctrl_value

	def get_value_print(self):
		return self.ctrl_value_print

	def get_max_value(self):
		return self.ctrl_max_value

	def get_value0(self):
		return self.val0

	def get_value_type(self):
		if self.zctrl.is_toggle:
			return "bool"
		elif self.zctrl.is_integer:
			return "int"
		elif self.zctrl.is_logarithmic:
			return "logarithmic"
		else:
			return "float"

	def get_step_size(self):
		return self.step


	def config(self, zctrl):
		#logging.debug("CONFIG CONTROLLER %s => %s" % (self.index,zctrl.name))
		try:
			self.zctrl=zctrl
			self.step=1
			self.mult=1
			self.val0=0
			self.ctrl_value=None
			self.n_values=127
			self.inverted=False
			self.selmode = False
			self.logarithmic = zctrl.is_logarithmic
			self.scale_value=1
			self.format_print=None
			self.set_title(zctrl.short_name)
			self.set_midi_bind()
		except:
			pass

		logging.debug("ZCTRL '%s': %s (%s -> %s), %s, %s" % (zctrl.short_name,zctrl.value,zctrl.value_min,zctrl.value_max,zctrl.labels,zctrl.ticks))

		#List of values (value selector)
		if isinstance(zctrl.labels,list):
			self.n_values=len(zctrl.labels)
			if isinstance(zctrl.ticks,list):
				if zctrl.ticks[0]>zctrl.ticks[-1]:
					self.inverted=True
				if (isinstance(zctrl.midi_cc, int) and zctrl.midi_cc>0):
					self.ctrl_max_value=127
					#self.step=max(1,int(16/self.n_values))
					self.step = 1
					val=zctrl.value-zctrl.value_min
				else:
					self.selmode = True
					self.ctrl_max_value = self.n_values-1
					#self.mult = max(4,int(32/self.n_values))
					self.mult = 4
					val=zctrl.get_value2index()

					#if zctrl.value_range>32:
						#self.step = max(4,int(zctrl.value_range/(self.n_values*4)))
						#self.ctrl_max_value = zctrl.value_range + self.step*4
					#else:
					#	self.mult=max(4,int(32/self.n_values))
					#	self.ctrl_max_value = zctrl.value_range + 1
			else:
				self.ctrl_max_value=127;
				#self.step=max(1,int(16/self.n_values))
				self.step = 1
				val=zctrl.value-zctrl.value_min

		#Numeric value
		else:
			#"List Selection Controller" => step 1 element by rotary tick
			if zctrl.midi_cc==0:
				self.ctrl_max_value=self.n_values=zctrl.value_max
				self.val0=1
				val=zctrl.value

				#If many values => use adaptative step size based on rotary speed
				if self.n_values>=32:
					self.step=0
				else:
					self.mult = 4

			else:
				if zctrl.is_integer:
					#Integer < 127
					if zctrl.value_range<=127:
						self.ctrl_max_value=self.n_values=zctrl.value_range
						val=zctrl.value-zctrl.value_min
						#If many values => use adaptative step size based on rotary speed
						if self.n_values>32:
							self.step=0
							self.mult = 1
						else:
							self.mult = 4
					#Integer > 127
					else:
						#Not MIDI controller
						if zctrl.midi_cc is None:
							self.ctrl_max_value=self.n_values=zctrl.value_range
							self.scale_value=1
							val=(zctrl.value-zctrl.value_min)
						#MIDI controller
						else:
							self.ctrl_max_value=self.n_values=127
							self.scale_value=r/self.ctrl_max_value
							val=(zctrl.value-zctrl.value_min)/self.scale_value
				#Float
				else:
					self.ctrl_max_value=self.n_values=200
					self.format_print="{0:.3g}"
					if self.logarithmic:
						self.scale_value = self.zctrl.value_max/self.zctrl.value_min
						self.log_scale_value = math.log(self.scale_value)
						val = self.n_values*math.log(zctrl.value/zctrl.value_min)/self.log_scale_value
					else:
						self.scale_value = zctrl.value_range/self.ctrl_max_value
						val = (zctrl.value-zctrl.value_min)/self.scale_value

				#Use adaptative step size based on rotary speed
				self.step=0

		#Calculate scale parameter for plotting
		if self.selmode:
			self.scale_plot=self.ctrl_max_value/(self.n_values-1)
		elif zctrl.ticks:
			self.scale_plot=self.ctrl_max_value/zctrl.value_range
		elif self.n_values>1:
			self.scale_plot=self.ctrl_max_value/(self.n_values-1)
		else:
			self.scale_plot=self.ctrl_max_value

		self.set_value(val)
		self.setup_zyncoder()
		self.max_value_changed.emit()
		self.value0_changed.emit()
		self.value_type_changed.emit()
		self.step_size_changed.emit()

		#logging.debug("labels: "+str(zctrl.labels))
		#logging.debug("ticks: "+str(zctrl.ticks))
		#logging.debug("value_min: "+str(zctrl.value_min))
		#logging.debug("value_max: "+str(zctrl.value_max))
		#logging.debug("range: "+str(zctrl.value_range))
		#logging.debug("inverted: "+str(self.inverted))
		#logging.debug("n_values: "+str(self.n_values))
		#logging.debug("max_value: "+str(self.ctrl_max_value))
		#logging.debug("step: "+str(self.step))
		#logging.debug("mult: "+str(self.mult))
		#logging.debug("scale_plot: "+str(self.scale_plot))
		#logging.debug("val0: "+str(self.val0))
		#logging.debug("value: "+str(self.ctrl_value))


	def zctrl_sync(self, set_zyncoder=True):
		#List of values (value selector)
		if self.selmode:
			val=self.zctrl.get_value2index()
		if self.zctrl.labels:
			#logging.debug("ZCTRL SYNC LABEL => {}".format(self.zctrl.get_value2label()))
			val=self.zctrl.get_label2value(self.zctrl.get_value2label())
		#Numeric value
		else:
			#"List Selection Controller" => step 1 element by rotary tick
			if self.zctrl.midi_cc==0:
				val=self.zctrl.value
			elif self.logarithmic:
				val = self.n_values*math.log(self.zctrl.value/self.zctrl.value_min)/self.log_scale_value
			else:
				val = (self.zctrl.value-self.zctrl.value_min)/self.scale_value
		#Set value & Update zyncoder
		self.set_value(val, set_zyncoder, False)
		#logging.debug("ZCTRL SYNC {} => {}".format(self.ctrl_title, val))


	#def setup_zyncoder(self):
		#self.init_value=None
		#try:
			#if isinstance(self.zctrl.osc_path,str):
				##logging.debug("Setup zyncoder %d => %s" % (self.index,self.zctrl.osc_path))
				#midi_cc=None
				#zyn_osc_path="{}:{}".format(self.zctrl.osc_port,self.zctrl.osc_path)
				#osc_path_char=ctypes.c_char_p(zyn_osc_path.encode('UTF-8'))
				##if zctrl.engine.osc_target:
				##	liblo.send(zctrl.engine.osc_target, self.zctrl.osc_path)
			#elif isinstance(self.zctrl.graph_path,str):
				##logging.debug("Setup zyncoder %d => %s" % (self.index,self.zctrl.graph_path))
				#midi_cc=None
				#osc_path_char=None
			#else:
				##logging.debug("Setup zyncoder %d => %s" % (self.index,self.zctrl.midi_cc))
				#midi_cc=self.zctrl.midi_cc
				#osc_path_char=None
			#if zyncoder.lib_zyncoder:
				#if self.inverted:
					#pin_a=zynthian_gui_config.zyncoder_pin_b[self.index]
					#pin_b=zynthian_gui_config.zyncoder_pin_a[self.index]
				#else:
					#pin_a=zynthian_gui_config.zyncoder_pin_a[self.index]
					#pin_b=zynthian_gui_config.zyncoder_pin_b[self.index]
				#zyncoder.lib_zyncoder.setup_zyncoder(self.index,pin_a,pin_b,self.zctrl.midi_chan,midi_cc,osc_path_char,int(self.mult*self.ctrl_value),int(self.mult*(self.ctrl_max_value-self.val0)),self.step)
		#except Exception as err:
			#logging.error("%s" % err)

	def setup_zyncoder(self):
		if not self.__visible:
			return
		self.init_value=None
		try:
			if self.inverted:
				zyncoder.lib_zyncoder.setup_rangescale_zynpot(self.index, int(self.mult*(self.max_value-self.val0)), 0, int(self.mult*self.value), self.step)
			else:
				#self.step=4
				if self.custom_encoder_speed > 0:
					self.step = self.custom_encoder_speed
				#logging.error("SETTING UP RANGE SCALE {} {} max {} value {} step {}".format(self.index, self.ctrl_title, int(self.mult*(self.max_value-self.val0)), int(self.mult*self.value), self.step))
				zyncoder.lib_zyncoder.setup_rangescale_zynpot(self.index, 0, int(self.mult*(self.max_value-self.val0)), int(self.mult*self.value), self.step)

			if isinstance(self.zctrl.osc_path,str):
				#logging.debug("Setup zyncoder %d => %s" % (self.index,self.zctrl.osc_path))
				midi_cc = None
				#zyn_osc_path="{}:{}".format(self.zctrl.osc_port,self.zctrl.osc_path)
				#osc_path_char=ctypes.c_char_p(zyn_osc_path.encode('UTF-8'))
				osc_path_char = None
				##if zctrl.engine.osc_target:
				##	liblo.send(zctrl.engine.osc_target, self.zctrl.osc_path)
			elif isinstance(self.zctrl.graph_path,str):
				#logging.debug("Setup zyncoder %d => %s" % (self.index,self.zctrl.graph_path))
				midi_cc = None
				osc_path_char=None
			else:
				#logging.debug("Setup zyncoder %d => %s" % (self.index,self.zctrl.midi_cc))
				midi_cc = self.zctrl.midi_cc
				osc_path_char = None

			zyncoder.lib_zyncoder.setup_midi_zynpot(self.index, self.zctrl.midi_chan, midi_cc)
			zyncoder.lib_zyncoder.setup_osc_zynpot(self.index, osc_path_char)

		except Exception as err:
			logging.error("%s" % err)

	def set_value(self, v, set_zynpot=False, send_zynpot=True):
		if v>self.ctrl_max_value:
			v=self.ctrl_max_value
		elif v<0:
			v=0
		if self.ctrl_value is None or self.ctrl_value!=v or True:
			self.ctrl_value=v
			#logging.error("CONTROL %d VALUE => %s" % (self.index,self.ctrl_value))
			if self.__visible:
				if set_zynpot:
					if self.mult>1: v = self.mult*v
					zyncoder.lib_zyncoder.set_value_zynpot(self.index,int(v),int(send_zynpot))
					#logging.error("set_value_zyncoder {} {} ({}, {}) => {}".format(self, self.index, self.zctrl.symbol,self.zctrl.midi_cc,v))
			self.calculate_plot_values()
			self.value_changed.emit()
			return True


	def set_init_value(self, v):
		if self.init_value is None:
			self.init_value=v
			self.set_value(v,True)
			logging.debug("INIT VALUE %s => %s" % (self.index,v))



	def read_zyncoder(self):
		#if self.canvas_push_ts:
		#	return
		is_external_app = hasattr(zynthian_gui_config, 'top') and zynthian_gui_config.top.isActive() == False
		if not self.__visible or is_external_app:
			return
		if self.zctrl and zyncoder.lib_zyncoder.get_value_flag_zynpot(self.index):
			val=zyncoder.lib_zyncoder.get_value_zynpot(self.index)
			#logging.debug("ZYNCODER %d (%s), RAW VALUE => %s" % (self.index,self.title,val))
			if self.mult>1:
				val = int((val+1)/self.mult)
			return self.set_value(val)

		else:
			return False


	def cb_canvas_wheel(self,event):
		if event.num == 5 or event.delta == -120:
			self.set_value(self.ctrl_value - 1, True)
		if event.num == 4 or event.delta == 120:
			self.set_value(self.ctrl_value + 1, True)


	index_changed = Signal()
	title_changed = Signal()
	midi_bind_changed = Signal()
	value_changed = Signal()
	value_print_changed = Signal()
	max_value_changed = Signal()
	value0_changed = Signal()
	value_type_changed = Signal()
	step_size_changed = Signal()
	visible_changed = Signal()

	encoder_index = Property(int, get_index, set_index, notify = index_changed)
	title = Property(str, get_title, notify = title_changed)
	visible = Property(bool, get_visible, set_visible, notify = visible_changed)
	midi_bind = Property(str, get_midi_bind, notify = midi_bind_changed)
	value = Property(float, get_value, write_value, notify = value_changed)
	value_print = Property(str, get_value_print, notify = value_print_changed)
	value0 = Property(float, get_value0, notify = value0_changed)
	max_value = Property(float, get_max_value, notify = max_value_changed)
	value_type = Property(str, get_value_type, notify = value_type_changed)
	step_size= Property(float, get_step_size, notify = step_size_changed)

#------------------------------------------------------------------------------
