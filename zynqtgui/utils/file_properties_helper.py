import logging
import taglib
import tempfile
from subprocess import check_output
import Zynthbox

from PySide2.QtCore import Property, QMimeDatabase, QObject, Signal, Slot
from pathlib import Path
from PySide2.QtGui import QIcon
from PySide2.QtWidgets import QApplication, QStyle
from soundfile import SoundFile


class file_properties_helper(QObject):
    def __init__(self, parent=None):
        super(file_properties_helper, self).__init__(parent)
        self.file_path = None
        self.file_metadata = []
        self.preview_clip = None
        self.is_preview_playing = False

    ### Property filePath
    def get_file_path(self):
        return self.file_path
    def set_file_path(self, path):
        self.file_path = Path(path)
        self.file_path_changed.emit()

        is_wav = self.file_path.name.endswith(".wav")

        if is_wav:
            properties = self.getWavData(self.file_path)
        else:
            properties = []

        file_stat = self.file_path.stat()

        self.file_metadata = {
            "filepath": str(self.file_path),
            "filename": self.file_path.name,
            "size": file_stat.st_size,
            "isWav": is_wav,
            "isDir": self.file_path.is_dir(),
            "isFile": self.file_path.is_file(),
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

    ### Property isPreviewPlaying
    def get_is_preview_playing(self):
        return self.is_preview_playing
    is_preview_playing_changed = Signal()
    isPreviewPlaying = Property(bool, get_is_preview_playing, notify=is_preview_playing_changed)
    ### END Property isPreviewPlaying

    @staticmethod
    def getWavData(path):
        try:
            f = SoundFile(path)
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
                self.preview_clip.deleteLater()
            self.preview_clip = Zynthbox.ClipAudioSource(str(self.file_path), False, self)
            self.preview_clip.setLaneAffinity(1)

            self.preview_clip.play()
            self.is_preview_playing = True
            self.is_preview_playing_changed.emit()

    @Slot(None)
    def stopPreview(self):
        if self.file_metadata is not None and self.file_metadata["isWav"] and self.preview_clip is not None:
            self.preview_clip.stop()
            self.is_preview_playing = False
            self.is_preview_playing_changed.emit()
