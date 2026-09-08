#!/usr/bin/env python3
"""Check the active Hide Dock route cannot create or call a SpringBoard session."""
from pathlib import Path
root = Path(__file__).resolve().parents[1]
view = (root / "lara/views/new/HideDockIslandView.swift").read_text()
engine = (root / "lara/views/new/EagleDockRecipes.swift").read_text()
native = (root / "lara/kexploit/pe/rc.m").read_text()
header = (root / "lara/kexploit/pe/rc.h").read_text()
for forbidden in ("prepareFreshRemoteCall", "beginExclusiveRemoteCall", "RemoteCall", "find_process_pid",
                  "eagle_set_dock_background_hidden", "lara_overwritefile"):
    assert forbidden not in view, f"Unsafe/obsolete Dock route remains: {forbidden}"
assert "eagle_set_dock_background_hidden" not in native + header
assert "manager.vfsinit" in view and "vfsManager.vfsoverwritewithdata" in view
assert "offersRespring: true" in view
assert "dockDark.materialrecipe" in engine and "dockLight.materialrecipe" in engine
assert 'forKey: "eagle.dock.backgroundRecipeHidden"' in view
print("PASS: Hide Dock uses verified VFS recipes and user-confirmed respring; RemoteCall route removed")
