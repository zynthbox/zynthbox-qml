import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Qt.labs.folderlistmodel 2.11

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
    property alias headerText: heading.text
    property string rootFolder: "/"
    property alias folderModel: folderModel
    signal fileSelected(var file)

    id: pickerDialog
    modal: true
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
                icon.name: "user-home-symbolic"
                onClicked: {
                    folderModel.folder = pickerDialog.rootFolder+"/"
                }
            }

            Repeater {
                model: folderBreadcrumbs.folderSplitArray
                delegate: Zynthian.BreadcrumbButton {
                    text: modelData
                    onClicked: {
                        folderModel.folder = pickerDialog.rootFolder+"/"+folderBreadcrumbs.folderSplitArray.slice(0, index+1).join("/")
                    }
                }
            }
        }
    }
    footer: null

    contentItem: QQC2.ScrollView {
        contentItem: ListView {
            Layout.leftMargin: 8
            clip: true
            model: FolderListModel {
                id: folderModel
                showDirs: true
                showDirsFirst: true
                showDotAndDotDot: false
            }
            delegate: Kirigami.BasicListItem {
                width: ListView.view.width

                label: model.fileName
                icon: {
                    if (model.fileIsDir) {
                        return "folder-symbolic"
                    }
                    else if (model.filePath.endsWith(".wav")) {
                        return "folder-music-symbolic"
                    } else {
                        return "file-catalog-symbolic"
                    }
                }
                onClicked: {
                    console.log(model.fileName, model.filePath)

                    if (model.fileIsDir) {
                        folderModel.folder = model.filePath
                    } else {
                        fileSelected(model)
                        pickerDialog.accept()
                    }
                }
            }
        }
    }
}
