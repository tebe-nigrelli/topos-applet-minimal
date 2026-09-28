// SPDX-License-Identifier: GPL-2.0-or-later
#pragma once

#include <QAbstractListModel>
#include <QVector>

struct ToposHistoryEntry
{
    int index = -1;
    QString label;
    bool current = false;
};

class HistoryModel final : public QAbstractListModel
{
    Q_OBJECT

public:
    enum Role {
        IndexRole = Qt::UserRole + 1,
        LabelRole,
        CurrentRole,
    };
    Q_ENUM(Role)

    explicit HistoryModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setEntries(QVector<ToposHistoryEntry> entries);
    void clear();

private:
    QVector<ToposHistoryEntry> m_entries;
};
