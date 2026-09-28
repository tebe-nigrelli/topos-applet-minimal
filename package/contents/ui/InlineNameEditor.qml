// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import org.kde.plasma.components as PlasmaComponents

PlasmaComponents.TextField {
    id: root
    property string initialText: ""
    signal committed(string name)
    signal canceled()

    text: initialText
    selectByMouse: true

    onVisibleChanged: {
        if (visible) {
            text = initialText
            forceActiveFocus()
            selectAll()
        }
    }

    onAccepted: committed(text.trim())

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            canceled()
            event.accepted = true
        }
    }
}
