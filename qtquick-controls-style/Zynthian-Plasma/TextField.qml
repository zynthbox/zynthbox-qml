/*
    SPDX-FileCopyrightText: 2016 Marco Martin <mart@kde.org>

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick 2.6
import QtQuick.Window 2.2
import QtQuick.Controls 2.4
import QtQuick.Templates 2.4 as T
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.kconfig 1.0
import "private" as Private
import org.kde.kirigami 2.5 as Kirigami
import "mobiletextselection" as MobileTextSelection

T.TextField {
    id: control

    // FIXME Outdated Plasma theme type stuff
    // This surely is supposed to be something more useful... but without defining them, things get errorsy, and that's just ugly
    // More to be done to make them properly go away, but for now...
    property bool __hasBackgroundAndMargins: false
    property int implicitBackgroundWidth: 0
    property int implicitBackgroundHeight: 0
    property int topInset: 0
    property int bottomInset: 0
    property int leftInset: 0
    property int rightInset: 0

    /* It might be preferrable to do background width OR content width if we
     * want content to stay within the background rather than expanding the
     * control, but this is maintaining compatibility with the pre-existing
     * behavior. Use the following 2 lines if you want text to stay within the
     * background:
    implicitBackgroundWidth + leftInset + rightInset
    || Math.ceil(Math.max(contentWidth, placeholder.implicitWidth)) + leftPadding + rightPadding
     */
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            Math.ceil(Math.max(contentWidth, placeholder.implicitWidth)) + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             contentHeight + topPadding + bottomPadding,
                             placeholder.implicitHeight + topPadding + bottomPadding)

    leftPadding: (__hasBackgroundAndMargins ? background.margins.left : 0)
    topPadding: __hasBackgroundAndMargins ? background.margins.top : 0
    rightPadding: (__hasBackgroundAndMargins ? background.margins.right : 0)
    bottomPadding: __hasBackgroundAndMargins ? background.margins.bottom : 0

    PlasmaCore.ColorScope.inherit: !background || !background.visible
    // FIXME Outdated Plasma theme type stuff
    // PlasmaCore.ColorScope.colorGroup: theme.ViewColorGroup - If there's a newer Plasma eventually, this'll want commenting back in

    color: theme.textColor
    selectionColor: theme.highlightColor
    selectedTextColor: theme.highlightedTextColor
    verticalAlignment: TextInput.AlignVCenter
    // Manually setting this fixes alignment in RTL layouts
    horizontalAlignment: TextInput.AlignLeft
    opacity: control.enabled ? 1 : 0.6
    hoverEnabled: !Kirigami.Settings.tabletMode

    // Work around Qt bug where NativeRendering breaks for non-integer scale factors
    // https://bugreports.qt.io/browse/QTBUG-70481
    renderType: Screen.devicePixelRatio % 1 !== 0 ? Text.QtRendering : Text.NativeRendering

    selectByMouse: !Kirigami.Settings.tabletMode

    cursorDelegate: Kirigami.Settings.tabletMode ? mobileCursor : null
    Component {
        id: mobileCursor
        MobileTextSelection.MobileCursor {
            target: control
        }
    }
    onFocusChanged: {
        if (focus) {
            MobileTextSelection.MobileTextActionsToolBar.controlRoot = control;
        }
    }

    onTextChanged: MobileTextSelection.MobileTextActionsToolBar.shouldBeVisible = false;
    onPressed: MobileTextSelection.MobileTextActionsToolBar.shouldBeVisible = true;

    onPressAndHold: {
        if (!Kirigami.Settings.tabletMode) {
            return;
        }
        forceActiveFocus();
        cursorPosition = positionAt(event.x, event.y);
        selectWord();
    }
    MobileTextSelection.MobileCursor {
        target: control
        selectionStartHandle: true
        property var rect: target.positionToRectangle(target.selectionStart)
        //FIXME: this magic values seem to be always valid, for every font,every dpi, every scaling
        x: rect.x + 5
        y: rect.y + 6
    }

    Label {
        id: placeholder
        enabled: false
        x: control.leftPadding
        y: control.topPadding
        width: control.availableWidth
        height: control.availableHeight

        text: control.placeholderText
        font: control.font
        // FIXME Outdated Qt type thing
        // This colour is a 5.12 addition
        // color: control.placeholderTextColor
        horizontalAlignment: control.horizontalAlignment
        verticalAlignment: control.verticalAlignment
        visible: !control.length && !control.preeditText && (!control.activeFocus || control.horizontalAlignment !== Qt.AlignHCenter)
        elide: Text.ElideRight
        renderType: control.renderType
    }

    background: PlasmaCore.FrameSvgItem {
        implicitWidth: units.gridUnit * 8 + margins.left + margins.right
        implicitHeight: units.gridUnit + margins.top + margins.bottom
        imagePath: "widgets/lineedit"
        prefix: "base"

        Private.TextFieldFocus {
            state: control.activeFocus ? "focus" : (control.hovered ? "hover" : "hidden")
            anchors.fill: parent
        }
    }
}
