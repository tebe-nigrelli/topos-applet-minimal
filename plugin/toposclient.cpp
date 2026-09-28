// SPDX-License-Identifier: GPL-2.0-or-later
#include "toposclient.h"

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusMetaType>
#include <QDBusServiceWatcher>
#include <QDBusVariant>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTimer>
#include <utility>

namespace
{
constexpr auto kService = "org.kde.KWin";
constexpr auto kPath = "/Topos";
constexpr auto kInterface = "org.kde.KWin.Topos";
constexpr auto kPropertiesInterface = "org.freedesktop.DBus.Properties";

QDBusMessage callMessage(const QString &interfaceName, const QString &method, const QVariantList &arguments = {})
{
    QDBusMessage message = QDBusMessage::createMethodCall(
        QString::fromLatin1(kService),
        QString::fromLatin1(kPath),
        interfaceName,
        method);
    message.setArguments(arguments);
    return QDBusConnection::sessionBus().call(message, QDBus::Block, 1200);
}

QVariant unwrapDbusVariant(const QVariant &value)
{
    if (value.metaType() == QMetaType::fromType<QDBusVariant>()) {
        return value.value<QDBusVariant>().variant();
    }
    return value;
}
}

ToposClient::ToposClient(QObject *parent)
    : QObject(parent)
    , m_profiles(this)
    , m_history(this)
{
    auto bus = QDBusConnection::sessionBus();
    m_serviceWatcher = new QDBusServiceWatcher(
        QString::fromLatin1(kService),
        bus,
        QDBusServiceWatcher::WatchForOwnerChange,
        this);

    connect(m_serviceWatcher, &QDBusServiceWatcher::serviceOwnerChanged, this, [this] {
        refresh();
    });

    bus.connect(QString::fromLatin1(kService), QString::fromLatin1(kPath), QString::fromLatin1(kInterface), QStringLiteral("StateChanged"), this, SLOT(handleRemoteChange()));
    bus.connect(QString::fromLatin1(kService), QString::fromLatin1(kPath), QString::fromLatin1(kInterface), QStringLiteral("ProfilesChanged"), this, SLOT(handleRemoteChange()));
    bus.connect(QString::fromLatin1(kService), QString::fromLatin1(kPath), QString::fromLatin1(kInterface), QStringLiteral("HistoryChanged"), this, SLOT(handleRemoteChange()));
    bus.connect(QString::fromLatin1(kService), QString::fromLatin1(kPath), QString::fromLatin1(kInterface), QStringLiteral("DesktopSignatureChanged"), this, SLOT(handleRemoteChange()));

    QTimer::singleShot(0, this, &ToposClient::refresh);
}

bool ToposClient::available() const { return m_available; }
QString ToposClient::unavailableReason() const { return m_unavailableReason; }
int ToposClient::apiVersion() const { return m_apiVersion; }
QString ToposClient::activeProfile() const { return m_activeProfile; }
QString ToposClient::lastLoadedProfile() const { return m_lastLoadedProfile; }
bool ToposClient::dirty() const { return m_dirty; }
bool ToposClient::canUndo() const { return m_canUndo; }
bool ToposClient::canRedo() const { return m_canRedo; }
int ToposClient::historyLimit() const { return m_historyLimit; }
bool ToposClient::persistHistory() const { return m_persistHistory; }
int ToposClient::gestureDistance() const { return m_gestureDistance; }
double ToposClient::settleThreshold() const { return m_settleThreshold; }
bool ToposClient::showHandles() const { return m_showHandles; }
bool ToposClient::showBridgePreview() const { return m_showBridgePreview; }
QString ToposClient::topologyGraphLayout() const { return m_topologyGraphLayout; }
double ToposClient::topologyGraphSpread() const { return m_topologyGraphSpread; }
ProfileModel *ToposClient::profiles() { return &m_profiles; }
HistoryModel *ToposClient::history() { return &m_history; }
QString ToposClient::lastError() const { return m_lastError; }

void ToposClient::refresh()
{
    const QDBusMessage reply = callMessage(QString::fromLatin1(kPropertiesInterface), QStringLiteral("GetAll"), {QString::fromLatin1(kInterface)});
    if (reply.type() != QDBusMessage::ReplyMessage || reply.arguments().isEmpty()) {
        setAvailable(false);
        setUnavailableReason(QStringLiteral("Topos is not running."));
        clearRemoteState();
        return;
    }

    const QVariantMap properties = qdbus_cast<QVariantMap>(reply.arguments().constFirst());
    const int apiVersion = unwrapDbusVariant(properties.value(QStringLiteral("apiVersion"))).toInt();
    const bool ready = unwrapDbusVariant(properties.value(QStringLiteral("ready"))).toBool();

    if (m_apiVersion != apiVersion) {
        m_apiVersion = apiVersion;
        Q_EMIT stateChanged();
    }

    if (apiVersion != RequiredApiVersion) {
        setAvailable(false);
        setUnavailableReason(QStringLiteral("Incompatible Topos API version %1 (this applet requires %2).")
                                 .arg(apiVersion)
                                 .arg(RequiredApiVersion));
        clearRemoteState();
        return;
    }

    if (!ready) {
        setAvailable(false);
        setUnavailableReason(QStringLiteral("Topos is starting."));
        clearRemoteState();
        return;
    }

    setAvailable(true);
    setUnavailableReason({});
    setLastError({});
    refreshProperties(properties);
    refreshProfiles();
    refreshHistory();
}

void ToposClient::activateProfile(const QString &name, bool builtin)
{
    const QString trimmed = name.trimmed();
    if (trimmed.isEmpty()) {
        return;
    }

    if (builtin && trimmed == QStringLiteral("Base Grid")) {
        reset();
        return;
    }

    invoke(builtin ? QStringLiteral("ApplyBuiltin") : QStringLiteral("LoadProfile"), {trimmed});
}

void ToposClient::reset() { invoke(QStringLiteral("Reset")); }

void ToposClient::saveProfile(const QString &name, bool overwrite)
{
    const QString trimmed = name.trimmed();
    if (trimmed.isEmpty()) {
        setLastError(QStringLiteral("Profile name cannot be empty."));
        Q_EMIT operationFailed(m_lastError);
        return;
    }
    invoke(QStringLiteral("SaveProfile"), {trimmed, overwrite});
}

void ToposClient::renameProfile(const QString &oldName, const QString &newName, bool overwrite)
{
    const QString trimmed = newName.trimmed();
    if (trimmed.isEmpty() || oldName == trimmed) {
        return;
    }
    invoke(QStringLiteral("RenameProfile"), {oldName, trimmed, overwrite});
}

void ToposClient::deleteProfile(const QString &name)
{
    const QString trimmed = name.trimmed();
    if (!trimmed.isEmpty()) {
        invoke(QStringLiteral("DeleteProfile"), {trimmed});
    }
}

void ToposClient::undo(int count) { invoke(QStringLiteral("Undo"), {qMax(1, count)}); }
void ToposClient::redo(int count) { invoke(QStringLiteral("Redo"), {qMax(1, count)}); }
void ToposClient::clearHistory() { invoke(QStringLiteral("ClearHistory")); }
void ToposClient::setHistoryLimit(int limit) { setRemoteProperty(QStringLiteral("historyLimit"), qBound(1, limit, 1000)); }
void ToposClient::setPersistHistory(bool enabled) { setRemoteProperty(QStringLiteral("persistHistory"), enabled); }
void ToposClient::setGestureDistance(int distance) { setRemoteProperty(QStringLiteral("gestureDistance"), qBound(50, distance, 2000)); }
void ToposClient::setSettleThreshold(double threshold) { setRemoteProperty(QStringLiteral("settleThreshold"), qBound(0.05, threshold, 0.95)); }
void ToposClient::setShowHandles(bool show) { setRemoteProperty(QStringLiteral("showHandles"), show); }
void ToposClient::setShowBridgePreview(bool show) { setRemoteProperty(QStringLiteral("showBridgePreview"), show); }
void ToposClient::setTopologyGraphLayout(const QString &layout)
{
    setRemoteProperty(QStringLiteral("topologyGraphLayout"), layout.compare(QStringLiteral("loose"), Qt::CaseInsensitive) == 0 ? QStringLiteral("loose") : QStringLiteral("grid"));
}
void ToposClient::setTopologyGraphSpread(double spread) { setRemoteProperty(QStringLiteral("topologyGraphSpread"), qBound(0.75, spread, 2.5)); }
void ToposClient::gotoHistory(int index) { invoke(QStringLiteral("GotoHistory"), {index}); }

bool ToposClient::profileExists(const QString &name) const
{
    return m_allProfileNames.contains(name.trimmed(), Qt::CaseSensitive);
}

bool ToposClient::builtinExists(const QString &name) const
{
    return m_profiles.containsBuiltin(name.trimmed());
}

void ToposClient::handleRemoteChange()
{
    refresh();
}

bool ToposClient::invoke(const QString &method, const QVariantList &arguments)
{
    if (!m_available) {
        setLastError(m_unavailableReason.isEmpty() ? QStringLiteral("Topos is not running.") : m_unavailableReason);
        Q_EMIT operationFailed(m_lastError);
        return false;
    }

    const QDBusMessage reply = callMessage(QString::fromLatin1(kInterface), method, arguments);
    if (reply.type() == QDBusMessage::ErrorMessage) {
        const QString message = reply.errorMessage().isEmpty() ? reply.errorName() : reply.errorMessage();
        setLastError(message);
        Q_EMIT operationFailed(message);
        return false;
    }
    if (!reply.arguments().isEmpty() && reply.arguments().constFirst().metaType() == QMetaType::fromType<bool>() && !reply.arguments().constFirst().toBool()) {
        const QString message = QStringLiteral("Topos operation failed: %1").arg(method);
        setLastError(message);
        Q_EMIT operationFailed(message);
        return false;
    }

    setLastError({});
    refresh();
    return true;
}

bool ToposClient::setRemoteProperty(const QString &name, const QVariant &value)
{
    if (!m_available) {
        setLastError(m_unavailableReason.isEmpty() ? QStringLiteral("Topos is not running.") : m_unavailableReason);
        Q_EMIT operationFailed(m_lastError);
        return false;
    }

    const QVariant wrapped = QVariant::fromValue(QDBusVariant(value));
    const QDBusMessage reply = callMessage(QString::fromLatin1(kPropertiesInterface), QStringLiteral("Set"),
                                           {QString::fromLatin1(kInterface), name, wrapped});
    if (reply.type() == QDBusMessage::ErrorMessage) {
        const QString message = reply.errorMessage().isEmpty() ? reply.errorName() : reply.errorMessage();
        setLastError(message);
        Q_EMIT operationFailed(message);
        return false;
    }

    setLastError({});
    refresh();
    return true;
}

void ToposClient::setAvailable(bool available)
{
    if (m_available == available) {
        return;
    }
    m_available = available;
    Q_EMIT availableChanged();
}

void ToposClient::setUnavailableReason(const QString &reason)
{
    if (m_unavailableReason == reason) {
        return;
    }
    m_unavailableReason = reason;
    Q_EMIT unavailableReasonChanged();
}

void ToposClient::setLastError(const QString &error)
{
    if (m_lastError == error) {
        return;
    }
    m_lastError = error;
    Q_EMIT lastErrorChanged();
}

void ToposClient::clearRemoteState()
{
    m_profiles.setProfiles({}, {}, {});
    m_history.clear();
    m_allProfileNames.clear();

    const bool changed = !m_activeProfile.isEmpty() || !m_lastLoadedProfile.isEmpty() || m_dirty || m_canUndo || m_canRedo;
    m_activeProfile.clear();
    m_lastLoadedProfile.clear();
    m_dirty = false;
    m_canUndo = false;
    m_canRedo = false;
    if (changed) {
        Q_EMIT stateChanged();
    }
}

void ToposClient::refreshProfiles()
{
    bool builtinsOk = false;
    bool profilesOk = false;
    bool allProfilesOk = false;
    QStringList builtins = stringListReply(QStringLiteral("ListBuiltins"), &builtinsOk);
    const QStringList profiles = stringListReply(QStringLiteral("ListProfiles"), &profilesOk);
    const QStringList allProfiles = stringListReply(QStringLiteral("ListProfilesAll"), &allProfilesOk);

    // These are part of the Topos v1 built-in surface and should always be
    // visible in the applet.  Keep any additional built-ins returned by KWin.
    const QStringList standardBuiltins = {
        QStringLiteral("Base Grid"),
        QStringLiteral("Torus"),
        QStringLiteral("Sphere"),
        QStringLiteral("Cylinder"),
    };
    for (const QString &name : standardBuiltins) {
        if (!builtins.contains(name, Qt::CaseSensitive)) {
            builtins.push_back(name);
        }
    }

    // ListProfilesAll() is only needed for collision detection.  Do not throw
    // away a valid ListBuiltins()/ListProfiles() result if that optional call
    // is unavailable on an older Topos v1 build.
    m_allProfileNames = allProfilesOk ? allProfiles : (profilesOk ? profiles : QStringList{});

    const QString displayedActive = !m_activeProfile.isEmpty()
        ? m_activeProfile
        : (m_dirty ? m_lastLoadedProfile : QString());
    m_profiles.setProfiles(builtins, profilesOk ? profiles : QStringList{}, displayedActive);
}

void ToposClient::refreshProperties(const QVariantMap &properties)
{
    const QString oldActive = m_activeProfile;
    const QString oldLastLoaded = m_lastLoadedProfile;
    const bool oldDirty = m_dirty;
    const bool oldCanUndo = m_canUndo;
    const bool oldCanRedo = m_canRedo;
    const int oldHistoryLimit = m_historyLimit;
    const bool oldPersistHistory = m_persistHistory;
    const int oldGestureDistance = m_gestureDistance;
    const double oldSettleThreshold = m_settleThreshold;
    const bool oldShowHandles = m_showHandles;
    const bool oldShowBridgePreview = m_showBridgePreview;
    const QString oldTopologyGraphLayout = m_topologyGraphLayout;
    const double oldTopologyGraphSpread = m_topologyGraphSpread;

    auto property = [&](const char *name) {
        return unwrapDbusVariant(properties.value(QString::fromLatin1(name)));
    };

    const QVariant active = property("activeProfile");
    if (active.isValid()) m_activeProfile = active.toString();
    const QVariant lastLoaded = property("lastLoadedProfile");
    if (lastLoaded.isValid()) m_lastLoadedProfile = lastLoaded.toString();
    const QVariant dirty = property("dirty");
    if (dirty.isValid()) m_dirty = dirty.toBool();
    const QVariant canUndo = property("canUndo");
    if (canUndo.isValid()) m_canUndo = canUndo.toBool();
    const QVariant canRedo = property("canRedo");
    if (canRedo.isValid()) m_canRedo = canRedo.toBool();
    const QVariant historyLimit = property("historyLimit");
    if (historyLimit.isValid()) m_historyLimit = historyLimit.toInt();
    const QVariant persistHistory = property("persistHistory");
    if (persistHistory.isValid()) m_persistHistory = persistHistory.toBool();
    const QVariant gestureDistance = property("gestureDistance");
    if (gestureDistance.isValid()) m_gestureDistance = gestureDistance.toInt();
    const QVariant settleThreshold = property("settleThreshold");
    if (settleThreshold.isValid()) m_settleThreshold = settleThreshold.toDouble();
    const QVariant showHandles = property("showHandles");
    if (showHandles.isValid()) m_showHandles = showHandles.toBool();
    const QVariant showBridgePreview = property("showBridgePreview");
    if (showBridgePreview.isValid()) m_showBridgePreview = showBridgePreview.toBool();
    const QVariant topologyGraphLayout = property("topologyGraphLayout");
    if (topologyGraphLayout.isValid()) m_topologyGraphLayout = topologyGraphLayout.toString();
    const QVariant topologyGraphSpread = property("topologyGraphSpread");
    if (topologyGraphSpread.isValid()) m_topologyGraphSpread = topologyGraphSpread.toDouble();

    if (oldActive != m_activeProfile || oldLastLoaded != m_lastLoadedProfile || oldDirty != m_dirty || oldCanUndo != m_canUndo || oldCanRedo != m_canRedo
        || oldHistoryLimit != m_historyLimit || oldPersistHistory != m_persistHistory || oldGestureDistance != m_gestureDistance
        || !qFuzzyCompare(oldSettleThreshold, m_settleThreshold) || oldShowHandles != m_showHandles || oldShowBridgePreview != m_showBridgePreview
        || oldTopologyGraphLayout != m_topologyGraphLayout || !qFuzzyCompare(oldTopologyGraphSpread, m_topologyGraphSpread)) {
        Q_EMIT stateChanged();
    }
}

void ToposClient::refreshHistory()
{
    const QDBusMessage reply = callMessage(QString::fromLatin1(kInterface), QStringLiteral("GetHistory"));
    if (reply.type() != QDBusMessage::ReplyMessage || reply.arguments().isEmpty()) {
        m_history.clear();
        return;
    }

    const QByteArray json = reply.arguments().constFirst().toString().toUtf8();
    QJsonParseError error;
    const QJsonDocument document = QJsonDocument::fromJson(json, &error);
    if (error.error != QJsonParseError::NoError) {
        m_history.clear();
        return;
    }

    QJsonArray entries;
    int currentIndex = -1;
    if (document.isArray()) {
        entries = document.array();
    } else if (document.isObject()) {
        const QJsonObject object = document.object();
        entries = object.value(QStringLiteral("entries")).toArray();
        currentIndex = object.value(QStringLiteral("current")).toInt(-1);
        if (currentIndex < 0) {
            currentIndex = object.value(QStringLiteral("cursor")).toInt(-1);
        }
    }

    QVector<ToposHistoryEntry> parsed;
    parsed.reserve(entries.size());
    for (qsizetype i = 0; i < entries.size(); ++i) {
        const QJsonValue value = entries.at(i);
        ToposHistoryEntry entry;
        entry.index = static_cast<int>(i);

        if (value.isString()) {
            entry.label = value.toString();
        } else if (value.isObject()) {
            const QJsonObject object = value.toObject();
            entry.index = object.value(QStringLiteral("index")).toInt(static_cast<int>(i));
            entry.label = object.value(QStringLiteral("label")).toString();
            entry.current = object.value(QStringLiteral("current")).toBool(false);
        }

        if (entry.label.isEmpty()) {
            entry.label = QStringLiteral("History %1").arg(entry.index);
        }
        if (entry.index == currentIndex) {
            entry.current = true;
        }
        parsed.push_back(entry);
    }

    m_history.setEntries(std::move(parsed));
}

QStringList ToposClient::stringListReply(const QString &method, bool *ok) const
{
    const QDBusMessage reply = callMessage(QString::fromLatin1(kInterface), method);
    const bool success = reply.type() == QDBusMessage::ReplyMessage && !reply.arguments().isEmpty();
    if (ok) {
        *ok = success;
    }
    if (!success) {
        return {};
    }
    return qdbus_cast<QStringList>(reply.arguments().constFirst());
}
