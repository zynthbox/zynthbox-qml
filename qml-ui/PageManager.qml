import QtQuick 2.11
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami

import Zynthian 1.0 as Zynthian

Zynthian.Stack {
    id: root
    
    // Any new screen should be added here for PageManager to find and load page
    readonly property var pageScreenMapping: {
        "sketchpad": "Sketchpad/Main.qml",
        "main": "MainPage.qml",
        "layer": "SynthSetupPage.qml",
        "fixed_layers": "SynthSetupPage.qml",
        "main_layers_view": "SynthSetupPage.qml",
        "layers_for_channel": "SynthSetupPage.qml",
        "bank": "SynthSetupPage.qml",
        "preset": "SynthSetupPage.qml",
        "control": "ControlPage.qml",
        "layer_effects": "FXSetupPage.qml",
        "effect_types": "FXSetupPage.qml",
        "layer_effect_chooser": "FXSetupPage.qml",
        "layer_midi_effects": "MidiFXSetupPage.qml",
        "midi_effect_types": "MidiFXSetupPage.qml",
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
        "channel": "ChannelPage.qml",
        "channel_external_setup": "ChannelExternalSetup.qml",
        "channel_wave_editor": "ChannelWaveEditor.qml",
        "song_arranger": "SongArranger/main.qml",
        "song_player": "SongPlayerPage.qml",
        "song_manager": "SongManagerPage.qml",
        "sketchpad_copier": "SketchpadCopier/main.qml",
        "sample_downloader": "SampleDownloaderPage.qml",
        "sound_downloader": "SoundDownloaderPage.qml",
        "soundfont_downloader": "SoundfontDownloaderPage.qml",
        "soundset_downloader": "SoundsetsDownloaderPage.qml",
        "control_downloader": "ControlDownloaderPage.qml",
        "fx_control_downloader": "FXControlDownloaderPage.qml",
        "sequence_downloader": "SequenceDownloaderPage.qml",
        "sketchpad_downloader": "SketchpadDownloaderPage.qml",
        "network_info": "NetworkInfoPage.qml",
        "guioptions" : "GuiOptionsPage.qml",
        "sound_categories": "SoundCategories/Main.qml",
        "wifi_settings":"WifiSettingsPage.qml",
        "test_knobs":"TestKnobsPage.qml"
    }
    
    property var currentPage: ""
    property var pageCache: ({})
    
    // Get absolute url of page file by page name
    function pageResolvedUrl(page) {
        return Qt.resolvedUrl("./pages/" + root.pageScreenMapping[page])
    }
    
    // Instantiates and returns a new page object
    function createPageObject(page) {
        // zynthian.currentTaskMessage = "Loading " + page + " page"

        console.log("Caching page :", pageResolvedUrl(page))

        var component = Qt.createComponent(pageResolvedUrl(page));
        var obj = component.createObject(applicationWindow(), {"width": root.width, "height": root.height, visible: false})
        if (component.errorString() != "") {
            console.log("Error caching page", pageResolvedUrl(page), ":", component.errorString());
        } else {
            console.log("Page cached :", pageResolvedUrl(page))
        }

        return obj
    }
    
    // Get page instance
    // This method checks if page exists in cache. If not found in cache then the object is cached
    function getPage(page) {
        // Point all library pages to layers_for_channel cache
        if (["layer", "fixed_layers", "main_layers_view", "layers_for_channel", "bank", "preset"].indexOf(page) >= 0) {
            console.log("Page", page, "is a library page. Using layers_for_channel cache")
            page = "layers_for_channel"
        }

        if (root.pageCache[page] != null) {
            console.log("Page cache found for page :", pageResolvedUrl(page))
            return root.pageCache[page]
        } else {
            console.log("Page cache not found for page :", pageResolvedUrl(page))
            root.pageCache[page] = createPageObject(page)
            return root.pageCache[page]
        }

    }

    Component.onCompleted: {
        // Cache all the main pages when starting up
        root.pageCache["main"] = createPageObject("main")
        root.pageCache["control"] = createPageObject("control")
        root.pageCache["layers_for_channel"] = createPageObject("layers_for_channel")
        root.pageCache["playgrid"] = createPageObject("playgrid")
        root.pageCache["midi_key_range"] = createPageObject("midi_key_range")
        root.pageCache["sound_categories"] = createPageObject("sound_categories")
        root.pageCache["engine"] = createPageObject("engine")
        root.pageCache["song_manager"] = createPageObject("song_manager")
        root.pageCache["channel_wave_editor"] = createPageObject("channel_wave_editor")
        root.pageCache["sketchpad"] = createPageObject("sketchpad")

        // Display initial page 
        zynthian.show_modal("sketchpad")
    }

    background: Rectangle {
        color: Kirigami.Theme.backgroundColor
    }

    Connections {
        target: zynthian
        onCurrent_screen_idChanged: handlePageChange(zynthian.current_screen_id)
        onCurrent_modal_screen_idChanged: handlePageChange(zynthian.current_screen_id)

        function handlePageChange(page) {
            if (page != "" && root.currentPage != page) {
                root.currentPage = page
                console.log("Changing page to", page)
                
                if (zynthian.current_modal_screen_id === "confirm") {
                    // Confirm page is not a seperate page. Show confirm dialog if confirm page is requested
                    applicationWindow().showConfirmationDialog()
                } else {
                    if (root.currentItem) {
                        root.currentItem.visible = false
                    }
                    root.replace(root.getPage(page))
                    root.currentItem.visible = true
                }
            }
        }
    }
}
