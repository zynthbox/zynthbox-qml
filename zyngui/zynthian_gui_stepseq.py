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

import sys
import os
import tkinter
import logging
import tkinter.font as tkFont
import jack
import json
import threading
import copy
from zyncoder import *

# Zynthian specific modules
from . import zynthian_gui_config

#------------------------------------------------------------------------------
# Zynthian Step-Sequencer GUI Class
#------------------------------------------------------------------------------

# Local constants
MAX_PATTERNS		= 999
STEP_MENU_PATTERN	= 0
STEP_MENU_VELOCITY	= 1
STEP_MENU_STEPS		= 2
STEP_MENU_COPY		= 3
STEP_MENU_CLEAR		= 4
STEP_MENU_TRANSPOSE	= 5
STEP_MENU_MIDI		= 6
STEP_MENU_MIDI_START= 7
STEP_MENU_PLAYMODE	= 8
STEP_MENU_GRID		= 9
STEP_MENU_ROWS		= 10
SELECT_BORDER		= '#ff8717'
NOTE_ON_BORDER		= 'black'
PLAYHEAD_CURSOR		= '#cc701b'
CANVAS_BACKGROUND	= '#dddddd'
SELECT_THICKNESS	= 3
# Define encoder use: 0=Layer, 1=Back, 2=Snapshot, 3=Select
ENC_LAYER			= 0
ENC_BACK			= 1
ENC_SNAPSHOT		= 2
ENC_SELECT			= 3
ENC_MENU			= ENC_LAYER
ENC_NOTE			= ENC_SNAPSHOT
ENC_STEP			= ENC_SELECT

# Class implements step sequencer
class zynthian_gui_stepseq():

	# Function to initialise class
	def __init__(self):
		self.redrawPlayhead = False # Flag indicating main process should redraw playhead
		self.playDirection = 1 # Direction of playhead [0, -1]
		self.clock = 0 # Count of MIDI clock pulses since last step [0..24]
		self.status = "STOP" # Play status [STOP | PLAY]
		self.playhead = 0 # Play head position in steps [0..gridColumns]
		self.pattern = 0 # Index of current pattern (zero indexed)
		# List of notes in selected pattern, indexed by step: each step is list of events, each event is list of (note,velocity)
		self.patterns = [] # List of patterns
		self.stepWidth = 40 # Grid column width in pixels (default 40)
		self.gridColumns = 16 # Quantity of columns in grid (default 16)
		self.keyOrigin = 60 # MIDI note number of top row in grid
		self.selectedCell = (self.playhead, self.keyOrigin) # Location of selected cell (step,note)
		#TODO: Get values from persistent storage
		self.menu = [{'title': 'Pattern', 'min': 1, 'max': MAX_PATTERNS, 'value': 1}, \
			{'title': 'Velocity', 'min': 0, 'max': 127, 'value':100}, \
			{'title': 'Steps', 'min': 2, 'max': 64, 'value': 16}, \
			{'title': 'Copy pattern', 'min': 1, 'max': MAX_PATTERNS, 'value': 1}, \
			{'title': 'Clear pattern', 'min': 1, 'max': MAX_PATTERNS, 'value': 1}, \
			{'title': 'Transpose', 'min': -1, 'max': 2, 'value': 1}, \
			{'title': 'MIDI Channel', 'min': 1, 'max': 16, 'value': 1}, \
			{'title': 'Transport start mode', 'min': 0, 'max': 1, 'value': 0},
			{'title': 'Play mode', 'min': 0, 'max': 2, 'value': 0},
			{'title': 'Grid lines', 'min': 0, 'max': 8, 'value': 0},
			{'title': 'Rows', 'min': 1, 'max': 100, 'value': 16}]
		self.menuSelected = STEP_MENU_VELOCITY
		self.menuSelectMode = False # True to change selected menu value, False to change menu selection
		self.menuModeMutex = False # Flag to avoid updating menus whilst processing changes
		self.midiOutQueue = [] # List of events to be sent to MIDI output
		self.shown = False # True when GUI in view
		self.zyngui = zynthian_gui_config.zyngui # Zynthian GUI configuration

		# Geometry vars
		self.width=zynthian_gui_config.display_width
		self.height=zynthian_gui_config.display_height
		self.playheadHeight = 5
		self.titlebarHeight = int(self.height * 0.1)
		self.gridHeight = self.height - self.titlebarHeight - self.playheadHeight
		self.gridWidth = int(self.width * 0.9)
		self.pianoRollWidth = self.width - self.gridWidth
		self.updateRowHeight()

		# Main Frame
		self.main_frame = tkinter.Frame(zynthian_gui_config.top,
			width=zynthian_gui_config.display_width,
			height=zynthian_gui_config.display_height,
			bg=CANVAS_BACKGROUND)

		logging.info("Starting PyStep...")
		# Load pattern from file
		try:
			filename=os.environ.get("ZYNTHIAN_MY_DATA_DIR", "/zynthian/zynthian-my-data") + "/sequences/patterns.json"
			with open(filename) as f:
				self.patterns = json.load(f)
		except:
			logging.warn('Failed to load pattern file')
			self.patterns = [[[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[]]] # Default to empty 16 step pattern
		# Draw pattern grid
		self.gridCanvas = tkinter.Canvas(self.main_frame, width=self.gridWidth, height=self.rowHeight * self.menu[STEP_MENU_ROWS]['value'])
		self.gridCanvas.grid(row=1, column=1)
		# Draw title bar
		self.titleCanvas = tkinter.Canvas(self.main_frame, width=self.width, height=self.titlebarHeight, bg=zynthian_gui_config.color_header_bg)
		self.titleCanvas.grid(row=0, column=0, columnspan=2)
		self.titleCanvas.create_text(self.width - 2, int(self.height * 0.05), anchor="e", font=tkFont.Font(family=zynthian_gui_config.font_topbar[0], size=int(self.height * 0.05)), fill=zynthian_gui_config.color_panel_tx, tags="lblPattern")
		lblMenu = self.titleCanvas.create_text(2, int(self.height * 0.05), anchor="w", font=tkFont.Font(family=zynthian_gui_config.font_topbar[0], size=int(self.height * .06)), fill=zynthian_gui_config.color_panel_tx, tags="lblMenu")
		rectMenu = self.titleCanvas.create_rectangle(self.titleCanvas.bbox(lblMenu), fill=zynthian_gui_config.color_header_bg, width=0, tags="rectMenu")
		self.titleCanvas.tag_lower(rectMenu, lblMenu)
		self.refreshMenu()
		# Draw pianoroll
		self.pianoRoll = tkinter.Canvas(self.main_frame, width=self.pianoRollWidth, height=self.menu[STEP_MENU_ROWS]['value'] * self.rowHeight, bg="white")
		self.pianoRoll.grid(row=1, column=0)
		self.pianoRoll.bind("<ButtonPress-1>", self.pianoRollDragStart)
		self.pianoRoll.bind("<ButtonRelease-1>", self.pianoRollDragEnd)
		self.pianoRoll.bind("<B1-Motion>", self.pianoRollDragMotion)
		# Draw playhead
		self.playCanvas = tkinter.Canvas(self.main_frame, height=self.playheadHeight, bg=CANVAS_BACKGROUND)
		self.playCanvas.create_rectangle(0, 0, self.stepWidth, self.playheadHeight, fill=PLAYHEAD_CURSOR, state="hidden", width=0, tags="playCursor")
		self.playCanvas.grid(row=2, column=1)

		self.loadPattern(self.menu[STEP_MENU_PATTERN]['value'] - 1)

		# Set up JACK interface
		jackClient = jack.Client("zynthstep")
		self.midiInput = jackClient.midi_inports.register("input")
		self.midiOutput = jackClient.midi_outports.register("output")
		jackClient.set_process_callback(self.onJackProcess)
		jackClient.activate()
		#TODO: Remove auto test connection 
		try:
			jackClient.connect("a2j:MidiSport 2x2 [20] (capture): MidiSport 2x2 MIDI 1", "zynthstep:input")
			jackClient.connect("zynthstep:output", "ZynMidiRouter:main_in")
		except:
			logging.error("Failed to connect MIDI devices")

	# Function to show GUI
	def show(self):
		if not self.shown:
			self.shown=True
			self.main_frame.grid()
			# Set up encoders
			if zyncoder.lib_zyncoder:
				# Encoder 0 (Layer): Not used
				pin_a=zynthian_gui_config.zyncoder_pin_a[ENC_BACK]
				pin_b=zynthian_gui_config.zyncoder_pin_b[ENC_BACK]
#				zyncoder.lib_zyncoder.setup_zyncoder(ENC_BACK,pin_a,pin_b,0,0,None,0,127,0)
				# Encoder 1 (Back): Select note
				pin_a=zynthian_gui_config.zyncoder_pin_a[ENC_NOTE]
				pin_b=zynthian_gui_config.zyncoder_pin_b[ENC_NOTE]
				zyncoder.lib_zyncoder.setup_zyncoder(ENC_NOTE,pin_a,pin_b,0,0,None,self.selectedCell[1],127,0)
				# Encoder 2 (Snapshot): Menu
				pin_a=zynthian_gui_config.zyncoder_pin_a[ENC_MENU]
				pin_b=zynthian_gui_config.zyncoder_pin_b[ENC_MENU]
				zyncoder.lib_zyncoder.setup_zyncoder(ENC_MENU,pin_a,pin_b,0,0,None,self.menuSelected,len(self.menu) - 1,0)
				# Encoder 3 (Select): Select step
				pin_a=zynthian_gui_config.zyncoder_pin_a[ENC_STEP]
				pin_b=zynthian_gui_config.zyncoder_pin_b[ENC_STEP]
				zyncoder.lib_zyncoder.setup_zyncoder(ENC_STEP,pin_a,pin_b,0,0,None,self.selectedCell[0],self.gridColumns - 1,0)

	# Function to hide GUI
	def hide(self):
		if self.shown:
			if self.menuSelectMode:
				self.toggleMenuMode(False)
			self.shown=False
			self.main_frame.grid_forget()
			self.savePatterns()

	# Function to handle start of pianoroll drag
	def pianoRollDragStart(self, event):
		self.pianoRollDragStartY = event.y

	# Function to handle pianoroll drag motion
	def pianoRollDragMotion(self, event):
		if event.y > self.pianoRollDragStartY + self.rowHeight and self.keyOrigin < 128 - self.menu[STEP_MENU_ROWS]['value']:
			self.keyOrigin = self.keyOrigin + 1
			self.pianoRollDragStartY = event.y
			self.drawGrid()
		elif event.y < self.pianoRollDragStartY - self.rowHeight and self.keyOrigin > 0:
			self.keyOrigin = self.keyOrigin - 1
			self.pianoRollDragStartY = event.y
			self.drawGrid()

	# Function to handle end of pianoroll drag
	def pianoRollDragEnd(self, event):
		self.pianoRollDragStartY = None

	# Function to draw the play head cursor
	def drawPlayhead(self):
		self.playCanvas.coords("playCursor", 1 + self.playhead * self.stepWidth, 0, self.playhead * self.stepWidth + self.stepWidth, self.rowHeight / 2)
		self.redrawPlayhead = False

	# Function to handle mouse click / touch
	#   event: Mouse event
	def onCanvasClick(self, event):
		closest = event.widget.find_closest(event.x, event.y)
		tags = self.gridCanvas.gettags(closest)
		self.toggleEvent(int(tags[0].split(',')[0]), [self.keyOrigin + int(tags[0].split(',')[1]), self.menu[STEP_MENU_VELOCITY]['value']])

	# Function to toggle note event
	#   step: step (column) index
	#   note: note list [note, velocity]
	def toggleEvent(self, step, note):
		if step < 0 or step >= self.gridColumns:
			return
		found = False
		for event in self.patterns[self.pattern][step]:
			if event[0] == note[0]:
				self.patterns[self.pattern][step].remove(event)
				found = True
				break
		if not found and note[1]:
			self.patterns[self.pattern][step].append(note)
			self.noteOn(note)
			self.noteOffTimer = threading.Timer(0.1, self.noteOff, [note]).start()
		if note[0] >= self.keyOrigin and note[0] < self.keyOrigin + self.menu[STEP_MENU_ROWS]['value']:
			self.selectCell(step, note[0])

	# Function to draw a grid cell
	#   step: Column index
	#   note: Row index
	def drawCell(self, col, row):
		if col >= self.gridColumns:
			return
		velocity = 255 # White
		for note in self.patterns[self.pattern][col]:
			if note[0] == self.keyOrigin + row:
				velocity = 200 - int(note[1] / 2)
		fill = "#%02x%02x%02x" % (velocity, velocity, velocity)
		if self.selectedCell == (col, row + self.keyOrigin):
			outline = SELECT_BORDER
		elif velocity == 255:
			outline = CANVAS_BACKGROUND
		else:
			outline = NOTE_ON_BORDER
		cell = self.gridCanvas.find_withtag("%d,%d"%(col,row))
		x1 = 1 + col * self.stepWidth
		y1 = (self.menu[STEP_MENU_ROWS]['value'] - row) * self.rowHeight
		x2 = 1 + (col + 1) * self.stepWidth - SELECT_THICKNESS
		y2 = (self.menu[STEP_MENU_ROWS]['value'] - row - 1) * self.rowHeight + SELECT_THICKNESS
		if cell:
			# Update existing cell
			self.gridCanvas.itemconfig(cell, fill=fill, outline=outline)
			self.gridCanvas.coords(cell, x1, y1, x2, y2)
		else:
			# Create new cell
			cell = self.gridCanvas.create_rectangle(x1, y1, x2, y2, fill=fill, outline=outline, tags=("%d,%d"%(col,row)), width=SELECT_THICKNESS)
			self.gridCanvas.tag_bind(cell, '<Button-1>', self.onCanvasClick)

	# Function to draw grid
	#   clearGrid: True to clear grid and create all new elements, False to reuse existing elements if they exist
	def drawGrid(self, clearGrid = False):
		if clearGrid:
			self.gridCanvas.delete(tkinter.ALL)
			self.stepWidth = int(self.gridWidth / self.gridColumns)
			self.drawPianoroll()
		# Delete existing note names
		for item in self.pianoRoll.find_withtag("notename"):
			self.pianoRoll.delete(item)
		# Redraw gridlines
		for item in self.gridCanvas.find_withtag("gridline"):
			self.gridCanvas.delete(item)
		for col in range(self.gridColumns):
			if self.menu[STEP_MENU_GRID]['value'] and col % self.menu[STEP_MENU_GRID]['value'] == 0:
				cell = self.gridCanvas.create_line(col * self.stepWidth - 1, 0, col * self.stepWidth - 1, self.menu[STEP_MENU_ROWS]['value'] * self.rowHeight, width=2, tags=("gridline"))
		# Draw cells of grid
		for row in range(self.menu[STEP_MENU_ROWS]['value']):
			for col in range(self.gridColumns):
				self.drawCell(col, row)
			# Update pianoroll keys
			key = (self.keyOrigin + row) % 12
			id = "row%d" % (row)
			if key in (0,2,4,5,7,9,11):
				self.pianoRoll.itemconfig(id, fill="white")
				if key == 0:
					self.pianoRoll.create_text((self.pianoRollWidth / 2, self.rowHeight * (self.menu[STEP_MENU_ROWS]['value'] - row - 0.5)), text="C%d (%d)" % ((self.keyOrigin + row) // 12 - 1, self.keyOrigin + row), font=tkFont.Font(family=zynthian_gui_config.font_topbar[0], size=int(self.rowHeight * 0.5)), fill=CANVAS_BACKGROUND, tags="notename")
			else:
				self.pianoRoll.itemconfig(id, fill="black")

	# Function to send MIDI note on
	#   note: List (MIDI note number, MIDI velocity)
	def noteOn(self, note):
		self.midiOutQueue.append((0x90 | (self.menu[STEP_MENU_MIDI]['value'] - 1), note[0], note[1]))

	# Function to send MIDI note off
	#   note: List (MIDI note number, MIDI velocity)
	def noteOff(self, note):
		self.midiOutQueue.append((0x80 | (self.menu[STEP_MENU_MIDI]['value'] - 1), note[0], note[1]))

	# Function to control play head
	#   command: Playhead command ["STOP" | "START" | "CONTINUE"]
	def setPlayState(self, command):
		if command == "START":
				logging.info("MIDI START")
				self.playhead = self.gridColumns - 1
				self.clock = 24
				self.status = "PLAY"
				self.playCanvas.coords("playCursor", 0, 0, self.stepWidth, self.rowHeight / 2)
				self.playCanvas.itemconfig("playCursor", state = 'normal')
		elif command == "CONTINUE":
				logging.info("MIDI CONTINUE")
				self.status = "PLAY"
				self.playCanvas.itemconfig("playCursor", state = 'normal')
		elif command == "STOP":
				logging.info("MIDI STOP")
				self.status = "STOP"
				self.playCanvas.itemconfig("playCursor", state = 'hidden')
				for note in self.patterns[self.pattern][self.playhead]:
					self.noteOff(note)

	# Function to handle JACK process events
	#   frames: Quantity of frames since last process event
	def onJackProcess(self, frames):
		for offset, data in self.midiInput.incoming_midi_events():
			if data[0] == b'\xf8':
				# MIDI Clock
				if self.status == "PLAY":
					self.clock = self.clock + 1
					if self.clock >= 6:
						# Time to process a time slot
						self.clock = 0
						for note in self.patterns[self.pattern][self.playhead]:
							self.noteOff(note)
						self.playhead = self.playhead + self.playDirection
						if self.playhead >= self.gridColumns:
							if self.menu[STEP_MENU_PLAYMODE]['value']:
								self.playhead = self.gridColumns - 2
								self.playDirection = -1
							else:
								self.playhead = 0
						elif self.playhead < 0:
							if self.menu[STEP_MENU_PLAYMODE]['value'] == 1:
								self.playhead = self.gridColumns - 1
							else:
								self.playhead = 1
								self.playDirection = 1
						for note in self.patterns[self.pattern][self.playhead]:
							self.noteOn(note)
						self.redrawPlayhead = True # Flag playhead needs redrawing
		self.midiOutput.clear_buffer();
		for out in self.midiOutQueue:
			self.midiOutput.write_midi_event(0, out)
		self.midiOutQueue.clear()

	# Function to draw pianoroll keys (does not fill key colour)
	def drawPianoroll(self):
		self.pianoRoll.delete(tkinter.ALL)
		for row in range(self.menu[STEP_MENU_ROWS]['value']):
			y = self.rowHeight * (self.menu[STEP_MENU_ROWS]['value'] - row)
			id = "row%d" % (row)
			id = self.pianoRoll.create_rectangle(0, y, self.pianoRollWidth, y - self.rowHeight, tags=id)

	# Function to update selectedCell
	#   step: Step (column) of selected cell
	#   note: Note number of selected cell
	def selectCell(self, step, note):
		if step >= self.gridColumns or step < 0:
			return
		if note >= self.keyOrigin + self.menu[STEP_MENU_ROWS]['value']:
			# Note is off top of display
			if note < 128:
				self.keyOrigin = note + 1 - self.menu[STEP_MENU_ROWS]['value']
			else:
				self.keyOrigin = 128 - self.menu[STEP_MENU_ROWS]['value']
			self.drawGrid()
		elif note < self.keyOrigin:
			self.keyOrigin = note
			self.drawGrid()
		else:
			previousSelected = self.selectedCell
			self.selectedCell = (step, note)
			self.drawCell(previousSelected[0], previousSelected[1]- self.keyOrigin) # Remove selection highlight
			self.drawCell(self.selectedCell[0], self.selectedCell[1] - self.keyOrigin)
		if zyncoder.lib_zyncoder:
			zyncoder.lib_zyncoder.set_value_zyncoder(ENC_NOTE, note)
			zyncoder.lib_zyncoder.set_value_zyncoder(ENC_STEP, step)

	# Function to save patterns to json file
	def savePatterns(self):
		filename=os.environ.get("ZYNTHIAN_MY_DATA_DIR", "/zynthian/zynthian-my-data") + "/sequences/patterns.json"
		os.makedirs(os.path.dirname(filename), exist_ok=True)
		try:
			with open(filename, 'w') as f:
				json.dump(self.patterns, f)
		except:
			logging.error("Failed to save step sequence")

	# Function to set menu value
	#   menuItem: Index of menu item
	#   value: Value to set menu item to
	def setMenuValue(self, menuItem, value):
		if menuItem >= len(self.menu) or value < self.menu[menuItem]['min'] or value > self.menu[menuItem]['max']:
			return
		Force = False
		self.menu[menuItem]['value'] = value
		if menuItem == STEP_MENU_VELOCITY:
			# Adjust velocity of selected cell
			currentStep = self.patterns[self.pattern][self.selectedCell[0]]
			for event in currentStep:
				if event[0] == self.selectedCell[1]:
					event[1] = value
					self.drawCell(self.selectedCell[0], self.selectedCell[1] - self.keyOrigin)
					return
		elif menuItem == STEP_MENU_PATTERN or menuItem == STEP_MENU_COPY:
			self.menu[STEP_MENU_COPY]['value'] = value # update copy value when pattern value changes
			self.menu[STEP_MENU_CLEAR]['value'] = value # update clear value when pattern value changes
			if value >= len(self.patterns):
				self.patterns.append([[],[],[],[],[],[],[],[]]) # Dynamically create extra patterns
			self.loadPattern(value - 1)
		elif menuItem == STEP_MENU_STEPS:
			for step in range(self.gridColumns, value):
				self.patterns[self.pattern].append([])
			self.gridColumns = value
			self.drawGrid(True)
			if zyncoder.lib_zyncoder:
				pin_a=zynthian_gui_config.zyncoder_pin_a[ENC_STEP]
				pin_b=zynthian_gui_config.zyncoder_pin_b[ENC_STEP]
				zyncoder.lib_zyncoder.setup_zyncoder(ENC_STEP,pin_a,pin_b,0,0,None,self.selectedCell[0],self.gridColumns - 1,0)
		elif menuItem == STEP_MENU_TRANSPOSE:
			# zyncoders only support positive integers so must use offset
			for step in range(self.gridColumns):
				for note in self.patterns[self.pattern][step]:
					note[0] = note[0] + value - 1
			if zyncoder.lib_zyncoder:
				zyncoder.lib_zyncoder.set_value_zyncoder(ENC_MENU, 1)
				zyncoder.lib_zyncoder.zynmidi_send_all_notes_off()
		elif menuItem == STEP_MENU_ROWS:
			self.updateRowHeight()
			Force = True
		self.drawGrid(Force)

	# Function to calculate row height
	def updateRowHeight(self):
		self.rowHeight = int((self.gridHeight)  / (self.menu[STEP_MENU_ROWS]['value']))

	# Function to clear a pattern
	#	pattern: Index of the pattern to clear
	def clearPattern(self, pattern):
		if pattern < 0 or pattern > len(self.patterns):
			return
		for step in range(len(self.patterns[pattern])):
			self.patterns[pattern][step] = []

	# Function to copy pattern
	#	source: Index of pattern to copy from
	#	dest: Index of pattern to copy to
	def copyPattern(self, source, dest):
		if source < 0 or source > len(self.patterns) or dest < 0 or dest > len(self.patterns) or source == dest:
			return
		self.patterns[dest] = copy.deepcopy(self.patterns[source])
		if dest == self.pattern:
			self.loadPattern(dest)

	# Function to toggle menu mode between menu selection and data entry
	#	assertChange: True to assert changes, False to cancel changes
	def toggleMenuMode(self, assertChange = True):
		self.menuModeMutex = True
		self.menuSelectMode = not self.menuSelectMode
		if self.menuSelectMode:
			# Entered value edit mode
			self.titleCanvas.itemconfig("rectMenu", fill=zynthian_gui_config.color_hl)
			if zyncoder.lib_zyncoder:
				pin_a=zynthian_gui_config.zyncoder_pin_a[ENC_MENU]
				pin_b=zynthian_gui_config.zyncoder_pin_b[ENC_MENU]
				zyncoder.lib_zyncoder.setup_zyncoder(ENC_MENU,pin_a,pin_b,0,0,None,self.menu[self.menuSelected]['value'],self.menu[self.menuSelected]['max'],0)
		else:
			# Entered menu item select mode
			self.titleCanvas.itemconfig("rectMenu", fill=zynthian_gui_config.color_header_bg)
			if assertChange:
				if self.menuSelected == STEP_MENU_STEPS:
					self.removeObsoleteSteps()
				elif self.menuSelected == STEP_MENU_COPY:
					self.copyPattern(self.menu[STEP_MENU_PATTERN]['value'] - 1, self.pattern)
					self.menu[STEP_MENU_PATTERN]['value'] = self.pattern + 1
			elif self.menuSelected == STEP_MENU_STEPS:
				self.loadPattern(self.pattern)
			if zyncoder.lib_zyncoder:
				pin_a=zynthian_gui_config.zyncoder_pin_a[ENC_MENU]
				pin_b=zynthian_gui_config.zyncoder_pin_b[ENC_MENU]
				zyncoder.lib_zyncoder.setup_zyncoder(ENC_MENU,pin_a,pin_b,0,0,None,self.menuSelected,len(self.menu) - 1,0)
		self.refreshMenu()
		self.menuModeMutex = False

	# Function to remove steps that are not within current display window
	def removeObsoleteSteps(self):
		self.patterns[self.pattern] = self.patterns[self.pattern][:self.gridColumns]

	# Function to update menu display
	def refreshMenu(self):
		menuItem = self.menu[self.menuSelected]
		if self.menuSelected == STEP_MENU_MIDI_START:
			value = 'CONTINUE' if menuItem['value'] else 'START'
		elif self.menuSelected == STEP_MENU_PLAYMODE:
			if menuItem['value'] == 1:
				value = "Reverse"
			elif menuItem['value'] == 2:
				value = "Bounce"
			else:
				value = "Forward"
		elif self.menuSelected == STEP_MENU_GRID and menuItem['value'] == 0:
			value = "None"
		elif self.menuSelected == STEP_MENU_TRANSPOSE:
			value = "Up/Down"
		elif self.menuSelected == STEP_MENU_COPY:
			value = "From %d to %d" % (self.menu[STEP_MENU_PATTERN]['value'], self.pattern + 1)
		else:
			value = menuItem['value']
		self.titleCanvas.itemconfig("lblMenu", text="%s: %s" % (menuItem['title'], value))
		self.titleCanvas.coords("rectMenu", self.titleCanvas.bbox("lblMenu"))

	# Function to handle menu change
	#   value: New value
	def onMenuChange(self, value):
		self.menuModeMutex = True
		if self.menuSelectMode:
			# Set menu value
			self.setMenuValue(self.menuSelected, value)
			self.refreshMenu()
		elif value >= 0 and value < len(self.menu):
			self.menuSelected = value
			self.refreshMenu()
			if zyncoder.lib_zyncoder:
				pin_a=zynthian_gui_config.zyncoder_pin_a[ENC_MENU]
				pin_b=zynthian_gui_config.zyncoder_pin_b[ENC_MENU]
				zyncoder.lib_zyncoder.setup_zyncoder(ENC_MENU,pin_a,pin_b,0,0,None,self.menuSelected,len(self.menu) - 1,0)
		self.menuModeMutex = False

	# Function to load new pattern
	def loadPattern(self, index):
		if index >= len(self.patterns) or index < 0:
			return
		self.pattern = index
		self.gridColumns = len(self.patterns[self.pattern])
		self.menu[STEP_MENU_STEPS]['value'] = self.gridColumns
		if self.playhead >= self.gridColumns:
			self.playhead = 0
		self.drawGrid(True)
		self.playCanvas.config(width=self.gridColumns * self.stepWidth)
		self.titleCanvas.itemconfig("lblPattern", text="Pattern: %d" % (self.pattern + 1))
		if zyncoder.lib_zyncoder:
			pin_a=zynthian_gui_config.zyncoder_pin_a[ENC_STEP]
			pin_b=zynthian_gui_config.zyncoder_pin_b[ENC_STEP]
			zyncoder.lib_zyncoder.setup_zyncoder(ENC_STEP,pin_a,pin_b,0,0,None,self.selectedCell[0],self.gridColumns - 1,0)

	def refresh_loading(self):
		pass

	# Function to handle zyncoder polling
	def zyncoder_read(self):
		if not self.shown:
			return
		if zyncoder.lib_zyncoder:
			val=zyncoder.lib_zyncoder.get_value_zyncoder(ENC_NOTE)
			if val != self.selectedCell[1]:
				self.selectCell(self.selectedCell[0], val)
			val=zyncoder.lib_zyncoder.get_value_zyncoder(ENC_STEP)
			if val != self.selectedCell[0]:
				self.selectCell(val, self.selectedCell[1])
			val = zyncoder.lib_zyncoder.get_value_zyncoder(ENC_MENU)
			if self.menuSelectMode:
				# Change value
				if not self.menuModeMutex and val != self.menu[self.menuSelected]['value']:
					self.onMenuChange(val)
			else:
				# Change menu
				if not self.menuModeMutex and val != self.menuSelected:
					self.onMenuChange(val)
		if self.redrawPlayhead:
			self.drawPlayhead()

	# Function to handle CUIA SELECT_UP command
	def select_up(self):
		if zyncoder.lib_zyncoder:
			zyncoder.lib_zyncoder.set_value_zyncoder(ENC_SELECT, zyncoder.lib_zyncoder.get_value_zyncoder(ENC_SELECT) + 1)

	# Function to handle CUIA SELECT_DOWN command
	def select_down(self):
		if zyncoder.lib_zyncoder:
			value = zyncoder.lib_zyncoder.get_value_zyncoder(ENC_SELECT)
			if value > 0:
				zyncoder.lib_zyncoder.set_value_zyncoder(ENC_SELECT, value - 1)

	# Function to handle CUIA LAYER_UP command
	def layer_up():
		if zyncoder.lib_zyncoder:
			zyncoder.lib_zyncoder.set_value_zyncoder(ENC_LAYER, zyncoder.lib_zyncoder.get_value_zyncoder(ENC_LAYER) + 1)

	# Function to handle CUIA LAYER_DOWN command
	def layer_down():
		if zyncoder.lib_zyncoder:
			zyncoder.lib_zyncoder.set_value_zyncoder(ENC_LAYER, zyncoder.lib_zyncoder.get_value_zyncoder(ENC_LAYER) - 1)

	# Function to handle CUIA SNAPSHOT_UP command
	def snapshot_up():
		if zyncoder.lib_zyncoder:
			zyncoder.lib_zyncoder.set_value_zyncoder(ENC_SNAPSHOT, zyncoder.lib_zyncoder.get_value_zyncoder(ENC_SNAPSHOT) + 1)

	# Function to handle CUIA SNAPSHOT_DOWN command
	def snapshot_down():
		if zyncoder.lib_zyncoder:
			zyncoder.lib_zyncoder.set_value_zyncoder(ENC_SNAPSHOT, zyncoder.lib_zyncoder.get_value_zyncoder(ENC_SNAPSHOT) - 1)

	# Function to handle CUIA SELECT command
	def switch_select(self, t):
		self.switch(3, t)

	# Function to handle switch press
	#	switch: Switch index [0=Layer, 1=Back, 2=Snapshot, 3=Select]
	#	type: Press type ["S"=Short, "B"=Bold, "L"=Long]
	#	returns True if action fully handled or False if parent action should be triggered
	def switch(self, switch, type):
		if type == "L":
			return False # Don't handle any long presses
		if switch == ENC_BACK:
			if self.menuSelectMode:
				self.toggleMenuMode(False) # Disable data entry before exit
			else:
				return False
		if switch == ENC_MENU:
			if self.menuSelected == STEP_MENU_CLEAR:
				if type == "B":
					self.clearPattern(self.pattern)
					self.loadPattern(self.pattern)
			else:
				self.toggleMenuMode()
		if switch == ENC_NOTE:
			if self.status == "STOP":
				command = "CONTINUE" if self.menu[STEP_MENU_MIDI_START]['value'] else "START"
				self.setPlayState(command)
			else:
				self.setPlayState("STOP")
		if switch == ENC_STEP:
			self.toggleEvent(self.selectedCell[0], [self.selectedCell[1], self.menu[STEP_MENU_VELOCITY]['value']])
		return True # Tell parent that we handled all short and bold key presses
#------------------------------------------------------------------------------
