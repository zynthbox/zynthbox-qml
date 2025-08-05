import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.6 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

GridLayout {
    id: control
    /**
      * An array of 5 elements containing data that needs to be displayed on the slots
      * This data will vary depending upon which type of data is to be displayed which is supplied via
      * slotType property. The main purpose of these properties are to use the existing logic to display slots data into same slots
      * but instead of the data depending on trackType, it is explicitly set by slotType
      *
      * slotData values can be any of synthSlotsData, sampleSlotsData, sketchSlotsData, externalSlotsData, fxSlotsData, sketchFxSlotsData or an array of 5 strings for slotType "text"
      */
    property var slotData: []
    /**
      * Type of data that needs to be displayed. It should be "synth" for synthSlotsData, "sample-trig" for sampleSlotsData
      * "sample-loop" for sketchSlotsData, "external" for externalSlotsData, "fx" for fxSlotsData "sketch-fx" for sketchFxSlotsData.
      * For displaying simple text in slot data use "text" as slot Type
      * Allowed values : "synth", "sample-trig", "sample-loop", "external", "text", "sketch-fx"
      */
    property string slotType
    /**
      * When set to true, it will display the slotTypeLabel before the slots
      * If slotTypeLabel is not defined it will generate a label based on slot type
      * Default : false
      */
    property bool showSlotTypeLabel: false
    /**
      * slotTypeLabel will be displayed before the slots when showSlotTypeLabel is set to true
      * If slotTypeLabel is not set, a label will be generated based on trackType
      */
    property string slotTypeLabel: ""
    /**
     * \brief If set to false, we will not perform the normal slot type interactions, and only emit the slotClicked(index) signal
     */
    property bool performSlotInteractions: true
    /**
     * \brief If set to false, the slot will not use the currentSlot value to highlight whatever the currently selected slot for the track is
     */
    property bool highlightCurrentlySelectedSlot: true
    /**
     * \brief Allow setting the orientation of the layout
     */
    property int orientation: Qt.Horizontal
    /**
     * \brief Set the channel that TrackSlotsData should operate on
     */
    property QtObject channel: applicationWindow().selectedChannel
    /**
     * \brief Set to true if single click action should happen after focus
     */
    property bool singleClickEnabled: true
    /**
     * \brief Set to true if click and hold action should happen
     */
    property bool clickAndHoldEnabled: true
    /**
     * \brief Set to true if double click action should happen
     */
    property bool doubleClickEnabled: true
    /**
     * \brief Set to true if drag action should happen
     */
    property bool dragEnabled: true

    rows: {
        if (control.orientation == Qt.Horizontal) {
            return 1
        } else if (control.orientation == Qt.Vertical) {
            return Zynthbox.Plugin.sketchpadSlotCount + (control.showSlotTypeLabel ? 1 : 0) // +1 row for label if label is visible
        } else {
            return 1 // Fallback to horizontal
        }
    }
    columns: {
        if (control.orientation == Qt.Horizontal) {
            return Zynthbox.Plugin.sketchpadSlotCount + (control.showSlotTypeLabel ? 1 : 0) // +1 col for label if label is visible
        } else if (control.orientation == Qt.Vertical) {
            return 1
        } else {
            return Zynthbox.Plugin.sketchpadSlotCount + (control.showSlotTypeLabel ? 1 : 0) // Fallback to horizontal
        }
    }
    flow: {
        if (control.orientation == Qt.Horizontal) {
            return GridLayout.LeftToRight
        } else if (control.orientation == Qt.Vertical) {
            return GridLayout.TopToBottom
        } else {
            return GridLayout.LeftToRight // Fallback to horizontal
        }
    }
    layoutDirection: Qt.LeftToRight

    /**
     * \brief Emitted whenever the user clicks on the slot
     * @param index The index of the slot which was clicked on
     */
    signal slotClicked(int index)
    /**
      * Emulate a click to slot at specified index
      */
    function switchToSlot(index, onlyFocus=false, onlySelectSlot=false) {
        // This function may conceivably (and does, or this wouldn't be here) be called during incubation, so let's just... not cause errors
        let slotItem = slotRepeater.itemAt(index);
        if (slotItem) {
            slotItem.switchToThisSlot(onlyFocus, onlySelectSlot);
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
                case "TracksBar_sketchfxslot":
                    return "sketch-fx";
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
                case "sketch-fx":
                    return "TracksBar_sketchfxslot";
                case "external":
                    return "TracksBar_externalslot";
                default:
                    return "unknown-slotType:%1".arg(slotType);
            }
        }
    }

    QQC2.Label {
        Layout.fillWidth: false
        Layout.fillHeight: true
        Layout.preferredWidth: Kirigami.Units.gridUnit * 4
        horizontalAlignment: Qt.AlignRight
        verticalAlignment: Qt.AlignVCenter
        visible: control.showSlotTypeLabel
        // font.bold: true
        fontSizeMode: Text.Fit
        minimumPointSize: 6
        wrapMode: Text.NoWrap
        font.pointSize: 11
        text: {
            if (control.slotTypeLabel == "") {
                switch (control.slotType) {
                    case "synth":
                        return qsTr("Synths :")
                    case "sample-trig":
                        return qsTr("Samples :")
                    case "sample-loop":
                        return qsTr("Sketches :")
                    case "external":
                        return qsTr("Settings :")
                    case "fx":
                        return qsTr("FX :")
                    case "sketch-fx":
                        return qsTr("FX :")
                    case "text":
                        return qsTr("")
                }
            } else {
                return control.slotTypeLabel
            }
        }
    }

    Repeater {
        id: slotRepeater

        model: Zynthbox.Plugin.sketchpadSlotCount
        delegate: QQC2.Control {
            id: slotDelegate
            property bool highlighted: zynqtgui.sketchpad.lastSelectedObj != null && zynqtgui.sketchpad.lastSelectedObj.track == control.channel && zynqtgui.sketchpad.lastSelectedObj.className == _private.className && zynqtgui.sketchpad.lastSelectedObj.value === index
            property int slotIndex: index
            property bool isSketchpadClip: control.slotData && control.slotData[index] != null && control.slotData[index].hasOwnProperty("className") && control.slotData[index].className == "sketchpad_clip"
            property QtObject clip: isSketchpadClip ? control.slotData[index] : null
            property QtObject cppClipObject: isSketchpadClip ? Zynthbox.PlayGridManager.getClipById(control.slotData[index].cppObjId) : null
            // A property to determine if slot is a sample-loop and is enabled
            property bool isClipEnabled: control.slotType === "sample-loop" && control.slotData[index] && control.slotData[index].enabled
            property int midiChannel: control.channel != null ? control.channel.chainedSounds[index] : -1
            property QtObject synthPassthroughClient: control.channel != null && Zynthbox.Plugin.synthPassthroughClients[slotDelegate.midiChannel] != null ? Zynthbox.Plugin.synthPassthroughClients[slotDelegate.midiChannel] : null
            property QtObject fxPassthroughClient: control.channel != null && Zynthbox.Plugin.fxPassthroughClients[control.channel.id] != null ? Zynthbox.Plugin.fxPassthroughClients[control.channel.id][index] : null
            property QtObject sketchFxPassthroughClient: control.channel != null && Zynthbox.Plugin.sketchFxPassthroughClients[control.channel.id] != null ? Zynthbox.Plugin.sketchFxPassthroughClients[control.channel.id][index] : null
            property QtObject zynthianLayer: {
                let layer = null;
                if (control.channel != null) {
                    switch (_private.className) {
                    case "TracksBar_synthslot":
                        let midiChannel = control.channel.chainedSounds[index];
                        if (midiChannel >= 0 && control.channel.checkIfLayerExists(midiChannel)) {
                            layer = zynqtgui.layer.get_layer_by_midi_channel(midiChannel)
                        }
                        break;
                    case "TracksBar_fxslot":
                        layer = control.channel.chainedFx[index];
                        break;
                    case "TracksBar_sketchfxslot":
                        layer = control.channel.chainedSketchFx[index];
                        break;
                    }
                    if (layer == undefined) {
                        layer = null;
                    }
                }
                return layer;
            }
            // This property will be used to determine if a slot makes sound
            // For synth slots, this will be true if not muted
            // For fx slots, this will be true if not bypassed
            property bool slotMakesSound: {
                if (slotDelegate.zynthianLayer != null && _private.className == "TracksBar_synthslot" && slotDelegate.synthPassthroughClient != null) {
                    return !slotDelegate.synthPassthroughClient.muted
                } else if (slotDelegate.zynthianLayer != null && _private.className == "TracksBar_fxslot" && slotDelegate.fxPassthroughClient != null) {
                    return !slotDelegate.fxPassthroughClient.bypass
                } else if (_private.className == "TracksBar_sampleslot" && slotDelegate.cppClipObject != null) {
                    return !slotDelegate.cppClipObject.rootSlice.gainHandler.muted
                } else {
                    // For all other cases, default value is true
                    return true
                }
            }

            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            opacity: slotMakesSound ? 1 : 0.3
            background: Item {
                // Show highlighted color on slot border when slot is a sample-loop and is enabled
                Rectangle {
                    visible: !svgBg.visible
                    anchors.fill: parent
                    Kirigami.Theme.inherit: false
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    color: Kirigami.Theme.backgroundColor
                    border.color: slotDelegate.isClipEnabled ? Kirigami.Theme.highlightColor : "#ff999999"
                    border.width: 2
                    radius: 4
                }
                PlasmaCore.FrameSvgItem {
                    id: svgBg
                    anchors.fill: parent
                    visible: fromCurrentTheme

                    readonly property real leftPadding: margins.left
                    readonly property real rightPadding: margins.right
                    readonly property real topPadding: margins.top
                    readonly property real bottomPadding: margins.bottom

                    imagePath: "widgets/slots-delegate-background"
                    prefix: slotDelegate.isClipEnabled ? ["focus", ""] : ""
                    colorGroup: PlasmaCore.Theme.ButtonColorGroup
                }
            }

            function switchToThisSlot(onlyFocus=false, onlySelectSlot=false) {
                if (control.performSlotInteractions) {
                    if (!control.singleClickEnabled) {
                        // If single click is disable, set onlyFocus to true so that clicks are not passed to slotsBar to handle popups
                        onlyFocus = true;
                    }

                    let wasAlreadySelected = slotDelegate.highlighted
                    control.channel.selectedSlot.setTo(_private.className, index, slotDelegate, control.channel);
                    if (onlySelectSlot == false) {
                        if (wasAlreadySelected == false || onlyFocus) {
                            let className = "TracksBar_synthslot"
                            switch (control.slotType) {
                            case "synth":
                                className = "TracksBar_synthslot";
                                break;
                            case "sample-trig":
                                className = "TracksBar_sampleslot";
                                break;
                            case "sample-loop":
                                className = "TracksBar_sketchslot";
                                break;
                            case "external":
                                className = "TracksBar_externalslot";
                                break;
                            case "fx":
                                className = "TracksBar_fxslot";
                                break;
                            case "sketch-fx":
                                className = "TracksBar_sketchfxslot";
                                break;
                            case "text":
                                // Do nothing for text slots
                                break;
                            default:
                                console.log("Unknown slot type, assuming synth, will likely break something! The unknown slot type is:", control.slotType);
                                control.channel.displayFx = false;
                                break;
                            }
                            zynqtgui.sketchpad.lastSelectedObj.setTo(className, index, slotDelegate, control.channel);
                            control.channel.selectedSlotRow = index;
                        } else {
                            if (control.slotType === "external") {
                                // If channel type is external, then it has 2 slots visible
                                // and the respective selectedSlotRow is already selected. Hence directly handle item click
                                if (!onlyFocus) {
                                    pageManager.getPage("sketchpad").bottomStack.slotsBar.handleItemClick(control.slotType);
                                }
                            } else {
                                // Handle item click only if not dragged
                                if (!delegateMouseArea.dragHappened && !onlyFocus) {
                                    pageManager.getPage("sketchpad").bottomStack.slotsBar.handleItemClick(control.slotType);
                                }
                            }
                        }
                        // FIXME This needs refactoring away... everything should be using the selectedSlot logic instead
                        control.channel.selectedSlotRow = index;
                        control.channel.selectedFxSlotRow = index;

                        if (control.slotType == "synth") {
                            control.channel.setCurlayerByType("synth")
                        } else if (control.slotType == "sample-trig") {
                            control.channel.setCurlayerByType("sample")
                        } else if (control.slotType == "sample-loop") {
                            control.channel.setCurlayerByType("loop")
                        } else if (control.slotType == "external") {
                            control.channel.setCurlayerByType("external")
                        } else if (control.slotType == "fx") {
                            control.channel.setCurlayerByType("fx")
                        } else if (control.slotType == "sketch-fx") {
                            control.channel.setCurlayerByType("sketch-fx")
                        } else if (control.slotType == "text") {
                            // Do nothing for text slots
                        } else {
                            control.channel.setCurlayerByType("")
                        }
                    }
                }
                control.slotClicked(slotDelegate.slotIndex);
            }

            contentItem: Item {
                id: delegate

                // For external mode the first three slots are visible
                // For other modes all slots are visible
                enabled: (control.slotType !== "external") || (control.slotType === "external" && (index === 0 || index === 1 || index === 2))
                opacity: enabled ? 1 : 0
                visible: enabled
                readonly property bool isSelectedSlot: control.channel != null && control.channel.selectedSlot.className === _private.className && control.channel.selectedSlot.value === slotDelegate.slotIndex
                Item {
                    id: slotDelegateVisualsContainer
                    anchors {
                        fill: parent
                        margins: Kirigami.Units.smallSpacing
                    }
                    visible: control.dragEnabled
                    Rectangle {
                        width: slotDelegate.synthPassthroughClient ? parent.width * slotDelegate.synthPassthroughClient.dryGainHandler.gainAbsolute : 0
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
                        width: slotDelegate.fxPassthroughClient && slotDelegate.fxPassthroughClient.dryWetMixAmount >= 0 ? parent.width * Zynthian.CommonUtils.interp(slotDelegate.fxPassthroughClient.dryWetMixAmount, 0, 2, 0, 1) : 0
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
                    Rectangle {
                        // dryWetMixAmount ranges from 0 to 2. Interpolate it to range 0 to 1 to be able to calculate width of progress bar
                        width: slotDelegate.sketchFxPassthroughClient && slotDelegate.sketchFxPassthroughClient.dryWetMixAmount >= 0 ? parent.width * Zynthian.CommonUtils.interp(slotDelegate.sketchFxPassthroughClient.dryWetMixAmount, 0, 2, 0, 1) : 0
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                        }
                        radius: 4
                        opacity: 0.8
                        visible: control.slotType === "sketch-fx" && control.slotData[index] != null && control.slotData[index].length > 0
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
                        if (control.slotData && control.slotData[index] != null) {
                            if (control.slotType === "synth") {
                                return control.slotData[index]
                            } else if ((control.slotType === "sample-trig" || control.slotType === "sample-loop")) {
                                if (slotDelegate.cppClipObject && slotDelegate.cppClipObject.sourceExists === false) {
                                    return "Missing: %1".arg(control.slotData[index].title ? control.slotData[index].title : "");
                                } else {
                                    return control.slotData[index].title ? control.slotData[index].title : ""
                                }
                            } else if (control.slotType === "external") {
                                return index < 3 ? control.slotData[index] : ""
                            } else if (control.slotType === "fx") {
                                return control.slotData[index]
                            } else if (control.slotType === "sketch-fx") {
                                return control.slotData[index]
                            } else if (control.slotType === "text") {
                                if (typeof control.slotData[index] === "string") {
                                    return control.slotData[index]
                                } else {
                                    return control.slotData[index].toString();
                                }
                            } else {
                                return ""
                            }
                        } else {
                            return ""
                        }
                    }
                    elide: control.slotType === "sample-trig" && slotDelegate.cppClipObject && slotDelegate.cppClipObject.sourceExists === false ? Text.ElideLeft : Text.ElideRight
                    color: slotDelegate.cppClipObject && slotDelegate.cppClipObject.sourceExists === false ? "red" : Kirigami.Theme.textColor
                }

                // Implement a double tap gesture
                // On released event, start the double tap timer if it is not already running
                // On pressed event, if the timer is already running then it means the 2nd tap was done within given time and hence a double tap event should be emitted
                // On pressed event, if the timer is not running then it means it is the first click. Dont do anything as released handler will start the double tap timer
                Timer {
                    id: doublePressedTimer
                    interval: zynqtgui.ui_settings.doubleClickThreshold
                    repeat: false
                    onTriggered: {
                        if (!delegateMouseArea.dragHappened) {
                            slotDelegate.switchToThisSlot();
                        }
                    }
                }

                MouseArea {
                    id: delegateMouseArea
                    property real initialMouseX
                    property bool dragHappened: false

                    anchors.fill: parent
                    onPressed: {
                        if (control.dragEnabled) {
                            delegateMouseArea.initialMouseX = mouse.x
                        }
                    }
                    onReleased: {
                        if (control.dragEnabled) {
                            dragHappenedResetTimer.restart();
                        }
                        if (control.doubleClickEnabled) {
                            if (doublePressedTimer.running) {
                                doublePressedTimer.stop();
                                // Double press has happened. Toggle mute/bypass state the slot
                                switch (control.slotType) {
                                    case "synth":
                                        if (slotDelegate.synthPassthroughClient) {
                                            slotDelegate.synthPassthroughClient.muted = !slotDelegate.synthPassthroughClient.muted;
                                        }
                                        break;
                                    case "sample-trig":
                                        if (slotDelegate.cppClipObject) {
                                            slotDelegate.cppClipObject.rootSlice.gainHandler.muted = !slotDelegate.cppClipObject.rootSlice.gainHandler.muted;
                                        }
                                        break;
                                    case "fx":
                                        if (slotDelegate.fxPassthroughClient) {
                                            slotDelegate.fxPassthroughClient.bypass = !slotDelegate.fxPassthroughClient.bypass;
                                        }
                                        break;
                                }
                            } else {
                                doublePressedTimer.restart();
                            }
                        } else {
                            slotDelegate.switchToThisSlot();
                        }
                    }
                    onMouseXChanged: {
                        if (control.dragEnabled) {
                            var newVal
                            if (control.slotType === "synth" && control.channel.checkIfLayerExists(slotDelegate.midiChannel) && mouse.x - delegateMouseArea.initialMouseX != 0) {
                                newVal = Zynthian.CommonUtils.clamp(mouse.x / delegate.width, 0, 1);
                                delegateMouseArea.dragHappened = true;
                                let synthPassthroughClient = Zynthbox.Plugin.synthPassthroughClients[slotDelegate.midiChannel]
                                synthPassthroughClient.dryGainHandler.gainAbsolute = newVal;
                            } else if (control.slotType == "sample-trig" && control.slotData[index] != null && mouse.x - delegateMouseArea.initialMouseX != 0) {
                                newVal = Zynthian.CommonUtils.clamp(mouse.x / delegate.width, 0, 1);
                                delegateMouseArea.dragHappened = true;
                                slotDelegate.cppClipObject.rootSlice.gainHandler.gainAbsolute = newVal;
                            } else if (control.slotType == "fx" && control.slotData[index] != null && control.slotData[index].length > 0 && mouse.x - delegateMouseArea.initialMouseX != 0) {
                                newVal = Zynthian.CommonUtils.clamp(mouse.x / delegate.width, 0, 1);
                                delegateMouseArea.dragHappened = true;
                                // dryWetMixAmount ranges from 0 to 2. Interpolate newVal to range from 0 to 1 to 0 to 2
                                control.channel.set_passthroughValue("fxPassthrough", index, "dryWetMixAmount", Zynthian.CommonUtils.interp(newVal, 0, 1, 0, 2));
                            } else if (control.slotType == "sketch-fx" && control.slotData[index] != null && control.slotData[index].length > 0 && mouse.x - delegateMouseArea.initialMouseX != 0) {
                                newVal = Zynthian.CommonUtils.clamp(mouse.x / delegate.width, 0, 1);
                                delegateMouseArea.dragHappened = true;
                                // dryWetMixAmount ranges from 0 to 2. Interpolate newVal to range from 0 to 1 to 0 to 2
                                control.channel.set_passthroughValue("sketchFxPassthrough", index, "dryWetMixAmount", Zynthian.CommonUtils.interp(newVal, 0, 1, 0, 2));
                            }
                        }
                    }
                    onPressAndHold: {
                        if (!delegateMouseArea.dragHappened && control.clickAndHoldEnabled) {
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
                                    zynqtgui.bottomBarControlObj = control.channel;
                                    bottomStack.slotsBar.bottomBarButton.checked = true;
                                    Qt.callLater(function() {
                                        bottomStack.bottomBar.channelWaveEditorAction.trigger();
                                    })
                                }
                            } else if (control.slotType === "synth") {
                                // If channel type is synth open synth edit page
                                if (control.channel.checkIfLayerExists(control.channel.chainedSounds[index])) {
                                    zynqtgui.fixed_layers.activate_index(control.channel.chainedSounds[index])
                                    zynqtgui.control.single_effect_engine = null;
                                    zynqtgui.current_screen_id = "control";
                                    zynqtgui.forced_screen_back = "sketchpad"
                                }
                            }
                        }
                    }
                    Timer {
                        id: dragHappenedResetTimer
                        interval: 300
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
