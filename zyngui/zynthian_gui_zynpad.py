#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian GUI Step-Sequencer Class
# 
# Copyright (C) 2015-2020 Fernando Moyano <jofemodo@zynthian.org>
# Copyright (C) 2015-2020 Brian Walton <brian@riban.co.uk>
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

# Define encoder use: 0=Layer, 1=Back, 2=Snapshot, 3=Select
ENC_LAYER           = 0
ENC_BACK            = 1
ENC_SNAPSHOT        = 2
ENC_SELECT          = 3

import inspect
import tkinter
import logging
import tkinter.font as tkFont
from math import sqrt
from PIL import Image, ImageTk
from time import sleep

# Zynthian specific modules
from . import zynthian_gui_config
from . import zynthian_gui_stepsequencer
from zyncoder import *

SELECT_BORDER	= zynthian_gui_config.color_on


#------------------------------------------------------------------------------
# Zynthian Step-Sequencer Sequence / Pad Trigger GUI Class
#------------------------------------------------------------------------------

# Class implements step sequencer
class zynthian_gui_zynpad():

	# Function to initialise class
	def __init__(self, parent):
		self.parent = parent

		self.zyngui = zynthian_gui_config.zyngui # Zynthian GUI configuration

		self.columns = 4
		self.rows = 4
		self.selectedPad = 0 # Index of selected pad
		self.selectedCol = 0
		self.selectedRow = 0
		self.song = 1001 # Index of song used to configure pads

		self.playModes = ['Disabled', 'Oneshot', 'Loop', 'Oneshot all', 'Loop all', 'Oneshot sync', 'Loop sync']
		self.padColourDisabled = 'grey'
		self.padColourStarting = 'orange'
		self.padColourPlaying = 'green'
		self.padColourStopping = 'red'
		self.padColourStoppedEven = 'purple'
		self.padColourStoppedOdd = 'blue'

		# Geometry vars
		self.width=zynthian_gui_config.display_width
		self.height=zynthian_gui_config.body_height
		self.selectThickness = 4#1 + int(self.width / 500) # Scale thickness of select border based on screen
		self.colWidth = self.width / self.columns
		self.rowHeight = self.height / self.rows

		# Main Frame
		self.main_frame = tkinter.Frame(self.parent.main_frame)
		self.main_frame.grid(row=1, column=0, sticky="nsew")

		# Pad grid
		self.gridCanvas = tkinter.Canvas(self.main_frame,
			width=self.width, 
			height=self.height,
			bd=0,
			highlightthickness=0,
			relief='flat',
			bg = zynthian_gui_config.color_bg)
		self.gridCanvas.grid(row=0, column=0)

		# Icons
		self.icon = [tkinter.PhotoImage(),tkinter.PhotoImage(),tkinter.PhotoImage(),tkinter.PhotoImage(),tkinter.PhotoImage(),tkinter.PhotoImage(),tkinter.PhotoImage()]

		# Selection highlight
		self.selection = self.gridCanvas.create_rectangle(0, 0, self.colWidth, self.rowHeight, fill="", outline=SELECT_BORDER, width=self.selectThickness, tags="selection")

	#Function to set values of encoders
	#	note: Call after other routine uses one or more encoders
	def setupEncoders(self):
		self.parent.registerZyncoder(ENC_BACK, self)
		self.parent.registerZyncoder(ENC_SELECT, self)
		self.parent.registerSwitch(ENC_SELECT, self, 'S')

	# Function to show GUI
	#   params: Misc parameters
	def show(self, params):
		self.main_frame.tkraise()
		self.setupEncoders()
		self.selectSong()

	# Function to populate menu
	def populateMenu(self):
		self.parent.addMenu({'Pad mode':{'method':self.parent.showParamEditor, 'params':{'min':0, 'max':len(self.playModes)-1, 'getValue':self.getSelectedPadMode, 'onChange':self.onMenuChange}}})
		self.parent.addMenu({'Trigger channel':{'method':self.parent.showParamEditor, 'params':{'min':1, 'max':16, 'getValue':self.getTriggerChannel, 'onChange':self.onMenuChange}}})
		self.parent.addMenu({'Tally channel':{'method':self.parent.showParamEditor, 'params':{'min':0, 'max':15, 'getValue':self.getTallyChannel, 'onChange':self.onMenuChange}}})
		self.parent.addMenu({'Tempo':{'method':self.parent.showParamEditor, 'params':{'min':0, 'max':999, 'getValue':self.parent.libseq.getTempo, 'onChange':self.onMenuChange}}})

	# Function to hide GUI
	def hide(self):
		self.parent.unregisterZyncoder(ENC_BACK)
		self.parent.unregisterZyncoder(ENC_SELECT)
		self.parent.unregisterSwitch(ENC_SELECT)

	# Function to get the MIDI trigger channel
	#   returns: MIDI channel
	def getTriggerChannel(self):
		return self.parent.libseq.getTriggerChannel() + 1

	# Function to get the MIDI tally channel
	#   returns: MIDI channel to send tallies (e.g. to light controller pads)
	def getTallyChannel(self):
		channel = self.parent.libseq.getTallyChannel()
		if channel > 15:
			return 0
		else:
			return channel + 1

	# Function to get the mode of the currently selected pad
	#   returns: Mode of selected pad
	def getSelectedPadMode(self):
		return self.parent.libseq.getPlayMode(self.getSequence(self.selectedPad))

	# Function to get pad sequence
	#   pad: Pad index
	#   returns: Index of sequence associated with pad
	def getSequence(self, pad):
		return self.parent.libseq.getSequence(self.song, pad)

	# Function to handle menu editor change
	#   params: Menu item's parameters
	#   returns: String to populate menu editor label
	#   note: params is a dictionary with required fields: min, max, value
	def onMenuChange(self, params):
		menuItem = self.parent.paramEditorItem
		value = params['value']
		if value < params['min']:
			value = params['min']
		if value > params['max']:
			value = params['max']
		if menuItem == 'Tempo':
			#TODO: Consider how this works with tempo map (song master channel)
			self.parent.libseq.transportSetTempo(value)
		prefix = "%s%d" % (chr(int((self.selectedPad) / self.rows) + 65), (self.selectedPad) % self.rows + 1)
		if menuItem == 'Pad mode':
			self.parent.libseq.setPlayMode(self.getSequence(self.selectedPad), value)
			self.drawPad(self.selectedPad)
			return "%s: %s" % (prefix, self.playModes[value])
		elif menuItem == 'Trigger channel':
			self.parent.libseq.setTriggerChannel(value - 1)
			return "%s: Channel: %d" % (prefix, value)
		elif menuItem == 'Tally channel':
			if value == 0:
				self.setPadTallies(255)
				return "None"
			else:
				self.setPadTallies(value - 1)
			return "Channel: %d" % (value)
		return "%s: %d" % (menuItem, value)

	# Function to configure pad tallies
	#	channel: MIDI channel to send tallies (255 to disable tallies)
	def setPadTallies(self, channel):
		#TODO: Currently only handles Akai APC
		for track in range(self.parent.libseq.getTracks(self.song)):
			sequence = self.parent.libseq.getSequence(self.song, track)
			if sequence:
				note = self.parent.libseq.getTriggerNote(sequence)
				self.parent.libseq.setTallyChannel(sequence, channel)
				if channel < 16:
					if note < 128 and self.parent.libseq.getSequenceLength(sequence):
						self.parent.libseq.playNote(note, 3, channel, 0)
					else:
						self.parent.libseq.playNote(note, 0, channel, 0)

	# Function to load song
	def selectSong(self):
		#TODO: Should we stop song and recue?
		song = self.parent.libseq.getSong()
		self.song = song + 1000
#		self.parent.libseq.solo(self.song, 0, False)
		tracks = self.parent.libseq.getTracks(self.song)
		if tracks < 1:
			self.columns = 1
		else:
			self.columns = int(sqrt(int(tracks - 1))+1)
		self.rows = self.columns
		self.colWidth = self.width / self.columns
		self.rowHeight = self.height / self.rows
		imgWidth = int(self.width / self.columns / 4)
		iconsize = (imgWidth, imgWidth)
		img = (Image.open("/zynthian/zynthian-ui/icons/endnoline.png").resize(iconsize))
		self.icon[1] = ImageTk.PhotoImage(img)
		img = (Image.open("/zynthian/zynthian-ui/icons/loop.png").resize(iconsize))
		self.icon[2] = ImageTk.PhotoImage(img)
		img = (Image.open("/zynthian/zynthian-ui/icons/end.png").resize(iconsize))
		self.icon[3] = ImageTk.PhotoImage(img)
		img = (Image.open("/zynthian/zynthian-ui/icons/loopstop.png").resize(iconsize))
		self.icon[4] = ImageTk.PhotoImage(img)
		img = (Image.open("/zynthian/zynthian-ui/icons/end.png").resize(iconsize))
		self.icon[5] = ImageTk.PhotoImage(img)
		img = (Image.open("/zynthian/zynthian-ui/icons/loopstop.png").resize(iconsize))
		self.icon[6] = ImageTk.PhotoImage(img)
		self.drawGrid(True)
		self.parent.setTitle("ZynPad (%d)"%(song))

	# Function to draw grid
	def drawGrid(self, clear = False):
		if clear:
			self.gridCanvas.delete(tkinter.ALL)
			self.selection = self.gridCanvas.create_rectangle(0, 0, self.colWidth, self.rowHeight, fill="", outline=SELECT_BORDER, width=self.selectThickness, tags="selection")
		for col in range(self.columns):
			self.drawColumn(col, clear)

	# Function to draw grid column
	#   col: Column index
	def drawColumn(self, col, clear = False):
		for row in range(self.rows):
			self.drawCell(col, row, clear)

	# Function to draw grid cell (pad)
	#   col: Column index
	#   row: Row index
	def drawCell(self, col, row, clear = False):
		pad = row + col * self.rows
		sequence = self.getSequence(pad)
		group = self.parent.libseq.getGroup(sequence)
		if col < 0 or col >= self.columns or row < 0 or row >= self.rows:
			return
		padX = col * self.width / self.columns
		padY = row * self.height / self.rows
		padWidth = self.width / self.columns - 2 #TODO: Calculate pad size once
		padHeight = self.height / self.rows - 2
		cell = self.gridCanvas.find_withtag("pad:%d"%(pad))
		if cell:
			mode = self.parent.libseq.getPlayMode(sequence)
			if self.parent.libseq.getSequenceLength(sequence) == 0:
				mode = 0
			self.gridCanvas.itemconfig("mode:%d"%pad, image=self.icon[mode], state='normal')
			if not sequence or self.parent.libseq.getPlayMode(sequence) == zynthian_gui_stepsequencer.SEQ_DISABLED:
				fill = self.padColourDisabled
				self.gridCanvas.itemconfig("mode:%d"%pad, state='hidden')
			elif self.parent.libseq.getPlayState(sequence) == zynthian_gui_stepsequencer.SEQ_STOPPED:
				if group % 2:
					fill = self.padColourStoppedOdd
				else:
					fill = self.padColourStoppedEven
			elif self.parent.libseq.getPlayState(sequence) == zynthian_gui_stepsequencer.SEQ_STARTING:
				fill = self.padColourStarting
			elif self.parent.libseq.getPlayState(sequence) == zynthian_gui_stepsequencer.SEQ_STOPPING:
				fill = self.padColourStopping
			else:
				fill = self.padColourPlaying
			self.gridCanvas.itemconfig(cell, fill=fill)
			self.gridCanvas.coords(cell, padX, padY, padX + padWidth, padY + padHeight)
		else:
			cell = self.gridCanvas.create_rectangle(padX, padY, padX + padWidth, padY + padHeight,
				fill='grey', width=0, tags=("pad:%d"%(pad), "gridcell"))
			if pad >= self.parent.libseq.getTracks(self.song):
				return
			self.gridCanvas.create_text(padX + padWidth / 2, padY + padHeight / 2,
				font=tkFont.Font(family=zynthian_gui_config.font_topbar[0],
				size=int(padHeight * 0.3)),
				fill=zynthian_gui_config.color_panel_tx,
				tags="lbl_pad:%d"%(pad),
				text="%s%d" % (chr(65 + group), pad+1))
			self.gridCanvas.create_image(padX + padWidth - 1, padY + padHeight - 1, tags=("mode:%d"%(pad)), anchor="se")
			self.gridCanvas.tag_bind("pad:%d"%(pad), '<Button-1>', self.onPadPress)
			self.gridCanvas.tag_bind("lbl_pad:%d"%(pad), '<Button-1>', self.onPadPress)
			self.gridCanvas.tag_bind("mode:%d"%(pad), '<Button-1>', self.onPadPress)
			self.gridCanvas.tag_bind("pad:%d"%(pad), '<ButtonRelease-1>', self.onPadRelease)
			self.gridCanvas.tag_bind("lbl_pad:%d"%(pad), '<ButtonRelease-1>', self.onPadRelease)
			self.gridCanvas.tag_bind("mode:%d"%(pad), '<ButtonRelease-1>', self.onPadRelease)

	# Function to draw pad
	#   pad: Pad index
	def drawPad(self, pad):
		pads = self.rows * self.columns
		if pads < 1 or pad < 0 or pad >= pads:
			return 0
		col = int(pad / self.rows)
		row = pad % self.rows
		self.drawCell(col, row)
		if self.selectedPad == pad:
			self.gridCanvas.coords(self.selection, 1 + col * self.colWidth, 1 + row * self.rowHeight, (1 + col) * self.colWidth - self.selectThickness, (1 + row) * self.rowHeight - self.selectThickness)
			self.gridCanvas.tag_raise(self.selection)
			self.gridCanvas.itemconfig(self.selection, state="normal")

	# Function to handle pad press
	def onPadPress(self, event):
		if self.parent.lstMenu.winfo_viewable():
			self.parent.hideMenu()
			return
		tags = self.gridCanvas.gettags(self.gridCanvas.find_withtag(tkinter.CURRENT))
		pad = int(tags[0].split(':')[1])
		self.selectedPad = pad
		self.selectedCol = int((pad) / self.columns)
		self.selectedRow = (pad) % self.columns
		self.togglePad()
		
	# Function to toggle pad
	def togglePad(self):
		sequence = self.getSequence(self.selectedPad)
		if sequence == 0:
			return;
		self.parent.libseq.togglePlayState(sequence)

	# Function to handle pad release
	def onPadRelease(self, event):
		pass

	# Function called when new file loaded from disk
	def onLoad(self):
		pass

	# Function to refresh status
	def refresh_status(self):
		for pad in range(0, self.rows * self.columns):
			self.drawPad(pad)

	def refresh_loading(self):
		pass

	# Function to handle zyncoder value change
	#   encoder: Zyncoder index [0..4]
	#   value: Current value of zyncoder
	def onZyncoder(self, encoder, value):
		if encoder == ENC_SELECT:
			# SELECT encoder adjusts pad selection
			self.selectedCol += value
			if self.selectedCol < 0:
				self.selectedCol = 0
			if self.selectedCol >= self.columns:
				self.selectedCol = self.columns - 1
		elif encoder == ENC_BACK:
			# BACK encoder adjusts pad selection
			self.selectedRow += value
			if self.selectedRow < 0:
				self.selectedRow = 0
			if self.selectedRow >= self.rows:
				self.selectedRow = self.rows - 1
		self.selectedPad = self.selectedRow + self.selectedCol * self.rows

	# Function to handle switch press
	#	switch: Switch index [0=Layer, 1=Back, 2=Snapshot, 3=Select]
	#	type: Press type ["S"=Short, "B"=Bold, "L"=Long]
	#	returns True if action fully handled or False if parent action should be triggered
	def onSwitch(self, switch, type):
		if switch == ENC_SELECT:
			self.togglePad()
			return True
		return False

#------------------------------------------------------------------------------
