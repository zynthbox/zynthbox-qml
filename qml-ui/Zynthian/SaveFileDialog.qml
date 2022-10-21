import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Qt.labs.folderlistmodel 2.11

QQC2.Dialog {
    property alias headerText: header.text
    property alias conflict: conflictRow.visible
    property alias fileName: fileName.text
    property string conflictText: qsTr("File Exists")
    property bool overwriteOnConflict: true

    id: saveDialog
    header: Kirigami.Heading {
        id: header
        padding: 4
        font.pointSize: 16
    }
    modal: true
    z: 999999999
    x: Math.round(parent.width/2 - width/2)
    y: Qt.inputMethod.visible ? Math.round(parent.height/5) : Math.round(parent.height/2 - height/2)
    width: Kirigami.Units.gridUnit * 15
    height: Kirigami.Units.gridUnit * 8
    onVisibleChanged : {
        cancelSaveButton.forceActiveFocus();
//        if (visible) {
//            delayKeyboardTimer.restart()
//        }
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
        QQC2.TextField {
            id: fileName
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(Kirigami.Units.gridUnit * 1.6)
            onAccepted: {
                if (fileName.text.length > 0) {
                    if (overwriteOnConflict && conflict)
                        return

                    saveDialog.accept();
                }
            }
            onTextChanged: fileNameChanged(fileName.text)
        }
        RowLayout {
            id: conflictRow
            visible: false
            QQC2.Label {
                Layout.fillWidth: true
                text: conflictText
            }
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
                text: qsTr("Cancel")
                onClicked: {
                    saveDialog.reject();
                }
            }
            QQC2.Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                text: conflict && overwriteOnConflict ? qsTr("Overwrite") : qsTr("Save")
                enabled: {
                    if (fileName.text.length > 0) {
                        if (conflict && !overwriteOnConflict)
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
