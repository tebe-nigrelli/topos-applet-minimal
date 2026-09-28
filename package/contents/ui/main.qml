// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.topos as Topos

PlasmoidItem {
    id: root

    readonly property bool inPanel: plasmoid.formFactor === PlasmaCore.Types.Horizontal
        || plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool viewMode: plasmoid.configuration.widgetMode === "view"

    preferredRepresentation: root.inPanel ? compactRepresentation : fullRepresentation
    hideOnWindowDeactivate: root.inPanel

    Topos.ToposClient {
        id: toposClient
    }

    compactRepresentation: CompactRepresentation {
        client: toposClient
        plasmoidItem: root
    }

    fullRepresentation: Item {
        implicitWidth: Kirigami.Units.gridUnit * 24
        implicitHeight: Kirigami.Units.gridUnit * 28
        Layout.minimumWidth: Kirigami.Units.gridUnit * 24
        Layout.minimumHeight: Kirigami.Units.gridUnit * 20
        Layout.maximumWidth: Kirigami.Units.gridUnit * 80
        Layout.maximumHeight: Kirigami.Units.gridUnit * 40
        Layout.preferredHeight: implicitHeight

        Loader {
            anchors.fill: parent
            sourceComponent: root.viewMode ? mapComponent : controlComponent
        }
    }

    Component {
        id: controlComponent
        FullRepresentation {
            client: toposClient
        }
    }

    Component {
        id: mapComponent
        MapRepresentation {
            client: toposClient
        }
    }
}
