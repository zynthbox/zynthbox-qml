import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Qt.labs.folderlistmodel 2.11

import Zynthian 1.0 as Zynthian
import org.zynthian.quick 1.0 as ZynQuick
import JuceGraphics 1.0

ColumnLayout {
    id: root
    property QtObject channel
    // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the component, which is very slow
    property QtObject sequence: zynthian.isBootingComplete ? ZynQuick.PlayGridManager.getSequenceModel(zynthian.sketchpad.song.scenesModel.selectedSketchName) : null
    property QtObject selectedPartClip
    property QtObject selectedPartPattern
    property bool songMode: zynthian.sketchpad.song.mixesModel.songMode

    signal clicked()

    spacing: 1

    Repeater {
        model: root.channel && root.sequence ? 5 : 0
        delegate: Rectangle {
            id: partDelegate
            property int partIndex: index
            property QtObject pattern: root.sequence.getByPart(root.channel.id, model.index)
            property QtObject clip: root.channel.getClipsModelByPart(partDelegate.partIndex).getClip(zynthian.sketchpad.song.scenesModel.selectedSketchIndex)
            property bool clipHasWav: partDelegate.clip && partDelegate.clip.path && partDelegate.clip.path.length > 0

            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#000000"
            border{
                color: Kirigami.Theme.highlightColor
                width: root.songMode
                        ? zynthian.sketchpad.song.mixesModel.selectedMix.segmentsModel.selectedSegment.clips.indexOf(partDelegate.clip) >= 0
                            ? 1
                            : 0
                        : partDelegate.clip && partDelegate.clip.inCurrentScene
                            ? 1
                            : 0
            }
            WaveFormItem {
                anchors.fill: parent
                color: Kirigami.Theme.textColor
                source: partDelegate.clip ? partDelegate.clip.path : ""

                visible: root.visible && root.channel.channelAudioType === "sample-loop" &&
                         partDelegate.clipHasWav
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
                font.pointSize: 8
                visible: ["sample-trig", "sample-slice", "synth", "external"].indexOf(root.channel.channelAudioType) >= 0
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
                anchors.fill: parent
                onClicked: {
                    if (root.songMode) {
                        zynthian.sketchpad.song.mixesModel.selectedMix.segmentsModel.selectedSegment.toggleClip(partDelegate.clip)
                    } else {
                        partDelegate.clip.enabled = !partDelegate.clip.enabled;
                        root.channel.selectedPart = index;

                        root.selectedPartClip = partDelegate.clip
                        root.selectedPartPattern = partDelegate.pattern
                    }

                    root.clicked()
                }
                onPressAndHold: {
                    partDelegate.clip.enabled = true;
                    root.channel.selectedPart = index;

                    bottomStack.bottomBar.controlType = BottomBar.ControlType.Pattern;
                    bottomStack.bottomBar.controlObj = root.channel.sceneClip;
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
