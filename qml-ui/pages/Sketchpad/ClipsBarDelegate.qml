
import QtQuick 2.15
import QtQml 2.15
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Qt.labs.folderlistmodel 2.11

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

ColumnLayout {
    id: root
    property QtObject channel
    // Do not bind this property to visible, otherwise it will cause it to be rebuilt when switching to the component, which is very slow
    property QtObject sequence: zynqtgui.isBootingComplete && zynqtgui.sketchpad.song && zynqtgui.sketchpad.song.isLoading == false ? Zynthbox.PlayGridManager.getSequenceModel(zynqtgui.sketchpad.song.scenesModel.selectedSequenceName) : null
    property QtObject selectedClipObject
    property QtObject selectedClipPattern
    property QtObject selectedComponent
    // Set to true to make this operate on song bits
    property bool songMode: false

    signal clicked()
    function handleItemClick(index) {
        clipsRepeater.itemAt(index).handleItemClick()
    }

    spacing: 1

    readonly property QtObject repeater: clipsRepeater
    Repeater {
        id: clipsRepeater
        model: root.channel && root.sequence ? 5 : 0
        delegate: Rectangle {
            id: clipDelegate
            property int clipIndex: index
            property QtObject pattern: root.sequence.getByClipId(root.channel.id, model.index)
            property QtObject clip: root.channel.getClipsModelById(clipDelegate.clipIndex).getClip(zynqtgui.sketchpad.song.scenesModel.selectedSketchpadSongIndex)
            property bool clipHasWav: clipDelegate.clip && !clipDelegate.clip.isEmpty
            property QtObject cppClipObject: root.visible && root.channel.trackType === "sample-loop" && clipDelegate.clipHasWav ? Zynthbox.PlayGridManager.getClipById(clipDelegate.clip.cppObjId) : null;
            function handleItemClick() {
                if (root.songMode) {
                    if (zynqtgui.altButtonPressed) {
                        zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModel.selectedSegment.setRestartClip(clipDelegate.clip, !zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModel.selectedSegment.restartClip(clipDelegate.clip));
                    } else {
                        zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModel.selectedSegment.toggleClip(clipDelegate.clip);
                    }
                } else {
                    if (zynqtgui.sketchpad.lastSelectedObj.className === "sketchpad_clips" &&
                            zynqtgui.sketchpad.lastSelectedObj.value === clipDelegate.clip &&
                            zynqtgui.sketchpad.lastSelectedObj.component === clipDelegate) {
                        clipDelegate.clip.enabled = !clipDelegate.clip.enabled;
                    }
                    root.channel.selectedClip = index;
                    root.selectedClipObject = clipDelegate.clip
                    root.selectedClipPattern = clipDelegate.pattern
                    root.selectedComponent = clipDelegate
                }

                root.clicked()
            }
            property bool clipPlaying: root.channel.trackType === "sample-loop"
                ? clipDelegate.cppClipObject ? clipDelegate.cppClipObject.isPlaying : nextBarState == Zynthbox.PlayfieldManager.PlayingState
                : clipDelegate.pattern ? clipDelegate.pattern.isPlaying : nextBarState == Zynthbox.PlayfieldManager.PlayingState
            // nextBarState is updated from the container (i.e. ClipsBar and slotSelectionDrawer in the main window - SongMode doesn't update this state, as it handles the playfield state explicitly during playback)
            property int nextBarState: Zynthbox.PlayfieldManager.StoppedState

            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#000000"
            border{
                color: root.songMode
                        ? zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModel.selectedSegment != null && zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModel.selectedSegment.clips.indexOf(clipDelegate.clip) >= 0
                            ? Kirigami.Theme.highlightColor
                            : "#000000"
                        : clipDelegate.clip && clipDelegate.clip.inCurrentScene
                            ? Kirigami.Theme.highlightColor
                            : "#000000"
                width: 1
            }
            Zynthbox.WaveFormItem {
                id: waveformItem
                anchors.fill: parent
                color: Kirigami.Theme.textColor
                source: clipDelegate.cppClipObject ? "clip:/%1".arg(clipDelegate.cppClipObject.id) : ""
                start: clipDelegate.cppClipObject != null ? clipDelegate.cppClipObject.selectedSliceObject.startPositionSeconds : 0
                end: clipDelegate.cppClipObject != null ? clipDelegate.cppClipObject.selectedSliceObject.startPositionSeconds + clipDelegate.cppClipObject.selectedSliceObject.lengthSeconds : 0
                readonly property real relativeStart: waveformItem.start / waveformItem.length
                readonly property real relativeEnd: waveformItem.end / waveformItem.length

                visible: root.visible && root.channel.trackType === "sample-loop" && clipDelegate.clipHasWav
                // Progress line
                Rectangle {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                    }
                    visible: parent.visible && clipDelegate.cppClipObject && clipDelegate.cppClipObject.isPlaying
                    color: Kirigami.Theme.highlightColor
                    width: 1
                    x: visible ? Zynthian.CommonUtils.fitInWindow(clipDelegate.cppClipObject.position, waveformItem.relativeStart, waveformItem.relativeEnd) * parent.width : 0
                }
            }
            Image {
                anchors.fill: parent
                anchors.margins: 2
                smooth: false
                visible: root.visible && root.channel.trackType !== "sample-loop" &&
                         clipDelegate.pattern &&
                         clipDelegate.pattern.hasNotes
                source: clipDelegate.pattern ? clipDelegate.pattern.thumbnailUrl : ""
                cache: false
                Rectangle {
                    anchors {
                        top: parent.top
                        bottom: parent.bottom
                    }
                    visible: parent.visible && clipDelegate.pattern ? clipDelegate.pattern.isPlaying : false
                    color: Kirigami.Theme.highlightColor
                    property double widthFactor: root.visible && parent.visible && clipDelegate.pattern ? parent.width / (clipDelegate.pattern.width * clipDelegate.pattern.bankLength) : 1
                    width: Math.max(1, Math.floor(widthFactor))
                    x: root.visible && parent.visible && clipDelegate.pattern ? clipDelegate.pattern.bankPlaybackPosition * widthFactor : 0
                }
            }
            QQC2.Label {
                anchors.centerIn: parent
                font.pointSize: 12
                visible: ["sample-trig", "synth", "external"].indexOf(root.channel.trackType) >= 0
                color: clipDelegate.pattern && clipDelegate.pattern.hasNotes ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                opacity: clipDelegate.pattern && clipDelegate.pattern.hasNotes ? 1 : 0.3
                text: String.fromCharCode(clipDelegate.clipIndex + 65)
            }
            QQC2.Label {
                anchors.centerIn: parent
                font.pointSize: 12
                visible: ["sample-loop"].indexOf(root.channel.trackType) >= 0
                color: Qt.rgba(255, 255, 255, clipDelegate.clipHasWav ? 1 : 0.3)
                text: clipDelegate.clipIndex + 1
            }
            QQC2.Label {
                anchors.fill: parent
                verticalAlignment: Text.AlignBottom
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: 8
                visible: root.songMode === true && ["sample-loop", "sample-trig", "synth", "external"].indexOf(root.channel.trackType) >= 0
                text: visible
                    ? root.channel.trackType == "sample-loop"
                        ? clipDelegate.cppClipObject && clipDelegate.cppClipObject.durationSeconds > 0
                            ? "%1s".arg(clipDelegate.cppClipObject.selectedSliceObject.lengthSeconds.toFixed(2))
                            : ""
                        : clipDelegate.pattern && clipDelegate.pattern.hasNotes
                            ? "%1s".arg(patternBarsToSeconds(clipDelegate.pattern, Zynthbox.SyncTimer.bpm).toFixed(2))
                            : ""
                    : ""
                function patternBarsToSeconds(pattern, bpm) {
                    // Set up the loop points in the new recording
                    let patternSubbeatToTickMultiplier = (Zynthbox.SyncTimer.getMultiplier() / 32);
                    // Reset this to beats (rather than pattern subbeats)
                    let patternDurationInBeats = pattern.patternLength * pattern.stepLength / patternSubbeatToTickMultiplier;
                    let patternDurationInSeconds = Zynthbox.SyncTimer.subbeatCountToSeconds(bpm, patternDurationInBeats * patternSubbeatToTickMultiplier);
                    return patternDurationInSeconds;
                }
            }
            Rectangle {
                height: 16
                anchors {
                    left: parent.left
                    top: parent.top
                    right: parent.right
                }
                color: "#99888888"
                visible: root.channel.trackType === "sample-loop" &&
                         detailsLabel.text && detailsLabel.text.trim().length > 0

                QQC2.Label {
                    id: detailsLabel

                    anchors.centerIn: parent
                    width: parent.width - 4
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    font.pointSize: 8
                    text: root.visible ? clipDelegate.clip.path.split("/").pop() : ""
                }
            }
            Kirigami.Icon {
                anchors {
                    left: parent.left
                    bottom: parent.bottom
                    margins: Kirigami.Units.smallSpacing
                }
                height: Kirigami.Units.largeSpacing
                width: Kirigami.Units.largeSpacing
                visible: root.songMode && zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModel.selectedSegment != null && zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModel.selectedSegment.restartClips && zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModel.selectedSegment.restartClip(clipDelegate.clip)
                source: "media-skip-backward-symbolic"
            }
            Kirigami.Icon {
                anchors {
                    left: parent.left
                    bottom: parent.bottom
                    margins: Kirigami.Units.smallSpacing
                }
                height: Kirigami.Units.largeSpacing
                width: Kirigami.Units.largeSpacing
                // Visible (blinking) if we are not in song mode, we are running playback, the clip is not playing, and we are going to start the clip at the top of the next bar
                // Also visible (non-blinking) regardless of song mode state, if the timer is running, the clip is playing, and it is going to keep playing on the next bar
                visible: (root.songMode === false && Zynthbox.SyncTimer.timerRunning && clipDelegate.clipPlaying === false && clipDelegate.nextBarState == Zynthbox.PlayfieldManager.PlayingState && Zynthbox.PlayGridManager.metronomeBeat16th % 4 === 0)
                    || (Zynthbox.SyncTimer.timerRunning && clipDelegate.clipPlaying === true && clipDelegate.nextBarState == Zynthbox.PlayfieldManager.PlayingState)
                source: "media-playback-start-symbolic"
            }
            Kirigami.Icon {
                anchors {
                    left: parent.left
                    bottom: parent.bottom
                    margins: Kirigami.Units.smallSpacing
                }
                height: Kirigami.Units.largeSpacing
                width: Kirigami.Units.largeSpacing
                // Visible if we are not in song mode, we are running playback, the clip is playing, and we are going to stop the clip at the top of the next bar
                visible: root.songMode === false && Zynthbox.SyncTimer.timerRunning && clipDelegate.clipPlaying === true && clipDelegate.nextBarState == Zynthbox.PlayfieldManager.StoppedState && Zynthbox.PlayGridManager.metronomeBeat16th % 4 === 0
                source: "media-playback-stop-symbolic"
            }
            MouseArea {
                id: mouseArea
                anchors.fill: parent
                onClicked: clipDelegate.handleItemClick()
                onPressAndHold: {
                    if (root.songMode) {
                        zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModel.selectedSegment.setRestartClip(clipDelegate.clip, !zynqtgui.sketchpad.song.arrangementsModel.selectedArrangement.segmentsModel.selectedSegment.restartClip(clipDelegate.clip));
                    } else {
                        clipDelegate.clip.enabled = true;
                        root.channel.selectedClip = index;
                        zynqtgui.bottomBarControlType = "bottombar-controltype-pattern";
                        zynqtgui.bottomBarControlObj = root.channel.sceneClip;
                        bottomStack.slotsBar.bottomBarButton.checked = true;

                        if (root.channel.trackType === "sample-loop") {
                            if (clipDelegate.clipHasWav) {
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
