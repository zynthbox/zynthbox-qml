/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Main Class and Program for Zynthian GUI

Copyright (C) 2021 Marco Martin <mart@kde.org>

******************************************************************************

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 2 of
the License, or any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

For a full copy of the GNU General Public License see the LICENSE.txt file.

******************************************************************************
*/

import QtQuick 2.11
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import QtQuick.Window 2.1
import org.kde.kirigami 2.6 as Kirigami

import "components" as ZComponents
import "pages" as Pages

Kirigami.AbstractApplicationWindow {
    id: root

    readonly property PageScreenMapping pageScreenMapping: PageScreenMapping {}
    readonly property Item currentPage: screensLayer.layers.depth > 1 ? modalScreensLayer.currentItem : screensLayer.currentItem

    width: screen.width
    height: screen.height

    header: ZComponents.Breadcrumb {
        layerManager: screensLayer.layers
        leftHeaderControl: QQC2.Button {
                implicitWidth: height
                icon.name: "go-home"
                onClicked: zynthian.current_screen_id = 'main'
            }
        rightHeaderControl: ZComponents.StatusInfo {}
    }
    pageStack: screensLayer
    ScreensLayer {
        id: screensLayer
        parent: root.contentItem
        anchors.fill: parent
        initialPage: [root.pageScreenMapping.pageForScreen('main'), root.pageScreenMapping.pageForScreen('layer'), root.pageScreenMapping.pageForScreen('control')]
    }

    CustomTheme {}

    Instantiator {
        model: zynthian.keybinding.key_sequences_model
        delegate: Shortcut {
            //enabled: zynthian.keybinding.enabled
            sequence: model.display
            context: Qt.ApplicationShortcut
            onActivated: zynthian.process_keybinding_shortcut(model.display)
            onActivatedAmbiguously: zynthian.process_keybinding_shortcut(model.display)
        }
    }

    ModalScreensLayer {
        id: modalScreensLayer
        visible: false
    }

    QQC2.Dialog {
        id: confirmDialog
        standardButtons: QQC2.Dialog.Yes | QQC2.Dialog.No
        x: root.width / 2 - width / 2
        y: root.height / 2 - height / 2
        dim: true
        width: Math.round(Math.max(implicitWidth, root.width * 0.8))
        height: Math.round(Math.max(implicitHeight, root.height * 0.8))
        contentItem: Kirigami.Heading {
            level: 2
            text: zynthian.confirm.text
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        onAccepted: zynthian.confirm.accept()
        onRejected: zynthian.confirm.reject()
    }

    ZComponents.ModalLoadingOverlay {
        parent: root.contentItem.parent
        anchors.fill: parent
    }

    //FIXME: reimplement this toolbar
    footer: ColumnLayout {
        spacing: 0
        QQC2.ToolBar {
            Layout.fillWidth: true
            visible: screensLayer.layers.depth === 1 && screensLayer.currentIndex === 1

            contentItem: RowLayout {
                QQC2.ToolButton {
                    //Layout.fillWidth: true
                    Layout.preferredWidth: root.width/4
                    text: qsTr("Synth")
                    onClicked: zynthian.layer.select_engine()
                }
                Item {
                    Layout.fillWidth: true
                }
            }
        }
        QQC2.ToolBar {
            Layout.fillWidth: true
            contentItem: RowLayout {
                spacing: 0
                QQC2.ToolButton {
                    id: backButton
                    Layout.preferredWidth: root.width/4
                    text: qsTr("Back")
                    enabled: screensLayer.currentIndex > 0 || screensLayer.layers.depth > 1
                    opacity: enabled ? 1 : 0.3
                    onClicked: {
                        if (root.currentPage && root.currentPage.previousScreen.length > 0) {
                            if (screensLayer.layers.depth > 1) {
                                zynthian.current_modal_screen_id = root.currentPage.previousScreen;
                            } else {
                                zynthian.current_screen_id = root.currentPage.previousScreen;
                            }
                        } else {
                            zynthian.go_back();
                        }
                    }
                }
                QQC2.ToolButton {
                    Layout.preferredWidth: root.width/4
                    //enabled: layersPage.visible
                    opacity: enabled ? 1 : 0.3
                    text: qsTr("Layers")
                    onClicked: zynthian.current_screen_id = "layer"
                }
                QQC2.ToolButton {
                    Layout.preferredWidth: root.width/4
                    text: screensLayer.currentIndex === 1 ? qsTr("Favorites") : qsTr("Presets")
                    //enabled: presetsPage.visible
                    opacity: enabled ? 1 : 0.3
                    checkable: screensLayer.currentIndex === 1
                    checked: screensLayer.currentIndex === 1 && zynthian.preset.show_only_favorites
                    onClicked: zynthian.current_screen_id = "preset"
                    onCheckedChanged: {
                        if (screensLayer.currentIndex === 1) {
                            zynthian.preset.show_only_favorites = checked
                        }
                    }
                }
                QQC2.ToolButton {
                    Layout.preferredWidth: root.width/4
                    text: qsTr("Edit")
                    //enabled: controlPage.visible
                    opacity: enabled ? 1 : 0.3
                    onClicked: zynthian.current_screen_id = "control"
                }
            }
        }
    }
}

