// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

MouseArea {
    id: root

    required property var client
    required property PlasmoidItem plasmoidItem

    property bool wasExpanded: false

    implicitWidth: Kirigami.Units.gridUnit * 2
    implicitHeight: Kirigami.Units.gridUnit * 2
    hoverEnabled: true

    onPressed: root.wasExpanded = root.plasmoidItem.expanded
    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            root.plasmoidItem.expanded = !root.wasExpanded
        }
    }

    Accessible.name: "Topos"
    Accessible.description: client.available
        ? (client.activeProfile || "Grid Default")
        : client.unavailableReason
    Accessible.role: Accessible.Button

    TopologyMap {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing / 2
        client: root.client
        compact: true
        interactive: false
        opacity: root.client.available ? 1.0 : 0.45
    }
}
