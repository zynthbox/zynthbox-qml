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

import Zynthian 1.0 as Zynthian
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

    function pageForDashboardScreen(screen) {
        if (screen in dashboardScreens) {
            return Qt.resolvedUrl("./pages/" + dashboardScreens[screen]);
        } else {
            return "";
        }
    }



    readonly property var screens: {
        "layer": "SynthSetupPage.qml",
        "fixed_layers": "SynthSetupPage.qml",
        "main_layers_view": "SynthSetupPage.qml",
        "layers_for_track": "SynthSetupPage.qml",
        "bank": "SynthSetupPage.qml",
        "preset": "SynthSetupPage.qml",
        "control": "ControlPage.qml",
        "layer_effects": "FXSetupPage.qml",
        "effect_types": "FXSetupPage.qml",
        "layer_effect_chooser": "FXSetupPage.qml",
        "layer_midi_effects": "MidiFXSetupPage.qml",
        "midi_effect_types": "MidiFXSetupPage.qml",
    }

    readonly property var modalScreens: {
        "session_dashboard": "SessionDashboard/Main.qml",
        "midi_key_range": "MidiKeyRangePage.qml",
        "engine": "EnginePage.qml",
        "midi_chan": "MidiChanPage.qml",
        "layer_options": "LayerOptionsPage.qml",
        "snapshot": "SnapshotPage.qml",
        "audio_in": "AudioInPage.qml",
        "audio_out": "AudioOutPage.qml",
        "audio_recorder": "AudioRecorderPage.qml",
        "midi_recorder": "MidiRecorderPage.qml",
        "admin": "AdminPage.qml",
        "about": "AboutPage.qml",
        "info": "InfoPage.qml",
        "option": "OptionPage.qml",
        "theme_chooser": "ThemePage.qml",
        "theme_downloader": "ThemeDownloaderPage.qml",
        "module_downloader": "ModuleDownloaderPage.qml",
        "norns_shield": "NornsPage.qml",
        "test_touchpoints": "TestTouchpoints.qml",
        "audio_settings":"AudioSettingsPage.qml",
        "synth_behaviour":"SynthBehaviourPage.qml",
        "snapshots_menu":"SnapshotsMenuPage.qml",
        "network":"NetworkPage.qml",
        "hardware":"HardwarePage.qml",
        "playgrid": "PlayGrid.qml",
        "playgrid_downloader": "PlayGridDownloaderPage.qml",
        "track": "TrackPage.qml",
        "song_arranger": "SongArranger/main.qml",
        "sketch_copier": "SketchCopier/main.qml",
        "sound_downloader": "SoundDownloaderPage.qml",
        "soundfont_downloader": "SoundfontDownloaderPage.qml",
        "soundset_downloader": "SoundsetsDownloaderPage.qml",
        "control_downloader": "ControlDownloaderPage.qml",
        "fx_control_downloader": "FXControlDownloaderPage.qml",
        "sequence_downloader": "SequenceDownloaderPage.qml",
        "sketch_downloader": "SketchDownloaderPage.qml",
        "network_info": "NetworkInfoPage.qml",
        "guioptions" : "GuiOptionsPage.qml",
        "sound_categories": "SoundCategories/Main.qml",
        "wifi_settings":"WifiSettingsPage.qml"
    }

    readonly property var dashboardScreens: {
        "main": "MainPage.qml",
        "zynthiloops": "ZynthiLoops/Main.qml",
    }
}
