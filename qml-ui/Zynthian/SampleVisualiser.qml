import QtQuick 2.10
import QtQuick.Layouts 1.4
import org.kde.kirigami 2.4 as Kirigami

import org.zynthian.quick 1.0 as ZynQuick
import JuceGraphics 1.0

Item {
    id: component
    property QtObject sample: null
    property string channelAudioType: "" // One of the track audio type strings, so: "sample-trig", "sample-slice", "sample-loop", "external", or "synth"
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
    }
    Binding {
        target: _private
        property: "sample"
        value: component.sample
        when: component.visible
        delayed: true
    }
    WaveFormItem {
        id: waveForm
        anchors.fill: parent
        color: Kirigami.Theme.textColor
        Binding {
            target: waveForm
            property: "source"
            value: _private.sample ? _private.sample.path : ""
            when: parent.visible
            delayed: true
        }

        visible: component.visible && _private.sample && _private.sample.path && _private.sample.path.length > 0

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
            x: _private.sample ? ((((60/zynthian.sketchpad.song.bpm) * _private.sample.length) / _private.sample.duration) * parent.width) + ((_private.sample.startPosition / _private.sample.duration) * parent.width) : 0
        }

        // Progress line
        Rectangle {
            anchors {
                top: parent.top
                bottom: parent.bottom
            }
            visible: component.visible && _private.sample && _private.sample.isPlaying
            color: Kirigami.Theme.highlightColor
            width: Kirigami.Units.smallSpacing
            x: visible ? _private.sample.progress/_private.sample.duration * parent.width : 0
        }

        // SamplerSynth progress dots
        Repeater {
            property QtObject cppClipObject: parent.visible ? ZynQuick.PlayGridManager.getClipById(_private.sample.cppObjId) : null;
            model: (component.visible && component.channelAudioType === "sample-slice" || component.channelAudioType === "sample-trig") && cppClipObject
                ? cppClipObject.playbackPositions
                : 0
            delegate: Item {
                visible: model.positionGain > 0
                Rectangle {
                    anchors.centerIn: parent
                    rotation: 45
                    color: Kirigami.Theme.highlightColor
                    width: Kirigami.Units.largeSpacing
                    height:  Kirigami.Units.largeSpacing
                    scale: 0.5 + model.positionGain
                }
                anchors.verticalCenter: parent.verticalCenter
                x: Math.floor(model.positionProgress * parent.width)
            }
        }
    }
}
