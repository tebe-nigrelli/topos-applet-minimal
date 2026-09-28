// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page

    property string cfg_widgetMode: "control"

    QQC2.Switch {
        id: modeSwitch
        Kirigami.FormData.label: i18n("Widget mode:")
        text: checked ? i18n("View") : i18n("Control")
        checked: page.cfg_widgetMode === "view"
        onToggled: page.cfg_widgetMode = checked ? "view" : "control"
    }

    QQC2.Label {
        Kirigami.FormData.label: i18n("View:")
        text: i18n("Shows the topology map; selecting a node switches to that virtual desktop.")
        wrapMode: Text.Wrap
        Layout.fillWidth: true
    }
}
