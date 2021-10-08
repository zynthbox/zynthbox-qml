import logging

from PySide2.QtCore import Property, QMimeDatabase, QObject, Signal
from pathlib import Path

from PySide2.QtGui import QIcon
from PySide2.QtWidgets import QApplication, QStyle
from soundfile import SoundFile


class file_properties_helper(QObject):
    def __init__(self, parent=None):
        super(file_properties_helper, self).__init__(parent)
        self.file_path = None
        self.file_metadata = []

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
