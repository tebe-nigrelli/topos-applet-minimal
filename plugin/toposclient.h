// SPDX-License-Identifier: GPL-2.0-or-later
#pragma once

#include "historymodel.h"
#include "profilemodel.h"

#include <QObject>
#include <QStringList>
#include <QVariantMap>

class QDBusServiceWatcher;

class ToposClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available NOTIFY availableChanged)
    Q_PROPERTY(QString unavailableReason READ unavailableReason NOTIFY unavailableReasonChanged)
    Q_PROPERTY(int apiVersion READ apiVersion NOTIFY stateChanged)
    Q_PROPERTY(QString activeProfile READ activeProfile NOTIFY stateChanged)
    Q_PROPERTY(QString lastLoadedProfile READ lastLoadedProfile NOTIFY stateChanged)
    Q_PROPERTY(bool dirty READ dirty NOTIFY stateChanged)
    Q_PROPERTY(bool canUndo READ canUndo NOTIFY stateChanged)
    Q_PROPERTY(bool canRedo READ canRedo NOTIFY stateChanged)
    Q_PROPERTY(int historyLimit READ historyLimit NOTIFY stateChanged)
    Q_PROPERTY(bool persistHistory READ persistHistory NOTIFY stateChanged)
    Q_PROPERTY(int gestureDistance READ gestureDistance NOTIFY stateChanged)
    Q_PROPERTY(double settleThreshold READ settleThreshold NOTIFY stateChanged)
    Q_PROPERTY(bool showHandles READ showHandles NOTIFY stateChanged)
    Q_PROPERTY(bool showBridgePreview READ showBridgePreview NOTIFY stateChanged)
    Q_PROPERTY(QString topologyGraphLayout READ topologyGraphLayout NOTIFY stateChanged)
    Q_PROPERTY(double topologyGraphSpread READ topologyGraphSpread NOTIFY stateChanged)
    Q_PROPERTY(ProfileModel *profiles READ profiles CONSTANT)
    Q_PROPERTY(HistoryModel *history READ history CONSTANT)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)

public:
    static constexpr int RequiredApiVersion = 1;

    explicit ToposClient(QObject *parent = nullptr);

    bool available() const;
    QString unavailableReason() const;
    int apiVersion() const;
    QString activeProfile() const;
    QString lastLoadedProfile() const;
    bool dirty() const;
    bool canUndo() const;
    bool canRedo() const;
    int historyLimit() const;
    bool persistHistory() const;
    int gestureDistance() const;
    double settleThreshold() const;
    bool showHandles() const;
    bool showBridgePreview() const;
    QString topologyGraphLayout() const;
    double topologyGraphSpread() const;
    ProfileModel *profiles();
    HistoryModel *history();
    QString lastError() const;

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void activateProfile(const QString &name, bool builtin);
    Q_INVOKABLE void reset();
    Q_INVOKABLE void saveProfile(const QString &name, bool overwrite = false);
    Q_INVOKABLE void renameProfile(const QString &oldName, const QString &newName, bool overwrite = false);
    Q_INVOKABLE void deleteProfile(const QString &name);
    Q_INVOKABLE void undo(int count = 1);
    Q_INVOKABLE void redo(int count = 1);
    Q_INVOKABLE void clearHistory();
    Q_INVOKABLE void setHistoryLimit(int limit);
    Q_INVOKABLE void setPersistHistory(bool enabled);
    Q_INVOKABLE void setGestureDistance(int distance);
    Q_INVOKABLE void setSettleThreshold(double threshold);
    Q_INVOKABLE void setShowHandles(bool show);
    Q_INVOKABLE void setShowBridgePreview(bool show);
    Q_INVOKABLE void setTopologyGraphLayout(const QString &layout);
    Q_INVOKABLE void setTopologyGraphSpread(double spread);
    Q_INVOKABLE void gotoHistory(int index);
    Q_INVOKABLE bool profileExists(const QString &name) const;
    Q_INVOKABLE bool builtinExists(const QString &name) const;

Q_SIGNALS:
    void availableChanged();
    void unavailableReasonChanged();
    void stateChanged();
    void lastErrorChanged();
    void operationFailed(const QString &message);

private Q_SLOTS:
    void handleRemoteChange();

private:
    bool invoke(const QString &method, const QVariantList &arguments = {});
    bool setRemoteProperty(const QString &name, const QVariant &value);
    void setAvailable(bool available);
    void setUnavailableReason(const QString &reason);
    void setLastError(const QString &error);
    void clearRemoteState();
    void refreshProfiles();
    void refreshProperties(const QVariantMap &properties);
    void refreshHistory();
    QStringList stringListReply(const QString &method, bool *ok = nullptr) const;

    bool m_available = false;
    QString m_unavailableReason = QStringLiteral("Topos is not running.");
    int m_apiVersion = 0;
    QString m_activeProfile;
    QString m_lastLoadedProfile;
    bool m_dirty = false;
    bool m_canUndo = false;
    bool m_canRedo = false;
    int m_historyLimit = 50;
    bool m_persistHistory = true;
    int m_gestureDistance = 200;
    double m_settleThreshold = 0.25;
    bool m_showHandles = true;
    bool m_showBridgePreview = true;
    QString m_topologyGraphLayout = QStringLiteral("grid");
    double m_topologyGraphSpread = 1.35;
    QString m_lastError;
    QStringList m_allProfileNames;

    ProfileModel m_profiles;
    HistoryModel m_history;
    QDBusServiceWatcher *m_serviceWatcher = nullptr;
};
