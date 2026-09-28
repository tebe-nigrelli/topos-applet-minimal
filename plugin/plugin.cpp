// SPDX-License-Identifier: GPL-2.0-or-later

#include "toposclient.h"

#include <QQmlExtensionPlugin>
#include <qqml.h>

class ToposPlugin final : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlExtensionInterface_iid)

public:
    void registerTypes(const char *uri) override
    {
        Q_ASSERT(QString::fromLatin1(uri) == QStringLiteral("org.kde.plasma.private.topos"));
        qmlRegisterType<ToposClient>(uri, 1, 0, "ToposClient");
    }
};

#include "plugin.moc"
