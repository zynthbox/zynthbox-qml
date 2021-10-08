import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Window 2.1
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Qt.labs.folderlistmodel 2.11

import Helpers 1.0 as Helpers

import Zynthian 1.0 as Zynthian

/**
  * EXAMPLE :
  *
  * Zynthian.FilePickerDialog {
  *      id: pickerDialog
  *
  *      x: parent.width/2 - width/2
  *      y: parent.height/2 - height/2
  *      width: Math.round(parent.width * 0.8)
  *      height: Math.round(parent.height * 0.8)
  *
  *      rootFolder: '/zynthian/zynthian-my-data'
  *      folderModel {
  *          folder: '/zynthian/zynthian-my-data/sketches'
  *          nameFilters: ["*.wav"]
  *      }
  *      onFileSelected: {
  *          console.log(filePath)
  *      }
  * }
  */
QQC2.Dialog {
    id: pickerDialog
    property alias headerText: heading.text
    property string rootFolder: "/"
    property alias folderModel: folderModel
    property alias filesListView: filesListView
    property alias breadcrumb: folderBreadcrumbs
    signal fileSelected(var file)
    property bool saveMode
    property alias fileNameToSave: nameFiled.text
    property alias noFilesMessage: noFilesMessage.text
    property alias conflictMessageLabel: conflictLabel

    modal: true

    y: pickerDialog.parent.mapFromGlobal(0, saveMode && Qt.inputMethod.visible ? Kirigami.Units.gridUnit : Math.round(header.Window.height/2 - height/2)).y
    x: pickerDialog.parent.mapFromGlobal(Math.round(header.Window.width/2 - width/2), 0).x

    width: Math.round(header.Window.width * 0.8)
    height: saveMode && Qt.inputMethod.visible ? Math.round(header.Window.height / 2) : Math.round(header.Window.height * 0.8)
    z: 999999999

    onAccepted: filesListView.selectedModelData = null
    onRejected: filesListView.selectedModelData = null
    onDiscarded: filesListView.selectedModelData = null

    header: ColumnLayout{
        spacing: 8

        Kirigami.Heading {
            id: heading

            text: qsTr("Pick a file")
            font.pointSize: 16
            Layout.leftMargin: 12
            Layout.topMargin: 12
        }

        RowLayout {
            property var folderSplitArray: String(folderModel.folder).replace("file://"+pickerDialog.rootFolder, "").split("/").filter(function(e) { return e.length > 0 })

            id: folderBreadcrumbs
            Layout.leftMargin: 12
            spacing: 2

            Zynthian.BreadcrumbButton {
                id: homeButton
                icon.name: "user-home-symbolic"
                onClicked: {
                    folderModel.folder = pickerDialog.rootFolder + "/"
                }
            }

            Repeater {
                id: breadcrumbsRepeater
                model: folderBreadcrumbs.folderSplitArray
                delegate: Zynthian.BreadcrumbButton {
                    text: modelData
                    onClicked: {
                        folderModel.folder = pickerDialog.rootFolder + "/" + folderBreadcrumbs.folderSplitArray.slice(0, index+1).join("/")
                        filesListView.currentIndex = 0;
                    }
                }
            }
        }
    }
    onVisibleChanged: nameFiled.text = ""
    footer: QQC2.Control {
        leftPadding: pickerDialog.leftPadding
        topPadding: Kirigami.Units.smallSpacing
        rightPadding: pickerDialog.rightPadding
        bottomPadding: pickerDialog.bottomPadding
        contentItem: ColumnLayout {
            RowLayout {
                visible: pickerDialog.saveMode
                QQC2.Label {
                    text: qsTr("File Name:")
                }
                QQC2.TextField {
                    id: nameFiled
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.6
                    onTextChanged: {
                        if (filesListView.selectedModelData) {
                            filesListView.selectedModelData.fileName = text;
                        } else {
                            filesListView.selectedModelData = {};
                            filesListView.selectedModelData.fileName = nameFiled.text;
                            filesListView.selectedModelData.filePath = String(folderModel.folder).replace("file://", "") + "/" + nameFiled.text;
                            pickerDialog.fileSelected(filesListView.selectedModelData);
                        }
                    }
                }
            }
            QQC2.Label {
                id: conflictLabel
                visible: zynthian.file_exists(String(folderModel.folder).replace("file://", "") + "/" + nameFiled.text)
                Layout.fillWidth: true
                text: qsTr("File Exists: overwrite?")
                horizontalAlignment: Text.AlignHCenter
            }

            RowLayout {
                Layout.fillWidth: true
                QQC2.Button {
                    id: cancelSaveButton
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    text: qsTr("Cancel")
                    onClicked: pickerDialog.close();
                }
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    text: {
                        if (pickerDialog.saveMode) {
                            return conflictLabel.visible ? qsTr("Overwrite") : qsTr("Save");
                        } else {
                            return qsTr("Load")
                        }
                    }
                    enabled: filesListView.selectedModelData !== null
                    onClicked: {
                        /*if (pickerDialog.saveMode) {
                            if (nameFiled.text.length > 0) {
                                let file = {};
                                file.fileName = nameFiled.text;
                                file.filePath = String(folderModel.folder).replace("file://", "") + "/" + nameFiled.text;
                                pickerDialog.fileSelected(file);
                                pickerDialog.accept();
                            }
                        } else*/ {
                            fileSelected(filesListView.selectedModelData);
                            pickerDialog.accept();
                            filesListView.currentIndex = 0;
                        }
                    }
                }
            }
        }
    }


    contentItem: RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true

        QtObject {
            id: filesListViewDimensions

            property var rowHeight: Kirigami.Units.gridUnit*2
            property var rowMargin: Kirigami.Units.gridUnit
        }

        QQC2.ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            contentItem: ColumnLayout {
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: Kirigami.Units.gridUnit*2

                    color: "#11000000"
                    border.width: 1
                    border.color: "#22000000"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 4
                        anchors.rightMargin: 4

                        QQC2.Label {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: qsTr("Filename")
                        }

                        QQC2.Label {
                            Layout.preferredWidth: Kirigami.Units.gridUnit*8
                            Layout.maximumWidth: Kirigami.Units.gridUnit*8
                            Layout.fillHeight: true
                            text: qsTr("Duration")
                        }
                    }
                }

                ListView {
                    id: filesListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    focus: true
                    onCurrentIndexChanged: {
                        filePropertiesSection.filePropertiesHelperObj = filesListView.currentItem.fileProperties;
                    }
                    Layout.leftMargin: 8
                    clip: true

                    property var selectedModelData: null

                    function selectItem(model) {
                        console.log(model.fileName, model.filePath, model.index)
                        if (model.fileIsDir) {
                            var path = model.filePath;

                            if (path.endsWith("/")) {
                                path = path.slice(0, path.length - 1);
                            }

                            folderModel.folder = path;
                            filesListView.currentIndex = 0;
                        } else {
                            filesListView.selectedModelData = model;
                            if (pickerDialog.saveMode) {
                                nameFiled.text = model.fileName;
                            }
                            pickerDialog.filesListView.currentIndex = model.index;
                        }
                    }

                    QQC2.Label {
                        id: noFilesMessage
                        parent: filesListView
                        anchors.centerIn: parent
                        visible: filesListView.count === 0
                        text: qsTr("There are no files present")
                    }


                    model: FolderListModel {
                        id: folderModel
                        showDirs: true
                        showDirsFirst: true
                        showDotAndDotDot: false
                        onFolderChanged: {
                            filesListView.currentIndex = 0;
                            filePropertiesSection.filePropertiesHelperObj = filesListView.currentItem.fileProperties;
                        }
                    }
                    delegate: Rectangle {
                        property var fileProperties: Helpers.FilePropertiesHelper {
                            filePath: model.filePath
                        }

                        width: ListView.view.width
                        height: Kirigami.Units.gridUnit*2
                        color: ListView.isCurrentItem ? Kirigami.Theme.highlightColor : "transparent"

                        ColumnLayout {
                            spacing: 0
                            anchors.fill: parent

                            RowLayout {

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: Kirigami.Units.gridUnit

                                Kirigami.Icon {
                                    Layout.preferredWidth: parent.height
                                    Layout.maximumWidth: parent.height
                                    Layout.fillHeight: true
                                    Layout.margins: 8

                                    source: {
                                        if (model.fileIsDir) {
                                            return "folder-symbolic"
                                        }
                                        else if (model.filePath.endsWith(".wav")) {
                                            return "folder-music-symbolic"
                                        } else {
                                            return "file-catalog-symbolic"
                                        }
                                    }
                                }

                                RowLayout {
                                    QQC2.Label {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        text: model.fileName
                                    }

                                    QQC2.Label {
                                        Layout.preferredWidth: Kirigami.Units.gridUnit*8
                                        Layout.maximumWidth: Kirigami.Units.gridUnit*8
                                        Layout.fillHeight: true
                                        text: fileProperties.fileMetadata.isWav
                                                ? qsTr("%1 secs").arg(fileProperties.fileMetadata.properties.duration.toFixed(2))
                                                : ""
                                    }
                                }
                            }

                            Kirigami.Separator {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: filesListView.selectItem(model)
                        }
                    }
                }
            }
        }

        Flickable {
            Layout.preferredWidth: Kirigami.Units.gridUnit*12
            Layout.maximumWidth: Kirigami.Units.gridUnit*12
            Layout.fillHeight: true
            clip: true
            flickableDirection: Flickable.VerticalFlick
            contentHeight: filePropertiesSection.height

            ColumnLayout {
                property var filePropertiesHelperObj: null

                id: filePropertiesSection
                visible: filePropertiesHelperObj !== null && filePropertiesHelperObj.fileMetadata !== null

                width: parent.width
                spacing: 0

                Kirigami.Icon {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48

                    Layout.alignment: Qt.AlignHCenter
                    source: {
                        if (filePropertiesSection.filePropertiesHelperObj.fileMetadata.isDir) {
                            return "folder-symbolic"
                        }
                        else if (filePropertiesSection.filePropertiesHelperObj.fileMetadata.isWav) {
                            return "folder-music-symbolic"
                        } else {
                            return "file-catalog-symbolic"
                        }
                    }
                }

                QQC2.Label {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.maximumWidth: Kirigami.Units.gridUnit*10
                    elide: Text.Elide.Middle
                    text: filePropertiesSection.filePropertiesHelperObj.fileMetadata.filename.length > 23
                            ? filePropertiesSection.filePropertiesHelperObj.fileMetadata.filename.substring(0, 20) + '...'
                            : filePropertiesSection.filePropertiesHelperObj.fileMetadata.filename
                }

                QQC2.Button {
                    id: previewButton
                    visible: filePropertiesSection.filePropertiesHelperObj.fileMetadata.isWav
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Kirigami.Units.gridUnit
                    Layout.bottomMargin: Kirigami.Units.gridUnit
                    text: filePropertiesSection.filePropertiesHelperObj.isPreviewPlaying ? qsTr("Stop") : qsTr("Preview")
                    icon.name: filePropertiesSection.filePropertiesHelperObj.isPreviewPlaying ? "media-playback-stop" : "media-playback-start"
                    onClicked: {
                        if (filePropertiesSection.filePropertiesHelperObj.isPreviewPlaying) {
                            filePropertiesSection.filePropertiesHelperObj.stopPreview();
                        } else {
                            filePropertiesSection.filePropertiesHelperObj.playPreview();
                        }
                    }
                }

                Kirigami.BasicListItem {
                    Layout.fillWidth: true
                    visible: filePropertiesSection.filePropertiesHelperObj.fileMetadata.isWav
                    label: qsTr("Size: %1 MB").arg((filePropertiesSection.filePropertiesHelperObj.fileMetadata.size/1024/1024).toFixed(2))
                }

                Kirigami.BasicListItem {
                    Layout.fillWidth: true
                    visible: filePropertiesSection.filePropertiesHelperObj.fileMetadata.isWav
                    label: qsTr("Sample Rate: %1").arg(filePropertiesSection.filePropertiesHelperObj.fileMetadata.properties.sampleRate)
                }

                Kirigami.BasicListItem {
                    Layout.fillWidth: true
                    visible: filePropertiesSection.filePropertiesHelperObj.fileMetadata.isWav
                    label: qsTr("Channels: %1").arg(filePropertiesSection.filePropertiesHelperObj.fileMetadata.properties.channels)
                }

                Kirigami.BasicListItem {
                    Layout.fillWidth: true
                    visible: filePropertiesSection.filePropertiesHelperObj.fileMetadata.isWav
                    label: qsTr("Duration: %1 secs").arg(filePropertiesSection.filePropertiesHelperObj.fileMetadata.properties.duration.toFixed(2))
                }
            }
        }
    }

    function cuiaCallback(cuia) {
        switch (cuia) {
            case "SELECT_UP":
                pickerDialog.filesListView.currentIndex = pickerDialog.filesListView.currentIndex > 0
                                                            ? pickerDialog.filesListView.currentIndex - 1
                                                            : 0
                return true;

            case "SELECT_DOWN":
                pickerDialog.filesListView.currentIndex = pickerDialog.filesListView.currentIndex < pickerDialog.filesListView.count-1
                                                            ? pickerDialog.filesListView.currentIndex + 1
                                                            : pickerDialog.filesListView.count-1
                return true;

            case "SWITCH_SELECT_SHORT":
            case "SWITCH_SELECT_BOLD":
            case "SWITCH_SELECT_LONG":
                if (pickerDialog.filesListView.currentIndex >= 0 &&
                    pickerDialog.filesListView.currentIndex < pickerDialog.filesListView.count) {
                    pickerDialog.filesListView.currentItem.clicked();
                }

                return true;

            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_BOLD":
            case "SWITCH_BACK_LONG":
                pickerDialog.goBack();

                return true;

            default:
                return false;
        }
    }

    function goBack() {
        var newPath = String(folderModel.folder).replace("file://", "").split("/");
        newPath.pop();
        newPath = newPath.join("/");

        if (newPath.includes(rootFolder)) {
            folderModel.folder = newPath;
        } else {
            folderModel.folder = rootFolder;
        }
    }
}
