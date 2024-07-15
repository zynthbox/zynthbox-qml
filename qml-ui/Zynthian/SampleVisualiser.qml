import QtQuick 2.15
import QtQml 2.15
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.4 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import io.zynthbox.components 1.0 as Zynthbox

/**
 * \brief Visualiser for samples, including progress information either for single progress (e.g. preview purposes), or for all playback positions
 */
Item {
    id: component
    /**
     * Set to the sketchpad sample you want to see visualisation for
     */
    property QtObject sample: null
    /**
     * This should be set to the channel audio type string for the channel appropriate for the given sample.
     * If you don't set this, you will have no progress reporting
     * If you are visualising an orphaned sample (for example when previewing one for loading), set this to "sample-loop" to have a single progress line, or "sample-trig" for multiple progress dots
     * Accepted values are any one of the track audio type strings, so: "sample-trig", "sample-slice", "sample-loop", "external", or "synth"
     */
    property string trackType: ""
    clip: true
    Rectangle {
        anchors.fill: parent
        color: "#222222"
        border.width: 1
        border.color: "#ff999999"
        radius: 4
    }
    QtObject {
        id: _private
        property QtObject sample: null
        property int progressStyle: 0 // 0 is no progress, 1 is single progress line, 2 is progress dots
    }
    Binding {
        target: _private
        property: "sample"
        value: component.sample
        when: component.visible
        delayed: true
        restoreMode: Binding.RestoreBinding
    }
    Binding {
        target: _private
        property: "progressStyle"
        value: component.trackType === "sample-loop"
            ? 1
            : component.trackType === "sample-trig" || component.trackType === "sample-slice"
                ? 2
                : 0
    }
    Zynthbox.WaveFormItem {
        id: waveForm
        anchors.fill: parent
        color: Kirigami.Theme.textColor
        Binding {
            target: waveForm
            property: "source"
            value: _private.sample ? _private.sample.path : ""
            when: parent.visible
            delayed: true
            restoreMode: Binding.RestoreBinding
        }

        visible: component.visible && _private.sample && !_private.sample.isEmpty

        // Mask for wave part before start
        Rectangle {
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: parent.left
                right: startLoopLine.left
            }
            color: "#99000000"
        }

        // Mask for wave part after
        Rectangle {
            anchors {
                top: parent.top
                bottom: parent.bottom
                left: endLoopLine.right
                right: parent.right
            }
            color: "#99000000"
        }

        // Start loop line
        Rectangle {
            id: startLoopLine
            anchors {
                top: parent.top
                bottom: parent.bottom
            }
            color: Kirigami.Theme.positiveTextColor
            opacity: 0.6
            width: Kirigami.Units.smallSpacing
            x: _private.sample ? (_private.sample.startPosition / _private.sample.duration) * parent.width : 0
        }

        // End loop line
        Rectangle {
            id: endLoopLine
            anchors {
                top: parent.top
                bottom: parent.bottom
            }
            color: Kirigami.Theme.neutralTextColor
            opacity: 0.6
            width: Kirigami.Units.smallSpacing
            x: _private.sample ? ((((60/Zynthbox.SyncTimer.bpm) * _private.sample.length) / _private.sample.duration) * parent.width) + ((_private.sample.startPosition / _private.sample.duration) * parent.width) : 0
        }

        // Progress line
        Rectangle {
            anchors {
                top: parent.top
                bottom: parent.bottom
            }
            visible: component.visible && _private.progressStyle === 1 && progressDots.cppClipObject && progressDots.cppClipObject.isPlaying
            color: Kirigami.Theme.highlightColor
            width: Kirigami.Units.smallSpacing
            x: visible ? progressDots.cppClipObject.progress * parent.width : 0
        }

        // SamplerSynth progress dots
        Repeater {
            id: progressDots
            property QtObject cppClipObject: parent.visible ? Zynthbox.PlayGridManager.getClipById(_private.sample.cppObjId) : null;
            model: Zynthbox.Plugin.clipMaximumPositionCount
            property QtObject playbackPositions: null
            Timer {
                id: dotFetcher
                interval: 1; repeat: false; running: false;
                onTriggered: {
                    progressDots.playbackPositions = component.visible && _private.progressStyle === 2 && progressDots.cppClipObject
                        ? progressDots.cppClipObject.playbackPositions
                        : null
                }
            }
            Connections {
                target: component
                onVisibleChanged: dotFetcher.restart();
            }
            Connections {
                target: progressDots
                onCppClipObjectChanged: dotFetcher.restart();
            }
            Connections {
                target: _private
                onProgressStyleChanged: dotFetcher.restart();
            }
            delegate: Item {
                property QtObject progressEntry: progressDots.playbackPositions ? progressDots.playbackPositions.positions[model.index] : null
                visible: progressEntry && progressEntry.id > -1
                Rectangle {
                    anchors.centerIn: parent
                    rotation: 45
                    color: Kirigami.Theme.highlightColor
                    width: Kirigami.Units.largeSpacing
                    height:  Kirigami.Units.largeSpacing
                    scale: progressEntry ? 0.5 + progressEntry.gain : 1
                }
                anchors {
                    top: parent.verticalCenter
                    topMargin: progressEntry ? progressEntry.pan * (parent.height / 2) : 0
                }
                x: visible ? Math.floor(progressEntry.progress * parent.width) : 0
            }
        }
    }
    QQC2.Label {
        anchors.centerIn: parent
        opacity: 0.5
        text: qsTr("No sample data to display")
        visible: _private.sample && _private.sample.cppObjId === -1
    }
}
