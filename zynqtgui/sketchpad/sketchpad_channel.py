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

from pathlib import Path
from PySide2.QtCore import Property, QGenericArgument, QMetaObject, QObject, QThread, QTimer, Qt, Signal, Slot
from .sketchpad_clips_model import sketchpad_clips_model
from .sketchpad_clip import sketchpad_clip
from zynqtgui import zynthian_gui_config
from ..zynthian_gui_multi_controller import MultiController


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
        self.__volume__ = self.__initial_volume__
        self.__initial_pan__ = 0
        self.__pan__ = self.__initial_pan__
        self.__audio_level__ = -200
        self.__clips_model__ = [sketchpad_clips_model(song, self, 0), sketchpad_clips_model(song, self, 1), sketchpad_clips_model(song, self, 2), sketchpad_clips_model(song, self, 3), sketchpad_clips_model(song, self, 4)]
        self.__layers_snapshot = []
        self.master_volume = Zynthbox.Plugin.instance().dBFromVolume(self.zynqtgui.masterVolume/100)
        self.zynqtgui.masterVolumeChanged.connect(lambda: self.master_volume_changed())
        self.__connected_pattern__ = -1
        # self.__connected_sound__ = -1
        self.__chained_sounds__ = [-1, -1, -1, -1, -1]
        self.zynqtgui.screens["layer"].layer_deleted.connect(self.layer_deleted)
        self.__muted__ = False
        self.__samples__ = []
        self.__keyzone_mode__ = "all-full"
        self.__base_samples_dir__ = Path(self.__song__.sketchpad_folder) / 'wav' / 'sampleset'
        self.__color__ = "#000000"
        self.__selected_slot_row__ = 0
        self.__selected_fx_slot_row = 0
        self.__selected_part__ = 0
        self.__externalMidiChannel__ = -1
        self.__sound_json_snapshot__ = ""
        self.route_through_global_fx = True
        self.__channel_synth_ports = []
        self.__dry_amount = 100
        self.__wet_fx_1_amount = 100
        self.__wet_fx_2_amount = 100
        self.__filter_cutoff_controllers = [MultiController(parent=self), MultiController(parent=self), MultiController(parent=self), MultiController(parent=self), MultiController(parent=self)]
        self.__filter_resonance_controllers = [MultiController(parent=self), MultiController(parent=self), MultiController(parent=self), MultiController(parent=self), MultiController(parent=self)]

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
        self.__chained_sounds_info_updater.timeout.connect(self.chainedSoundsInfoChanged.emit)

        # Load engine config
        try:
            with open("/zynthian/zynthbox-qml/config/engine_config.json", "r") as f:
                self.__engine_config = json.load(f)
        except Exception as e:
            logging.error(f"Error loading engine config from /zynthian/zynthbox-qml/config/engine_config.json : {str(e)}")
            self.__engine_config = {}

        # Create 5 clip objects for 5 samples per channel
        for i in range(0, 5):
            newSample = sketchpad_clip(self.id, -1, -1, self.__song__, self, True)
            newSample.set_lane(i)
            self.__samples__.append(newSample)

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
            self.zynqtgui.sketchpad.song.scenesModel.selectedTrackIndexChanged.connect(lambda: self.occupiedSlotsChanged.emit())
        except:
            pass
        self.channel_audio_type_changed.connect(lambda: self.occupiedSlotsChanged.emit())
        self.samples_changed.connect(lambda: self.occupiedSlotsChanged.emit())

        self.selectedPartChanged.connect(lambda: self.clipsModelChanged.emit())
        self.selectedPartChanged.connect(lambda: self.scene_clip_changed.emit())
        self.zynqtgui.fixed_layers.list_updated.connect(self.fixed_layers_list_updated_handler_throttle.start)

        ### Proxy recordingPopupActive from zynthian_qt_gui
        self.zynqtgui.recordingPopupActiveChanged.connect(self.recordingPopupActiveChanged.emit)

        # Re-read sound snapshot json when a new snapshot is loaded
        self.zynqtgui.layer.snapshotLoaded.connect(self.update_sound_snapshot_json)
        # Update filter controllers when booting is complete
        self.zynqtgui.isBootingCompleteChanged.connect(self.update_filter_controllers)

    @Slot(int, int)
    def onClipEnabledChanged(self, trackIndex, partNum):
        clip = self.getClipsModelByPart(partNum).getClip(trackIndex)

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
        self.cache_bank_preset_lists()
        self.update_filter_controllers()
        self.zynqtgui.zynautoconnect()
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

    def cache_bank_preset_lists(self):
        # Back up curlayer
        curlayer = self.zynqtgui.curlayer

        for midi_channel in self.chainedSounds:
            if midi_channel >= 0 and self.checkIfLayerExists(midi_channel):
                # Change curlayer to synth's layer and fill back/preset list
                self.zynqtgui.curlayer = self.zynqtgui.layer.layer_midi_map[midi_channel]
                logging.debug(f"Caching midi channel : channel({midi_channel}), layer({self.zynqtgui.curlayer})")
                self.zynqtgui.currentTaskMessage = f"Caching bank/preset lists for Channel {self.name}"
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

                if layer.engine.nickname in self.__engine_config and \
                        "cutoffControl" in self.__engine_config[layer.engine.nickname] and \
                        self.__engine_config[layer.engine.nickname]["cutoffControl"] in synth_controllers_dict:
                    self.__filter_cutoff_controllers[index].add_control(synth_controllers_dict[self.__engine_config[layer.engine.nickname]["cutoffControl"]])
                elif "cutoff" in synth_controllers_dict:
                    self.__filter_cutoff_controllers[index].add_control(synth_controllers_dict["cutoff"])
                elif "filter_cutoff" in synth_controllers_dict:
                    self.__filter_cutoff_controllers[index].add_control(synth_controllers_dict["filter_cutoff"])

                if layer.engine.nickname in self.__engine_config and \
                        "resonanceControl" in self.__engine_config[layer.engine.nickname] and \
                        self.__engine_config[layer.engine.nickname]["resonanceControl"] in synth_controllers_dict:
                    self.__filter_resonance_controllers[index].add_control(synth_controllers_dict[self.__engine_config[layer.engine.nickname]["resonanceControl"]])
                elif "resonance" in synth_controllers_dict:
                    self.__filter_resonance_controllers[index].add_control(synth_controllers_dict["resonance"])
                elif "filter_resonance" in synth_controllers_dict:
                    self.__filter_resonance_controllers[index].add_control(synth_controllers_dict["filter_resonance"])

        self.filterCutoffControllersChanged.emit()
        self.filterResonanceControllersChanged.emit()

    def className(self):
        return "sketchpad_channel"

    def layer_deleted(self, chan : int):
        self.set_chained_sounds([-1 if x==chan else x for x in self.__chained_sounds__])

    def select_correct_layer(self):
        zynqtgui = self.__song__.get_metronome_manager().zynqtgui
        if self.checkIfLayerExists(zynqtgui.active_midi_channel):
            logging.info("### select_correct_layer : Reselect any available sound since it is removing current selected channel")
            # zynqtgui.screens['session_dashboard'].set_selected_channel(zynqtgui.screens['session_dashboard'].selectedChannel, True)
            try:
                zynqtgui.screens["layers_for_channel"].update_channel_sounds()
            except:
                pass
        else:
            logging.info("### select_correct_layer : Do not Reselect channel sound since it is not removing current selected channel")

    def master_volume_changed(self):
        self.master_volume = Zynthbox.Plugin.instance().dBFromVolume(self.zynqtgui.masterVolume/100)

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
                self.zynqtgui.zynautoconnect()
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

    @Slot()
    def update_jack_port(self, run_in_thread=True):
        if self.zynqtgui is not None and not self.zynqtgui.get_isBootingComplete():
            logging.debug("Booting in progress. Ignoring port update request")
            # QTimer.singleShot(1000, self.update_jack_port)
        else:
            self.zynqtgui.currentTaskMessage = f"Updating jack ports for channel `{self.name}`"

            # If run_in_thread is set to False, directly call the method
            # This will allow startup process to wait till all ports are updated before displaying splash screen
            if run_in_thread:
                self.update_jack_port_timer.start()
            else:
                self.do_update_jack_port(run_in_thread)

    def do_update_jack_port(self, run_in_thread=True):
        def task(zynqtgui, channel):
            jack_basenames = []

            channelHasEffects = False
            for ch in channel.chainedSounds:
                if ch >= 0 and channel.checkIfLayerExists(ch):
                    layer = zynqtgui.screens['layer'].layer_midi_map[ch]

                    # Iterate over all connected layers (including fx layer) on midi channel `channel`
                    for fxlayer in zynqtgui.screens['layer'].get_fxchain_layers(layer):
                        try:
                            jack_basenames.append(fxlayer.jackname.split(":")[0])

                            # fxlayer can be a Midi synth, or an effect. Check if it is an effect
                            if fxlayer.engine.type == "Audio Effect":
                                channelHasEffects = True
                        except Exception as e:
                            logging.error(f"### update_jack_port Error : {str(e)}")

            synth_ports = []

            for port_name in jack_basenames:
                port_names = []
                ports = [x.name for x in jack.Client("").get_ports(name_pattern=port_name, is_output=True, is_audio=True, is_physical=False)]

                for port in zip(ports, [f"AudioLevels:Channel{self.id + 1}-left_in", f"AudioLevels:Channel{self.id + 1}-right_in"]):
                    port_names.append(port[0])

                synth_ports.append(port_names)

            self.set_channelSynthPorts(synth_ports)

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


    @Signal
    def volume_changed(self):
        pass

    def get_volume(self):
        return self.__volume__

    def set_volume(self, volume:int, force_set=False):
        if self.__volume__ != round(volume) or force_set is True:
            self.__volume__ = round(volume)
            self.set_dryAmount(self.dryAmount, True)
            self.set_wetFx1Amount(self.wetFx1Amount, True)
            self.set_wetFx2Amount(self.wetFx2Amount, True)

            self.volume_changed.emit()
            self.__song__.schedule_save()

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
            Zynthbox.Plugin.instance().channelPassthroughClients()[self.id].setPanAmount(self.__pan__)
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
            # zynqtgui.screens['session_dashboard'].set_selected_channel(zynqtgui.screens['session_dashboard'].selectedChannel, True)
            zynqtgui.screens['layers_for_channel'].activate_index(0)
            zynqtgui.set_curlayer(None)
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
        zynqtgui = self.__song__.get_metronome_manager().zynqtgui

        def task():
            zynqtgui.screens['layers_for_channel'].fill_list()

            zynqtgui.layer.remove_root_layer(chan)
            self.select_correct_layer()
            self.__song__.schedule_save()
            self.chained_sounds_changed.emit()

            if cb is not None:
                cb()

            zynqtgui.end_long_task()

        self.zynqtgui.currentTaskMessage = f"Removing chained sound at slot `{self.selectedSlotRow + 1}` from channel `{self.name}`"
        zynqtgui.do_long_task(task)

    def set_chained_sounds(self, sounds):
        update_jack_ports = True

        # Stop all playing notes
        for old_chan in self.__chained_sounds__:
            if old_chan > -1:
                self.zynqtgui.raw_all_notes_off_chan(old_chan)

        chained_sounds = [-1, -1, -1, -1, -1]
        for i, sound in enumerate(sounds):
            if sound not in chained_sounds:
                chained_sounds[i] = sound

        if chained_sounds == self.__chained_sounds__:
            update_jack_ports = False

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
        if self.__muted__ != muted:
            self.__muted__ = muted
            Zynthbox.Plugin.instance().channelPassthroughClients()[self.id].setMuted(muted)
            self.mutedChanged.emit()

    mutedChanged = Signal()

    muted = Property(bool, get_muted, set_muted, notify=mutedChanged)
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
            self.channel_audio_type_changed.emit()

            # Set selectedSlotRow to 0 when type is changed to slice as slice mode always operates on slot 0
            if type == "sample-slice":
                self.selectedSlotRow = 0

            # Set keyZoneMode to "Off"(all-full) state when type is changed to trig
            if type == "sample-trig":
                self.keyZoneMode = "all-full"

            for track in range(0, 10):
                for part in range(0, 5):
                    clip = self.__song__.getClipByPart(self.id, track, part)
                    if clip is not None:
                        clip.enabled_changed.emit(clip.col, clip.part)
            if force_set == False:
                self.__song__.schedule_save()
            self.update_jack_port()

    channel_audio_type_changed = Signal()

    channelAudioType = Property(str, get_channel_audio_type, set_channel_audio_type, notify=channel_audio_type_changed)
    ### END Property channelAudioType

    ### BEGIN Property channelTypeDisplayName
    def get_channelTypeDisplayName(self):
        if self.__channel_audio_type__ == "synth":
            return "Synth"
        elif self.__channel_audio_type__ == "sample-loop":
            return "Sketch"
        elif self.__channel_audio_type__.startswith("sample"):
            return "Sample"
        elif self.__channel_audio_type__ == "external":
            return "External"

    channelTypeDisplayName = Property(str, get_channelTypeDisplayName, notify=channel_audio_type_changed)
    ### END Property channelTypeDisplayName

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
                    clip = self.__song__.getClipByPart(self.id, track, part)
                    if clip is not None:
                        clip.enabled_changed.emit(clip.col, clip.part)
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
                    layer = self.zynqtgui.layer.layer_midi_map[sound]
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
        self.__chained_sounds_info_updater.start()

    chainedSoundsInfoChanged = Signal()

    chainedSoundsInfo = Property('QVariantList', get_chainedSoundsInfo, notify=chainedSoundsInfoChanged)

    ### END Property chained_sounds_presets

    ### Property selectedSlotRow
    def get_selectedSlotRow(self):
        return self.__selected_slot_row__

    def set_selectedSlotRow(self, row):
        if self.__selected_slot_row__ != row:
            self.__selected_slot_row__ = row
            self.selectedSlotRowChanged.emit()

    selectedSlotRowChanged = Signal()

    selectedSlotRow = Property(int, get_selectedSlotRow, set_selectedSlotRow, notify=selectedSlotRowChanged)
    ### END Property selectedSlotRow

    ### Property selectedFxSlotRow
    def get_selectedFxSlotRow(self):
        return self.__selected_fx_slot_row

    def set_selectedFxSlotRow(self, row):
        if self.__selected_fx_slot_row != row:
            self.__selected_fx_slot_row = row
            self.selectedFxSlotRowChanged.emit()

    selectedFxSlotRowChanged = Signal()

    selectedFxSlotRow = Property(int, get_selectedFxSlotRow, set_selectedFxSlotRow, notify=selectedFxSlotRowChanged)
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
            clip = self.getClipsModelByPart(i).getClip(self.zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex)

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

    ### Property channelHasSynth
    def get_channelHasSynth(self):
        for sound in self.__chained_sounds__:
            if sound >= 0 and self.checkIfLayerExists(sound):
                return True
        return False

    channelHasSynth = Property(bool, get_channelHasSynth, notify=chained_sounds_changed)
    ### END Property channelSynthPorts

    ### Property dryAmount
    def get_dryAmount(self):
        return self.__dry_amount

    def set_dryAmount(self, value, force_set=False):
        if self.__dry_amount != value or force_set is True:
            self.__dry_amount = value
            volume = np.interp(self.__volume__, (-40, 20), (0, 1))
            # Calculate dry amount as per volume
            Zynthbox.Plugin.instance().channelPassthroughClients()[self.id].setDryAmount(np.interp(self.__dry_amount * volume, (0, 100), (0, 1)))
            self.dryAmountChanged.emit()

    dryAmountChanged = Signal()

    dryAmount = Property(float, get_dryAmount, set_dryAmount, notify=dryAmountChanged)
    ### END Property wetFx2Amount

    ### Property wetFx1Amount
    def get_wetFx1Amount(self):
        return self.__wet_fx_1_amount

    def set_wetFx1Amount(self, value, force_set=False):
        if self.__wet_fx_1_amount != value or force_set is True:
            self.__wet_fx_1_amount = value
            volume = np.interp(self.__volume__, (-40, 20), (0, 1))
            # Calculate wet amount as per volume
            Zynthbox.Plugin.instance().channelPassthroughClients()[self.id].setWetFx1Amount(np.interp(self.__wet_fx_1_amount * volume, (0, 100), (0, 1)))
            self.wetFx1AmountChanged.emit()

    wetFx1AmountChanged = Signal()

    wetFx1Amount = Property(int, get_wetFx1Amount, set_wetFx1Amount, notify=wetFx1AmountChanged)
    ### END Property wetFx1Amount

    ### Property wetFx2Amount
    def get_wetFx2Amount(self):
        return self.__wet_fx_2_amount

    def set_wetFx2Amount(self, value, force_set=False):
        if self.__wet_fx_2_amount != value or force_set is True:
            self.__wet_fx_2_amount = value
            volume = np.interp(self.__volume__, (-40, 20), (0, 1))
            # Calculate wet amount as per volume
            Zynthbox.Plugin.instance().channelPassthroughClients()[self.id].setWetFx2Amount(np.interp(self.__wet_fx_2_amount * volume, (0, 100), (0, 1)))
            self.wetFx2AmountChanged.emit()

    wetFx2AmountChanged = Signal()

    """
    Store wetFx1Amount for current channel as a property and set it to JackPassthrough when value changes
    Stored value ranges from 0-100 and accepted range by setWetFx1Amount is 0-1
    """
    wetFx2Amount = Property(float, get_wetFx2Amount, set_wetFx2Amount, notify=wetFx2AmountChanged)
    ### END Property wetFx2Amount

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

    @Slot(None, result=QObject)
    def getClipToRecord(self):
        if self.channelAudioType in ["sample-trig", "sample-slice"]:
            return self.samples[self.selectedSlotRow]
        else:
            return self.getClipsModelByPart(self.selectedSlotRow).getClip(self.__song__.scenesModel.selectedTrackIndex)

    @Slot(str)
    def setChannelSamplesFromSnapshot(self, snapshot: str):
        sampleData = json.loads(snapshot)
        i = 0
        for sample in sampleData:
            if i > 4:
                logging.error("For some reason we have more than five elements in the encoded sample data, what happened?!")
                break;
            filename = sample["filename"]
            # Clear out the existing sample, whether or not there's a new sample to go into that spot
            # If the filename is an empty string, nothing to load
            if len(filename) == 0:
                # Store the new sample in a temporary file
                with tempfile.TemporaryDirectory() as tmp:
                    temporaryFile = Path(tmp) / filename
                    with open(temporaryFile, "wb") as file:
                        file.write(base64.b64decode(sample["sampledata"]))
                    # Now set this slot's path to that, and should_copy is True by default, but let's be explicit so we can make sure it keeps working
                    self.__samples__[i].set_path(temporaryFile, should_copy=True)
            i += 1
        pass

    @Slot(None, result=str)
    def getChannelSampleSnapshot(self):
        encodedSampleData = {};
        for index in range(5):
            sample = self.__samples__[index]
            thisSample = {
                "filename": "",
                "sampledata": ""
                }
            if len(sample.path()) > 0:
                thisSample["filename"] = sample.filename()
                with open(sample.path(), "rb") as file:
                    thisSample["sampledata"] = base64.b64encode(file.read())
            encodedSampleData[index] = thisSample
        return json.dumps(encodedSampleData)

    @Slot(None, result=str)
    def getChannelSoundSnapshotJson(self):
        #logging.error(f"getChannelSoundSnapshotJson : T({self.__id__ + 1})")
        return self.__sound_json_snapshot__

    @Slot(str, result=None)
    def setChannelSoundFromSnapshotJson(self, snapshot):
        self.zynqtgui.sound_categories.loadChannelSoundFromJson(self.id, snapshot)

    def update_sound_snapshot_json(self):
        if self.connectedSound == -1:
            self.__sound_json_snapshot__ = ""
        else:
            self.__sound_json_snapshot__ = json.dumps(self.zynqtgui.layer.export_multichannel_snapshot(self.connectedSound))

        # logging.debug(f"### sound snapshot json for channel {self.name} connectedSound {self.connectedSound} : {self.__sound_json_snapshot__}")

    className = Property(str, className, constant=True)
