// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

QQC2.Popup {
    id: root
    required property var historyModel
    signal gotoRequested(int index)

    padding: Kirigami.Units.smallSpacing
    width: Kirigami.Units.gridUnit * 18
    height: Math.min(contentItem.implicitHeight + padding * 2, Kirigami.Units.gridUnit * 18)

    contentItem: ListView {
        implicitHeight: contentHeight
        clip: true
        model: root.historyModel
        delegate: PlasmaComponents.Button {
            required property int historyIndex
            required property string label
            required property bool current
            width: ListView.view.width
            flat: true
            text: (current ? "✓ " : "") + label
            onClicked: {
                root.gotoRequested(historyIndex)
                root.close()
            }
        }
    }
}
