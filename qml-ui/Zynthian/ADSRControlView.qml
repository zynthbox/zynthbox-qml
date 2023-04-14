/* -*- coding: utf-8 -*-
******************************************************************************
ZYNTHIAN PROJECT: Zynthian Qt GUI

Controller based UI for handling ADSR envelopes

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

import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

GridLayout {
    rows: 2
    columns: 4

    property alias attackController: attackSlider.controller
    property alias decayController: decaySlider.controller
    property alias sustainController: sustainSlider.controller
    property alias releaseController: releaseSlider.controller

    AbstractADSRView {
        id: canvas
        Layout.columnSpan: 4
        implicitWidth: 1
        implicitHeight: 1
        Layout.fillWidth: true
        Layout.fillHeight: true

        attackValue: attackSlider.slider.value
        attackMax: attackSlider.slider.to
        decayValue: decaySlider.slider.value
        decayMax: decaySlider.slider.to
        sustainValue: sustainSlider.slider.value
        sustainMax: sustainSlider.slider.to
        releaseValue: releaseSlider.slider.value
        releaseMax: releaseSlider.slider.to
    }

    SliderController {
        id: attackSlider
        implicitWidth: 1
        implicitHeight: 1
        onValueChanged: canvas.requestPaint()
        encoderIndex: 0
    }
    SliderController {
        id: decaySlider
        implicitWidth: 1
        implicitHeight: 1
        onValueChanged: canvas.requestPaint()
        encoderIndex: 1
    }
    SliderController {
        id: sustainSlider
        implicitWidth: 1
        implicitHeight: 1
        onValueChanged: canvas.requestPaint()
        encoderIndex: 2
    }
    SliderController {
        id: releaseSlider
        implicitWidth: 1
        implicitHeight: 1
        onValueChanged: canvas.requestPaint()
        encoderIndex: 3
    }
}
