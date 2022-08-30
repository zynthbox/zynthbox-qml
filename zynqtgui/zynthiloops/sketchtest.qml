
import QtQuick 2.0
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.3 as Controls
import org.kde.kirigami 2.4 as Kirigami

import JuceGraphics 1.0

Controls.ApplicationWindow {
    width: 300
    height: 400
    visible: true

    ColumnLayout {
        RowLayout {
            Controls.Label {
                text: songManager.song.name
            }
            Repeater {
                model: songManager.song.channelsModel
                delegate: Controls.Label {
                    text: channel.name
                }
            }
        }
        RowLayout {
            ColumnLayout {
                Repeater {
                    model: songManager.song.partsModel
                    delegate: Controls.Button {
                        text: part.name
                        onClicked: {
                                if (model.part.isPlaying) {
                                    model.part.stop()
                                } else {
                                    model.part.play()
                                }
                            }
                    }
                }
            }
            GridLayout {
                id: lay
                rows: songManager.song.partsModel.count
                flow: GridLayout.TopToBottom
                Repeater {
                    model: songManager.song.channelsModel
                    delegate: Repeater {
                        model: channel.clipsModel
                        delegate: Controls.Button {
                            id: clipButton
                            text: model.clip.name
                            Component.onCompleted: model.clip.path = "/home/diau/test.wav"
                            onClicked: {
                                print(model.clip.path)

                                print(model.clip)
                                if (model.clip.isPlaying) {
                                    model.clip.stop()
                                } else {
                                    //model.clip.path = "/home/diau/test.wav"
                                    model.clip.play()
                                }
                            }
                            Rectangle {
                                id: progressRect
                                visible: model.clip.isPlaying
                                color: "red"
                                height: 4
                                width: (model.clip.progress * clipButton.width) / (model.clip.startPosition + (60/songManager.song.bpm) * model.clip.length)  - model.clip.startPosition*model.clip.duration
                            }
                        }
                    }
                }
            }
        }
        Controls.Button {
            text: "Add Channel"
            onClicked: songManager.song.addChannel()
        }
        Controls.Button {
            text: "Reset Song"
            onClicked: songManager.clearSong()
        }
    }
}
