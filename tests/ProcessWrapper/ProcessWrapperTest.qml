import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.6 as Kirigami

ApplicationWindow {
    id: root

    ColumnLayout {
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: app.consoleOutput
            delegate: Label {
                text: modelData
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2

            TextArea {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
            Button {
                Layout.fillHeight: true
                Layout.preferredWidth: height
                source: "keyboard-enter"
            }
        }
    }
}
