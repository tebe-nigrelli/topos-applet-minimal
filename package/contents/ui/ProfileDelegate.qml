// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Item {
    id: root
    required property string name
    required property bool builtin
    required property bool active
    required property var client

    signal activated(string name, bool builtin)

    property bool renaming: false
    property string pendingRenameName: ""
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

        PlasmaComponents.Button {
            visible: !root.renaming
            flat: true
            Layout.fillWidth: true
            text: root.name + (root.active && root.client.dirty ? " — modified" : "")
            onClicked: root.activated(root.name, root.builtin)
        }

        InlineNameEditor {
            visible: root.renaming
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
