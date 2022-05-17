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
    property QtObject track
    property QtObject sequence: ZynQuick.PlayGridManager.getSequenceModel("Scene " + zynthian.zynthiloops.song.scenesModel.selectedSceneName)

    spacing: 1

    Repeater {
        model: 5
        delegate: Rectangle {
            id: partDelegate
            property int partIndex: index
            property QtObject pattern: root.sequence.getByPart(root.track.id, model.index)
            property QtObject clip: root.track.getClipsModelByPart(partDelegate.partIndex).getClip(zynthian.zynthiloops.selectedClipCol)

            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#000000"
            border{
                color: Kirigami.Theme.highlightColor
                width: (root.track.trackAudioType === "sample-loop" && root.track.selectedPart === partDelegate.partIndex) ||
                       (partDelegate.clip && partDelegate.clip.enabled)
                        ? 1
                        : 0
            }
            WaveFormItem {
                anchors.fill: parent
                color: Kirigami.Theme.textColor
                source: partDelegate.clip ? partDelegate.clip.path : ""

                visible: root.track.trackAudioType === "sample-loop" &&
                         partDelegate.clip && partDelegate.clip.path && partDelegate.clip.path.length > 0
            }
            Image {
                anchors.fill: parent
                anchors.margins: 2
                smooth: false
                visible: root.track.trackAudioType !== "sample-loop" &&
                         partDelegate.pattern &&
                         partDelegate.pattern.hasNotes
                source: partDelegate.pattern ? partDelegate.pattern.thumbnailUrl : ""
                cache: false
                Rectangle {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                    }
                    visible: partDelegate.pattern ? partDelegate.pattern.isPlaying : false
                    color: Kirigami.Theme.highlightColor
                    property double widthFactor: partDelegate.pattern ? parent.width / (partDelegate.pattern.width * partDelegate.pattern.bankLength) : 1
                    width: Math.max(1, Math.floor(widthFactor))
                    x: partDelegate.pattern ? partDelegate.pattern.bankPlaybackPosition * widthFactor : 0
                }
            }
            QQC2.Label {
                anchors.centerIn: parent
                font.pointSize: 8
                visible: ["sample-trig", "sample-slice", "synth", "external"].indexOf(root.track.trackAudioType) >= 0
                text: qsTr("%1%2")
                        .arg(root.track.id + 1)
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
                visible: root.track.trackAudioType === "sample-loop" &&
                         detailsLabel.text && detailsLabel.text.trim().length > 0

                QQC2.Label {
                    id: detailsLabel

                    anchors.centerIn: parent
                    width: parent.width - 4
                    elide: "ElideRight"
                    horizontalAlignment: "AlignHCenter"
                    font.pointSize: 8
                    text: partDelegate.clip.path.split("/").pop()
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    partDelegate.clip.enabled = !partDelegate.clip.enabled;
                }
            }
        }
    }
}
