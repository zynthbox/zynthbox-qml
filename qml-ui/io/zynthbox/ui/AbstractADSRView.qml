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

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as QQC2
import org.kde.kirigami 2.6 as Kirigami

Card {
    id: component
    property double attackValue: 1
    property double attackMax: 1
    property double attackWidth: attackMax
    property double decayValue: 1
    property double decayMax: 1
    property double decayWidth: decayMax
    property double sustainValue: 1
    property double sustainMax: 1
    property double sustainWidth: 1
    property double releaseValue: 1
    property double releaseMax: 1
    property double releaseWidth: releaseMax

    property alias attackLine: attackLineRect.visible
    property alias attackLabel: attackLineLabel.text
    property alias decayLine: decayLineRect.visible
    property alias decayLabel: decayLineLabel.text
    property alias sustainLine: sustainLineRect.visible
    property alias sustainLabel: sustainLineLabel.text
    property alias releaseLine: releaseLineRect.visible
    property alias releaseLabel: releaseLineLabel.text
    property alias endLine: endLineRect.visible
    property alias endLabel: endLineLabel.text

    function requestPaint() {
        canvas.requestPaint();
    }

    contentItem: Canvas {
        id: canvas
        onPaint: {
            var ctx = getContext("2d");
            ctx.lineWidth = 3;
            ctx.strokeStyle = Kirigami.Theme.highlightColor
            // var grd = ctx.createLinearGradient(0, 0, 0, height)
            // grd.addColorStop(0, Qt.rgba(Kirigami.Theme.highlightColor.r,
            //                             Kirigami.Theme.highlightColor.g,
            //                             Kirigami.Theme.highlightColor.b,
            //                             0.4))
            // grd.addColorStop(0.8, Qt.rgba(Kirigami.Theme.highlightColor.r,
            //                             Kirigami.Theme.highlightColor.g,
            //                             Kirigami.Theme.highlightColor.b,
            //                             0))
            // ctx.fillStyle = grd;

            let actualWidth = component.attackValue + component.decayValue + component.sustainWidth + component.releaseValue;
            let maximumWidth = component.attackWidth + component.decayWidth + component.sustainWidth + component.releaseWidth;

            let attackWidth = width * component.attackValue / maximumWidth;
            let decayWidth = width * component.decayValue / maximumWidth;
            let sustainWidth = width * component.sustainWidth / maximumWidth;
            let releaseWidth = width * component.releaseValue / maximumWidth;

            let top = Kirigami.Units.gridUnit
            let bottom = height - Kirigami.Units.gridUnit * 2

            ctx.clearRect(0, 0, width, height);
            ctx.beginPath();

            let currentX = width * ((maximumWidth - actualWidth) / maximumWidth) / 2;
            attackLineRect.x = currentX;
            ctx.moveTo(currentX, top + bottom);
            currentX += attackWidth;
            decayLineRect.x = currentX;
            ctx.lineTo(currentX, top);
            currentX += decayWidth;
            sustainLineRect.x = currentX;
            ctx.lineTo(currentX, top + bottom * (1 - component.sustainValue/component.sustainMax));
            currentX += sustainWidth;
            releaseLineRect.x = currentX;
            ctx.lineTo(currentX, top + bottom * (1 - component.sustainValue/component.sustainMax));
            currentX += releaseWidth;
            endLineRect.x = currentX;
            ctx.lineTo(currentX, top + bottom);
            //ctx.closePath();
            ctx.stroke();
            // ctx.fill();
        }
        Rectangle {
            id: attackLineRect
            anchors {
                top: parent.top
                bottom: parent.bottom
            }
            visible: false
            opacity: 0.8
            width: 1
            color: Kirigami.Theme.textColor
            QQC2.Label {
                id: attackLineLabel
                anchors {
                    top: parent.bottom
                    left: parent.left
                }
                rotation: -90
                transformOrigin: Item.TopLeft
            }
        }
        Rectangle {
            id: decayLineRect
            anchors {
                top: parent.top
                bottom: parent.bottom
            }
            visible: false
            opacity: 0.8
            width: 1
            color: Kirigami.Theme.textColor
            QQC2.Label {
                id: decayLineLabel
                anchors {
                    top: parent.bottom
                    left: parent.left
                }
                rotation: -90
                transformOrigin: Item.TopLeft
            }
        }
        Rectangle {
            id: sustainLineRect
            anchors {
                top: parent.top
                bottom: parent.bottom
            }
            visible: false
            opacity: 0.8
            width: 1
            color: Kirigami.Theme.textColor
            QQC2.Label {
                id: sustainLineLabel
                anchors {
                    top: parent.bottom
                    left: parent.left
                }
                rotation: -90
                transformOrigin: Item.TopLeft
            }
        }
        Rectangle {
            id: releaseLineRect
            anchors {
                top: parent.top
                bottom: parent.bottom
            }
            visible: false
            opacity: 0.8
            width: 1
            color: Kirigami.Theme.textColor
            QQC2.Label {
                id: releaseLineLabel
                anchors {
                    top: parent.bottom
                    left: parent.left
                }
                rotation: -90
                transformOrigin: Item.TopLeft
            }
        }
        Rectangle {
            id: endLineRect
            anchors {
                top: parent.top
                bottom: parent.bottom
            }
            visible: false
            opacity: 0.8
            width: 1
            color: Kirigami.Theme.textColor
            QQC2.Label {
                id: endLineLabel
                anchors {
                    top: parent.bottom
                    left: parent.left
                }
                rotation: -90
                transformOrigin: Item.TopLeft
            }
        }
    }
}
