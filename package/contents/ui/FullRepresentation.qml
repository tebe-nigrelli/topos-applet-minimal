// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Item {
    id: root
    required property var client

    implicitWidth: Kirigami.Units.gridUnit * 23
    implicitHeight: Kirigami.Units.gridUnit * 28

    property bool settingsOpen: false
    property bool saveEditing: false
    property string pendingSaveName: ""

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Button {
                text: "Save"
                icon.name: "document-save"
                enabled: root.client.available
                Layout.fillWidth: true
                onClicked: {
                    root.pendingSaveName = root.client.activeProfile || root.client.lastLoadedProfile || "New topology"
                    root.saveEditing = true
                    root.settingsOpen = false
                }
            }

            PlasmaComponents.Button {
                text: "Undo"
                icon.name: "edit-undo"
                enabled: root.client.available && root.client.canUndo
                Layout.fillWidth: true
                onClicked: root.client.undo()
                onPressAndHold: undoHistory.open()
            }

            PlasmaComponents.Button {
                text: "Redo"
                icon.name: "edit-redo"
                enabled: root.client.available && root.client.canRedo
                Layout.fillWidth: true
                onClicked: root.client.redo()
                onPressAndHold: redoHistory.open()
            }

            PlasmaComponents.Button {
                text: "Settings"
                icon.name: "settings-configure"
                checkable: true
                checked: root.settingsOpen
                Layout.fillWidth: true
                onClicked: root.settingsOpen = checked
            }
        }

        PlasmaComponents.TextField {
            id: search
            Layout.fillWidth: true
            visible: !root.settingsOpen
            placeholderText: "Search configurations…"
            enabled: root.client.available
            onTextChanged: root.client.profiles.filter = text
        }

        InlineNameEditor {
            id: saveEditor
            Layout.fillWidth: true
            visible: root.saveEditing && !root.settingsOpen
            initialText: root.pendingSaveName
            placeholderText: "Topology name"

            onCommitted: name => {
                if (name.length === 0) {
                    return
                }
                root.pendingSaveName = name
                if (root.client.builtinExists(name)) {
                    builtinConflict.open()
                } else if (root.client.profileExists(name)) {
                    overwriteConflict.open()
                } else {
                    root.client.saveProfile(name, false)
                    root.saveEditing = false
                }
            }
            onCanceled: root.saveEditing = false
        }

        PlasmaComponents.Label {
            Layout.fillWidth: true
            visible: !root.client.available
            text: root.client.unavailableReason
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }

        PlasmaComponents.Label {
            Layout.fillWidth: true
            visible: root.client.available && root.client.lastError.length > 0
            text: root.client.lastError
            color: Kirigami.Theme.negativeTextColor
            wrapMode: Text.Wrap
        }

        SettingsPage {
            visible: root.settingsOpen
            Layout.fillWidth: true
            Layout.fillHeight: true
            client: root.client
        }

        ListView {
            id: profileList
            visible: !root.settingsOpen && root.client.available
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Kirigami.Units.smallSpacing
            model: root.client.profiles

            delegate: ProfileDelegate {
                required property string name
                required property bool builtin
                required property bool active
                width: profileList.width
                client: root.client
                onActivated: (profileName, isBuiltin) => root.client.activateProfile(profileName, isBuiltin)
            }
        }
    }

    HistoryMenu {
        id: undoHistory
        historyModel: root.client.history
        onGotoRequested: index => root.client.gotoHistory(index)
    }

    HistoryMenu {
        id: redoHistory
        historyModel: root.client.history
        onGotoRequested: index => root.client.gotoHistory(index)
    }

    QQC2.Dialog {
        id: overwriteConflict
        title: "Profile already exists"
        modal: true
        standardButtons: QQC2.Dialog.Yes | QQC2.Dialog.Cancel
        contentItem: PlasmaComponents.Label {
            text: "Overwrite ‘" + root.pendingSaveName + "’?"
            wrapMode: Text.Wrap
        }
        onAccepted: {
            root.client.saveProfile(root.pendingSaveName, true)
            root.saveEditing = false
        }
    }

    QQC2.Dialog {
        id: builtinConflict
        title: "Built-in name"
        modal: true
        standardButtons: QQC2.Dialog.Ok
        contentItem: PlasmaComponents.Label {
            text: "Built-ins cannot be overwritten. Choose a different name."
            wrapMode: Text.Wrap
        }
        onAccepted: {
            root.pendingSaveName = root.pendingSaveName + " copy"
            root.saveEditing = true
        }
    }
}
