from PySide2.QtCore import Property, QObject, Signal


class song_arranger_cell(QObject):
    def __init__(self, id, parent=None):
        super(song_arranger_cell, self).__init__(parent)

        self.__id__ = id
        self.__zl_clip__ = None

    ### Property id
    def get_id(self):
        return self.__id__
    id = Property(int, get_id, constant=True)
    ### END Property id

    ### Property zlClip
    def get_zl_clip(self):
        return self.__zl_clip__
    def set_zl_clip(self, clip):
        self.__zl_clip__ = clip
        self.zl_clip_changed.emit()
    zl_clip_changed = Signal()
    zlClip = Property(QObject, get_zl_clip, set_zl_clip, notify=zl_clip_changed)
    ### END Property zlClip
