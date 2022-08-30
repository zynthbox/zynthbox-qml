import logging

from PySide2.QtCore import Property, QObject, Signal

from zynqtgui.zynthiloops import zynthian_gui_zynthiloops
from zynqtgui.zynthiloops.libzl.zynthiloops_clip import zynthiloops_clip


class song_arranger_cell(QObject):
    def __init__(self, bar, metronome_manager, channel, arranger):
        super(song_arranger_cell, self).__init__(channel)

        self.__bar__ = bar
        self.__zl_clip__: zynthiloops_clip = None
        self.__metronome_manager__: zynthian_gui_zynthiloops = metronome_manager
        self.__is_playing__ = False
        self.__channel__ = channel
        self.__arranger__ = arranger

        self.__metronome_manager__.current_bar_changed.connect(self.current_bar_changed_handler)

    ### Property bar
    def get_bar(self):
        return self.__bar__
    bar = Property(int, get_bar, constant=True)
    ### END Property bar

    ### Property zlClip
    def get_zl_clip(self):
        return self.__zl_clip__
    def set_zl_clip(self, clip: zynthiloops_clip):
        if clip is not None:
            clip.add_arranger_bar_position(self.__bar__)
        else:
            self.__zl_clip__.remove_arranger_bar_position(self.__bar__)

        self.__zl_clip__ = clip
        self.zl_clip_changed.emit()
    zl_clip_changed = Signal()
    zlClip = Property(QObject, get_zl_clip, set_zl_clip, notify=zl_clip_changed)
    ### END Property zlClip

    ### Property isPlaying
    def get_is_playing(self):
        return self.__is_playing__
    is_playing_changed = Signal()
    isPlaying = Property(bool, get_is_playing, notify=is_playing_changed)
    ### END Property isPlaying

    def current_bar_changed_handler(self):
        if self.__arranger__ is not None and self.__arranger__.isPlaying:
            current_bar = self.__metronome_manager__.currentBar + self.__arranger__.startFromBar

            if current_bar == self.__bar__:
                if not self.__is_playing__:
                    if self.__zl_clip__ is not None:
                        self.__zl_clip__.play_audio(False)
                    self.__is_playing__ = True
                    self.is_playing_changed.emit()
            else:
                if self.__is_playing__:
                    self.__is_playing__ = False
                    self.is_playing_changed.emit()
        else:
            self.__is_playing__ = False
            self.is_playing_changed.emit()

    def destroy(self):
        self.__metronome_manager__.current_bar_changed.disconnect(self.current_bar_changed_handler)
        self.deleteLater()
