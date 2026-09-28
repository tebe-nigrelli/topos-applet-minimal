#!/usr/bin/env python3
"""Validate the KWin Topos D-Bus XML contract expected by this applet."""

from __future__ import annotations

import sys
import xml.etree.ElementTree as ET
from pathlib import Path

REQUIRED_API_VERSION = 1

EXPECTED_PROPERTIES = {
    "apiVersion": ("i", "read"),
    "ready": ("b", "read"),
    "activeProfile": ("s", "read"),
    "lastLoadedProfile": ("s", "read"),
    "dirty": ("b", "read"),
    "canUndo": ("b", "read"),
    "canRedo": ("b", "read"),
    "historyLimit": ("i", "readwrite"),
    "persistHistory": ("b", "readwrite"),
    "gestureDistance": ("i", "readwrite"),
    "settleThreshold": ("d", "readwrite"),
    "showHandles": ("b", "readwrite"),
    "showBridgePreview": ("b", "readwrite"),
    "topologyGraphLayout": ("s", "readwrite"),
    "topologyGraphSpread": ("d", "readwrite"),
}

EXPECTED_SIGNALS = {"StateChanged", "ProfilesChanged", "HistoryChanged", "DesktopSignatureChanged"}

EXPECTED_METHODS = {
    "Reset": ((), ("b",)),
    "ApplyBuiltin": (("s",), ("b",)),
    "ListBuiltins": ((), ("as",)),
    "ListProfiles": ((), ("as",)),
    "ListProfilesAll": ((), ("as",)),
    "LoadProfile": (("s",), ("b",)),
    "SaveProfile": (("s", "b"), ("b",)),
    "RenameProfile": (("s", "s", "b"), ("b",)),
    "DeleteProfile": (("s",), ("b",)),
    "Undo": (("i",), ("b",)),
    "Redo": (("i",), ("b",)),
    "ClearHistory": ((), ()),
    "GotoHistory": (("i",), ("b",)),
    "GetHistory": ((), ("s",)),
}


def signature(method: ET.Element) -> tuple[tuple[str, ...], tuple[str, ...]]:
    incoming: list[str] = []
    outgoing: list[str] = []
    for arg in method.findall("arg"):
        direction = arg.get("direction", "in")
        target = outgoing if direction == "out" else incoming
        target.append(arg.get("type", ""))
    return tuple(incoming), tuple(outgoing)


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {Path(sys.argv[0]).name} /path/to/org.kde.KWin.Topos.xml", file=sys.stderr)
        return 2

    root = ET.parse(sys.argv[1]).getroot()
    interface = root.find("./interface[@name='org.kde.KWin.Topos']")
    if interface is None:
        print("missing org.kde.KWin.Topos interface", file=sys.stderr)
        return 1

    failed = False
    properties = {p.get("name"): (p.get("type"), p.get("access")) for p in interface.findall("property")}
    methods = {m.get("name"): signature(m) for m in interface.findall("method")}
    signals = {signal.get("name") for signal in interface.findall("signal")}

    for name, expected in EXPECTED_PROPERTIES.items():
        actual = properties.get(name)
        if actual != expected:
            failed = True
            print(f"property {name}: expected {expected}, got {actual}", file=sys.stderr)

    for name, expected in EXPECTED_METHODS.items():
        actual = methods.get(name)
        if actual != expected:
            failed = True
            print(f"method {name}: expected {expected}, got {actual}", file=sys.stderr)

    missing_signals = EXPECTED_SIGNALS - signals
    if missing_signals:
        failed = True
        print(f"missing signals: {sorted(missing_signals)}", file=sys.stderr)

    if failed:
        return 1

    print(f"Topos D-Bus contract is compatible with applet API v{REQUIRED_API_VERSION}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
