import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

QQC2.Button {
    id: root

    property alias active: visibleBinding.value

    Layout.preferredWidth: Kirigami.Units.gridUnit * 2
    Layout.preferredHeight: Kirigami.Units.gridUnit * 2

    Binding {
        id: visibleBinding

        target: root
        property: "visible"
        delayed: true
    }
}
