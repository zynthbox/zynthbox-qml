import QtQuick 2.15

Rectangle {
    property bool highlighted: false
    property string highlightColor: "#ccaaff00" // green
    property string inactiveColor: "#11ffffff"

    radius: height
    color: highlighted ? highlightColor : inactiveColor
}
