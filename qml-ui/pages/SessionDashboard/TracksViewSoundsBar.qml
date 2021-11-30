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

    // Hack to always update UI
    Connections {
        target: bottomDrawer
        onOpened: {
            console.log("### Populating chained sounds");

            chainedSoundsRepeater.model = [];
            chainedSoundsRepeater.model = chainedSounds;
        }
        onClosed: {
            chainedSoundsRepeater.model = [];
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

    padding: Kirigami.Units.gridUnit
    contentItem: ColumnLayout {
        anchors.margins: Kirigami.Units.gridUnit

        Repeater {
            id: chainedSoundsRepeater
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
                        Layout.preferredHeight: Kirigami.Units.gridUnit*2
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
                                        zynthian.current_screen_id = 'fixed_layers';
                                        bottomDrawer.close();
                                    } else {
                                        if (!root.selectedTrack.createChainedSoundInNextFreeLayer(index)) {
                                            noFreeSlotsPopup.open();
                                        } else {
                                            bottomDrawer.close();

                                            if (root.selectedTrack.connectedPattern >= 0) {
                                                var seq = ZynQuick.PlayGridManager.getSequenceModel("Global").get(playgridPickerPopup.trackObj.connectedPattern);
                                                seq.midiChannel = root.selectedTrack.connectedSound;
                                            }
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
                        Layout.preferredHeight: Kirigami.Units.gridUnit*2
                        Layout.alignment: Qt.AlignVCenter
                        radius: 4
                        enabled: root.selectedRowIndex === index
                        onClicked: {
                            if (root.selectedTrack.checkIfLayerExists(soundDelegate.chainedSound)) {
                                bottomDrawer.close();

                                zynthian.fixed_layers.activate_index(soundDelegate.chainedSound)
                                zynthian.layer.ask_remove_current_layer()
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
                        Layout.preferredHeight: Kirigami.Units.gridUnit*2
                        Layout.alignment: Qt.AlignVCenter
                        radius: 4
                        enabled: root.selectedRowIndex === index
                        onClicked: {
                            if (root.selectedTrack.checkIfLayerExists(soundDelegate.chainedSound)) {
                                // Open library edit page
                                bottomDrawer.close();

                                zynthian.fixed_layers.activate_index(soundDelegate.chainedSound)
                                zynthian.control.single_effect_engine = null;
                                zynthian.current_screen_id = "control";
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
                        Layout.preferredHeight: Kirigami.Units.gridUnit*2
                        Layout.alignment: Qt.AlignVCenter
                        radius: 4
                        enabled: root.selectedRowIndex === index
                        onClicked: {
                            if (root.selectedTrack.checkIfLayerExists(soundDelegate.chainedSound)) {
                                // Open library edit page
                                bottomDrawer.close();

                                zynthian.fixed_layers.activate_index(soundDelegate.chainedSound);
                                zynthian.current_modal_screen_id = "midi_key_range";
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
                        Layout.preferredHeight: Kirigami.Units.gridUnit*2
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
                                    bottomDrawer.close();
                                    zynthian.fixed_layers.activate_index(soundDelegate.chainedSound)
                                    zynthian.layer_options.show();
                                    zynthian.current_screen_id = "layer_effects";
                                }
                            }
                        }
                    }

                    QQC2.RoundButton {
                        Layout.fillWidth: false
                        Layout.fillHeight: false
                        Layout.preferredWidth: Kirigami.Units.gridUnit*2
                        Layout.preferredHeight: Kirigami.Units.gridUnit*2
                        Layout.alignment: Qt.AlignVCenter
                        radius: 4
                        enabled: root.selectedRowIndex === index && fxLabel.text.length > 0
                        onClicked: {
                            if (root.selectedTrack.checkIfLayerExists(soundDelegate.chainedSound)) {
                                bottomDrawer.close();

                                zynthian.fixed_layers.activate_index(soundDelegate.chainedSound)
                                zynthian.layer_effects.fx_reset()
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
                        Layout.preferredHeight: Kirigami.Units.gridUnit*2
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
