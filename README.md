# Topos Plasma applet

A Plasma 6 panel client for the Topos KWin fork. The applet contains no topology-routing logic; KWin remains authoritative for graph state, profiles, history, gesture settings, and the Grid View editor.

## Compatibility

This release targets **Topos D-Bus API version 1**.

Service: `org.kde.KWin`  
Object: `/Topos`  
Interface: `org.kde.KWin.Topos`

The applet reads `apiVersion` before enabling controls. A missing or different version is reported as an incompatible Topos installation instead of allowing partially working calls.

Methods used:

- `ListBuiltins() -> as`
- `ListProfiles() -> as`
- `ListProfilesAll() -> as` for save/rename collision detection
- `ApplyBuiltin(name)`
- `LoadProfile(name)`
- `Reset()`
- `SaveProfile(name, overwrite)`
- `RenameProfile(oldName, newName, overwrite)`
- `DeleteProfile(name)`
- `Undo(count)` / `Redo(count)`
- `GetHistory() -> JSON string`
- `GotoHistory(index)`
- `ClearHistory()`

Properties read through `org.freedesktop.DBus.Properties.GetAll`:

- `apiVersion`
- `ready`
- `activeProfile`
- `lastLoadedProfile`
- `dirty`
- `canUndo`
- `canRedo`
- `historyLimit`
- `persistHistory`
- `gestureDistance`
- `settleThreshold`
- `showHandles`
- `showBridgePreview`
- `topologyGraphLayout`
- `topologyGraphSpread`

The writable settings are changed through standard `org.freedesktop.DBus.Properties.Set`, matching the KWin interface XML. The client listens for `StateChanged`, `ProfilesChanged`, `HistoryChanged`, and `DesktopSignatureChanged`, and watches the `org.kde.KWin` service owner so it reconnects after KWin restarts.

You can statically verify the D-Bus contract against a patched KWin source tree:

```bash
./tools/check-kwin-contract.py /path/to/kwin/src/org.kde.KWin.Topos.xml
```

## Arch Linux build

```bash
sudo pacman -S --needed base-devel cmake extra-cmake-modules qt6-base qt6-declarative libplasma
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build
sudo cmake --install build
```

Then add **Topos** to a Plasma panel.

For widget testing, install `plasma-sdk` and use:

```bash
plasmoidviewer -a org.kde.plasma.topos -f horizontal
plasmoidviewer -a org.kde.plasma.topos -f vertical
QT_SCALE_FACTOR=2 plasmoidviewer -a org.kde.plasma.topos -f horizontal
```

## Implemented panel surface

- compact icon + current/unsaved tooltip
- explicit KWin/API compatibility check
- Save / Undo / Redo / Settings row
- compatible-profile list plus all-profile collision detection
- profile activation
- inline save and rename with overwrite handling
- unavailable/incompatible-state handling
- history jump on long-press of Undo/Redo
- history depth and persistent-history setting
- gesture distance and settle threshold settings
- Grid View handle and bridge-preview settings
- topology graph layout (Grid / Loose DAG) and Loose DAG spread
- Clear History
- D-Bus service restart recovery

Topology editing and graph rendering remain in KWin's Grid View overlay.

# All in One
```
cmake --build build -j"$(nproc)" && sudo cmake --install build && systemctl --user restart plasma-plasmashell.service

```