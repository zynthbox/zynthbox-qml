import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Window 2.1
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick

Zynthian.Card {
    id: root

    property QtObject selectedTrack: applicationWindow().selectedTrack
    property int selectedTrackIndex: zynthian.session_dashboard.selectedTrack;
    property var chainedSounds: selectedTrack ? selectedTrack.chainedSounds : []
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
                if (zynthian.session_dashboard.selectedSoundRow > 0) {
                    zynthian.session_dashboard.selectedSoundRow -= 1
                }
                return true;

            case "SELECT_DOWN":
                if (zynthian.session_dashboard.selectedSoundRow < 4) {
                    zynthian.session_dashboard.selectedSoundRow += 1
                }
                return true;

//            case "NAVIGATE_LEFT":
//                var selectedMidiChannel = root.chainedSounds[zynthian.session_dashboard.selectedSoundRow];
//                if (selectedTrack.checkIfLayerExists(selectedMidiChannel)) {
//                    zynthian.layer.selectPrevPreset(selectedMidiChannel);
//                    chainedSoundsRepeater.itemAt(selectedRowIndex).update();
//                }
//                return true;

//            case "NAVIGATE_RIGHT":
//                var selectedMidiChannel = root.chainedSounds[zynthian.session_dashboard.selectedSoundRow];
//                if (selectedTrack.checkIfLayerExists(selectedMidiChannel)) {
//                    zynthian.layer.selectNextPreset(selectedMidiChannel);
//                    chainedSoundsRepeater.itemAt(zynthian.session_dashboard.selectedSoundRow).update();
//                }
//                return true;

            case "SWITCH_BACK_SHORT":
                bottomStack.slotsBar.trackButton.checked = true

                return true;

            case "SWITCH_SELECT_SHORT":
            case "SWITCH_SELECT_BOLD":
            case "SWITCH_SELECT_LONG":
                layerSetupDialog.open();
                return true;

            // Set respective selected row when button 1-5 is pressed or 6(mod)+1-5 is pressed
            case "TRACK_1":
            case "TRACK_6":
                zynthian.session_dashboard.selectedSoundRow = 0
                return true
            case "TRACK_2":
            case "TRACK_7":
                zynthian.session_dashboard.selectedSoundRow = 1
                return true
            case "TRACK_3":
            case "TRACK_8":
                zynthian.session_dashboard.selectedSoundRow = 2
                return true
            case "TRACK_4":
            case "TRACK_9":
                zynthian.session_dashboard.selectedSoundRow = 3
                return true
            case "TRACK_5":
            case "TRACK_10":
                zynthian.session_dashboard.selectedSoundRow = 4
                return true

            default:
                return false;
        }
    }

    padding: Kirigami.Units.gridUnit
    contentItem: ColumnLayout {
        anchors.margins: Kirigami.Units.gridUnit

        Kirigami.Heading {
            text: qsTr("Track : %1").arg(root.selectedTrack.name)
        }

        Repeater {
            id: chainedSoundsRepeater
            model: root.chainedSounds.length //performace optimization, this length never changes so we never recreate the items
            delegate: Rectangle {
                id: soundDelegate

                property int chainedSound: root.chainedSounds[index]
                Connections {
                    target: root
                    onChainedSoundsChanged: soundDelegate.chainedSound = root.chainedSounds[index]
                }

                Layout.fillWidth: true
                Layout.fillHeight: true

                border.width: zynthian.session_dashboard.selectedSoundRow === index ? 1 : 0
                border.color: Kirigami.Theme.highlightColor
                color: "transparent"
                radius: 4
                function update() {
                    soundLabelSynth.updateName();
                    soundLabelPreset.updateName();
                    fxLabel.updateName();
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        zynthian.session_dashboard.selectedSoundRow = index;
                    }
                }

                RowLayout {
                    opacity: zynthian.session_dashboard.selectedSoundRow === index ? 1 : 0.5
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
                                    var presetName = root.selectedTrack.getLayerNameByMidiChannel(chainedSound).split(">")[1]
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
                                    var presetName = root.selectedTrack.getLayerNameByMidiChannel(chainedSound).split(">")[1]
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
                                if (zynthian.session_dashboard.selectedSoundRow !== index) {
                                    zynthian.session_dashboard.selectedSoundRow = index;
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
                            text: chainedSound > -1 && root.selectedTrack ? root.selectedTrack.getLayerNameByMidiChannel(chainedSound).split(">")[0] : ""

                            elide: "ElideRight"

                            function updateName() {
                                text = chainedSound > -1 && root.selectedTrack ? root.selectedTrack.getLayerNameByMidiChannel(chainedSound).split(">")[0] : ""
                            }
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                if (zynthian.session_dashboard.selectedSoundRow !== index) {
                                    zynthian.session_dashboard.selectedSoundRow = index;
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
                        enabled: zynthian.session_dashboard.selectedSoundRow === index && soundDelegate.chainedSound !== -1
                        onClicked: {
                            if (root.selectedTrack.checkIfLayerExists(soundDelegate.chainedSound)) {
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
                        enabled: zynthian.session_dashboard.selectedSoundRow === index && soundDelegate.chainedSound !== -1
                        onClicked: {
                            if (root.selectedTrack.checkIfLayerExists(soundDelegate.chainedSound)) {
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
                        enabled: zynthian.session_dashboard.selectedSoundRow === index && soundDelegate.chainedSound !== -1
                        onClicked: {
                            if (root.selectedTrack.checkIfLayerExists(soundDelegate.chainedSound)) {
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
                            text: root.selectedTrack ? root.selectedTrack.getEffectsNameByMidiChannel(chainedSound) : ""
                            function updateName() {
                                text = root.selectedTrack ? root.selectedTrack.getEffectsNameByMidiChannel(chainedSound) : ""
                            }

                            elide: "ElideRight"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (soundDelegate.chainedSound === -1 || zynthian.session_dashboard.selectedSoundRow !== index) {
                                    zynthian.session_dashboard.selectedSoundRow = index;
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
                        enabled: zynthian.session_dashboard.selectedSoundRow === index && fxLabel.text.length > 0
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
                        property QtObject volumeControlObject: zynthian.layers_for_track.volume_controls[index] ? zynthian.layers_for_track.volume_controls[index] : null

                        Layout.fillWidth: true
                        Layout.fillHeight: false
                        Layout.preferredHeight: parent.height < Kirigami.Units.gridUnit*2 ? Kirigami.Units.gridUnit*1.3 : Kirigami.Units.gridUnit*2
                        Layout.alignment: Qt.AlignVCenter
                        Layout.leftMargin: Kirigami.Units.gridUnit
                        Layout.rightMargin: Kirigami.Units.gridUnit

                        orientation: Qt.Horizontal
                        enabled: zynthian.session_dashboard.selectedSoundRow === index &&
                                 soundDelegate.chainedSound >= 0 &&
                                 root.selectedTrack &&
                                 root.selectedTrack.checkIfLayerExists(soundDelegate.chainedSound) &&
                                 volumeControlObject.controllable
                        value: volumeControlObject ? volumeControlObject.value : 0
                        stepSize: volumeControlObject ? volumeControlObject.step_size : 1
                        from: volumeControlObject ? volumeControlObject.value_min : 0
                        to: volumeControlObject ? volumeControlObject.value_max : 1
                        onMoved: {
                            zynthian.layers_for_track.volume_controls[index].value = value;
                        }
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

    Zynthian.LayerSetupDialog {
        id: layerSetupDialog
    }
} 
