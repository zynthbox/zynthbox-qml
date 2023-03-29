import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Window 2.1
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick

Zynthian.Card {
    id: root

    property QtObject selectedChannel
    //: applicationWindow().selectedChannel

    Binding {
        target: root
        property: "selectedChannel"
        delayed: true
        value: applicationWindow().selectedChannel
    }

    property int selectedChannelIndex: zynthian.session_dashboard.selectedChannel;
    property var chainedSounds: selectedChannel ? selectedChannel.chainedSounds : []
    property bool openBottomDrawerOnLoad: false

    Connections {
        target: zynthian.fixed_layers
        onList_updated: {
            // Update sound / preset /synth labels on change
            for (var i = 0; i < chainedSoundsRepeater.count; ++i ) {
                chainedSoundsRepeater.itemAt(i).update();
            }
        }
    }

    Connections {
        id: currentScreenConnection
        property string oldScreen: "session_dashboard"
        target: zynthian
        onCurrent_screen_idChanged: {
            for (var i = 0; i < chainedSoundsRepeater.count; ++i ) {
                chainedSoundsRepeater.itemAt(i).update();
            }
        }
    }

    function cuiaCallback(cuia) {
        switch (cuia) {
            case "SELECT_UP":
                if (root.selectedChannel.selectedSlotRow > 0) {
                    root.selectedChannel.selectedSlotRow -= 1
                }
                return true;

            case "SELECT_DOWN":
                if (root.selectedChannel.selectedSlotRow < 4) {
                    root.selectedChannel.selectedSlotRow += 1
                }
                return true;

//            case "NAVIGATE_LEFT":
//                var selectedMidiChannel = root.chainedSounds[root.selectedChannel.selectedSlotRow];
//                if (selectedChannel.checkIfLayerExists(selectedMidiChannel)) {
//                    zynthian.layer.selectPrevPreset(selectedMidiChannel);
//                    chainedSoundsRepeater.itemAt(selectedRowIndex).update();
//                }
//                return true;

//            case "NAVIGATE_RIGHT":
//                var selectedMidiChannel = root.chainedSounds[root.selectedChannel.selectedSlotRow];
//                if (selectedChannel.checkIfLayerExists(selectedMidiChannel)) {
//                    zynthian.layer.selectNextPreset(selectedMidiChannel);
//                    chainedSoundsRepeater.itemAt(root.selectedChannel.selectedSlotRow).update();
//                }
//                return true;

            case "SWITCH_BACK_SHORT":
                bottomStack.slotsBar.channelButton.checked = true

                return true;

            case "SWITCH_SELECT_SHORT":
            case "SWITCH_SELECT_BOLD":
            case "SWITCH_SELECT_LONG":
                layerSetupDialog.open();
                return true;

            // Set respective selected row when button 1-5 is pressed or 6(mod)+1-5 is pressed
            case "CHANNEL_1":
            case "CHANNEL_6":
                root.selectedChannel.selectedSlotRow = 0
                return true
            case "CHANNEL_2":
            case "CHANNEL_7":
                root.selectedChannel.selectedSlotRow = 1
                return true
            case "CHANNEL_3":
            case "CHANNEL_8":
                root.selectedChannel.selectedSlotRow = 2
                return true
            case "CHANNEL_4":
            case "CHANNEL_9":
                root.selectedChannel.selectedSlotRow = 3
                return true
            case "CHANNEL_5":
            case "CHANNEL_10":
                root.selectedChannel.selectedSlotRow = 4
                return true

            default:
                return false;
        }
    }

    padding: Kirigami.Units.gridUnit
    contentItem: ColumnLayout {
        anchors.margins: Kirigami.Units.gridUnit

//        Kirigami.Heading {
//            text: qsTr("Channel : %1").arg(root.selectedChannel.name)
//        }

        Repeater {
            id: chainedSoundsRepeater
            model: root.chainedSounds.length //performace optimization, this length never changes so we never recreate the items
            delegate: Rectangle {
                id: soundDelegate

                property int chainedSound: root.chainedSounds[index]
                property QtObject volumeControlObject: zynthian.fixed_layers.volumeControllers[chainedSound] ? zynthian.fixed_layers.volumeControllers[chainedSound] : null
                property real volumePercent: volumeControlObject
                                                ? (volumeControlObject.value - volumeControlObject.value_min)/(volumeControlObject.value_max - volumeControlObject.value_min)
                                                : 0

                Connections {
                    target: root
                    onChainedSoundsChanged: {
                        soundDelegate.chainedSound = root.chainedSounds[index]
                        update()
                    }
                }

                Layout.fillWidth: true
                Layout.fillHeight: true

                border.width: root.selectedChannel.selectedSlotRow === index ? 1 : 0
                border.color: Kirigami.Theme.highlightColor
                color: "transparent"
                radius: 4
                enabled: true

                function update() {
                    soundLabelSynth.updateName();
                    soundLabelPreset.updateName();
                    fxLabel.updateName();
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.selectedChannel.selectedSlotRow = index;
                    }
                }

                RowLayout {
                    opacity: root.selectedChannel.selectedSlotRow === index ? 1 : 0.5
                    anchors.fill: parent

                    Rectangle {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.preferredWidth: Kirigami.Units.gridUnit*10
                        Layout.preferredHeight: parent.height < Kirigami.Units.gridUnit*2 ? Kirigami.Units.gridUnit*1.3 : Kirigami.Units.gridUnit*2
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: Kirigami.Units.gridUnit

                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        color: Kirigami.Theme.backgroundColor

                        border.color: "#ff999999"
                        border.width: 1
                        radius: 4

                        QQC2.Label {
                            id: soundLabelPreset
                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: parent.left
                                right: parent.right
                                leftMargin: Kirigami.Units.gridUnit*0.5
                                rightMargin: Kirigami.Units.gridUnit*0.5
                            }
                            horizontalAlignment: Text.AlignLeft
                            text: {
                                var str = "";

                                if (chainedSound !== -1) {
                                    var presetName = root.selectedChannel.getLayerNameByMidiChannel(chainedSound).split(">")[1]
                                    if (presetName != null) {
                                        str = presetName;
                                    }
                                }

                                return str;
                            }

                            elide: "ElideRight"

                            function updateName() {
                                var str = "";

                                if (chainedSound !== -1) {
                                    var presetName = root.selectedChannel.getLayerNameByMidiChannel(chainedSound).split(">")[1]
                                    if (presetName != null) {
                                        str = presetName;
                                    }
                                }

                                text = str;
                            }
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                if (root.selectedChannel.selectedSlotRow !== index) {
                                    root.selectedChannel.selectedSlotRow = index;
                                } else {
                                    layerSetupDialog.open()
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.preferredWidth: Kirigami.Units.gridUnit*10
                        Layout.preferredHeight: parent.height < Kirigami.Units.gridUnit*2 ? Kirigami.Units.gridUnit*1.3 : Kirigami.Units.gridUnit*2
                        Layout.alignment: Qt.AlignVCenter
                        Layout.rightMargin: Kirigami.Units.gridUnit

                        Kirigami.Theme.inherit: false
                        Kirigami.Theme.colorSet: Kirigami.Theme.Button
                        color: Kirigami.Theme.backgroundColor

                        border.color: "#ff999999"
                        border.width: 1
                        radius: 4

                        Rectangle {
                            width: parent.width * soundDelegate.volumePercent
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            visible: root.selectedChannel.channelAudioType === "synth" &&
                                     soundLabelSynth.text.trim().length > 0

                            color: Kirigami.Theme.highlightColor
                        }

                        QQC2.Label {
                            id: soundLabelSynth
                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: parent.left
                                right: parent.right
                                leftMargin: Kirigami.Units.gridUnit*0.5
                                rightMargin: Kirigami.Units.gridUnit*0.5
                            }
                            horizontalAlignment: Text.AlignLeft
                            text: chainedSound > -1 && root.selectedChannel ? root.selectedChannel.getLayerNameByMidiChannel(chainedSound).split(">")[0] : ""

                            elide: "ElideRight"

                            function updateName() {
                                text = chainedSound > -1 && root.selectedChannel ? root.selectedChannel.getLayerNameByMidiChannel(chainedSound).split(">")[0] : ""
                            }
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                if (root.selectedChannel.selectedSlotRow !== index) {
                                    root.selectedChannel.selectedSlotRow = index;
                                } else {
                                    layerSetupDialog.open()
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
                        enabled: root.selectedChannel.selectedSlotRow === index && soundDelegate.chainedSound !== -1
                        onClicked: {
                            if (root.selectedChannel.checkIfLayerExists(soundDelegate.chainedSound)) {
                                selectedChannel.remove_and_unchain_sound(soundDelegate.chainedSound);
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
                        enabled: root.selectedChannel.selectedSlotRow === index && soundDelegate.chainedSound !== -1
                        onClicked: {
                            if (root.selectedChannel.checkIfLayerExists(soundDelegate.chainedSound)) {
                                zynthian.start_loading()

                                // Open library edit page
                                zynthian.fixed_layers.activate_index(soundDelegate.chainedSound)

                                zynthian.stop_loading()

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
                        enabled: root.selectedChannel.selectedSlotRow === index && soundDelegate.chainedSound !== -1
                        onClicked: {
                            if (root.selectedChannel.checkIfLayerExists(soundDelegate.chainedSound)) {
                                zynthian.start_loading()

                                // Open library edit page
                                // Not sure if switching to the channel is required here
                                zynthian.fixed_layers.activate_index(soundDelegate.chainedSound);

                                zynthian.stop_loading()

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
                        Layout.preferredWidth: Kirigami.Units.gridUnit*10
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
                            text: root.selectedChannel ? root.selectedChannel.getEffectsNameByMidiChannel(chainedSound) : ""
                            function updateName() {
                                text = root.selectedChannel ? root.selectedChannel.getEffectsNameByMidiChannel(chainedSound) : ""
                            }

                            elide: "ElideRight"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (soundDelegate.chainedSound === -1 || root.selectedChannel.selectedSlotRow !== index) {
                                    root.selectedChannel.selectedSlotRow = index;
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
                        enabled: root.selectedChannel.selectedSlotRow === index && fxLabel.text.length > 0
                        onClicked: {
                            if (root.selectedChannel.checkIfLayerExists(soundDelegate.chainedSound)) {
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
                }
            }
        }
    }

    Zynthian.Popup {
        id: noFreeSlotsPopup
        x: Math.round(parent.width/2 - width/2)
        y: Math.round(parent.height/2 - height/2)
        width: Kirigami.Units.gridUnit*12
        height: Kirigami.Units.gridUnit*4

        QQC2.Label {
            width: parent.width
            height: parent.height
            horizontalAlignment: "AlignHCenter"
            verticalAlignment: "AlignVCenter"
            text: qsTr("No free slots remaining")
            font.italic: true
        }
    }

    Zynthian.LayerSetupDialog {
        id: layerSetupDialog
    }
} 
