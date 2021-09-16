from PySide2.QtCore import Property, QObject


class song_arranger_cell(QObject):
    def __init__(self, id, parent=None):
        super(song_arranger_cell, self).__init__(parent)

        self.__id__ = id

    ### Property id
    def get_id(self):
        return self.__id__
    id = Property(int, get_id, constant=True)
    ### END Property id
