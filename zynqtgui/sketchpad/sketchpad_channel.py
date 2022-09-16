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
from pathlib import Path
from subprocess import Popen

import jack
import numpy as np
from PySide2.QtCore import Property, QGenericArgument, QMetaObject, QObject, QThread, QTimer, Qt, Signal, Slot

from zynqtgui.sketchpad.libzl import libzl
from .sketchpad_clips_model import sketchpad_clips_model
from .sketchpad_clip import sketchpad_clip
from zynqtgui import zynthian_gui_config

class sketchpad_channel(QObject):
    # Possible Values : "audio", "video"
    __type__ = "audio"

    def __init__(self, id: int, song: QObject, parent: QObject = None):
        super(sketchpad_channel, self).__init__(parent)
        self.zyngui = zynthian_gui_config.zyngui
        self.__id__ = id
        self.__name__ = None
        self.__song__ = song
        self.__initial_volume__ = 0
        self.__volume__ = self.__initial_volume__
        self.__initial_pan__ = 0
        self.__pan__ = self.__initial_pan__
        self.__audio_level__ = -200
        self.__clips_model__ = [sketchpad_clips_model(song, self, 0), sketchpad_clips_model(song, self, 1), sketchpad_clips_model(song, self, 2), sketchpad_clips_model(song, self, 3), sketchpad_clips_model(song, self, 4)]
        self.__layers_snapshot = []
        self.master_volume = libzl.dbFromVolume(self.__song__.get_metronome_manager().get_master_volume()/100)
        self.__song__.get_metronome_manager().master_volume_changed.connect(lambda: self.master_volume_changed())
        self.__connected_pattern__ = -1
        # self.__connected_sound__ = -1
        self.__chained_sounds__ = [-1, -1, -1, -1, -1]
        self.zyngui.screens["layer"].layer_deleted.connect(self.layer_deleted)
        self.__muted__ = False
        self.__samples__ = []
        self.__keyzone_mode__ = "all-full"
        self.__base_samples_dir__ = Path(self.__song__.sketchpad_folder) / 'wav' / 'sampleset'
        self.__color__ = "#000000"
        self.__selected_slot_row__ = 0
        self.__selected_part__ = 0
        self.__externalMidiChannel__ = -1
        self.__sound_json_snapshot__ = ""
        self.route_through_global_fx = True
        self.__channel_synth_ports = []

        self.update_jack_port_timer = QTimer()
        self.update_jack_port_timer.setInterval(100)
        self.update_jack_port_timer.setSingleShot(True)
        self.update_jack_port_timer.timeout.connect(self.do_update_jack_port)

        self.fixed_layers_list_updated_handler_throttle = QTimer()
        self.fixed_layers_list_updated_handler_throttle.setInterval(100)
        self.fixed_layers_list_updated_handler_throttle.setSingleShot(True)
        self.fixed_layers_list_updated_handler_throttle.timeout.connect(self.fixed_layers_list_updated_handler)

        # Create 5 clip objects for 5 samples per channel
        for i in range(0, 5):
            self.__samples__.append(sketchpad_clip(self.id, -1, -1, self.__song__, self, True))

        self.__channel_audio_type__ = "synth"

        # self.chained_sounds_changed.connect(self.select_correct_layer)

        if self.__id__ < 5:
            # self.__connected_sound__ = self.__id__
            self.__chained_sounds__[0] = self.__id__

        # Connect to default patterns on init
        # This will be overwritten by deserialize if user changed the value, so it is safe to always set the value
        if 0 <= self.__id__ <= 9:
            self.__connected_pattern__ = self.__id__

        self.__song__.scenesModel.selected_track_index_changed.connect(self.track_index_changed_handler)
        self.__song__.scenesModel.selected_scene_index_changed.connect(lambda: self.selectedPartNamesChanged.emit())

        # Emit occupiedSlotsChanged on dependant property changes
        self.chained_sounds_changed.connect(self.chained_sounds_changed_handler)
        try:
            self.zyngui.sketchpad.song.scenesModel.selectedTrackIndexChanged.connect(lambda: self.occupiedSlotsChanged.emit())
        except:
            pass
        self.channel_audio_type_changed.connect(lambda: self.occupiedSlotsChanged.emit())
        self.samples_changed.connect(lambda: self.occupiedSlotsChanged.emit())

        self.selectedPartChanged.connect(lambda: self.clipsModelChanged.emit())
        self.selectedPartChanged.connect(lambda: self.scene_clip_changed.emit())
        self.zyngui.fixed_layers.list_updated.connect(self.fixed_layers_list_updated_handler_throttle.start)

        ### Proxy recordingPopupActive from zynthian_qt_gui
        self.zyngui.recordingPopupActiveChanged.connect(self.recordingPopupActiveChanged.emit)

        # Re-read sound snapshot json when a new snapshot is loaded
        self.zyngui.layer.snapshotLoaded.connect(self.update_sound_snapshot_json)

    # Since signals can't carry parameters when defined in python (yay), we're calling this directly from clips_model
    def onClipEnabledChanged(self, trackIndex, partNum):
        clip = self.getClipsModelByPart(partNum).getClip(trackIndex)

        # if clip is not None and clip.enabled is not None:
            # logging.error(f"{clip} is enabled? {clip.enabled} for trackIndex {trackIndex} and part {partNum} for channel {self.id}")

        if clip is not None and clip.enabled is True:
            self.set_selected_part(partNum)
            # We will now allow playing multiple parts of a sample-loop channel
            allowMultipart = (self.channelAudioType == "sample-loop" or self.channelAudioType == "sample-trig") and self.keyZoneMode == "all-full"
            # logging.error(f"Allowing multipart playback: {allowMultipart}")
            if not allowMultipart:
                for part in range(0, 5):
                    if part != self.__selected_part__:
                        clipForDisabling = self.getClipsModelByPart(part).getClip(trackIndex)
                        # NOTE This will cause an infinite loop if we assign True here (see: the rest of this function)
                        if clipForDisabling is not None:
                            clipForDisabling.enabled = False

        self.selectedPartNamesChanged.emit()

    def track_index_changed_handler(self):
        self.scene_clip_changed.emit()
        self.selectedPartNamesChanged.emit()

    def chained_sounds_changed_handler(self):
        self.__song__.updateAutoconnectedSounds()
        self.occupiedSlotsChanged.emit()
        self.connectedSoundChanged.emit()
        self.connectedSoundNameChanged.emit()
        self.chainedSoundsInfoChanged.emit()
        self.chainedSoundsNamesChanged.emit()

    def fixed_layers_list_updated_handler(self):
        self.connectedSoundChanged.emit()
        self.connectedSoundNameChanged.emit()
        self.chainedSoundsInfoChanged.emit()
        self.chainedSoundsNamesChanged.emit()

    @Property(str, constant=True)
    def className(self):
        return "sketchpad_channel"

    def layer_deleted(self, chan : int):
        self.set_chained_sounds([-1 if x==chan else x for x in self.__chained_sounds__])

    def select_correct_layer(self):
        zyngui = self.__song__.get_metronome_manager().zyngui
        if self.checkIfLayerExists(zyngui.active_midi_channel):
            logging.info("### select_correct_layer : Reselect any available sound since it is removing current selected channel")
            # zyngui.screens['session_dashboard'].set_selected_channel(zyngui.screens['session_dashboard'].selectedChannel, True)
            try:
                zyngui.screens["layers_for_channel"].update_channel_sounds()
            except:
                pass
        else:
            logging.info("### select_correct_layer : Do not Reselect channel sound since it is not removing current selected channel")

    def master_volume_changed(self):
        self.master_volume = libzl.dbFromVolume(self.__song__.get_metronome_manager().get_master_volume()/100)
        logging.debug(f"Master Volume : {self.master_volume} dB")

    def stopAllClips(self):
        for part_index in range(0, 5):
            for clip_index in range(0, self.getClipsModelByPart(part_index).count):
                self.__song__.getClipByPart(self.__id__, clip_index, part_index).stop()

    def save_bank(self):
        bank_dir = Path(self.bankDir)

        obj = []
        for sample in self.__samples__:
            if sample.path is not None and len(sample.path) > 0:
                sample.saveMetadata()
                if sample.audioSource:
                    obj.append({"path": Path(sample.path).name,
                                "keyZoneStart": sample.audioSource.keyZoneStart(),
                                "keyZoneEnd": sample.audioSource.keyZoneEnd(),
                                "rootNote": sample.audioSource.rootNote()})
                else:
                    obj.append({"path": Path(sample.path).name})
            else:
                obj.append(None)

        # Create bank dir and write bank json only if channel has some samples loaded
        for c in obj:
            if c is not None:
                bank_dir.mkdir(parents=True, exist_ok=True)
                try:
                    logging.info(f"Writing to sample-bank.json {bank_dir}/sample-bank.json")
                    with open(bank_dir / 'sample-bank.json', "w") as f:
                        json.dump(obj, f)
                        f.truncate()
                        f.flush()
                        os.fsync(f.fileno())
                except Exception as e:
                    logging.error(f"Error writing sample-bank.json to {bank_dir} : {str(e)}")

                break

    def restore_bank(self):
        bank_dir = Path(self.bankDir)

        if not (bank_dir / 'sample-bank.json').exists():
            logging.info(f"sample-bank.json does not exist for channel {self.id + 1}. Skipping restoration")
        else:
            logging.info(f"Restoring sample-bank.json for channel {self.id + 1}")

            try:
                with open(bank_dir / 'sample-bank.json', "r") as f:
                    obj = json.loads(f.read())

                    for i, clip in enumerate(obj):
                        if clip is not None:
                            if (bank_dir / clip["path"]).exists():
                                self.__samples__[i].set_path(str(bank_dir / clip["path"]), False) # Do not copy file when restoring
                            if self.__samples__[i].audioSource:
                                if "keyZoneStart" in clip:
                                    self.__samples__[i].audioSource.setKeyZoneStart(clip["keyZoneStart"])
                                else:
                                    self.__samples__[i].audioSource.setKeyZoneStart(0)
                                if "keyZoneEnd" in clip:
                                    self.__samples__[i].audioSource.setKeyZoneEnd(clip["keyZoneEnd"])
                                else:
                                    self.__samples__[i].audioSource.setKeyZoneEnd(127)
                                if "rootNote" in clip:
                                    self.__samples__[i].audioSource.setRootNote(clip["rootNote"])
                                else:
                                    self.__samples__[i].audioSource.setRootNote(60)

                    self.samples_changed.emit()
            except Exception as e:
                logging.error(f"Error reading sample-bank.json from {bank_dir} : {str(e)}")

    def serialize(self):
        # Save bank when serializing so that bank is saved everytime song is saved
        self.save_bank()

        return {"name": self.__name__,
                "color": self.__color__,
                "volume": self.__volume__,
                "pan": self.__pan__,
                "connectedPattern": self.__connected_pattern__,
                # "connectedSound": self.__connected_sound__,
                "chainedSounds": self.__chained_sounds__,
                "channelAudioType": self.__channel_audio_type__,
                "selectedPart": self.__selected_part__,
                "externalMidiChannel" : self.__externalMidiChannel__,
                "clips": [self.__clips_model__[part].serialize() for part in range(0, 5)],
                "layers_snapshot": self.__layers_snapshot,
                "keyzone_mode": self.__keyzone_mode__,
                "routeThroughGlobalFX": self.route_through_global_fx}

    def deserialize(self, obj):
        try:
            if "name" in obj:
                self.__name__ = obj["name"]
            if "color" in obj:
                self.__color__ = obj["color"]
            if "volume" in obj:
                self.__volume__ = obj["volume"]
                self.set_volume(self.__volume__, True)
            if "pan" in obj:
                self.__pan__ = obj["pan"]
                self.set_pan(self.__pan__, True)
            if "connectedPattern" in obj:
                self.__connected_pattern__ = obj["connectedPattern"]
                self.set_connected_pattern(self.__connected_pattern__)
            # if "connectedSound" in obj:
            #     self.__connected_sound__ = obj["connectedSound"]
            #     self.set_connected_sound(self.__connected_sound__)
            if "chainedSounds" in obj:
                self.__chained_sounds__ = obj["chainedSounds"]
                self.set_chained_sounds(self.__chained_sounds__)
            if "channelAudioType" in obj:
                self.__channel_audio_type__ = obj["channelAudioType"]
                self.set_channel_audio_type(self.__channel_audio_type__, True)
            if "externalMidiChannel" in obj:
                self.set_externalMidiChannel(obj["externalMidiChannel"])
            if "clips" in obj:
                for x in range(0, 5):
                    self.__clips_model__[x].deserialize(obj["clips"][x], x)
            if "layers_snapshot" in obj:
                self.__layers_snapshot = obj["layers_snapshot"]
                self.sound_data_changed.emit()
            if "keyzone_mode" in obj:
                self.__keyzone_mode__ = obj["keyzone_mode"]
                self.keyZoneModeChanged.emit();
            if "selectedPart" in obj:
                self.set_selected_part(obj["selectedPart"])
            if "routeThroughGlobalFX" in obj:
                self.set_routeThroughGlobalFX(obj["routeThroughGlobalFX"], True)
                # Run autoconnect to update jack connections when routeThrouGlobalFX is set
                self.zyngui.zynautoconnect()
        except Exception as e:
            logging.error(f"Error during channel deserialization: {e}")
            traceback.print_exception(None, e, e.__traceback__)

        # Restore bank after restoring channel
        self.restore_bank()

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

    def update_jack_port(self):
        self.zyngui.currentTaskMessage = f"Updating jack ports for channel `{self.name}`"
        self.update_jack_port_timer.start()

    def do_update_jack_port(self):
        def task(zyngui, channel):
            jack_basenames = []

            channelHasEffects = False
            for ch in channel.chainedSounds:
                if ch >= 0 and channel.checkIfLayerExists(ch):
                    layer = zyngui.screens['layer'].layer_midi_map[ch]

                    # Iterate over all connected layers (including fx layer) on midi channel `channel`
                    for fxlayer in zyngui.screens['layer'].get_fxchain_layers(layer):
                        try:
                            jack_basenames.append(fxlayer.jackname.split(":")[0])

                            # fxlayer can be a Midi synth, or an effect. Check if it is an effect
                            if fxlayer.engine.type == "Audio Effect":
                                channelHasEffects = True
                        except Exception as e:
                            logging.error(f"### update_jack_port Error : {str(e)}")

            try:
                for port in zip([f"SamplerSynth-channel_{self.id + 1}:left_out", f"SamplerSynth-channel_{self.id + 1}:right_out"], [f"AudioLevels-Channel{self.id + 1}:left_in", f"AudioLevels-Channel{self.id + 1}:right_in"]):
                    try:
                        if channelHasEffects or self.get_channel_audio_type().startswith("sample-") is False:
                            p = Popen(("jack_disconnect", port[1], port[0]))
                            p.wait()
                        else:
                            p = Popen(("jack_connect", port[1], port[0]))
                            p.wait()
                    except Exception as e:
                        logging.error(f"Error processing SamplerSynth jack port for Ch{self.id + 1} : {port}({str(e)})")
            except Exception as e:
                logging.error(f"Error processing SamplerSynth jack ports for Ch{self.id + 1}: {str(e)}")

            synth_ports = []

            for port_name in jack_basenames:
                port_names = []
                try:
                    ports = [x.name for x in jack.Client("").get_ports(name_pattern=port_name, is_output=True, is_audio=True, is_physical=False)]

                    # Map first port from jack.Client.get_ports to channel A and second port to channel B
                    for port in zip(ports, [f"AudioLevels-Channel{self.id + 1}:left_in", f"AudioLevels-Channel{self.id + 1}:right_in"]):
                        logging.error(f"Connecting port {port[0]} -> {port[1]}")
                        port_names.append(port[0])
                        p = Popen(("jack_connect", port[0], port[1]))
                        p.wait()
                except Exception as e:
                    logging.error(f"Error processing jack port for Ch{self.id + 1} : {port}({str(e)})")

                synth_ports.append(port_names)

            self.set_channelSynthPorts(synth_ports)
            self.zyngui.zynautoconnect(True)

        worker_thread = threading.Thread(target=task, args=(self.zyngui, self))
        worker_thread.start()

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

    @Signal
    def __name_changed__(self):
        pass

    def name(self):
        if self.__name__ is None:
            return f"Ch{self.__id__ + 1}"
        else:
            return self.__name__

    def set_name(self, name):
        if name != f"Ch{self.__id__ + 1}":
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
            logging.debug(f"Channel : Setting volume {self.__volume__}")

            # Update synth volume when channel volume changes
            for sound in self.chainedSounds:
                if sound >= 0 and self.checkIfLayerExists(sound):
                    volume_control_obj = self.zyngui.fixed_layers.volume_controls[sound]

                    # Interpolate channel volume (-40 -> 20) to volume control object's range
                    if volume_control_obj is not None and \
                            volume_control_obj.value != np.interp(self.__volume__, [-40, 20], [volume_control_obj.value_min, volume_control_obj.value_max]):
                        volume_control_obj.value = np.interp(self.__volume__, [-40, 20], [volume_control_obj.value_min, volume_control_obj.value_max])

            self.volume_changed.emit()
            self.__song__.schedule_save()
            self.zyngui.sketchpad.set_selector()

    volume = Property(int, get_volume, set_volume, notify=volume_changed)

    ### Property initialPan
    def get_initial_pan(self):
        return self.__initial_pan__
    initialPan = Property(float, get_initial_pan, constant=True)
    ### END Property initialPan

    ### Property pan
    def get_pan(self):
        return self.__pan__

    def set_pan(self, pan: float, force_set=False):
        if self.__pan__ != pan or force_set is True:
            self.__pan__ = pan

            self.panChanged.emit()
            self.zyngui.sketchpad.set_selector()
            if force_set is False:
                self.__song__.schedule_save()

    panChanged = Signal()

    pan = Property(float, get_pan, set_pan, notify=panChanged)
    ### END Property pan

    ### Property initialVolume
    def get_initial_volume(self):
        return self.__initial_volume__
    initialVolume = Property(int, get_initial_volume, constant=True)
    ### END Property initialVolume

    def type(self):
        return self.__type__
    type = Property(str, type, constant=True)

    @Slot(int, result=QObject)
    def getClipsModelByPart(self, part):
        return self.__clips_model__[part]
    def clipsModel(self):
        return self.__clips_model__[self.__selected_part__]
    clipsModelChanged = Signal()
    clipsModel = Property(QObject, clipsModel, notify=clipsModelChanged)

    @Slot(result='QVariantList')
    def getAllPartClips(self):
        clips = []

        for index in range(5):
            clips_model = self.getClipsModelByPart(index)
            clips.append(clips_model.getClip(self.__song__.scenesModel.selectedTrackIndex))

        return clips

    ### BEGIN Property parts
    def getParts(self):
        return self.__clips_model__
    partsChanged = Signal()
    parts = Property('QVariantList', getParts, notify=partsChanged)
    ### END Property parts

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
        self.__audio_level__ = leveldB + self.__volume__ + self.master_volume
        self.audioLevelChanged.emit()

    audioLevel = Property(float, get_audioLevel, set_audioLevel, notify=audioLevelChanged)

    @Slot(None, result=bool)
    def isEmpty(self):
        is_empty = True

        for clip_index in range(0, self.clipsModel.count):
            clip: sketchpad_clip = self.clipsModel.getClip(clip_index)
            if clip.path is not None and len(clip.path) > 0:
                is_empty = False
                break

        return is_empty

    # source : Source sketchpad_channel object
    @Slot(QObject)
    def copyFrom(self, source):
        for part in range(5):
            # Copy all clips from source channel to self
            for clip_index in range(0, self.parts[part].count):
                self.parts[part].getClip(clip_index).copyFrom(source.parts[part].getClip(clip_index))

        source_bank_dir = Path(source.bankDir)
        dest_bank_dir = Path(self.bankDir)

        dest_bank_dir.mkdir(parents=True, exist_ok=True)

        # Copy all samples from source channel
        for file in source_bank_dir.glob("*"):
            shutil.copy2(file, dest_bank_dir / file.name)

        # Restore bank after copying
        self.restore_bank()

    @Slot(int, result=bool)
    def createChainedSoundInNextFreeLayer(self, index):
        zyngui = self.__song__.get_metronome_manager().zyngui
        assigned_layers = [x for x in zyngui.screens["layer"].layer_midi_map.keys()]
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
            zyngui.screens["fixed_layers"].activate_index(next_free_layer)

            for channel_id in range(self.__song__.channelsModel.count):
                channel = self.__song__.channelsModel.getChannel(channel_id)
                channel.__chained_sounds__ = [-1 if x == next_free_layer else x for x in channel.__chained_sounds__]

            self.__chained_sounds__[index] = next_free_layer
            self.__song__.schedule_save()

            return True

    def getFreeLayers(self):
        zyngui = self.__song__.get_metronome_manager().zyngui
        assigned_layers = [x for x in zyngui.screens["layer"].layer_midi_map.keys()]
        free_layers = []

        for x in range(0, 16):
            if x not in assigned_layers:
                free_layers.append(x)

        return free_layers

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
            logging.debug(chained)

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

        self.chained_sounds_changed.emit()

    @Slot(None)
    def clearChainedSoundsWithoutCloning(self):
        self.__chained_sounds__ = [-1, -1, -1, -1, -1]

        try: #can be called before creation
            zyngui = self.__song__.get_metronome_manager().zyngui
            zyngui.screens['fixed_layers'].fill_list() #This will update *also* layers for channel
            # zyngui.screens['session_dashboard'].set_selected_channel(zyngui.screens['session_dashboard'].selectedChannel, True)
            zyngui.screens['layers_for_channel'].activate_index(0)
            zyngui.set_curlayer(None)
        except Exception as e:
            logging.error(f"Error filling list : {str(e)}")

        self.__song__.schedule_save()
        self.chained_sounds_changed.emit()

    @Slot(str)
    def setBank(self, path):
        bank_path = Path(path)
        self_bank_path = Path(self.bankDir)

        self_bank_path.mkdir(parents=True, exist_ok=True)

        # Delete existing sample-bank.json if it exists
        try:
            (self_bank_path / "sample-bank.json").unlink()
        except:
            pass

        # Copy bank json from selected bank
        shutil.copy2(bank_path, self_bank_path / "sample-bank.json")

        # Copy all wavs from selected bank
        for wav in bank_path.parent.glob("*.wav"):
            shutil.copy2(wav, self_bank_path / wav.name)

        # Populate samples
        self.restore_bank()

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
        zyngui = self.__song__.get_metronome_manager().zyngui

        def task():
            zyngui.screens['layers_for_channel'].fill_list()

            zyngui.layer.remove_root_layer(chan)
            self.select_correct_layer()
            self.__song__.schedule_save()
            self.chained_sounds_changed.emit()

            if cb is not None:
                cb()

            zyngui.end_long_task()

        self.zyngui.currentTaskMessage = f"Removing chained sound at slot `{self.selectedSlotRow + 1}` from channel `{self.name}`"
        zyngui.do_long_task(task)

    def set_chained_sounds(self, sounds):
        update_jack_ports = True

        # Stop all playing notes
        for old_chan in self.__chained_sounds__:
            if old_chan > -1:
                self.zyngui.raw_all_notes_off_chan(old_chan)

        chained_sounds = [-1, -1, -1, -1, -1]
        for i, sound in enumerate(sounds):
            if sound not in chained_sounds:
                chained_sounds[i] = sound

        if chained_sounds == self.__chained_sounds__:
            update_jack_ports = False

        self.__chained_sounds__ = chained_sounds

        try: #can be called before creation
            self.zyngui.screens['layers_for_channel'].fill_list()
            if self.connectedSound >= 0:
                self.zyngui.screens['layers_for_channel'].layer_selection_consistency_check()
            else:
                self.zyngui.screens['layers_for_channel'].select_action(
                    self.zyngui.screens['layers_for_channel'].current_index)
        except:
            pass

        if update_jack_ports:
            self.update_jack_port()

        self.update_sound_snapshot_json()
        self.__song__.schedule_save()
        self.chained_sounds_changed.emit()

    chained_sounds_changed = Signal()
    chainedSounds = Property('QVariantList', get_chained_sounds, set_chained_sounds, notify=chained_sounds_changed)
    ### END Property chainedSounds

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

    ### Property muted
    def get_muted(self):
        return self.__muted__
    def set_muted(self, muted):
        self.__muted__ = muted
        if muted:
            self.mute_all_clips_in_channel()
        elif self.__song__.playChannelSolo == -1 or (self.__song__.playChannelSolo == self.id):
            self.unmute_all_clips_in_channel()
        self.isMutedChanged.emit()
    isMutedChanged = Signal()
    muted = Property(bool, get_muted, set_muted, notify=isMutedChanged)
    ### End Property muted

    ### Property channelAudioType
    # Possible values : "synth", "sample-loop", "sample-trig", "sample-slice", "external"
    # For simplicity, channelAudioType is string in the format "sample-xxxx" or "synth" or "external"
    # TODO : Later implement it properly with model and enums
    def get_channel_audio_type(self):
        return self.__channel_audio_type__

    def set_channel_audio_type(self, type:str, force_set=False):
        logging.debug(f"Setting Audio Type : {type}, {self.__channel_audio_type__}")

        if force_set or type != self.__channel_audio_type__:
            self.__channel_audio_type__ = type
            self.zyngui.sketchpad.set_selector()
            self.channel_audio_type_changed.emit()
            for track in range(0, 10):
                for part in range(0, 5):
                    self.onClipEnabledChanged(track, part)
            if not force_set:
                self.__song__.schedule_save()
            self.update_jack_port()

    channel_audio_type_changed = Signal()

    channelAudioType = Property(str, get_channel_audio_type, set_channel_audio_type, notify=channel_audio_type_changed)
    ### END Property channelAudioType

    ### Property samples
    def get_samples(self):
        return self.__samples__

    @Slot(str, int, result=None)
    def set_sample(self, path, index):
        self.__samples__[index].set_path(path)
        self.samples_changed.emit()
        self.__song__.schedule_save()

    samples_changed = Signal()

    samples = Property('QVariantList', get_samples, notify=samples_changed)
    ### END Property samples

    ### Property keyzoneMode
    # Possible values : "manual", "all-full", "split-full", "split-narrow"
    # manual will not apply any automatic stuff
    # all-full will set all samples to full width, c4 at 60
    # split-full will spread samples across the note range, in the order 4, 2, 1, 3, 5, starting at note 0, 24 for each, with c4 on the 12th note inside the sample's range
    # split-narrow will set the samples to play only on the white keys from note 60 and up, with that note as root
    def get_keyZoneMode(self):
        return self.__keyzone_mode__

    @Slot(str)
    def set_keyZoneMode(self, keyZoneMode):
        if self.__keyzone_mode__ != keyZoneMode:
            self.__keyzone_mode__ = keyZoneMode
            self.keyZoneModeChanged.emit()
            for track in range(0, 10):
                for part in range(0, 5):
                    self.onClipEnabledChanged(track, part)
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
    def get_bank_dir(self):
        try:
            # Check if a dir named <somerandomname>.<channel_id> exists.
            # If exists, use that name as the bank dir name otherwise use default name `sample-bank`
            bank_name = [x.name for x in self.__base_samples_dir__.glob(f"*.{self.id + 1}")][0].split(".")[0]
        except:
            bank_name = "sample-bank"
        path = self.__base_samples_dir__ / f"{bank_name}.{self.id + 1}"

        logging.debug(f"get_bank_dir channel{self.id + 1} : bankDir({path})")

        return str(path)

    bankDir = Property(str, get_bank_dir, constant=True)
    ### END Property bankDir

    ### Property sceneClip
    def get_scene_clip(self):
        return self.__song__.getClip(self.id, self.__song__.scenesModel.selectedTrackIndex)

    scene_clip_changed = Signal()

    sceneClip = Property(QObject, get_scene_clip, notify=scene_clip_changed)
    ### END Property sceneClip

    ### Property chainedSoundsInfo
    def get_chainedSoundsInfo(self):
        info = []

        try:
            for sound in self.chainedSounds:
                if sound >= 0 and self.checkIfLayerExists(sound):
                    layer = self.zyngui.layer.layer_midi_map[sound]
                    info.append({
                        'presetIndex': layer.preset_index,
                        'presetLength': len(layer.preset_list),
                        'bankName': layer.bank_name,
                        'synthName': layer.engine.name,
                        'presetName': layer.preset_name
                    })
                else:
                    info.append({
                        'presetIndex': 0,
                        'presetLength': 0,
                        'bankName': '',
                        'synthName': '',
                        'presetName': ''
                    })
        except Exception as e:
            logging.error(f"Error getting sound info : {str(e)}")
            traceback.print_exception()

            info.append({
                'presetIndex': 0,
                'presetLength': 0,
                'bankName': '',
                'synthName': '',
                'presetName': ''
            })

        return info

    @Slot(None)
    def updateChainedSoundsInfo(self):
        self.chainedSoundsInfoChanged.emit()

    chainedSoundsInfoChanged = Signal()

    chainedSoundsInfo = Property('QVariantList', get_chainedSoundsInfo, notify=chainedSoundsInfoChanged)

    ### END Property chained_sounds_presets

    ### Property selectedSlotRow
    def get_selectedSlotRow(self):
        return self.__selected_slot_row__

    def set_selectedSlotRow(self, row):
        if self.__selected_slot_row__ != row:
            self.__selected_slot_row__ = row
            self.zyngui.sketchpad.set_selector()
            self.selectedSlotRowChanged.emit()

    selectedSlotRowChanged = Signal()

    selectedSlotRow = Property(int, get_selectedSlotRow, set_selectedSlotRow, notify=selectedSlotRowChanged)
    ### END Property selectedSlotRow

    ### Property occupiedSlots
    @Slot(None, result='QVariantList')
    def get_occupiedSlots(self):
        occupied_slots = []

        if self.__channel_audio_type__ == "sample-trig":
            # logging.debug(f"### get_occupiedSlots : Sample trig")
            # If type is sample-trig check how many samples has wavs selected
            for sample in self.__samples__:
                if sample is not None and \
                        sample.path is not None and \
                        len(sample.path) > 0:
                    occupied_slots.append(True)
                else:
                    occupied_slots.append(False)
        elif self.__channel_audio_type__ == "synth":
            # logging.debug(f"### get_occupiedSlots : synth")
            # If type is synth check how many synth engines are selected and chained
            for sound in self.__chained_sounds__:
                if sound >= 0 and self.checkIfLayerExists(sound):
                    occupied_slots.append(True)
                else:
                    occupied_slots.append(False)
        elif self.__channel_audio_type__ == "sample-slice":
            # logging.debug(f"### get_occupiedSlots : Sample slice")

            # If type is sample-slice check if samples[0] has wav selected
            if self.__samples__[0] is not None and \
                    self.__samples__[0].path is not None and \
                    len(self.__samples__[0].path) > 0:
                occupied_slots = [True, None, None, None, None]
            else:
                occupied_slots = [False, None, None, None, None]
        else:
            # logging.debug(f"### get_occupiedSlots : Slots not in use")
            # For any other modes, sample slots are not in use. Hence do not increment occupied_slots
            pass

        # logging.debug(f"### get_occupiedSlots : occupied_slots({occupied_slots})")

        return occupied_slots

    occupiedSlotsChanged = Signal()

    occupiedSlots = Property('QVariantList', get_occupiedSlots, notify=occupiedSlotsChanged)
    ### END Property occupiedSlots

    ### Property occupiedSlots
    @Slot(None, result='QVariantList')
    def get_occupiedSlotsCount(self):
        count = 0

        for slot in self.occupiedSlots:
            if slot:
                count += 1

        return count

    occupiedSlotsCount = Property(int, get_occupiedSlotsCount, notify=occupiedSlotsChanged)
    ### END Property occupiedSlots

    ### Property selectedPart
    def get_selected_part(self):
        return self.__selected_part__

    def set_selected_part(self, selected_part):
        if selected_part != self.__selected_part__:
            old_selected_part = self.__selected_part__
            self.__selected_part__ = selected_part

            # old_clip = self.__song__.getClipByPart(self.__id__, self.__song__.scenesModel.selectedTrackIndex, old_selected_part)
            # if old_clip is not None:
            #     old_clip.stop()
            #
            # clip = self.__song__.getClipByPart(self.__id__, self.__song__.scenesModel.selectedTrackIndex, selected_part)
            # if clip is not None and clip.inCurrentScene:
            #     clip.play()

            self.selectedPartChanged.emit()
            self.__song__.schedule_save()

    selectedPartChanged = Signal()

    selectedPart = Property(int, get_selected_part, set_selected_part, notify=selectedPartChanged)
    ### END Property selectedPart

    ### Property externalMidiChannel
    # Logic for this is, -1 is "just use the normal one", anything else is a specific channel
    def get_externalMidiChannel(self):
        return self.__externalMidiChannel__

    def set_externalMidiChannel(self, externalMidiChannel):
        if externalMidiChannel != self.__externalMidiChannel__:
            self.__externalMidiChannel__ = externalMidiChannel
            self.externalMidiChannelChanged.emit()

    externalMidiChannelChanged = Signal()

    externalMidiChannel = Property(int, get_externalMidiChannel, set_externalMidiChannel, notify=externalMidiChannelChanged)
    ### END Property selectedPart

    ### Property selectedPartNames
    def get_selectedPartNames(self):
        partNames = []
        for i in range(5):
            clip = self.getClipsModelByPart(i).getClip(self.zyngui.sketchpad.song.scenesModel.selectedTrackIndex)

            if clip.enabled:
                partNames.append(chr(i+65).lower())
            else:
                partNames.append("")

        return partNames

    selectedPartNamesChanged = Signal()

    selectedPartNames = Property('QVariantList', get_selectedPartNames, notify=selectedPartNamesChanged)
    ### Property selectedPartNames

    ### Property recordingPopupActive
    ### Proxy recordingPopupActive from zynthian_qt_gui

    def get_recordingPopupActive(self):
        return self.zyngui.recordingPopupActive

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
            self.zyngui.zynautoconnect()

    routeThroughGlobalFXChanged = Signal()

    routeThroughGlobalFX = Property(bool, get_routeThroughGlobalFX, set_routeThroughGlobalFX, notify=routeThroughGlobalFXChanged)
    ### END Property routeThroughGlobalFX

    ### Property channelSynthPorts
    def get_channelSynthPorts(self):
        return self.__channel_synth_ports

    def set_channelSynthPorts(self, ports):
        if self.__channel_synth_ports != ports:
            self.__channel_synth_ports = ports
            self.channelSynthPortsChanged.emit()

    channelSynthPortsChanged = Signal()

    channelSynthPorts = Property('QVariantList', get_channelSynthPorts, notify=channelSynthPortsChanged)
    ### END Property channelSynthPorts

    @Slot(None, result=QObject)
    def getClipToRecord(self):
        if self.channelAudioType in ["sample-trig", "sample-slice"]:
            return self.samples[self.selectedSlotRow]
        else:
            return self.getClipsModelByPart(self.selectedSlotRow).getClip(self.__song__.scenesModel.selectedTrackIndex)

    @Slot(None, result=str)
    def getChannelSoundSnapshotJson(self):
        #logging.error(f"getChannelSoundSnapshotJson : T({self.__id__ + 1})")
        return self.__sound_json_snapshot__

    @Slot(str, result=None)
    def setChannelSoundFromSnapshotJson(self, snapshot):
        self.zyngui.sound_categories.loadChannelSoundFromJson(self.id, snapshot)

    def mute_all_clips_in_channel(self):
        for clip_model_index in range(5):
            clips_model = self.__clips_model__[clip_model_index]
            for clip_index in range(0, clips_model.count):
                clip = clips_model.getClip(clip_index)
                if clip is not None:
                    clip.setVolume(-40)

    def unmute_all_clips_in_channel(self):
        for clip_model_index in range(5):
            clips_model = self.__clips_model__[clip_model_index]
            for clip_index in range(0, clips_model.count):
                clip = clips_model.getClip(clip_index)
                if clip is not None:
                    clip.setVolume(self.volume)

    def update_sound_snapshot_json(self):
        if self.connectedSound == -1:
            self.__sound_json_snapshot__ = ""
        else:
            self.__sound_json_snapshot__ = json.dumps(self.zyngui.layer.export_multichannel_snapshot(self.connectedSound))

        logging.debug(f"### sound snapshot json for channel {self.name} connectedSound {self.connectedSound} : {self.__sound_json_snapshot__}")
