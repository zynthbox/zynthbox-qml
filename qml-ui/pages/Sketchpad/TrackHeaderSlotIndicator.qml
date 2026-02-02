import QtQuick 2.15
import org.kde.kirigami 2.4 as Kirigami
import io.zynthbox.ui 1.0 as ZUI

Rectangle {
    property bool highlighted: false
    property string highlightColor: "#ccaaff00" // green
    property string inactiveColor: Kirigami.Theme.textColor

    opacity: highlighted ? 1 : 0
    radius: ZUI.Theme.radius
    color: highlighted ? highlightColor : inactiveColor
}
