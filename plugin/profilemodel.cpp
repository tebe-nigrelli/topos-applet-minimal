// SPDX-License-Identifier: GPL-2.0-or-later
#include "profilemodel.h"

#include <algorithm>
#include <utility>

ProfileModel::ProfileModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int ProfileModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_visible.size();
}

QVariant ProfileModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_visible.size()) {
        return {};
    }

    const auto &entry = m_visible.at(index.row());
    switch (role) {
    case NameRole:
        return entry.name;
    case BuiltinRole:
        return entry.builtin;
    case ActiveRole:
        return entry.active;
    default:
        return {};
    }
}

QHash<int, QByteArray> ProfileModel::roleNames() const
{
    return {
        {NameRole, "name"},
        {BuiltinRole, "builtin"},
        {ActiveRole, "active"},
    };
}

QString ProfileModel::filter() const
{
    return m_filter;
}

void ProfileModel::setFilter(const QString &filter)
{
    if (m_filter == filter) {
        return;
    }
    m_filter = filter;
    rebuildVisible();
    Q_EMIT filterChanged();
}

void ProfileModel::setProfiles(const QStringList &builtins, const QStringList &profiles, const QString &activeProfile)
{
    m_all.clear();
    m_all.reserve(builtins.size() + profiles.size());

    for (const QString &name : builtins) {
        m_all.push_back({name, true, name == activeProfile});
    }

    QStringList sortedProfiles = profiles;
    sortedProfiles.sort(Qt::CaseInsensitive);
    for (const QString &name : sortedProfiles) {
        m_all.push_back({name, false, name == activeProfile});
    }

    rebuildVisible();
}

bool ProfileModel::containsUserProfile(const QString &name) const
{
    return std::any_of(m_all.cbegin(), m_all.cend(), [&](const ToposProfileEntry &entry) {
        return !entry.builtin && entry.name.compare(name, Qt::CaseSensitive) == 0;
    });
}

bool ProfileModel::containsBuiltin(const QString &name) const
{
    return std::any_of(m_all.cbegin(), m_all.cend(), [&](const ToposProfileEntry &entry) {
        return entry.builtin && entry.name.compare(name, Qt::CaseSensitive) == 0;
    });
}

void ProfileModel::rebuildVisible()
{
    beginResetModel();
    m_visible.clear();

    const QString needle = m_filter.trimmed();
    for (const auto &entry : std::as_const(m_all)) {
        if (needle.isEmpty() || entry.name.contains(needle, Qt::CaseInsensitive)) {
            m_visible.push_back(entry);
        }
    }
    endResetModel();
}
