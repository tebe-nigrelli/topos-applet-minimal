// SPDX-License-Identifier: GPL-2.0-or-later
#pragma once

#include <QAbstractListModel>
#include <QStringList>
#include <QVector>

struct ToposProfileEntry
{
    QString name;
    bool builtin = false;
    bool active = false;
};

class ProfileModel final : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)

public:
    enum Role {
        NameRole = Qt::UserRole + 1,
        BuiltinRole,
        ActiveRole,
    };
    Q_ENUM(Role)

    explicit ProfileModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString filter() const;
    void setFilter(const QString &filter);

    void setProfiles(const QStringList &builtins, const QStringList &profiles, const QString &activeProfile);
    bool containsUserProfile(const QString &name) const;
    bool containsBuiltin(const QString &name) const;

Q_SIGNALS:
    void filterChanged();

private:
    void rebuildVisible();

    QString m_filter;
    QVector<ToposProfileEntry> m_all;
    QVector<ToposProfileEntry> m_visible;
};
