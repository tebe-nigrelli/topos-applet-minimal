// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.private.topos as Topos

PlasmoidItem {
    id: root

    Topos.ToposClient {
        id: client
    }

    compactRepresentation: CompactRepresentation {
        client: client
        onActivated: root.expanded = !root.expanded
    }

    fullRepresentation: FullRepresentation {
        client: client
    }
}
