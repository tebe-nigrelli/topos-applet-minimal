// SPDX-License-Identifier: GPL-2.0-or-later
import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

Item {
    id: root

    required property var client
    property bool compact: false
    property bool interactive: false

    property var graphNodes: []
    property var graphEdges: []
    property var positions: []
    property int layoutEpoch: 0

    readonly property real nodeRadius: compact ? Math.max(2.2, Math.min(width, height) * 0.075) : 17
    readonly property real activeNodeRadius: compact ? nodeRadius * 1.35 : 21
    readonly property real edgeWidth: compact ? 1.0 : 2.0

    function desktopIndexById(id) {
        for (let i = 0; i < graphNodes.length; ++i) {
            if (graphNodes[i].id === id) return i;
        }
        return -1;
    }

    function rebuildGraph() {
        let document = {};
        try {
            document = JSON.parse(client.graphJson || "{}");
        } catch (error) {
            document = {};
        }

        const effective = document.effective || [];
        const nodes = [];
        const nodeIds = {};
        for (let i = 0; i < effective.length; ++i) {
            const arc = effective[i];
            if (arc.source === undefined || nodeIds[arc.source] !== undefined) continue;
            nodeIds[arc.source] = nodes.length;
            nodes.push({ id: arc.source, name: arc.sourceName || "" });
        }

        const edgesByPair = {};
        const edges = [];
        for (let i = 0; i < effective.length; ++i) {
            const arc = effective[i];
            if (arc.exists !== true || arc.target === undefined) continue;
            const source = nodeIds[arc.source];
            const target = nodeIds[arc.target];
            if (source === undefined || target === undefined || source === target) continue;

            const a = Math.min(source, target);
            const b = Math.max(source, target);
            const key = a + ":" + b;
            let edge = edgesByPair[key];
            if (edge === undefined) {
                edge = { a: a, b: b, aToB: false, bToA: false };
                edgesByPair[key] = edge;
                edges.push(edge);
            }
            if (source === a) edge.aToB = true;
            else edge.bToA = true;
        }

        graphNodes = nodes;
        graphEdges = edges;
        rebuildLayout();
    }

    function graphGridPositions(w, h, n) {
        const margin = compact ? Math.max(2.5, Math.min(w, h) * 0.12) : 34;
        const rows = Math.max(1, Math.min(n, client.desktopRows || 1));
        const columns = Math.max(1, Math.ceil(n / rows));
        const rowSpan = Math.max(1, rows - 1);
        const columnSpan = Math.max(1, columns - 1);
        const usableW = Math.max(1, w - 2 * margin);
        const usableH = Math.max(1, h - 2 * margin);
        const result = [];
        for (let i = 0; i < n; ++i) {
            const row = Math.floor(i / columns);
            const column = i % columns;
            result.push({
                x: columns === 1 ? w / 2 : margin + column / columnSpan * usableW,
                y: rows === 1 ? h / 2 : margin + row / rowSpan * usableH
            });
        }
        return result;
    }

    function graphLoosePositions(w, h, n, edges) {
        const margin = compact ? Math.max(2.5, Math.min(w, h) * 0.12) : 30;
        const cx = w / 2;
        const cy = h / 2;
        const spread = client.topologyGraphSpread || 1.35;
        let p = graphGridPositions(w, h, n);
        if (n > 1) {
            for (let i = 0; i < n; ++i) {
                const angle = i * 2.399963229728653;
                const jitter = compact ? 0.7 : 5;
                p[i].x += Math.cos(angle) * jitter;
                p[i].y += Math.sin(angle) * jitter;
            }
        }

        const scale = compact ? Math.min(w, h) / 220 : 1;
        const restLength = Math.max(compact ? 5 : 54,
                                    Math.min(compact ? Math.min(w, h) * 0.55 : 150,
                                             Math.min(w, h) * 0.30 * spread));
        const repulsion = 5600 * spread * spread * Math.max(0.006, scale * scale);
        for (let iteration = 0; iteration < 130 && n > 1; ++iteration) {
            let fx = new Array(n).fill(0);
            let fy = new Array(n).fill(0);
            for (let i = 0; i < n; ++i) {
                for (let j = i + 1; j < n; ++j) {
                    let dx = p[i].x - p[j].x;
                    let dy = p[i].y - p[j].y;
                    let d2 = dx * dx + dy * dy;
                    if (d2 < 1) d2 = 1;
                    const d = Math.sqrt(d2);
                    const repel = repulsion / d2;
                    fx[i] += dx / d * repel;
                    fy[i] += dy / d * repel;
                    fx[j] -= dx / d * repel;
                    fy[j] -= dy / d * repel;
                }
            }
            for (let e = 0; e < edges.length; ++e) {
                const edge = edges[e];
                const dx = p[edge.b].x - p[edge.a].x;
                const dy = p[edge.b].y - p[edge.a].y;
                const d = Math.max(1, Math.sqrt(dx * dx + dy * dy));
                const spring = (d - restLength) * 0.018;
                fx[edge.a] += dx / d * spring;
                fy[edge.a] += dy / d * spring;
                fx[edge.b] -= dx / d * spring;
                fy[edge.b] -= dy / d * spring;
            }
            for (let i = 0; i < n; ++i) {
                fx[i] += (cx - p[i].x) * 0.0035;
                fy[i] += (cy - p[i].y) * 0.0035;
                p[i].x = Math.max(margin, Math.min(w - margin, p[i].x + fx[i] * 0.78));
                p[i].y = Math.max(margin, Math.min(h - margin, p[i].y + fy[i] * 0.78));
            }
        }
        return p;
    }

    function rebuildLayout() {
        const n = graphNodes.length;
        positions = client.topologyGraphLayout === "loose"
            ? graphLoosePositions(width, height, n, graphEdges)
            : graphGridPositions(width, height, n);
        layoutEpoch++;
        edgeCanvas.requestPaint();
    }

    function nodePosition(index) {
        layoutEpoch;
        if (index < 0 || index >= positions.length) return Qt.point(width / 2, height / 2);
        return Qt.point(positions[index].x, positions[index].y);
    }

    function segmentDistanceSquared(point, a, b) {
        const dx = b.x - a.x;
        const dy = b.y - a.y;
        const length2 = dx * dx + dy * dy;
        if (length2 < 0.001) {
            const px = point.x - a.x;
            const py = point.y - a.y;
            return px * px + py * py;
        }
        const t = Math.max(0, Math.min(1, ((point.x - a.x) * dx + (point.y - a.y) * dy) / length2));
        const qx = a.x + t * dx;
        const qy = a.y + t * dy;
        const px = point.x - qx;
        const py = point.y - qy;
        return px * px + py * py;
    }

    function routePenalty(points, edge) {
        let penalty = 0;
        let length = 0;
        for (let segment = 0; segment + 1 < points.length; ++segment) {
            const a = points[segment];
            const b = points[segment + 1];
            const dx = b.x - a.x;
            const dy = b.y - a.y;
            length += Math.sqrt(dx * dx + dy * dy);
            for (let i = 0; i < positions.length; ++i) {
                if (i === edge.a || i === edge.b) continue;
                const node = nodePosition(i);
                const d2 = segmentDistanceSquared(node, a, b);
                if (d2 < 24 * 24) penalty += 100000 + (24 * 24 - d2) * 100;
                else if (d2 < 38 * 38) penalty += (38 * 38 - d2) * 4;
            }
        }
        return penalty + length;
    }

    function graphRoute(edge) {
        const a = nodePosition(edge.a);
        const b = nodePosition(edge.b);
        if (compact || client.topologyGraphLayout === "loose") return [a, b];

        const dx = b.x - a.x;
        const dy = b.y - a.y;
        const sx = dx >= 0 ? 1 : -1;
        const sy = dy >= 0 ? 1 : -1;
        const xStep = Math.max(18, Math.min(Math.abs(dx) * 0.34, 34));
        const yStep = Math.max(18, Math.min(Math.abs(dy) * 0.34, 34));
        const candidates = [[a, b]];

        if (Math.abs(dy) < 2) {
            const lane = 26 + ((edge.a + edge.b) % 3) * 7;
            if (a.y - lane > 18) candidates.push([a, Qt.point(a.x, a.y - lane), Qt.point(b.x, b.y - lane), b]);
            if (a.y + lane < height - 18) candidates.push([a, Qt.point(a.x, a.y + lane), Qt.point(b.x, b.y + lane), b]);
        } else if (Math.abs(dx) < 2) {
            const lane = 26 + ((edge.a + edge.b) % 3) * 7;
            if (a.x - lane > 18) candidates.push([a, Qt.point(a.x - lane, a.y), Qt.point(b.x - lane, b.y), b]);
            if (a.x + lane < width - 18) candidates.push([a, Qt.point(a.x + lane, a.y), Qt.point(b.x + lane, b.y), b]);
        } else {
            candidates.push([a, Qt.point(a.x, a.y + sy * yStep),
                             Qt.point(b.x - sx * xStep, a.y + sy * yStep),
                             Qt.point(b.x - sx * xStep, b.y), b]);
            candidates.push([a, Qt.point(a.x + sx * xStep, a.y),
                             Qt.point(a.x + sx * xStep, b.y - sy * yStep),
                             Qt.point(b.x, b.y - sy * yStep), b]);
            candidates.push([a, Qt.point(b.x, a.y), b]);
            candidates.push([a, Qt.point(a.x, b.y), b]);
        }

        let best = candidates[0];
        let bestPenalty = routePenalty(best, edge);
        for (let i = 1; i < candidates.length; ++i) {
            const penalty = routePenalty(candidates[i], edge);
            if (penalty < bestPenalty) {
                bestPenalty = penalty;
                best = candidates[i];
            }
        }
        return best;
    }

    function drawArrow(ctx, from, to, radius) {
        const dx = to.x - from.x;
        const dy = to.y - from.y;
        const d = Math.sqrt(dx * dx + dy * dy);
        if (d < 1) return;
        const ux = dx / d;
        const uy = dy / d;
        const tipX = to.x - ux * radius;
        const tipY = to.y - uy * radius;
        const size = compact ? Math.max(1.8, Math.min(width, height) * 0.055) : 8;
        const backX = tipX - ux * size;
        const backY = tipY - uy * size;
        const px = -uy;
        const py = ux;
        ctx.beginPath();
        ctx.moveTo(tipX, tipY);
        ctx.lineTo(backX + px * size * 0.55, backY + py * size * 0.55);
        ctx.moveTo(tipX, tipY);
        ctx.lineTo(backX - px * size * 0.55, backY - py * size * 0.55);
        ctx.stroke();
    }

    Rectangle {
        anchors.fill: parent
        visible: !root.compact
        radius: Kirigami.Units.cornerRadius
        color: Qt.rgba(Kirigami.Theme.backgroundColor.r,
                       Kirigami.Theme.backgroundColor.g,
                       Kirigami.Theme.backgroundColor.b, 0.82)
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                              Kirigami.Theme.textColor.g,
                              Kirigami.Theme.textColor.b, 0.22)
    }

    Canvas {
        id: edgeCanvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.lineWidth = root.edgeWidth;
            ctx.strokeStyle = Kirigami.Theme.textColor;
            ctx.globalAlpha = root.compact ? 0.78 : 0.68;
            for (let i = 0; i < root.graphEdges.length; ++i) {
                const edge = root.graphEdges[i];
                const route = root.graphRoute(edge);
                if (route.length < 2) continue;
                ctx.beginPath();
                ctx.moveTo(route[0].x, route[0].y);
                for (let j = 1; j < route.length; ++j) ctx.lineTo(route[j].x, route[j].y);
                ctx.stroke();
                if (edge.aToB) root.drawArrow(ctx, route[route.length - 2], route[route.length - 1], root.nodeRadius);
                if (edge.bToA) root.drawArrow(ctx, route[1], route[0], root.nodeRadius);
            }
        }
    }

    Repeater {
        model: root.graphNodes.length

        Rectangle {
            required property int index
            readonly property var node: root.graphNodes[index]
            readonly property bool current: node && node.id === root.client.currentDesktopId
            readonly property point mapPosition: root.nodePosition(index)
            x: mapPosition.x - width / 2
            y: mapPosition.y - height / 2
            width: (current ? root.activeNodeRadius : root.nodeRadius) * 2
            height: width
            radius: width / 2
            color: current ? Kirigami.Theme.highlightColor : Kirigami.Theme.backgroundColor
            border.width: root.compact ? 1 : (current ? 3 : 2)
            border.color: root.compact && current ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor

            Text {
                anchors.centerIn: parent
                visible: !root.compact
                text: parent.index + 1
                color: parent.current ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                font.bold: parent.current
            }

            Text {
                anchors.top: parent.bottom
                anchors.topMargin: 2
                anchors.horizontalCenter: parent.horizontalCenter
                width: 100
                visible: !root.compact
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                text: parent.node ? parent.node.name : ""
                color: Kirigami.Theme.textColor
                font.pixelSize: 10
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.interactive && root.client.available
                hoverEnabled: enabled
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.client.switchDesktop(parent.node.id)

                QQC2.ToolTip.visible: containsMouse && parent.node
                QQC2.ToolTip.text: parent.node ? parent.node.name : ""
                QQC2.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }
    }

    onWidthChanged: Qt.callLater(rebuildLayout)
    onHeightChanged: Qt.callLater(rebuildLayout)
    Component.onCompleted: rebuildGraph()

    Connections {
        target: root.client
        function onGraphChanged() { root.rebuildGraph(); }
        function onStateChanged() { root.rebuildLayout(); }
    }
}
