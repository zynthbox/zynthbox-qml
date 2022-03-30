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
        self.__sound_category_filter_proxy_model__.setFilterCaseSensitivity(Qt.CaseInsensitive)

        # Valid Sound category IDs
        # 1: Drums
        # 2: Bass
        # 3: Leads
        # 4: Keys/Pads
        # 99: Other
        self.__my_sounds__ = {
            "1": [],
            "2": [],
            "3": [],
            "4": [],
            "99": [],
        }
        self.__community_sounds__ = {
            "1": [],
            "2": [],
            "3": [],
            "4": [],
            "99": [],
        }

        self.load_sounds_model()

    def show(self):
        pass

    def zyncoder_read(self):
        pass

    def refresh_loading(self):
        pass

    def move_sound_category(self, sound, toCategory):
        if sound.type == "community-sounds":
            try:
                self.__community_sounds__[sound.category].remove(sound.name)
            except: pass

            try:
                self.__community_sounds__[toCategory].append(sound.name)
            except: pass

        elif sound.type == "my-sounds":
            try:
                self.__my_sounds__[sound.category].remove(sound.name)
            except: pass

            try:
                self.__my_sounds__[toCategory].append(sound.name)
            except: pass

        self.save_categories()
        self.load_sounds_model()

    # Returns the category index if found otherwise returns 0 for uncategorized entries
    def get_category_for_sound(self, _sound, _type):
        if _type == "community-sounds":
            source_categories = self.__community_sounds__
        elif _type == "my-sounds":
            source_categories = self.__my_sounds__
        else:
            source_categories = {}

        for category, sounds in source_categories.items():
            if _sound in sounds:
                return category

        return 0

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

        # Read community-sounds categories
        try:
            with open(self.__community_sounds_path__ / "categories.json", "r+") as f:
                self.__community_sounds__ = json.load(f)
        except Exception as e:
            logging.error(f"Error while trying to read community sounds metadata : {str(e)}")
            traceback.print_stack()

        # Read my-sounds categories
        try:
            with open(self.__my_sounds_path__ / "categories.json", "r+") as f:
                self.__my_sounds__ = json.load(f)
        except Exception as e:
            logging.error(f"Error while trying to read community sounds metadata : {str(e)}")
            traceback.print_stack()

        # Fill community-sounds list
        for file in self.__community_sounds_path__.glob("**/*.sound"):
            self.__sounds_model__.add_sound(
                sounds_model_sound_dto(
                    self,
                    self.zyngui,
                    file.name,
                    "community-sounds",
                    self.get_category_for_sound(file.name, "community-sounds")
                )
            )

        # Fill my-sounds list
        for file in self.__my_sounds_path__.glob("**/*.sound"):
            self.__sounds_model__.add_sound(
                sounds_model_sound_dto(
                    self,
                    self.zyngui,
                    file.name,
                    "my-sounds",
                    self.get_category_for_sound(file.name, "my-sounds")
                )
            )

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
    def setSoundTypeFilter(self, _filter):
        self.__sound_type_filter_proxy_model__.setFilterFixedString(_filter)

    @Slot(str)
    def setCategoryFilter(self, _filter):
        # If qml sends category filter as `*`, clear any filtering and display all sounds
        if _filter == "*":
            self.__sound_category_filter_proxy_model__.setFilterRegExp("")
        else:
            self.__sound_category_filter_proxy_model__.setFilterFixedString(f"{_filter}")

    ### Property soundsModel
    def get_sounds_model(self):
        return self.__sound_category_filter_proxy_model__

    soundsModel = Property(QObject, get_sounds_model, constant=True)
    ### END Property soundsModel
