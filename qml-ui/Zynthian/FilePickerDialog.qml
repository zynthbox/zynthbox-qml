import QtQuick 2.15
import QtQuick.Layouts 1.4
import QtQuick.Window 2.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.4 as Kirigami

import Qt.labs.folderlistmodel 2.15

import Helpers 1.0 as Helpers

import Zynthian 1.0 as Zynthian
import io.zynthbox.components 1.0 as Zynthbox

/**
  * EXAMPLE :
  *
  * Zynthian.Fileroot {
  *      id: root
  *
  *      x: parent.width/2 - width/2
  *      y: parent.height/2 - height/2
  *      width: Math.round(parent.width * 0.8)
  *      height: Math.round(parent.height * 0.8)
  *
  *      rootFolder: '/zynthian/zynthian-my-data'
  *      folderModel {
  *          folder: '/zynthian/zynthian-my-data/sketchpads'
  *          nameFilters: ["*.wav"]
  *      }
  *      onAccepted: {
  *          console.log(selectedFile.filePath)
  *      }
  * }
  */
Zynthian.Dialog {
    id: root
    property alias headerText: heading.text
    property string rootFolder: "/"
    property alias folderModel: folderModel
    property alias filesListView: filesListView
    property alias breadcrumb: folderBreadcrumbs
    signal fileSelected(var file)
    property bool saveMode
    property alias fileNameToSave: namedFile.text
    property alias noFilesMessage: noFilesMessage.text
    property alias conflictMessageLabel: conflictLabel
    property alias filePropertiesComponent: filePropertiesColumn.sourceComponent
    property var currentFileInfo: null
    property string autoExtension: "" // Set this to suggest what the file extension will be on a saved file (so the overwrite checking logic can be retained)

    property alias listCurrentIndex: filesListView.currentIndex
    property alias listCount: filesListView.count
    readonly property var selectedFile: filesListView.saveModelData ? filesListView.saveModelData : filesListView.selectedModelData
    property var folderInfoStrings: ({})

    property var cuiaCallback: function (cuia) {
        var result = true;
        switch (cuia) {
            case "NAVIGATE_LEFT":
                root.goBack();
                result = true;
                break;
            case "NAVIGATE_RIGHT":
                // If the currently selected thing is a directory, then enter that directory
                if (root.currentFileInfo !== null && root.currentFileInfo.fileIsDir) {
                    root.filesListView.currentItem.selectItem();
                }
                result = true;
                break;
            case "SELECT_UP":
                root.filesListView.currentIndex = Zynthian.CommonUtils.clamp(root.filesListView.currentIndex - 1, 0, root.filesListView.count - 1);
                result = true;
                break;
            case "SELECT_DOWN":
                root.filesListView.currentIndex = Zynthian.CommonUtils.clamp(root.filesListView.currentIndex + 1, 0, root.filesListView.count - 1);
                result = true;
                break;
            case "SWITCH_SELECT_SHORT":
            case "SWITCH_SELECT_BOLD":
            case "SWITCH_SELECT_LONG":
                if (root.saveMode === false && filePropertiesColumn.filePropertiesHelperObj && filePropertiesColumn.filePropertiesHelperObj.fileMetadata.isFile) {
                    // We are loading, and have something selected which is a file
                    root.fileSelected(root.selectedFile);
                    root.accept();
                } else if (root.filesListView.currentIndex >= 0 && root.filesListView.currentIndex < root.filesListView.count) {
                    console.log("ZL Filepicker SELECT :", root.filesListView.currentItem, root.filesListView.currentItem.selectItem)
                    root.filesListView.currentItem.selectItem();
                }
                result = true;
                break;
            case "SWITCH_BACK_SHORT":
            case "SWITCH_BACK_BOLD":
            case "SWITCH_BACK_LONG":
                root.reject();
                result = true;
                break;
            case "KNOB0_UP":
            case "KNOB0_DOWN":
            case "KNOB1_UP":
            case "KNOB1_DOWN":
            case "KNOB2_UP":
            case "KNOB2_DOWN":
                result = true;
                break;
            case "KNOB3_UP":
                root.filesListView.currentIndex = Zynthian.CommonUtils.clamp(root.filesListView.currentIndex + 1, 0, root.filesListView.count - 1);
                result = true;
                break;
            case "KNOB3_DOWN":
                root.filesListView.currentIndex = Zynthian.CommonUtils.clamp(root.filesListView.currentIndex - 1, 0, root.filesListView.count - 1);
                result = true;
                break;
            default:
                result = true;
                break;
        }
        return result;
    }

    function goBack() {
        root.oldPath = folderModel.folder;
        let newPath = folderModel.folder.toString().replace("file://", "").split("/");
        newPath.pop();
        newPath = newPath.join("/");

        if (newPath.includes(rootFolder)) {
            folderModel.folder = newPath;
        } else {
            folderModel.folder = rootFolder;
        }
    }
    property var oldPath: undefined
    Connections {
        target: folderModel
        onStatusChanged: {
            if (folderModel.status == FolderListModel.Ready && root.oldPath != undefined) {
                // console.log("Resetting current index to match", root.oldPath, "at index", folderModel.indexOf(root.oldPath));
                root.filesListView.currentIndex = folderModel.indexOf(root.oldPath);
                root.oldPath = undefined;
            } else {
                filesListView.currentIndex = 0;
            }
        }
    }

    modal: true
    closePolicy: QQC2.Popup.CloseOnPressOutside

    x: Math.round(parent.width/2 - width/2)
    y: Math.round(parent.height/2 - height/2)
    width: header.Window.width
    height: saveMode && Qt.inputMethod.visible ? Math.round(header.Window.height / 2) : header.Window.height
    parent: QQC2.Overlay.overlay

    onOpenedChanged: {
        if (opened) {
            filesListView.saveModelData = null;
            namedFile.text = "";
            filesListView.currentIndex = -1;
        }
    }

    header: RowLayout {
        Layout.margins: Kirigami.Units.smallSpacing
        Kirigami.Heading {
            id: heading

            text: qsTr("Pick a file")
            font.pointSize: 16
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
        // TODO When we get to adding in tagging support, this is where we want to add switching to that view
        // QQC2.ToolButton {
        //     Layout.fillHeight: true
        //     display: QQC2.AbstractButton.TextBesideIcon
        //     icon.name: "view-list-details"
        //     text: qsTr("View...")
        // }
        QQC2.ToolButton {
            id: newFolderButton
            Layout.fillHeight: true
            display: QQC2.AbstractButton.TextBesideIcon
            icon.name: "folder-new"
            text: qsTr("New Folder...")
            readonly property var userEditableFolders: ["file:///zynthian/zynthian-my-data/sketches/my-sketches", "file:///zynthian/zynthian-my-data/samples/my-samples", "file:///zynthian/zynthian-my-data/sketchpads/my-sketchpads"]
            Connections {
                target: folderModel
                onFolderChanged: {
                    let newFolderButtonEnabled = false;
                    for (let userEditableFolderIndex = 0; userEditableFolderIndex < newFolderButton.userEditableFolders.length; ++userEditableFolderIndex) {
                        if (folderModel.folder.toString().startsWith(newFolderButton.userEditableFolders[userEditableFolderIndex])) {
                            newFolderButtonEnabled = true;
                            break;
                        }
                    }
                    newFolderButton.enabled = newFolderButtonEnabled;
                }
            }
            onClicked: newFolderDialog.open()
            Zynthian.DialogQuestion {
                id: newFolderDialog
                textInputVisible: true
                adjectiveNounButtonVisible: true
                title: qsTr("New Folder")
                text: qsTr("Enter the name for your new folder below\n%1").arg(newFolderPath)
                acceptText: qsTr("Yes, Create Folder")
                acceptEnabled: inputText.length > 0 && folderModel.folderPropertiesHelper.checkFileExists(newFolderDialog.newFolderPath) === false
                rejectText: qsTr("No, Don't Create Folder")
                readonly property string newFolderName: folderModel.folder + "/" + newFolderDialog.inputText
                readonly property string newFolderPath: newFolderName.substring(7) // There's a file:// at the start of this string, so get rid of that before throwing it at python
                onAccepted: {
                    // console.log("Creating new folder named", newFolderDialog.newFolderName, "and then entering it");
                    folderModel.folderPropertiesHelper.makePath(newFolderDialog.newFolderPath);
                    folderModel.folder = newFolderDialog.newFolderName;
                }
            }
        }
        Item {
            Layout.fillHeight: true
            Layout.minimumWidth: Kirigami.Units.gridUnit
            Layout.maximumWidth: Kirigami.Units.gridUnit
        }
        QQC2.ToolButton {
            Layout.fillHeight: true
            display: QQC2.AbstractButton.TextBesideIcon
            icon.name: "entry-edit"
            text: qsTr("Rename...")
            enabled: filePropertiesColumn.filePropertiesHelperObj && filePropertiesColumn.filePropertiesHelperObj.fileMetadata.isReadWrite
            onClicked: {
                let suffixStartIndex = filePropertiesColumn.filePropertiesHelperObj.fileMetadata.filename.indexOf(".");
                renameEntryDialog.inputText = filePropertiesColumn.filePropertiesHelperObj.fileMetadata.filename.substring(0, suffixStartIndex);
                renameEntryDialog.suffix = filePropertiesColumn.filePropertiesHelperObj.fileMetadata.filename.substring(suffixStartIndex);
                renameEntryDialog.containingDirectory = filePropertiesColumn.filePropertiesHelperObj.fileMetadata.filepath.substring(0, filePropertiesColumn.filePropertiesHelperObj.fileMetadata.filepath.lastIndexOf("/"));
                renameEntryDialog.open();
            }
            Zynthian.DialogQuestion {
                id: renameEntryDialog
                textInputVisible: true
                adjectiveNounButtonVisible: true
                title: qsTr("Rename?")
                text: filePropertiesColumn.filePropertiesHelperObj
                    ? filePropertiesColumn.filePropertiesHelperObj.fileMetadata.isDir
                        ? qsTr("Are you sure you wish to rename the folder:\n%1\nto\n%2").arg(filePropertiesColumn.filePropertiesHelperObj.fileMetadata.filename).arg(renameEntryDialog.newFilename)
                        : qsTr("Are you sure you wish to rename the file:\n%1\nto\n%2").arg(filePropertiesColumn.filePropertiesHelperObj.fileMetadata.filename).arg(renameEntryDialog.newFilename)
                    : ""
                acceptText: qsTr("Yes, Rename")
                acceptEnabled: filePropertiesColumn.filePropertiesHelperObj && filePropertiesColumn.filePropertiesHelperObj.checkFileExists(renameEntryDialog.newPathname) === false
                rejectText: qsTr("No, Don't Rename")
                // We only allow people to rename the base name here (that is, no suffixes), so we also disallow periods in the name, or it gets weird...
                readonly property string newPathname: containingDirectory + "/" + newFilename
                readonly property string newFilename: renameEntryDialog.inputText.replace(".", "_") + suffix
                property string containingDirectory: ""
                property string suffix: ""
                onAccepted: {
                    root.oldPath = "file://" + renameEntryDialog.newPathname;
                    filePropertiesColumn.filePropertiesHelperObj.renameFile(filePropertiesColumn.filePropertiesHelperObj.fileMetadata.filepath, renameEntryDialog.newPathname);
                }
            }
        }
        QQC2.ToolButton {
            Layout.fillHeight: true
            display: QQC2.AbstractButton.TextBesideIcon
            icon.name: "edit-move"
            text: qsTr("Move...")
            enabled: filePropertiesColumn.filePropertiesHelperObj && filePropertiesColumn.filePropertiesHelperObj.fileMetadata.isReadWrite
            onClicked: {
                let currentFileRoot = "";
                for (let userEditableFolderIndex = 0; userEditableFolderIndex < newFolderButton.userEditableFolders.length; ++userEditableFolderIndex) {
                    if (folderModel.folder.toString().startsWith(newFolderButton.userEditableFolders[userEditableFolderIndex])) {
                        currentFileRoot = newFolderButton.userEditableFolders[userEditableFolderIndex].substring(7);
                        break;
                    }
                }
                moveEntryLocationPicker.subfolders = filePropertiesColumn.filePropertiesHelperObj.getSubdirectoryList(currentFileRoot);
                moveEntryLocationPicker.currentSubfolder = filePropertiesColumn.filePropertiesHelperObj.fileMetadata.filepath.substring(0, filePropertiesColumn.filePropertiesHelperObj.fileMetadata.filepath.lastIndexOf("/"));
                let subfolderSubpaths = [];
                let currentLocationIndex = -1;
                for (let subfolderIndex = 0; subfolderIndex < moveEntryLocationPicker.subfolders.length; ++subfolderIndex) {
                    let subfolder = moveEntryLocationPicker.subfolders[subfolderIndex];
                    let newFilename = subfolder.path + "/" + filePropertiesColumn.filePropertiesHelperObj.fileMetadata.filename;
                    if (subfolder.path === moveEntryLocationPicker.currentSubfolder) {
                        currentLocationIndex = subfolderIndex;
                        subfolderSubpaths.push(subfolder.subpath + " (current location)");
                    } else if (filePropertiesColumn.filePropertiesHelperObj.checkFileExists(newFilename)) {
                        subfolderSubpaths.push(subfolder.subpath + " (filename exists)");
                    } else {
                        subfolderSubpaths.push(subfolder.subpath);
                    }
                }
                moveEntryLocationPicker.subfolderSubpaths = subfolderSubpaths;
                moveEntryLocationPicker.currentIndex = currentLocationIndex;
                moveEntryLocationPicker.onClicked();
            }
            // Show the type-local hierarchy (don't allow moving samples to sketches etc) as potential destinations
            // TODO and also any removable drives and their file system structure
            Zynthian.ComboBox {
                id: moveEntryLocationPicker
                visible: false;
                model: subfolderSubpaths
                property var subfolderSubpaths: []
                property var subfolders: []
                property string currentSubfolder: ""
                onActivated: {
                    if (moveEntryLocationPicker.currentIndex > -1) {
                        let destination = moveEntryLocationPicker.subfolders[moveEntryLocationPicker.currentIndex];
                        if (destination.path === moveEntryLocationPicker.currentSubfolder) {
                            // console.log("Attempting to move to the same location we're already in, aborting...");
                        } else {
                            let newFilename = destination.path + "/" + filePropertiesColumn.filePropertiesHelperObj.fileMetadata.filename;
                            if (filePropertiesColumn.filePropertiesHelperObj.checkFileExists(newFilename)) {
                                // console.log("Attempting to move to a location which already has a file with that name, aborting...");
                            } else {
                                // console.log("Moving file from", filePropertiesColumn.filePropertiesHelperObj.fileMetadata.filepath, "to", newFilename);
                                filePropertiesColumn.filePropertiesHelperObj.renameFile(filePropertiesColumn.filePropertiesHelperObj.fileMetadata.filepath, newFilename);
                                root.oldPath = "file://" + newFilename;
                                folderModel.folder = destination.path;
                            }
                        }
                    }
                }
            }
        }
        QQC2.ToolButton {
            Layout.fillHeight: true
            display: QQC2.AbstractButton.TextBesideIcon
            icon.name: "entry-delete"
            text: qsTr("Delete...")
            enabled: filePropertiesColumn.filePropertiesHelperObj && filePropertiesColumn.filePropertiesHelperObj.fileMetadata.isReadWrite
            onClicked: deleteEntryDialog.open()
            Zynthian.DialogQuestion {
                id: deleteEntryDialog
                title: qsTr("Delete?")
                text: filePropertiesColumn.filePropertiesHelperObj
                    ? isFolderAndHasContents
                        ? qsTr("To delete the folder %1, you will need to first remove its contents.").arg(filePropertiesColumn.filePropertiesHelperObj.fileMetadata.filename)
                        : qsTr("Are you sure you wish to delete:\n\n%1").arg(filePropertiesColumn.filePropertiesHelperObj.fileMetadata.filename)
                    : ""
                readonly property bool isFolderAndHasContents: filePropertiesColumn.filePropertiesHelperObj && filePropertiesColumn.filePropertiesHelperObj.fileMetadata.isDir && filePropertiesColumn.filePropertiesHelperObj.directoryHasContents(filePropertiesColumn.filePropertiesHelperObj.fileMetadata.filepath)
                acceptText: qsTr("Yes, Delete")
                acceptEnabled: isFolderAndHasContents === false
                rejectText: qsTr("No, Don't Delete")
                onAccepted: {
                    if (filesListView.currentIndex + 1 <= filesListView.count) {
                        // This option is "leave the highlight where it is" in a visual sense
                        root.oldPath = folderModel.get(filesListView.currentIndex + 1, "fileUrl");
                    } else if (filesListView.currentIndex > 0) {
                        // This option is "at least have /something/ highlighted
                        root.oldPath = folderModel.get(filesListView.currentIndex - 1, "fileUrl");
                    }
                    filePropertiesColumn.filePropertiesHelperObj.deleteFile(filePropertiesColumn.filePropertiesHelperObj.fileMetadata.filepath);
                }
            }
        }
    }
    footer: QQC2.Control {
        leftPadding: root.leftPadding
        topPadding: Kirigami.Units.smallSpacing
        rightPadding: root.rightPadding
        bottomPadding: root.bottomPadding
        contentItem: ColumnLayout {
            RowLayout {
                visible: root.saveMode
                QQC2.Label {
                    text: qsTr("File Name:")
                }
                QQC2.TextField {
                    id: namedFile
                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.6
                    onTextChanged: {
                        filesListView.saveModelData = {};
                        filesListView.saveModelData.fileName = namedFile.text;
                        filesListView.saveModelData.filePath = folderModel.folder.toString().replace("file://", "") + "/" + namedFile.text;
                        root.fileSelected(root.selectedFile);
                    }
                }
                PlayGridButton {
                    id: adjectiveNounButton
                    Layout.fillHeight: true
                    Layout.fillWidth: false
                    Layout.minimumWidth: height
                    Layout.maximumWidth: height
                    icon.name: "roll"
                    flat: true
                    onClicked: {
                        let suffixStart = namedFile.text.indexOf(".");
                        let fileSuffix = "";
                        if (suffixStart > -1) {
                            fileSuffix = namedFile.text.substring(suffixStart);
                        }
                        namedFile.text = Zynthbox.AdjectiveNoun.formatted("%1-%2") + fileSuffix;
                    }
                }
            }
            QQC2.Label {
                id: conflictLabel
                opacity: namedFile.text !== "" && (root.autoExtension === "" || namedFile.text.endsWith(root.autoExtension)
                    ? zynqtgui.file_exists(folderModel.folder.toString().replace("file://", "") + "/" + namedFile.text)
                    : zynqtgui.file_exists(folderModel.folder.toString().replace("file://", "") + "/" + namedFile.text + root.autoExtension)
                    )
                visible: opacity > 0
                Layout.preferredHeight: opacity > 0 ? implicitHeight : 0
                Layout.fillWidth: true
                text: qsTr("File Exists: Overwrite?")
                horizontalAlignment: Text.AlignHCenter
            }

            RowLayout {
                Layout.fillWidth: true
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                    text: qsTr("Cancel")
                    onClicked: root.reject();
                }
                QQC2.Button {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                    text: root.saveMode
                        ? conflictLabel.visible ? qsTr("Overwrite") : qsTr("Save")
                        : qsTr("Load")
                    enabled: root.saveMode
                        ? root.selectedFile !== null
                        : filePropertiesColumn.filePropertiesHelperObj && filePropertiesColumn.filePropertiesHelperObj.fileMetadata.isFile
                    onClicked: {
                        root.fileSelected(root.selectedFile);
                        root.accept();
                    }
                }
            }
        }
    }

    contentItem: Row {
        spacing: 0
        ColumnLayout {
            width: parent.width * 0.75
            height: parent.height
            RowLayout {
                readonly property var folderSplitArray: folderModel.folder.toString().replace("file://"+root.rootFolder, "").split("/").filter(function(e) { return e.length > 0 })

                id: folderBreadcrumbs
                Layout.fillWidth: true
                Layout.minimumHeight: Kirigami.Units.gridUnit * 2
                Layout.maximumHeight: Kirigami.Units.gridUnit * 2
                Layout.leftMargin: 6
                spacing: 2

                Zynthian.BreadcrumbButton {
                    id: homeButton
                    icon.name: "user-home-symbolic"
                    onClicked: {
                        folderModel.folder = root.rootFolder + "/"
                    }
                }

                Repeater {
                    id: breadcrumbsRepeater
                    model: folderBreadcrumbs.folderSplitArray
                    delegate: Zynthian.BreadcrumbButton {
                        text: modelData
                        onClicked: {
                            folderModel.folder = root.rootFolder + "/" + folderBreadcrumbs.folderSplitArray.slice(0, index+1).join("/")
                            filesListView.currentIndex = 0;
                        }
                    }
                }
            }
            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                contentItem: ListView {
                    id: filesListView
                    focus: true
                    onCurrentIndexChanged: {
                        positionViewAtIndex(currentIndex, ListView.Contain);
                    }
                    Layout.leftMargin: 8
                    clip: true

                    readonly property var selectedModelData: filesListView.currentItem ? filesListView.currentItem.itemModelData : null
                    property var saveModelData: null

                    function selectItem(model) {
                        console.log(model.fileName, model.filePath, model.index)
                        root.currentFileInfo = model;
                        if (model.fileIsDir) {
                            var path = model.filePath;

                            if (path.endsWith("/")) {
                                path = path.slice(0, path.length - 1);
                            }

                            folderModel.folder = path;
                        } else {
                            if (root.saveMode) {
                                namedFile.text = model.fileName;
                            }
                            root.filesListView.currentIndex = model.index;
                        }
                    }

                    QQC2.Label {
                        id: noFilesMessage
                        parent: filesListView
                        anchors.centerIn: parent
                        visible: filesListView.count === 0
                        text: qsTr("There are no files present")
                        verticalAlignment: Text.AlignVCenter
                        QQC2.Label {
                            anchors {
                                top: parent.bottom
                                margins: Kirigami.Units.largeSpacing
                                horizontalCenter: parent.horizontalCenter
                            }
                            verticalAlignment: Text.AlignTop
                            horizontalAlignment: Text.AlignHCenter
                            function getHelp(folderName) {
                                if (folderName == "file:///zynthian/zynthian-my-data/sketches/community-sketches") {
                                    return qsTr("When you download Sketches from the popup in Sample and Sketch slots, you will be able to find them here");
                                } else if (folderName == "file:///zynthian/zynthian-my-data/sketches/my-sketches") {
                                    return qsTr("This is where you should store your own Sketches.\nUse Save A Copy... in the Sketch slot popup after bouncing");
                                } else if (folderName == "file:///zynthian/zynthian-my-data/samples/my-samples") {
                                    return qsTr("This is where you should store your own samples.\nUse Save A Copy... in the Sample slot popup after recording.\nYou can also use WebConf to easily access the file system");
                                } else if (folderName == "file:///zynthian/zynthian-my-data/sounds/community-sounds") {
                                    return qsTr("When you use Get New Sounds, you will be able to find them here");
                                } else if (folderName == "file:///zynthian/zynthian-my-data/sounds/my-sounds") {
                                    return qsTr("This is where you should store your own sounds");
                                } else if (folderName == "file:///zynthian/zynthian-my-data/soundsets/community-soundsets") {
                                    return qsTr("When you use Get New Soundsets, you will be able to find them here");
                                } else if (folderName == "file:///zynthian/zynthian-my-data/soundsets/my-soundsets") {
                                    return qsTr("This is where you should store your own soundsets");
                                } else if (folderName == "file:///zynthian/zynthian-my-data/sequences/community-sequences") {
                                    return qsTr("When you use Get New Sequences, you will be able to find them here");
                                } else if (folderName == "file:///zynthian/zynthian-my-data/sequences/my-sequences") {
                                    return qsTr("This is where you should store sequences you create");
                                }
                                return "";
                            }
                            text: getHelp(folderModel.folder)
                        }
                    }

                    headerPositioning: ListView.PullBackHeader
                    header: Rectangle {
                        width: ListView.view.width
                        height: Kirigami.Units.gridUnit*2
                        z: 2
                        color: "#110000"

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
                                    source: "file-library-symbolic"
                                }

                                RowLayout {
                                    QQC2.Label {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        text: qsTr("Filename")
                                    }
                                }
                            }

                            Kirigami.Separator {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                            }
                        }
                    }

                    footerPositioning: ListView.OverlayFooter
                    footer: Item {
                        width: ListView.view.width
                        height: fileListFooterLayout.height
                        visible: folderInfoLabel.text !== ""
                        z: 3
                        Rectangle {
                            anchors {
                                fill: parent
                                margins: 1
                            }
                            color: "#110000"
                        }

                        ColumnLayout {
                            id: fileListFooterLayout
                            spacing: 0
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                                margins: 2
                            }
                            Kirigami.Separator {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                            }
                            QQC2.Label {
                                id: folderInfoLabel
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                Connections {
                                    target: folderModel
                                    onFolderChanged: {
                                        let foundOne = false;
                                        for (const folder in root.folderInfoStrings) {
                                            if (folderModel.folder.toString().startsWith(folder)) {
                                                folderInfoLabel.text = root.folderInfoStrings[folder];
                                                foundOne = true;
                                                break;
                                            }
                                        }
                                        if (foundOne === false) {
                                            folderInfoLabel.text = "";
                                        }
                                    }
                                }
                            }
                        }
                    }

                    model: FolderListModel {
                        id: folderModel
                        caseSensitive: false
                        showDirs: true
                        showDirsFirst: true
                        showDotAndDotDot: false
                        sortCaseSensitive: false
                        onFolderChanged: {
                            if (root.saveMode) {
                                filesListView.currentIndex = -1;
                            } else {
                                filesListView.currentIndex = 0;
                            }
                        }
                        readonly property var folderPropertiesHelper: Helpers.FilePropertiesHelper {
                            filePath: folderModel.folder.toString().substring(7) // There's a file:// at the start of this string, so get rid of that before throwing it at python
                        }
                        function describeFile(filePath) {
                            let description = "";
                            if (filePath.endsWith("Autosave.sketchpad.json")) {
                                description = qsTr("Active Working Version");
                            } else if (filePath.endsWith(".sketchpad.json")) {
                                description = qsTr("Saved Version");
                            } else if (filePath.endsWith(".sketch.wav")) {
                                description = qsTr("Sketch");
                            } else if (filePath.endsWith(".wav")) {
                                description = qsTr("Sample");
                            }
                            return description;
                        }
                    }
                    delegate: Rectangle {
                        readonly property var fileProperties: Helpers.FilePropertiesHelper {
                            filePath: model.filePath
                        }

                        id: fileListDelegate
                        width: ListView.view.width
                        height: Kirigami.Units.gridUnit*2
                        z: 1
                        color: ListView.isCurrentItem ? Kirigami.Theme.highlightColor : "transparent"
                        property bool isCurrentItem: ListView.isCurrentItem
                        onIsCurrentItemChanged: {
                            if (isCurrentItem) {
                                root.currentFileInfo = model;
                            }
                        }

                        readonly property var itemModelData: model
                        function selectItem() {
                            filesListView.selectItem(model)
                        }

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
                                    spacing: Kirigami.Units.largeSpacing
                                    QQC2.Label {
                                        Layout.fillHeight: true
                                        elide: Text.ElideMiddle
                                        textFormat: Text.StyledText
                                        text: model.fileName
                                    }
                                    Item { // Spacer
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                    }

                                    QQC2.Label {
                                        property string fileDescription: folderModel.describeFile(model.filePath)
                                        Layout.fillHeight: true
                                        Layout.alignment: Qt.AlignRight
                                        textFormat: Text.StyledText
                                        text: fileDescription == "" ? "" : "<i>(%1)</i>".arg(fileDescription)
                                    }
                                }
                            }

                            Kirigami.Separator {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            onClicked: fileListDelegate.selectItem()
                        }
                    }
                }
            }
        }

        Loader {
            id: filePropertiesColumn
            readonly property var filePropertiesHelperObj: filesListView.currentItem ? filesListView.currentItem.fileProperties : null
            width: parent.width * 0.25
            height: parent.height
            sourceComponent: Component {
                Flickable {
                    clip: true
                    flickableDirection: Flickable.VerticalFlick
                    contentHeight: filePropertiesSection.height

                    ColumnLayout {
                        id: filePropertiesSection

                        visible: filePropertiesColumn.filePropertiesHelperObj !== null && filePropertiesColumn.filePropertiesHelperObj.fileMetadata !== null

                        width: parent.width
                        spacing: 0

                        Kirigami.Icon {
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48

                            Layout.alignment: Qt.AlignHCenter
                            source: {
                                if (filePropertiesColumn.filePropertiesHelperObj && filePropertiesColumn.filePropertiesHelperObj.fileMetadata.isDir) {
                                    return "folder-symbolic"
                                }
                                else if (filePropertiesColumn.filePropertiesHelperObj && filePropertiesColumn.filePropertiesHelperObj.fileMetadata.isWav) {
                                    return "folder-music-symbolic"
                                } else {
                                    return "file-catalog-symbolic"
                                }
                            }
                        }

                        QQC2.Label {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: Kirigami.Units.gridUnit*10
                            elide: Text.ElideMiddle
                            text: filePropertiesColumn.filePropertiesHelperObj
                                    ? (filePropertiesColumn.filePropertiesHelperObj.fileMetadata.filename.length > 23
                                        ? filePropertiesColumn.filePropertiesHelperObj.fileMetadata.filename.substring(0, 20) + '...'
                                        : filePropertiesColumn.filePropertiesHelperObj.fileMetadata.filename)
                                    : ""
                        }

                        QQC2.Button {
                            id: previewButton
                            visible: filePropertiesColumn.filePropertiesHelperObj && filePropertiesColumn.filePropertiesHelperObj.fileMetadata.isWav
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: Kirigami.Units.gridUnit
                            Layout.bottomMargin: Kirigami.Units.gridUnit
                            text: filePropertiesColumn.filePropertiesHelperObj && filePropertiesColumn.filePropertiesHelperObj.isPreviewPlaying ? qsTr("Stop") : qsTr("Preview")
                            icon.name: filePropertiesColumn.filePropertiesHelperObj && filePropertiesColumn.filePropertiesHelperObj.isPreviewPlaying ? "media-playback-stop" : "media-playback-start"
                            onClicked: {
                                if (filePropertiesColumn.filePropertiesHelperObj.isPreviewPlaying) {
                                    filePropertiesColumn.filePropertiesHelperObj.stopPreview();
                                } else {
                                    filePropertiesColumn.filePropertiesHelperObj.playPreview();
                                }
                            }
                        }

                        Kirigami.BasicListItem {
                            Layout.fillWidth: true
                            visible: filePropertiesColumn.filePropertiesHelperObj && filePropertiesColumn.filePropertiesHelperObj.fileMetadata.isWav
                            label: qsTr("Size: %1").arg(filePropertiesColumn.filePropertiesHelperObj ? filePropertiesColumn.filePropertiesHelperObj.fileMetadata.humanSize : "")
                        }

                        Kirigami.BasicListItem {
                            Layout.fillWidth: true
                            visible: filePropertiesColumn.filePropertiesHelperObj && filePropertiesColumn.filePropertiesHelperObj.fileMetadata.isWav
                            label: qsTr("Sample Rate: %1KHz").arg(filePropertiesColumn.filePropertiesHelperObj ? filePropertiesColumn.filePropertiesHelperObj.fileMetadata.properties.sampleRate / 1000 : 0)
                        }

                        Kirigami.BasicListItem {
                            Layout.fillWidth: true
                            visible: filePropertiesColumn.filePropertiesHelperObj && filePropertiesColumn.filePropertiesHelperObj.fileMetadata.isWav
                            label: qsTr("Channels: %1").arg(filePropertiesColumn.filePropertiesHelperObj ? filePropertiesColumn.filePropertiesHelperObj.fileMetadata.properties.channels : 0)
                        }

                        Kirigami.BasicListItem {
                            Layout.fillWidth: true
                            visible: filePropertiesColumn.filePropertiesHelperObj && filePropertiesColumn.filePropertiesHelperObj.fileMetadata.isWav
                            label: qsTr("Duration: %1 secs")
                                    .arg(filePropertiesColumn.filePropertiesHelperObj
                                            ? filePropertiesColumn.filePropertiesHelperObj.fileMetadata.properties.duration && filePropertiesColumn.filePropertiesHelperObj.fileMetadata.properties.duration.toFixed(1)
                                            : 0)
                        }

                        Kirigami.BasicListItem {
                            Layout.fillWidth: true
                            visible: filePropertiesColumn.filePropertiesHelperObj && filePropertiesColumn.filePropertiesHelperObj.fileMetadata.isSketch && filePropertiesColumn.filePropertiesHelperObj.fileMetadata.properties.zynthbox.bpm > 0
                            label: qsTr("BPM: %1").arg(visible ? filePropertiesColumn.filePropertiesHelperObj.fileMetadata.properties.zynthbox.bpm : 0)
                        }

                        Kirigami.BasicListItem {
                            Layout.fillWidth: true
                            visible: filePropertiesColumn.filePropertiesHelperObj && filePropertiesColumn.filePropertiesHelperObj.fileMetadata.isSketch
                            label: visible
                                ? filePropertiesColumn.filePropertiesHelperObj.fileMetadata.properties.zynthbox.playbackStyle === "NonLoopingPlaybackStyle"
                                    ? qsTr("Playback Style: %1").arg("Non-looping")
                                    : filePropertiesColumn.filePropertiesHelperObj.fileMetadata.properties.zynthbox.playbackStyle === "LoopingPlaybackStyle"
                                        ? qsTr("Playback Style: %1").arg("Looping")
                                        : filePropertiesColumn.filePropertiesHelperObj.fileMetadata.properties.zynthbox.playbackStyle === "OneshotPlaybackStyle"
                                            ? qsTr("Playback Style: %1").arg("One-shot")
                                            : filePropertiesColumn.filePropertiesHelperObj.fileMetadata.properties.zynthbox.playbackStyle === "GranularNonLoopingPlaybackStyle"
                                                ? qsTr("Playback Style: %1").arg("Granular Non-looping")
                                                : filePropertiesColumn.filePropertiesHelperObj.fileMetadata.properties.zynthbox.playbackStyle === "GranularLoopingPlaybackStyle"
                                                    ? qsTr("Playback Style: %1").arg("Granular Looping")
                                                    : filePropertiesColumn.filePropertiesHelperObj.fileMetadata.properties.zynthbox.playbackStyle === "WavetableStyle"
                                                        ? qsTr("Playback Style: %1").arg("Wavetable")
                                                        : filePropertiesColumn.filePropertiesHelperObj.fileMetadata.properties.zynthbox.playbackStyle
                                : ""
                        }

                        Kirigami.BasicListItem {
                            Layout.fillWidth: true
                            visible: filePropertiesColumn.filePropertiesHelperObj && filePropertiesColumn.filePropertiesHelperObj.fileMetadata.isSketch && filePropertiesColumn.filePropertiesHelperObj.fileMetadata.properties.zynthbox.soundDescriptions.length > 0
                            label: visible ? qsTr("Sounds: %1").arg(filePropertiesColumn.filePropertiesHelperObj.fileMetadata.properties.zynthbox.soundDescriptions.join(", ")) : "(no sound snapshot)"
                        }
                    }
                }
            }
        }
    }
}
