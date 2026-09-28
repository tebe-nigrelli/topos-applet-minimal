// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Item {
    id: root
    required property var model
    required property var client

    readonly property string name: model.name
    readonly property bool builtin: model.builtin
    readonly property bool active: model.active

    signal activated(string name, bool builtin)

    property bool renaming: false
    property string pendingRenameName: ""
    readonly property string displayName: root.builtin && root.name === "Base Grid" ? "Grid Default" : root.name
    implicitHeight: Kirigami.Units.gridUnit * 2.25

    Rectangle {
        anchors.fill: parent
        radius: Kirigami.Units.cornerRadius
        color: root.active ? Kirigami.Theme.highlightColor : "transparent"
        opacity: root.active ? 0.18 : 1.0
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Kirigami.Units.smallSpacing
        anchors.rightMargin: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents.Label {
            text: root.active ? "✓" : ""
            Layout.preferredWidth: Kirigami.Units.gridUnit
            horizontalAlignment: Text.AlignHCenter
        }

        PlasmaComponents.ItemDelegate {
            visible: !root.renaming
            Layout.fillWidth: true
            text: root.displayName + (!root.builtin && root.active && root.client.dirty ? " — modified" : "")
            onClicked: root.activated(root.name, root.builtin)
        }

        InlineNameEditor {
            visible: !root.builtin && root.renaming
            Layout.fillWidth: true
            initialText: root.name
            onCommitted: newName => {
                if (newName.length === 0 || newName === root.name) {
                    root.renaming = false
                    return
                }
                root.pendingRenameName = newName
                if (root.client.builtinExists(newName)) {
                    builtinConflict.open()
                } else if (root.client.profileExists(newName)) {
                    renameConflict.open()
                } else {
                    root.client.renameProfile(root.name, newName, false)
                    root.renaming = false
                }
            }
            onCanceled: root.renaming = false
        }

        PlasmaComponents.Label {
            visible: root.builtin && !root.renaming
            text: "Built-in"
            opacity: 0.65
            Layout.alignment: Qt.AlignVCenter
        }

        PlasmaComponents.ToolButton {
            visible: !root.builtin && !root.renaming
            icon.name: "document-edit"
            text: "Rename"
            onClicked: root.renaming = true
        }
    }

    QQC2.Dialog {
        id: renameConflict
        title: "Profile already exists"
        modal: true
        standardButtons: QQC2.Dialog.Yes | QQC2.Dialog.Cancel
        contentItem: PlasmaComponents.Label {
            text: "Replace ‘" + root.pendingRenameName + "’?"
            wrapMode: Text.Wrap
        }
        onAccepted: {
            root.client.renameProfile(root.name, root.pendingRenameName, true)
            root.renaming = false
        }
        onRejected: root.renaming = true
    }

    QQC2.Dialog {
        id: builtinConflict
        title: "Built-in name"
        modal: true
        standardButtons: QQC2.Dialog.Ok
        contentItem: PlasmaComponents.Label {
            text: "Built-in topology names cannot be replaced. Choose a different name."
            wrapMode: Text.Wrap
        }
        onAccepted: root.renaming = true
    }
}
