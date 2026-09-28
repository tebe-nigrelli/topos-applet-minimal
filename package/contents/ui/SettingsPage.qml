// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

ColumnLayout {
    id: root
    required property var client
    spacing: Kirigami.Units.smallSpacing

    RowLayout {
        Layout.fillWidth: true
        PlasmaComponents.Label {
            text: "History depth"
            Layout.fillWidth: true
        }
        PlasmaComponents.SpinBox {
            from: 1
            to: 1000
            value: root.client.historyLimit
            enabled: root.client.available
            onValueModified: root.client.setHistoryLimit(value)
        }
    }

    PlasmaComponents.CheckBox {
        text: "Persist history"
        checked: root.client.persistHistory
        enabled: root.client.available
        onToggled: root.client.setPersistHistory(checked)
    }

    RowLayout {
        Layout.fillWidth: true
        PlasmaComponents.Label {
            text: "Gesture distance"
            Layout.fillWidth: true
        }
        PlasmaComponents.SpinBox {
            from: 50
            to: 2000
            stepSize: 10
            value: root.client.gestureDistance
            enabled: root.client.available
            onValueModified: root.client.setGestureDistance(value)
        }
    }

    RowLayout {
        Layout.fillWidth: true
        PlasmaComponents.Label {
            text: "Settle threshold"
            Layout.fillWidth: true
        }
        PlasmaComponents.SpinBox {
            from: 5
            to: 95
            value: Math.round(root.client.settleThreshold * 100)
            enabled: root.client.available
            onValueModified: root.client.setSettleThreshold(value / 100.0)
        }
        PlasmaComponents.Label { text: "%" }
    }

    PlasmaComponents.CheckBox {
        text: "Show Topos handles in Grid View"
        checked: root.client.showHandles
        enabled: root.client.available
        onToggled: root.client.setShowHandles(checked)
    }

    PlasmaComponents.CheckBox {
        text: "Show bridge previews"
        checked: root.client.showBridgePreview
        enabled: root.client.available
        onToggled: root.client.setShowBridgePreview(checked)
    }

    PlasmaComponents.Button {
        text: "Clear History"
        icon.name: "edit-clear-history"
        enabled: root.client.available
        onClicked: root.client.clearHistory()
    }

    Item { Layout.fillHeight: true }
}
