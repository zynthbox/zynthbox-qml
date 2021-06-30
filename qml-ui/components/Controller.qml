/**
 *
 *  SPDX-FileCopyrightText: 2021 Marco Martin <mart@kde.org>
 *
 *  SPDX-License-Identifier: LGPL-2.0-or-later
 */

import QtQuick 2.1
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami


Card {
    id: root

    // instance of zynthian_gui_controller.py, TODO: should be registered in qml?
    property QtObject controller

    Layout.fillWidth: true
    Layout.fillHeight: true

    contentItem: ColumnLayout {
        Kirigami.Heading {
            text: root.controller.title
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            level: 2
        }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // TODO: manage logarythmic controls?
            QQC2.Dial {
                anchors {
                    fill: parent
                    margins: Kirigami.Units.largeSpacing
                }
                stepSize: root.controller.step_size
                value: root.controller.value
                from: 0
                to: root.controller.max_value
                scale: root.controller.value_type !== "bool"
                enabled: root.controller.value_type !== "bool"
                onMoved: root.controller.value = value

                Kirigami.Heading {
                    anchors.centerIn: parent
                    text: root.controller.value_print
                }
                Behavior on value {
                    NumberAnimation {
                        duration: Kirigami.Units.longDuration
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: Kirigami.Units.longDuration
                    }
                }
            }
            QQC2.Switch {
                anchors.fill: parent
                scale: root.controller.value_type === "bool"
                enabled: root.controller.value_type === "bool"
                checked: root.controller.value !== 0
                onToggled: root.controller.value = checked ? 1 : 0
                Behavior on scale {
                    NumberAnimation {
                        duration: Kirigami.Units.longDuration
                    }
                }
                Kirigami.Heading {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: parent.height / 5
                    }
                    text: parent.checked ? "ON" : "OFF"
                }
            }
        }
        QQC2.Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.controller.midi_bind
        }
    }
}
