import QtQuick 2.10
import QtQuick.Layouts 1.4
import QtQuick.Controls 2.2 as QQC2
import org.kde.kirigami 2.4 as Kirigami

QQC2.Button {
  Layout.preferredHeight: 40
  Layout.preferredWidth: 40
  Layout.alignment: Qt.AlignHCenter
  
  Kirigami.Theme.inherit: false
  Kirigami.Theme.colorSet: Kirigami.Theme.Button
  
  background: Rectangle {
    radius: 2
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Button
    border {
      width: 1
      color: Kirigami.Theme.textColor
    }
    color: Kirigami.Theme.backgroundColor
  }
} 
