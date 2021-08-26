
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
                text: song.name
            }
            Repeater {
                model: song.tracksModel
                delegate: Controls.Label {
                    text: track.name
                }
            }
        }
        RowLayout {
            ColumnLayout {
                Repeater {
                    model: song.partsModel
                    delegate: Controls.Label {
                        text: part.name
                    }
                }
            }
            GridLayout {
                id: lay
                rows: song.partsModel.count
                flow: GridLayout.TopToBottom
                Repeater {
                    model: song.tracksModel
                    delegate: Repeater {
                        model: track.clipsModel
                        delegate: Controls.Button {
                            text: model.clip.name
                            //Component.onCompleted: model.clip.path = "/home/diau/test.wav"
                            onClicked: {
                                print(model.clip.path)
                                
                                print(model.clip)
                                if (model.clip.isPlaying) {
                                    model.clip.stop()
                                } else {
                                    model.clip.path = "/home/diau/test.wav"
                                    model.clip.play()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
