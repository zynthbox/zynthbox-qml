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
        onLayer_created: {
            print("AAAAAAAA")
            zynthian.current_screen_id = "session_dashboard"
            bottomDrawer.open()
            backToSelection.enabled = false
            backToSelectionTimer.restart()
        }
    }
    Timer {
        id: backToSelectionTimer
        interval: 1250
        onTriggered: {
            print("BBBBBBBBB")
            zynthian.current_screen_id = "session_dashboard"
            bottomDrawer.open()
        }
    }
    Connections {
        id: currentScreenConnection
        property string oldScreen: "session_dashboard"
        target: zynthian
        onCurrent_screen_idChanged: {
            if (oldScreen == "engine") {
                backToSelection.enabled = false
            }
            oldScreen = zynthian.current_screen_id
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
            model: selectedTrack.chainedSounds
            delegate: Rectangle {
                id: soundDelegate

                property int chainedSound: modelData

                Layout.fillWidth: true
                Layout.fillHeight: true

                border.width: root.selectedRowIndex === index ? 1 : 0
                border.color: Kirigami.Theme.highlightColor
                color: "transparent"
                radius: 4

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
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                if (root.selectedRowIndex !== index) {
                                    root.selectedRowIndex = index;
                                } else {
                                    if (root.selectedTrack.checkIfLayerExists(soundDelegate.chainedSound)) {
                                        // Open library page
                                        zynthian.current_screen_id = 'layers_for_track';
                                        bottomDrawer.close();
                                    } else if (!root.selectedTrack.createChainedSoundInNextFreeLayer(index)) {
                                        noFreeSlotsPopup.open();
                                    } else {
                                        // Enable layer popup rejected handler to re-select connected sound if any
                                        layerPopupRejectedConnections.enabled = true;

                                        applicationWindow().requestOpenLayerSetupDialog();
                                        //this depends on requirements
                                       // backToSelection.enabled = true;

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
                        enabled: root.selectedRowIndex === index
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
                        enabled: root.selectedRowIndex === index
                        onClicked: {
                            if (root.selectedTrack.checkIfLayerExists(soundDelegate.chainedSound)) {
                                // Open library edit page
                                zynthian.fixed_layers.activate_index(soundDelegate.chainedSound)
                                zynthian.control.single_effect_engine = null;
                                zynthian.current_screen_id = "control";

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
                        enabled: root.selectedRowIndex === index
                        onClicked: {
                            if (root.selectedTrack.checkIfLayerExists(soundDelegate.chainedSound)) {
                                // Open library edit page
                                zynthian.fixed_layers.activate_index(soundDelegate.chainedSound);
                                zynthian.current_modal_screen_id = "midi_key_range";

                                bottomDrawer.close();
                            }
                        }

                        Kirigami.Icon {
                            width: Math.round(Kirigami.Units.gridUnit)
                            height: width
                            anchors.centerIn: parent
                            source: "documentinfo"
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

                            elide: "ElideRight"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (root.selectedRowIndex !== index) {
                                    root.selectedRowIndex = index;
                                } else {
                                    zynthian.fixed_layers.activate_index(soundDelegate.chainedSound)
                                    zynthian.layer_options.show();
                                    zynthian.current_screen_id = "layer_effects";

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
                        Layout.preferredHeight: Kirigami.Units.gridUnit
                        //Layout.maximumHeight: Kirigami.Units.gridUnit*0.1
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
