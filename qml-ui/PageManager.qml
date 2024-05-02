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
        "effect_preset": "FXSetupPage.qml",
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
        "song_manager": "SongManagerPage.qml",
        "sketchpad_copier": "SketchpadCopier/main.qml",
        "sketch_downloader": "SketchDownloaderPage.qml",
        "sound_downloader": "SoundDownloaderPage.qml",
        "soundfont_downloader": "SoundfontDownloaderPage.qml",
        "soundset_downloader": "SoundsetsDownloaderPage.qml",
        "control_downloader": "ControlDownloaderPage.qml",
        "fx_control_downloader": "FXControlDownloaderPage.qml",
        "sequence_downloader": "SequenceDownloaderPage.qml",
        "sketchpad_downloader": "SketchpadDownloaderPage.qml",
        "network_info": "NetworkInfoPage.qml",
        "sound_categories": "SoundCategories/Main.qml",
        "wifi_settings":"WifiSettingsPage.qml",
        "test_knobs":"TestKnobsPage.qml"
    }
    readonly property var pageDisplayNames: {
        "main": "Main Menu",
        "control": "Synth Edit",
        "layers_for_channel": "Library",
        "layer_effects": "FX Library",
        "layer_midi_effects": "MidiFX Library",
        "playgrid": "Playgrid",
        "sound_categories": "Sound Categories",
        "engine": "Synths",
        "song_manager": "Song Manager",
        "channel_wave_editor": "Audio Editor",
        "sketchpad": "Sketchpad"
    }

    // List of pages that will be cached on start
    property var pagesToCache: [
        "playgrid",
        "sketchpad",
        "main",
        "control",
        "layers_for_channel",
        "layer_effects",
        "layer_midi_effects",
        "sound_categories",
        "engine",
        "song_manager"
    ]
    property string currentPage: ""
    property var pageCache: ({})

    // Function to get display name of page
    function getPageDisplayName(page) {
        if (root.pageDisplayNames[page] != null) {
            return root.pageDisplayNames[page]
        } else {
            // If display name is not found, generate a display name by replacing all _ with " " and capitalizing first letter of each word
            return page
                    .replace(/_/g, " ")
                    .replace(/\b[a-z]/g, function(letter) { return letter.toUpperCase() })
        }
    }

    // Get absolute url of page file by page name
    function pageResolvedUrl(page) {
        return Qt.resolvedUrl("./pages/" + root.pageScreenMapping[page])
    }

    property string switchToPageAfterCacheCreation: ""
    property int remainingPagesForCreation: 0
    onRemainingPagesForCreationChanged: {
        if (remainingPagesForCreation === 0) {
            // We are done! (at least with the current batch) Let's spit out some statistics
            console.log("------------------------------------------------------------------------")
            console.log("PAGE CACHE SUMMARY")
            console.log("------------------------------------------------------------------------")
            for (let page in root.pageCache) {
                let cache = root.pageCache[page]
                console.log(`${page.padEnd(20)} ${("("+cache.url+")").padEnd(70)} ${cache.errorString == "" ? "SUCCESS" : "ERRORED " + cache.errorString} : ${(""+cache.ttl).padStart(4)} ms`)
            }
            console.log("------------------------------------------------------------------------")

            if (switchToPageAfterCacheCreation !== "") {
                pageChangeHandler.handlePageChange(root.switchToPageAfterCacheCreation);
                root.switchToPageAfterCacheCreation = "";
            }
            zynqtgui.currentTaskMessage = "Loaded Core UI"

            // And finally, hide the splash now that the caching process has been completed
            zynqtgui.stop_splash();
        } else {
            zynqtgui.currentTaskMessage = "Loading Core UI: %1\%".arg(100 - Math.floor(100 * root.remainingPagesForCreation / root.pagesToCache.length));
        }
    }
    function handlePageCreation(page, incubator) {
        root.pageCache[page].ttl = Date.now() - root.pageCache[page].creationStartedTime;
        if (incubator && incubator.status === Component.Ready) {
            root.pageCache[page].pageObject = incubator.object;
        } else {
            root.pageCache[page].errorString = "Failed to incubate object from otherwise successfully loaded component";
        }
        root.remainingPagesForCreation = root.remainingPagesForCreation - 1;
    }
    function handleComponentCreated(page, createdComponent, params) {
        if (createdComponent.status === Component.Ready) {
            let incubator = createdComponent.incubateObject(applicationWindow(), root.pageCache[page].params);
            if (incubator.status === Component.Loading) {
                // If the object is still being loaded, don't complete yet
                incubator.onStatusChanged = function() {
                    handlePageCreation(page, incubator);
                };
            } else {
                // Otherwise, time to handle that immediately
                handlePageCreation(page, incubator);
            }
        } else {
            console.log("Error during the creation of the", page, "component! This is not great. The reported error was:", createdComponent.errorString());
            root.pageCache[page].errorString = createdComponent.errorString();
            handlePageCreation(page, null);
        }
    }
    function buildCache() {
        root.remainingPagesForCreation = root.remainingPagesForCreation + root.pagesToCache.length;
        for (let pageIndex = 0; pageIndex < root.pagesToCache.length; ++pageIndex) {
            let page = root.pagesToCache[pageIndex];
            let url = pageResolvedUrl(page);
            root.pageCache[page] = {
                creationStartedTime: Date.now(),
                ttl: 0,
                url: url,
                params: {"width": root.width, "height": root.height, visible: false},
                errorString: "",
                pageObject: null
            }
            let component = Qt.createComponent(url, Component.Asynchronous);
            if (component.status === Component.Loading) {
                // If the component is still loading, don't complete yet
                component.statusChanged.connect(function() {
                    handleComponentCreated(page, component);
                });
            } else {
                // If it's done, let's do the thing now
                handleComponentCreated(page, component);
            }
        }
    }
    Component.onCompleted: {
        root.buildCache();
    }

    background: Rectangle {
        color: Kirigami.Theme.backgroundColor
    }

    // Get page instance
    // This method checks if page exists in cache. If not found in cache then the object is cached
    function getPage(page) {
        // Point all multi selector pages to respective cache
        if (["layer", "fixed_layers", "main_layers_view", "layers_for_channel", "bank", "preset"].indexOf(page) >= 0) {
            console.log("Page", page, "is a library page. Using layers_for_channel cache")
            page = "layers_for_channel"
        } else if (["layer_effects", "effect_types", "layer_effect_chooser", "effect_preset"].indexOf(page) >= 0) {
            console.log("Page", page, "is an FX page. Using layers_effects cache")
            page = "layer_effects"
        } else if (["layer_midi_effects", "midi_effect_types", "layer_midi_effect_chooser"].indexOf(page) >= 0) {
            console.log("Page", page, "is an Midi FX page. Using layer_midi_effects cache")
            page = "layer_midi_effects"
        }

        if (root.pageCache[page] != null) {
            // console.log("Page cache found for page :", pageResolvedUrl(page))
            return root.pageCache[page].pageObject
        } else {
            // console.log("Page cache not found for page :", pageResolvedUrl(page))
            console.log("Instantiating page", page, ":", pageResolvedUrl(page))
            var cache = Zynthian.CommonUtils.instantiateComponent(pageResolvedUrl(page), {"width": root.width, "height": root.height, visible: false})

            if (cache.errorString != "") {
                console.log("Error instantiating page", cache.url, ":", cache.errorString);
            } else {
                root.pageCache[page] = cache
            }
            return root.pageCache[page].pageObject
        }
    }

    Connections {
        id: pageChangeHandler
        target: zynqtgui
        onCurrent_screen_idChanged: handlePageChange(zynqtgui.current_screen_id)
        onCurrent_modal_screen_idChanged: handlePageChange(zynqtgui.current_screen_id)

        function handlePageChange(page) {
            if (root.remainingPagesForCreation === 0) {
                if (page != "" && root.currentPage != page) {
                    root.currentPage = page
                    console.log("Changing page to", page)
                    if (zynqtgui.current_modal_screen_id === "confirm") {
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
            } else {
                root.switchToPageAfterCacheCreation = page;
            }
        }
    }
}
