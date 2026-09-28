// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

MouseArea {
    id: root
    required property var client
    signal activated()

    implicitWidth: Kirigami.Units.gridUnit * 2
    implicitHeight: Kirigami.Units.gridUnit * 2
    hoverEnabled: true
    onClicked: activated()

    Accessible.name: "Topos"
    Accessible.description: client.available
        ? (client.dirty ? "Unsaved topology" : (client.activeProfile || "Base Grid"))
        : client.unavailableReason

    Kirigami.Icon {
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height) - Kirigami.Units.smallSpacing * 2
        height: width
        source: "preferences-desktop-virtual"
        opacity: client.available ? 1.0 : 0.45
    }

    QQC2.ToolTip.visible: containsMouse
    QQC2.ToolTip.text: client.available
        ? "Topos\n" + (client.dirty ? "Unsaved topology" : (client.activeProfile || "Base Grid"))
        : "Topos\n" + client.unavailableReason
}
