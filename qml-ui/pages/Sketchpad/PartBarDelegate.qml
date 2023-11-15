import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Qt.labs.folderlistmodel 2.11

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

ColumnLayout {
    id: root
    property QtObject channel
    // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the component, which is very slow
    property QtObject sequence: zynqtgui.isBootingComplete ? Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedTrackName) : null
    property QtObject selectedPartClip
    property QtObject selectedPartPattern
    property QtObject selectedComponent
    // Set to true to make this operate on song bits
    property bool songMode: false

    signal clicked()
    function handleItemClick(index) {
        partRepeater.itemAt(index).handleItemClick()
    }

    spacing: 1

    Repeater {
        id: partRepeater
        model: root.channel && root.sequence ? 5 : 0
        delegate: Rectangle {
            id: partDelegate
            property int partIndex: index
            property QtObject pattern: root.sequence.getByPart(root.channel.id, model.index)
            property QtObject clip: root.channel.getClipsModelByPart(partDelegate.partIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedTrackIndex)
            property bool clipHasWav: partDelegate.clip && partDelegate.clip.path && partDelegate.clip.path.length > 0
            function handleItemClick() {
                if (root.songMode) {
                    zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegment.toggleClip(partDelegate.clip)
                } else {
                    partDelegate.clip.enabled = !partDelegate.clip.enabled;
                    root.channel.selectedPart = index;
                    root.channel.selectedSlotRow = index;

                    root.selectedPartClip = partDelegate.clip
                    root.selectedPartPattern = partDelegate.pattern
                    root.selectedComponent = partDelegate
                }

                root.clicked()
            }

            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#000000"
            border{
                color: root.songMode
                        ? zynqtgui.sketchpad.song.sketchesModel.selectedSketch.segmentsModel.selectedSegment.clips.indexOf(partDelegate.clip) >= 0
                            ? Kirigami.Theme.highlightColor
                            : "#000000"
                        : partDelegate.clip && partDelegate.clip.inCurrentScene
                            ? Kirigami.Theme.highlightColor
                            : "#000000"
                width: 1
            }
            Zynthbox.WaveFormItem {
                anchors.fill: parent
                color: Kirigami.Theme.textColor
                source: partDelegate.clip ? partDelegate.clip.path : ""

                visible: root.visible && root.channel.channelAudioType === "sample-loop" && partDelegate.clipHasWav
                // Progress line
                Rectangle {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                    }
                    property QtObject cppClipObject: parent.visible ? Zynthbox.PlayGridManager.getClipById(partDelegate.clip.cppObjId) : null;
                    visible: parent.visible && cppClipObject && cppClipObject.isPlaying
                    color: Kirigami.Theme.highlightColor
                    width: Kirigami.Units.smallSpacing
                    x: cppClipObject ? cppClipObject.position * parent.width : 0
                }
            }
            Image {
                anchors.fill: parent
                anchors.margins: 2
                smooth: false
                visible: root.visible && root.channel.channelAudioType !== "sample-loop" &&
                         partDelegate.pattern &&
                         partDelegate.pattern.hasNotes
                source: partDelegate.pattern ? partDelegate.pattern.thumbnailUrl : ""
                cache: false
                Rectangle {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                    }
                    visible: parent.visible && partDelegate.pattern ? partDelegate.pattern.isPlaying : false
                    color: Kirigami.Theme.highlightColor
                    property double widthFactor: root.visible && parent.visible && partDelegate.pattern ? parent.width / (partDelegate.pattern.width * partDelegate.pattern.bankLength) : 1
                    width: Math.max(1, Math.floor(widthFactor))
                    x: root.visible && parent.visible && partDelegate.pattern ? partDelegate.pattern.bankPlaybackPosition * widthFactor : 0
                }
            }
            QQC2.Label {
                anchors.centerIn: parent
                font.pointSize: 12
                visible: ["sample-loop", "sample-trig", "sample-slice", "synth", "external"].indexOf(root.channel.channelAudioType) >= 0
                text: qsTr("%1%2")
                        .arg(root.channel.id + 1)
                        .arg(String.fromCharCode(partDelegate.partIndex+65).toLowerCase())
            }
            Rectangle {
                height: 16
                anchors {
                    left: parent.left
                    top: parent.top
                    right: parent.right
                }
                color: "#99888888"
                visible: root.channel.channelAudioType === "sample-loop" &&
                         detailsLabel.text && detailsLabel.text.trim().length > 0

                QQC2.Label {
                    id: detailsLabel

                    anchors.centerIn: parent
                    width: parent.width - 4
                    elide: "ElideRight"
                    horizontalAlignment: "AlignHCenter"
                    font.pointSize: 8
                    text: root.visible ? partDelegate.clip.path.split("/").pop() : ""
                }
            }
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                onClicked: partDelegate.handleItemClick()
                onPressAndHold: {
                    partDelegate.clip.enabled = true;
                    root.channel.selectedPart = index;
                    root.channel.selectedSlotRow = index;

                    if (!root.songMode) {
                        zynqtgui.bottomBarControlType = "bottombar-controltype-pattern";
                        zynqtgui.bottomBarControlObj = root.channel.sceneClip;
                        bottomStack.slotsBar.bottomBarButton.checked = true;

                        if (root.channel.channelAudioType === "sample-loop") {
                            if (partDelegate.clipHasWav) {
                                bottomStack.bottomBar.waveEditorAction.trigger();
                            } else {
                                bottomStack.bottomBar.recordingAction.trigger();
                            }
                        } else {
                            bottomStack.bottomBar.patternAction.trigger();
                        }
                    }
                }
            }
        }
    }
}
