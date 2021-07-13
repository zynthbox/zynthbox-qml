/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Main Class and Program for Zynthian GUI

Copyright (C) 2021 Marco Martin <mart@kde.org>

******************************************************************************

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 2 of
the License, or any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

For a full copy of the GNU General Public License see the LICENSE.txt file.

******************************************************************************
*/

import QtQuick 2.11
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Window 2.1
import org.kde.kirigami 2.6 as Kirigami

import "components" as ZComponents
import "pages" as Pages

QtObject {
	id: root
	function pageForScreen(screen) {
		if (screen in screens) {
			return Qt.resolvedUrl("./pages/" + screens[screen]);
		} else {
			return "";
		}
	}

	function pageForModalScreen(screen) {
		if (screen in modalScreens) {
			return Qt.resolvedUrl("./pages/" + modalScreens[screen]);
		} else {
			return "";
		}
	}

	readonly property var screens: {
		"main": "MainPage.qml",
		"layer": "SynthSetupPage.qml",
		"bank": "SynthSetupPage.qml",
		"preset": "SynthSetupPage.qml",
		"control": "ControlPage.qml"
	}

	readonly property var modalScreens: {
		"engine": "EnginePage.qml",
		"midi_chan": "MidiChanPage.qml",
		"layer_options": "LayerOptionsPage.qml",
		"snapshot": "SnapshotPage.qml",
		"audio_recorder": "AudioRecorderPage.qml",
		"midi_recorder": "MidiRecorderPage.qml",
		"admin": "AdminPage.qml",
		"info": "InfoPage.qml",
	}
}
