#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Sketchpad Song: An object to store song information
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
import math
import shutil
import Zynthbox
import logging
import json
import os
import warnings

from pathlib import Path
from PySide2.QtCore import Qt, QTimer, QMetaObject, Property, QObject, Signal, Slot
from .sketchpad_sketch import sketchpad_sketch
from .sketchpad_sketches_model import sketchpad_sketches_model
from .sketchpad_scenes_model import sketchpad_scenes_model
from .sketchpad_segment import sketchpad_segment
from .sketchpad_channel import sketchpad_channel
from .sketchpad_part import sketchpad_part
from .sketchpad_clip import sketchpad_clip
from .sketchpad_parts_model import sketchpad_parts_model
from .sketchpad_channels_model import sketchpad_channels_model
from zynqtgui import zynthian_gui_config

def restorePassthroughClientData(passthroughClient, dataChunk):
    for index, filterValues in enumerate(dataChunk["equaliserSettings"]):
        passthroughClient.equaliserSettings()[index].setFilterType(Zynthbox.JackPassthroughFilter.FilterType.values[filterValues["filterType"]])
        passthroughClient.equaliserSettings()[index].setFrequency(filterValues["frequency"])
        passthroughClient.equaliserSettings()[index].setQuality(filterValues["quality"])
        passthroughClient.equaliserSettings()[index].setSoloed(filterValues["soloed"])
        passthroughClient.equaliserSettings()[index].setGain(filterValues["gain"])
        passthroughClient.equaliserSettings()[index].setActive(filterValues["active"])
    passthroughClient.compressorSettings().setThresholdDB(dataChunk["compressorSettings"]["thresholdDB"])
    passthroughClient.compressorSettings().setMakeUpGainDB(dataChunk["compressorSettings"]["makeUpGainDB"])
    passthroughClient.compressorSettings().setKneeWidthDB(dataChunk["compressorSettings"]["kneeWidthDB"])
    passthroughClient.compressorSettings().setRelease(dataChunk["compressorSettings"]["release"])
    passthroughClient.compressorSettings().setAttack(dataChunk["compressorSettings"]["attack"])
    passthroughClient.compressorSettings().setRatio(dataChunk["compressorSettings"]["ratio"])
    passthroughClient.setEqualiserEnabled(dataChunk["equaliserEnabled"])
    passthroughClient.setCompressorEnabled(dataChunk["compressorEnabled"])
    passthroughClient.setCompressorSidechannelLeft(dataChunk["compressorSidechannelLeft"])
    passthroughClient.setCompressorSidechannelRight(dataChunk["compressorSidechannelRight"])
def setPassthroughClientDefaults(passthroughClient):
    passthroughClient.setEqualiserEnabled(False)
    passthroughClient.setCompressorEnabled(False)
    passthroughClient.setCompressorSidechannelLeft("")
    passthroughClient.setCompressorSidechannelRight("")
    for filterObject in passthroughClient.equaliserSettings():
        filterObject.setDefaults()
    passthroughClient.compressorSettings().setDefaults()

class sketchpad_song(QObject):
    __instance__ = None

    def __init__(self, sketchpad_folder: str, name, parent=None, load_autosave=True):
        super(sketchpad_song, self).__init__(parent)

        self.zynqtgui = zynthian_gui_config.zynqtgui
        self.__metronome_manager__ = parent
        self.sketchpad_folder = sketchpad_folder

        self.__is_loading__ = True
        self.__is_saving__ = False
        self.isLoadingChanged.emit()
        self.__channels_model__ = sketchpad_channels_model(self)
        self.__parts_model__ = sketchpad_parts_model(self)
        self.__scenes_model__ = sketchpad_scenes_model(self)
        self.__sketches_model__ = sketchpad_sketches_model(self)
        self.__bpm__ = [120, 120, 120, 120, 120, 120, 120, 120, 120, 120]
        self.__volume__ = 100
        self.__index__ = 0
        self.__is_playing__ = False
        self.__save_timer__ = QTimer(self)
        self.__save_timer__.setInterval(1000)
        self.__save_timer__.setSingleShot(True)
        self.__save_timer__.timeout.connect(self.save)
        self.__scale_model__ = ['C', 'G', 'D', 'A', 'E', 'B', 'Gb', 'Db', 'Ab', 'Eb', 'Bb', 'F']
        self.__selected_scale_index__ = 0
        # The octave is -1 indexed, as we operate with C4 == midi note 60, so this makes our default a key of C2
        self.__octave__ = 2
        self.__play_channel_solo = -1
        self.__hasUnsavedChanges__ = False

        self.__current_bar__ = 0
        self.__current_part__ = self.__parts_model__.getPart(0)
        self.__name__ = name
        # self.__initial_name__ = name # To be used while storing cache details when name changes
        self.__to_be_deleted__ = False

        def connectPassthroughClientForSaving(passthroughClient):
            passthroughClient.equaliserEnabledChanged.connect(self.schedule_save)
            for filterObject in passthroughClient.equaliserSettings():
                filterObject.filterTypeChanged.connect(self.schedule_save)
                filterObject.frequencyChanged.connect(self.schedule_save)
                filterObject.qualityChanged.connect(self.schedule_save)
                filterObject.soloedChanged.connect(self.schedule_save)
                filterObject.gainChanged.connect(self.schedule_save)
                filterObject.activeChanged.connect(self.schedule_save)
            passthroughClient.compressorEnabledChanged.connect(self.schedule_save)
            passthroughClient.compressorSidechannelLeftChanged.connect(self.schedule_save)
            passthroughClient.compressorSidechannelRightChanged.connect(self.schedule_save)
            passthroughClient.compressorSettings().thresholdChanged.connect(self.schedule_save)
            passthroughClient.compressorSettings().makeUpGainChanged.connect(self.schedule_save)
            passthroughClient.compressorSettings().kneeWidthChanged.connect(self.schedule_save)
            passthroughClient.compressorSettings().releaseChanged.connect(self.schedule_save)
            passthroughClient.compressorSettings().attackChanged.connect(self.schedule_save)
            passthroughClient.compressorSettings().ratioChanged.connect(self.schedule_save)
        connectPassthroughClientForSaving(Zynthbox.Plugin.instance().globalPlaybackClient())
        for midiChannel in range(0, 16):
            connectPassthroughClientForSaving(Zynthbox.Plugin.instance().synthPassthroughClients()[midiChannel])
        for trackIndex in range(0, Zynthbox.Plugin.instance().sketchpadTrackCount()):
            connectPassthroughClientForSaving(Zynthbox.Plugin.instance().trackPassthroughClients()[trackIndex])
            for slotIndex in range(0, Zynthbox.Plugin.instance().sketchpadPartCount()):
                connectPassthroughClientForSaving(Zynthbox.Plugin.instance().fxPassthroughClients()[trackIndex][slotIndex])

        if not self.restore(load_autosave):
            # Creating new temp sketchpad. So set hasUnsavedChanges to True
            self.hasUnsavedChanges = True
            self.__is_loading__ = True
            self.isLoadingChanged.emit()
            # First, clear out any cruft that might have occurred during a failed load attempt
            self.__parts_model__ = sketchpad_parts_model(self)
            self.__channels_model__ = sketchpad_channels_model(self)
            self.__scenes_model__ = sketchpad_scenes_model(self)
            self.__sketches_model__ = sketchpad_sketches_model(self)

            # Add default parts
            for i in range(0, 10):
                self.__parts_model__.add_part(sketchpad_part(i, self))

            for _ in range(0, 10):
                channel = sketchpad_channel(self.__channels_model__.count, self, self.__channels_model__)
                self.__channels_model__.add_channel(channel)
                # Set default audio type settings when creating new channel to reset passthroug clients to default values
                channel.setAudioTypeSettings(channel.defaultAudioTypeSettings())

                # Create 5 parts per channel
                for i in range(0, 5):
                    clipsModel = channel.getClipsModelByPart(i)
                    # There is only 1 track now
                    for j in range(1):
                        clip = sketchpad_clip(channel.id, j, i, self, clipsModel)
                        clipsModel.add_clip(clip)

            for channel_index in range(10):
                channel = self.__channels_model__.getChannel(channel_index)

                # Add first part of channel to current scene
                # There is only 1 track now
                for track_index in range(1):
                    channel.getClipsModelByPart(0).getClip(track_index).enabled = True

            # Add default Sketches and Segments
            for sketch_index in range(10):
                sketch = sketchpad_sketch(sketch_index, self)
                segment = sketchpad_segment(sketch, sketch.segmentsModel, self)
                sketch.segmentsModel.add_segment(0, segment)

                self.__sketches_model__.add_sketch(sketch_index, sketch)

            # Clear all the passthrough clients to default state
            setPassthroughClientDefaults(Zynthbox.Plugin.instance().globalPlaybackClient())
            for trackIndex in range(0, Zynthbox.Plugin.instance().sketchpadTrackCount()):
                setPassthroughClientDefaults(Zynthbox.Plugin.instance().trackPassthroughClients()[trackIndex])
                for slotIndex in range(0, Zynthbox.Plugin.instance().sketchpadPartCount()):
                    setPassthroughClientDefaults(Zynthbox.Plugin.instance().fxPassthroughClients()[trackIndex][slotIndex])
            for midiChannel in range(0, 16):
                setPassthroughClientDefaults(Zynthbox.Plugin.instance().synthPassthroughClients()[midiChannel])

        # Save updated bpm value when it changes
        Zynthbox.SyncTimer.instance().bpmChanged.connect(self.setTrackBpmFromCurrent)

        # Create wav dir for recording
        (Path(self.sketchpad_folder) / 'wav').mkdir(parents=True, exist_ok=True)
        # Create sampleset dir if not exists
        (Path(self.sketchpad_folder) / 'wav' / 'sampleset').mkdir(parents=True, exist_ok=True)
        # Finally, just in case something happened, make sure we're not loading any longer
        self.__is_loading__ = False
        self.isLoadingChanged.emit()

    def to_be_deleted(self):
        self.__to_be_deleted__ = True

    def serialize(self):
        def serializePassthroughData(passthroughClient):
            equaliserSettingsData = []
            for client in passthroughClient.equaliserSettings():
                equaliserSettingsData.append({
                    "filterType": client.filterType().name.decode().split(".")[-1],
                    "frequency": client.frequency(),
                    "quality": client.quality(),
                    "soloed": client.soloed(),
                    "gain": client.gain(),
                    "active": client.active()
                })
            return {
                "equaliserSettings": equaliserSettingsData,
                "equaliserEnabled": passthroughClient.equaliserEnabled(),
                "compressorEnabled": passthroughClient.compressorEnabled(),
                "compressorSidechannelLeft": passthroughClient.compressorSidechannelLeft(),
                "compressorSidechannelRight": passthroughClient.compressorSidechannelRight(),
                "compressorSettings": {
                    "thresholdDB": passthroughClient.compressorSettings().thresholdDB(),
                    "makeUpGainDB": passthroughClient.compressorSettings().makeUpGainDB(),
                    "kneeWidthDB": passthroughClient.compressorSettings().kneeWidthDB(),
                    "release": passthroughClient.compressorSettings().release(),
                    "attack": passthroughClient.compressorSettings().attack(),
                    "ratio": passthroughClient.compressorSettings().ratio()
                }
            }
        synthPassthroughClientsData = []
        for midiChannel in range(0, 16):
            synthPassthroughClientsData.append(serializePassthroughData(Zynthbox.Plugin.instance().synthPassthroughClients()[midiChannel]))
        trackPassthroughClientsData = []
        for trackIndex in range(0, Zynthbox.Plugin.instance().sketchpadTrackCount()):
            slotData = []
            for slotIndex in range(0, Zynthbox.Plugin.instance().sketchpadPartCount()):
                slotData.append(serializePassthroughData(Zynthbox.Plugin.instance().fxPassthroughClients()[trackIndex][slotIndex]))
            trackPassthroughClientsData.append({
                    "trackPassthroughClient": serializePassthroughData(Zynthbox.Plugin.instance().trackPassthroughClients()[trackIndex]),
                    "fxPassthroughClients": slotData
                })
        return {
            "name": self.__name__,
            "bpm": self.__bpm__,
            "volume": self.__volume__,
            "selectedScaleIndex": self.__selected_scale_index__,
            "octave": self.__octave__,
            "tracks": self.__channels_model__.serialize(),
            "parts": self.__parts_model__.serialize(),
            "scenes": self.__scenes_model__.serialize(),
            "sketches": self.__sketches_model__.serialize(),
            "globalPlaybackClient": serializePassthroughData(Zynthbox.Plugin.instance().globalPlaybackClient()),
            "trackPassthroughClients": trackPassthroughClientsData,
            "synthPassthroughClients": synthPassthroughClientsData
        }

    def save(self, autosave=True):
        if self.__is_saving__ == False:
            if self.__to_be_deleted__:
                return
            self.set_isSaving(True)

            sketchpad_file = None
            save_snapshot = None
            soundsets_dir = Path(self.sketchpad_folder) / "soundsets"
            current_state_obj = self.serialize()

            if not self.isTemp and autosave is True:
                logging.debug("Writing autosave")
                # Since this is an autosave or a temp sketchpad, do not save snapshot as it relies on last_state snapshot
                save_snapshot = False
                # If this is an autosave or if it is a temp sketchpad set sketchpad name to autosave
                # (temp sketchpads do not have autosave file. Sketchpad-1.sketchpad.json acts as the autosave file)
                sketchpad_file = Path(self.sketchpad_folder) / "Autosave.sketchpad.json"
                # Since this is an autosave, sketchpad has unsaved changes
                self.hasUnsavedChanges = True
                self.zynqtgui.global_settings.setValue("Sketchpad/lastSelectedSketchpad", str(sketchpad_file))
            else:
                if self.isTemp:
                    # For temp sketchpad, do not save snapshot as it relies on last_state snapshot
                    save_snapshot = False
                    # temp sketchpad should always have hasUnsavedChanges set to True
                    self.hasUnsavedChanges = True
                else:
                    # For non temp sketchpads, do save snapshot
                    save_snapshot = True
                    # For non temp sketchpads, saving sketchpad deletes the autosave and hence mark hasUnsavedChanges to False
                    self.hasUnsavedChanges = False
                # Since this is not an autosave, set sketchpad file name to fullname
                sketchpad_file = Path(self.sketchpad_folder) / f"{self.__name__}.sketchpad.json"
                logging.info(f"Storing sketchpad to {str(sketchpad_file)}")
                # Also delete the cache file as we are performing a sketchpad save initiated by user
                Path(self.sketchpad_folder + "Autosave.sketchpad.json").unlink(missing_ok=True)

            # Save a sequence for this version if not a temp sketchpad and not an autosave version
            if not self.isTemp and not autosave:
                sequenceModel = Zynthbox.PlayGridManager.instance().getSequenceModel(self.scenesModel.selectedSequenceName)
                sequenceModel.exportTo(f"{self.sketchpad_folder}/sequences/{self.name}/{sequenceModel.objectName().lower().replace(' ', '-')}/metadata.sequence.json")

            try:
                Path(self.sketchpad_folder).mkdir(parents=True, exist_ok=True)
                with open(sketchpad_file, "w") as f:
                    f.write(json.dumps(current_state_obj))
                    f.flush()
                    os.fsync(f.fileno())
            except Exception as e:
                logging.exception(f"Error writing sketchpad json to {str(sketchpad_file)} : {e}")

            if save_snapshot:
                snapshot_file = str(soundsets_dir) + "/" + self.__name__ + ".zss"
                try:
                    soundsets_dir.mkdir(parents=True, exist_ok=True)
                    self.zynqtgui.layer.save_snapshot(snapshot_file)
                except Exception as e:
                    logging.error(f"Error saving snapshot to {snapshot_file} : {str(e)}")
            self.set_isSaving(False)

            for trackId in range(self.__channels_model__.count):
                track = self.__channels_model__.getChannel(trackId)
                bank_dir = Path(track.bankDir)
                # Do some cleanup
                # If there's a sample bank there already, get rid of it
                if (bank_dir / 'sample-bank.json').exists():
                    os.remove(bank_dir / 'sample-bank.json')
                if bank_dir.exists() and len(os.listdir(bank_dir)) == 0:
                    os.removedirs(bank_dir)
                # Write sample metadata
                for sample in track.samples:
                    sample.metadata.write(isAutosave=autosave)
                # Write clip metadata
                for part_index in range(5):
                    clips_model = track.getClipsModelByPart(part_index)
                    for clip_index in range(clips_model.count):
                        clip = clips_model.getClip(clip_index)
                        clip.metadata.write(isAutosave=autosave)

    @Slot(None)
    def schedule_save(self):
        if self.__is_loading__ == False and self.__is_saving__ == False:
            QMetaObject.invokeMethod(self.__save_timer__, "start", Qt.QueuedConnection)

    def restore(self, load_autosave):
        if self.__name__ == "Autosave":
            # If user is explicitly loading Autosave, set load_autosave to True to mimic automatic loading an autosave sketchpad
            load_autosave = True
        sketchpad_file = Path(self.sketchpad_folder) / f"{self.__name__}.sketchpad.json"
        self.__is_loading__ = True
        self.isLoadingChanged.emit()
        self.zynqtgui.currentTaskMessage = "Loading Sketchpad : Restoring Data"

        if load_autosave is True and (Path(self.sketchpad_folder) / "Autosave.sketchpad.json").exists():
            sketchpad_file = Path(self.sketchpad_folder) / "Autosave.sketchpad.json"
            # Since this is an autosave, sketchpad has unsaved changes
            self.hasUnsavedChanges = True
        else:
            # Since this is NOT an autosave, sketchpad does not have any unsaved changes
            self.hasUnsavedChanges = False
            # Also delete the cache file if there are any (for fallback purposes)
            Path(self.sketchpad_folder + "Autosave.sketchpad.json").unlink(missing_ok=True)

        try:
            if sketchpad_file.exists():
                logging.info(f"Restoring sketchpad {sketchpad_file}")
                with open(sketchpad_file, "r") as f:
                    sketchpad = json.loads(f.read())

                    if "name" in sketchpad and sketchpad["name"] != "":
                        if self.__name__ == "Autosave":
                            # If Sketchpad name is Autosave, make sure to update self.__name__ to the one saved in json
                            self.__name__ = sketchpad["name"]
                            self.__name_changed__.emit()
                        elif self.__name__ != sketchpad["name"]:
                            logging.info(f"Sketchpad filename changed from '{sketchpad['name']}' to '{self.__name__}'. "
                                        f"Trying to rename soundset file.")
                            logging.info(f'Renaming {self.sketchpad_folder}/soundsets/{sketchpad["name"]}.zss to {self.sketchpad_folder}/soundsets/{self.__name__}.zss')

                            try:
                                shutil.move(f'{self.sketchpad_folder}/soundsets/{sketchpad["name"]}.zss', f'{self.sketchpad_folder}/soundsets/{self.__name__}.zss')
                            except Exception as e:
                                logging.error(f"Error renaming old soundset to new name : {str(e)}")
                    if "volume" in sketchpad:
                        self.__volume__ = sketchpad["volume"]
                        self.set_volume(self.__volume__, True)
                    if "selectedScaleIndex" in sketchpad:
                        self.set_selected_scale_index(sketchpad["selectedScaleIndex"], True)
                    if "octave" in sketchpad:
                        self.set_octave(sketchpad["octave"], True)
                    if "parts" in sketchpad:
                        self.__parts_model__.deserialize(sketchpad["parts"])

                    # TODO : `channels` key is deprecated and has been renamed to `tracks`. Remove this fallback later
                    if "channels" in sketchpad:
                        warnings.warn("`channels` key is deprecated (will be removed soon) and has been renamed to `track`. Update any existing references to avoid issues with loading sketchpad", DeprecationWarning)
                        self.__channels_model__.deserialize(sketchpad["channels"], load_autosave=not self.isTemp and load_autosave)
                    if "tracks" in sketchpad:
                        self.__channels_model__.deserialize(sketchpad["tracks"], load_autosave=not self.isTemp and load_autosave)

                    if "scenes" in sketchpad:
                        self.__scenes_model__.deserialize(sketchpad["scenes"])
                    if "sketches" in sketchpad:
                        self.__sketches_model__.deserialize(sketchpad["sketches"])
                    if "bpm" in sketchpad:
                        # In older sketchpad files, bpm would still be an int instead of a list
                        # So if bpm is not a list, then generate a list and store it
                        if isinstance(sketchpad["bpm"], list):
                            self.__bpm__ = sketchpad["bpm"]
                        else:
                            self.__bpm__ = [120, 120, 120, 120, 120, 120, 120, 120, 120, 120]
                            self.__bpm__[self.__scenes_model__.selectedSketchpadSongIndex] = sketchpad["bpm"]

                        Zynthbox.SyncTimer.instance().setBpm(self.__bpm__[self.__scenes_model__.selectedSketchpadSongIndex])

                    if "globalPlaybackClient" in sketchpad:
                        restorePassthroughClientData(Zynthbox.Plugin.instance().globalPlaybackClient(), sketchpad["globalPlaybackClient"])
                    else:
                        setPassthroughClientDefaults(Zynthbox.Plugin.instance().globalPlaybackClient())
                    if "trackPassthroughClients" in sketchpad:
                        for trackIndex in range(0, Zynthbox.Plugin.instance().sketchpadTrackCount()):
                            restorePassthroughClientData(Zynthbox.Plugin.instance().trackPassthroughClients()[trackIndex], sketchpad["trackPassthroughClients"][trackIndex]["trackPassthroughClient"])
                            for slotIndex in range(0, Zynthbox.Plugin.instance().sketchpadPartCount()):
                                restorePassthroughClientData(Zynthbox.Plugin.instance().fxPassthroughClients()[trackIndex][slotIndex], sketchpad["trackPassthroughClients"][trackIndex]["fxPassthroughClients"][slotIndex])
                    else:
                        for trackIndex in range(0, Zynthbox.Plugin.instance().sketchpadTrackCount()):
                            setPassthroughClientDefaults(Zynthbox.Plugin.instance().trackPassthroughClients()[trackIndex])
                            for slotIndex in range(0, Zynthbox.Plugin.instance().sketchpadPartCount()):
                                setPassthroughClientDefaults(Zynthbox.Plugin.instance().fxPassthroughClients()[trackIndex][slotIndex])
                    if "synthPassthroughClients" in sketchpad:
                        for midiChannel in range(0, 16):
                            restorePassthroughClientData(Zynthbox.Plugin.instance().synthPassthroughClients()[midiChannel], sketchpad["synthPassthroughClients"][midiChannel])
                    else:
                        for midiChannel in range(0, 16):
                            setPassthroughClientDefaults(Zynthbox.Plugin.instance().synthPassthroughClients()[midiChannel])

                    # Load sequence model for this version explicitly after restoring sketchpad if it is not a temp sketchpad and not an autosave version
                    if not self.isTemp and not load_autosave:
                        sequenceModel = Zynthbox.PlayGridManager.instance().getSequenceModel(self.scenesModel.selectedSequenceName)
                        sequenceModel.importFrom(f"{self.sketchpad_folder}/sequences/{self.name}/{sequenceModel.objectName().lower().replace(' ', '-')}/metadata.sequence.json")

                    self.__is_loading__ = False
                    self.isLoadingChanged.emit()
                    return True
            else:
                logging.info(f"Sketchpad not restored - no such file (expected when creating a new sketchpad): {sketchpad_file}")
                self.__is_loading__ = False
                self.isLoadingChanged.emit()
                return False
        except Exception as e:
            logging.exception(f"Error during sketchpad restoration: {e}")

            self.__is_loading__ = False
            self.isLoadingChanged.emit()
            return False

    @Slot(int, int, result=QObject)
    def getClip(self, channel: int, sketchpad: int):
        # logging.error("GETCLIP {} {} count {}".format(channel, part, self.__channels_model__.count))
        if channel >= self.__channels_model__.count:
            return None

        channel = self.__channels_model__.getChannel(channel)
        # logging.error(channel.clipsModel.count)

        if sketchpad >= channel.clipsModel.count:
            return None

        clip = channel.clipsModel.getClip(sketchpad)
        # logging.error(clip)
        return clip

    @Slot(int, int, int, result=QObject)
    def getClipByPart(self, channel: int, sketchpad: int, part: int):
        # logging.error("GETCLIP {} {} count {}".format(channel, part, self.__channels_model__.count))
        if channel >= self.__channels_model__.count:
            return None

        channel = self.__channels_model__.getChannel(channel)
        # logging.error(channel.clipsModel.count)

        clipsModel = channel.getClipsModelByPart(part)
        if sketchpad >= clipsModel.count:
            return None

        clip = clipsModel.getClip(sketchpad)
        # logging.error(clip)
        return clip


    def get_metronome_manager(self):
        return self.__metronome_manager__

    def playable(self):
        return False
    playable = Property(bool, playable, constant=True)

    def recordable(self):
        return False
    recordable = Property(bool, recordable, constant=True)

    def clearable(self):
        return False
    clearable = Property(bool, clearable, constant=True)

    def deletable(self):
        return False
    deletable = Property(bool, deletable, constant=True)

    def nameEditable(self):
        return True
    nameEditable = Property(bool, nameEditable, constant=True)

    @Signal
    def is_temp_changed(self):
        pass

    def get_isTemp(self):
        return self.sketchpad_folder == str(Path("/zynthian/zynthian-my-data/sketchpads/my-sketchpads/") / "temp") + "/"

    isTemp = Property(bool, get_isTemp, notify=is_temp_changed)

    @Signal
    def __name_changed__(self):
        pass


    def name(self):
        return self.__name__

    def set_name(self, name):
        if name is not None:
            self.__name__ = name
            self.__name_changed__.emit()
            self.is_temp_changed.emit()
            self.schedule_save()

    name = Property(str, name, set_name, notify=__name_changed__)


    @Signal
    def volume_changed(self):
        pass

    def get_volume(self):
        return self.__volume__

    def set_volume(self, volume:int, force_set=False):
        if self.__volume__ != math.floor(volume) or force_set is True:
            self.__volume__ = math.floor(volume)
            self.volume_changed.emit()
            self.schedule_save()

    volume = Property(int, get_volume, set_volume, notify=volume_changed)

    @Signal
    def index_changed(self):
        pass

    @Signal
    def __is_playing_changed__(self):
        pass

    @Signal
    def current_beat_changed(self):
        pass

    @Signal
    def channels_model_changed(self):
        pass

    @Signal
    def __parts_model_changed__(self):
        pass

    @Signal
    def __scenes_model_changed__(self):
        pass

    def channelsModel(self):
        return self.__channels_model__
    channelsModel = Property(QObject, channelsModel, notify=channels_model_changed)

    def partsModel(self):
        return self.__parts_model__
    partsModel = Property(QObject, partsModel, notify=__parts_model_changed__)

    def scenesModel(self):
        return self.__scenes_model__
    scenesModel = Property(QObject, scenesModel, notify=__scenes_model_changed__)

    ### Property sketchesModel
    def get_sketchesModel(self):
        return self.__sketches_model__

    sketchesModelChanged = Signal()

    sketchesModel = Property(QObject, get_sketchesModel, notify=sketchesModelChanged)
    ### END Property sketchesModel

    def isPlaying(self):
        return self.__is_playing__
    isPlaying = Property(bool, notify=__is_playing_changed__)

    # @Slot(None)
    # def addChannel(self):
    #     channel = sketchpad_channel(self.__channels_model__.count, self, self.__channels_model__)
    #     self.__channels_model__.add_channel(channel)
    #     for i in range(0, 2): #TODO: keep numer of parts consistent
    #         clip = sketchpad_clip(channel.id, i, self, channel.clipsModel)
    #         channel.clipsModel.add_clip(clip)
    #         #self.add_clip_to_part(clip, i)
    #     self.schedule_save()

    def setBpmFromTrack(self):
        Zynthbox.SyncTimer.instance().setBpm(self.__bpm__[self.__scenes_model__.selectedSketchpadSongIndex])

    @Slot()
    def setTrackBpmFromCurrent(self):
        bpm = math.floor(Zynthbox.SyncTimer.instance().getBpm())
        if self.__bpm__[self.__scenes_model__.selectedSketchpadSongIndex] != bpm:
            self.__bpm__[self.__scenes_model__.selectedSketchpadSongIndex] = bpm
            self.schedule_save()

    def index(self):
        return self.__index__

    def set_index(self, index):
        self.__index__ = index
        self.index_changed.emit()

    index = Property(int, index, set_index, notify=index_changed)

    ### Property metronomeManager
    def get_metronomeManager(self):
        return self.__metronome_manager__

    metronomeManager = Property(QObject, get_metronomeManager, constant=True)
    ### END Property metronomeManager

    ### Property scaleModel
    def get_scale_model(self):
        return self.__scale_model__
    scaleModel = Property('QVariantList', get_scale_model, constant=True)
    ### END Property scaleModel

    ### Property selectedScaleIndex
    def get_selected_scale_index(self):
        return self.__selected_scale_index__
    def set_selected_scale_index(self, index, force_set=False):
        if self.__selected_scale_index__ != index or force_set is True:
            self.__selected_scale_index__ = index
            self.selected_scale_index_changed.emit()
            self.schedule_save()
    selected_scale_index_changed = Signal()
    selectedScaleIndex = Property(int, get_selected_scale_index, set_selected_scale_index, notify=selected_scale_index_changed)
    ### END Property selectedScaleIndex

    ### Property selectedScale
    def get_selected_scale(self):
        return self.__scale_model__[self.__selected_scale_index__]
    selectedScale = Property(str, get_selected_scale, notify=selected_scale_index_changed)
    ### END Property selectedScale

    ### Property octave
    # The octave is -1 indexed, as we operate with C4 == midi note 60
    # The song's octave can be combined with the scaleIndex to work out what the song's key is as a midi note value:
    # Multiply the octave's value plus one with twelve, and add the scaleIndex, or:
    # (octave + 1) * 12 + scaleIndex
    def get_octave(self):
        return self.__octave__
    def set_octave(self, octave, force_set=False):
        if self.__octave__ != octave or force_set is True:
            self.__octave__ = octave
            if force_set is not True:
                self.octave_changed.emit()
                self.schedule_save()
    octave_changed = Signal()
    octave = Property(int, get_octave, set_octave, notify=octave_changed)
    ### END Property octave

    ### Property sketchpadFolderName
    def get_sketchpad_folder_name(self):
        return Path(self.sketchpad_folder).stem
    sketchpadFolderName = Property(str, get_sketchpad_folder_name, constant=True)
    ### END Property sketchpadFolderName

    ### Property sketchpadFolder
    def get_sketchpad_folder(self):
        return self.sketchpad_folder
    sketchpadFolder = Property(str, get_sketchpad_folder, constant=True)
    ### END Property sketchpadFolder

    ### Property playChannelSolo
    def get_playChannelSolo(self):
        return self.__play_channel_solo

    def set_playChannelSolo(self, value):
        """
        Passthrough client's setMuted change is handled on sketchpad_channel to update the channel muted state. The muted handler on sketchpad_channel
        depends on playChannelSolo property to determine if the current muted state of channel is due to solo mode. Hence, update the playChannelSolo first
        before doing any change to muted state when starting solo mode and when ending solo mode, change value after muted state alteration is done
        TODO : Find a better way to do this later. For now this does the job.
        """
        if self.__play_channel_solo != value:
            valueUpdated = False
            if value > -1:
                self.__play_channel_solo = value
                self.playChannelSoloChanged.emit()
                valueUpdated = True

            for channel_index in range(self.channelsModel.count):
                channel = self.channelsModel.getChannel(channel_index)
                if value == -1:
                    for laneId in range(0, 5):
                        Zynthbox.Plugin.instance().trackPassthroughClients()[channel.id * 5 + laneId].setMuted(channel.muted)
                elif value == channel.id:
                    for laneId in range(0, 5):
                        Zynthbox.Plugin.instance().trackPassthroughClients()[channel.id * 5 + laneId].setMuted(False)
                else:
                    for laneId in range(0, 5):
                        Zynthbox.Plugin.instance().trackPassthroughClients()[channel.id * 5 + laneId].setMuted(True)

            if not valueUpdated:
                self.__play_channel_solo = value
                self.playChannelSoloChanged.emit()

    playChannelSoloChanged = Signal()

    playChannelSolo = Property(int, get_playChannelSolo, set_playChannelSolo, notify=playChannelSoloChanged)
    ### END Property playChannelSolo

    ### Property isLoading
    def get_isLoading(self):
        return self.__is_loading__

    isLoadingChanged = Signal()

    isLoading = Property(bool, get_isLoading, notify=isLoadingChanged)
    ### END Property isLoading

    ### BEGIN Property isSaving
    def get_isSaving(self):
        return self.__is_saving__

    def set_isSaving(self, newIsSaving):
        if self.__is_saving__ != newIsSaving:
            self.__is_saving__ = newIsSaving
            self.isSavingChanged.emit()

    isSavingChanged = Signal()

    isSaving = Property(bool, get_isSaving, notify=isSavingChanged)
    ### END Property isSaving

    ### BEGIN Property hasUnsavedChanges
    def get_hasUnsavedChanges(self):
        return self.__hasUnsavedChanges__

    def set_hasUnsavedChanges(self, val):
        if self.__hasUnsavedChanges__ != val:
            self.__hasUnsavedChanges__ = val
            self.hasUnsavedChangesChanged.emit()

    hasUnsavedChangesChanged = Signal()

    hasUnsavedChanges = Property(bool, get_hasUnsavedChanges, set_hasUnsavedChanges, notify=hasUnsavedChangesChanged)
    ### END Property hasUnsavedChanges

    def stop(self):
        for i in range(0, self.__parts_model__.count):
            part = self.__parts_model__.getPart(i)
            part.stop()
