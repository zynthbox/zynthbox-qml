import logging
import taglib
import tempfile
import os
import os.path
from subprocess import check_output
import Zynthbox

from PySide2.QtCore import Property, QMimeDatabase, QObject, Signal, Slot
from pathlib import Path
from PySide2.QtGui import QIcon
from PySide2.QtWidgets import QApplication, QStyle
from soundfile import SoundFile

# Function by Fred Cirera - https://web.archive.org/web/20111010015624/http://blogmag.net/blog/read/38/Print_human_readable_file_size
def sizeof_fmt(num, suffix="B"):
    for unit in ("", "Ki", "Mi", "Gi", "Ti", "Pi", "Ei", "Zi"):
        if abs(num) < 1024.0:
            return f"{num:3.1f}{unit}{suffix}"
        num /= 1024.0
    return f"{num:.1f}Yi{suffix}"

class file_properties_helper(QObject):
    def __init__(self, parent=None):
        super(file_properties_helper, self).__init__(parent)
        self.file_path = None
        self.file_metadata = []
        self.preview_clip = None
        self.is_preview_playing = False
        self.__user_folders = [Path("/zynthian/zynthian-my-data/sketches/my-sketches"), Path("/zynthian/zynthian-my-data/samples/my-samples"), Path("/zynthian/zynthian-my-data/sketchpads/my-sketchpads")]

    ### Property filePath
    def get_file_path(self):
        return str(self.file_path)
    def set_file_path(self, path):
        newPath = Path(path)
        if self.file_path != newPath:
            self.file_path = newPath
            self.file_path_changed.emit()

            is_wav = self.file_path.name.endswith(".wav")

            is_sketch = False
            if is_wav:
                properties = self.getWavData(self.file_path)
                is_sketch = "zynthbox" in properties
            else:
                properties = []

            file_stat = self.file_path.stat()

            is_read_write = False
            # If the a file or directory is in one of our user-folders (the ones called something with "my-"), then we define them as read-write
            for testPath in self.__user_folders:
                if testPath != self.file_path and self.file_path.is_relative_to(testPath):
                    is_read_write = True
                    break

            self.file_metadata = {
                "filepath": str(self.file_path),
                "filename": self.file_path.name,
                "size": file_stat.st_size,
                "humanSize": sizeof_fmt(file_stat.st_size),
                "isWav": is_wav,
                "isSketch": is_sketch,
                "isDir": self.file_path.is_dir(),
                "isFile": self.file_path.is_file(),
                "isReadWrite": is_read_write,
                "properties": properties
            }
            self.file_metadata_changed.emit()
    file_path_changed = Signal()
    filePath = Property(str, get_file_path, set_file_path, notify=file_path_changed)
    ### END Property filePath

    ### Property fileMetadata
    def get_file_metadata(self):
        return self.file_metadata
    file_metadata_changed = Signal()
    fileMetadata = Property('QVariantMap', get_file_metadata, notify=file_metadata_changed)
    ### END Property fileMetadata

    ### BEGIN A bunch of helper functions that only really require a container object, and this is a file operations related one, so they can go here
    @Slot(str, result=bool)
    def checkFileExists(self, pathname):
        if Path(pathname).exists():
            return True
        return False

    @Slot(str, str)
    def renameFile(self, oldPathname, newPathname):
        fileToRename = Path(oldPathname)
        if fileToRename.exists():
            fileToRename.rename(newPathname)

    @Slot(str, result=bool)
    def directoryHasContents(self, pathname):
        directory = Path(pathname)
        if directory.is_dir():
            if any(directory.iterdir()):
                return True
        return False

    @Slot(str)
    def deleteFile(self, pathname):
        fileToDelete = Path(pathname)
        if fileToDelete.exists():
            if fileToDelete.is_dir():
                fileToDelete.rmdir()
            else:
                fileToDelete.unlink()

    @Slot(str)
    def makePath(self, pathname):
        pathToCreate = Path(pathname)
        pathToCreate.mkdir(parents=True, exist_ok=True)

    # Returns an ordered list of subdirectories for the given pathname, containing objects with the keys path, subpath and name
    # path contains the fill file system path of the entry
    # subpath contains the last part of the path, including the search path's last directory, including the /
    # name contains only the entry's directory name
    @Slot(str, result='QVariantList')
    def getSubdirectoryList(self, pathname):
        subdirectories = []
        pathStringLength = pathname.rfind("/")
        for dirpath, dirnames, filenames in os.walk(pathname, onerror=print, followlinks=False):
            subdirectories.append({"path": dirpath, "subpath": dirpath[pathStringLength:], "name": dirpath.split('/')[-1]})
        return subdirectories

    # Returns an ordered list of subdirectories for the given pathname, containing objects with the keys path, subpath, and name
    # The list does not include the given path itself, only subdirectories
    # path contains the fill file system path of the entry
    # subpath contains the last part of the path, *excluding* the search path's last directory
    # name contains only the entry's directory name
    @Slot(str, result='QVariantList')
    def getOnlySubdirectoryList(self, pathname):
        subdirectories = []
        pathStringLength = len(pathname + "/")
        afterFirstDir = False # As we want to exclude the given path, skip the first entry (which when using os.walk will always be that one)
        for dirpath, dirnames, filenames in os.walk(pathname, onerror=print, followlinks=False):
            if afterFirstDir:
                subdirectories.append({"path": dirpath, "subpath": dirpath[pathStringLength:], "name": dirpath.split('/')[-1]})
            afterFirstDir = True
        return subdirectories

    # Returns an ordered list of subdirectories for the given paths, containing objects with the keys path, subpath, and name
    # This is equivalent to simply calling getOnlySubdirectoryList on all entries in the paths list and concatenating the resulting lists
    @Slot('QVariantList', result='QVariantList')
    def getOnlySubdirectoriesList(self, paths):
        subdirectories = []
        if isinstance(paths, list):
            for path in paths:
                subdirectories.extend(self.getOnlySubdirectoryList(path))
        return subdirectories

    @Slot(str, 'QVariantMap')
    def writeMetadata(self, filename, values: dict):
        # for key, value in values.items():
            # logging.info(f"Writing metadata to {filename} : {key} -> {value}")
        if filename is not None:
            try:
                file = taglib.File(filename)
                for key, value in values.items():
                    file.tags[key] = [str(value)]
                file.save()
            except Exception as e:
                logging.error(f"Error writing metadata : {str(e)}")
                logging.info(f"Trying to create a new file without metadata")

                try:
                    with tempfile.TemporaryDirectory() as tmp:
                        logging.info("Creating new temp file without metadata")
                        logging.debug(f"ffmpeg -i {filename} -codec copy {Path(tmp) / 'output.wav'}")
                        check_output(f"ffmpeg -i {filename} -codec copy {Path(tmp) / 'output.wav'}", shell=True)

                        logging.info("Replacing old file")
                        logging.debug(f"mv {Path(tmp) / 'output.wav'} {filename}")
                        check_output(f"mv {Path(tmp) / 'output.wav'} {filename}", shell=True)

                        file = taglib.File(filename)
                        for key, value in values.items():
                            file.tags[key] = [str(value)]
                        file.save()
                except Exception as e:
                    logging.error(f"Error creating new file and writing metadata : {str(e)}")

    ### END A bunch of helper functions that only really require a container object, and this is a file operations related one, so they can go here

    ### Property isPreviewPlaying
    def get_is_preview_playing(self):
        return self.is_preview_playing
    is_preview_playing_changed = Signal()
    isPreviewPlaying = Property(bool, get_is_preview_playing, notify=is_preview_playing_changed)
    ### END Property isPreviewPlaying


    @staticmethod
    def getWavData(path):
        def getMetadataProperty(metadata, name, default=None):
            try:
                value = metadata[name][0]
                if value == "None":
                    # If 'None' value is saved, return default
                    return default
                return value
            except:
                return default
        try:
            f = SoundFile(path)
            try:
                file = taglib.File(path)
                metadata = file.tags
                file.close()
            except Exception as e:
                metadata = {}
            if "ZYNTHBOX_BPM" in metadata:
                snapshot = getMetadataProperty(metadata, "ZYNTHBOX_SOUND_SNAPSHOT", None)
                soundDescriptions = []
                if snapshot is not None:
                    # This is so we don't have to import the layers code from parent, but... maybe we want to, or it wants to live elsewhere, or... something
                    try:
                        data = []
                        layers = JSONDecoder().decode(snapshot)
                        for layer_data in layers["layers"]:
                            layer_snapshot = self.zynqtgui.zynthbox_plugins_helper.update_layer_snapshot_plugin_id_to_name(layer_data)
                            #if not layer_snapshot["midi_chan"] in data:
                                #data[layer_snapshot["midi_chan"]] = []
                            item = {"name": layer_snapshot["engine_name"].split("/")[-1]}
                            if "midi_chan" in layer_snapshot:
                                item["midi_chan"] = layer_snapshot["midi_chan"]
                            else:
                                item["midi_chan"] = -1
                            if "slot_index" in layer_snapshot:
                                item["slot_index"] = layer_snapshot["slot_index"]
                            if "bank_name" in layer_snapshot:
                                item["bank_name"] = layer_snapshot["bank_name"]
                            if "preset_name" in layer_snapshot:
                                item["preset_name"] = layer_snapshot["preset_name"]
                            if "engine_type" in layer_snapshot:
                                item["engine_type"] = layer_snapshot["engine_type"]
                            data.append(item)
                        for entry in data:
                            if entry["name"] != "":
                                soundDescriptions.append(f"{entry['name']} ({entry['preset_name']})")
                    except Exception as e:
                        logging.error(e)
                return {
                    "frames": f.frames,
                    "sampleRate": f.samplerate,
                    "channels": f.channels,
                    "duration": f.frames/f.samplerate,
                    "zynthbox": {
                        "bpm": getMetadataProperty(metadata, "ZYNTHBOX_BPM", 0),
                        "playbackStyle": getMetadataProperty(metadata, "ZYNTHBOX_PLAYBACK_STYLE", "LoopingPlaybackStyle").split(".")[-1],
                        "soundDescriptions": soundDescriptions
                    }
                }
            else:
                return {
                    "frames": f.frames,
                    "sampleRate": f.samplerate,
                    "channels": f.channels,
                    "duration": f.frames/f.samplerate
                }
        except:
            return []

    @Slot(None)
    def playPreview(self):
        if self.file_metadata is not None and self.file_metadata["isWav"]:
            if self.preview_clip is not None:
                self.preview_clip.stop()
                if self.preview_clip.getFilePath() != str(self.file_path):
                    self.preview_clip.deleteLater()
                    self.preview_clip = None
            if self.preview_clip is None:
                self.preview_clip = Zynthbox.ClipAudioSource(str(self.file_path), -1, 0, False, False, self)
                self.preview_clip.setLaneAffinity(0)
                self.preview_clip_changed.emit()

            self.preview_clip.play(False)
            self.is_preview_playing = True
            self.is_preview_playing_changed.emit()

    @Slot(None)
    def stopPreview(self):
        if self.file_metadata is not None and self.file_metadata["isWav"] and self.preview_clip is not None:
            self.preview_clip.stop()
            self.is_preview_playing = False
            self.is_preview_playing_changed.emit()

    # BEGIN Property previewClip
    def get_preview_clip(self):
        return self.preview_clip
    preview_clip_changed = Signal()
    previewClip = Property(QObject, get_preview_clip, notify=preview_clip_changed)
    # END Property previewClip
