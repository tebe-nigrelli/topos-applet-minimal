// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.private.topos as Topos

PlasmoidItem {
    id: root

    readonly property bool inPanel: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
        || Plasmoid.formFactor === PlasmaCore.Types.Vertical

    // Match panel widgets such as Clipboard: keep the icon in the panel and
    // put the full representation in Plasma's popup dialog.
    preferredRepresentation: root.inPanel ? root.compactRepresentation : root.fullRepresentation

    Topos.ToposClient {
        id: client
    }

    compactRepresentation: CompactRepresentation {
        client: client
    }

    fullRepresentation: FullRepresentation {
        client: client
    }
}
