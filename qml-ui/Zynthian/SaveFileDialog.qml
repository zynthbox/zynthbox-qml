import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Qt.labs.folderlistmodel 2.11

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

Zynthian.Dialog {
    property alias headerText: header.text
    property bool conflict: false
    property alias fileName: fileName.text
    property string conflictText: qsTr("File Exists")
    property bool overwriteOnConflict: true
    property alias additionalContent: additionalContentColumn.data

    id: saveDialog
    header: Kirigami.Heading {
        id: header
        padding: 4
        font.pointSize: 16
    }
    modal: true
    z: 999999999
    x: Math.round(parent.width/2 - width/2)
    y: Math.round(parent.height/2 - height/2)
    width: Kirigami.Units.gridUnit * 25
    height: Kirigami.Units.gridUnit * 10 + additionalContentColumn.height
    onVisibleChanged : {
        cancelSaveButton.forceActiveFocus();

        if (!visible) {
            applicationWindow().virtualKeyboard.comment = ""
        }
    }
    onConflictChanged: {
        if (visible) {
            applicationWindow().virtualKeyboard.comment = Qt.binding(function() {
                if (saveDialog.conflict) {
                    return saveDialog.conflictText
                } else {
                    return ""
                }
            })
        }
    }

    Timer {
        id: delayKeyboardTimer
        interval: 300
        onTriggered: {
            fileName.forceActiveFocus()
            Qt.inputMethod.setVisible(true);
        }
    }
    contentItem: ColumnLayout {
        Row {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            QQC2.TextField {
                id: fileName
                height: parent.height
                width: parent.width - parent.height
                onAccepted: {
                    if (fileName.text.length > 0) {
                        if (overwriteOnConflict && saveDialog.conflict) {
                            return;
                        }
                        saveDialog.accept();
                    }
                }
            }
            PlayGridButton {
                id: adjectiveNounButton
                height: parent.height
                width: parent.height
                icon.name: "roll"
                flat: true
                onClicked: {
                    let suffixStart = fileName.text.indexOf(".");
                    let fileSuffix = "";
                    if (suffixStart > -1) {
                        fileSuffix = fileName.text.substring(suffixStart);
                    }
                    fileName.text = Zynthbox.AdjectiveNoun.formatted("%1-%2") + fileSuffix;
                }
            }
        }
        RowLayout {
            id: conflictRow
            opacity: saveDialog.conflict ? 1 : 0
            QQC2.Label {
                Layout.fillWidth: true
                text: conflictText
            }
        }
        ColumnLayout {
            id: additionalContentColumn
            Layout.fillWidth: true
        }
    }
    footer: QQC2.Control {
        leftPadding: saveDialog.leftPadding
        topPadding: Kirigami.Units.smallSpacing
        rightPadding: saveDialog.rightPadding
        bottomPadding: saveDialog.bottomPadding
        contentItem: RowLayout {
            Layout.fillWidth: true
            QQC2.Button {
                id: cancelSaveButton
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                text: qsTr("Cancel")
                onClicked: {
                    saveDialog.reject();
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                text: saveDialog.conflict && overwriteOnConflict ? qsTr("Overwrite") : qsTr("Save")
                enabled: {
                    if (fileName.text.length > 0) {
                        if (saveDialog.conflict && !overwriteOnConflict)
                            return false

                        return true
                    } else {
                        return false
                    }
                }
                onClicked: {
                    if (fileName.text.length > 0) {
                        saveDialog.accept();
                    }
                }
            }
        }
    }
}
