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
import json
import logging
import math
import os
import shutil
import tempfile
import threading
import traceback
import jack
import numpy as np
import base64
import Zynthbox
import warnings

from pathlib import Path
from PySide2.QtCore import Property, QGenericArgument, QMetaObject, QObject, QThread, QTimer, Qt, Signal, Slot
from PySide2.QtGui import QColor
from .sketchpad_clips_model import sketchpad_clips_model
from .sketchpad_clip import sketchpad_clip
from .sketchpad_engineRoutingData import sketchpad_engineRoutingData
from .sketchpad_keyzoneData import sketchpad_keyzoneData
from zynqtgui import zynthian_gui_config
from ..zynthian_gui_multi_controller import MultiController

class last_selected_obj_dto(QObject):
    def __init__(self, parent=None):
        super(last_selected_obj_dto, self).__init__(parent)
        self.__className = "TracksBar_synthslot"
        self.__value = 0
        self.__component = None

        self.classNameChanged.connect(self.isCopyableChanged.emit)

    @Slot()
    def reset(self):
        self.__className = None
        self.__value = 0
        self.__component = None

        self.classNameChanged.emit()
        self.valueChanged.emit()
        self.componentChanged.emit()

    @Slot(str, 'QVariant', QObject)
    def setTo(self,className, value, component):
        if self.__className != className or self.__value != value or self.__component != component:
            self.__className = className
            self.__value = value
            self.__component = component
            self.classNameChanged.emit()
            self.valueChanged.emit()
            self.componentChanged.emit()

    ### BEGIN Property className
    def get_className(self):
        return self.__className

    def set_className(self, val):
        if self.__className != val:
            self.__className = val
            self.classNameChanged.emit()

    classNameChanged = Signal()

    className = Property(str, get_className, set_className, notify=classNameChanged)
    ### END Property className

    ### BEGIN Property value
    def get_value(self):
        return self.__value

    def set_value(self, val):
        if self.__value != val:
            self.__value = val
            self.valueChanged.emit()

    valueChanged = Signal()

    value = Property("QVariant", get_value, set_value, notify=valueChanged)
    ### END Property value

    ### BEGIN Property component
    def get_component(self):
        return self.__component

    def set_component(self, val):
        if self.__component != val:
            self.__component = val
            self.componentChanged.emit()

    componentChanged = Signal()

    component = Property(QObject, get_component, set_component, notify=componentChanged)
    ### END Property component

    ### BEGIN Property isCopyable
    def get_isCopyable(self):
        return False

    isCopyableChanged = Signal()

    """
    isCopyable property will return if the current selected object is copyable
    If the object is copyable, copyFrom should implement copy logic of the type

    isCopyable depends upon className and hence change should be notified when className changes
    """
    isCopyable = Property(bool, get_isCopyable, notify=isCopyableChanged)
    ### END Property component

    @Slot(QObject)
    def copyFrom(self, sourceObject):
        pass

class external_mode_settings(QObject):
    def __init__(self, parent: QObject = None):
        super(external_mode_settings, self).__init__(parent)
        self.__track__ = parent
        self.__keyValueStores__ = {}
        self.__defaultKeyValueStore__ = {
            "controls": [
                { "midiChannel": -1, "ccControl": 2},
                { "midiChannel": -1, "ccControl": 4},
                { "midiChannel": -1, "ccControl": 5},
                { "midiChannel": -1, "ccControl": 7},
                { "midiChannel": -1, "ccControl": 8},
                { "midiChannel": -1, "ccControl": 10},
                { "midiChannel": -1, "ccControl": 11},
                { "midiChannel": -1, "ccControl": 12},
                { "midiChannel": -1, "ccControl": 13},
                { "midiChannel": -1, "ccControl": 16},
                { "midiChannel": -1, "ccControl": 17},
                { "midiChannel": -1, "ccControl": 18}
            ]
        }
        self.__selectedModule__ = ""
        self.__midiChannel__ = -1
        self.__captureVolume__ = 0
        self.__audioSource__ = ""
        self.__midiOutDevice__ = "" # Default is the midi 5-pin output
        self.keyValueStoreChanged.connect(self.somethingChanged)
        self.selectedModuleChanged.connect(self.somethingChanged)
        self.midiChannelChanged.connect(self.somethingChanged)
        self.captureVolumeChanged.connect(self.somethingChanged)
        self.audioSourceChanged.connect(self.somethingChanged)
        self.midiOutDeviceChanged.connect(self.somethingChanged)

    # Fired whenever something changes (see also the connections in the ctor)
    somethingChanged = Signal()

    # BEGIN Property keyValueStore
    # A simple key/value store, intended for use by the currently selected module (a separate one will be available to each specific module)
    def get_keyValueStore(self):
        if self.__selectedModule__ == "":
            return self.__defaultKeyValueStore__
        elif self.__selectedModule__ not in self.__keyValueStores__:
            return {}
        return self.__keyValueStores__[self.__selectedModule__]

    @Slot(str, 'QVariant')
    def setValue(self, key, value):
        if self.__selectedModule__ == "" or self.__selectedModule__ not in self.__keyValueStores__:
            self.__defaultKeyValueStore__[key] = value
        else:
            self.__keyValueStores__[self.__selectedModule__][key] = value
        self.keyValueStoreChanged.emit()

    @Slot(str, str, 'QVariant')
    def setSubValue(self, key, subkey, value):
        if self.__selectedModule__ == "" or self.__selectedModule__ not in self.__keyValueStores__:
            self.__defaultKeyValueStore__[key][subkey] = value
        else:
            self.__keyValueStores__[self.__selectedModule__][key][subkey] = value
        self.keyValueStoreChanged.emit()

    @Slot(str, int, str, 'QVariant')
    def setSubIndexValue(self, key, index, subkey, value):
        if self.__selectedModule__ == "" or self.__selectedModule__ not in self.__keyValueStores__:
            self.__defaultKeyValueStore__[key][index][subkey] = value
        else:
            self.__keyValueStores__[self.__selectedModule__][key][index][subkey] = value
        self.keyValueStoreChanged.emit()

    @Slot(str)
    def clearValue(self, key):
        if self.__selectedModule__ == "" or self.__selectedModule__ not in self.__keyValueStores__:
            self.__defaultKeyValueStore__.pop(key, None)
        else:
            self.__keyValueStores__[self.__selectedModule__].pop(key, None)
        self.keyValueStoreChanged.emit()

    keyValueStoreChanged = Signal()
    keyValueStore = Property('QVariant', get_keyValueStore, notify=keyValueStoreChanged)
    # END Property keyValueStore

    # BEGIN Property selectedModule
    # If set to the name of some module, the external control page will attempt to load that module (and fall back gracefully to the default if that module doesn't exist)
    def get_selectedModule(self):
        return self.__selectedModule__
    def set_selectedModule(self, selectedModule):
        if self.__selectedModule__ != selectedModule:
            self.__selectedModule__ = selectedModule
            if selectedModule != "" and selectedModule not in self.__keyValueStores__:
                self.__keyValueStores__[selectedModule] = {}
            self.selectedModuleChanged.emit()
            self.keyValueStoreChanged.emit()
    selectedModuleChanged = Signal()
    selectedModule = Property(str, get_selectedModule, set_selectedModule, notify=selectedModuleChanged)
    # END Property selectedModule

    # BEGIN Property midiChannel
    def get_midiChannel(self):
        return self.__midiChannel__
    def set_midiChannel(self, midiChannel):
        if self.__midiChannel__ != midiChannel:
            self.__midiChannel__ = midiChannel
            self.midiChannelChanged.emit()
    midiChannelChanged = Signal()
    midiChannel = Property(int, get_midiChannel, set_midiChannel, notify=midiChannelChanged)
    # END Property midiChannel

    # BEGIN Property captureVolume
    def get_captureVolume(self):
        return self.__captureVolume__
    def set_captureVolume(self, captureVolume):
        if self.__captureVolume__ != captureVolume:
            self.__captureVolume__ = captureVolume
            self.captureVolumeChanged.emit()
    captureVolumeChanged = Signal()
    captureVolume = Property(float, get_captureVolume, set_captureVolume, notify=captureVolumeChanged)
    # END Property captureVolume

    # BEGIN Property audioSource
    def get_audioSource(self):
        return self.__audioSource__
    def set_audioSource(self, audioSource):
        if self.__audioSource__ != audioSource:
            self.__audioSource__ = audioSource
            self.audioSourceChanged.emit()
    audioSourceChanged = Signal()
    audioSource = Property(str, get_audioSource, set_audioSource, notify=audioSourceChanged)
    # END Property audioSource

    # BEGIN Property midiOutDevice
    def get_midiOutDevice(self):
        return self.__midiOutDevice__
    def set_midiOutDevice(self, midiOutDevice):
        if self.__midiOutDevice__ != midiOutDevice:
            self.__midiOutDevice__ = midiOutDevice
            self.midiOutDeviceChanged.emit()
            Zynthbox.MidiRouter.instance().setSketchpadTrackExternalDeviceTarget(Zynthbox.ZynthboxBasics.Track(self.__track__.id), self.__midiOutDevice__)
    midiOutDeviceChanged = Signal()
    midiOutDevice = Property(str, get_midiOutDevice, set_midiOutDevice, notify=midiOutDeviceChanged)
    # END Property midiOutDevice

class sketchpad_channel(QObject):
    # Possible Values : "audio", "video"
    __type__ = "audio"
    jclient: jack.Client = None

    def __init__(self, id: int, song: QObject, parent: QObject = None):
        super(sketchpad_channel, self).__init__(parent)
        if sketchpad_channel.jclient is None:
            sketchpad_channel.jclient = jack.Client("sketchpad_channel")
        self.zynqtgui = zynthian_gui_config.zynqtgui
        self.__id__ = id
        self.__name__ = None
        self.__song__ = song
        self.__initial_volume__ = 0
        self.__volume__ = Zynthbox.AudioLevels.instance().tracks()[id].gainHandler()
        self.__volume__.gainChanged.connect(self.handleGainChanged)
        self.__initial_pan__ = 0
        self.__audio_level__ = -200
        self.__clips_model__ = [sketchpad_clips_model(song, self, 0), sketchpad_clips_model(song, self, 1), sketchpad_clips_model(song, self, 2), sketchpad_clips_model(song, self, 3), sketchpad_clips_model(song, self, 4)]
        for clip_model in self.__clips_model__:
            for clip in clip_model.__clips__:
                clip.path_changed.connect(self.sketchSlotsDataChanged.emit)
        self.__layers_snapshot = []
        self.master_volume = Zynthbox.Plugin.instance().dBFromVolume(self.zynqtgui.masterVolume/100)
        self.zynqtgui.masterVolumeChanged.connect(lambda: self.master_volume_changed())
        self.__connected_pattern__ = -1
        # self.__connected_sound__ = -1
        self.__chained_sounds__ = [-1, -1, -1, -1, -1]
        self.__chained_sounds_keyzones__ = [ sketchpad_keyzoneData(self), sketchpad_keyzoneData(self), sketchpad_keyzoneData(self), sketchpad_keyzoneData(self), sketchpad_keyzoneData(self) ]
        for slotIndex, keyzoneData in enumerate(self.__chained_sounds_keyzones__):
            keyzoneData.keyZoneStartChanged.connect(lambda idx=slotIndex, data=keyzoneData:self.handleChainedSoundsKeyzoneChanged(data, idx))
            keyzoneData.keyZoneEndChanged.connect(lambda idx=slotIndex, data=keyzoneData:self.handleChainedSoundsKeyzoneChanged(data, idx))
            keyzoneData.rootNoteChanged.connect(lambda idx=slotIndex, data=keyzoneData:self.handleChainedSoundsKeyzoneChanged(data, idx))
        self.chainedSoundsKeyzonesChanged.connect(self.__song__.schedule_save)
        self.__chained_fx = [None, None, None, None, None]
        self.__chained_sketch_fx = [None, None, None, None, None]
        self.zynqtgui.screens["layer"].layer_deleted.connect(self.layer_deleted)
        self.__muted__ = False
        self.__samples__ = []
        self.__sample_picking_style__ = "all"
        self.__trustExternalDeviceChannels__ = False
        self.__keyzone_mode__ = "all-full"
        self.__base_samples_dir__ = Path(self.__song__.sketchpad_folder) / 'wav' / 'sampleset'
        self.__color__ = self.zynqtgui.theme_chooser.trackColors[self.__id__]
        self.__selected_slot_obj = last_selected_obj_dto(self)
        self.__selected_slot_row__ = 0
        self.__selected_fx_slot_row = 0
        self.__selected_clip__ = 0
        Zynthbox.MidiRouter.instance().setSketchpadTrackTargetTrack(Zynthbox.ZynthboxBasics.Track(self.__id__), Zynthbox.ZynthboxBasics.Track(self.__id__));
        self.__externalSettings__ = external_mode_settings(self)
        self.__externalSettings__.somethingChanged.connect(self.__song__.schedule_save)
        self.__sound_json_snapshot__ = ""
        self.__sound_snapshot_changed = True
        self.route_through_global_fx = True
        self.__channel_sound_recording_ports = {
            0: [], # Left Channel
            1: []  # Right Channel
        }
        self.__audioTypeSettings__ = self.defaultAudioTypeSettings()
        self.volume_changed.connect(self.handleVolumeChanged)
        self.panChanged.connect(self.handlePanChanged)
        self.dryAmountChanged.connect(self.handleDryAmountChanged)
        self.wetFx1AmountChanged.connect(self.handleWetFx1AmountChanged)
        self.wetFx2AmountChanged.connect(self.handleWetFx2AmountChanged)
        self.synthPassthroughMixingChanged.connect(self.handleSynthPassthroughMixingChanged)
        self.fxPassthroughMixingChanged.connect(self.handleFxPassthroughMixingChanged)
        self.sketchFxPassthroughMixingChanged.connect(self.handleSketchFxPassthroughMixingChanged)
        self.track_type_changed.connect(self.handleAudioTypeSettingsChanged)
        self.track_type_changed.connect(self.selectedClipNamesChanged.emit, Qt.QueuedConnection)
        self.chainedFxChanged.connect(self.chainedFxChangedHandler, Qt.QueuedConnection)
        self.chainedSketchFxChanged.connect(self.chainedSketchFxChangedHandler, Qt.QueuedConnection)
        self.zynaddsubfx_midi_output = None
        self.zynaddsubfx_midi_input = None
        self.zynaddubfx_heuristic_connect_timer = QTimer(self)
        self.zynaddubfx_heuristic_connect_timer.setSingleShot(True)
        self.zynaddubfx_heuristic_connect_timer.setInterval(2000)
        self.zynaddubfx_heuristic_connect_timer.timeout.connect(self.zynaddubfx_heuristic_connect)

        self.__filter_cutoff_controllers = [MultiController(parent=self), MultiController(parent=self), MultiController(parent=self), MultiController(parent=self), MultiController(parent=self)]
        self.__filter_resonance_controllers = [MultiController(parent=self), MultiController(parent=self), MultiController(parent=self), MultiController(parent=self), MultiController(parent=self)]
        self.__fx_filter_cutoff_controllers = [MultiController(parent=self), MultiController(parent=self), MultiController(parent=self), MultiController(parent=self), MultiController(parent=self)]
        self.__fx_filter_resonance_controllers = [MultiController(parent=self), MultiController(parent=self), MultiController(parent=self), MultiController(parent=self), MultiController(parent=self)]
        self.__sketchfx_filter_cutoff_controllers = [MultiController(parent=self), MultiController(parent=self), MultiController(parent=self), MultiController(parent=self), MultiController(parent=self)]
        self.__sketchfx_filter_resonance_controllers = [MultiController(parent=self), MultiController(parent=self), MultiController(parent=self), MultiController(parent=self), MultiController(parent=self)]

        self.update_jack_port_timer = QTimer()
        self.update_jack_port_timer.setInterval(100)
        self.update_jack_port_timer.setSingleShot(True)
        self.update_jack_port_timer.timeout.connect(self.do_update_jack_port)

        self.fixed_layers_list_updated_handler_throttle = QTimer()
        self.fixed_layers_list_updated_handler_throttle.setInterval(100)
        self.fixed_layers_list_updated_handler_throttle.setSingleShot(True)
        self.fixed_layers_list_updated_handler_throttle.timeout.connect(self.fixed_layers_list_updated_handler)

        self.__chained_sounds_info_updater = QTimer()
        self.__chained_sounds_info_updater.setInterval(1)
        self.__chained_sounds_info_updater.setSingleShot(True)

        self.__synthRoutingDataUpdaterThrottle__ = QTimer()
        self.__synthRoutingDataUpdaterThrottle__.setInterval(1)
        self.__synthRoutingDataUpdaterThrottle__.setSingleShot(True)
        self.__synthRoutingDataUpdaterThrottle__.timeout.connect(self.updateSynthRoutingDataActual)

        self.zynqtgui.layer.layerPresetChanged.connect(self.layerPresetChangedHandler)
        self.zynqtgui.layer.layer_created.connect(self.layerCreatedHandler)

        # Create 5 clip objects for 5 samples per channel
        for i in range(0, Zynthbox.Plugin.instance().sketchpadSlotCount()):
            newSample = sketchpad_clip(self.id, i, i, self.__song__, self, True)
            # Explicitly set channel as it is a channelSample
            newSample.channel = self
            newSample.path_changed.connect(self.samples_changed.emit)
            self.__samples__.append(newSample)

        # All tracks should be multiclip by default
        self.__allowMulticlip__ = True
        self.__track_type__ = "synth"
        self.__track_routing_style__ = "standard"
        self.__routingData__ = {
            "sketchfx": [],
            "fx": [],
            "synth": []
            }
        for routingDataCategory in ["sketchfx", "fx", "synth"]:
            for slotIndex in range(0, Zynthbox.Plugin.instance().sketchpadSlotCount()):
                newRoutingData = sketchpad_engineRoutingData(self)
                newRoutingData.routingDataChanged.connect(self.__song__.schedule_save)
                self.__routingData__[routingDataCategory].append(newRoutingData)

        # self.chained_sounds_changed.connect(self.select_correct_layer)

        # Default snapshot has 3 preselected synths at midi channel 0, 1 and 2
        # When creating new sketchpad, set first 3 track's first slot to the default synths
        # When later any sketchpad is restored, chainedSounds will be reset
        if self.__id__ <= 2:
            self.__chained_sounds__[0] = self.__id__

        # Connect to default patterns on init
        # This will be overwritten by deserialize if user changed the value, so it is safe to always set the value
        if 0 <= self.__id__ <= 9:
            self.__connected_pattern__ = self.__id__

        self.__song__.scenesModel.selected_sketchpad_song_index_changed.connect(self.track_index_changed_handler)
        self.__song__.scenesModel.selected_scene_index_changed.connect(lambda: self.selectedClipNamesChanged.emit())

        # Emit occupiedSlotsChanged on dependant property changes
        self.chained_sounds_changed.connect(self.chained_sounds_changed_handler)
        try:
            self.__song__.scenesModel.selectedSketchpadSongIndexChanged.connect(lambda: self.occupiedSlotsChanged.emit())
        except:
            pass
        self.track_type_changed.connect(lambda: self.occupiedSlotsChanged.emit())
        self.samples_changed.connect(lambda: self.occupiedSlotsChanged.emit())

        self.selectedClipChanged.connect(lambda: self.clipsModelChanged.emit())
        self.selectedClipChanged.connect(lambda: self.scene_clip_changed.emit())
        self.zynqtgui.fixed_layers.list_updated.connect(self.fixed_layers_list_updated_handler_throttle.start)

        ### Proxy recordingPopupActive from zynthian_qt_gui
        self.zynqtgui.recordingPopupActiveChanged.connect(self.recordingPopupActiveChanged.emit)

        # Re-read sound snapshot json when a new snapshot is loaded
        self.zynqtgui.layer.snapshotLoaded.connect(self.snapshotLoadedHandler)
        # Update filter controllers when booting is complete
        self.zynqtgui.isBootingCompleteChanged.connect(self.update_filter_controllers)
        self.zynqtgui.isBootingCompleteChanged.connect(self.update_fx_filter_controllers)
        self.zynqtgui.isBootingCompleteChanged.connect(self.update_sketchfx_filter_controllers)

        def handlePassthroughClientDryAmountChanged(theSender):
            self.handlePassthroughClientSomethingChanged(theSender, "dryAmount", theSender.dryAmount())
        # def handlePassthroughClientWetFx1AmountChanged(theSender):
            # self.handlePassthroughClientSomethingChanged(theSender, "wetFx1Amount", theSender.wetFx1Amount())
        # def handlePassthroughClientWetFx2AmountChanged(theSender):
            # self.handlePassthroughClientSomethingChanged(theSender, "wetFx2Amount", theSender.wetFx2Amount())
        def handlePassthroughClientDryWetMixAmountChanged(theSender):
            self.handlePassthroughClientSomethingChanged(theSender, "dryWetMixAmount", theSender.dryWetMixAmount())
        def handlePassthroughClientPanAmountChanged(theSender):
            self.handlePassthroughClientSomethingChanged(theSender, "panAmount", theSender.panAmount())
        def handlePassthroughClientMutedChanged(theSender):
            self.handlePassthroughClientSomethingChanged(theSender, "muted", theSender.muted())
        self.__synthPassthroughClients = []
        for channelIndex in range(0, 16):
            synthPassthrough = Zynthbox.Plugin.instance().synthPassthroughClients()[channelIndex]
            self.__synthPassthroughClients.insert(channelIndex, synthPassthrough)
            synthPassthrough.panAmountChanged.connect(lambda theClient=synthPassthrough:handlePassthroughClientPanAmountChanged(theClient))
            synthPassthrough.dryAmountChanged.connect(lambda theClient=synthPassthrough:handlePassthroughClientDryAmountChanged(theClient))
        self.__trackMixerClient = Zynthbox.AudioLevels.instance().tracks()[self.id]
        self.__trackMixerClient.mutedChanged.connect(lambda theClient=self.__trackMixerClient:handlePassthroughClientMutedChanged(theClient), Qt.DirectConnection)
        self.__trackPassthroughClients = [None] * 10
        self.__fxPassthroughClients = []
        self.__sketchFxPassthroughClients = []
        for laneId in range(0, Zynthbox.Plugin.instance().sketchpadSlotCount()):
            channelClient = Zynthbox.Plugin.instance().trackPassthroughClient(self.__id__, 0, laneId)
            self.__trackPassthroughClients[laneId] = channelClient
            # Make the muted change handler a direct connection so playChannelSolo do not get updated while handling the muted state change
            # channelClient.mutedChanged.connect(lambda theClient=channelClient:handlePassthroughClientMutedChanged(theClient), Qt.DirectConnection)
            # channelClient.wetFx1AmountChanged.connect(lambda theClient=channelClient:handlePassthroughClientWetFx1AmountChanged(theClient))
            # channelClient.wetFx2AmountChanged.connect(lambda theClient=channelClient:handlePassthroughClientWetFx2AmountChanged(theClient))
            channelSketchClient = Zynthbox.Plugin.instance().trackPassthroughClient(self.__id__, 1, laneId)
            self.__trackPassthroughClients[laneId + 5] = channelSketchClient
            # Make the muted change handler a direct connection so playChannelSolo do not get updated while handling the muted state change
            # channelSketchClient.mutedChanged.connect(lambda theClient=channelSketchClient:handlePassthroughClientMutedChanged(theClient), Qt.DirectConnection)
            # channelSketchClient.wetFx1AmountChanged.connect(lambda theClient=channelSketchClient:handlePassthroughClientWetFx1AmountChanged(theClient))
            # channelSketchClient.wetFx2AmountChanged.connect(lambda theClient=channelSketchClient:handlePassthroughClientWetFx2AmountChanged(theClient))
            fxClient = Zynthbox.Plugin.instance().fxPassthroughClients()[self.__id__][laneId]
            self.__fxPassthroughClients.insert(laneId, fxClient)
            fxClient.dryWetMixAmountChanged.connect(lambda theClient=fxClient:handlePassthroughClientDryWetMixAmountChanged(theClient))
            fxClient.panAmountChanged.connect(lambda theClient=fxClient:handlePassthroughClientPanAmountChanged(theClient))

            sketchFxClient = Zynthbox.Plugin.instance().sketchFxPassthroughClients()[self.__id__][laneId]
            self.__sketchFxPassthroughClients.insert(laneId, sketchFxClient)
            sketchFxClient.dryWetMixAmountChanged.connect(lambda theClient=sketchFxClient:handlePassthroughClientDryWetMixAmountChanged(theClient))
            sketchFxClient.panAmountChanged.connect(lambda theClient=sketchFxClient:handlePassthroughClientPanAmountChanged(theClient))

        # Make sure our track's various mixer values are as they are supposed to be, before we potentially load any from disk
        self.set_muted(False)
        self.gainHandler.setGainDb(0)
        self.set_wetFx1Amount(0)
        self.set_wetFx2Amount(0)
        self.set_pan(0)

        # Update the keyzone data when the things that it depends on change
        self.keyZoneModeChanged.connect(self.updateKeyZones)
        self.samples_changed.connect(self.updateKeyZones) # Since this is emitted when each sample's path changes as well, just hook in here
        self.chained_sounds_changed.connect(self.updateKeyZones)

        # Connect to respective signals when any of the slot data changes
        self.slotsReordered.connect(self.sketchSlotsDataChanged.emit)
        self.externalAudioSourceChanged.connect(self.externalSlotsDataChanged.emit)
        self.externalMidiChannelChanged.connect(self.externalSlotsDataChanged.emit)
        self.__externalSettings__.midiOutDeviceChanged.connect(self.externalSlotsDataChanged.emit)

    def handlePassthroughClientSomethingChanged(self, theSender, theSomething, theValue):
        if theSender == self.__trackMixerClient:
            if theSomething == "muted":
                # Do not update channel muted state when being played on solo mode
                # If muted state is changed at all times, when setting solo mode, all channel's muted state is set to True
                # and hence disabling solo mode does
                if self.__song__.playChannelSolo == -1:
                    self.set_muted(theValue)
        elif theSender in self.__trackPassthroughClients:
            # if theSomething == "muted":
                # Do not update channel muted state when being played on solo mode
                # If muted state is changed at all times, when setting solo mode, all channel's muted state is set to True
                # and hence disabling solo mode does
                # if self.__song__.playChannelSolo == -1:
                    # self.set_muted(theValue)
            # elif theSomething == "wetFx1Amount":
                # self.set_wetFx1Amount(theValue)
            # elif theSomething == "wetFx2Amount":
                # self.set_wetFx2Amount(theValue)
            pass
        elif theSender in self.__synthPassthroughClients:
            clientIndex = self.__synthPassthroughClients.index(theSender)
            if clientIndex in self.__chained_sounds__:
                laneId = self.__chained_sounds__.index(clientIndex)
                self.set_passthroughValue("synthPassthrough", laneId, theSomething, theValue)
        elif theSender in self.__fxPassthroughClients:
            clientIndex = self.__fxPassthroughClients.index(theSender)
            if clientIndex in self.__chained_fx:
                laneId = self.__chained_fx.index(clientIndex)
                self.set_passthroughValue("fxPassthrough", laneId, theSomething, theValue)
        elif theSender in self.__sketchFxPassthroughClients:
            clientIndex = self.__sketchFxPassthroughClients.index(theSender)
            if clientIndex in self.__chained_sketch_fx:
                laneId = self.__chained_sketch_fx.index(clientIndex)
                self.set_passthroughValue("sketchFxPassthrough", laneId, theSomething, theValue)

    def handleChainedSoundsKeyzoneChanged(self, keyzoneData, slotIndex):
        Zynthbox.MidiRouter.instance().setZynthianSynthKeyzones(self.__chained_sounds__[slotIndex], keyzoneData.keyZoneStart, keyzoneData.keyZoneEnd, keyzoneData.rootNote)
        self.chainedSoundsKeyzonesChanged.emit()

    # If we want to eventually change to having multiple versions
    # again... this will letus do that without fundamentally
    # changing anything again
    def audioTypeSettingsKey(self):
        return "synth"

    def defaultAudioTypeSettings(self):
        # NOTE: This is old logic, but just keeping it around doesn't really hurt anything, if
        # we do want to split the settings out again at some point...
        # A set of mixing values for each of the main audio types. The logic being that
        # if you e.g. bounce a thing, you've also recorded the effects, and then playing back
        # that resulting sketch immediately, you'd end up pumping it through the same fx
        # setup, which while it might occasionally be serendipitous in a sound design sense,
        # it would be highly unexpected, and we kind of want to avoid that.
        mixingValues = {}
        for audioType in ["synth"]:
            audioTypeValues = {}
            # Channel passthrough defaults
            # There are five lanes per channel
            passthroughValues = []
            for i in range(0, 10):
                passthroughValues.append({
                    "panAmount": self.__initial_pan__,
                    "dryAmount": 1,
                    "wetFx1Amount": 0,
                    "wetFx2Amount": 0,
                })
            audioTypeValues["trackPassthrough"] = passthroughValues
            # Synth passthrough defaults
            passthroughValues = []
            for i in range(0, 5):
                passthroughValues.append({
                    "panAmount": self.__initial_pan__,
                    "dryAmount": 1,
                })
            audioTypeValues["synthPassthrough"] = passthroughValues
            # FX Passthrough defaults
            passthroughValues = []
            for i in range(0, 5):
                if audioType in ["synth", "sample", "sketch", "external"]:
                    # Since we have separate lanes for sound and sketch slots, default is to have 100% dry and 100% wet mixed for all modes
                    passthroughValues.append({
                        "panAmount": self.__initial_pan__,
                        "dryWetMixAmount": 1,
                    })
                else:
                    passthroughValues.append({
                        "panAmount": self.__initial_pan__,
                        "dryWetMixAmount": -1,
                    })
            audioTypeValues["fxPassthrough"] = passthroughValues
            # Sketch FX Passthrough defaults
            passthroughValues = []
            for i in range(0, 5):
                if audioType in ["synth", "sample", "sketch", "external"]:
                    # Since we have separate lanes for sound and sketch slots, default is to have 100% dry and 100% wet mixed for all modes
                    passthroughValues.append({
                        "panAmount": self.__initial_pan__,
                        "dryWetMixAmount": 1,
                    })
                else:
                    passthroughValues.append({
                        "panAmount": self.__initial_pan__,
                        "dryWetMixAmount": -1,
                    })
            audioTypeValues["sketchFxPassthrough"] = passthroughValues
            mixingValues[audioType] = audioTypeValues
        return mixingValues

    def layerPresetChangedHandler(self, layer_index):
        layer = self.zynqtgui.layer.layers[layer_index]
        if layer in self.chainedFx:
            self.chainedFxNamesChanged.emit()

    def layerCreatedHandler(self, midichannel):
        if midichannel in self.chainedSounds:
            self.chainedSoundsAcceptedChannelsChanged.emit()

    def snapshotLoadedHandler(self):
        self.__sound_snapshot_changed = True

    @Slot(int, int)
    def onClipEnabledChanged(self, trackIndex, clipId):
        clip = self.getClipsModelById(clipId).getClip(trackIndex)

        if clip is not None and clip.enabled is True:
            self.set_selected_clip(clipId)
            # We will now allow playing multiple clips of a sample-loop channel
            # allowMulticlip = self.trackType == "sample-loop" or (self.trackType == "sample-trig" and (self.keyZoneMode == "all-full" or self.keyZoneMode == "manual"))
            # logging.error(f"Allowing multiclip playback: {self.__allowMulticlip__}")
            if not self.__allowMulticlip__:
                for clipId in range(0, Zynthbox.Plugin.instance().sketchpadSlotCount()):
                    if clipId != self.__selected_clip__:
                        clipForDisabling = self.getClipsModelById(clipId).getClip(trackIndex)
                        # NOTE This will cause an infinite loop if we assign True here (see: the rest of this function)
                        if clipForDisabling is not None:
                            clipForDisabling.enabled = False

        self.selectedClipNamesChanged.emit()

    def track_index_changed_handler(self):
        self.scene_clip_changed.emit()
        self.selectedClipNamesChanged.emit()

    def chained_sounds_changed_handler(self):
        self.cache_bank_preset_lists()
        self.update_filter_controllers()
        self.occupiedSlotsChanged.emit()
        self.connectedSoundChanged.emit()
        self.connectedSoundNameChanged.emit()
        self.chainedSoundsNamesChanged.emit()
        self.chainedFxNamesChanged.emit()
        self.chainedSoundsAcceptedChannelsChanged.emit()
        self.zynqtgui.snapshot.schedule_save_last_state_snapshot()

    def chainedFxChangedHandler(self):
        self.zynqtgui.snapshot.schedule_save_last_state_snapshot()
        self.chainedFxNamesChanged.emit()
        self.update_fx_filter_controllers()

    def chainedSketchFxChangedHandler(self):
        # self.clearFxPassthroughForEmtpySlots()
        self.zynqtgui.snapshot.schedule_save_last_state_snapshot()
        self.chainedSketchFxNamesChanged.emit()
        self.update_sketchfx_filter_controllers()

    def fixed_layers_list_updated_handler(self):
        self.connectedSoundChanged.emit()
        self.connectedSoundNameChanged.emit()
        self.chainedSoundsNamesChanged.emit()
        self.chainedFxNamesChanged.emit()
        self.updateSynthRoutingData()

    def cache_bank_preset_lists(self):
        # Back up curlayer
        curlayer = self.zynqtgui.curlayer

        for midi_channel in self.chainedSounds:
            if midi_channel >= 0 and self.checkIfLayerExists(midi_channel):
                # Change curlayer to synth's layer and fill back/preset list
                self.zynqtgui.curlayer = self.zynqtgui.layer.layer_midi_map[midi_channel]
                logging.debug(f"Caching midi channel : channel({midi_channel}), layer({self.zynqtgui.curlayer})")
                self.zynqtgui.currentTaskMessage = f"Caching bank/preset lists for Track {self.name}"
                self.zynqtgui.bank.fill_list()
                self.zynqtgui.preset.fill_list()

        # Restore curlayer
        self.zynqtgui.curlayer = curlayer
        self.zynqtgui.bank.fill_list()
        self.zynqtgui.preset.fill_list()

    def update_filter_controllers(self):
        for index, midi_channel in enumerate(self.chainedSounds):
            self.__filter_cutoff_controllers[index].clear_controls()
            self.__filter_resonance_controllers[index].clear_controls()
            if midi_channel >= 0 and self.checkIfLayerExists(midi_channel):
                layer = self.zynqtgui.layer.layer_midi_map[midi_channel]
                synth_controllers_dict = layer.controllers_dict

                if layer.engine.plugin_info.cutoffControl != "" and layer.engine.plugin_info.cutoffControl in synth_controllers_dict:
                    self.__filter_cutoff_controllers[index].add_control(synth_controllers_dict[layer.engine.plugin_info.cutoffControl])
                elif "cutoff" in synth_controllers_dict:
                    self.__filter_cutoff_controllers[index].add_control(synth_controllers_dict["cutoff"])
                elif "filter_cutoff" in synth_controllers_dict:
                    self.__filter_cutoff_controllers[index].add_control(synth_controllers_dict["filter_cutoff"])

                if layer.engine.plugin_info.resonanceControl != "" and layer.engine.plugin_info.resonanceControl in synth_controllers_dict:
                    self.__filter_resonance_controllers[index].add_control(synth_controllers_dict[layer.engine.plugin_info.resonanceControl])
                elif "resonance" in synth_controllers_dict:
                    self.__filter_resonance_controllers[index].add_control(synth_controllers_dict["resonance"])
                elif "filter_resonance" in synth_controllers_dict:
                    self.__filter_resonance_controllers[index].add_control(synth_controllers_dict["filter_resonance"])

        self.filterCutoffControllersChanged.emit()
        self.filterResonanceControllersChanged.emit()

    def update_fx_filter_controllers(self):
        for index, layer in enumerate(self.chainedFx):
            self.__fx_filter_cutoff_controllers[index].clear_controls()
            self.__fx_filter_resonance_controllers[index].clear_controls()
            if layer is not None:
                synth_controllers_dict = layer.controllers_dict

                if layer.engine.plugin_info.cutoffControl != "" and layer.engine.plugin_info.cutoffControl in synth_controllers_dict:
                    self.__fx_filter_cutoff_controllers[index].add_control(synth_controllers_dict[layer.engine.plugin_info.cutoffControl])
                elif "cutoff" in synth_controllers_dict:
                    self.__fx_filter_cutoff_controllers[index].add_control(synth_controllers_dict["cutoff"])
                elif "filter_cutoff" in synth_controllers_dict:
                    self.__fx_filter_cutoff_controllers[index].add_control(synth_controllers_dict["filter_cutoff"])

                if layer.engine.plugin_info.resonanceControl != "" and layer.engine.plugin_info.resonanceControl in synth_controllers_dict:
                    self.__fx_filter_resonance_controllers[index].add_control(synth_controllers_dict[layer.engine.plugin_info.resonanceControl])
                elif "resonance" in synth_controllers_dict:
                    self.__fx_filter_resonance_controllers[index].add_control(synth_controllers_dict["resonance"])
                elif "filter_resonance" in synth_controllers_dict:
                    self.__fx_filter_resonance_controllers[index].add_control(synth_controllers_dict["filter_resonance"])

        self.fxFilterCutoffControllersChanged.emit()
        self.fxFilterResonanceControllersChanged.emit()

    def update_sketchfx_filter_controllers(self):
        for index, layer in enumerate(self.chainedSketchFx):
            self.__sketchfx_filter_cutoff_controllers[index].clear_controls()
            self.__sketchfx_filter_resonance_controllers[index].clear_controls()
            if layer is not None:
                synth_controllers_dict = layer.controllers_dict

                if layer.engine.plugin_info.cutoffControl != "" and layer.engine.plugin_info.cutoffControl in synth_controllers_dict:
                    self.__sketchfx_filter_cutoff_controllers[index].add_control(synth_controllers_dict[layer.engine.plugin_info.cutoffControl])
                elif "cutoff" in synth_controllers_dict:
                    self.__sketchfx_filter_cutoff_controllers[index].add_control(synth_controllers_dict["cutoff"])
                elif "filter_cutoff" in synth_controllers_dict:
                    self.__sketchfx_filter_cutoff_controllers[index].add_control(synth_controllers_dict["filter_cutoff"])

                if layer.engine.plugin_info.resonanceControl != "" and layer.engine.plugin_info.resonanceControl in synth_controllers_dict:
                    self.__sketchfx_filter_resonance_controllers[index].add_control(synth_controllers_dict[layer.engine.plugin_info.resonanceControl])
                elif "resonance" in synth_controllers_dict:
                    self.__sketchfx_filter_resonance_controllers[index].add_control(synth_controllers_dict["resonance"])
                elif "filter_resonance" in synth_controllers_dict:
                    self.__sketchfx_filter_resonance_controllers[index].add_control(synth_controllers_dict["filter_resonance"])

        self.sketchFxFilterCutoffControllersChanged.emit()
        self.sketchFxFilterResonanceControllersChanged.emit()

    def className(self):
        return "sketchpad_channel"

    def layer_deleted(self, chan : int):
        self.set_chained_sounds([-1 if x==chan else x for x in self.__chained_sounds__])

    def select_correct_layer(self):
        zynqtgui = self.__song__.get_metronome_manager().zynqtgui
        if self.checkIfLayerExists(zynqtgui.active_midi_channel):
            logging.info("### select_correct_layer : Reselect any available sound since it is removing current selected channel")
            try:
                zynqtgui.screens["layers_for_channel"].update_channel_sounds()
            except:
                pass
        else:
            logging.info("### select_correct_layer : Do not Reselect channel sound since it is not removing current selected channel")

    def master_volume_changed(self):
        self.master_volume = Zynthbox.Plugin.instance().dBFromVolume(self.zynqtgui.masterVolume/100)

    def stopAllClips(self):
        for clip_index in range(0, Zynthbox.Plugin.instance().sketchpadSlotCount()):
            for song_index in range(0, Zynthbox.Plugin.instance().sketchpadSongCount()):
                self.__song__.getClipById(self.__id__, song_index, clip_index).stop()

    def serialize(self):
        samplesObj = []
        for sample in self.__samples__:
            if sample.path is not None and len(sample.path) > 0:
                samplesObj.append(sample.serialize())
            else:
                samplesObj.append(None)

        return {"name": self.__name__,
                "color": self.__color__ if type(self.__color__) == str else self.__color__.name(),
                "volume": self.__volume__.gainDb(),
                "audioTypeSettings": self.__audioTypeSettings__,
                "connectedPattern": self.__connected_pattern__,
                "chainedSounds": self.__chained_sounds__,
                "allowMulticlip": self.__allowMulticlip__,
                "trackType": self.__track_type__,
                "trackRoutingStyle": self.__track_routing_style__,
                "fxRoutingData": [entry.serialize() for entry in self.__routingData__["fx"]],
                "synthRoutingData": [entry.serialize() for entry in self.__routingData__["synth"]],
                "sketchFxRoutingData": [entry.serialize() for entry in self.__routingData__["sketchfx"]],
                "synthKeyzoneData": [entry.serialize() for entry in self.__chained_sounds_keyzones__],
                "targetTrack": int(Zynthbox.MidiRouter.instance().sketchpadTrackTargetTracks()[self.__id__]),
                "externalMidiChannel" : self.__externalSettings__.midiChannel,
                "externalCaptureVolume" : self.__externalSettings__.captureVolume,
                "externalAudioSource": self.__externalSettings__.audioSource,
                "externalKeyValueStores": self.__externalSettings__.__keyValueStores__,
                "externalDefaultKeyValueStore": self.__externalSettings__.__defaultKeyValueStore__,
                "externalSelectedModule": self.__externalSettings__.selectedModule,
                "externalMidiOutDevice": self.__externalSettings__.midiOutDevice,
                "clips": [self.__clips_model__[clipId].serialize() for clipId in range(0, 5)],
                "selectedClip": self.__selected_clip__,
                "samples": samplesObj,
                "layers_snapshot": self.__layers_snapshot,
                "sample_picking_style": self.__sample_picking_style__,
                "trustExternalDeviceChannels": self.__trustExternalDeviceChannels__,
                "keyzone_mode": self.__keyzone_mode__,
                "routeThroughGlobalFX": self.route_through_global_fx,
                "synthSlotsData": self.synthSlotsData, # synthSlotsData is a list of strings. Just what we need
                "sampleSlotsData": [Path(f.path if f.path is not None else "").name for f in self.sampleSlotsData], # sampleSlotsData is a list of clips. Generate a list of names
                "sketchSlotsData": [Path(f.path if f.path is not None else "").name for f in self.sketchSlotsData], # sampleSlotsData is a list of clips. Generate a list of names
                "fxSlotsData": self.fxSlotsData, # fxSlotsData is a list of strings. Just what we need
                "externalSlotsData": self.externalSlotsData} # externalSlotsData is a list of strings. Just what we need

    def deserialize(self, obj, load_autosave=True):
        logging.debug(f"channel_deserialize : {load_autosave}")
        try:
            if "name" in obj:
                self.__name__ = obj["name"]
            if "color" in obj and obj["color"] != "#000000":
                self.set_color(obj["color"], force_set=True)
            else:
                self.set_color(self.zynqtgui.theme_chooser.trackColors[self.__id__])
            if "volume" in obj:
                self.set_volume(obj["volume"], True)
            if "connectedPattern" in obj:
                self.__connected_pattern__ = obj["connectedPattern"]
                self.set_connected_pattern(self.__connected_pattern__)
            if "chainedSounds" in obj:
                self.__chained_sounds__ = [-1, -1, -1, -1, -1] # When loading, we need to reset this forcibly to ensure things are updated fully
                self.set_chained_sounds(obj["chainedSounds"])

            if "allowMulticlip" in obj:
                self.set_allowMulticlip(obj["allowMulticlip"], True)
            else:
                self.set_allowMulticlip(False, True)

            # TODO : `channelAudioType` key is deprecated and has been renamed to `trackType`. Remove this fallback later
            if "channelAudioType" in obj:
                warnings.warn("`channelAudioType` key is deprecated (will be removed soon) and has been renamed to `trackType`. Update any existing references to avoid issues with loading sketchpad", DeprecationWarning)
                self.__track_type__ = obj["channelAudioType"]
                self.set_track_type(self.__track_type__, True)
            if "trackType" in obj:
                self.__track_type__ = obj["trackType"]
                self.set_track_type(self.__track_type__, True)

            _audioTypeSettings = self.defaultAudioTypeSettings()
            if "audioTypeSettings" in obj:
                _audioTypeSettings.update(obj["audioTypeSettings"])
            # Set audioTypeSettings even if not found in json to set the default values and emit respective signals
            self.setAudioTypeSettings(_audioTypeSettings)

            # TODO : `channelRoutingStyle` key is deprecated and has been renamed to `trackRoutingStyle`. Remove this fallback later
            if "channelRoutingStyle" in obj:
                warnings.warn("`channelRoutingStyle` key is deprecated (will be removed soon) and has been renamed to `trackRoutingStyle`. Update any existing references to avoid issues with loading sketchpad", DeprecationWarning)
                self.set_track_routing_style(obj["channelRoutingStyle"], True)
            else:
                self.set_track_routing_style("standard", True)
            if "trackRoutingStyle" in obj:
                self.set_track_routing_style(obj["trackRoutingStyle"], True)
            else:
                self.set_track_routing_style("standard", True)

            if "sketchFxRoutingData" in obj:
                for slotIndex, routingData in enumerate(obj["sketchFxRoutingData"]):
                    if slotIndex > 4:
                        logging.error("Error during deserialization: sketchFxRoutingData has too many entries")
                        break
                    self.__routingData__["sketchfx"][slotIndex].deserialize(routingData)
            self.sketchFxRoutingDataChanged.emit()
            if "fxRoutingData" in obj:
                for slotIndex, routingData in enumerate(obj["fxRoutingData"]):
                    if slotIndex > 4:
                        logging.error("Error during deserialization: fxRoutingData has too many entries")
                        break
                    self.__routingData__["fx"][slotIndex].deserialize(routingData)
            self.fxRoutingDataChanged.emit()
            if "synthRoutingData" in obj:
                for slotIndex, routingData in enumerate(obj["synthRoutingData"]):
                    if slotIndex > 4:
                        logging.error("Error during deserialization: synthRoutingData has too many entries")
                        break
                    self.__routingData__["synth"][slotIndex].deserialize(routingData)
            self.synthRoutingDataChanged.emit()
            if "synthKeyzoneData" in obj:
                for slotIndex, keyzoneData in enumerate(obj["synthKeyzoneData"]):
                    if slotIndex > 4:
                        logging.error("Error during deserialization: synthKeyzoneData has too many entries")
                        break
                    self.__chained_sounds_keyzones__[slotIndex].deserialize(keyzoneData)
            else:
                for entry in self.__chained_sounds_keyzones__:
                    entry.clear()
            self.chainedSoundsKeyzonesChanged.emit()

            if "targetTrack" in obj:
                Zynthbox.MidiRouter.instance().setSketchpadTrackTargetTrack(Zynthbox.ZynthboxBasics.Track(self.__id__), Zynthbox.ZynthboxBasics.Track(obj["targetTrack"]))
            else:
                Zynthbox.MidiRouter.instance().setSketchpadTrackTargetTrack(Zynthbox.ZynthboxBasics.Track(self.__id__), Zynthbox.ZynthboxBasics.Track(self.__id__))

            if "externalMidiChannel" in obj:
                self.set_externalMidiChannel(obj["externalMidiChannel"])
            if "externalAudioSource" in obj:
                self.set_externalAudioSource(obj["externalAudioSource"])
            if "externalCaptureVolume" in obj:
                self.set_externalCaptureVolume(obj["externalCaptureVolume"])
            if "externalDefaultKeyValueStore" in obj:
                self.__externalSettings__.__defaultKeyValueStore__ = obj["externalDefaultKeyValueStore"]
                self.__externalSettings__.keyValueStoreChanged.emit()
            if "externalKeyValueStores" in obj:
                self.__externalSettings__.__keyValueStores__ = obj["externalKeyValueStores"]
                self.__externalSettings__.keyValueStoreChanged.emit()
            if "externalSelectedModule" in obj:
                self.__externalSettings__.selectedModule = obj["externalSelectedModule"]
            if "externalMidiOutDevice" in obj:
                self.__externalSettings__.midiOutDevice = obj["externalMidiOutDevice"]
            if not "samples" in obj and (Path(self.bankDir) / "sample-bank.json").exists():
                # TODO : `sample-bank.json` file is deprecated. sample data is now stored in sketchpad json. Remove this fallback later
                # Read sample-bank.json and inject sample data to all saved versions as it should have with new latest sketchpad structure
                warnings.warn("`sample-bank.json` is deprecated (will be removed soon) and is now stored in sketchpad json. Update any existing references to avoid issues with loading sketchpad", DeprecationWarning)
                with open(Path(self.bankDir) / "sample-bank.json", "r") as f:
                    samples_obj = json.load(f)
                for sketchpad_file in Path(self.__song__.sketchpad_folder).glob("*.sketchpad.json"):
                    logging.debug(f"Injecting sample-bank to sketchpad {sketchpad_file}")
                    with open(sketchpad_file, "r+") as f:
                        _obj = json.load(f)
                        _obj["tracks"][self.id]["samples"] = samples_obj
                        f.seek(0)
                        f.write(json.dumps(_obj))
                        f.flush()
                        os.fsync(f.fileno())
                # Inject samples to current sketchpad data
                obj["samples"] = samples_obj
                # Delete sample-bank.json as we now have modified existing sketchpad files
                (Path(self.bankDir) / "sample-bank.json").unlink(missing_ok=True)
            if "samples" in obj:
                bank_dir = Path(self.bankDir)
                for i, clip in enumerate(obj["samples"]):
                    if clip is None:
                        self.__samples__[i].clear()
                    else:
                        if (bank_dir / clip["path"]).exists():
                            self.__samples__[i].deserialize(clip)
                self.samples_changed.emit()
            if "clips" in obj:
                for clipId, clip_model in enumerate(self.__clips_model__):
                    self.__clips_model__[clipId].deserialize(obj["clips"][clipId], clipId)
                    for clip in clip_model.__clips__:
                        clip.path_changed.connect(self.sketchSlotsDataChanged.emit)
            if "selectedClip" in obj:
                self.set_selected_clip(obj["selectedClip"], force_set=True)
            else:
                self.set_selected_clip(0, force_set=True)
            if "layers_snapshot" in obj:
                self.__layers_snapshot = obj["layers_snapshot"]
                self.sound_data_changed.emit()
            if "sample_picking_style" in obj:
                self.set_samplePickingStyle(obj["sample_picking_style"])
            if "trustExternalDeviceChannels" in obj:
                self.set_trustExternalDeviceChannels(obj["trustExternalDeviceChannels"])
            else:
                self.set_trustExternalDeviceChannels(False)
            if "keyzone_mode" in obj:
                self.__keyzone_mode__ = obj["keyzone_mode"]
                self.keyZoneModeChanged.emit();
            if "routeThroughGlobalFX" in obj:
                self.set_routeThroughGlobalFX(obj["routeThroughGlobalFX"], True)
                # Run autoconnect to update jack connections when routeThrouGlobalFX is set
                self.zynqtgui.zynautoconnect()
            if "synthSlotsData" not in obj or "sampleSlotsData" not in obj or "sketchSlotsData" not in obj or "fxSlotsData" not in obj or "externalSlotsData" not in obj:
                # Sketchpad does not have slots data. Schedule autosave explicitly to save the updated sketchpad json
                # TODO : Rmove this check after a considerable amount of time when supposedly all the old sketchpads are migrated
                self.__song__.schedule_save()
            # Finally, make sure our selected slot value makes some decent amount of sense
            self.selectFirstAndBestSlot()
        except Exception as e:
            logging.error(f"Error during channel deserialization: {e}")
            traceback.print_exception(None, e, e.__traceback__)

    def selectFirstAndBestSlot(self):
        pickedASlot = False
        if self.trackType == "synth" or self.trackType == "sample-trig":
            for slotIndex, chainedSound in enumerate(self.__chained_sounds__):
                if chainedSound > -1:
                    self.__selected_slot_obj.setTo("TracksBar_synthslot", slotIndex, None)
                    pickedASlot = True
                    break
            if pickedASlot == False:
                for slotIndex, sample in enumerate(self.__samples__):
                    if sample.path is not None and len(sample.path) > 0:
                        self.__selected_slot_obj.setTo("TracksBar_sampleslot", slotIndex, None)
                        pickedASlot = True
                        break
            if pickedASlot == False:
                for slotIndex, fx in enumerate(self.__chained_fx):
                    if fx is not None:
                        self.__selected_slot_obj.setTo("TracksBar_fxslot", slotIndex, None)
                        pickedASlot = True
                        break
            if pickedASlot == False:
                self.__selected_slot_obj.setTo("TracksBar_synthslot", 0, None)
        elif self.trackType == "sample-loop":
            for slotIndex in range(Zynthbox.Plugin.instance().sketchpadSlotCount()):
                clips_model = self.getClipsModelById(slotIndex)
                clip = clips_model.getClip(self.__song__.scenesModel.selectedSketchpadSongIndex)
                if clip.path is not None and len(clip.path) > 0:
                    self.__selected_slot_obj.setTo("TracksBar_sketchslot", slotIndex, None)
                    pickedASlot = True
                    break
            if pickedASlot == False:
                for slotIndex, fx in enumerate(self.__chained_sketch_fx):
                    if fx is not None:
                        self.__selected_slot_obj.setTo("TracksBar_sketchfxslot", slotIndex, None)
                        pickedASlot = True
                        break
            if pickedASlot == False:
                self.__selected_slot_obj.setTo("TracksBar_sketchslot", 0, None)
        elif self.trackType == "external":
            self.__selected_slot_obj.setTo("TracksBar_externalslot", 0, None)

    def set_layers_snapshot(self, snapshot):
        self.__layers_snapshot = snapshot
        self.sound_data_changed.emit()

    def get_layers_snapshot(self):
        return self.__layers_snapshot

    def playable(self):
        return False
    playable = Property(bool, playable, constant=True)

    def recordable(self):
        return False
    recordable = Property(bool, recordable, constant=True)

    def clearable(self):
        return True
    clearable = Property(bool, clearable, constant=True)

    def deletable(self):
        return False
    deletable = Property(bool, deletable, constant=True)

    def nameEditable(self):
        return True
    nameEditable = Property(bool, nameEditable, constant=True)

    def id(self):
        return self.__id__
    id = Property(int, id, constant=True)

    @Signal
    def sound_data_changed(self):
        pass

    def get_soundData(self):
        return self.__layers_snapshot
    soundData = Property('QVariantList', get_soundData, notify=sound_data_changed)

    @Slot()
    def update_jack_port(self, run_in_thread=True):
        if self.zynqtgui is not None and not self.zynqtgui.get_isBootingComplete():
            # logging.debug("Booting in progress. Ignoring port update request")
            # QTimer.singleShot(1000, self.update_jack_port)
            pass
        else:
            self.zynqtgui.currentTaskMessage = f"Updating jack ports for Track `{self.name}`"

            # If run_in_thread is set to False, directly call the method
            # This will allow startup process to wait till all ports are updated before displaying splash screen
            if run_in_thread:
                QMetaObject.invokeMethod(self.update_jack_port_timer, "start", Qt.QueuedConnection)
            else:
                self.do_update_jack_port(run_in_thread)

    def do_update_jack_port(self, run_in_thread=True):
        def task(zynqtgui, channel):
            try:
                synth_ports = {
                    0: [], # Left channel
                    1: []  # Right channel
                }

                if self.trackRoutingStyle == "standard":
                    if self.channelHasFx:
                        # If there is fx, only the last FXPassthrough's dry out and the last fx out needs to be recorded
                        for index, fx in enumerate(self.chainedFx):
                            if fx is not None:
                                lastFxIndex = index
                        fxPorts = sketchpad_channel.jclient.get_ports(name_pattern=self.chainedFx[lastFxIndex].engine.jackname, is_output=True, is_audio=True, is_physical=False)
                        # If fx is mono, record both left and right channels from same output port
                        if len(fxPorts) == 1:
                            fxPorts.append(fxPorts[0])
                        for channel in range(2):
                            synth_ports[channel].append(f"FXPassthrough-lane{lastFxIndex}:Channel{self.id + 1}-sound-dryOut{'Left' if channel == 0 else 'Right'}")
                            synth_ports[channel].append(fxPorts[channel].name)
                    else:
                        # If there is no fx, then TrackPassthrough dry signal needs to be recorded
                        for channel in range(2):
                            # All sounds are routed through lane 1 in standard mode
                            synth_ports[channel].append(f"TrackPassthrough:Channel{self.id + 1}-lane1-dryOut{'Left' if channel == 0 else 'Right'}")
                elif self.trackRoutingStyle == "one-to-one":
                    for lane in range(1, 6):
                        if self.chainedFx[lane - 1] is None:
                            # lane has no FX. Record lane dryOut
                            for channel in range(2):
                                synth_ports[channel].append(f"TrackPassthrough:Channel{self.id + 1}-lane{lane}-dryOut{'Left' if channel == 0 else 'Right'}")
                        else:
                            # lane has FX. Connect FXPassthrough dryOut and fx out
                            fxPorts = sketchpad_channel.jclient.get_ports(name_pattern=self.chainedFx[lane - 1].engine.jackname, is_output=True, is_audio=True, is_physical=False)
                            # If fx is mono, record both left and right channels from same output port
                            if len(fxPorts) == 1:
                                fxPorts.append(fxPorts[0])
                            for channel in range(2):
                                synth_ports[channel].append(f"FXPassthrough-lane{lane}:Channel{self.id + 1}-sound-dryOut{'Left' if channel == 0 else 'Right'}")
                                synth_ports[channel].append(fxPorts[channel].name)

                # logging.debug(f"channelSoundRecordingPorts : {synth_ports}")
                self.set_channelSoundRecordingPorts(synth_ports)
            except Exception as e:
                # If jack port update fails, queue it for another run in the future
                logging.exception(f"Error trying to update jack port for channel {self.name} : str({e})")
                QMetaObject.invokeMethod(self.update_jack_port_timer, "start", Qt.QueuedConnection)


        # Do the task in a thread only if run_in_thread is set to True
        # This will allow startup process to wait till all ports are updated before displaying splash screen
        if run_in_thread:
            worker_thread = threading.Thread(target=task, args=(self.zynqtgui, self))
            worker_thread.start()
        else:
            task(self.zynqtgui, self)

    @Slot(None)
    def clear(self):
        channel = self.__song__.channelsModel.getChannel(self.__id__)
        clipsModel = channel.clipsModel

        logging.debug(f"Channel {channel} ClipsModel {clipsModel}")

        for clip_index in range(0, clipsModel.count):
            logging.debug(f"Channel {self.__id__} Clip {clip_index}")
            clip: sketchpad_clip = clipsModel.getClip(clip_index)
            logging.debug(
                f"Clip : clip.row({clip.row}), clip.col({clip.col}), clip({clip})")
            clip.clear()

    ### BEGIN Property name
    @Signal
    def __name_changed__(self):
        pass

    def name(self):
        if self.__name__ is None:
            return f"T{self.__id__ + 1}"
        else:
            return self.__name__

    def set_name(self, name):
        if name != f"Ch{self.__id__ + 1}":
            self.__name__ = name
            self.__name_changed__.emit()
            self.__song__.schedule_save()

    name = Property(str, name, set_name, notify=__name_changed__)
    ### END Property name

    ### BEGIN Property color
    def get_color(self):
        return self.__color__

    def set_color(self, color, force_set=False):
        if self.__color__ != color or force_set:
            if type(color) == str:
                self.__color__ = QColor(color)
            else:
                self.__color__ = color
            self.colorChanged.emit()
            self.__song__.schedule_save()

    colorChanged = Signal()

    color = Property('QColor', get_color, set_color, notify=colorChanged)
    ### END Property color

    @Signal
    def volume_changed(self):
        pass

    @Slot(None)
    def handleVolumeChanged(self):
        self.handlePanChanged()
        self.handleDryAmountChanged()
        self.handleWetFx1AmountChanged()
        self.handleWetFx2AmountChanged()

    def get_volume(self):
        return self.__volume__.gainDb()

    def set_volume(self, volume:int, force_set=False):
        if self.__volume__.gainDb() != round(volume) or force_set is True:
            self.__volume__.setGainDb(round(volume))

    volume = Property(int, get_volume, set_volume, notify=volume_changed)

    ### BEGIN Property gainHandler
    def handleGainChanged(self):
        self.volume_changed.emit()
        self.__song__.schedule_save()
        Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_TRACK_VOLUME", -1, Zynthbox.ZynthboxBasics.Track(self.__id__), Zynthbox.ZynthboxBasics.Slot.AnySlot, np.interp(self.__volume__.gainAbsolute(), (0, 1), (0, 127)))
        if self.zynqtgui.sketchpad.selectedTrackId == self.__id__:
            Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_TRACK_VOLUME", -1, Zynthbox.ZynthboxBasics.Track.CurrentTrack, Zynthbox.ZynthboxBasics.Slot.AnySlot, np.interp(self.__volume__.gainAbsolute(), (0, 1), (0, 127)))
    def get_gainHandler(self):
        return self.__volume__
    gainHandler = Property(QObject, get_gainHandler, constant=True)
    ### END Property gainHandler

    ### Property initialPan
    def get_initial_pan(self):
        return self.__initial_pan__
    initialPan = Property(float, get_initial_pan, constant=True)
    ### END Property initialPan

    ### Property initialVolume
    def get_initial_volume(self):
        return self.__initial_volume__
    initialVolume = Property(int, get_initial_volume, constant=True)
    ### END Property initialVolume

    def type(self):
        return self.__type__
    type = Property(str, type, constant=True)

    # Get the clip model for the specified clip ID
    @Slot(int, result=QObject)
    def getClipsModelById(self, clipId):
        return self.__clips_model__[clipId]
    ### BEGIN Property clipsModel
    # This is the clips model associated with the currently selected clip
    def clipsModel(self):
        return self.__clips_model__[self.__selected_clip__]
    clipsModelChanged = Signal()
    clipsModel = Property(QObject, clipsModel, notify=clipsModelChanged)
    ### END Property clipsModel

    ### BEGIN Property clips
    def getClips(self):
        return self.__clips_model__
    clipsChanged = Signal()
    clips = Property('QVariantList', getClips, notify=clipsChanged)
    ### END Property clips

    @Slot(None)
    def delete(self):
        self.__song__.channelsModel.delete_channel(self)

    def set_id(self, new_id):
        self.__id__ = new_id
        self.__name_changed__.emit()


    @Signal
    def audioLevelChanged(self):
        pass

    def get_audioLevel(self):
        return self.__audio_level__

    def set_audioLevel(self, leveldB):
        self.__audio_level__ = leveldB + self.__volume__.gainDb() + self.master_volume
        self.audioLevelChanged.emit()

    audioLevel = Property(float, get_audioLevel, set_audioLevel, notify=audioLevelChanged)

    @Slot(None, result=bool)
    def isEmpty(self):
        is_empty = True

        for songIndex in range(0, self.clipsModel.count):
            clip: sketchpad_clip = self.clipsModel.getClip(songIndex)
            if clip.path is not None and len(clip.path) > 0:
                is_empty = False
                break

        return is_empty

    # source : Source sketchpad_channel object
    @Slot(QObject)
    def copyFrom(self, source):
        for clipId in range(Zynthbox.Plugin.instance().sketchpadSlotCount()):
            # Copy all clips from source channel to self
            for songIndex in range(0, self.clips[clipId].count):
                self.clips[clipId].getClip(songIndex).copyFrom(source.clips[clipId].getClip(songIndex))

        for sample_id in range(5):
            self.samples[sample_id].copyFrom(source.samples[sample_id])

    @Slot(int, result=bool)
    def createChainedSoundInNextFreeLayer(self, index):
        zynqtgui = self.__song__.get_metronome_manager().zynqtgui
        assigned_layers = [x for x in zynqtgui.screens["layer"].layer_midi_map.keys()]
        next_free_layer = -1

        logging.debug(f"Already Assigned layers : {assigned_layers}")

        for i in range(0, 15):
            if i not in assigned_layers:
                next_free_layer = i
                break

        if next_free_layer == -1:
            return False
        else:
            logging.debug(f"Next free layer : {next_free_layer}")
            zynqtgui.screens["fixed_layers"].activate_index(next_free_layer)

            for channel_id in range(self.__song__.channelsModel.count):
                channel = self.__song__.channelsModel.getChannel(channel_id)
                channel.__chained_sounds__ = [-1 if x == next_free_layer else x for x in channel.__chained_sounds__]

            self.__chained_sounds__[index] = next_free_layer
            self.chained_sounds_changed.emit()
            self.__song__.schedule_save()

            return True

    def getFreeLayers(self):
        zynqtgui = self.__song__.get_metronome_manager().zynqtgui
        assigned_layers = [x for x in zynqtgui.screens["layer"].layer_midi_map.keys()]
        free_layers = []

        for x in range(0, 16):
            if x not in assigned_layers:
                free_layers.append(x)

        return free_layers

    @Slot(int, result=str)
    def getLayerNameByMidiChannel(self, channel):
        if self.checkIfLayerExists(channel):
            try:
                layer = self.__song__.get_metronome_manager().zynqtgui.screens["fixed_layers"].list_data[channel]
                return layer[2]
            except:
                return ""
        else:
            return ""

    @Slot(int, result=str)
    def getEffectsNameByMidiChannel(self, channel):
        if self.checkIfLayerExists(channel):
            try:
                fx = self.__song__.get_metronome_manager().zynqtgui.screens["fixed_layers"].list_metadata[channel]
                return fx["effects_label"]
            except:
                return ""
        else:
            return ""

    @Slot(int, result=bool)
    def checkIfLayerExists(self, channel):
        return channel in self.__song__.get_metronome_manager().zynqtgui.screens["layer"].layer_midi_map.keys()

    @Slot(int, result='QVariantList')
    def chainForLayer(self,chan):
        chain = []
        for i in range (16):
            if zynqtgui.screens['layer'].is_midi_cloned(chan, i) or zynqtgui.screens['layer'].is_midi_cloned(i, chan):
                cain.append(i)
        return chain

    @Slot(int, result='QVariantList')
    def printableChainForLayer(self,chan):
        chain = ""
        for i in range (16):
            if zynqtgui.screens['layer'].is_midi_cloned(chan, i) or zynqtgui.screens['layer'].is_midi_cloned(i, chan):
                cain.append(" {}".format(i))
        return chain

    @Slot(int)
    def selectSound(self, index):
        zynqtgui = self.__song__.get_metronome_manager().zynqtgui

        if index in self.__chained_sounds__:
            zynqtgui.screens["fixed_layers"].activate_index(index)
        else:
            chained = [index]
            for i in range (16):
                if i != index and zynqtgui.screens['layer'].is_midi_cloned(index, i) or zynqtgui.screens['layer'].is_midi_cloned(i, index):
                    chained.append(i)
                    if len(chained) >= 5:
                        break
            while len(chained) < 5:
                chained.append(-1)
            self.set_chained_sounds(chained)
            logging.debug(chained)

            #sounds_to_clone = []
            #for m_sound in self.__chained_sounds__:
                #if m_sound > -1:
                    #sounds_to_clone.append(m_sound)

            #for _index in range(0, len(sounds_to_clone) - 1):
                #logging.error(f"Removing cloned layers {sounds_to_clone[_index], sounds_to_clone[_index + 1]}")
                #zynqtgui.screens['layer'].remove_clone_midi(sounds_to_clone[_index], sounds_to_clone[_index + 1])
                #zynqtgui.screens['layer'].remove_clone_midi(sounds_to_clone[_index + 1], sounds_to_clone[_index])

            #self.set_chained_sounds([index, -1, -1, -1, -1])
            #zynqtgui.screens["fixed_layers"].activate_index(index)

        self.chained_sounds_changed.emit()

    @Slot(None)
    def clearChainedSoundsWithoutCloning(self):
        self.__chained_sounds__ = [-1, -1, -1, -1, -1]

        try: #can be called before creation
            zynqtgui = self.__song__.get_metronome_manager().zynqtgui
            zynqtgui.screens['fixed_layers'].fill_list() #This will update *also* layers for channel
            zynqtgui.screens['layers_for_channel'].activate_index(0)
            zynqtgui.set_curlayer(None)
        except Exception as e:
            logging.error(f"Error filling list : {str(e)}")

        self.__song__.schedule_save()
        self.chained_sounds_changed.emit()

    ### Property chainedSoundNames
    ### An array of 5 elements with sound name if available or empty string
    def get_chainedSoundsNames(self):
        res = []

        for sound in self.chainedSounds:
            if sound >= 0 and self.checkIfLayerExists(sound):
                res.append(self.getLayerNameByMidiChannel(sound))
            else:
                res.append("")

        return res

    chainedSoundsNamesChanged = Signal()

    chainedSoundsNames = Property('QVariantList', get_chainedSoundsNames, notify=chainedSoundsNamesChanged)

    ### END Property chainedSoundNames

    ### Property connectedPattern
    def get_connected_pattern(self):
        return self.__connected_pattern__
    def set_connected_pattern(self, pattern):
        if self.__connected_pattern__ == pattern:
            return
        self.__connected_pattern__ = pattern
        self.__song__.schedule_save()
        self.connected_pattern_changed.emit()
        self.__song__.channelsModel.connected_patterns_count_changed.emit()
    connected_pattern_changed = Signal()
    connectedPattern = Property(int, get_connected_pattern, set_connected_pattern, notify=connected_pattern_changed)
    ### END Property connectedPattern

    ### Property chainedSounds
    def get_chained_sounds(self):
        return self.__chained_sounds__

    @Slot(int)
    def remove_and_unchain_sound(self, chan, cb=None):
        def task():
            self.zynqtgui.screens['layers_for_channel'].fill_list()
            layer_to_delete = self.zynqtgui.layer.layer_midi_map[chan]
            self.zynqtgui.layer.remove_root_layer(self.zynqtgui.layer.root_layers.index(layer_to_delete))
            self.select_correct_layer()
            # Ensure we clear the passthrough (or it'll retain its value)
            passthroughClient = Zynthbox.Plugin.instance().synthPassthroughClients()[chan]
            self.__song__.clearPassthroughClient(passthroughClient)
            passthroughClient.setPanAmount(self.__initial_pan__)
            passthroughClient.setDryAmount(1)
            self.zynqtgui.screens['snapshot'].schedule_save_last_state_snapshot()
            self.__song__.schedule_save()
            self.chained_sounds_changed.emit()
            if cb is not None:
                cb()
            self.zynqtgui.end_long_task()
        self.__chained_sounds_keyzones__[self.selectedSlotRow].clear()
        self.zynqtgui.do_long_task(task, f"Removing {self.chainedSoundsNames[self.selectedSlotRow]} from slot {self.selectedSlotRow + 1} on Track {self.name}")

    def updateSynthRoutingData(self):
        self.__synthRoutingDataUpdaterThrottle__.start()

    def updateSynthRoutingDataActual(self):
        # logging.error(f"Updating routing data for {self.name} with chained sounds {self.__chained_sounds__}")
        for position in range(0, 5):
            newEntry = self.__chained_sounds__[position]
            if newEntry > -1 and self.checkIfLayerExists(newEntry):
                # if any engines have been added, ensure the synth engine data slot has that information
                newLayer = self.zynqtgui.layer.layer_midi_map[newEntry]
                # logging.error(f"Updating data container for {newLayer.engine.name}")
                dataContainer = self.__routingData__["synth"][position]
                dataContainer.name = self.getLayerNameByMidiChannel(newEntry)
                audioInPorts = self.jclient.get_ports(newLayer.get_jackname(), is_audio=True, is_input=True)
                for port in audioInPorts:
                    # logging.error(f"Adding audio in port for {port}")
                    dataContainer.addAudioInPort(dataContainer.humanReadablePortName(port.shortname), port.name)
                midiInPorts = self.jclient.get_ports(newLayer.get_jackname(), is_midi=True, is_input=True)
                for port in midiInPorts:
                    # logging.error(f"Adding midi in port for {port}")
                    dataContainer.addMidiInPort(dataContainer.humanReadablePortName(port.shortname), port.name)
            elif newEntry == -1: # Don't clear data unless the position is actually cleared
                # if any engines have been removed, clear out the equivalent synth engine data slot
                self.__routingData__["synth"][position].clear()

    def set_chained_sounds(self, sounds, updateRoutingData:bool = True):
        logging.debug(f"set_chained_sounds : {sounds}")
        update_jack_ports = True

        # Stop all playing notes
        for old_chan in self.__chained_sounds__:
            if old_chan > -1:
                self.zynqtgui.raw_all_notes_off_chan(self.id)

        chained_sounds = [-1, -1, -1, -1, -1]
        for i, sound in enumerate(sounds):
            if sound not in chained_sounds:
                chained_sounds[i] = sound

        if chained_sounds == self.__chained_sounds__:
            update_jack_ports = False

        oldChainedSounds = self.__chained_sounds__
        self.__chained_sounds__ = chained_sounds

        try: #can be called before creation
            self.zynqtgui.screens['layers_for_channel'].fill_list()
            if self.connectedSound >= 0:
                self.zynqtgui.screens['layers_for_channel'].layer_selection_consistency_check()
            else:
                self.zynqtgui.screens['layers_for_channel'].select_action(
                    self.zynqtgui.screens['layers_for_channel'].current_index)
        except:
            pass

        if update_jack_ports:
            self.update_jack_port()

        if updateRoutingData:
            self.updateSynthRoutingData()

        self.__sound_snapshot_changed = True
        if self.zynqtgui.isBootingComplete:
            self.__song__.schedule_save()
        self.chained_sounds_changed.emit()

    chained_sounds_changed = Signal()
    chainedSounds = Property('QVariantList', get_chained_sounds, set_chained_sounds, notify=chained_sounds_changed)
    ### END Property chainedSounds

    ### Property chainedFx
    def get_chainedFx(self):
        return self.__chained_fx

    def set_chainedFx(self, fx):
        if fx != self.__chained_fx:
            self.__chained_fx = fx
            for slot_index, layer in enumerate(fx):
                self.updateChainedFxEngineData(slot_index, layer)
            self.update_jack_port()
            self.__sound_snapshot_changed = True
            self.__song__.schedule_save()
            self.chainedFxChanged.emit()
            self.chainedFxNamesChanged.emit()

    # Add or replace a fx layer at slot_row to fx chain
    # If explicit slot_row is not set then selected slot row is used
    def setFxToChain(self, layer, slot_row=-1):
        if slot_row == -1:
            slot_row = self.__selected_fx_slot_row

        if self.__chained_fx[slot_row] is not None:
            self.zynqtgui.zynautoconnect_acquire_lock()
            self.__chained_fx[slot_row].reset()
            self.zynqtgui.zynautoconnect_release_lock()
            self.zynqtgui.screens['engine'].stop_unused_engines()
            self.__routingData__["fx"][slot_row].clear()

        self.__chained_fx[slot_row] = layer
        self.updateChainedFxEngineData(slot_row, layer)
        self.__sound_snapshot_changed = True
        self.update_jack_port()
        self.chainedFxChanged.emit()
        self.chainedFxNamesChanged.emit()

    @Slot()
    def removeSelectedFxFromChain(self):
        self.removeFxFromChain(self.__selected_fx_slot_row)

    @Slot(int)
    def removeFxFromChain(self, fxSlotIndex, showLoadingScreen=True):
        if -1 < fxSlotIndex and fxSlotIndex < Zynthbox.Plugin.instance().sketchpadSlotCount():
            def task():
                if self.__chained_fx[fxSlotIndex] is not None:
                    try:
                        layer_index = self.zynqtgui.layer.layers.index(self.__chained_fx[fxSlotIndex])
                        self.zynqtgui.layer.remove_layer(layer_index)
                        self.__chained_fx[fxSlotIndex] = None
                        self.__routingData__["fx"][fxSlotIndex].clear()
                        # Ensure we clear the passthrough (or it'll retain its value)
                        passthroughClient = Zynthbox.Plugin.instance().fxPassthroughClients()[self.__id__][fxSlotIndex]
                        self.__song__.clearPassthroughClient(passthroughClient)
                        passthroughClient.setPanAmount(self.__initial_pan__)
                        passthroughClient.setDryWetMixAmount(1)
                        self.zynqtgui.screens['snapshot'].schedule_save_last_state_snapshot()

                        self.chainedFxChanged.emit()
                        self.chainedFxNamesChanged.emit()
            #            self.zynqtgui.layer_effects.fx_layers_changed.emit()
            #            self.zynqtgui.layer_effects.fx_layer = None
            #            self.zynqtgui.layer_effects.fill_list()
            #            self.zynqtgui.main_layers_view.fill_list()
            #            self.zynqtgui.fixed_layers.fill_list()
                    except Exception as e:
                        logging.exception(e)

                    if showLoadingScreen:
                        QTimer.singleShot(1000, self.zynqtgui.end_long_task)

            if showLoadingScreen:
                self.zynqtgui.do_long_task(task, f"Removing {self.chainedFxNames[self.selectedFxSlotRow]} from slot {self.selectedFxSlotRow + 1} on Track {self.name}")
            else:
                task()

    def updateChainedFxEngineData(self, position, layer):
        if layer is not None:
            dataContainer = self.__routingData__["fx"][position]
            dataContainer.name = self.chainedFxNames[position]
            audioInPorts = self.jclient.get_ports(layer.jackname, is_audio=True, is_input=True)
            for port in audioInPorts:
                dataContainer.addAudioInPort(dataContainer.humanReadablePortName(port.shortname), port.name)
            midiInPorts = self.jclient.get_ports(layer.jackname, is_midi=True, is_input=True)
            for port in midiInPorts:
                dataContainer.addMidiInPort(dataContainer.humanReadablePortName(port.shortname), port.name)

    chainedFxChanged = Signal()
    chainedFx = Property('QVariantList', get_chainedFx, set_chainedFx, notify=chainedFxChanged)
    ### END Property chainedFx

    ### Property chainedFxNames
    def get_chainedFxNames(self):
        names = []
        for fx in self.chainedFx:
            try:
                # Strip Jalv/Jucy prefix from name (if any)
                engine_name = fx.engine.name.lstrip("Jalv/").lstrip("Jucy/")
                if fx.preset_name is not None and fx.preset_name != "None" and fx.preset_name != "":
                    names.append(f"{engine_name} > {fx.preset_name}")
                else:
                    names.append(engine_name)
            except:
                names.append("")
        return names

    chainedFxNamesChanged = Signal()

    chainedFxNames = Property('QStringList', get_chainedFxNames, notify=chainedFxNamesChanged)
    ### END Property chainedFxNames

    ### Property chainedSketchFx
    def get_chainedSketchFx(self):
        return self.__chained_sketch_fx

    def set_chainedSketchFx(self, fx):
        if fx != self.__chained_sketch_fx:
            self.__chained_sketch_fx = fx
            for slot_index, layer in enumerate(fx):
                self.updateChainedSketchFxEngineData(slot_index, layer)
            self.update_jack_port()
            self.__sound_snapshot_changed = True
            self.__song__.schedule_save()
            self.chainedSketchFxChanged.emit()
            self.chainedSketchFxNamesChanged.emit()

    # Add or replace a fx layer at slot_row to fx chain
    # If explicit slot_row is not set then selected slot row is used
    def setSketchFxToChain(self, layer, slot_row=-1):
        if slot_row == -1:
            if self.selectedSlot.className == "TracksBar_sketchfxslot":
                slot_row == self.selectedSlot.value
            else:
                logging.error(f"Selected Slot is not a TracksBar_sketchfxslot. Cannot continue adding fx! : slotType({self.selectedSlot.className}), value({self.selectedSlot.value})")
                return

        if self.__chained_sketch_fx[slot_row] is not None:
            self.zynqtgui.zynautoconnect_acquire_lock()
            self.__chained_sketch_fx[slot_row].reset()
            self.zynqtgui.zynautoconnect_release_lock()
            self.zynqtgui.screens['engine'].stop_unused_engines()
            self.__routingData__["sketchfx"][slot_row].clear()

        self.update_jack_port()
        self.__chained_sketch_fx[slot_row] = layer
        self.updateChainedSketchFxEngineData(slot_row, layer)
        self.__sound_snapshot_changed = True
        self.chainedSketchFxChanged.emit()
        self.chainedSketchFxNamesChanged.emit()

    @Slot()
    def removeSelectedSketchFxFromChain(self):
        if self.selectedSlot.className == "TracksBar_sketchfxslot":
           self.removeSketchFxFromChain(self.selectedSlot.value)
        else:
           logging.error(f"Selected Slot is not a TracksBar_sketchfxslot. Cannot continue removing fx! : slotType({self.selectedSlot.className}), value({self.selectedSlot.value})")
           return

    @Slot(int)
    def removeSketchFxFromChain(self, fxSlotIndex):
        if -1 < fxSlotIndex and fxSlotIndex < Zynthbox.Plugin.instance().sketchpadSlotCount():
            def task():
                if self.__chained_sketch_fx[fxSlotIndex] is not None:
                    try:
                        layer_index = self.zynqtgui.layer.layers.index(self.__chained_sketch_fx[fxSlotIndex])
                        self.zynqtgui.layer.remove_layer(layer_index)
                        self.__chained_sketch_fx[fxSlotIndex] = None
                        self.__routingData__["sketchfx"][fxSlotIndex].clear()
                        # Ensure we clear the passthrough (or it'll retain its value)
                        passthroughClient = Zynthbox.Plugin.instance().sketchFxPassthroughClients()[self.__id__][fxSlotIndex]
                        self.__song__.clearPassthroughClient(passthroughClient)
                        passthroughClient.setPanAmount(self.__initial_pan__)
                        passthroughClient.setDryWetMixAmount(1)
                        self.zynqtgui.screens['snapshot'].schedule_save_last_state_snapshot()

                        self.chainedSketchFxChanged.emit()
                        self.chainedSketchFxNamesChanged.emit()
                    except Exception as e:
                        logging.exception(e)
                    QTimer.singleShot(1, self.zynqtgui.end_long_task)
            self.zynqtgui.do_long_task(task, f"Removing {self.chainedSketchFxNames[fxSlotIndex]} from slot {fxSlotIndex + 1} on Track {self.name}")

    def updateChainedSketchFxEngineData(self, position, layer):
        if layer is not None:
            dataContainer = self.__routingData__["sketchfx"][position]
            dataContainer.name = self.chainedSketchFxNames[position]
            audioInPorts = self.jclient.get_ports(layer.jackname, is_audio=True, is_input=True)
            for port in audioInPorts:
                dataContainer.addAudioInPort(dataContainer.humanReadablePortName(port.shortname), port.name)
            midiInPorts = self.jclient.get_ports(layer.jackname, is_midi=True, is_input=True)
            for port in midiInPorts:
                dataContainer.addMidiInPort(dataContainer.humanReadablePortName(port.shortname), port.name)

    chainedSketchFxChanged = Signal()
    chainedSketchFx = Property('QVariantList', get_chainedSketchFx, set_chainedSketchFx, notify=chainedSketchFxChanged)
    ### END Property chainedSketchFx

    ### Property chainedSketchFxNames
    def get_chainedSketchFxNames(self):
        names = []
        for fx in self.chainedSketchFx:
            try:
                # Strip Jalv/Jucy prefix from name (if any)
                engine_name = fx.engine.name.lstrip("Jalv/").lstrip("Jucy/")
                if fx.preset_name is not None and fx.preset_name != "None" and fx.preset_name != "":
                    names.append(f"{engine_name} > {fx.preset_name}")
                else:
                    names.append(engine_name)
            except:
                names.append("")
        return names

    chainedSketchFxNamesChanged = Signal()

    chainedSketchFxNames = Property('QStringList', get_chainedSketchFxNames, notify=chainedSketchFxNamesChanged)
    ### END Property chainedSketchFxNames

    ### BEGIN Property channelHasFx
    def get_channelHasFx(self):
        for fx in self.chainedFx:
            if fx is not None:
                return True
        return False

    channelHasFx = Property(bool, get_channelHasFx, notify=chainedFxChanged)
    ### END Property channelHasFx

    ### Property connectedSound
    def get_connected_sound(self):
        for sound in self.__chained_sounds__:
            if sound >= 0 and self.checkIfLayerExists(sound):
                return sound

        return -1

    connectedSoundChanged = Signal()

    connectedSound = Property(int, get_connected_sound, notify=connectedSoundChanged)
    ### END Property connectedSound

    ### Property connectedSoundName
    def get_connected_sound_name(self):
        soundName = " > "

        try:
            for index, sound in enumerate(self.__chained_sounds__):
                if sound >= 0 and self.checkIfLayerExists(sound):
                    soundName = self.chainedSoundsNames[index]
                    break
        except:
            pass

        return soundName

    connectedSoundNameChanged = Signal()

    connectedSoundName = Property(str, get_connected_sound_name, notify=connectedSoundNameChanged)
    ### END Property connectedSoundName

    ### BEGIN Property muted
    def get_muted(self):
        return self.__muted__

    def set_muted(self, muted):
        if self.__muted__ != muted:
            logging.debug(f"$$ Setting muted for Track {self.name} to : {muted}")
            self.__muted__ = muted
            self.__trackMixerClient.setMuted(muted)
            self.mutedChanged.emit()
            Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_TRACK_MUTED", -1, Zynthbox.ZynthboxBasics.Track(self.__id__), Zynthbox.ZynthboxBasics.Slot.AnySlot, (1 if self.__muted__ == True else 0))

    mutedChanged = Signal()

    muted = Property(bool, get_muted, set_muted, notify=mutedChanged)
    ### END Property muted

    ### BEGIN Property allowMulticlip
    def get_allowMulticlip(self):
        return self.__allowMulticlip__

    def set_allowMulticlip(self, allowMulticlip, force_set=False):
        if force_set or self.__allowMulticlip__ != allowMulticlip:
            self.__allowMulticlip__ = allowMulticlip
            self.allowMulticlipChanged.emit()
            if self.__allowMulticlip__ == False and self.__song__.isLoading == False:
                for clipId in range(Zynthbox.Plugin.instance().sketchpadSlotCount()):
                    clip = self.getClipsModelById(clipId).getClip(self.id)
                    if clip.enabled:
                        self.onClipEnabledChanged(self.id, clipId)
                        break
            if force_set == False:
                self.__song__.schedule_save()

    allowMulticlipChanged = Signal()

    allowMulticlip = Property(bool, get_allowMulticlip, set_allowMulticlip, notify=allowMulticlipChanged)
    ### END Property allowMulticlip

    ### BEGIN Property trackType
    # Possible values : "synth", "sample-loop", "sample-trig", "external"
    # For simplicity, trackType is string in the format "sample-xxxx" or "synth" or "external"
    # TODO : Later implement it properly with model and enums
    def get_track_type(self):
        return self.__track_type__

    def set_track_type(self, type:str, force_set=False):
        logging.debug(f"Setting Audio Type : {type}, {self.__track_type__}")

        if force_set or type != self.__track_type__:
            # Heuristic to fix a problem with ZynAddSubFX :
            # While switching track_type for a couple of times, ZynAddSubFX goes completely berserk
            # and causes jack to become unresponsive and hence causing everything to go out-of-order
            # Testing suggests ZynAddSubFX does not like handling midi events it does not quite know about.
            # During testing it was noticed that if ZynAddSubFX was disconnected before changing track_type
            # and reconnected on complete it does not cause the aforementioned issue. Hence make sure to
            # do the disconnect-connect dance when changing track_type only to the ZynAddSubFX synth if the
            # track has one
            self.zynaddsubfx_midi_input = None
            self.zynaddsubfx_midi_output = None
            for midichannel in self.chainedSounds:
                if midichannel >= 0 and self.checkIfLayerExists(midichannel):
                    engine = self.zynqtgui.layer.layer_midi_map[midichannel].engine
                    if engine.name == "ZynAddSubFX":
                        try:
                            self.zynaddsubfx_midi_input = sketchpad_channel.jclient.get_ports(engine.jackname, is_input=True, is_midi=True)[0]
                            self.zynaddsubfx_midi_output = f"ZLRouter:Zynthian-Channel{midichannel}"
                        except:
                            self.zynaddsubfx_midi_input = None
                            self.zynaddsubfx_midi_output = None
                        break
            if self.zynaddsubfx_midi_output is not None and self.zynaddsubfx_midi_input is not None:
                logging.debug(f"ZynAddSubFX Heuristic : Disconnect {self.zynaddsubfx_midi_output} {self.zynaddsubfx_midi_input}")
                try:
                    sketchpad_channel.jclient.disconnect(self.zynaddsubfx_midi_output, self.zynaddsubfx_midi_input)
                except: pass

            self.__track_type__ = type
            self.track_type_changed.emit()

            # Set keyZoneMode to "Off"(all-full) state when type is changed to trig
            if type == "sample-trig":
                self.keyZoneMode = "all-full"

            for songId in range(0, Zynthbox.Plugin.instance().sketchpadSongCount()):
                for clipId in range(0, Zynthbox.Plugin.instance().sketchpadSlotCount()):
                    clip = self.__song__.getClipById(self.id, songId, clipId)
                    if clip is not None:
                        clip.enabled_changed.emit(clip.col, clip.id)
            if force_set == False:
                # If we are *not* being forced, we have switched from the UI, and need to select a reasonable slot, and also save
                self.selectFirstAndBestSlot()
                self.__song__.schedule_save()
            self.update_jack_port()
            self.zynaddubfx_heuristic_connect_timer.start()

    def zynaddubfx_heuristic_connect(self):
        if self.zynaddsubfx_midi_output is not None and self.zynaddsubfx_midi_input is not None:
            logging.debug(f"ZynAddSubFX Heuristic : Connect {self.zynaddsubfx_midi_output} {self.zynaddsubfx_midi_input}")
            try:
                sketchpad_channel.jclient.connect(self.zynaddsubfx_midi_output, self.zynaddsubfx_midi_input)
            except: pass

    track_type_changed = Signal()

    def audioTypeKey(self, trackType = None):
        if trackType is None:
            trackType = self.trackType

        if trackType == "sample-loop":
            return "sketch"
        elif trackType == "sample-trig":
            return "sample"
        return trackType

    @Slot(None)
    def handleAudioTypeSettingsChanged(self):
        self.panChanged.emit()
        self.dryAmountChanged.emit()
        self.wetFx1AmountChanged.emit()
        self.wetFx2AmountChanged.emit()
        self.synthPassthroughMixingChanged.emit()
        self.fxPassthroughMixingChanged.emit()
        self.sketchFxPassthroughMixingChanged.emit()

    trackTypeKey = Property(str, audioTypeKey, notify=track_type_changed)
    trackType = Property(str, get_track_type, set_track_type, notify=track_type_changed)
    ### END Property trackType

    ### BEGIN Property trackRoutingStyle
    # Possible values : "standard", "one-to-one"
    # Standard routes all audio through a serial lane of all effects (so e.g. synth or sample slot 3 will be routed to fx slot 1, which in turn is passed through fx slot 2, and so on, and the final fx through the global fx)
    # One-to-one routes each individual lane to a separate lane (each containing one effect, so e.g. synth or sample slot 3 routes to fx slot 3, and from there to the global fx)
    def get_track_routing_style(self):
        return self.__track_routing_style__

    def set_track_routing_style(self, newRoutingStyle, force_set=False):
        if force_set or newRoutingStyle != self.__track_routing_style__:
            self.__track_routing_style__ = newRoutingStyle
            self.track_routing_style_changed.emit()
            self.update_jack_port()
            self.zynqtgui.zynautoconnect()
            if force_set == False:
                self.__song__.schedule_save()

    track_routing_style_changed = Signal()

    trackRoutingStyle = Property(str, get_track_routing_style, set_track_routing_style, notify=track_routing_style_changed)

    def get_track_routing_style_name(self):
        if self.__track_routing_style__ == "standard":
            return "Standard"
        elif self.__track_routing_style__ == "one-to-one":
            return "One-to-One"
        return "Unknown"
    trackRoutingStyleName = Property(str, get_track_routing_style_name, notify=track_routing_style_changed)
    ### END Property trackRoutingStyle

    ### BEGIN Property sketchFxRoutingData
    def get_sketchFxRoutingData(self):
        return self.__routingData__["sketchfx"]

    sketchFxRoutingDataChanged = Signal()

    sketchFxRoutingData = Property('QVariantList', get_sketchFxRoutingData, notify=sketchFxRoutingDataChanged)
    ### END Property sketchFxRoutingData

    ### BEGIN Property fxRoutingData
    def get_fxRoutingData(self):
        return self.__routingData__["fx"]

    fxRoutingDataChanged = Signal()

    fxRoutingData = Property('QVariantList', get_fxRoutingData, notify=fxRoutingDataChanged)
    ### END Property fxRoutingData

    ### BEGIN Property synthRoutingData
    def get_synthRoutingData(self):
        routingData = self.__routingData__["synth"]
        # logging.error(f"Getting routing data: {routingData}")
        return routingData

    synthRoutingDataChanged = Signal()

    synthRoutingData = Property('QVariantList', get_synthRoutingData, notify=synthRoutingDataChanged)
    ### END Property synthRoutingData

    # TODO : sketchFX Implement sketchFxRoutingData

    ### BEGIN Property chainedSoundsKeyzones
    def get_chainedSoundsKeyzones(self):
        return self.__chained_sounds_keyzones__

    chainedSoundsKeyzonesChanged = Signal()

    chainedSoundsKeyzones = Property('QVariantList', get_chainedSoundsKeyzones, notify=chainedSoundsKeyzonesChanged)
    ### END Property chainedSoundsKeyzones

    ### BEGIN Property channelTypeDisplayName
    def get_channelTypeDisplayName(self):
        if self.__track_type__ == "synth":
            return "Sketch"
        elif self.__track_type__ == "sample-loop":
            return "Loop"
        elif self.__track_type__.startswith("sample"):
            return "Sample"
        elif self.__track_type__ == "external":
            return "External"

    channelTypeDisplayName = Property(str, get_channelTypeDisplayName, notify=track_type_changed)
    ### END Property channelTypeDisplayName

    ### Property samples
    def get_samples(self):
        return self.__samples__

    @Slot(str, int, result=None)
    def set_sample(self, path, index):
        self.__samples__[index].importFromFile(path)

    samples_changed = Signal()

    samples = Property('QVariantList', get_samples, notify=samples_changed)
    ### END Property samples

    ### BEGIN Property samplePickingStyle
    # Possible values: "same", "first", "all"
    # first will always pick the sample which current pattern's slot number (unless explicitly rejected by the keyZone setup)
    # first will always pick whatever is the first sample with a matching keyZone
    # all will pick all samples which match the keyZone
    def get_samplePickingStyle(self):
        return self.__sample_picking_style__

    @Slot(str)
    def set_samplePickingStyle(self, sample_picking):
        if self.__sample_picking_style__ != sample_picking:
            if sample_picking == "same-or-first": # Our old default
                self.__sample_picking_style__ = "all"
            else:
                self.__sample_picking_style__ = sample_picking
            self.samplePickingStyleChanged.emit()
            self.__song__.schedule_save()

    samplePickingStyleChanged = Signal()

    samplePickingStyle = Property(str, get_samplePickingStyle, set_samplePickingStyle, notify=samplePickingStyleChanged)
    ### END Property samplePickingStyle

    ### BEGIN Property trustExternalDeviceChannels
    def get_trustExternalDeviceChannels(self):
        return self.__trustExternalDeviceChannels__
    @Slot(bool)
    def set_trustExternalDeviceChannels(self, newValue):
        if self.__trustExternalDeviceChannels__ != newValue:
            self.__trustExternalDeviceChannels__ = newValue
            self.trustExternalDeviceChannelsChanged.emit()
            self.__song__.schedule_save()
            Zynthbox.MidiRouter.instance().setSketchpadTrackTrustExternalInputChannel(Zynthbox.ZynthboxBasics.Track(self.id), newValue)
    trustExternalDeviceChannelsChanged = Signal()
    trustExternalDeviceChannels = Property(bool, get_trustExternalDeviceChannels, set_trustExternalDeviceChannels, notify=trustExternalDeviceChannelsChanged)
    ### END Property trustExternalDeviceChannels

    ### Property keyzoneMode
    # Possible values : "manual", "all-full", "split-full", "split-narrow"
    # manual will not apply any automatic stuff
    # all-full will set all samples to full width, c4 at 60
    # split-full will spread samples across the note range, in the order 4, 2, 1, 3, 5, starting at note 0, 24 for each, with c4 on the 12th note inside the sample's range
    # split-narrow will set the samples to play only on the white keys from note 60 and up, with that note as root
    # 2-low-3-high will set the slots to be split at the 2 first slots playing from 0 through c4, and the 3 last slots playing from c#4 and up, with no transposition

    @Slot()
    def updateKeyZones(self):
        # This should be called whenever one of the things it depends on changes:
        # - keyzoneMode
        # - synth engines (chained_sounds)
        # - sample setup (samples)
        slotSettings = None
        if self.__keyzone_mode__ == "all-full":
            slotSettings = [
                [0, 127, 0],
                [0, 127, 0],
                [0, 127, 0],
                [0, 127, 0],
                [0, 127, 0]
            ]
        elif self.__keyzone_mode__ == "split-full":
            # auto-split keyzones: SLOT 4 c-1 - b1, SLOT 2 c1-b3, SLOT 1 c3-b5, SLOT 3 c5-b7, SLOT 5 c7-c9
            # root key transpose in semtitones: +48, +24 ,0 , -24, -48
            slotSettings = [
                [48, 71, 0],   # slot 1
                [24, 47, -24], # slot 2
                [72, 95, 24],  # slot 3
                [0, 23, -48],  # slot 4
                [96, 119, 48]  # slot 5
            ]
        elif self.__keyzone_mode__ == "split-narrow":
            # Narrow split puts the samples on the keys C4, D4, E4, F4, G4, and plays them as C4 on those notes
            slotSettings = [
                [60, 60, 0], # slot 1
                [62, 62, 2], # slot 2
                [64, 64, 4], # slot 3
                [65, 65, 5], # slot 4
                [67, 67, 7]  # slot 5
            ]
        # TODO We probably want to ensure that we use the track's split point here, instead of a hardcoded one... ;)
        elif self.__keyzone_mode__ == "2-low-3-high":
            slotSettings = [
                [0, 59, 0],
                [0, 59, 0],
                [60, 127, 0],
                [60, 127, 0],
                [60, 127, 0]
            ]

        if slotSettings is not None:
            for i in range(0, Zynthbox.Plugin.instance().sketchpadSlotCount()):
                # Synth slots
                keyzoneData = self.__chained_sounds_keyzones__[i]
                keyzoneData.keyZoneStart = slotSettings[i][0]
                keyzoneData.keyZoneEnd = slotSettings[i][1]
                keyzoneData.rootNote = 60 + slotSettings[i][2]
                # Sample slots
                sample = self.__samples__[i]
                clip = Zynthbox.PlayGridManager.instance().getClipById(sample.cppObjId)
                if clip:
                    clip.rootSlice().setKeyZoneStart(slotSettings[i][0])
                    clip.rootSlice().setKeyZoneEnd(slotSettings[i][1])
                    clip.rootSlice().setRootNote(60 + slotSettings[i][2])

    def get_keyZoneMode(self):
        return self.__keyzone_mode__

    @Slot(str)
    def set_keyZoneMode(self, keyZoneMode):
        if self.__keyzone_mode__ != keyZoneMode:
            self.__keyzone_mode__ = keyZoneMode
            self.keyZoneModeChanged.emit()
            for songId in range(0, Zynthbox.Plugin.instance().sketchpadSongCount()):
                for clipId in range(0, Zynthbox.Plugin.instance().sketchpadSlotCount()):
                    clip = self.__song__.getClipById(self.id, songId, clipId)
                    if clip is not None:
                        clip.enabled_changed.emit(clip.col, clip.id)
            self.__song__.schedule_save()

    keyZoneModeChanged = Signal()

    keyZoneMode = Property(str, get_keyZoneMode, set_keyZoneMode, notify=keyZoneModeChanged)
    ### END Property keyzoneMode

    ### Property recordingDir
    def get_recording_dir(self):
        wav_path = Path(self.__song__.sketchpad_folder) / 'wav'
        if wav_path.exists():
            return str(wav_path)
        else:
            return self.__song__.sketchpad_folder

    recordingDir = Property(str, get_recording_dir, constant=True)
    ### END Property recordingDir

    ### Property bankDir
    """
    bankDir points to the directory where samples are saved
    The path gets resolved to /zynthian/zynthian-my-data/sketchpads/my-sketchpads/<sketchpad dir name>/wav/sampleset/*.<track id>
    """
    def get_bank_dir(self):
        try:
            # Check if a dir named <somerandomname>.<channel_id> exists.
            # If exists, use that name as the bank dir name otherwise use default name `sample-bank`
            bank_name = (self.__base_samples_dir__.glob(f"*.{self.id + 1}")[0]).name.split(".")[0]
        except:
            bank_name = "sample-bank"
        path = self.__base_samples_dir__ / f"{bank_name}.{self.id + 1}"
        return str(path)

    bankDir = Property(str, get_bank_dir, constant=True)
    ### END Property bankDir

    ### Property sceneClip
    def get_scene_clip(self):
        return self.__song__.getClip(self.id, self.__song__.scenesModel.selectedSketchpadSongIndex)

    scene_clip_changed = Signal()

    sceneClip = Property(QObject, get_scene_clip, notify=scene_clip_changed)
    ### END Property sceneClip

    ### BEGIN Property selectedSlot
    def get_selectedSlot(self):
        return self.__selected_slot_obj
    selectedSlot = Property(QObject, get_selectedSlot, constant=True)
    ### END Property selectedSlot

    ### Property selectedSlotRow
    def get_selectedSlotRow(self):
        return self.__selected_slot_row__

    def set_selectedSlotRow(self, row, shouldEmitCurrentSlotCUIAFeedback=True):
        if self.__selected_slot_row__ != row:
            self.__selected_slot_row__ = row
            self.selectedSlotRowChanged.emit()
            if shouldEmitCurrentSlotCUIAFeedback:
                self.emitCurrentSlotCUIAFeedback()

    selectedSlotRowChanged = Signal()

    selectedSlotRow = Property(int, get_selectedSlotRow, set_selectedSlotRow, notify=selectedSlotRowChanged)
    ### END Property selectedSlotRow

    @Slot(None)
    def emitCurrentSlotCUIAFeedback(self):
        knownGain = 0.0
        knownPan = 0.0
        if self.audioTypeKey() == "synth":
            synthIndex = self.chainedSounds[self.selectedSlotRow]
            if synthIndex > -1:
                knownGain = self.__audioTypeSettings__[self.audioTypeSettingsKey()]["synthPassthrough"][self.selectedSlotRow]["dryAmount"]
                knownPan = self.__audioTypeSettings__[self.audioTypeSettingsKey()]["synthPassthrough"][self.selectedSlotRow]["panAmount"]
        elif self.audioTypeKey() == "sample":
            sample = self.samples[self.selectedSlotRow]
            if sample.audioSource:
                knownGain = sample.audioSource.rootSlice().gainHandler().gainAbsolute()
                knownPan = sample.audioSource.rootSlice().pan()
        elif self.audioTypeKey() == "sketch":
            theClip = self.getClipsModelById(self.selectedSlotRow).getClip(self.__song__.scenesModel.selectedSketchpadSongIndex)
            if theClip.audioSource:
                knownGain = theClip.audioSource.rootSlice().gainHandler().gainAbsolute()
                knownPan = theClip.audioSource.rootSlice().pan()
        elif self.audioTypeKey() == "external":
            pass
        Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_SLOT_GAIN", -1, Zynthbox.ZynthboxBasics.Track.CurrentTrack, Zynthbox.ZynthboxBasics.Slot.CurrentSlot, np.interp(knownGain, (0, 1), (0, 127)))
        Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_SLOT_PAN", -1, Zynthbox.ZynthboxBasics.Track.CurrentTrack, Zynthbox.ZynthboxBasics.Slot.CurrentSlot, np.interp(knownPan, (-1, 1), (0, 127)))
        knownDryWetMixAmount = 0.0
        if self.chainedFx[self.__selected_fx_slot_row]:
            knownDryWetMixAmount = self.__audioTypeSettings__[self.audioTypeSettingsKey()]["fxPassthrough"][self.__selected_fx_slot_row]["dryWetMixAmount"]
        Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_FX_AMOUNT", -1, Zynthbox.ZynthboxBasics.Track.CurrentTrack, Zynthbox.ZynthboxBasics.Slot.CurrentSlot, np.interp(knownDryWetMixAmount, (0, 2), (0, 127)))

        # TODO : sketchFx

    ### Property selectedFxSlotRow
    def get_selectedFxSlotRow(self):
        return self.__selected_fx_slot_row

    def set_selectedFxSlotRow(self, row):
        if self.__selected_fx_slot_row != row:
            self.__selected_fx_slot_row = row
            self.selectedFxSlotRowChanged.emit()

    selectedFxSlotRowChanged = Signal()

    selectedFxSlotRow = Property(int, get_selectedFxSlotRow, set_selectedFxSlotRow, notify=selectedFxSlotRowChanged)
    ### END Property selectedFxSlotRow

    ### Property occupiedSlots
    @Slot(None, result='QVariantList')
    def get_occupiedSlots(self):
        occupied_slots = []

        if self.__track_type__ == "sample-trig":
            # logging.debug(f"### get_occupiedSlots : Sample trig")
            # If type is sample-trig check how many samples has wavs selected
            for sample in self.__samples__:
                if sample is not None and \
                        sample.path is not None and \
                        len(sample.path) > 0:
                    occupied_slots.append(True)
                else:
                    occupied_slots.append(False)
        elif self.__track_type__ == "synth":
            # logging.debug(f"### get_occupiedSlots : synth")
            # If type is synth check how many synth engines are selected and chained
            for sound in self.__chained_sounds__:
                if sound >= 0 and self.checkIfLayerExists(sound):
                    occupied_slots.append(True)
                else:
                    occupied_slots.append(False)
        else:
            # logging.debug(f"### get_occupiedSlots : Slots not in use")
            # For any other modes, sample slots are not in use. Hence do not increment occupied_slots
            pass

        # logging.debug(f"### get_occupiedSlots : occupied_slots({occupied_slots})")

        return occupied_slots

    occupiedSlotsChanged = Signal()

    occupiedSlots = Property('QVariantList', get_occupiedSlots, notify=occupiedSlotsChanged)
    ### END Property occupiedSlots

    ### Property occupiedSlotsCount
    @Slot(None, result='QVariantList')
    def get_occupiedSlotsCount(self):
        count = 0

        for slot in self.occupiedSlots:
            if slot:
                count += 1

        return count

    occupiedSlotsCount = Property(int, get_occupiedSlotsCount, notify=occupiedSlotsChanged)
    ### END Property occupiedSlotsCount

    ### BEGIN Property occupiedSampleSlotsCount
    def get_occupiedSampleSlotsCount(self):
        count = 0
        for sample in self.__samples__:
            if sample is not None and sample.path is not None and len(sample.path) > 0:
                count += 1
        return count

    occupiedSampleSlotsCount = Property(int, get_occupiedSampleSlotsCount, notify=occupiedSlotsChanged)
    ### END Property occupiedSampleSlotsCount

    # BEGIN Property selectedClip
    # This is to decide which clip to show for this track (as opposed to which clip(s) are currently enabled for playback)
    def get_selected_clip(self):
        return self.__selected_clip__
    def set_selected_clip(self, selected_clip, force_set=False, shouldEmitCurrentClipCUIAFeedback=True):
        if self.__selected_clip__ != selected_clip or force_set == True:
            self.__selected_clip__ = selected_clip
            self.selectedClipChanged.emit()
            if self.trackType == "sample-loop":
                self.requestSwitchToSlot.emit("sketch", self.__selected_clip__)
            if shouldEmitCurrentClipCUIAFeedback:
                self.emitCurrentClipCUIAFeedback()
    selectedClipChanged = Signal()
    selectedClip = Property(int, get_selected_clip, set_selected_clip, notify=selectedClipChanged)
    # END Property selectedClip

    requestSwitchToSlot = Signal(str, int, arguments=["slotType", "slotIndex"])

    @Slot(None)
    def emitCurrentClipCUIAFeedback(self):
        if self.__id__ == self.zynqtgui.sketchpad.selectedTrackId:
            Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_CLIP_CURRENT", -1, Zynthbox.ZynthboxBasics.Track.CurrentTrack, Zynthbox.ZynthboxBasics.Slot(self.__selected_clip__), -1)
        Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_CLIP_CURRENT", -1, Zynthbox.ZynthboxBasics.Track(self.__id__), Zynthbox.ZynthboxBasics.Slot(self.__selected_clip__), -1)
        # Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_CLIP_CURRENT_RELATIVE", -1, Zynthbox.ZynthboxBasics.Track(self.__id__), Zynthbox.ZynthboxBasics.Slot(self.__selected_clip__), -1)

    # BEGIN Property externalSettings
    def get_externalSettings(self):
        return self.__externalSettings__
    externalSettings = Property(QObject, get_externalSettings, constant=True)
    # END Property externalSettings

    # END Property externalMidiChannel
    # DEPRECATED Switch to accessing the externalSettings property directly
    # Logic for this is, -1 is "just use the normal one", anything else is a specific channel
    def get_externalMidiChannel(self):
        return self.__externalSettings__.midiChannel

    def set_externalMidiChannel(self, externalMidiChannel):
        if externalMidiChannel != self.__externalSettings__.midiChannel:
            self.__externalSettings__.midiChannel = externalMidiChannel
            self.externalMidiChannelChanged.emit()

    externalMidiChannelChanged = Signal()

    externalMidiChannel = Property(int, get_externalMidiChannel, set_externalMidiChannel, notify=externalMidiChannelChanged)
    # END Property externalMidiChannel

    # BEGIN Property externalCaptureVolume
    # DEPRECATED Switch to accessing the externalSettings property directly
    def get_externalCaptureVolume(self):
        return self.__externalSettings__.captureVolume

    def set_externalCaptureVolume(self, newVolume):
        if newVolume != self.__externalSettings__.captureVolume:
            self.__externalSettings__.captureVolume__ = newVolume
            self.externalMidiChannelChanged.emit()

    externalCaptureVolumeChanged = Signal()

    # This is on a scale from 0 (no sound should happen) to 1 (all the sound please)
    externalCaptureVolume = Property(float, get_externalCaptureVolume, set_externalCaptureVolume, notify=externalCaptureVolumeChanged)
    # END Property externalCaptureVolume

    # BEGIN Property externalAudioSource
    # DEPRECATED Switch to accessing the externalSettings property directly
    def get_externalAudioSource(self):
        return self.__externalSettings__.audioSource

    def set_externalAudioSource(self, newAudioSource):
        if newAudioSource != self.__externalSettings__.audioSource:
            self.__externalSettings__.audioSource = newAudioSource
            self.externalAudioSourceChanged.emit()
            self.zynqtgui.zynautoconnect()
            self.__song__.schedule_save()

    externalAudioSourceChanged = Signal()

    externalAudioSource = Property(str, get_externalAudioSource, set_externalAudioSource, notify=externalAudioSourceChanged)
    # END Property externalAudioSource

    ### Property selectedClipNames
    def get_selectedClipNames(self):
        clipNames = []
        for i in range(5):
            clip = self.getClipsModelById(i).getClip(self.__song__.scenesModel.selectedSketchpadSongIndex)

            if clip.enabled:
                if self.trackType == "sample-loop":
                    # Show 1-5 for sketch mode
                    clipNames.append(f"{i+1}")
                else:
                    # Show A-E for other modes
                    clipNames.append(chr(i+65).lower())
            else:
                clipNames.append("")

        return clipNames

    selectedClipNamesChanged = Signal()

    selectedClipNames = Property('QVariantList', get_selectedClipNames, notify=selectedClipNamesChanged)
    ### Property selectedClipNames

    ### Property recordingPopupActive
    ### Proxy recordingPopupActive from zynthian_qt_gui

    def get_recordingPopupActive(self):
        return self.zynqtgui.recordingPopupActive

    recordingPopupActiveChanged = Signal()

    recordingPopupActive = Property(bool, get_recordingPopupActive, notify=recordingPopupActiveChanged)
    ### END Property recordingPopupActive

    ### Property routeThroughGlobalFX
    def get_routeThroughGlobalFX(self):
        return self.route_through_global_fx

    def set_routeThroughGlobalFX(self, val, force_set=False):
        if self.route_through_global_fx != val or force_set is True:
            self.route_through_global_fx = val
            self.routeThroughGlobalFXChanged.emit()
            self.zynqtgui.zynautoconnect()

    routeThroughGlobalFXChanged = Signal()

    routeThroughGlobalFX = Property(bool, get_routeThroughGlobalFX, set_routeThroughGlobalFX, notify=routeThroughGlobalFXChanged)
    ### END Property routeThroughGlobalFX

    ### Property channelSoundRecordingPorts
    def get_channelSoundRecordingPorts(self):
        return self.__channel_sound_recording_ports

    def set_channelSoundRecordingPorts(self, ports):
        if self.__channel_sound_recording_ports != ports:
            self.__channel_sound_recording_ports = ports
            self.channelSoundRecordingPortsChanged.emit()

    channelSoundRecordingPortsChanged = Signal()

    channelSoundRecordingPorts = Property('QVariantList', get_channelSoundRecordingPorts, notify=channelSoundRecordingPortsChanged)
    ### END Property channelSoundRecordingPorts

    ### Property channelHasSynth
    def get_channelHasSynth(self):
        for sound in self.__chained_sounds__:
            if sound >= 0 and self.checkIfLayerExists(sound):
                return True
        return False

    channelHasSynth = Property(bool, get_channelHasSynth, notify=chained_sounds_changed)
    ### END Property channelHasSynth

    def get_audioTypeSettings(self):
        return self.__audioTypeSettings__

    ### BEGIN Property pan
    def get_pan(self):
        return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["trackPassthrough"][0]["panAmount"]

    def set_pan(self, pan: float, force_set=False):
        if self.__audioTypeSettings__[self.audioTypeSettingsKey()]["trackPassthrough"][0]["panAmount"] != pan or force_set is True:
            self.__audioTypeSettings__[self.audioTypeSettingsKey()]["trackPassthrough"][0]["panAmount"] = pan
            self.panChanged.emit()
            if force_set is False:
                self.__song__.schedule_save()

    @Slot(None)
    def handlePanChanged(self):
        self.__trackMixerClient.setPanAmount(self.__audioTypeSettings__[self.audioTypeSettingsKey()]["trackPassthrough"][0]["panAmount"])
        Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_TRACK_PAN", -1, Zynthbox.ZynthboxBasics.Track(self.__id__), Zynthbox.ZynthboxBasics.Slot.AnySlot, np.interp(self.__audioTypeSettings__[self.audioTypeSettingsKey()]["trackPassthrough"][0]["panAmount"], (-1, 1), (0, 127)))

    panChanged = Signal()

    pan = Property(float, get_pan, set_pan, notify=panChanged)
    ### END Property pan

    ### BEGIN Property dryAmount
    def get_dryAmount(self):
        return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["trackPassthrough"][0]["dryAmount"]

    def set_dryAmount(self, value, force_set=False):
        if self.__audioTypeSettings__[self.audioTypeSettingsKey()]["trackPassthrough"][0]["dryAmount"] != value or force_set is True:
            self.__audioTypeSettings__[self.audioTypeSettingsKey()]["trackPassthrough"][0]["dryAmount"] = value
            self.dryAmountChanged.emit()
            if force_set is False:
                self.__song__.schedule_save()

    dryAmountChanged = Signal()

    @Slot(None)
    def handleDryAmountChanged(self):
        for slotType in range(0, 2):
            for laneId in range(0, Zynthbox.Plugin.instance().sketchpadSlotCount()):
                # TODO If we want to separate the channel passthrough settings for 1-to-1, the 0 below should be swapped for laneId, and we will need to individually set the amounts
                passthroughClient = Zynthbox.Plugin.instance().trackPassthroughClient(self.id, slotType, laneId)
                dryAmount = self.__audioTypeSettings__[self.audioTypeSettingsKey()]["trackPassthrough"][0]["dryAmount"]
                # logging.info(f"Changing channel dry amount for {self.__id__} lane {laneId} from {passthroughClient.dryAmount()} to {dryAmount}")
                passthroughClient.dryGainHandler().setGain(self.__audioTypeSettings__[self.audioTypeSettingsKey()]["trackPassthrough"][0]["dryAmount"])

    dryAmount = Property(float, get_dryAmount, set_dryAmount, notify=dryAmountChanged)
    ### END Property dryAmount

    ### BEGIN Property wetFx1Amount
    def get_wetFx1Amount(self):
        return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["trackPassthrough"][0]["wetFx1Amount"]

    def set_wetFx1Amount(self, value, force_set=False):
        if self.__audioTypeSettings__[self.audioTypeSettingsKey()]["trackPassthrough"][0]["wetFx1Amount"] != value or force_set is True:
            # Set same value to all lanes
            # TODO If we want to separate the channel passthrough settings for 1-to-1, we will need to individually set the amounts
            for laneId in range(5):
                self.__audioTypeSettings__[self.audioTypeSettingsKey()]["trackPassthrough"][laneId]["wetFx1Amount"] = value
                self.wetFx1AmountChanged.emit()
                if force_set is False:
                    self.__song__.schedule_save()

    wetFx1AmountChanged = Signal()

    @Slot(None)
    def handleWetFx1AmountChanged(self):
        for slotType in range(0, 2):
            for laneId in range(0, Zynthbox.Plugin.instance().sketchpadSlotCount()):
                passthroughClient = Zynthbox.Plugin.instance().trackPassthroughClient(self.id, slotType, laneId)
                passthroughClient.wetFx1GainHandler().setGain(np.interp(self.__audioTypeSettings__[self.audioTypeSettingsKey()]["trackPassthrough"][laneId]["wetFx1Amount"], (0, 100), (0, 1)))
        Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_TRACK_SEND1_AMOUNT", -1, Zynthbox.ZynthboxBasics.Track(self.__id__), Zynthbox.ZynthboxBasics.Slot.AnySlot, np.interp(self.__audioTypeSettings__[self.audioTypeSettingsKey()]["trackPassthrough"][0]["wetFx1Amount"], (0, 1), (0, 127)))

    wetFx1Amount = Property(float, get_wetFx1Amount, set_wetFx1Amount, notify=wetFx1AmountChanged)
    ### END Property wetFx1Amount

    ### BEGIN Property wetFx2Amount
    def get_wetFx2Amount(self):
        return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["trackPassthrough"][0]["wetFx2Amount"]

    def set_wetFx2Amount(self, value, force_set=False):
        if self.__audioTypeSettings__[self.audioTypeSettingsKey()]["trackPassthrough"][0]["wetFx2Amount"] != value or force_set is True:
            # Set same value to all lanes
            # TODO If we want to separate the channel passthrough settings for 1-to-1, we will need to individually set the amounts
            for laneId in range(10):
                self.__audioTypeSettings__[self.audioTypeSettingsKey()]["trackPassthrough"][laneId]["wetFx2Amount"] = value
                self.wetFx2AmountChanged.emit()
                if force_set is False:
                    self.__song__.schedule_save()

    wetFx2AmountChanged = Signal()

    @Slot(None)
    def handleWetFx2AmountChanged(self):
        for slotType in range(0, 2):
            for laneId in range(0, Zynthbox.Plugin.instance().sketchpadSlotCount()):
                passthroughClient = Zynthbox.Plugin.instance().trackPassthroughClient(self.id, slotType, laneId)
                passthroughClient.wetFx2GainHandler().setGain(np.interp(self.__audioTypeSettings__[self.audioTypeSettingsKey()]["trackPassthrough"][laneId]["wetFx2Amount"], (0, 100), (0, 1)))
        Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_TRACK_SEND1_AMOUNT", -1, Zynthbox.ZynthboxBasics.Track(self.__id__), Zynthbox.ZynthboxBasics.Slot.AnySlot, np.interp(self.__audioTypeSettings__[self.audioTypeSettingsKey()]["trackPassthrough"][0]["wetFx2Amount"], (0, 1), (0, 127)))
    """
    Store wetFx2Amount for current channel as a property and set it to JackPassthrough when value changes
    Stored value ranges from 0-100 and accepted range by setWetFx2Amount is 0-1
    """
    wetFx2Amount = Property(float, get_wetFx2Amount, set_wetFx2Amount, notify=wetFx2AmountChanged)
    ### END Property wetFx2Amount

    ### BEGIN Passthrough properties
    @Slot(str, int, str, float)
    def set_passthroughValue(self, passthroughKey:str, laneIndex:int, valueType:str, newValue:float):
        self.__audioTypeSettings__[self.audioTypeSettingsKey()][passthroughKey][laneIndex][valueType] = newValue
        if passthroughKey == "synthPassthrough":
            self.synthPassthroughMixingChanged.emit()
            if valueType == "dryAmount":
                Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_SLOT_GAIN", -1, Zynthbox.ZynthboxBasics.Track(self.__id__), Zynthbox.ZynthboxBasics.Slot(laneIndex), np.interp(newValue, (0, 1), (0, 127)))
                if self.zynqtgui.sketchpad.selectedTrackId == self.__id__ and self.__selected_slot_row__ == laneIndex:
                    Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_SLOT_GAIN", -1, Zynthbox.ZynthboxBasics.Track.CurrentTrack, Zynthbox.ZynthboxBasics.Slot.CurrentSlot, np.interp(newValue, (0, 1), (0, 127)))
        elif passthroughKey == "fxPassthrough":
            self.fxPassthroughMixingChanged.emit()
            if valueType == "dryWetMixAmount":
                Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_FX_AMOUNT", -1, Zynthbox.ZynthboxBasics.Track(self.__id__), Zynthbox.ZynthboxBasics.Slot(laneIndex), np.interp(newValue, (0, 2), (0, 127)))
                if self.zynqtgui.sketchpad.selectedTrackId == self.__id__ and self.__selected_fx_slot_row == laneIndex:
                    Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_FX_AMOUNT", -1, Zynthbox.ZynthboxBasics.Track.CurrentTrack, Zynthbox.ZynthboxBasics.Slot.CurrentSlot, np.interp(newValue, (0, 2), (0, 127)))
        elif passthroughKey == "sketchFxPassthrough":
            self.sketchFxPassthroughMixingChanged.emit()
            if valueType == "dryWetMixAmount":
                Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_SKETCH_FX_AMOUNT", -1, Zynthbox.ZynthboxBasics.Track(self.__id__), Zynthbox.ZynthboxBasics.Slot(laneIndex), np.interp(newValue, (0, 2), (0, 127)))
                if self.zynqtgui.sketchpad.selectedTrackId == self.__id__ and self.selectedSlot.value == laneIndex:
                    Zynthbox.MidiRouter.instance().cuiaEventFeedback("SET_SKETCH_FX_AMOUNT", -1, Zynthbox.ZynthboxBasics.Track.CurrentTrack, Zynthbox.ZynthboxBasics.Slot.CurrentSlot, np.interp(newValue, (0, 2), (0, 127)))

    ### BEGIN synthPassthrough properties
    @Slot(None)
    def handleSynthPassthroughMixingChanged(self):
        for laneId in range(0, 5):
            if self.__chained_sounds__[laneId] > -1:
                synthPassthroughClient = Zynthbox.Plugin.instance().synthPassthroughClients()[self.__chained_sounds__[laneId]]
                panAmount = self.__audioTypeSettings__[self.audioTypeSettingsKey()]["synthPassthrough"][laneId]["panAmount"]
                dryAmount = self.__audioTypeSettings__[self.audioTypeSettingsKey()]["synthPassthrough"][laneId]["dryAmount"]
                # logging.info(f"Changing pan/dry amounts for {self.__id__} lane {laneId} from {synthPassthroughClient.panAmount()} and {synthPassthroughClient.dryAmount()} from {panAmount} to {dryAmount}")
                synthPassthroughClient.setPanAmount(panAmount)
                synthPassthroughClient.dryGainHandler().setGain(dryAmount)
                self.zynqtgui.screens['snapshot'].schedule_save_last_state_snapshot()

    def get_synthPassthrough0pan(self): return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["synthPassthrough"][0]["panAmount"]
    def get_synthPassthrough0dry(self): return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["synthPassthrough"][0]["dryAmount"]
    def get_synthPassthrough1pan(self): return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["synthPassthrough"][1]["panAmount"]
    def get_synthPassthrough1dry(self): return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["synthPassthrough"][1]["dryAmount"]
    def get_synthPassthrough2pan(self): return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["synthPassthrough"][2]["panAmount"]
    def get_synthPassthrough2dry(self): return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["synthPassthrough"][2]["dryAmount"]
    def get_synthPassthrough3pan(self): return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["synthPassthrough"][3]["panAmount"]
    def get_synthPassthrough3dry(self): return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["synthPassthrough"][3]["dryAmount"]
    def get_synthPassthrough4pan(self): return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["synthPassthrough"][4]["panAmount"]
    def get_synthPassthrough4dry(self): return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["synthPassthrough"][4]["dryAmount"]
    synthPassthroughMixingChanged = Signal()
    synthPassthrough0pan = Property(float, get_synthPassthrough0pan, notify=synthPassthroughMixingChanged)
    synthPassthrough0dry = Property(float, get_synthPassthrough0dry, notify=synthPassthroughMixingChanged)
    synthPassthrough1pan = Property(float, get_synthPassthrough1pan, notify=synthPassthroughMixingChanged)
    synthPassthrough1dry = Property(float, get_synthPassthrough1dry, notify=synthPassthroughMixingChanged)
    synthPassthrough2pan = Property(float, get_synthPassthrough2pan, notify=synthPassthroughMixingChanged)
    synthPassthrough2dry = Property(float, get_synthPassthrough2dry, notify=synthPassthroughMixingChanged)
    synthPassthrough3pan = Property(float, get_synthPassthrough3pan, notify=synthPassthroughMixingChanged)
    synthPassthrough3dry = Property(float, get_synthPassthrough3dry, notify=synthPassthroughMixingChanged)
    synthPassthrough4pan = Property(float, get_synthPassthrough4pan, notify=synthPassthroughMixingChanged)
    synthPassthrough4dry = Property(float, get_synthPassthrough4dry, notify=synthPassthroughMixingChanged)
    ### END synthPassthrough properties

    ### BEGIN fxPassthrough properties
    @Slot(None)
    def handleFxPassthroughMixingChanged(self):
        for laneId in range(0, 5):
            fxPassthroughClient = Zynthbox.Plugin.instance().fxPassthroughClients()[self.__id__][laneId]
            panAmount = self.__audioTypeSettings__[self.audioTypeSettingsKey()]["fxPassthrough"][laneId]["panAmount"]
            dryWetMixAmount = self.__audioTypeSettings__[self.audioTypeSettingsKey()]["fxPassthrough"][laneId]["dryWetMixAmount"]
            # logging.info(f"Changing fx pan/wetdrymix amounts for {self.__id__} lane {laneId} from {fxPassthroughClient.panAmount()} and {fxPassthroughClient.dryWetMixAmount()} to {panAmount} and {dryWetMixAmount}")
            fxPassthroughClient.setPanAmount(panAmount)
            fxPassthroughClient.setDryWetMixAmount(dryWetMixAmount)
            self.zynqtgui.screens['snapshot'].schedule_save_last_state_snapshot()

    def get_fxPassthrough0pan(self):       return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["fxPassthrough"][0]["panAmount"]
    def get_fxPassthrough0dryWetMix(self): return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["fxPassthrough"][0]["dryWetMixAmount"]
    def get_fxPassthrough1pan(self):       return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["fxPassthrough"][1]["panAmount"]
    def get_fxPassthrough1dryWetMix(self): return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["fxPassthrough"][1]["dryWetMixAmount"]
    def get_fxPassthrough2pan(self):       return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["fxPassthrough"][2]["panAmount"]
    def get_fxPassthrough2dryWetMix(self): return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["fxPassthrough"][2]["dryWetMixAmount"]
    def get_fxPassthrough3pan(self):       return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["fxPassthrough"][3]["panAmount"]
    def get_fxPassthrough3dryWetMix(self): return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["fxPassthrough"][3]["dryWetMixAmount"]
    def get_fxPassthrough4pan(self):       return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["fxPassthrough"][4]["panAmount"]
    def get_fxPassthrough4dryWetMix(self): return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["fxPassthrough"][4]["dryWetMixAmount"]
    fxPassthroughMixingChanged = Signal()
    fxPassthrough0pan =       Property(float, get_fxPassthrough0pan, notify=fxPassthroughMixingChanged)
    fxPassthrough0dryWetMix = Property(float, get_fxPassthrough0dryWetMix, notify=fxPassthroughMixingChanged)
    fxPassthrough1pan =       Property(float, get_fxPassthrough1pan, notify=fxPassthroughMixingChanged)
    fxPassthrough1dryWetMix = Property(float, get_fxPassthrough1dryWetMix, notify=fxPassthroughMixingChanged)
    fxPassthrough2pan =       Property(float, get_fxPassthrough2pan, notify=fxPassthroughMixingChanged)
    fxPassthrough2dryWetMix = Property(float, get_fxPassthrough2dryWetMix, notify=fxPassthroughMixingChanged)
    fxPassthrough3pan =       Property(float, get_fxPassthrough3pan, notify=fxPassthroughMixingChanged)
    fxPassthrough3dryWetMix = Property(float, get_fxPassthrough3dryWetMix, notify=fxPassthroughMixingChanged)
    fxPassthrougg4pan =       Property(float, get_fxPassthrough4pan, notify=fxPassthroughMixingChanged)
    fxPassthrough4dryWetMix = Property(float, get_fxPassthrough4dryWetMix, notify=fxPassthroughMixingChanged)

    @Slot(None)
    def handleSketchFxPassthroughMixingChanged(self):
        for laneId in range(0, 5):
            try:
                fxPassthroughClient = Zynthbox.Plugin.instance().sketchFxPassthroughClients()[self.__id__][laneId]
                panAmount = self.__audioTypeSettings__[self.audioTypeSettingsKey()]["sketchFxPassthrough"][laneId]["panAmount"]
                dryWetMixAmount = self.__audioTypeSettings__[self.audioTypeSettingsKey()]["sketchFxPassthrough"][laneId]["dryWetMixAmount"]
                # logging.info(f"Changing fx pan/wetdrymix amounts for {self.__id__} lane {laneId} from {fxPassthroughClient.panAmount()} and {fxPassthroughClient.dryWetMixAmount()} to {panAmount} and {dryWetMixAmount}")
                fxPassthroughClient.setPanAmount(panAmount)
                fxPassthroughClient.setDryWetMixAmount(dryWetMixAmount)
                self.zynqtgui.screens['snapshot'].schedule_save_last_state_snapshot()
            except Exception as e:
                logging.error(f"Error occured in handlingSketchFxPassthroughMixingChanged : str(e)")

    def get_sketchFxPassthrough0pan(self):       return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["sketchFxPassthrough"][0]["panAmount"]
    def get_sketchFxPassthrough0dryWetMix(self): return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["sketchFxPassthrough"][0]["dryWetMixAmount"]
    def get_sketchFxPassthrough1pan(self):       return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["sketchFxPassthrough"][1]["panAmount"]
    def get_sketchFxPassthrough1dryWetMix(self): return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["sketchFxPassthrough"][1]["dryWetMixAmount"]
    def get_sketchFxPassthrough2pan(self):       return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["sketchFxPassthrough"][2]["panAmount"]
    def get_sketchFxPassthrough2dryWetMix(self): return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["sketchFxPassthrough"][2]["dryWetMixAmount"]
    def get_sketchFxPassthrough3pan(self):       return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["sketchFxPassthrough"][3]["panAmount"]
    def get_sketchFxPassthrough3dryWetMix(self): return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["sketchFxPassthrough"][3]["dryWetMixAmount"]
    def get_sketchFxPassthrough4pan(self):       return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["sketchFxPassthrough"][4]["panAmount"]
    def get_sketchFxPassthrough4dryWetMix(self): return self.__audioTypeSettings__[self.audioTypeSettingsKey()]["sketchFxPassthrough"][4]["dryWetMixAmount"]
    sketchFxPassthroughMixingChanged = Signal()
    sketchFxPassthrough0pan =       Property(float, get_sketchFxPassthrough0pan, notify=sketchFxPassthroughMixingChanged)
    sketchFxPassthrough0dryWetMix = Property(float, get_sketchFxPassthrough0dryWetMix, notify=sketchFxPassthroughMixingChanged)
    sketchFxPassthrough1pan =       Property(float, get_sketchFxPassthrough1pan, notify=sketchFxPassthroughMixingChanged)
    sketchFxPassthrough1dryWetMix = Property(float, get_sketchFxPassthrough1dryWetMix, notify=sketchFxPassthroughMixingChanged)
    sketchFxPassthrough2pan =       Property(float, get_sketchFxPassthrough2pan, notify=sketchFxPassthroughMixingChanged)
    sketchFxPassthrough2dryWetMix = Property(float, get_sketchFxPassthrough2dryWetMix, notify=sketchFxPassthroughMixingChanged)
    sketchFxPassthrough3pan =       Property(float, get_sketchFxPassthrough3pan, notify=sketchFxPassthroughMixingChanged)
    sketchFxPassthrough3dryWetMix = Property(float, get_sketchFxPassthrough3dryWetMix, notify=sketchFxPassthroughMixingChanged)
    sketchFxPassthrougg4pan =       Property(float, get_sketchFxPassthrough4pan, notify=sketchFxPassthroughMixingChanged)
    sketchFxPassthrough4dryWetMix = Property(float, get_sketchFxPassthrough4dryWetMix, notify=sketchFxPassthroughMixingChanged)
    ### END fxPassthrough properties
    ### END Passthrough properties

    ### BEGIN Audio Type Settings getter and setter
    @Slot(None,result=str)
    def getAudioTypeSettings(self):
        return json.dumps(self.__audioTypeSettings__)

    @Slot(str)
    def setAudioTypeSettings(self, audioTypeSettings):
        try:
            if isinstance(audioTypeSettings, dict):
                # If passed audioTypeSettings is a dict directly store it
                self.__audioTypeSettings__ = audioTypeSettings
            elif isinstance(audioTypeSettings, str):
                # If passed audioTypeSettings is a string try parsing it as a json
                self.__audioTypeSettings__ = json.loads(audioTypeSettings)

            # TODO : `channelPassthrough` key is deprecated and has been renamed to `trackPassthrough`. Remove this fallback later
            settings_updated = False
            for audioType in self.__audioTypeSettings__:
                if "channelPassthrough" in self.__audioTypeSettings__[audioType]:
                    warnings.warn("`channelPassthrough` key is deprecated (will be removed soon) and has been renamed to `trackPassthrough`. Update any existing references to avoid issues with loading sketchpad", DeprecationWarning)
                    self.__audioTypeSettings__[audioType]["trackPassthrough"] = self.__audioTypeSettings__[audioType]["channelPassthrough"]
                    del self.__audioTypeSettings__[audioType]["channelPassthrough"]
                    settings_updated = True
            if settings_updated:
                self.__song__.schedule_save()

            self.volume_changed.emit()
            self.panChanged.emit()
            self.dryAmountChanged.emit()
            self.wetFx1AmountChanged.emit()
            self.wetFx2AmountChanged.emit()
            self.synthPassthroughMixingChanged.emit()
            self.fxPassthroughMixingChanged.emit()
        except Exception as e:
            logging.error(f"Error restoring the audio type settings from given json: {e} - the json passed to this function was: \n{audioTypeSettings}")
    ### END Audio Type Settings getter and setter

    ### Begin property filterCutoffControllers
    def get_filterCutoffControllers(self):
        return self.__filter_cutoff_controllers

    filterCutoffControllersChanged = Signal()

    filterCutoffControllers = Property("QVariantList", get_filterCutoffControllers, notify=filterCutoffControllersChanged)
    ### End property filterCutoffControllers

    ### Begin property filterResonanceControllers
    def get_filterResonanceControllers(self):
        return self.__filter_resonance_controllers

    filterResonanceControllersChanged = Signal()

    filterResonanceControllers = Property("QVariantList", get_filterResonanceControllers, notify=filterResonanceControllersChanged)
    ### End property filterResonanceControllers

    ### Begin property fxFilterCutoffControllers
    def get_fxFilterCutoffControllers(self):
        return self.__fx_filter_cutoff_controllers

    fxFilterCutoffControllersChanged = Signal()

    fxFilterCutoffControllers = Property("QVariantList", get_fxFilterCutoffControllers, notify=fxFilterCutoffControllersChanged)
    ### End property fxFilterCutoffControllers

    ### Begin property fxFilterResonanceControllers
    def get_fxFilterResonanceControllers(self):
        return self.__fx_filter_resonance_controllers

    fxFilterResonanceControllersChanged = Signal()

    fxFilterResonanceControllers = Property("QVariantList", get_fxFilterResonanceControllers, notify=fxFilterResonanceControllersChanged)
    ### End property fxFilterResonanceControllers

    ### Begin property sketchFxFilterCutoffControllers
    def get_sketchFxFilterCutoffControllers(self):
        return self.__sketchfx_filter_cutoff_controllers

    sketchFxFilterCutoffControllersChanged = Signal()

    sketchFxFilterCutoffControllers = Property("QVariantList", get_sketchFxFilterCutoffControllers, notify=sketchFxFilterCutoffControllersChanged)
    ### End property sketchFxFilterCutoffControllers

    ### Begin property sketchFxFilterResonanceControllers
    def get_sketchFxFilterResonanceControllers(self):
        return self.__sketchfx_filter_resonance_controllers

    sketchFxFilterResonanceControllersChanged = Signal()

    sketchFxFilterResonanceControllers = Property("QVariantList", get_sketchFxFilterResonanceControllers, notify=sketchFxFilterResonanceControllersChanged)
    ### End property sketchFxFilterResonanceControllers

    ### Begin property chainedSoundsAcceptedChannels
    """
    This property will let the MidiRouter/Synctimer know what input channels the engine is listening to
    For MPE purpose, the synth engines needs to accept notes from any channel. But not all synth allows doing that
    For example, ZynAddSubFX does not support accepting midi notes from multiple channels.
    """
    def get_chainedSoundsAcceptedChannels(self):
        accepted_channels = []

        for index, midichannel in enumerate(self.chainedSounds):
            channels = []
            if midichannel >= 0 and self.checkIfLayerExists(midichannel):
                engine = self.zynqtgui.layer.layer_midi_map[midichannel].engine
                engine_nickname = engine.nickname.split("/")[0]

                # The following engines does not support notes from multiple channels. It only accepts notes from the midi channel it is assigned
                non_mpe_engines = ["ZY", "BF", "AE"]
                if engine_nickname in non_mpe_engines:
                    if engine_nickname == "AE":
                        # Aeolus engine has 4 instruments and accepts notes only on those channels 0 to 3 inclusive
                        # So set accepted channel to selected instrument
                        channels = [engine.selected_instrument]
                    else:
                        channels = [layer.midi_chan for layer in engine.layers]
                else:
                    # Other engines accepts notes from any midi channel
                    channels = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15]
            accepted_channels.append(channels)

        return accepted_channels

    chainedSoundsAcceptedChannelsChanged = Signal()

    chainedSoundsAcceptedChannels = Property("QVariantList", get_chainedSoundsAcceptedChannels, notify=chainedSoundsAcceptedChannelsChanged)
    ### End property chainedSoundsAcceptedChannels

    ### BEGIN Property synthSlotsData
    def get_synthSlotsData(self):
        return self.chainedSoundsNames
    synthSlotsData = Property("QVariantList", get_synthSlotsData, notify=chainedSoundsNamesChanged)
    ### END Property synthSlotsData

    ### BEGIN Property sampleSlotsData
    def get_sampleSlotsData(self):
        return self.samples
    sampleSlotsData = Property("QVariantList", get_sampleSlotsData, notify=samples_changed)
    ### END Property sampleSlotsData

    ### BEGIN Property sketchSlotsData
    def get_sketchSlotsData(self):
        clips = []
        for clip_index in range(Zynthbox.Plugin.instance().sketchpadSlotCount()):
            clips_model = self.getClipsModelById(clip_index)
            clips.append(clips_model.getClip(self.__song__.scenesModel.selectedSketchpadSongIndex))
        return clips
    sketchSlotsDataChanged = Signal()
    sketchSlotsData = Property("QVariantList", get_sketchSlotsData, notify=sketchSlotsDataChanged)
    ### END Property sketchSlotsData

    ### BEGIN Property fxSlotsData
    def get_fxSlotsData(self):
        return self.chainedFxNames
    fxSlotsData = Property("QVariantList", get_fxSlotsData, notify=chainedFxNamesChanged)
    ### END Property fxSlotsData

    ### BEGIN Property sketchFxSlotsData
    def get_sketchFxSlotsData(self):
        return self.chainedSketchFxNames
    sketchFxSlotsData = Property("QVariantList", get_sketchFxSlotsData, notify=chainedSketchFxNamesChanged)
    ### END Property sketchFxSlotsData

    ### BEGIN Property externalSlotsData
    def get_externalSlotsData(self):
        def humanReadableExternalClientName(clientName):
            if clientName == "":
                return "None"
            elif clientName == "system:":
                return "Mic In"
            elif clientName == "system:capture_1":
                return "Mic In (L)"
            elif clientName == "system:capture_2":
                return "Mic In (R)"
            elif clientName == "usb-gadget-in:":
                return "USB In"
            elif clientName == "usb-gadget-in:capture_1":
                return "USB In (L)"
            elif clientName == "usb-gadget-in:capture_2":
                return "USB In (R)"
            else:
                return clientName

        midiOutDeviceName = "Midi Out Device"
        if self.__externalSettings__.midiOutDevice == "":
            midiOutDeviceName = "Midi 5-Pin"
        else:
            midiOutDeviceName = self.__externalSettings__.midiOutDevice
            availableDevices = Zynthbox.MidiRouter.instance().model().midiOutSources()
            for device in availableDevices:
                if device["value"] == self.__externalSettings__.midiOutDevice:
                    midiOutDeviceName = device["text"]
                    break

        return [f"Capture: {humanReadableExternalClientName(self.externalAudioSource)}",
                f"Midi Channel: {(self.externalMidiChannel + 1) if self.externalMidiChannel > -1 else (self.id + 1)}",
                midiOutDeviceName,
                None,
                None]
    externalSlotsDataChanged = Signal()
    externalSlotsData = Property("QVariantList", get_externalSlotsData, notify=externalSlotsDataChanged)
    ### END Property externalSlotsData

    ### BEGIN Property occupiedSynthSlots
    def get_occupiedSynthSlots(self):
        return [sound != "" for sound in self.chainedSoundsNames]

    occupiedSynthSlots = Property("QVariantList", get_occupiedSynthSlots, notify=chainedSoundsNamesChanged)
    ### END Property occupiedSynthSlots

    ### BEGIN Property occupiedSampleSlots
    def get_occupiedSampleSlots(self):
        return [sample is not None and sample.path is not None and len(sample.path) > 0 for sample in self.samples]

    occupiedSampleSlots = Property("QVariantList", get_occupiedSampleSlots, notify=samples_changed)
    ### END Property occupiedSampleSlots

    ### BEGIN Property occupiedSketchSlots
    def get_occupiedSketchSlots(self):
        occupied_slots = []
        for clip_id in range(5):
            clip = self.getClipsModelById(clip_id).getClip(self.zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
            if clip is not None and clip.path is not None and len(clip.path) > 0:
                occupied_slots.append(True)
            else:
                occupied_slots.append(False)
        return occupied_slots

    occupiedSketchSlots = Property("QVariantList", get_occupiedSketchSlots, notify=sketchSlotsDataChanged)
    ### END Property occupiedSketchSlots

    ### BEGIN Property occupiedFxSlots
    def get_occupiedFxSlots(self):
        return [fx != "" for fx in self.chainedFxNames]

    occupiedFxSlots = Property("QVariantList", get_occupiedFxSlots, notify=chainedFxNamesChanged)
    ### END Property occupiedFxSlots

    ### BEGIN Property occupiedSketchFxSlots
    def get_occupiedSketchFxSlots(self):
        return [fx != "" for fx in self.chainedSketchFxNames]

    occupiedSketchFxSlots = Property("QVariantList", get_occupiedSketchFxSlots, notify=chainedSketchFxNamesChanged)
    ### END Property occupiedSketchFxSlots

    @Slot(int)
    def selectPreviousSynthPreset(self, slot_index):
        midi_channel = self.chainedSounds[slot_index]

        if midi_channel >= 0 and self.checkIfLayerExists(midi_channel):
            layer = self.zynqtgui.layer.layer_midi_map[midi_channel]
            if layer.preset_index > 0:
                prev_volume = None
                try:
                    prev_volume = self.zynqtgui.fixed_layers.volumeControllers[midi_channel].value
                except Exception: pass

                layer.set_preset(layer.preset_index - 1)
                self.zynqtgui.fixed_layers.update_mixers()

                if prev_volume is not None:
                    try:
                        self.zynqtgui.fixed_layers.volumeControllers[midi_channel].value = prev_volume
                    except Exception: pass

                self.zynqtgui.preset.select(layer.preset_index)
                self.zynqtgui.layer.emit_layer_preset_changed(layer)
                self.zynqtgui.screens['control'].show()
                self.zynqtgui.layer.fill_list()
                self.zynqtgui.screens['snapshot'].schedule_save_last_state_snapshot()
                self.chainedSoundsNamesChanged.emit()

    @Slot(int)
    def selectNextSynthPreset(self, slot_index):
        midi_channel = self.chainedSounds[slot_index]

        if midi_channel >= 0 and self.checkIfLayerExists(midi_channel):
            layer = self.zynqtgui.layer.layer_midi_map[midi_channel]
            if layer.preset_index < len(layer.preset_list) - 1:
                prev_volume = None
                try:
                    prev_volume = self.zynqtgui.fixed_layers.volumeControllers[midi_channel].value
                except Exception: pass

                layer.set_preset(layer.preset_index + 1)
                self.zynqtgui.fixed_layers.update_mixers()

                if prev_volume is not None:
                    try:
                        self.zynqtgui.fixed_layers.volumeControllers[midi_channel].value = prev_volume
                    except Exception: pass

                self.zynqtgui.preset.select(layer.preset_index)
                self.zynqtgui.layer.emit_layer_preset_changed(layer)
                self.zynqtgui.screens['control'].show()
                self.zynqtgui.layer.fill_list()
                self.zynqtgui.screens['snapshot'].schedule_save_last_state_snapshot()
                self.chainedSoundsNamesChanged.emit()

    @Slot(int)
    def selectPreviousFxPreset(self, slot_index):
        layer = self.chainedFx[slot_index]

        if layer is not None and layer.preset_index > 0:
            layer.set_preset(layer.preset_index - 1)
            self.zynqtgui.preset.select(layer.preset_index)
            self.zynqtgui.layer.emit_layer_preset_changed(layer)
            self.zynqtgui.screens['control'].show()
            self.zynqtgui.layer.fill_list()
            self.zynqtgui.screens['snapshot'].schedule_save_last_state_snapshot()
            self.chainedFxNamesChanged.emit()

    @Slot(int)
    def selectNextFxPreset(self, slot_index):
        layer = self.chainedFx[slot_index]

        if layer is not None and layer.preset_index < len(layer.preset_list) - 1:
            layer.set_preset(layer.preset_index + 1)
            self.zynqtgui.preset.select(layer.preset_index)
            self.zynqtgui.layer.emit_layer_preset_changed(layer)
            self.zynqtgui.screens['control'].show()
            self.zynqtgui.layer.fill_list()
            self.zynqtgui.screens['snapshot'].schedule_save_last_state_snapshot()
            self.chainedFxNamesChanged.emit()

    @Slot(None, result=QObject)
    def getClipToRecord(self):
        if self.selectedSlot.className == "TracksBar_sketchslot":
            return self.getClipsModelById(self.selectedSlot.value).getClip(self.__song__.scenesModel.selectedSketchpadSongIndex)
        else:
            return self.samples[self.selectedSlot.value]

    @Slot(str)
    def setChannelSamplesFromSnapshot(self, snapshot: str):
        def task():
            snapshot_obj = json.loads(snapshot)
            for index, key in enumerate(snapshot_obj):
                if index > 4:
                    logging.error("For some reason we have more than five elements in the encoded sample data, what happened?!")
                    break;
                filename = snapshot_obj[key]["filename"]
                # Clear out the existing sample, whether or not there's a new sample to go into that spot
                self.__samples__[index].clear()
                # If the filename is an empty string, nothing to load
                if len(filename) > 0:
                    # Store the new sample in a temporary file
                    with tempfile.TemporaryDirectory() as tmp:
                        temporaryFile = Path(tmp) / filename
                        with open(temporaryFile, "wb") as file:
                            file.write(base64.b64decode(snapshot_obj[key]["sampledata"]))
                        # Now set this slot's path to that, and should_copy is True by default, but let's be explicit so we can make sure it keeps working
                        self.__samples__[index].set_path(str(temporaryFile), should_copy=True)
                        # Restore the metadata, if it's been saved to the snapshot (otherwise load it from disk)
                        if "metadata" in snapshot_obj[key]:
                            self.__samples__[index].metadata.deserialize(snapshot_obj[key]["metadata"])
                        else:
                            self.__samples__[index].metadata.clear()
                            # If the metadata doesn't exist in the object passed to us, read it out of the file itself, if that exists
                            if self.__samples__[index].audioSource is not None:
                                self.__samples__[index].metadata.read()
            self.zynqtgui.end_long_task()
        self.zynqtgui.do_long_task(task, "Loading samples")

    @Slot(str, int, int)
    def setChannelSampleFromSnapshotSlot(self, snapshot: str, slotIndex:int, snapshotIndex:int):
        if -1 < slotIndex and slotIndex < Zynthbox.Plugin.instance().sketchpadSlotCount() and -1 < snapshotIndex and snapshotIndex < Zynthbox.Plugin.instance().sketchpadSlotCount():
            sampleClip = self.__samples__[slotIndex]
            self.setClipSourceFromSnapshotSlot(snapshot, snapshotIndex, sampleClip)

    @Slot(str, int, int)
    def setSketchFromSnapshotSlot(self, snapshot: str, slotIndex:int, snapshotIndex:int):
        if -1 < slotIndex and slotIndex < Zynthbox.Plugin.instance().sketchpadSlotCount() and -1 < snapshotIndex and snapshotIndex < Zynthbox.Plugin.instance().sketchpadSlotCount():
            sketch = self.getClipsModelById(slotIndex).getClip(self.core_gui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
            self.setClipSourceFromSnapshotSlot(snapshot, snapshotIndex, sketch)

    def setClipSourceFromSnapshotSlot(self, snapshot: str, snapshotIndex: int, clip):
        def task():
            snapshot_obj = json.loads(snapshot)
            if snapshotIndex < len(snapshot_obj):
                for index, key in enumerate(snapshot_obj):
                    if index == snapshotIndex: # key isn't just an index, so... let's do this thing
                        filename = snapshot_obj[key]["filename"]
                        # Clear out the existing sample, whether or not there's a new sample to go into that spot
                        clip.clear()
                        # If the filename is an empty string, nothing to load
                        if len(filename) > 0:
                            # Store the new sample in a temporary file
                            with tempfile.TemporaryDirectory() as tmp:
                                temporaryFile = Path(tmp) / filename
                                with open(temporaryFile, "wb") as file:
                                    file.write(base64.b64decode(snapshot_obj[key]["sampledata"]))
                                # Now set this slot's path to that, and should_copy is True by default, but let's be explicit so we can make sure it keeps working
                                clip.set_path(str(temporaryFile), should_copy=True)
                                # Restore the metadata, if it's been saved to the snapshot (otherwise load it from disk)
                                clip.metadata.clear()
                                if "metadata" in snapshot_obj[key]:
                                    if len(snapshot_obj[key]["metadata"]) > 0:
                                        self.__samples__[index].metadata.deserialize(snapshot_obj[key]["metadata"])
                                else:
                                    # If the metadata doesn't exist in the object passed to us, read it out of the file itself, if that exists
                                    if clip.audioSource is not None:
                                        clip.metadata.read()
                        break
            self.zynqtgui.end_long_task()
        self.zynqtgui.do_long_task(task, f"Loading sample data from snapshot into slot {clip.id} on Track {self.name}")

    @Slot(None, result=str)
    def getChannelSampleSnapshot(self):
        encodedSampleData = {};
        for index in range(0, 5):
            sample = self.__samples__[index]
            thisSample = {
                "filename": "",
                "metadata": "",
                "sampledata": ""
                }
            if sample is not None and sample.path is not None and len(sample.path) > 0:
                thisSample["filename"] = sample.filename
                thisSample["metadata"] = sample.metadata.serialize()
                with open(sample.path, "rb") as file:
                    thisSample["sampledata"] = base64.b64encode(file.read()).decode("utf-8")
            encodedSampleData[index] = thisSample
        return json.dumps(encodedSampleData)

    @Slot(None, result=str)
    def getChannelSoundSnapshot(self):
        if self.__sound_snapshot_changed:
            # logging.debug(f"Updating sound snapshot json of Track {self.name}")
            self.__sound_json_snapshot__ = json.dumps(self.zynqtgui.layer.generate_snapshot(self))
            self.__sound_snapshot_changed = False
        return self.__sound_json_snapshot__

    @Slot(str, str, int, int, result=None)
    def setChannelSoundFromSnapshotSlot(self, snapshot, slotType, slotIndex:int, snapshotIndex:int):
        if not (slotType == "synth" or slotType == "fx"):
            return
        if slotIndex < 0 or Zynthbox.Plugin.instance().sketchpadSlotCount() - 1 < slotIndex:
            return
        if snapshotIndex < 0 or Zynthbox.Plugin.instance().sketchpadSlotCount() - 1 < snapshotIndex:
            return

        def task():
            snapshot_obj = json.loads(snapshot)
            source_channels = self.zynqtgui.layer.load_layer_channels_from_json(snapshot)

            def post_removal_task():
                free_layers = self.getFreeLayers()
                if slotType == "synth" and len(free_layers) == 0:
                    logging.error(f"There are no more free channels, and we need at least one to load a synth into this slot")
                else:
                    # Populate new chained sounds and update channel
                    limitedSnapshot = {"layers": []}
                    for index, snapshotEntry in enumerate(snapshot_obj["layers"]):
                        if snapshotEntry["slot_index"] == slotIndex:
                            snapshotEntry["track_index"] = self.id
                            if slotType == "synth":
                                # Repopulate after removing current channel layers
                                free_layers = self.getFreeLayers()
                                new_chained_sounds = self.chained_sounds
                                new_chained_sounds[slotIndex] = free_layers[0]
                                snapshotEntry["midi_chan"] = free_layers[index]
                            limitedSnapshot["layers"].append(snapshotEntry)
                            break
                    if len(limitedSnapshot["layers"]) > 0:
                        self.zynqtgui.layer.load_channels_snapshot(limitedSnapshot)
                        if slotType == "synth":
                            self.chainedSounds = new_chained_sounds
                        # Run autoconnect after completing loading sounds
                        self.zynqtgui.zynautoconnect()
                    else:
                        logging.error(f"There is nothing to restore from the slot we were asked to restore from")
                self.zynqtgui.end_long_task()
            # Reset preset view to show all presets
            self.zynqtgui.preset.show_only_favorites = False
            if self.chainedSounds[slotIndex] > -1:
                self.remove_and_unchain_sound(self.chainedSounds[slotIndex], post_removal_task)
            else:
                post_removal_task()
        self.zynqtgui.do_long_task(task, f"Loading {slotType} {snapshotIndex + 1} into slot {slotIndex + 1} on Track {self.name}")

    @Slot(str, result=None)
    def setChannelSoundFromSnapshot(self, snapshot):
        def task():
            snapshot_obj = json.loads(snapshot)
            source_channels = self.zynqtgui.layer.load_layer_channels_from_json(snapshot)
            free_layers = self.getFreeLayers()
            used_layers = []

            for i in self.chainedSounds:
                if i >= 0 and self.checkIfLayerExists(i):
                    used_layers.append(i)

            logging.debug("### Before Removing")
            logging.debug(f"# Selected Channel         : {self.id}")
            logging.debug(f"# Source Channels        : {source_channels}")
            logging.debug(f"# Free Layers            : {free_layers}")
            logging.debug(f"# Used Layers            : {used_layers}")
            logging.debug(f"# Chained Sounds         : {self.chainedSounds}")
            logging.debug(f"# Source Channels Count  : {len(source_channels)}")
            logging.debug(f"# Available Layers Count : {len(free_layers) + len(used_layers)}")

            # Check if count of channels required to load sound is available or not
            # Available count of channels : used layers by current channel (will get replaced) + free layers
            if (len(free_layers) + len(used_layers)) < len(source_channels):
                logging.debug(f"{len(source_channels) - len(free_layers) - len(used_layers)} more free channels are required to load sound. Please remove some sound from channels to continue.")
            else:
                # Required free channel count condition satisfied. Continue loading.

                # A counter to keep channel of numner of callbacks called
                # so that post_removal_task can be executed after all callbacks are called
                cb_counter = 0

                def post_removal_task():
                    nonlocal cb_counter
                    cb_counter -= 1

                    # Check if all callbacks are called
                    # If all callbacks are called then continue with post_removal_task
                    # Otherwise return
                    if cb_counter > 0:
                        return
                    else:
                        # Remove all fx
                        for i in range(Zynthbox.Plugin.instance().sketchpadSlotCount()):
                            self.removeFxFromChain(i, showLoadingScreen=False)

                        # Repopulate after removing current channel layers
                        free_layers = self.getFreeLayers()
                        # Populate new chained sounds and update channel
                        new_chained_sounds = [-1, -1, -1, -1, -1]

                        # Iterate over all the layers in snapshot_obj and update midi_chan such as
                        # - In case of a MIDI Synth, it is a new free layer
                        # - In case of an Audio Effect, it is the track id
                        for index, _ in enumerate(snapshot_obj["layers"]):
                            if snapshot_obj["layers"][index]["engine_type"] == "MIDI Synth":
                                snapshot_obj["layers"][index]["midi_chan"] = free_layers[index]
                                snapshot_obj["layers"][index]["track_index"] = self.id
                                new_chained_sounds[snapshot_obj["layers"][index]["slot_index"]] = free_layers[index]
                            elif snapshot_obj["layers"][index]["engine_type"] == "Audio Effect":
                                snapshot_obj["layers"][index]["track_index"] = self.id

                        self.zynqtgui.currentTaskMessage = f"Loading selected sounds in Track {self.name}"
                        self.zynqtgui.layer.load_channels_snapshot(snapshot_obj)

                        self.chainedSounds = new_chained_sounds

                        # Repopulate after loading sound
                        free_layers = self.getFreeLayers()

                        logging.debug("### After Loading")
                        logging.debug(f"# Free Layers            : {free_layers}")
                        logging.debug(f"# Chained Sounds         : {self.chainedSounds}")

                        # Run autoconnect after completing loading sounds
                        self.zynqtgui.zynautoconnect()

                        # Update curlayer by selected slot type
                        self.setCurlayerByType(self.selectedSlot.className)

                # Reset preset view to show all presets
                self.zynqtgui.preset.show_only_favorites = False
                if len(used_layers) > 0:
                    # Remove all current sounds from channel
                    for i in used_layers:
                        cb_counter += 1
                        self.remove_and_unchain_sound(i, post_removal_task)
                else:
                    # If there are no sounds in curent channel, immediately do post removal task
                    post_removal_task()
            self.zynqtgui.end_long_task()
        self.zynqtgui.do_long_task(task, f"Loading sound onto Track {self.name}")

    @Slot(str)
    def setCurlayerByType(self, type):
        if type == "synth" or type == "TracksBar_synthslot":
            sound = self.chainedSounds[self.__selected_slot_row__]
            if sound >= 0 and self.checkIfLayerExists(sound):
                self.zynqtgui.set_curlayer(self.zynqtgui.layer.layer_midi_map[sound])
            else:
                self.zynqtgui.set_curlayer(None)
        elif type == "fx" or type == "TracksBar_fxslot":
            self.zynqtgui.set_curlayer(self.chainedFx[self.selectedSlot.value])
        elif type == "sketch-fx" or type == "TracksBar_sketchfxslot":
            self.zynqtgui.set_curlayer(self.chainedSketchFx[self.selectedSlot.value])
        elif type == "loop" or type == "sample-loop" or type == "TracksBar_sketchslot":
            self.zynqtgui.set_curlayer(None)
        elif type == "sample" or type == "sample-trig" or type == "TracksBar_sampleslot":
            self.zynqtgui.set_curlayer(None)
        elif type == "external" or type == "TracksBar_externalslot":
            self.zynqtgui.set_curlayer(None)
        else:
            self.zynqtgui.set_curlayer(None)

    @Slot("QVariantList", str)
    def reorderSlots(self, newOrder, slotType = None):
        """
        This method will reorder the synth/sketch/sample slots as per the new index order provided in newOrder depending upon slotType
        """
        # TODO : Use selectedSketchpadSongIndex instead of hardcoding it to 0 after renaming it to something that does not interfere with the name track
        _slotType = slotType
        if _slotType is None:
            _slotType = self.trackType
        if _slotType == "synth":
            # Reorder synths
            # Form a new chainedSounds as per newOrder
            newChainedSounds = [self.__chained_sounds__[index] for index in newOrder]
            newKeyZoneData = [self.__chained_sounds_keyzones__[index] for index in newOrder]

            # Update slot_index of all the zynthian_layer objects
            for index, midiChannel in enumerate(newChainedSounds):
                if midiChannel >=0 and self.checkIfLayerExists(midiChannel):
                    layer = self.zynqtgui.layer.layer_midi_map[midiChannel]
                    layer.slot_index = index

            self.set_chained_sounds(newChainedSounds, updateRoutingData=False)

            # If we've got a manual keyzone setup, ensure we're moving the things around there as well
            if self.__keyzone_mode__ == "manual":
                self.__chained_sounds_keyzones__ = newKeyZoneData
                for slotIndex, keyzoneData in enumerate(self.__chained_sounds_keyzones__):
                    self. handleChainedSoundsKeyzoneChanged(keyzoneData, slotIndex)

            newRoutingData = [self.__routingData__["synth"][index] for index in newOrder]
            self.__routingData__["synth"] = newRoutingData
        elif _slotType == "sample-loop":
            # Reorder sketches
            old_order_clips = [self.getClipsModelById(index).getClip(0) for index in range(5)]
            for index, clip in enumerate(old_order_clips):
                if index != newOrder[index]:
                    self.getClipsModelById(newOrder[index]).__clips__[0] = clip
                    clip.id = newOrder[index]
                    clip.set_lane(clip.id)
            self.__song__.schedule_save()
        elif _slotType == "sample-trig":
            # Reorder samples
            new_order_samples = [self.samples[index] for index in newOrder]
            for index, sample in enumerate(new_order_samples):
                sample.id = index
                sample.set_lane(index)
            self.__samples__ = new_order_samples
            self.samples_changed.emit()

        # Update trackPassthrough values in audioTypeSettings to retain correct values after re-ordering
        newAudioTypeSettings = json.loads(self.getAudioTypeSettings())
        newAudioTypeSettings[self.audioTypeKey("synth")]["trackPassthrough"] = [newAudioTypeSettings[self.audioTypeKey("synth")]["trackPassthrough"][index] for index in newOrder]
        self.setAudioTypeSettings(json.dumps(newAudioTypeSettings))

        self.slotsReordered.emit()

    @Slot(int, int, str)
    def swapSlots(self, slot1, slot2, slotType = None):
        """
        Swap positions of two synth/sketch/sample slots at index slot1 and slot2 depending upon slotType
        """
        _slotType = slotType
        if _slotType is None:
            _slotType = self.trackType
        newOrder = [0, 1, 2, 3, 4]
        newOrder[slot1] = slot2
        newOrder[slot2] = slot1
        self.reorderSlots(newOrder, _slotType)

    @Slot("QVariantList")
    def reorderChainedFx(self, newOrder):
        """
        This method will reorder the chained FX engines as per the new index order provided in newOrder
        """
        # Form a new chainedFx as per newOrder
        newChainedFx = [self.__chained_fx[index] for index in newOrder]

        # Update slot_index of all the zynthian_layer objects
        for index, fx in enumerate(newChainedFx):
            if fx is not None:
                fx.slot_index = index

        # Swap the routing data
        newRoutingData = [self.__routingData__["fx"][index] for index in newOrder]
        self.__routingData__["fx"] = newRoutingData

        # Update fxPassthrough values in audioTypeSettings to retain correct values after re-ordering
        newAudioTypeSettings = json.loads(self.getAudioTypeSettings())
        for audioType in newAudioTypeSettings:
            newAudioTypeSettings[audioType]["fxPassthrough"] = [newAudioTypeSettings[audioType]["fxPassthrough"][index] for index in newOrder]
        self.setAudioTypeSettings(json.dumps(newAudioTypeSettings))

        # Update chainedFx
        self.set_chainedFx(newChainedFx)
        self.zynqtgui.zynautoconnect()

    @Slot(int, int)
    def swapChainedFx(self, slot1, slot2):
        """
        Swap positions of two FX engines in chainedFx located at index slot1 and slot2
        """
        newOrder = [0, 1, 2, 3, 4]
        newOrder[slot1] = slot2
        newOrder[slot2] = slot1
        self.reorderChainedFx(newOrder)

    @Slot("QVariantList")
    def reorderChainedSketchFx(self, newOrder):
        """
        This method will reorder the chained FX engines as per the new index order provided in newOrder
        """
        # Form a new chainedFx as per newOrder
        newChainedSketchFx = [self.__chained_sketch_fx[index] for index in newOrder]

        # Update slot_index of all the zynthian_layer objects
        for index, fx in enumerate(newChainedSketchFx):
            if fx is not None:
                fx.slot_index = index

        # Swap the routing data : TODO sketchFx
        # newRoutingData = [self.__routingData__["fx"][index] for index in newOrder]
        # self.__routingData__["fx"] = newRoutingData

        # Update fxPassthrough values in audioTypeSettings to retain correct values after re-ordering
        newAudioTypeSettings = json.loads(self.getAudioTypeSettings())
        for audioType in newAudioTypeSettings:
            newAudioTypeSettings[audioType]["sketchFxPassthrough"] = [newAudioTypeSettings[audioType]["sketchFxPassthrough"][index] for index in newOrder]
        self.setAudioTypeSettings(json.dumps(newAudioTypeSettings))

        # Update chainedFx
        self.set_chainedSketchFx(newChainedSketchFx)
        self.zynqtgui.zynautoconnect()

    @Slot(int, int)
    def swapChainedSketchFx(self, slot1, slot2):
        """
        Swap positions of two FX engines in chainedFx located at index slot1 and slot2
        """
        newOrder = [0, 1, 2, 3, 4]
        newOrder[slot1] = slot2
        newOrder[slot2] = slot1
        self.reorderChainedSketchFx(newOrder)

    slotsReordered = Signal()
    className = Property(str, className, constant=True)
