import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.6 as Kirigami

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

RowLayout {
    id: control
    /**
      * An array of 5 elements containing data that needs to be displayed on the slots
      * This data will vary depending upon which type of data is to be displayed which is supplied via
      * slotType property. The main purpose of these properties are to use the existing logic to display slots data into same slots
      * but instead of the data depending on trackType, it is explicitly set by slotType
      *
      * slotData values can be any of synthSlotsData, sampleSlotsData, sketchSlotsData, externalSlotsData
      */
    property var slotData: []
    /**
      * Type of data that needs to be displayed. It should be "synth" for synthSlotsData, "sample-trig" for sampleSlotsData
      * "sample-loop" for sketchSlotsData, "external" for externalSlotsData
      */
    property string slotType

    /**
      * Emulate a click to slot at specified index
      */
    function switchToSlot(index, onlyFocus=false) {
        // This function may conceivably (and does, or this wouldn't be here) be called during incubation, so let's just... not cause errors
        let slotItem = slotRepeater.itemAt(index);
        if (slotItem) {
            slotItem.switchToThisSlot(onlyFocus);
        }
    }

    QtObject {
        id: _private
        readonly property string className: slotTypeToClassName(control.slotType)
        function classNameToSlotType(className) {
            switch(className) {
                case "TracksBar_synthslot":
                    return "synth";
                case "TracksBar_sampleslot":
                    return "sample-trig";
                case "TracksBar_sketchslot":
                    return "sample-loop";
                case "TracksBar_fxslot":
                    return "fx";
                case "TracksBar_externalslot":
                    return "external";
                default:
                    return "unknown-className:%1".arg(className);
            }
        }
        function slotTypeToClassName(slotType) {
            switch(slotType) {
                case "synth":
                    return "TracksBar_synthslot";
                case "sample-trig":
                    return "TracksBar_sampleslot";
                case "sample-loop":
                    return "TracksBar_sketchslot";
                case "fx":
                    return "TracksBar_fxslot";
                case "external":
                    return "TracksBar_fxslot";
                default:
                    return "unknown-slotType:%1".arg(slotType);
            }
        }
    }

    Repeater {
        id: slotRepeater

        model: Zynthbox.Plugin.sketchpadSlotCount
        delegate: Rectangle {
            id: slotDelegate
            property bool highlighted: root.selectedChannel.selectedSlotRow === index
            property int slotIndex: index
            property bool isSketchpadClip: control.slotData[index] != null && control.slotData[index].hasOwnProperty("className") && control.slotData[index].className == "sketchpad_clip"
            property QtObject clip: isSketchpadClip ? control.slotData[index] : null
            property QtObject cppClipObject: isSketchpadClip ? Zynthbox.PlayGridManager.getClipById(control.slotData[index].cppObjId) : null

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            //                                        border.color: highlighted ? Kirigami.Theme.highlightColor : "transparent"
            //                                        border.width: 2
            color: "transparent"
            radius: 4

            function switchToThisSlot(onlyFocus=false) {
                if (zynqtgui.sketchpad.lastSelectedObj.component != slotDelegate || onlyFocus) {
                    switch (control.slotType) {
                        case "synth":
                            zynqtgui.sketchpad.lastSelectedObj.className = "TracksBar_synthslot";
                            root.selectedChannel.displayFx = false;
                            break;
                        case "sample-trig":
                            zynqtgui.sketchpad.lastSelectedObj.className = "TracksBar_sampleslot";
                            root.selectedChannel.displayFx = false;
                            break;
                        case "sample-loop":
                            zynqtgui.sketchpad.lastSelectedObj.className = "TracksBar_sketchslot";
                            root.selectedChannel.displayFx = false;
                            break;
                        case "external":
                            zynqtgui.sketchpad.lastSelectedObj.className = "TracksBar_externalslot";
                            root.selectedChannel.displayFx = false;
                            break;
                        case "fx":
                            zynqtgui.sketchpad.lastSelectedObj.className = "TracksBar_fxslot";
                            root.selectedChannel.displayFx = true;
                            break;
                        default:
                            console.log("Unknown slot type, assuming synth, will likely break something! The unknown slot type is:", control.slotType);
                            zynqtgui.sketchpad.lastSelectedObj.className = "TracksBar_synthslot";
                            root.selectedChannel.displayFx = false;
                            break;
                    }
                    zynqtgui.sketchpad.lastSelectedObj.value = index;
                    zynqtgui.sketchpad.lastSelectedObj.component = slotDelegate;
                    root.selectedChannel.selectedSlotRow = index;
                    // zynqtgui.bottomBarControlType = "bottombar-controltype-pattern";
                    // zynqtgui.bottomBarControlObj = root.selectedChannel.getClipsModelById(root.selectedChannel.selectedSlotRow).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex);
                } else {
                    if (control.slotType === "external") {
                        // If channel type is external, then it has 2 slots visible
                        // and the respective selectedSlotRow is already selected. Hence directly handle item click
                        if (!onlyFocus) {
                            bottomStack.slotsBar.handleItemClick(control.slotType)
                        }
                    } else {
                        // For synth, handle item click only if not dragged. For other cases handle click immediately
                        if ((control.slotType == "synth" && !delegateMouseArea.dragHappened) || control.slotType != "synth") {
                            if (!onlyFocus) {
                                bottomStack.slotsBar.handleItemClick(control.slotType)
                            }
                        }
                    }
                }
                root.selectedChannel.selectedSlot.setTo(zynqtgui.sketchpad.lastSelectedObj.className, index, slotDelegate);

                if (control.slotType == "synth") {
                    root.selectedChannel.setCurlayerByType("synth")
                } else if (control.slotType == "sample-trig") {
                    root.selectedChannel.setCurlayerByType("sample")
                } else if (control.slotType == "sample-loop") {
                    root.selectedChannel.setCurlayerByType("loop")
                } else if (control.slotType == "external") {
                    root.selectedChannel.setCurlayerByType("external")
                } else if (control.slotType == "fx") {
                    root.selectedChannel.setCurlayerByType("fx")
                } else {
                    root.selectedChannel.setCurlayerByType("")
                }
            }

            Rectangle {
                id: delegate
                property int midiChannel: root.selectedChannel.chainedSounds[index]
                property QtObject synthPassthroughClient: Zynthbox.Plugin.synthPassthroughClients[delegate.midiChannel] ? Zynthbox.Plugin.synthPassthroughClients[delegate.midiChannel] : null
                property QtObject fxPassthroughClient: Zynthbox.Plugin.fxPassthroughClients[root.selectedChannel.id] ? Zynthbox.Plugin.fxPassthroughClients[root.selectedChannel.id][index] : null

                anchors.fill: parent
                anchors.margins: 4
                Kirigami.Theme.inherit: false
                Kirigami.Theme.colorSet: Kirigami.Theme.Button
                color: Kirigami.Theme.backgroundColor
                border.color: control.slotType === "sample-loop" && control.slotData[index].enabled ? Kirigami.Theme.highlightColor :"#ff999999"
                border.width: 2
                radius: 4
                // For external mode the first two slots are visible
                // For other modes all slots are visible
                enabled: (control.slotType !== "external") ||
                (control.slotType === "external" && (index === 0 || index === 1))
                opacity: enabled ? 1 : 0
                visible: enabled

                Rectangle {
                    anchors {
                        fill: parent
                        margins: -4
                    }
                    opacity: root.selectedChannel.selectedSlot.component === slotDelegate ? 0.8 : 0
                    color: "transparent"
                    border {
                        width: 2
                        color: "white"
                    }
                }
                Item {
                    id: slotDelegateVisualsContainer
                    anchors {
                        fill: parent
                        margins: Kirigami.Units.smallSpacing
                    }
                    Rectangle {
                        width: delegate.synthPassthroughClient ? parent.width * delegate.synthPassthroughClient.dryGainHandler.gainAbsolute : 0
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                        }
                        radius: 4
                        opacity: 0.8
                        visible: control.slotType === "synth" && synthNameLabel.text.trim().length > 0
                        color: Kirigami.Theme.highlightColor
                    }
                    Rectangle {
                        width: slotDelegate.cppClipObject ? parent.width * slotDelegate.cppClipObject.rootSlice.gainHandler.gainAbsolute : 0
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                        }
                        radius: 4
                        opacity: 0.8
                        visible: slotDelegate.cppClipObject
                        color: Kirigami.Theme.highlightColor
                    }
                    Rectangle {
                        // dryWetMixAmount ranges from 0 to 2. Interpolate it to range 0 to 1 to be able to calculate width of progress bar
                        width: delegate.fxPassthroughClient && delegate.fxPassthroughClient.dryWetMixAmount >= 0 ? delegate.width * Zynthian.CommonUtils.interp(delegate.fxPassthroughClient.dryWetMixAmount, 0, 2, 0, 1) : 0
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                        }
                        radius: 4
                        opacity: 0.8
                        visible: control.slotType === "fx" && control.slotData[index] != null && control.slotData[index].length > 0
                        color: Kirigami.Theme.highlightColor
                    }

                    property int availableWidth: width - 6
                    Rectangle {
                        anchors {
                            top: parent.top
                            left: parent.left
                            leftMargin: 3 // because of the radius of the rectangles we're "inside"
                        }
                        height: 1
                        color: slotDelegate.cppClipObject && slotDelegate.cppClipObject.playbackPositions && slotDelegate.cppClipObject.playbackPositions.peakGainLeft > 1 ? "red" : "white"
                        opacity: width > 1 ? 0.8 : 0
                        width: slotDelegate.cppClipObject && slotDelegate.cppClipObject.playbackPositions ? Math.min(slotDelegateVisualsContainer.availableWidth, slotDelegate.cppClipObject.playbackPositions.peakGainLeft * slotDelegateVisualsContainer.availableWidth) : 0
                    }
                    Rectangle {
                        anchors {
                            left: parent.left
                            bottom: parent.bottom
                            bottomMargin: -1 // Because anchoring is weird and we want it to skirt the bottom of the blue bubbles...
                            leftMargin: 3 // because of the radius of the rectangles we're "inside"
                        }
                        height: 1
                        color: slotDelegate.cppClipObject && slotDelegate.cppClipObject.playbackPositions && slotDelegate.cppClipObject.playbackPositions.peakGainRight > 1 ? "red" : "white"
                        opacity: width > 1 ? 0.8 : 0
                        width: slotDelegate.cppClipObject && slotDelegate.cppClipObject.playbackPositions ? Math.min(slotDelegateVisualsContainer.availableWidth, slotDelegate.cppClipObject.playbackPositions.peakGainRight * slotDelegateVisualsContainer.availableWidth) : 0
                    }
                }

                QQC2.Label {
                    id: synthNameLabel
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        right: parent.right
                        leftMargin: Kirigami.Units.gridUnit*0.5
                        rightMargin: Kirigami.Units.gridUnit*0.5
                    }
                    horizontalAlignment: Text.AlignLeft
                    text: {
                        if (control.slotType === "synth" && control.slotData[index] != null) {
                            return control.slotData[index]
                        } else if ((control.slotType === "sample-trig" || control.slotType === "sample-loop") && control.slotData[index] && control.slotData[index].path) {
                            return control.slotData[index].path.split("/").pop()
                        } else if (control.slotType === "external" && index < 2) {
                            return control.slotData[index]
                        } else if (control.slotType === "fx" && control.slotData[index] != null ) {
                            return control.slotData[index]
                        } else {
                            return ""
                        }
                    }
                    elide: "ElideRight"
                }

                MouseArea {
                    id: delegateMouseArea
                    property real initialMouseX
                    property bool dragHappened: false

                    anchors.fill: parent
                    onPressed: {
                        delegateMouseArea.initialMouseX = mouse.x
                    }
                    onReleased: {
                        dragHappenedResetTimer.restart()
                    }
                    onClicked: slotDelegate.switchToThisSlot()
                    onMouseXChanged: {
                        var newVal
                        if (control.slotType === "synth" && root.selectedChannel.checkIfLayerExists(delegate.midiChannel) && mouse.x - delegateMouseArea.initialMouseX != 0) {
                            newVal = Zynthian.CommonUtils.clamp(mouse.x / delegate.width, 0, 1);
                            delegateMouseArea.dragHappened = true;
                            let synthPassthroughClient = Zynthbox.Plugin.synthPassthroughClients[delegate.midiChannel]
                            synthPassthroughClient.dryGainHandler.gainAbsolute = newVal;
                        } else if (control.slotType == "sample-trig" && control.slotData[index] != null && mouse.x - delegateMouseArea.initialMouseX != 0) {
                            newVal = Zynthian.CommonUtils.clamp(mouse.x / delegate.width, 0, 1);
                            delegateMouseArea.dragHappened = true;
                            slotDelegate.cppClipObject.rootSlice.gainHandler.gainAbsolute = newVal;
                        } else if (control.slotType == "fx" && control.slotData[index] != null && control.slotData[index].length > 0 && mouse.x - delegateMouseArea.initialMouseX != 0) {
                            newVal = Zynthian.CommonUtils.clamp(mouse.x / delegate.width, 0, 1);
                            delegateMouseArea.dragHappened = true;
                            // dryWetMixAmount ranges from 0 to 2. Interpolate newVal to range from 0 to 1 to 0 to 2
                            root.selectedChannel.set_passthroughValue("fxPassthrough", index, "dryWetMixAmount", Zynthian.CommonUtils.interp(newVal, 0, 1, 0, 2));
                        }
                    }
                    onPressAndHold: {
                        if (!delegateMouseArea.dragHappened) {
                            if (control.slotType === "sample-loop") {
                                // If channel type is sample-loop open clip wave editor
                                if (waveformContainer.clip && !waveformContainer.clip.isEmpty) {
                                    zynqtgui.bottomBarControlType = "bottombar-controltype-clip";
                                    zynqtgui.bottomBarControlObj = waveformContainer.clip;
                                    bottomStack.slotsBar.bottomBarButton.checked = true;
                                    Qt.callLater(function() {
                                        bottomStack.bottomBar.waveEditorAction.trigger();
                                    })
                                }
                            } else if (control.slotType.startsWith("sample")) {
                                // If channel type is sample then open channel wave editor
                                if (waveformContainer.clip && !waveformContainer.clip.isEmpty) {
                                    zynqtgui.bottomBarControlType = "bottombar-controltype-channel";
                                    zynqtgui.bottomBarControlObj = root.selectedChannel;
                                    bottomStack.slotsBar.bottomBarButton.checked = true;
                                    Qt.callLater(function() {
                                        bottomStack.bottomBar.channelWaveEditorAction.trigger();
                                    })
                                }
                            } else if (control.slotType === "synth") {
                                // If channel type is synth open synth edit page
                                if (root.selectedChannel.checkIfLayerExists(root.selectedChannel.chainedSounds[index])) {
                                    zynqtgui.fixed_layers.activate_index(root.selectedChannel.chainedSounds[index])
                                    zynqtgui.control.single_effect_engine = null;
                                    zynqtgui.current_screen_id = "control";
                                    zynqtgui.forced_screen_back = "sketchpad"
                                }
                            }
                        }
                    }
                    Timer {
                        id: dragHappenedResetTimer
                        interval: 100
                        repeat: false
                        onTriggered: {
                            delegateMouseArea.dragHappened = false
                        }
                    }
                }
            }
        }
    }
}
