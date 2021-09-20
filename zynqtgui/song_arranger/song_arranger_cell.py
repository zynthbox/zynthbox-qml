import logging

from PySide2.QtCore import Property, QObject, Signal

from zynqtgui.zynthiloops import zynthian_gui_zynthiloops


class song_arranger_cell(QObject):
    def __init__(self, bar, metronome_manager, track=None):
        super(song_arranger_cell, self).__init__(track)

        self.__bar__ = bar
        self.__zl_clip__ = None
        self.__metronome_manager__: zynthian_gui_zynthiloops = metronome_manager
        self.__is_playing__ = False
        self.__track__ = track

        self.__metronome_manager__.current_bar_changed.connect(self.current_bar_changed_handler)

    ### Property bar
    def get_bar(self):
        return self.__bar__
    bar = Property(int, get_bar, constant=True)
    ### END Property bar

    ### Property zlClip
    def get_zl_clip(self):
        return self.__zl_clip__
    def set_zl_clip(self, clip):
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
        current_bar = self.__metronome_manager__.currentBar
        logging.error(f"Cell Current Bar : {current_bar}")

        if current_bar == self.__bar__:
            if not self.__is_playing__:
                self.__is_playing__ = True
                self.is_playing_changed.emit()
        else:
            if self.__is_playing__:
                self.__is_playing__ = False
                self.is_playing_changed.emit()
