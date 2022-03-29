#!/usr/bin/python3
# -*- coding: utf-8 -*-
# ******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
#
# Zynthian Synth Categories
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
import logging
import os
import traceback
from pathlib import Path

from PySide2.QtCore import Property, QObject, QSortFilterProxyModel, Qt, Slot

from .sound_categories_sounds_model import sound_categories_sounds_model
from .sounds_model_sound_dto import sounds_model_sound_dto
from .. import zynthian_qt_gui_base


class zynthian_gui_sound_categories(zynthian_qt_gui_base.ZynGui):
    def __init__(self, parent=None):
        super(zynthian_gui_sound_categories, self).__init__(parent)
        self.__sounds_base_path__ = Path('/zynthian/zynthian-my-data/sounds')
        self.__community_sounds_path__ = self.__sounds_base_path__ / 'community-sounds'
        self.__my_sounds_path__ = self.__sounds_base_path__ / 'my-sounds'
        self.__sounds_model__ = sound_categories_sounds_model(self)

        self.__sound_type_filter_proxy_model__ = QSortFilterProxyModel()
        self.__sound_type_filter_proxy_model__.setSourceModel(self.__sounds_model__)
        self.__sound_type_filter_proxy_model__.setFilterRole(sound_categories_sounds_model.Roles.SoundTypeRole)
        self.__sound_type_filter_proxy_model__.setFilterCaseSensitivity(Qt.CaseInsensitive)
        self.__sound_type_filter_proxy_model__.setFilterFixedString("community-sounds")

        self.__sound_category_filter_proxy_model__ = QSortFilterProxyModel()
        self.__sound_category_filter_proxy_model__.setSourceModel(self.__sound_type_filter_proxy_model__)
        self.__sound_category_filter_proxy_model__.setFilterRole(sound_categories_sounds_model.Roles.CategoryRole)
        self.__sound_type_filter_proxy_model__.setFilterCaseSensitivity(Qt.CaseInsensitive)

        self.__my_sounds__ = {
            "1": [],
            "2": [],
            "3": [],
            "99": [],
        }
        self.__community_sounds__ = {
            "1": [],
            "2": [],
            "3": [],
            "99": [],
        }

        self.load_sounds_model()

    def show(self):
        pass

    def zyncoder_read(self):
        pass

    def refresh_loading(self):
        pass

    @Slot()
    def load_sounds_model(self):
        self.__sounds_model__.clear()

        # Create community-sounds categories.json if not exists
        if not (self.__community_sounds_path__ / 'categories.json').exists():
            with open(self.__community_sounds_path__ / 'categories.json', 'w') as f:
                json.dump(self.__community_sounds__, f)
                f.flush()
                os.fsync(f.fileno())

        # Create my-sounds categories.json if not exists
        if not (self.__my_sounds_path__ / 'categories.json').exists():
            with open(self.__my_sounds_path__ / 'categories.json', 'w') as f:
                json.dump(self.__my_sounds__, f)
                f.flush()
                os.fsync(f.fileno())

        try:
            with open(self.__community_sounds_path__ / "categories.json", "r+") as f:
                self.__community_sounds__ = json.load(f)
        except Exception as e:
            logging.error(f"Error while trying to read community sounds metadata : {str(e)}")
            traceback.print_stack()

        try:
            with open(self.__my_sounds_path__ / "categories.json", "r+") as f:
                self.__my_sounds__ = json.load(f)
        except Exception as e:
            logging.error(f"Error while trying to read community sounds metadata : {str(e)}")
            traceback.print_stack()

        # List community-sounds
        for file in self.__community_sounds_path__.glob("**/*.sound"):
            self.__sounds_model__.add_sound(sounds_model_sound_dto(self, file.name, "community-sounds"))

        # List my-sounds
        for file in self.__my_sounds_path__.glob("**/*.sound"):
            self.__sounds_model__.add_sound(sounds_model_sound_dto(self, file.name, "my-sounds"))

    def save_categories(self):
        with open(self.__community_sounds_path__ / 'categories.json', 'w') as f:
            json.dump(self.__community_sounds__, f)
            f.flush()
            os.fsync(f.fileno())

        with open(self.__my_sounds_path__ / 'categories.json', 'w') as f:
            json.dump(self.__my_sounds__, f)
            f.flush()
            os.fsync(f.fileno())

    @Slot(str)
    def setSoundTypeFilter(self, filter):
        self.__sound_type_filter_proxy_model__.setFilterFixedString(filter)

    @Slot(str)
    def setCategoryFilter(self, filter):
        if filter == "*":
            self.__sound_category_filter_proxy_model__.setFilterRegExp("")
        else:
            self.__sound_category_filter_proxy_model__.setFilterFixedString(f"{filter}")

    ### Property soundsModel
    def get_sounds_model(self):
        return self.__sound_category_filter_proxy_model__

    soundsModel = Property(QObject, get_sounds_model, constant=True)
    ### END Property soundsModel
