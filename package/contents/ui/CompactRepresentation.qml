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

    // Match Plasma's compact-representation click semantics: remember whether
    // the popup was open when the press started, then toggle from that state.
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

    Kirigami.Icon {
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height) - Kirigami.Units.smallSpacing * 2
        height: width
        source: "preferences-desktop-virtual"
        active: false
        opacity: client.available ? 1.0 : 0.45
    }
}
