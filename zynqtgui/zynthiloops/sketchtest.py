# This Python file uses the following encoding: utf-8
import ctypes
import os
from os.path import dirname, realpath
import sys
import math

#sys.path.insert(1, "./libzl")

from PySide2.QtCore import Property, QObject, Signal, Slot
from PySide2.QtGui import QGuiApplication
from PySide2.QtQml import QQmlApplicationEngine, qmlRegisterType

from libzl import libzl
from libzl import zynthiloops_song

@ctypes.CFUNCTYPE(None)
def cb():
    metronome_manager.__instance__.metronome_update()

class metronome_manager(QObject):
    __instance__ = None

    def __init__(self, parent: QObject = None):
        super(metronome_manager, self).__init__(parent)
        metronome_manager.__instance__ = self
        self.__metronome_running_refcount = 0
        self.__bpm__ = 120
        self.__current_beat__ = 0
        libzl.registerTimerCallback(cb)

    def current_beat_changed(self):
        pass

    @Signal
    def metronome_running_changed(self):
        pass


    @Signal
    def current_beat_changed(self):
        pass

    @Signal
    def metronome_running_changed(self):
        pass

    def start_metronome_request(self):
        self.__metronome_running_refcount += 1

        if self.__metronome_running_refcount == 1:
            libzl.startTimer(math.floor((60.0 / self.__bpm__) * 1000))
            self.metronome_running_changed.emit()


    def stop_metronome_request(self):
        self.__metronome_running_refcount = max(self.__metronome_running_refcount - 1, 0)

        if self.__metronome_running_refcount == 0:
            libzl.stopTimer()
            self.metronome_running_changed.emit()

            self.__current_beat__ = 0
            self.current_beat_changed.emit()

    def metronome_update(self):
        print("metronome update")
        self.__current_beat__ = (self.__current_beat__ + 1) % 4
        self.current_beat_changed.emit()


class song_manager(QObject):
    def __init__(self, parent: QObject = None):
        super(song_manager, self).__init__(parent)
        self.__metronome__ = metronome_manager()
        self.__song__ = zynthiloops_song.zynthiloops_song("/home/diau/", self.__metronome__)

    @Signal
    def song_changed(self):
        pass

    def song(self):
        return self.__song__
    song = Property(QObject, song, notify=song_changed)

    @Slot(None)
    def clearSong(self):
        self.__song__.destroy()
        self.__song__ = zynthiloops_song.zynthiloops_song("/home/diau/", self.__metronome__)
        self.song_changed.emit()


if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()
    libzl.init()
    libzl.registerGraphicTypes()

    song_man = song_manager()

    engine.rootContext().setContextProperty("songManager", song_man)
    engine.load(os.fspath(dirname(realpath(__file__)) + "/sketchtest.qml"))

    if not engine.rootObjects():
        sys.exit(-1)
    sys.exit(app.exec_())
