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

import Zynthian 1.0 as Zynthian
import "pages" as Pages

Kirigami.AbstractApplicationWindow {
    id: root

    readonly property PageScreenMapping pageScreenMapping: PageScreenMapping {}
    readonly property Item currentPage: screensLayer.layers.depth > 1 ? modalScreensLayer.currentItem : screensLayer.currentItem
    onCurrentPageChanged: zynthian.current_qml_page = currentPage

    property bool headerVisible: true

    function showConfirmationDialog() {
        confirmDialog.open()
    }
    function hideConfirmationDialog() {
        confirmDialog.close()
    }
    Component.onCompleted: {
        root.showFullScreen()
    }

    width: screen.width
    height: screen.height

    header: Zynthian.Breadcrumb {
        visible: root.headerVisible
        layerManager: screensLayer.layers
        leftHeaderControl: RowLayout {
            spacing: 0
            Zynthian.BreadcrumbButton {
                id: homeButton
                implicitWidth: height
                icon.name: "go-home"
                icon.color: customTheme.Kirigami.Theme.textColor
                rightPadding: Kirigami.Units.largeSpacing*2
                onClicked: zynthian.current_screen_id = 'main'
                highlighted: zynthian.current_screen_id === 'main'
            }
            Zynthian.BreadcrumbButton {
                text: screensLayer.layers.depth > 1 && zynthian.engine.midi_channel !== null && zynthian.current_screen_id === 'engine'
                        ? zynthian.engine.midi_channel > 5 ? "    6." + (zynthian.engine.midi_channel - 5) : zynthian.engine.midi_channel + 1 + "ˬ"
                        : zynthian.layer.selector_path_element > 5 ? "    6." + (zynthian.layer.selector_path_element - 5) : zynthian.layer.selector_path_element + "ˬ"
                onClicked: layersMenu.visible = true
                highlighted: zynthian.current_screen_id === 'layer' || zynthian.current_screen_id === 'fixed_layers'
                QQC2.Menu {
                    id: layersMenu
                    y: parent.height
                    modal: true
                    dim: false
                    Repeater {
                        model: zynthian.fixed_layers.selector_list
                        delegate: QQC2.MenuItem {
                            height: visible ? implicitHeight : 0
                            enabled: index !== 5 && (index < 5 || model.display.indexOf("- -") === -1)
                            text: model.display
                            width: parent.width
                            onClicked: zynthian.fixed_layers.activate_index(index === 5 ? 6 : index)
                            highlighted: zynthian.fixed_layers.current_index === index
                        }
                    }
                }
            }
        }
        rightHeaderControl: Zynthian.StatusInfo {}
    }
    pageStack: screensLayer
    ScreensLayer {
        id: screensLayer
        parent: root.contentItem
        anchors.fill: parent
        initialPage: [root.pageScreenMapping.pageForScreen('main'), root.pageScreenMapping.pageForScreen('layer')]
    }

    ModalScreensLayer {
        id: modalScreensLayer
        visible: false
    }

    CustomTheme {
        id: customTheme
    }

    background: Rectangle {
        Kirigami.Theme.inherit: false
        // TODO: this should eventually go to Window and the panels to View
        Kirigami.Theme.colorSet: Kirigami.Theme.View
        color: Kirigami.Theme.backgroundColor
    }

    Instantiator {
        model: zynthian.keybinding.key_sequences_model
        delegate: Shortcut {
            sequence: model.display
            context: Qt.ApplicationShortcut
            onActivated: zynthian.process_keybinding_shortcut(model.display)
            onActivatedAmbiguously: zynthian.process_keybinding_shortcut(model.display)
        }
    }

    QQC2.Dialog {
        id: confirmDialog
        x: root.width / 2 - width / 2
        y: root.height / 2 - height / 2
        dim: true
        modal: true
        width: Math.round(Math.max(implicitWidth, root.width * 0.8))
        height: Math.round(Math.max(implicitHeight, root.height * 0.8))
        contentItem: Kirigami.Heading {
            level: 2
            text: zynthian.confirm.text
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        onAccepted: zynthian.confirm.accept()
        onRejected: zynthian.confirm.reject()
        footer: QQC2.Control {
            leftPadding: confirmDialog.leftPadding
            topPadding: Kirigami.Units.largeSpacing
            rightPadding: confirmDialog.rightPadding
            bottomPadding: confirmDialog.bottomPadding
            contentItem: RowLayout {
                spacing: Kirigami.Units.smallSpacing
                QQC2.Button {
                    implicitWidth: 1
                    Layout.fillWidth: true
                    text: qsTr("No")
                    onClicked: confirmDialog.reject()
                }
                QQC2.Button {
                    implicitWidth: 1
                    Layout.fillWidth: true
                    text: qsTr("Yes")
                    onClicked: confirmDialog.accept()
                }
            }
        }
    }

    Zynthian.ModalLoadingOverlay {
        parent: root.contentItem.parent
        anchors.fill: parent
        z: 9999999
    }

    footer: Zynthian.ActionBar {
        currentPage: root.currentPage
        visible: root.controlsVisible
       // height: Math.max(implicitHeight, Kirigami.Units.gridUnit * 3)
    }

    Loader {
        parent: root.contentItem.parent
        z: Qt.inputMethod.visible ? 99999999 : 1
        anchors {
            left: parent.left
            bottom: parent.bottom
            right: parent.right
            //bottomMargin: -root.footer.height
        }
        height: Math.min(parent.height / 2, Math.max(parent.height/3, Kirigami.Units.gridUnit * 15))
        source: "./VirtualKeyboard.qml"
    }

    Connections {
        target: zynthian
        onMiniPlayGridToggle: miniPlayGridDrawer.visible = !miniPlayGridDrawer.visible
    }
    QQC2.Drawer {
        id: miniPlayGridDrawer
        width: root.width
        height: Kirigami.Units.gridUnit * 10
        edge: Qt.BottomEdge
        modal: false

        contentItem: MiniPlayGrid {}
    }
}

