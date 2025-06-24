import QtQuick 2.15
import org.kde.kirigami 2.4 as Kirigami

Rectangle {
    property bool highlighted: false
    property string highlightColor: "#ccaaff00" // green
    property string inactiveColor: Kirigami.Theme.textColor

    opacity: highlighted ? 1 : 0.5
    radius: height
    color: highlighted ? highlightColor : inactiveColor
}
