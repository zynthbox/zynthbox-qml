#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Data container (and support containers) for sound and fx engine routing information
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
from PySide2.QtCore import Property, QObject, Signal, Slot

class sketchpadEngineRoutingSource(QObject):
    def __init__(self, port:str, name:str, parent: QObject = None):
        super(sketchpadEngineRoutingSource, self).__init__(parent)
        self.__name__ = name
        self.__port__ = port

    def serialize(self):
        return {
            "name": self.__name__,
            "port": self.__port__
            }

    def deserialize(self,obj):
        try:
            if "name" in obj:
                self.name = obj["name"]
            if "port" in obj:
                self.port = obj["port"]
        except e as Exception:
            logging.error(f"Error during channel deserialization: {e}")

    ## BEGIN Property name
    def setName(self, newName:str):
        if self.__name__ != newName:
            self.__name__ = newName
            self.nameChanged.emit()
    def getName(self):
        return self.__name__
    nameChanged = Signal()
    name = Property(str, getName, setName, notify=nameChanged)
    ## END Property name

    ## BEGIN Property port
    def setPort(self, newPort:str):
        if self.__port__ != newPort:
            self.__port__ = newPort
            self.portChanged.emit()
    def getPort(self):
        return self.__port__
    portChanged = Signal()
    port = Property(str, getPort, setPort, notify=portChanged)
    ## END Property port

class sketchpad_engineRoutingPort(QObject):
    def __init__(self, name:str, jackname:str, parent: QObject = None):
        super(sketchpad_engineRoutingPort, self).__init__(parent)
        self.__sources__ = []
        self.__name__ = name
        self.__jackname__ = jackname

    routingDataChanged = Signal()

    def serialize(self):
        return {
            "name": self.__name__,
            "jackname": self.__jackname__,
            "sources": [source.serialize() for source in self.__sources__]
            }

    def deserialize(self,obj):
        self.__name__ = ""
        self.__jackname__ = ""
        self.__sources__ = []
        try:
            if "name" in obj:
                self.__name__ = obj["name"]
            if "jackname" in obj:
                self.__jackname__ = obj["jackname"]
            if "sources" in obj:
                for serialisedSource in obj["sources"]:
                    newSource = sketchpadEngineRoutingSource("", "", self)
                    newSource.deserialize(serialisedSource)
                    newSource.portChanged.connect(self.routingDataChanged)
                    newSource.nameChanged.connect(self.routingDataChanged)
                    self.__sources__.append(newSource)
        except e as Exception:
            logging.error(f"Error during channel deserialization: {e}")
        self.nameChanged.emit()
        self.jacknameChanged.emit()
        self.sourcesChanged.emit()

    ### BEGIN Property sources
    @Slot(str, str)
    def addSource(self, port:str, name:str):
        newSource = sketchpadEngineRoutingSource(port, name, self)
        newSource.portChanged.connect(self.routingDataChanged)
        newSource.nameChanged.connect(self.routingDataChanged)
        self.__sources__.append(newSource)
        self.sourcesChanged.emit()

    @Slot(int)
    def removeSource(self, index:int):
        if -1 < index and index < len(self.__sources__):
            del self.__sources__[index]
            self.sourcesChanged.emit()

    def getSources(self):
        return self.__sources__
    sourcesChanged = Signal()
    sources = Property('QVariantList', getSources, notify=sourcesChanged)
    ### END Property sources

    ## BEGIN Property name
    def setName(self, newName:str):
        if self.__name__ != newName:
            self.__name__ = newName
            self.nameChanged.emit()
    def getName(self):
        return self.__name__
    nameChanged = Signal()
    name = Property(str, getName, setName, notify=nameChanged)
    ## END Property name

    ## BEGIN Property jackname
    def setJackname(self, newJackname:str):
        if self.__jackname__ != newJackname:
            self.__jackname__ = newJackname
            self.jacknameChanged.emit()
    def getJackname(self):
        return self.__jackname__
    jacknameChanged = Signal()
    jackname = Property(str, getJackname, setJackname, notify=jacknameChanged)
    ## END Property jackname

class sketchpad_engineRoutingData(QObject):
    def __init__(self, parent: QObject = None):
        super(sketchpad_engineRoutingData, self).__init__(parent)
        self.__audioInPorts__ = []
        self.__midiInPorts__ = []
        self.__name__ = ""

    routingDataChanged = Signal()

    def serialize(self):
        return {
            "name": self.__name__,
            "audioInPorts": [port.serialize() for port in self.__audioInPorts__],
            "midiInPorts": [port.serialize() for port in self.__midiInPorts__]
            }

    def deserialize(self,obj):
        self.__name__ = ""
        self.__audioInPorts__ = []
        self.__midiInPorts__ = []
        try:
            if "name" in obj:
                self.name = obj["name"]
            if "audioInPorts" in obj:
                for serialisedPort in obj["audioInPorts"]:
                    newPort = sketchpad_engineRoutingPort("", "", self)
                    newPort.deserialize(serialisedPort)
                    newPort.sourcesChanged.connect(self.routingDataChanged)
                    newPort.routingDataChanged.connect(self.routingDataChanged)
                    self.__audioInPorts__.append(newPort)
            if "midiInPorts" in obj:
                for serialisedPort in obj["midiInPorts"]:
                    newPort = sketchpad_engineRoutingPort("", "", self)
                    newPort.deserialize(serialisedPort)
                    newPort.sourcesChanged.connect(self.routingDataChanged)
                    newPort.routingDataChanged.connect(self.routingDataChanged)
                    self.__midiInPorts__.append(newPort)
        except e as Exception:
            logging.error(f"Error during channel deserialization: {e}")
        self.audioInPortsChanged.emit()
        self.midiInPortsChanged.emit()
        self.routingDataChanged.emit()

    def clear(self):
        self.name = ""
        self.__audioInPorts__ = []
        self.audioInPortsChanged.emit()
        self.__midiInPorts__ = []
        self.midiInPortsChanged.emit()
        self.routingDataChanged.emit()

    def humanReadablePortName(self, portName):
        # Heuristics for more pleasant port display names
        if portName == "events" or portName == "lv2_events_in" or portName == "input":
            return "Midi Events In"
        if portName.startswith("lv2_audio_in_") or portName.startsWith("input_"):
            return "Audio In " + portName.split("_")[-1]
        if portName.startswith("lv2-audio-in-") or portName.startsWith("input-"):
            return "Audio In " + portName.split("-")[-1]
        if portName == "in_L":
            return "Audio In Left"
        if portName == "in_R":
            return "Audio In Right"
        return portName

    ### BEGIN Property audioInPorts
    @Slot(str)
    def addAudioInPort(self, name:str, jackname:str):
        portExists = False
        for oldPort in self.__audioInPorts__:
            if oldPort.jackname == jackname:
                if oldPort.name != name:
                    oldPort.name = name
                portExists = True
                break;
        if portExists == False:
            newPort = sketchpad_engineRoutingPort(name, jackname, self)
            newPort.sourcesChanged.connect(self.routingDataChanged)
            self.__audioInPorts__.append(newPort)
            self.audioInPortsChanged.emit()

    def getAudioInPorts(self):
        return self.__audioInPorts__
    audioInPortsChanged = Signal()
    audioInPorts = Property('QVariantList', getAudioInPorts, notify=audioInPortsChanged)
    ### END Property audioInPorts

    ### BEGIN Property midiInPorts
    @Slot(str)
    def addMidiInPort(self, name:str, jackname:str):
        portExists = False
        for oldPort in self.__midiInPorts__:
            if oldPort.jackname == jackname:
                if oldPort.name != name:
                    oldPort.name = name
                portExists = True
                break;
        if portExists == False:
            newPort = sketchpad_engineRoutingPort(name, jackname, self)
            newPort.sourcesChanged.connect(self.routingDataChanged)
            self.__midiInPorts__.append(newPort)
            self.midiInPortsChanged.emit()

    def getMidiInPorts(self):
        return self.__midiInPorts__
    midiInPortsChanged = Signal()
    midiInPorts = Property('QVariantList', getMidiInPorts, notify=midiInPortsChanged)
    ### END Property midiInPorts

    ## BEGIN Property name
    def setName(self, newName:str):
        if self.__name__ != newName:
            self.__name__ = newName
            self.nameChanged.emit()
    def getName(self):
        return self.__name__
    nameChanged = Signal()
    name = Property(str, getName, setName, notify=nameChanged)
    ## END Property name
