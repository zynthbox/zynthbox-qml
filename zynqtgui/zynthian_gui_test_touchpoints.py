#!/usr/bin/python3
# -*- coding: utf-8 -*-
#******************************************************************************
# ZYNTHIAN PROJECT: Zynthian GUI
# 
# Zynthian Test Touchpoints: A Test page to test multi
# 
# Copyright (C) 2021 Anupam Basak <anupam.basak27@gmail.com>
#
#******************************************************************************
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
#******************************************************************************

from . import zynthian_qt_gui_base


class zynthian_gui_test_touchpoints(zynthian_qt_gui_base.zynqtgui):
  def __init__(self, parent = None):
    super(zynthian_gui_test_touchpoints, self).__init__(parent)

  def show(self):
    pass

  def zyncoder_read(self):
    pass

  def refresh_loading(self):
    pass