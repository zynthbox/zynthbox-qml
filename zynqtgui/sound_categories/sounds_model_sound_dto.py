#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# A model to store sounds by categories
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
import os
from pathlib import Path

from PySide2.QtCore import Property, QObject, Signal


class sounds_model_sound_dto(QObject):
    def __init__(self, parent, zyngui, name, type, category="0"):
        super().__init__(parent)
        self.__sounds_base_path__ = Path('/zynthian/zynthian-my-data/sounds')
        self.__community_sounds_path__ = self.__sounds_base_path__ / 'community-sounds'
        self.__my_sounds_path__ = self.__sounds_base_path__ / 'my-sounds'

        self.zyngui = zyngui
        self.__name__ = name
        self.__type__ = type

        # Valid category values
        # 0 : Uncategorized
        # 1: Drums
        # 2: Bass
        # 3: Leads
        # 4: Keys/Pads
        # 99: Other
        self.__category__ = category

    ### Property name
    def get_name(self):
        return self.__name__

    name = Property(str, get_name, constant=True)
    ### END Property name

    ### Property type
    def get_type(self):
        return self.__type__

    type = Property(str, get_type, constant=True)
    ### END Property type

    ### Property category
    def get_category(self):
        return self.__category__

    def set_category(self, category):
        if self.__category__ != category:
            self.__category__ = category

            # Update category in sound file
            if self.type == "my-sounds":
                sound_file = self.__my_sounds_path__ / self.name
            elif self.type == "community-sounds":
                sound_file = self.__community_sounds_path__ / self.name

            if sound_file is not None:
                with open(sound_file, "r+") as file:
                    sound_json = json.load(file)
                    file.seek(0)

                    if category in ["0", "*"]:
                        del sound_json["category"]
                    else:
                        sound_json["category"] = category

                    json.dump(sound_json, file)
                    file.truncate()
                    file.flush()
                    os.fsync(file.fileno())

            # Notify model about updated item
            self.zyngui.sound_categories.__sounds_model__.emit_category_updated(self)
            self.category_changed.emit()

    category_changed = Signal()

    category = Property(str, get_category, set_category, notify=category_changed)
    ### END Property category

    ### Property path
    def get_path(self):
        if self.__type__ == "community-sounds":
            return "/zynthian/zynthian-my-data/sounds/community-sounds/"+self.__name__
        elif self.__type__ == "my-sounds":
            return "/zynthian/zynthian-my-data/sounds/my-sounds/"+self.__name__
        else:
            return None

    path = Property(str, get_path, constant=True)
    ### END Property path