// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Item {
    id: root
    required property var client
    focus: true

    // Match Plasma Clipboard's popup sizing policy: give Plasma the same
    // 24-grid-unit minimum width instead of forcing a wider preferred width.
    implicitWidth: Kirigami.Units.gridUnit * 24
    implicitHeight: Kirigami.Units.gridUnit * 28

    Layout.minimumWidth: Kirigami.Units.gridUnit * 24
    Layout.minimumHeight: Kirigami.Units.gridUnit * 20
    Layout.maximumWidth: Kirigami.Units.gridUnit * 80
    Layout.maximumHeight: Kirigami.Units.gridUnit * 40
    Layout.preferredHeight: implicitHeight

    property bool settingsOpen: false
    property bool saveEditing: false
    property string pendingSaveName: ""

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Button {
                text: "Save"
                icon.name: "document-save"
                enabled: root.client.available
                Layout.fillWidth: true
                onClicked: {
                    const target = root.client.activeProfile || root.client.lastLoadedProfile
                    root.settingsOpen = false

                    // Normal Save semantics: overwrite the user profile that
                    // produced the current topology. Built-ins are read-only,
                    // so saving one starts a new named configuration instead.
                    if (target.length > 0
                            && !root.client.builtinExists(target)
                            && root.client.profileExists(target)) {
                        root.client.saveProfile(target, true)
                        root.saveEditing = false
                    } else {
                        root.pendingSaveName = target.length > 0 && !root.client.builtinExists(target)
                            ? target
                            : "New topology"
                        root.saveEditing = true
                    }
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

        PlasmaComponents.Label {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            visible: !root.client.available
            text: root.client.unavailableReason
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }

        PlasmaComponents.Label {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            visible: root.client.available && root.client.lastError.length > 0
            text: root.client.lastError
            color: Kirigami.Theme.negativeTextColor
            wrapMode: Text.Wrap
        }

        InlineNameEditor {
            id: saveEditor
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
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


        PlasmaComponents.TextField {
            id: search
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            visible: !root.settingsOpen
            placeholderText: "Search configurations…"
            enabled: root.client.available
            onTextChanged: root.client.profiles.filter = text
        }


        SettingsPage {
            visible: root.settingsOpen
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop
            client: root.client
        }

        // Clipboard-style result area. Built-ins are ordered first by the
        // model and are all visible when the search field is empty. The area
        // scrolls instead of pushing controls off the top of the widget.
        QQC2.ScrollView {
            id: profileScroll
            visible: !root.settingsOpen && root.client.available
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop
            clip: true

            QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff
            QQC2.ScrollBar.vertical.policy: QQC2.ScrollBar.AsNeeded

            ListView {
                id: profileList
                width: profileScroll.availableWidth
                spacing: Kirigami.Units.smallSpacing
                model: root.client.profiles
                boundsBehavior: Flickable.StopAtBounds

                delegate: ProfileDelegate {
                    width: profileList.width
                    client: root.client
                    onActivated: (profileName, isBuiltin) => root.client.activateProfile(profileName, isBuiltin)
                }
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
