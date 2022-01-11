import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Window 2.1
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian

Zynthian.Card {
    id: root

    property int selectedRowIndex: 0
    property QtObject selectedTrack: zynthian.zynthiloops.song.tracksModel.getTrack(zynthian.session_dashboard.selectedTrack)
    property var chainedSounds: selectedTrack.chainedSounds
    property bool openBottomDrawerOnLoad: false

    function selectConnectedSound() {
        if (selectedTrack.connectedSound >= 0) {
            zynthian.fixed_layers.activate_index(selectedTrack.connectedSound);

            if (root.selectedTrack.connectedPattern >= 0) {
                var seq = ZynQuick.PlayGridManager.getSequenceModel("Global").get(playgridPickerPopup.trackObj.connectedPattern);
                seq.midiChannel = root.selectedTrack.connectedSound;
            }
        }
    }
    
    // Hack to always update UI
    Connections {
        target: bottomDrawer
        onOpened: {
            console.log("### Populating chained sounds");

            chainedSoundsRepeater.model = [];
            chainedSoundsRepeater.model = Qt.binding(function() { return chainedSounds; });
        }
        onClosed: {
            chainedSoundsRepeater.model = [];
        }
    }

    // When enabled, listen for layer popup rejected to re-select connected sound if any
    Connections {
        id: layerPopupRejectedConnections
        enabled: false
        target: applicationWindow()
        onLayerSetupDialogRejected: {
            console.log("Layer Popup Rejected");

            root.selectConnectedSound();
            layerPopupRejectedConnections.enabled = false;
        }
    }
    //NOTE: enable this if shouldn't switch to library
    Connections {
        id: backToSelection
        target: zynthian.layer
        enabled: false
        property string screenToGetBack: "session_dashboard"
        onLayer_created: {
            zynthian.current_modal_screen_id = screenToGetBack
            backToSelection.enabled = false
            backToSelectionTimer.restart()
            bottomDrawer.open()
        }
    }
    Timer {
        id: backToSelectionTimer
        interval: 250
        onTriggered: {
            zynthian.current_modal_screen_id = backToSelection.screenToGetBack
            for (var i = 0; i < chainedSoundsRepeater.count; ++i ) {
                chainedSoundsRepeater.itemAt(i).update();
            }
            bottomDrawer.open()
        }
    }

    Connections {
        id: currentScreenConnection
        property string oldScreen: "session_dashboard"
        target: zynthian
        onCurrent_screen_idChanged: {
            if (zynthian.current_screen_id === "session_dashboard" && root.openBottomDrawerOnLoad) {
                bottomDrawer.open()
                root.openBottomDrawerOnLoad = false;
            }
            if (oldScreen == "engine") {
                backToSelection.enabled = false
            }
            oldScreen = zynthian.current_screen_id
            for (var i = 0; i < chainedSoundsRepeater.count; ++i ) {
                chainedSoundsRepeater.itemAt(i).update();
            }
        }
    }

    // When enabled, listen for sound dialog rejected to re-select connected sound if any
    Connections {
        id: soundsDialogRejectedConnections
        enabled: false
        target: applicationWindow()
        onSoundsDialogAccepted: {
            console.log("Sounds Dialog Accepted");
            soundsDialogRejectedConnections.enabled = false;
        }
        onSoundsDialogRejected: {
            console.log("Sounds Dialog Rejected");

            root.selectConnectedSound();
            soundsDialogRejectedConnections.enabled = false;
        }
    }

    Connections {
        target: applicationWindow()
        onLayerSetupDialogLoadSoundClicked: {
            // Disable Rejected handler as popup is accepted
            layerPopupRejectedConnections.enabled = false;
        }
        onLayerSetupDialogNewSynthClicked: {
            bottomDrawer.close();

            // Disable Rejected handler as popup is accepted
            layerPopupRejectedConnections.enabled = false;
        }
        onLayerSetupDialogPickSoundClicked: {
            console.log("Sound Dialog Opened");

            // Enable Sounds dialog rejected handler to select sound if any on close
            soundsDialogRejectedConnections.enabled = true;

            // Disable Rejected handler as popup is accepted
            layerPopupRejectedConnections.enabled = false;
        }
    }

    function cuiaCallback(cuia) {
        switch (cuia) {
            case "SELECT_UP":
                if (root.selectedRowIndex > 0) {
                    root.selectedRowIndex -= 1
                    return true;
                } else {
                    return false;
                }

            case "SELECT_DOWN":
                if (root.selectedRowIndex < 4) {
                    root.selectedRowIndex += 1
                    return true;
                } else {
                    return false;
                }

            case "NAVIGATE_LEFT":
                var selectedMidiChannel = root.chainedSounds[root.selectedRowIndex];
                if (selectedTrack.checkIfLayerExists(selectedMidiChannel)) {
                    zynthian.layer.selectPrevPreset(selectedMidiChannel);
                    chainedSoundsRepeater.itemAt(selectedRowIndex).update();
                }
                return true;

            case "NAVIGATE_RIGHT":
                var selectedMidiChannel = root.chainedSounds[root.selectedRowIndex];
                if (selectedTrack.checkIfLayerExists(selectedMidiChannel)) {
                    zynthian.layer.selectNextPreset(selectedMidiChannel);
                    chainedSoundsRepeater.itemAt(root.selectedRowIndex).update();
                }
                return true;

            default:
                return false;
        }
    }

    function resetModel() {
        chainedSoundsRepeater.model = [];
        chainedSoundsRepeater.model = Qt.binding(function() { return chainedSounds; });
    }

    padding: Kirigami.Units.gridUnit
    contentItem: ColumnLayout {
        anchors.margins: Kirigami.Units.gridUnit

        Repeater {
            id: chainedSoundsRepeater
//            model: selectedTrack.chainedSounds
            delegate: Rectangle {
                id: soundDelegate

                property int chainedSound: modelData

                Layout.fillWidth: true
                Layout.fillHeight: true

                border.width: root.selectedRowIndex === index ? 1 : 0
                border.color: Kirigami.Theme.highlightColor
                color: "transparent"
                radius: 4
                function update() {
                    soundLabel.updateName();
                    fxLabel.updateName();
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.selectedRowIndex = index;
                    }
                }

                RowLayout {
                    opacity: root.selectedRowIndex === index ? 1 : 0.5
                    anchors.fill: parent

                    Rectangle {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.preferredWidth: Kirigami.Units.gridUnit*12
                        Layout.preferredHeight: parent.height < Kirigami.Units.gridUnit*2 ? Kirigami.Units.gridUnit*1.3 : Kirigami.Units.gridUnit*2
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: Kirigami.Units.gridUnit
                        Layout.rightMargin: Kirigami.Units.gridUnit

                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        color: Kirigami.Theme.backgroundColor

                        border.color: "#ff999999"
                        border.width: 1
                        radius: 4

                        QQC2.Label {
                            id: soundLabel
                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: parent.left
                                right: parent.right
                                leftMargin: Kirigami.Units.gridUnit*0.5
                                rightMargin: Kirigami.Units.gridUnit*0.5
                            }
                            horizontalAlignment: Text.AlignLeft
                            text: chainedSound === -1 ? "" : root.selectedTrack.getLayerNameByMidiChannel(chainedSound)

                            elide: "ElideRight"

                            function updateName() {
                                text = chainedSound === -1 ? "" : root.selectedTrack.getLayerNameByMidiChannel(chainedSound)
                            }
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                if (root.selectedRowIndex !== index) {
                                    root.selectedRowIndex = index;
                                } else {
                                    if (root.selectedTrack.checkIfLayerExists(soundDelegate.chainedSound)) {
                                        // Open library page
                                        var screenBack = zynthian.current_screen_id;
                                        zynthian.current_screen_id = 'layers_for_track';
                                        zynthian.forced_screen_back = screenBack;
                                        bottomDrawer.close();
                                    } else if (!root.selectedTrack.createChainedSoundInNextFreeLayer(index)) {
                                        noFreeSlotsPopup.open();
                                    } else {
                                        // Enable layer popup rejected handler to re-select connected sound if any
                                        layerPopupRejectedConnections.enabled = true;

                                        zynthian.layer.page_after_layer_creation = "session_dashboard";
                                        applicationWindow().requestOpenLayerSetupDialog();
                                        //this depends on requirements
                                        backToSelection.screenToGetBack = zynthian.current_screen_id;
                                        backToSelection.enabled = true;

                                        if (root.selectedTrack.connectedPattern >= 0) {
                                            var seq = ZynQuick.PlayGridManager.getSequenceModel("Global").get(playgridPickerPopup.trackObj.connectedPattern);
                                            seq.midiChannel = root.selectedTrack.connectedSound;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    QQC2.RoundButton {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.preferredWidth: Kirigami.Units.gridUnit*2
                        Layout.preferredHeight: parent.height < Kirigami.Units.gridUnit*2 ? Kirigami.Units.gridUnit*1.3 : Kirigami.Units.gridUnit*2
                        Layout.alignment: Qt.AlignVCenter
                        radius: 4
                        enabled: root.selectedRowIndex === index && soundDelegate.chainedSound !== -1
                        onClicked: {
                            if (root.selectedTrack.checkIfLayerExists(soundDelegate.chainedSound)) {
//                                bottomDrawer.close();

//                                zynthian.fixed_layers.activate_index(soundDelegate.chainedSound)
//                                zynthian.layer.ask_remove_current_layer()
                                var chainedSoundsCopy = selectedTrack.chainedSounds.slice();
                                chainedSoundsCopy[index] = -1;

                                console.log(chainedSoundsCopy);
                                //selectedTrack.chainedSounds = chainedSoundsCopy;
                                selectedTrack.remove_and_unchain_sound(soundDelegate.chainedSound);
                            }
                        }

                        Kirigami.Icon {
                            width: Math.round(Kirigami.Units.gridUnit)
                            height: width
                            anchors.centerIn: parent
                            source: "edit-clear-all"
                            color: Kirigami.Theme.textColor
                        }
                    }

                    QQC2.RoundButton {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.preferredWidth: Kirigami.Units.gridUnit*2
                        Layout.preferredHeight: parent.height < Kirigami.Units.gridUnit*2 ? Kirigami.Units.gridUnit*1.3 : Kirigami.Units.gridUnit*2
                        Layout.alignment: Qt.AlignVCenter
                        radius: 4
                        enabled: root.selectedRowIndex === index && soundDelegate.chainedSound !== -1
                        onClicked: {
                            if (root.selectedTrack.checkIfLayerExists(soundDelegate.chainedSound)) {
                                // Open library edit page
                                zynthian.fixed_layers.activate_index(soundDelegate.chainedSound)
                                zynthian.control.single_effect_engine = null;
                                root.openBottomDrawerOnLoad = true;
                                var screenBack = zynthian.current_screen_id;
                                zynthian.current_screen_id = "control";
                                zynthian.forced_screen_back = screenBack;

                                bottomDrawer.close();
                            }
                        }

                        Kirigami.Icon {
                            width: Math.round(Kirigami.Units.gridUnit)
                            height: width
                            anchors.centerIn: parent
                            source: "document-edit"
                            color: Kirigami.Theme.textColor
                        }
                    }

                    QQC2.RoundButton {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.preferredWidth: Kirigami.Units.gridUnit*2
                        Layout.preferredHeight: parent.height < Kirigami.Units.gridUnit*2 ? Kirigami.Units.gridUnit*1.3 : Kirigami.Units.gridUnit*2
                        Layout.alignment: Qt.AlignVCenter
                        radius: 4
                        enabled: root.selectedRowIndex === index && soundDelegate.chainedSound !== -1
                        onClicked: {
                            if (root.selectedTrack.checkIfLayerExists(soundDelegate.chainedSound)) {
                                // Open library edit page

                                // Not sure if switching to the channel is required here
                                zynthian.fixed_layers.activate_index(soundDelegate.chainedSound);

                                root.openBottomDrawerOnLoad = true;
                                var screenBack = zynthian.current_screen_id;
                                zynthian.current_modal_screen_id = "midi_key_range";
                                zynthian.forced_screen_back = screenBack

                                bottomDrawer.close();
                            }
                        }

                        Kirigami.Icon {
                            width: Math.round(Kirigami.Units.gridUnit)
                            height: width
                            anchors.centerIn: parent
                            source: "settings-configure"
                            color: Kirigami.Theme.textColor
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.preferredWidth: Kirigami.Units.gridUnit*12
                        Layout.preferredHeight: parent.height < Kirigami.Units.gridUnit*2 ? Kirigami.Units.gridUnit*1.3 : Kirigami.Units.gridUnit*2
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: Kirigami.Units.gridUnit
                        Layout.rightMargin: Kirigami.Units.gridUnit

                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        color: Kirigami.Theme.backgroundColor

                        border.color: "#ff999999"
                        border.width: 1
                        radius: 4

                        QQC2.Label {
                            id: fxLabel
                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: parent.left
                                right: parent.right
                                leftMargin: Kirigami.Units.gridUnit*0.5
                                rightMargin: Kirigami.Units.gridUnit*0.5
                            }
                            horizontalAlignment: Text.AlignLeft
                            text: root.selectedTrack.getEffectsNameByMidiChannel(chainedSound)
                            function updateName() {
                                text = root.selectedTrack.getEffectsNameByMidiChannel(chainedSound)
                            }

                            elide: "ElideRight"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (soundDelegate.chainedSound === -1 || root.selectedRowIndex !== index) {
                                    root.selectedRowIndex = index;
                                } else {
                                    zynthian.fixed_layers.activate_index(soundDelegate.chainedSound)
                                    zynthian.layer_options.show();
                                    var screenBack = zynthian.current_screen_id;
                                    zynthian.current_screen_id = "layer_effects";
                                    root.openBottomDrawerOnLoad = true;
                                    zynthian.forced_screen_back = screenBack;

                                    bottomDrawer.close();
                                }
                            }
                        }
                    }

                    QQC2.RoundButton {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.preferredWidth: Kirigami.Units.gridUnit*2
                        Layout.preferredHeight: parent.height < Kirigami.Units.gridUnit*2 ? Kirigami.Units.gridUnit*1.3 : Kirigami.Units.gridUnit*2
                        Layout.alignment: Qt.AlignVCenter
                        radius: 4
                        enabled: root.selectedRowIndex === index && fxLabel.text.length > 0
                        onClicked: {
                            if (root.selectedTrack.checkIfLayerExists(soundDelegate.chainedSound)) {
                                zynthian.fixed_layers.activate_index(soundDelegate.chainedSound)
                                zynthian.layer_effects.fx_reset()

                                bottomDrawer.close();
                            }
                        }

                        Kirigami.Icon {
                            width: Math.round(Kirigami.Units.gridUnit)
                            height: width
                            anchors.centerIn: parent
                            source: "edit-clear-all"
                            color: Kirigami.Theme.textColor
                        }
                    }

                    QQC2.Slider {
                        orientation: Qt.Horizontal

                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.preferredHeight: parent.height < Kirigami.Units.gridUnit*2 ? Kirigami.Units.gridUnit*1.3 : Kirigami.Units.gridUnit*2
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: Kirigami.Units.gridUnit
                        Layout.rightMargin: Kirigami.Units.gridUnit

                        from: 0
                        to: 100
                        stepSize: 1
                        value: 100
                    }
                }
            }
        }
    }

    QQC2.Popup {
        id: noFreeSlotsPopup
        x: Math.round(parent.width/2 - width/2)
        y: Math.round(parent.height/2 - height/2)
        width: Kirigami.Units.gridUnit*12
        height: Kirigami.Units.gridUnit*4
        modal: true

        QQC2.Label {
            width: parent.width
            height: parent.height
            horizontalAlignment: "AlignHCenter"
            verticalAlignment: "AlignVCenter"
            text: qsTr("No free slots remaining")
            font.italic: true
        }
    }
} 
