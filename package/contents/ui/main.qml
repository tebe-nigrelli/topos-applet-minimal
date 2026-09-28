// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.private.topos as Topos

PlasmoidItem {
    id: root

    // Panels use the normal compact icon + Plasma popup. On the desktop the
    // full representation is the widget itself, so clicking it never creates
    // a second popup/overlay.
    readonly property bool inPanel: plasmoid.formFactor === PlasmaCore.Types.Horizontal
        || plasmoid.formFactor === PlasmaCore.Types.Vertical

    preferredRepresentation: root.inPanel ? compactRepresentation : fullRepresentation
    hideOnWindowDeactivate: root.inPanel

    // CompactRepresentation deliberately has no local ToolTip. Plasma may show
    // its normal applet tooltip, but we do not add a second overlay containing
    // transient state such as "Unsaved topology".

    Topos.ToposClient {
        id: toposClient
    }

    compactRepresentation: CompactRepresentation {
        client: toposClient
        plasmoidItem: root
    }

    fullRepresentation: FullRepresentation {
        client: toposClient
    }
}
