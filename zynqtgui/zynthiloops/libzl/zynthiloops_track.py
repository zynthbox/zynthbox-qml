#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# A model to for storing tracks in ZynthiLoops page
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
import math
import threading

from PySide2.QtCore import Property, QObject, QThread, Signal, Slot

from . import libzl
from .zynthiloops_clips_model import zynthiloops_clips_model
from .zynthiloops_clip import zynthiloops_clip
from ... import zynthian_gui_config

class zynthiloops_track(QObject):
    # Possible Values : "audio", "video"
    __type__ = "audio"

    def __init__(self, id: int, song: QObject, parent: QObject = None):
        super(zynthiloops_track, self).__init__(parent)
        self.zyngui = zynthian_gui_config.zyngui
        self.__id__ = id
        self.__name__ = None
        self.__song__ = song
        self.__initial_volume__ = 0
        self.__volume__ = self.__initial_volume__
        self.__audio_level__ = -200
        self.__clips_model__ = zynthiloops_clips_model(song, self)
        self.__layers_snapshot = []
        self.master_volume = libzl.dbFromVolume(self.__song__.get_metronome_manager().get_master_volume()/100)
        self.__song__.get_metronome_manager().master_volume_changed.connect(lambda: self.master_volume_changed())
        self.__connected_pattern__ = -1
        # self.__connected_sound__ = -1
        self.__chained_sounds__ = [-1, -1, -1, -1, -1]
        self.zyngui.screens["layer"].layer_deleted.connect(self.layer_deleted)
        self.__muted__ = False
        # self.chained_sounds_changed.connect(self.select_correct_layer)

        if self.__id__ < 5:
            # self.__connected_sound__ = self.__id__
            self.__chained_sounds__[0] = self.__id__

        # Connect to default patterns on init
        # This will be overwritten by deserialize if user changed the value, so it is safe to always set the value
        if self.__id__ > 5 and self.__id__ < 11:
             self.__connected_pattern__ = self.__id__ - 6

    def layer_deleted(self, chan : int):
        self.set_chained_sounds([-1 if x==chan else x for x in self.__chained_sounds__])

    def select_correct_layer(self):
        zyngui = self.__song__.get_metronome_manager().zyngui
        if self.checkIfLayerExists(zyngui.active_midi_channel):
            logging.error("### select_correct_layer : Reselect any available sound since it is removing current selected channel")
            # zyngui.screens['session_dashboard'].set_selected_track(zyngui.screens['session_dashboard'].selectedTrack, True)
            try:
                zyngui.screens["layers_for_track"].update_track_sounds()
            except:
                pass
        else:
            logging.error("### select_correct_layer : Do not Reselect track sound since it is not removing current selected channel")

    def master_volume_changed(self):
        self.master_volume = libzl.dbFromVolume(self.__song__.get_metronome_manager().get_master_volume()/100)
        logging.error(f"Master Volume : {self.master_volume} dB")

    def serialize(self):
        return {"name": self.__name__,
                "volume": self.__volume__,
                "connectedPattern": self.__connected_pattern__,
                # "connectedSound": self.__connected_sound__,
                "chainedSounds": self.__chained_sounds__,
                "clips": self.__clips_model__.serialize(),
                "layers_snapshot": self.__layers_snapshot}

    def deserialize(self, obj):
        if "name" in obj:
            self.__name__ = obj["name"]
        if "volume" in obj:
            self.__volume__ = obj["volume"]
            self.set_volume(self.__volume__, True)
        if "connectedPattern" in obj:
            self.__connected_pattern__ = obj["connectedPattern"]
            self.set_connected_pattern(self.__connected_pattern__)
        # if "connectedSound" in obj:
        #     self.__connected_sound__ = obj["connectedSound"]
        #     self.set_connected_sound(self.__connected_sound__)
        if "chainedSounds" in obj:
            self.__chained_sounds__ = obj["chainedSounds"]
            self.set_chained_sounds(self.__chained_sounds__)
        if "clips" in obj:
            self.__clips_model__.deserialize(obj["clips"])
        if "layers_snapshot" in obj:
            self.__layers_snapshot = obj["layers_snapshot"]
            self.sound_data_changed.emit()

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


    @Slot(None)
    def clear(self):
        track = self.__song__.tracksModel.getTrack(self.__id__)
        clipsModel = track.clipsModel

        logging.error(f"Track {track} ClipsModel {clipsModel}")

        for clip_index in range(0, clipsModel.count):
            logging.error(f"Track {self.__id__} Clip {clip_index}")
            clip: zynthiloops_clip = clipsModel.getClip(clip_index)
            logging.error(
                f"Clip : clip.row({clip.row}), clip.col({clip.col}), clip({clip})")
            clip.clear()

    @Signal
    def __name_changed__(self):
        pass

    def name(self):
        if self.__name__ is None:
            return f"T{self.__id__ + 1}"
        else:
            return self.__name__

    def set_name(self, name):
        if name != f"T{self.__id__ + 1}":
            self.__name__ = name
            self.__name_changed__.emit()
            self.__song__.schedule_save()

    name = Property(str, name, set_name, notify=__name_changed__)


    @Signal
    def volume_changed(self):
        pass

    def get_volume(self):
        return self.__volume__

    def set_volume(self, volume:int, force_set=False):
        if self.__volume__ != math.floor(volume) or force_set is True:
            self.__volume__ = math.floor(volume)
            logging.error(f"Track : Setting volume {self.__volume__}")
            self.volume_changed.emit()
            self.__song__.schedule_save()

    volume = Property(int, get_volume, set_volume, notify=volume_changed)

    ### Property initialVolume
    def get_initial_volume(self):
        return self.__initial_volume__
    initialVolume = Property(int, get_initial_volume, constant=True)
    ### END Property initialVolume

    def type(self):
        return self.__type__
    type = Property(str, type, constant=True)

    def clipsModel(self):
        return self.__clips_model__
    clipsModel = Property(QObject, clipsModel, constant=True)

    @Slot(None)
    def delete(self):
        self.__song__.tracksModel.delete_track(self)

    def set_id(self, new_id):
        self.__id__ = new_id
        self.__name_changed__.emit()


    @Signal
    def audioLevelChanged(self):
        pass

    def get_audioLevel(self):
        return self.__audio_level__

    def set_audioLevel(self, leveldB):
        self.__audio_level__ = leveldB + self.__volume__ + self.master_volume
        self.audioLevelChanged.emit()

    audioLevel = Property(float, get_audioLevel, set_audioLevel, notify=audioLevelChanged)

    @Slot(None, result=bool)
    def isEmpty(self):
        is_empty = True

        for clip_index in range(0, self.__clips_model__.count):
            clip: zynthiloops_clip = self.__clips_model__.getClip(clip_index)
            if clip.path is not None and len(clip.path) > 0:
                is_empty = False
                break

        return is_empty

    @Slot(QObject)
    def copyFrom(self, source):
        for clip_index in range(0, self.__clips_model__.count):
            self.clipsModel.getClip(clip_index).copyFrom(source.clipsModel.getClip(clip_index))

    @Slot(int, result=bool)
    def createChainedSoundInNextFreeLayer(self, index):
        zyngui = self.__song__.get_metronome_manager().zyngui
        assigned_layers = [x for x in zyngui.screens["layer"].layer_midi_map.keys()]
        next_free_layer = -1

        logging.error(f"Already Assigned layers : {assigned_layers}")

        for i in range(0, 15):
            if i not in assigned_layers:
                next_free_layer = i
                break

        if next_free_layer == -1:
            return False
        else:
            logging.error(f"Next free layer : {next_free_layer}")
            zyngui.screens["fixed_layers"].activate_index(next_free_layer)

            self.__chained_sounds__ = [-1 if x == next_free_layer else x for x in self.__chained_sounds__]
            self.__chained_sounds__[index] = next_free_layer
            self.__song__.schedule_save()
            # self.chained_sounds_changed.emit()
            
            return True

    @Slot(int, result=str)
    def getLayerNameByMidiChannel(self, channel):
        if self.checkIfLayerExists(channel):
            try:
                layer = self.__song__.get_metronome_manager().zyngui.screens["fixed_layers"].list_data[channel]
                return layer[2]
            except:
                return ""
        else:
            return ""

    @Slot(int, result=str)
    def getEffectsNameByMidiChannel(self, channel):
        if self.checkIfLayerExists(channel):
            try:
                fx = self.__song__.get_metronome_manager().zyngui.screens["fixed_layers"].list_metadata[channel]
                return fx["effects_label"]
            except:
                return ""
        else:
            return ""

    @Slot(int, result=bool)
    def checkIfLayerExists(self, channel):
        return channel in self.__song__.get_metronome_manager().zyngui.screens["layer"].layer_midi_map.keys()

    @Slot(int, result='QVariantList')
    def chainForLayer(chan):
        chain = []
        for i in range (16):
            if zyngui.screens['layer'].is_midi_cloned(chan, i) or zyngui.screens['layer'].is_midi_cloned(i, chan):
                cain.append(i)
        return chain

    @Slot(int, result='QVariantList')
    def printableChainForLayer(chan):
        chain = ""
        for i in range (16):
            if zyngui.screens['layer'].is_midi_cloned(chan, i) or zyngui.screens['layer'].is_midi_cloned(i, chan):
                cain.append(" {}".format(i))
        return chain

    @Slot(int)
    def selectSound(self, index):
        zyngui = self.__song__.get_metronome_manager().zyngui

        if index in self.__chained_sounds__:
            zyngui.screens["fixed_layers"].activate_index(index)
        else:
            chained = [index]
            for i in range (16):
                if i != index and zyngui.screens['layer'].is_midi_cloned(index, i) or zyngui.screens['layer'].is_midi_cloned(i, index):
                    chained.append(i)
                    if len(chained) >= 5:
                        break
            while len(chained) < 5:
                chained.append(-1)
            self.set_chained_sounds(chained)
            logging.error(chained)

            #sounds_to_clone = []
            #for m_sound in self.__chained_sounds__:
                #if m_sound > -1:
                    #sounds_to_clone.append(m_sound)

            #for _index in range(0, len(sounds_to_clone) - 1):
                #logging.error(f"Removing cloned layers {sounds_to_clone[_index], sounds_to_clone[_index + 1]}")
                #zyngui.screens['layer'].remove_clone_midi(sounds_to_clone[_index], sounds_to_clone[_index + 1])
                #zyngui.screens['layer'].remove_clone_midi(sounds_to_clone[_index + 1], sounds_to_clone[_index])

            #self.set_chained_sounds([index, -1, -1, -1, -1])
            #zyngui.screens["fixed_layers"].activate_index(index)

        self.connected_sound_changed.emit()
        self.chained_sounds_changed.emit()

    @Slot(None)
    def clearChainedSoundsWithoutCloning(self):
        self.__chained_sounds__ = [-1, -1, -1, -1, -1]

        try: #can be called before creation
            zyngui = self.__song__.get_metronome_manager().zyngui
            zyngui.screens['fixed_layers'].fill_list() #This will update *also* layers for track
            # zyngui.screens['session_dashboard'].set_selected_track(zyngui.screens['session_dashboard'].selectedTrack, True)
            zyngui.screens['layers_for_track'].activate_index(0)
            zyngui.set_curlayer(None)
        except Exception as e:
            logging.error(f"Error filling list : {str(e)}")

        self.__song__.schedule_save()
        self.chained_sounds_changed.emit()
        self.connected_sound_changed.emit()

    ### Property connectedPattern
    def get_connected_pattern(self):
        return self.__connected_pattern__
    def set_connected_pattern(self, pattern):
        self.__connected_pattern__ = pattern
        self.__song__.schedule_save()
        self.connected_pattern_changed.emit()
        self.__song__.tracksModel.connected_patterns_count_changed.emit()
    connected_pattern_changed = Signal()
    connectedPattern = Property(int, get_connected_pattern, set_connected_pattern, notify=connected_pattern_changed)
    ### END Property connectedPattern

    ### Property connectedSound
    def get_connected_sound(self):
        # return self.__connected_sound__
        for sound in self.__chained_sounds__:
            if sound >= 0:
                return math.floor(sound)

        return -1
    # def set_connected_sound(self, sound):
    #     self.__connected_sound__ = sound
    #     self.__song__.schedule_save()
    #     self.connected_sound_changed.emit()
    #     self.__song__.tracksModel.connected_sounds_count_changed.emit()
    connected_sound_changed = Signal()
    connectedSound = Property(int, get_connected_sound, notify=connected_sound_changed)
    ### END Property connectedSound

    ### Property chainedSounds
    def get_chained_sounds(self):
        return self.__chained_sounds__

    @Slot(int)
    def remove_and_unchain_sound(self, chan):
        zyngui = self.__song__.get_metronome_manager().zyngui
        for i in range (16):
            for j in range(16):
                if i != j and i in self.__chained_sounds__ and j in self.__chained_sounds__ and self.checkIfLayerExists(i) and self.checkIfLayerExists(j):
                    zyngui.screens['layer'].remove_clone_midi(i, j)
                    zyngui.screens['layer'].remove_clone_midi(j, i)

        for i, sound in enumerate(self.__chained_sounds__):
            logging.error("AAAA {} {}".format(sound, chan))
            if sound == chan:
                self.__chained_sounds__[i] = -1
        zyngui.screens['layers_for_track'].fill_list()

        self.select_correct_layer()

        self.chained_sounds_changed.emit()
        self.connected_sound_changed.emit()

    def set_chained_sounds(self, sounds):
        class Worker:
            def run(self, parent, _zyngui, _sounds):
                # Update midi clone
                for i in range(16):
                    for j in range(16):
                        if i != j and i in _sounds and j in sounds and parent.checkIfLayerExists(
                                i) and parent.checkIfLayerExists(j):
                            _zyngui.screens['layer'].clone_midi(i, j)
                            _zyngui.screens['layer'].clone_midi(j, i)

        self.__chained_sounds__ = [-1, -1, -1, -1, -1]
        for i, sound in enumerate(sounds):
            if not sound in self.__chained_sounds__:
                self.__chained_sounds__[i] = sound

        self.__song__.schedule_save()
        zyngui = self.__song__.get_metronome_manager().zyngui

        worker = Worker()
        worker_thread = threading.Thread(target=worker.run, args=(self, zyngui, sounds))
        worker_thread.start()

        try: #can be called before creation
            self.zyngui.screens['layers_for_track'].fill_list()
            if self.connectedSound >= 0:
                #self.zyngui.screens['fixed_layers'].activate_index(self.connectedSound)
                self.zyngui.screens['layers_for_track'].layer_selection_consistency_check()
            else:
                self.zyngui.screens['layers_for_track'].select_action(
                    self.zyngui.screens['layers_for_track'].current_index)
        except:
            pass
        self.chained_sounds_changed.emit()
        self.connected_sound_changed.emit()

    chained_sounds_changed = Signal()
    chainedSounds = Property('QVariantList', get_chained_sounds, set_chained_sounds, notify=chained_sounds_changed)
    ### END Property chainedSounds

    ### Property muted
    def get_muted(self):
        return self.__muted__
    def set_muted(self, muted):
        self.__muted__ = muted
        for clip_index in range(0, self.__clips_model__.count):
            clip = self.__clips_model__.getClip(clip_index)
            if clip is not None:
                if muted:
                    clip.setVolume(-40)
                else:
                    clip.setVolume(self.volume)
        self.isMutedChanged.emit()
    isMutedChanged = Signal()
    muted = Property(bool, get_muted, set_muted, notify=isMutedChanged)
    ### End Property muted