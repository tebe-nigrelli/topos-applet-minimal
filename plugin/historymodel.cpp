// SPDX-License-Identifier: GPL-2.0-or-later
#include "historymodel.h"
#include <utility>

HistoryModel::HistoryModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int HistoryModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_entries.size();
}

QVariant HistoryModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_entries.size()) {
        return {};
    }

    const auto &entry = m_entries.at(index.row());
    switch (role) {
    case IndexRole:
        return entry.index;
    case LabelRole:
        return entry.label;
    case CurrentRole:
        return entry.current;
    default:
        return {};
    }
}

QHash<int, QByteArray> HistoryModel::roleNames() const
{
    return {
        {IndexRole, "historyIndex"},
        {LabelRole, "label"},
        {CurrentRole, "current"},
    };
}

void HistoryModel::setEntries(QVector<ToposHistoryEntry> entries)
{
    beginResetModel();
    m_entries = std::move(entries);
    endResetModel();
}

void HistoryModel::clear()
{
    setEntries({});
}
